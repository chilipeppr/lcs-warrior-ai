---
name: lcs-oauth
description: Use when implementing Google OAuth authentication for any LCS service or feature. Covers Google Workspace (@mylcs.com) OAuth flows, Google Classroom integration, credential management, and token exchange patterns. Trigger words: oauth, google login, sign in with google, authenticate, google classroom, mylcs.com login, google workspace auth.
---

# LCS OAuth — Google Workspace Authentication

Add Google OAuth 2.0 authentication to any LCS service using Google Workspace. Students and teachers sign in with their @mylcs.com Google accounts. No separate credentials needed.

## Architecture

LCS uses Google Workspace for authentication. Every student and teacher has an @mylcs.com Google account. OAuth flows use Google's standard OAuth 2.0 with the school's Google Cloud project.

```text
User clicks "Sign in with Google"
  -> Redirected to Google OAuth consent screen
  -> User authorizes with their @mylcs.com account
  -> Google redirects back with auth code
  -> App exchanges code for tokens
  -> User is authenticated
```

**Key properties:**
- Single sign-on with @mylcs.com Google accounts
- No separate passwords to manage
- Google Workspace admin can control which apps are authorized
- Student accounts have appropriate restrictions

## Google Cloud Setup (LCS IT Admin)

1. Use the LCS Google Cloud project at console.cloud.google.com
2. Enable the required APIs:
   - Google Classroom API (for class integration)
   - Google Drive API (for document access)
   - Google Calendar API (for scheduling)
3. Create OAuth credentials -> Web application
4. Add authorized redirect URI for your app
5. Copy client ID + secret to the service's config
6. Restrict to @mylcs.com domain in OAuth consent screen settings

## Adding OAuth to a New LCS App

### Step 1: Configure OAuth Credentials

Store your OAuth client ID in your app's config. The client secret stays on the server side only.

```json
{
  "clientId": "YOUR_CLIENT_ID.apps.googleusercontent.com",
  "allowedDomain": "mylcs.com"
}
```

### Step 2: Implement the Sign-In Flow

```javascript
// Simple Google Sign-In for LCS apps
const GOOGLE_AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
const CLIENT_ID = 'YOUR_CLIENT_ID.apps.googleusercontent.com';

function startGoogleSignIn() {
  const params = new URLSearchParams({
    client_id: CLIENT_ID,
    redirect_uri: window.location.origin + '/callback',
    response_type: 'code',
    scope: 'openid email profile',
    hd: 'mylcs.com',  // Restrict to school domain
    prompt: 'select_account',
  });
  
  window.location.href = `${GOOGLE_AUTH_URL}?${params}`;
}
```

### Step 3: Handle the Callback

```javascript
// Server-side callback handler
app.get('/callback', async (req, res) => {
  const { code } = req.query;
  
  // Exchange code for tokens
  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      redirect_uri: req.protocol + '://' + req.get('host') + '/callback',
      grant_type: 'authorization_code',
    }),
  });
  const tokens = await tokenRes.json();
  
  // Verify the user is from @mylcs.com
  const userInfo = await fetch('https://www.googleapis.com/oauth2/v2/userinfo', {
    headers: { Authorization: `Bearer ${tokens.access_token}` },
  });
  const user = await userInfo.json();
  
  if (!user.email.endsWith('@mylcs.com')) {
    return res.status(403).send('Access restricted to @mylcs.com accounts');
  }
  
  // Store tokens and create session
  saveTokens(user.email, tokens);
  res.redirect('/');
});
```

### Step 4: Token Storage

```javascript
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import { homedir } from 'os';

const TOKEN_PATH = `${homedir()}/.config/lcs-app-tokens.json`;

function loadTokens(email) {
  if (!existsSync(TOKEN_PATH)) return null;
  const all = JSON.parse(readFileSync(TOKEN_PATH, 'utf-8'));
  return all[email] || null;
}

function saveTokens(email, tokens) {
  const dir = dirname(TOKEN_PATH);
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  let all = {};
  if (existsSync(TOKEN_PATH)) {
    all = JSON.parse(readFileSync(TOKEN_PATH, 'utf-8'));
  }
  all[email] = { ...tokens, saved_at: Date.now() };
  writeFileSync(TOKEN_PATH, JSON.stringify(all, null, 2) + '\n');
}
```

### Step 5: Token Refresh

```javascript
async function getAccessToken(email) {
  let tokens = loadTokens(email);
  if (!tokens?.refresh_token) throw new Error('Not signed in');
  
  // Return cached if still valid (with 60s margin)
  if (tokens.access_token && tokens.expires_at > Date.now() + 60000) {
    return tokens.access_token;
  }
  
  // Refresh the token
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: tokens.refresh_token,
      grant_type: 'refresh_token',
    }),
  });
  const newTokens = await res.json();
  tokens.access_token = newTokens.access_token;
  tokens.expires_at = Date.now() + (newTokens.expires_in * 1000);
  if (newTokens.refresh_token) tokens.refresh_token = newTokens.refresh_token;
  saveTokens(email, tokens);
  return tokens.access_token;
}
```

## Google Classroom Integration

LCS apps can integrate with Google Classroom to access class rosters, assignments, and grades (with appropriate permissions):

```javascript
// Scopes for Classroom integration
const CLASSROOM_SCOPES = [
  'https://www.googleapis.com/auth/classroom.courses.readonly',
  'https://www.googleapis.com/auth/classroom.rosters.readonly',
  'https://www.googleapis.com/auth/classroom.student-submissions.students.readonly',
].join(' ');
```

**Important:** Classroom API access requires admin approval in the Google Workspace admin console. Teachers can request read access to their own classes; broader access requires IT admin approval.

## Supported Google APIs

| API | Scopes | Use Case |
|-----|--------|----------|
| Google Classroom | `classroom.courses`, `classroom.rosters` | Class rosters, assignments |
| Google Drive | `drive.file`, `drive.readonly` | Student documents, shared files |
| Google Calendar | `calendar.readonly`, `calendar.events` | School events, scheduling |
| Gmail | `gmail.readonly` | School announcements (admin only) |

## Security Rules

1. **Restrict to @mylcs.com** — always set `hd: 'mylcs.com'` in the OAuth request AND verify the domain server-side
2. **Never store client secrets in client-side code** — keep them server-side only
3. **FERPA compliance** — student data accessed via Google APIs is still subject to FERPA. Do not share or display student grades/records publicly
4. **Minimal scopes** — request only the Google API scopes your app actually needs
5. **Token security** — store tokens in secure server-side storage, never in localStorage or cookies without encryption

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| "Access blocked" error | The app needs to be approved in Google Workspace admin. Contact LCS IT. |
| "Not a @mylcs.com account" | Student is signed into a personal Google account. Sign out and use school account. |
| Token refresh fails | Token may have been revoked by admin. Re-authenticate. |
| "This app isn't verified" | Normal for internal apps. Click "Advanced" then "Go to app" (teachers only). Students may need admin pre-approval. |
