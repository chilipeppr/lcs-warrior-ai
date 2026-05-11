---
name: lcs-wiki-admin
description: Wiki administration for the LCS IT department. Covers wiki health monitoring, user management, page moderation, backup procedures, adding authorized emails, restarting the wiki server, and checking logs. Use when managing the LCS Wiki infrastructure. Server is at john-lcs-kvwm964iay74@adom.cloud. Trigger words: wiki admin, wiki health, wiki users, wiki moderation, wiki backup, wiki restart, wiki logs, add wiki email, wiki server, lcs wiki management, wiki additional emails, wiki troubleshooting.
---

# LCS Wiki Administration

Management guide for the LCS Wiki infrastructure. The wiki serves as the central hub for LCS apps, study guides, teacher resources, and student projects.

## Server Details

| Property | Value |
|----------|-------|
| **Wiki URL** | `https://lcs-wiki-bpd1iwhcgswk.adom.cloud` |
| **SSH** | `ssh john-lcs-kvwm964iay74@adom.cloud` |
| **Startup script** | `/home/adom/start-lcs-wiki.sh` |
| **Log location** | `/tmp/lcs-wiki.log` (primary), `journalctl` for systemd |

## Health Monitoring

### Quick Health Check

```bash
# From any LCS container
curl -sf https://lcs-wiki-bpd1iwhcgswk.adom.cloud/health | python3 -m json.tool
```

Expected response:
```json
{
  "ok": true,
  "service": "lcs-wiki",
  "uptime": 12345,
  "version": "X.Y.Z",
  "pages": 42,
  "users": 15
}
```

### Detailed Status Check

```bash
# SSH into the wiki server
ssh john-lcs-kvwm964iay74@adom.cloud

# Check process status
ps aux | grep -i wiki

# Check disk usage
df -h /home/adom

# Check memory
free -h

# Check recent logs
tail -100 /tmp/lcs-wiki.log
```

### Monitoring Checklist (Run Weekly)

```bash
# 1. Health endpoint responds
curl -sf https://lcs-wiki-bpd1iwhcgswk.adom.cloud/health

# 2. Disk usage under 80%
ssh john-lcs-kvwm964iay74@adom.cloud "df -h /home/adom | awk 'NR==2{print \$5}'"

# 3. No error spikes in logs
ssh john-lcs-kvwm964iay74@adom.cloud "grep -c ERROR /tmp/lcs-wiki.log"

# 4. All pages accessible
curl -sf https://lcs-wiki-bpd1iwhcgswk.adom.cloud/api/v1/pages | python3 -c "import sys,json; pages=json.load(sys.stdin); print(f'{len(pages)} pages OK')"
```

## User Management

### Adding Authorized Emails

Students and teachers access the wiki through their @mylcs.com Google accounts. To authorize additional email addresses (guest speakers, parent volunteers, admin staff with non-@mylcs.com emails):

```bash
# SSH into the wiki server
ssh john-lcs-kvwm964iay74@adom.cloud

# Add an email to the additional-emails.txt file
echo "guest.speaker@gmail.com" >> /home/adom/additional-emails.txt

# Verify it was added
cat /home/adom/additional-emails.txt
```

The `additional-emails.txt` file contains one email per line. These emails can access the wiki alongside @mylcs.com accounts.

### Listing Current Users

```bash
# Via API
curl -sf https://lcs-wiki-bpd1iwhcgswk.adom.cloud/api/v1/users | python3 -m json.tool

# View additional emails
ssh john-lcs-kvwm964iay74@adom.cloud "cat /home/adom/additional-emails.txt"
```

### Removing User Access

```bash
# SSH in and edit the additional-emails file
ssh john-lcs-kvwm964iay74@adom.cloud

# Remove a specific email (careful with this)
sed -i '/guest.speaker@gmail.com/d' /home/adom/additional-emails.txt
```

For @mylcs.com accounts, deactivation happens through Google Workspace admin (the school's IT admin console), not through the wiki directly.

## Page Moderation

### Review Recent Changes

```bash
# List recently modified pages
curl -sf https://lcs-wiki-bpd1iwhcgswk.adom.cloud/api/v1/pages?sort=updated_at&order=desc&limit=20 \
  | python3 -c "
import sys, json
pages = json.load(sys.stdin)
for p in pages[:20]:
    print(f\"{p.get('updated_at', 'unknown')[:10]}  {p.get('slug', '?')}  by {p.get('author_name', '?')}\")
"
```

### Check Page Content

```bash
# View a specific page
curl -sf "https://lcs-wiki-bpd1iwhcgswk.adom.cloud/api/v1/pages/<slug>" | python3 -m json.tool
```

### Remove Inappropriate Content

If a page contains non-school-appropriate content:

```bash
# Delete the page
curl -sf -X DELETE "https://lcs-wiki-bpd1iwhcgswk.adom.cloud/api/v1/pages/<slug>" \
  -H "Authorization: Bearer $WIKI_AUTH_TOKEN"
```

**Always document why content was removed** in case questions arise from students or teachers.

## Server Management

### Restarting the Wiki Server

```bash
# SSH into the server
ssh john-lcs-kvwm964iay74@adom.cloud

# Run the startup script (handles graceful restart)
bash /home/adom/start-lcs-wiki.sh
```

The startup script is idempotent — it stops any existing instance before starting a new one.

### Checking Logs

```bash
# View recent logs
ssh john-lcs-kvwm964iay74@adom.cloud "tail -100 /tmp/lcs-wiki.log"

# Search for errors
ssh john-lcs-kvwm964iay74@adom.cloud "grep ERROR /tmp/lcs-wiki.log | tail -20"

# Watch logs in real time
ssh john-lcs-kvwm964iay74@adom.cloud "tail -f /tmp/lcs-wiki.log"
```

### Common Log Patterns

| Pattern | Meaning | Action |
|---------|---------|--------|
| `ERROR: ENOSPC` | Disk full | Clean up old assets, expand storage |
| `ERROR: ECONNREFUSED` | Database connection failed | Restart the wiki |
| `WARN: rate limit` | Too many requests | Usually self-resolves; check for bots |
| `ERROR: auth failed` | Invalid token or expired session | Check user's Google account status |

## Backup Procedures

### Manual Backup

```bash
# SSH into the wiki server
ssh john-lcs-kvwm964iay74@adom.cloud

# Create a timestamped backup
BACKUP_DIR="/home/adom/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup the database
cp /home/adom/wiki-data/wiki.db "$BACKUP_DIR/wiki.db"

# Backup uploaded assets
cp -r /home/adom/wiki-data/assets "$BACKUP_DIR/assets"

# Backup configuration
cp /home/adom/additional-emails.txt "$BACKUP_DIR/additional-emails.txt"
cp /home/adom/start-lcs-wiki.sh "$BACKUP_DIR/start-lcs-wiki.sh"

echo "Backup complete: $BACKUP_DIR"
ls -lh "$BACKUP_DIR"
```

### Backup Schedule (Recommended)

| Frequency | What | Retention |
|-----------|------|-----------|
| Daily | Database (`wiki.db`) | 7 days |
| Weekly | Full backup (DB + assets + config) | 4 weeks |
| Monthly | Full backup archived | 6 months |

### Restore from Backup

```bash
# SSH into the wiki server
ssh john-lcs-kvwm964iay74@adom.cloud

# Stop the wiki
# (find and kill the wiki process first)
ps aux | grep wiki | grep -v grep
kill <PID>

# Restore from backup
cp /home/adom/backups/<timestamp>/wiki.db /home/adom/wiki-data/wiki.db
cp -r /home/adom/backups/<timestamp>/assets /home/adom/wiki-data/assets

# Restart
bash /home/adom/start-lcs-wiki.sh
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Wiki not loading | Server process crashed | SSH in and run `bash /home/adom/start-lcs-wiki.sh` |
| 502 Bad Gateway | Server process running but unhealthy | Check logs, restart if needed |
| Slow page loads | Database needs vacuuming or disk is full | SSH in: `sqlite3 wiki.db "VACUUM;"` or clean up old assets |
| Students can't log in | Google OAuth misconfigured or account issue | Check Google Workspace admin; verify @mylcs.com domain |
| Assets not loading | File permissions or disk full | Check `ls -la /home/adom/wiki-data/assets/` and `df -h` |
| Search not working | Search index needs rebuild | Restart the wiki server |

## Emergency Contacts

If the wiki is down and you cannot resolve it:
1. Check the server health via SSH
2. Try restarting with the startup script
3. Contact the Adom platform administrator for container-level issues
