---
name: lcs-gchat
description: >
  Post to Google Chat from the LCS container. Webhook-based, school-
  customizable. Spaces are #teachers, #students, #parents, #strive-center.
  Students post project updates, teachers share resources.
  Trigger words: gchat, google chat, post to chat, team notification,
  chat webhook, post to teachers, send message to space, chat alert,
  announce to class, notify teachers, notify students, strive-center,
  post to strive-center, post to parents.
---

# lcs-gchat — Google Chat CLI for LCS

Post messages to Google Chat spaces from the LCS container. Webhook-
based, no OAuth needed. Configured for Liberty Christian School spaces.

## Install

```
Install lcs-gchat. Download from
https://lcs-wiki-bpd1iwhcgswk.adom.cloud/static/apps/lcs-gchat/lcs-gchat
-> /tmp/lcs-gchat, chmod +x, sudo install to /usr/local/bin/lcs-gchat,
then run `lcs-gchat install` to deploy the skill + bash completions.
Verify with `lcs-gchat spaces`.
```

## Spaces

LCS uses four primary Google Chat spaces:

| Space | Audience | Use for |
|-------|----------|---------|
| `#teachers` | Faculty and staff | Resource sharing, curriculum updates, admin announcements |
| `#students` | Students | Project updates, assignment reminders, club announcements |
| `#parents` | Parents and guardians | School events, grade notifications, volunteer opportunities |
| `#strive-center` | STRIVE Center participants | Innovation lab updates, 3D printing queue, robotics team, project showcases |

## Usage

```bash
# Send a message
lcs-gchat send --space teachers "Parent-teacher conference schedule posted"

# Post a student project update
lcs-gchat send --space strive-center "New 3D printing project completed by robotics team"

# Threaded reply
lcs-gchat send --space students --thread science-fair "Reminder: abstracts due Friday"

# List configured spaces
lcs-gchat spaces

# Check connectivity
lcs-gchat health

# Set up spaces (interactive)
lcs-gchat setup
```

## Setting up spaces

1. Create a webhook in Google Chat: Space settings > Apps & integrations > Webhooks
2. Run `lcs-gchat setup` and paste the webhook URL
3. Test with `lcs-gchat send --space <name> "hello from LCS"`

## Attribution

Every message is prefixed with who sent it:
`*LCS (on behalf of username)* message text`

Customize the template during setup or in
`~/.config/gchat-webhooks.json` -> `attribution` field.

## Security

- Webhook URLs are secrets -- never commit them to git or paste in chat
- The CLI never leaks container slugs or hostnames in messages
- `--space` is required -- no default space to prevent accidental posts
