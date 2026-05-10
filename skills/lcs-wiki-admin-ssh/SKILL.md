---
name: lcs-wiki-admin-ssh
description: >
  Admin-only skill: How to SSH into the LCS Wiki container to modify
  server-side templates, CSS, JS, and other wiki internals. Requires
  an SSH key registered with Carbon.
---

# LCS Wiki Admin SSH Access

**Admin only** — this skill is not for students or teachers.

## Wiki Container

The LCS Wiki runs on its own Adom container:

- **Container slug:** `kvwm964iay74`
- **SSH command:** `ssh john-lcs-kvwm964iay74@adom.cloud`
- **Public hostname:** `lcs-wiki-bpd1iwhcgswk.adom.cloud`
- **Internal port:** 8785
- **Image:** `default-light`
- **Repo:** `john/lcs`

## SSH Setup (from another Adom container)

Adom containers don't come with SSH keys. You must generate one and register it with Carbon:

```bash
# 1. Generate an ed25519 key (no passphrase)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -q

# 2. Register it with Carbon via adom-cli
adom-cli carbon user ssh-key-add \
  --display-name "$(hostname)-container" \
  "$(cat ~/.ssh/id_ed25519.pub)"

# 3. SSH in (first time needs StrictHostKeyChecking=no)
ssh -o StrictHostKeyChecking=no john-lcs-kvwm964iay74@adom.cloud 'echo connected'
```

After the key is registered, SSH works immediately — no server restart needed.

## Wiki File Locations

Once SSH'd in, the wiki code lives at `/home/adom/wiki/`:

| Path | Purpose |
|------|---------|
| `lib/templates.js` | All server-side HTML templates (page detail, file explorer, activity, etc.) |
| `static/wiki.css` | Global stylesheet |
| `static/wiki.js` | Client-side JavaScript (toggle, search, etc.) |
| `server.js` | Express server entry point |
| `lib/` | Backend modules (routes, API, auth, etc.) |

## Restarting the Wiki

After modifying files, restart the Node process:

```bash
# Find the wiki process
ssh john-lcs-kvwm964iay74@adom.cloud 'ps aux | grep "node server" | grep -v grep'

# Kill and restart (it runs from /home/adom/wiki)
ssh john-lcs-kvwm964iay74@adom.cloud 'PID=$(pgrep -f "node server.js") && kill $PID && sleep 1 && cd /home/adom/wiki && nohup node server.js > /tmp/wiki.log 2>&1 &'
```

Verify it came back:
```bash
curl -sf https://lcs-wiki-bpd1iwhcgswk.adom.cloud/health
```

## Finding Container Info

If the container slug changes, look it up:

```bash
adom-cli carbon containers list 2>&1 | python3 -c "
import json,sys
for c in json.load(sys.stdin):
    if 'lcs' in c.get('default_hostname','').lower() and 'sample' not in c.get('default_hostname','').lower():
        print(c['ssh_credentials']['command'])
"
```

## Important

- **NEVER** modify wiki files without understanding the change — templates.js is the entire UI
- **Always** verify the wiki comes back after restart (`curl` the health endpoint)
- **Port forwarding must stay enabled** — see lcs-bootstrap skill for details
- Changes to `templates.js` require a server restart; changes to `static/` files are served immediately
