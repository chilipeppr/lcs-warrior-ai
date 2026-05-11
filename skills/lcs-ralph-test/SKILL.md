---
name: lcs-ralph-test
description: "Visual self-test loop — screenshot what the user sees, analyze it, fix issues, repeat until correct. Use BEFORE telling the user something is ready. Trigger words: ralph test, verify, check it looks right, self-test, visual test, does it look right, test the output."
user-invocable: true
---

# Ralph Test — Visual Self-Verification

"I see what you see." — Screenshot the output, look at it yourself, fix anything broken, repeat until it's correct. **Never tell a student something is ready without verifying it visually first.**

## What the user asked

$ARGUMENTS

## When to Ralph Test

- After opening a webview (lcs-webview pattern)
- After building or modifying any visual app/card/page
- After changing CSS, layout, or visual content
- Before telling the user "it's done" or "it's ready"
- Any time you're not 100% sure the output looks right

## The Loop

```text
1. Screenshot the panel/webview
2. Read the PNG — analyze what you see
3. Is it correct?
   YES → Done. Tell the user it's ready.
   NO  → Identify what's wrong → fix it → refresh → go to 1
```

## Step 1: Ensure Screen Sharing is Active

Screenshots require the user to have shared their tab. If screenshots fail with a 504 timeout, explain to the user in a friendly, non-scary way:

> "I need to be able to see what's on your screen so I can check that everything looks right before showing it to you. Click the **monitor icon** (looks like a little screen) in the top-right corner of your Hydrogen nav bar, then click **'Share this tab'**."
>
> "Don't worry — this doesn't share your screen with anyone else or record anything. It just lets me (your AI assistant inside this container) take snapshots of the Hydrogen tab so I can verify my work looks correct. It's like me peeking over your shoulder to make sure the page rendered properly. You only have to do this once per session."

### Why students see this prompt

The browser's built-in screen capture API requires user permission (it's a security feature of Chrome/Chromium). When the student clicks "Share this tab," they're giving the Hydrogen page permission to capture its own contents — NOT broadcasting to anyone external. The capture stays entirely within the container.

**Common student reactions and how to reassure them:**
- "Is someone watching me?" — No. The screenshot stays inside your container. Only your AI assistant sees it.
- "Will my teacher see this?" — No. This is private to your session.
- "Do I have to do this?" — Only if you want me to visually verify things for you. You can skip it, but then I can't check my own work before showing it to you.

## Step 2: Screenshot

```bash
# Find the panel you want to verify
adom-cli hydrogen workspace tabs

# Screenshot it
adom-cli hydrogen screenshot panel --panel-id <panel-id> -o /tmp/ralph-test.png
```

## Step 3: Analyze

Read the PNG with the Read tool. Look for:

- **Blank/white page** — server not running, wrong URL, or file not found
- **Error page** — malformed proxy URL, CORS issue, or missing resource
- **Broken layout** — CSS issues, overflow, wrong dimensions
- **Missing content** — JS errors preventing render, wrong data
- **Wrong content** — stale cache, wrong file served
- **Looks correct** — proceed to tell the user

## Step 4: Fix and Repeat

If anything is wrong:
1. Identify the specific problem from the screenshot
2. Fix the code/config
3. Refresh the webview: `adom-cli hydrogen webview refresh --panel-id <panel-id>`
4. Wait a beat, then screenshot again
5. Repeat until correct

## Rules

- **Never skip this.** If you built visual output, you ralph test it.
- **Never say "it should work"** — verify, don't guess.
- **Log to shotlog** if doing multiple iterations so the user can watch progress:
  ```bash
  shotlog inject -c "ralph-test" -d "v1: checking render" -s hydrogen /tmp/ralph-test.png
  ```
- **Max 5 iterations** — if still broken after 5 attempts, tell the user what's wrong and ask for help.
