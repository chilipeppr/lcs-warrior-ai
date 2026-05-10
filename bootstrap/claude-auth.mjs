#!/usr/bin/env node
/**
 * Authenticate Claude Code in container environments.
 *
 * The standard OAuth redirect-to-localhost flow doesn't work in containers.
 * This script does the PKCE flow manually:
 *   1. Generates a PKCE challenge
 *   2. Prints an auth URL for the user to open
 *   3. Prompts the user to paste the code they receive
 *   4. Tries to exchange the code for tokens server-side (multiple endpoints)
 *   5. If Cloudflare blocks all endpoints, offers fallback methods:
 *      a) Browser console snippet (paste on claude.ai — works for everyone)
 *      b) Existing token from `claude setup-token` on another machine
 *      c) Anthropic API key from console.anthropic.com
 *   6. Writes ~/.claude/.credentials.json
 */

import { createHash, randomBytes } from 'crypto';
import { request } from 'https';
import { createInterface } from 'readline';
import { mkdirSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

const CLIENT_ID = '9d1c250a-e61b-44d9-88ed-5944d1962f5e';
const REDIRECT_URI = 'https://platform.claude.com/oauth/code/callback';
const SCOPES = 'org:create_api_key user:profile user:inference user:sessions:claude_code user:mcp_servers';
const CRED_PATH = join(homedir(), '.claude', '.credentials.json');

// Generate PKCE verifier + challenge
const verifier = randomBytes(48).toString('base64url').slice(0, 64);
const challenge = createHash('sha256').update(verifier).digest('base64url');
const state = randomBytes(24).toString('base64url');

// Build auth URL
const params = new URLSearchParams({
  code: 'true',
  client_id: CLIENT_ID,
  response_type: 'code',
  redirect_uri: REDIRECT_URI,
  scope: SCOPES,
  code_challenge: challenge,
  code_challenge_method: 'S256',
  state: state,
});
const authUrl = `https://claude.ai/oauth/authorize?${params}`;

console.log('');
console.log('  Open this URL in your browser and sign in:');
console.log('');
console.log(`  ${authUrl}`);
console.log('');
console.log('  After signing in, you\'ll see a code to copy.');
console.log('');

const rl = createInterface({ input: process.stdin, output: process.stdout });

function ask(question) {
  return new Promise((resolve) => rl.question(question, resolve));
}

const rawCode = await ask('  Paste the code here: ');
// The pasted code may include #<state> appended — strip it
const code = rawCode.trim().split('#')[0];
if (!code) {
  console.error('  No code entered. Aborting.');
  process.exit(1);
}

console.log('');
console.log('  Exchanging code for tokens...');

// JSON body — must match what the CLI sends (axios POST with Content-Type: application/json)
const tokenBody = JSON.stringify({
  grant_type: 'authorization_code',
  code,
  redirect_uri: REDIRECT_URI,
  client_id: CLIENT_ID,
  code_verifier: verifier,
  state,
});

// Try multiple hostnames and paths — Cloudflare config varies by domain
const endpoints = [
  { hostname: 'platform.claude.com', path: '/v1/oauth/token' },
];

let success = false;
for (const ep of endpoints) {
  const result = await tryEndpoint(ep.hostname, ep.path, tokenBody);
  if (result === 'success') {
    success = true;
    break;
  }
  if (result === 'auth_error') {
    process.exit(1);
  }
}

if (!success) {
  console.log('');
  console.log('  Server-side token exchange blocked. Choose a method:');
  console.log('');
  console.log('  1) Browser console — paste a snippet on claude.ai');
  console.log('  2) Existing token — from `claude setup-token` on another machine');
  console.log('  3) API key — from console.anthropic.com/settings/keys');
  console.log('');

  const choice = (await ask('  Enter 1, 2, or 3: ')).trim();

  if (choice === '1') {
    await browserConsoleFallback();
  } else if (choice === '2') {
    await existingTokenFallback();
  } else if (choice === '3') {
    await apiKeyFallback();
  } else {
    console.error('  Invalid choice. Run this script again to retry.');
    process.exit(1);
  }
}

rl.close();

// ── Fallback methods ─────────────────────────────────────────

async function browserConsoleFallback() {
  console.log('');
  console.log('  In your browser, stay on the platform.claude.com page where you got the code.');
  console.log('  Open the browser console (F12 → Console tab) and paste this:');
  console.log('');

  const snippet = `fetch('/v1/oauth/token',{method:'POST',headers:{'Content-Type':'application/json','Accept':'application/json'},body:JSON.stringify({grant_type:'authorization_code',code:${JSON.stringify(code)},redirect_uri:${JSON.stringify(REDIRECT_URI)},client_id:${JSON.stringify(CLIENT_ID)},code_verifier:${JSON.stringify(verifier)},state:${JSON.stringify(state)}})}).then(r=>r.json()).then(t=>{if(t.error){console.error('Error:',t.error,t.error_description);return}const c=JSON.stringify({claudeAiOauth:{accessToken:t.access_token,refreshToken:t.refresh_token||'',expiresAt:Date.now()+(t.expires_in||3600)*1e3,scopes:(t.scope||'').split(' '),subscriptionType:null,rateLimitTier:null}});copy(c);console.log('Credentials copied to clipboard!')}).catch(e=>console.error('Failed:',e))`;

  console.log(`  ${snippet}`);
  console.log('');
  console.log('  It will copy the credentials to your clipboard.');
  console.log('');

  const credJson = (await ask('  Paste the credentials here: ')).trim();
  if (!credJson) {
    console.error('  No credentials entered.');
    process.exit(1);
  }

  try {
    const parsed = JSON.parse(credJson);
    if (!parsed.claudeAiOauth?.accessToken) throw new Error('Missing accessToken');
    writeCreds(parsed);
    console.log('  Authenticated successfully.');
  } catch (e) {
    console.error('  Invalid credentials JSON:', e.message);
    process.exit(1);
  }
}

async function existingTokenFallback() {
  console.log('');
  console.log('  On a machine where Claude Code is already authenticated, run:');
  console.log('');
  console.log('    claude setup-token');
  console.log('');
  console.log('  Copy the full token (starts with sk-ant-oat01-).');
  console.log('  Make sure to include the entire string if it wraps to two lines.');
  console.log('');

  const token = (await ask('  Paste the token here: ')).trim();
  if (!token) {
    console.error('  No token entered.');
    process.exit(1);
  }

  if (!token.startsWith('sk-ant-')) {
    console.error('  Token should start with sk-ant-. Got:', token.slice(0, 20));
    process.exit(1);
  }

  writeCreds({
    claudeAiOauth: {
      accessToken: token,
      refreshToken: '',
      expiresAt: Date.now() + 90 * 24 * 3600 * 1000, // 90 days
      scopes: ['user:inference', 'user:mcp_servers', 'user:profile', 'user:sessions:claude_code'],
      subscriptionType: null,
      rateLimitTier: null,
    },
  });
  console.log('  Authenticated successfully.');
}

async function apiKeyFallback() {
  console.log('');
  console.log('  Go to https://console.anthropic.com/settings/keys');
  console.log('  Create an API key (starts with sk-ant-api03-).');
  console.log('');

  const apiKey = (await ask('  Paste your API key here: ')).trim();
  if (!apiKey) {
    console.error('  No API key entered.');
    process.exit(1);
  }

  // API keys go in the environment, not .credentials.json
  const bashrc = join(homedir(), '.bashrc');
  const exportLine = `export ANTHROPIC_API_KEY='${apiKey}'`;

  // Add to .bashrc if not already there
  const existing = existsSync(bashrc)
    ? (await import('fs')).readFileSync(bashrc, 'utf-8')
    : '';
  if (!existing.includes('ANTHROPIC_API_KEY')) {
    writeFileSync(bashrc, existing + '\n' + exportLine + '\n');
  }

  // Also set in current process for verification
  process.env.ANTHROPIC_API_KEY = apiKey;

  console.log('  API key saved to ~/.bashrc');
  console.log('  It will be active after reloading VS Code.');
  console.log('  Authenticated successfully.');
}

// ── Helpers ──────────────────────────────────────────────────

function writeCreds(creds) {
  const claudeDir = join(homedir(), '.claude');
  mkdirSync(claudeDir, { recursive: true });
  writeFileSync(CRED_PATH, JSON.stringify(creds), { mode: 0o600 });
}

function tryEndpoint(hostname, path, body) {
  return new Promise((resolve) => {
    const req = request({
      hostname,
      path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
        'Accept': 'application/json',
      },
    }, (res) => {
      let data = '';
      res.on('data', (d) => data += d);
      res.on('end', () => {
        if (data.includes('challenge-platform') || data.includes('Just a moment')) {
          console.log(`  ${hostname}${path} — blocked by Cloudflare`);
          resolve('blocked');
          return;
        }

        try {
          const r = JSON.parse(data);
          if (r.error) {
            const errType = typeof r.error === 'object' ? r.error.type || JSON.stringify(r.error) : r.error;
            const errMsg = typeof r.error === 'object' ? r.error.message : r.error_description;
            console.error(`  ${hostname}${path} — ${errType}: ${errMsg || ''}`);
            resolve(errType === 'invalid_grant' ? 'auth_error' : 'error');
            return;
          }
          if (!r.access_token) {
            console.log(`  ${hostname}${path} — no access_token in response`);
            resolve('error');
            return;
          }

          writeCreds({
            claudeAiOauth: {
              accessToken: r.access_token,
              refreshToken: r.refresh_token || '',
              expiresAt: Date.now() + (r.expires_in || 3600) * 1000,
              scopes: typeof r.scope === 'string' ? r.scope.split(' ') : (r.scope || []),
              subscriptionType: null,
              rateLimitTier: null,
            },
          });
          console.log('  Authenticated successfully.');
          resolve('success');
        } catch (e) {
          console.log(`  ${hostname}${path} — unexpected response`);
          resolve('error');
        }
      });
    });

    req.on('error', (e) => {
      console.log(`  ${hostname}${path} — ${e.message}`);
      resolve('error');
    });

    req.write(body);
    req.end();
  });
}
