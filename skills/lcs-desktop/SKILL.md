---
name: lcs-desktop
description: Use when a student or teacher wants to connect their Chromebook or laptop to their LCS cloud container. Enables file transfer, browser automation, desktop notifications, and remote app control. Simplified for school use. Trigger words: connect desktop, desktop bridge, access my laptop, send files, desktop connection, chromebook bridge, connect my computer, lcs-desktop.
---

# LCS Desktop — Cloud-to-Device Bridge

LCS Desktop bridges Claude Code (running in the cloud container) with the student's or teacher's Chromebook or laptop via WebSocket. It enables:

- **File transfer**: Send files between the cloud container and the local device
- **Browser automation**: Open web pages, take screenshots, navigate URLs
- **Notifications**: Send desktop notifications for task completion, reminders
- **Shell**: Execute commands on the local machine (with appropriate permissions)

## Step 1: Check if Already Installed

```bash
which lcs-desktop 2>/dev/null && lcs-desktop --version
```

**If installed** — the full operational skill is at `~/.claude/skills/lcs-desktop/SKILL.md`. Read that file for the complete command reference. Then verify the connection:

```bash
if ! curl -sf http://127.0.0.1:8766/health >/dev/null 2>&1; then
  nohup lcs-desktop serve > /tmp/lcs-desktop-relay.log 2>&1 &
  disown
  for _ in 1 2 3 4 5 6; do
    sleep 0.5
    curl -sf http://127.0.0.1:8766/health >/dev/null 2>&1 && break
  done
fi
lcs-desktop ping
```

## Step 2: Ask the Student/Teacher

Before installing, confirm they need desktop integration:

> "LCS Desktop lets me send files to your Chromebook, open web pages, and send notifications. Want me to set it up? It takes about 2 minutes."

- If **yes** — continue to Step 3
- If they just need to work in the cloud container — no desktop bridge needed

## Step 3: Install the Bridge

Download and install:

```bash
# Download from LCS Wiki
curl -fsSL https://lcs-wiki-bpd1iwhcgswk.adom.cloud/static/apps/lcs-desktop/lcs-desktop \
  -o /tmp/lcs-desktop
sudo mv /tmp/lcs-desktop /usr/local/bin/lcs-desktop
sudo chmod +x /usr/local/bin/lcs-desktop

# Run the self-installer
lcs-desktop install
```

This deploys the skill and starts the relay server.

## Step 4: Connect the Device

Run `lcs-desktop setup_desktop` to get connection instructions.

**For Chromebooks:**
1. Download the connector extension from the provided URL
2. Enter the connection JSON in the extension settings
3. Wait for the green indicator

**For Windows/Mac laptops:**
1. Download the desktop app from the provided URL
2. Run the installer
3. Paste the server JSON into the Quick Add bar
4. Wait for the green dot

## Step 5: Verify

```bash
lcs-desktop ping
# Expected: { "echo": "pong", "roundTripMs": ..., "status": "connected" }

lcs-desktop status
# Shows connected client info
```

## Common Student Workflows

| Task | Command |
|------|---------|
| Send a file to your device | `lcs-desktop send /home/adom/project/report.pdf` |
| Open a web page | `lcs-desktop browser open "https://lcs-wiki-bpd1iwhcgswk.adom.cloud"` |
| Send a notification | `lcs-desktop notify "Build complete!" --body "Your project is ready"` |
| Take a screenshot | `lcs-desktop screenshot` |

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| "No desktop client connected" | Make sure the desktop app is running on your device |
| "Cannot reach relay server" | Run `lcs-desktop serve` to start the relay |
| File transfer fails | Check that the file path is correct and the file exists |
| Browser won't open | Make sure the desktop app has browser automation permissions |
