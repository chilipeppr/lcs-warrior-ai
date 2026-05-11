---
name: lcs-cache-busting
description: "Why webview content goes stale and how to fix it. Covers the three caching layers in LCS containers: Cloudflare edge, browser heuristic cache, and Python HTTP server defaults. Use when content looks stale, old versions keep appearing, or refreshes don't pick up changes. Trigger words: cache, stale, old version, not updating, still showing old, refresh not working, cache bust, why is it cached."
user-invocable: false
---

# LCS Cache Busting — Why Content Goes Stale and How to Fix It

When you edit a file and refresh the webview but the old version keeps showing up, here's why — and how to fix it at every layer.

## The Three Caching Layers

Requests flow through three layers, each of which can serve stale content:

```text
[1] Browser/Webview Cache (most common culprit)
        ↓
[2] Cloudflare Edge (DISABLED — but know why)
        ↓
[3] Origin HTTP Server (Python SimpleHTTPServer quirks)
```

---

## Layer 1: Browser Cache (The Usual Suspect)

**This is almost always the problem.**

Python's `SimpleHTTPServer` sends a `Last-Modified` header but does NOT send `Cache-Control` headers. Without explicit `Cache-Control: no-cache`, the browser applies **heuristic freshness** — it decides on its own how long to cache the response (often 10% of the time since `Last-Modified`, which can be minutes or hours).

### Symptoms
- You edit the HTML file, refresh the webview, and see the OLD content
- `curl` shows the new content but the webview shows the old
- Hard-refreshing (Ctrl+Shift+R) fixes it but normal refresh doesn't

### Fix: Use a No-Cache HTTP Server

Instead of bare `python3 -m http.server`, use this server that sends proper `Cache-Control: no-cache` headers:

```bash
python3 -c "
import http.server, os

class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

os.chdir('/home/adom/project')
http.server.HTTPServer(('0.0.0.0', 36199), NoCacheHandler).serve_forever()
" &
```

This tells the browser: "Never cache this. Always ask the origin."

### Fix: Query String Cache-Bust (Quick and Dirty)

Append a unique query string to force the browser to treat it as a new URL:

```bash
PROXY_URL=$(echo "$VSCODE_PROXY_URI" | sed 's/{{port}}/36199/')
FULL_URL="${PROXY_URL}my-file.html?v=$(date +%s)"
```

The `?v=1715367000` changes every second, so the browser can't match it to a cached response. Use this when iterating rapidly on a file.

### Fix: Navigate Instead of Refresh

`adom-cli hydrogen webview open-or-refresh` with a new `--url` (including a new query param) is more reliable than `adom-cli hydrogen webview refresh`, because refresh may serve from browser cache while navigate with a new URL forces a fresh fetch.

---

## Layer 2: Cloudflare Edge (Currently Disabled)

Cloudflare sits between the browser and your container. All `*.adom.cloud` traffic flows through Cloudflare's DFW edge.

**Current status: Edge caching is OFF.** All responses return `cf-cache-status: DYNAMIC`, meaning Cloudflare passes every request straight through to your container without caching.

### How to verify

```bash
PROXY_URL=$(echo "$VSCODE_PROXY_URI" | sed 's/{{port}}/36199/')
curl -sI "${PROXY_URL}my-file.html" | grep -i "cf-cache-status"
# Should show: cf-cache-status: DYNAMIC
```

- `DYNAMIC` = not cached at edge (good for development)
- `HIT` = served from Cloudflare cache (would need purging)
- `MISS` = not in cache, fetched from origin (first request)
- `EXPIRED` = was cached, now stale, re-fetched

### If Cloudflare caching is ever re-enabled

If you see `cf-cache-status: HIT` and content is stale, the only reliable fix is:
1. Query string cache-bust: `?v=$(date +%s)` — Cloudflare treats each unique URL as a separate cache entry
2. Ask an admin to purge the Cloudflare cache for that URL

### Useful Cloudflare headers for debugging

```bash
curl -sI "${PROXY_URL}my-file.html" 2>/dev/null | grep -iE "cf-cache|cf-ray|cache-control|last-modified|etag"
```

| Header | Meaning |
|--------|---------|
| `cf-cache-status: DYNAMIC` | Not cached at edge (normal) |
| `cf-ray: abc123-DFW` | Unique request ID + data center |
| `last-modified: ...` | When origin file was last changed |
| No `cache-control` | Browser will use heuristic caching |
| No `etag` | No conditional request support |

---

## Layer 3: Origin HTTP Server

Python's `SimpleHTTPServer` (and `http.server`) has specific behaviors that interact with caching:

### What it sends
- `Last-Modified` header (based on file mtime) — **causes heuristic caching**
- `Content-Type` based on file extension
- No `Cache-Control` header
- No `ETag` header

### What it doesn't do
- Does NOT support `If-Modified-Since` conditional requests properly
- Does NOT send `Cache-Control` headers
- Does NOT support gzip/compression
- Is single-threaded (one request at a time)

### Impact
The `Last-Modified` header without `Cache-Control` is the root cause of most stale content issues. The browser sees `Last-Modified`, calculates heuristic freshness, and decides to serve from cache without asking the server.

---

## Quick Reference: The Right Pattern

When serving content for webview during development/iteration:

```bash
# 1. Start a NO-CACHE server (not bare http.server)
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

# 2. Build proxy URL with cache-bust param
PROXY_URL=$(echo "$VSCODE_PROXY_URI" | sed 's/{{port}}/36199/')
FULL_URL="${PROXY_URL}my-file.html?v=$(date +%s)"

# 3. Open or refresh webview
adom-cli hydrogen webview open-or-refresh \
  --name "My App" \
  --url "$FULL_URL" \
  --panel-id <panel-id>
```

Using BOTH the no-cache server AND query string cache-bust is belt-and-suspenders — either one alone usually works, but together they guarantee fresh content every time.

---

## Troubleshooting

| Symptom | Layer | Fix |
|---------|-------|-----|
| Webview shows old content after edit | Browser cache | Use no-cache server + `?v=$(date +%s)` |
| `curl` shows new content but webview shows old | Browser cache | Navigate with new URL instead of refresh |
| `cf-cache-status: HIT` | Cloudflare edge | Add `?v=$(date +%s)` or ask admin to purge |
| Content updates after hard refresh (Ctrl+Shift+R) but not soft refresh | Browser heuristic cache | Add `Cache-Control: no-cache` to server |
| First load works, subsequent loads stale | Browser caching `Last-Modified` | Use no-cache server |
| Different content on different devices | Per-device browser cache | Each device has independent cache; normal |

---

## For the `lcs-webview` Skill

When following the `lcs-webview` pattern, always prefer the no-cache server over bare `python3 -m http.server`. The webview skill's Step 2 (start HTTP server) should use the `NoCacheHandler` pattern above when iterating on content.
