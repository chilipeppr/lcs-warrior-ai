---
name: lcs-webview
description: "Show web content (HTML pages, apps, cards, visualizations) to the user in a Hydrogen webview panel. Covers serving files, building proxy URLs, and opening webview tabs. MUST be used any time the user wants to see a webpage, preview, or visual output."
user-invocable: false
---

# LCS Webview — Showing Web Content to Users

Any time you generate or serve an HTML file, webpage, card, visualization, or app that the user needs to SEE — this is how you display it.

## The Golden Rule

**Hydrogen webview panels are browser iframes running on the user's Chromebook/device.** They connect BACK to this Docker container through a proxy URL. They cannot access the container's filesystem or loopback network directly.

### NEVER use:
- `file:///...` — the browser has no access to this container's filesystem
- `http://localhost:...` or `http://127.0.0.1:...` — loopback is unreachable from the remote browser

### ALWAYS use:
- `$VSCODE_PROXY_URI` with `{{port}}` replaced by your server's port

---

## Step-by-Step Pattern

### 1. Put files inside `/home/adom/project/`

All served content must live under the workspace root so VS Code can also see it.

### 2. Start an HTTP server

```bash
python3 -c "
import http.server, os
class H(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()
os.chdir('/home/adom/project')
http.server.HTTPServer(('0.0.0.0', 36199), H).serve_forever()
" &
```

Port 36199 is the LCS convention. Use a different port if 36199 is already occupied.

Verify it's running:
```bash
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:36199/your-file.html
# Should return 200
```

### 3. Build the proxy URL

```bash
PROXY_URL=$(echo "$VSCODE_PROXY_URI" | sed 's/{{port}}/36199/')
# Result: https://<container-hostname>/proxy/36199/
```

### 4. Test the proxy URL BEFORE opening the webview

**Always verify the URL resolves before sending it to Hydrogen.** The webview will silently show a blank/error page if the URL is wrong — the student won't know why.

```bash
FULL_URL="${PROXY_URL}your-file.html"

# Test it — must return 200
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FULL_URL")
if [ "$HTTP_STATUS" != "200" ]; then
  echo "ERROR: $FULL_URL returned $HTTP_STATUS — fix before opening webview"
  # Debug: is the server running locally?
  curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:36199/your-file.html
fi
```

If the proxy URL fails but localhost succeeds, the proxy URL is malformed. Double-check `$VSCODE_PROXY_URI` substitution.

### 5. Open the webview tab

```bash
# Find a panel ID to place the tab
adom-cli hydrogen workspace tabs

# Open (or refresh if already open)
adom-cli hydrogen webview open-or-refresh \
  --name "My Content" \
  --url "$FULL_URL" \
  --panel-id <panel-id-from-tabs>
```

The `--name` is a stable handle. Re-running with the same `--name` refreshes the existing tab instead of creating a duplicate.

### 6. Screenshot and visually verify

**Never assume it worked. Look at what the user sees.**

```bash
# Get the panel ID of the webview tab you just opened
adom-cli hydrogen workspace tabs
# Find your tab's panelId from the output

# Screenshot the panel
adom-cli hydrogen screenshot panel --panel-id <panel-id> -o /tmp/webview-verify.png

# Read the screenshot — visually confirm the content rendered correctly
# (use the Read tool on the PNG to see it)
```

If the screenshot shows:
- **Blank white page** — server not running or wrong path
- **Browser error page** — proxy URL is malformed or port mismatch
- **Partial render / broken layout** — fix the HTML/CSS, refresh, screenshot again
- **Correct content** — done, tell the user it's ready

**Do NOT tell the user "it's open" until you have visually confirmed the screenshot looks right.** Students can't debug broken webviews — that's your job.

---

## Complete Example

User asks: "Make me a birthday card"

```bash
# 1. Create the HTML file
# (write to /home/adom/project/birthday_card.html)

# 2. Start server (if not already running)
python3 -c "import http.server,os; os.chdir('/home/adom/project'); http.server.HTTPServer(('0.0.0.0',36199),http.server.SimpleHTTPRequestHandler).serve_forever()" &

# 3. Build proxy URL
PROXY_URL=$(echo "$VSCODE_PROXY_URI" | sed 's/{{port}}/36199/')
FULL_URL="${PROXY_URL}birthday_card.html"

# 4. TEST before opening — never skip this
curl -s -o /dev/null -w "%{http_code}" "$FULL_URL"
# Must be 200. If not, debug before proceeding.

# 5. Open webview
adom-cli hydrogen webview open-or-refresh \
  --name "Birthday Card" \
  --url "$FULL_URL" \
  --panel-id <panel-id>

# 6. Screenshot and visually verify before telling the user it's ready
adom-cli hydrogen screenshot panel --panel-id <panel-id> -o /tmp/webview-verify.png
# Read the PNG — confirm it looks correct
# If broken: fix, refresh, screenshot again
# If correct: tell the user their card is ready
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Webview shows blank/error | Used `file://` or `localhost` URL | Rebuild URL with `$VSCODE_PROXY_URI` |
| "Address already in use" | Server already running on that port | It's fine — the server is still serving |
| 404 in webview | Wrong path relative to server root | Check `os.chdir()` matches your file location |
| Tab created but nothing renders | Server not started | Start the HTTP server first, verify with curl |

---

## Key Facts

- `$VSCODE_PROXY_URI` is always available in every LCS container
- The proxy URL format: `https://<container-hostname>/proxy/<port>/`
- Port 36199 is the LCS default for serving app/content files
- The webview tab persists across refreshes — use `--name` as the stable handle
- For panel-id: use `adom-cli hydrogen workspace tabs` to find a leaf panel
