---
name: lcs-debug
description: >-
  Full reference guide for iterative visual debugging in LCS apps. Covers
  screenshot wiring, Puppeteer scripting, and image sizing. Trigger: "debug",
  "debug widget", "visual debug", "iterate on", "test my app", "not rendering",
  "looks wrong", "fix the UI", "screenshot loop", "debug loop", "can't see".
  ALSO trigger PROACTIVELY when you are creating or editing HTML, CSS, or JS
  that will be displayed visually -- in a Hydrogen webview, pup browser session,
  or any other visual surface. If you just wrote or edited UI code, you MUST
  enter the visual feedback loop: install tools (section 0), start shotlog
  (section 2), screenshot, analyze, and iterate until it looks right.
---

# Debug Guide -- Iterative Visual Feedback Loop

Full reference for debugging in the LCS environment. The same Ralph Wiggum philosophy applies: screenshot everything, iterate until it looks right, log every frame to shotlog.

---

## 0. Auto-Install Debug Tools

**Run this FIRST before any debug session.**

```bash
# shotlog -- screenshot log viewer (port 8820)
if ! command -v shotlog &>/dev/null; then
  echo "Installing shotlog..."
  gh release download v0.2.0 -R adom-inc/shotlog -p "shotlog" -D /tmp --clobber
  chmod +x /tmp/shotlog
  sudo mv /tmp/shotlog /usr/local/bin/shotlog
  echo "shotlog installed: $(shotlog --version 2>&1 || echo 'ok')"
fi
```

---

## 1. The Debug Philosophy

Four rules:

1. **Always screenshot and analyze yourself.** Never say "check your viewer" or "it should work now." YOU must visually verify every iteration.
2. **Never stop until the screenshot looks correct.** Loop until the visual output matches what is expected. No exceptions.
3. **Failures are data.** Each broken screenshot tells you exactly what to fix next.
4. **Always log to shotlog.** Every screenshot gets injected into shotlog so the user can watch the debug session unfold in real-time.

---

## 2. Start Shotlog First

**Before entering the debug loop, always set up shotlog.**

```bash
# 1. Ensure shotlog server is running
shotlog health || shotlog serve &

# 2. Pick a descriptive channel name
CHANNEL="<descriptive-name>"

# 3. Open the shotlog viewer panel
shotlog open -c "$CHANNEL"
```

---

## 3. The Debug Loop

```text
1. Edit code
2. Refresh the debug surface (webview refresh, pup reload, or restart server)
3. Interact -- send commands to exercise the change (rotate camera, click buttons, toggle states)
4. Screenshot the panel and save to file
5. Inject into shotlog (user sees it appear in real-time)
6. Read the PNG -- analyze it visually yourself
7. If broken --> identify what is wrong --> fix code --> go to 1
8. If correct --> done
```

**Steps 4-5 together, every time:**
```bash
# Screenshot
adom-cli hydrogen screenshot panel --panel-id <id> -o /tmp/debug-v1.png

# Immediately inject into shotlog
shotlog inject -c "$CHANNEL" \
  -d "v1: Initial render after adding nav dropdown component" \
  -s hydrogen /tmp/debug-v1.png
```

Increment filenames and prefix descriptions with the version: `v1:`, `v2:`, `v3:` so the shotlog timeline tells a clear story.

---

## 4. Screen Sharing Setup

**Required for hydrogen screenshots to work.** One-time setup per session.

1. Tell the user: "Click the **monitor icon** in the hydrogen nav bar (top right)"
2. A browser dialog appears asking what to share:
   - **"Share this tab"** -- enables `panel` + `workspace` screenshot scopes
   - **"Share entire screen"** -- enables all scopes including `screen`
3. Persists for the entire session

---

## 5. Screenshots

Always prefer the most targeted scope.

### Panel capture (primary -- fastest)

```bash
adom-cli hydrogen workspace get
adom-cli hydrogen screenshot panel --panel-id <leaf-id> -o /tmp/debug-v1.png
```

### Workspace capture

```bash
adom-cli hydrogen screenshot workspace -o /tmp/ws.png
```

### Screen capture

```bash
adom-cli hydrogen screenshot screen -o /tmp/screen.png
```

---

## 6. Debug Surfaces

### Webview panels (primary)

The main debug surface. Pattern: start HTTP server, create webview panel, refresh after changes, screenshot.

**Control:**
```bash
adom-cli hydrogen webview navigate --panel-id <id> <url>
adom-cli hydrogen webview refresh --panel-id <id>
adom-cli hydrogen webview set-header --panel-id <id> true
```

### Pup browser sessions (desktop browser)

For when you need a real Chrome window.

```bash
adom-desktop browser_open_window \
  '{"sessionId":"debug","profile":"debug","url":"http://localhost:3000"}'
adom-desktop browser_reload '{"sessionId":"debug"}'
adom-desktop browser_screenshot '{"sessionId":"debug"}'
adom-desktop browser_errors '{"sessionId":"debug"}'
```

---

## 7. Decision Tree

```text
Need visual debug feedback?
  |
  +-- Content in a hydrogen panel?
  |     +-- Screen sharing enabled?
  |     |     +-- YES --> screenshot panel --panel-id <id>
  |     |     +-- NO  --> Tell user to click monitor icon
  |     +-- After changes: webview refresh, then interact, then screenshot
  |
  +-- Content in a desktop browser window? (pup session)
  |     +-- browser_reload --> browser_eval --> browser_screenshot
  |
  +-- Need to see multiple panels or full layout?
  |     +-- screenshot workspace
  |
  +-- Need full screen?
        +-- screenshot screen
```

---

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| 504 timeout on screenshot | Sharing dialog not addressed | Click monitor icon in nav bar |
| 409 "No browser session" | Editor tab closed | Surface the Hydrogen tab |
| Panel ID not found | Wrong ID or panel closed | `adom-cli hydrogen workspace get` |
| Webview shows blank | Server not running | `curl http://127.0.0.1:PORT/` |
| Screenshot shows stale content | Not refreshed | `adom-cli hydrogen webview refresh` |

---

## Image Resizing for Claude

All screenshot methods auto-resize to <=1568px on the longest edge. For manual resizing:

```bash
shotlog resize large-image.png
shotlog resize large-image.png -o small.png
```
