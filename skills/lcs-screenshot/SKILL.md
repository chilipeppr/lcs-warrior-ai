---
name: lcs-screenshot
description: How to capture screenshots -- Hydrogen panels/workspace/screen (primary) and desktop windows. Enables AI visual feedback loops. **EVERY screenshot MUST be logged to shotlog immediately after capture.** Trigger words -- screenshot, screencap, capture panel, hydrogen screenshot, browser screenshot, visual verification, debug loop, walkthrough proof, visual feedback, capture my app, screenshot my project.
---

# Screenshot and Visual Feedback -- LCS

## Always inject to shotlog -- non-negotiable

**After EVERY screenshot, before moving on, run `shotlog inject -c <channel> -d "<specific description>" -s <source> <file>`.** No exceptions.

**Why:**
- The shotlog webview is how humans review visual history across a session
- Screenshots not in shotlog are effectively lost when the chat scrolls
- This rule distinguishes a repeatable visual record from a one-off preview

**How to apply:**
- Every `adom-cli hydrogen screenshot` call is immediately followed by `shotlog inject`
- Every `browser_screenshot` (pup) call is immediately followed by `shotlog inject`
- Pick a channel name tied to the task (`flashcard-app-debug`, `strive-dashboard-layout`)
- Description is SPECIFIC (`step3-quiz-timer-overflow`, not `shot3`)

## Default: Use Hydrogen Screenshots

**Priority order:**
1. `hydrogen screenshot panel` -- single panel (fastest)
2. `hydrogen screenshot workspace` -- all panels side by side
3. `hydrogen screenshot screen` -- entire display
4. Desktop `desktop_screenshot_window` -- native apps, background windows
5. Desktop `desktop_screenshot_screen` -- full desktop

## Quick Reference

| Need to see... | Tool | Setup |
|---|---|---|
| A single hydrogen panel | `hydrogen screenshot panel --panel-id <id>` | Screen sharing (monitor icon) |
| All hydrogen panels | `hydrogen screenshot workspace` | Screen sharing |
| Full display | `hydrogen screenshot screen` | Screen sharing ("Share entire screen") |
| Native desktop apps | `desktop_screenshot_window` via adom-desktop CLI | Desktop app |

---

## Hydrogen Editor Screenshots

### Screen Sharing Setup (one-time per session)

1. Click the **monitor icon** in the hydrogen nav bar (top right)
2. A browser dialog appears:
   - **"Share this tab"** -- enables `panel` + `workspace` scopes (recommended)
   - **"Share entire screen"** -- enables all scopes including `screen`
3. Persists for the session

### Commands

```bash
# Get panel IDs
adom-cli hydrogen workspace get

# Single panel (fastest -- use this by default)
adom-cli hydrogen screenshot panel --panel-id <leaf-id>

# All panels side by side
adom-cli hydrogen screenshot workspace

# Entire display
adom-cli hydrogen screenshot screen
```

Files saved automatically to `~/project/screenshots/`.

---

## Visual Feedback Loop

```text
1. Edit code
2. Refresh the debug surface (webview refresh, pup reload, server restart)
3. Interact -- send commands to exercise the change
4. Screenshot (choose the right method from the table above)
5. shotlog inject with a SPECIFIC description   <-- always, no exceptions
6. Analyze the screenshot -- does it look right?
7. If not right --> identify what is wrong --> fix --> go to step 1
```

---

## Image Resizing for Claude

All screenshot methods auto-resize to <=1568px on the longest edge. For manual resizing:

```bash
shotlog resize large-image.png
shotlog resize large-image.png -o small.png
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| 504 timeout on screenshot | Click monitor icon in nav bar to approve sharing |
| 409 "No browser session" | Surface the Hydrogen tab |
| Panel ID not found | `adom-cli hydrogen workspace get` to list current IDs |
| Webview shows blank | Check server is running: `curl http://127.0.0.1:PORT/` |
| Screenshot shows stale content | `adom-cli hydrogen webview refresh --panel-id <id>` |
