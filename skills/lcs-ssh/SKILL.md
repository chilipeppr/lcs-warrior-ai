---
name: lcs-ssh
description: "SSH into LCS containers for students and teachers. Use when a student needs to access their development container, deploy a project, or run commands remotely. Covers key generation, connection basics, and common workflows. Simplified for school use. Triggers: SSH into container, connect to container, remote access, run command on container, deploy project, access my container."
---

# LCS SSH Connection Guide

End-to-end guide for SSH access to LCS containers. Students and teachers can connect to their containers from Chromebooks or laptops.

## Architecture

All LCS containers are accessible via SSH through a centralized gateway:

```text
Your Chromebook/Laptop --SSH--> adom.cloud:22 --routes--> Your Container
                                (gateway)
```

The gateway routes connections based on the SSH username:

```bash
ssh <owner>-<repo>-<slug>@adom.cloud
```

## Prerequisites: SSH Keys

SSH requires two things:
1. A **private key** on the machine you're connecting FROM
2. The matching **public key** registered with your account

**One key works for all your containers.** You don't need separate keys for each one.

### Setting Up Your SSH Key (First Time)

```bash
# Check if you already have a key
ls ~/.ssh/id_ed25519

# If no key exists, generate one
ssh-keygen -t ed25519 -C "lcs-student" -f ~/.ssh/id_ed25519 -N ""

# Register it with your account
adom-cli carbon user ssh-key-add --display-name "My Chromebook" "$(cat ~/.ssh/id_ed25519.pub)"
```

### Verify Your Key Is Registered

```bash
# Your local key fingerprint
ssh-keygen -lf ~/.ssh/id_ed25519.pub

# Keys registered with your account
adom-cli carbon user ssh-keys
```

## Finding Your Container's SSH Info

### List all your containers

```bash
adom-cli carbon containers list
```

Each container has an `ssh_credentials` field with the connection command.

### Get a specific container

```bash
adom-cli carbon containers get <slug>
```

## Connecting

### Interactive session

```bash
ssh username-repo-slug@adom.cloud
```

For first connection (auto-accept host key):

```bash
ssh -o StrictHostKeyChecking=accept-new username-repo-slug@adom.cloud
```

### Run a single command

```bash
ssh username-repo-slug@adom.cloud "ls -la /home/adom/"
```

### Copy files

```bash
# Upload a file to your container
scp ./my-project.zip username-repo-slug@adom.cloud:/home/adom/

# Download a file from your container
scp username-repo-slug@adom.cloud:/home/adom/output.pdf ./
```

## Common Student Workflows

### Check if your project server is running

```bash
ssh username-repo-slug@adom.cloud "curl -sf http://127.0.0.1:8080/health"
```

### Deploy your project

```bash
ssh username-repo-slug@adom.cloud "cd ~/project && git pull && npm install && npm start"
```

### View project logs

```bash
ssh username-repo-slug@adom.cloud "tail -50 /tmp/project.log"
```

### SSH config for convenience

Add to `~/.ssh/config` for shorter commands:

```text
Host myproject
    HostName adom.cloud
    User username-repo-slug
    IdentityFile ~/.ssh/id_ed25519
```

Then just: `ssh myproject`

## Chromebook SSH

Chromebooks can use the built-in Linux terminal (Crostini) or the Secure Shell extension:

1. **Linux terminal (recommended):** Enable Linux in Chromebook settings, then use `ssh` normally
2. **Secure Shell extension:** Install from Chrome Web Store, enter hostname `adom.cloud`, username, and import your key

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| "Permission denied (publickey)" | No SSH key registered | Run the key setup steps above |
| "Could not connect to your container" | Container not created with `--ssh` | Ask LCS IT to recreate with SSH enabled |
| "Connection refused" | Container not running | Check with `adom-cli carbon containers get <slug>` |
| "Connection timed out" | Network issue | Check your internet connection; try again in 30 seconds |
| "Host key verification failed" | Known hosts conflict | `ssh-keygen -R adom.cloud` and retry |
| Works on one device but not another | Different key on each device | Register a key on each device |
