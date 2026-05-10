---
name: lcs-bootstrap
description: >
  Re-run the LCS Warrior AI bootstrap to update skills, fix configuration,
  or reset the environment. Use when the user says "run bootstrap",
  "update my environment", "reinstall skills", "reset warrior ai",
  "fix my setup", "bootstrap", or "update warrior ai".
---

# LCS Bootstrap

Re-run the Warrior AI bootstrap to update skills, install missing tools, or fix configuration.

## How to run

```bash
curl -fsSL https://lcs-wiki-bpd1iwhcgswk.adom.cloud/static/apps/lcs-bootstrap/bootstrap.sh | bash
```

## What it does

1. Installs/updates Claude Code CLI + extension
2. Configures VS Code settings
3. Downloads all LCS skills from the Warriors Wiki
4. Sets up CLAUDE.md and project directory
5. Verifies wiki connectivity
6. Installs adom-cli and adom-vscode
7. Opens the Warrior AI welcome page

## When to re-run

- After new skills are published to the wiki
- If `adom-cli` or `adom-vscode` are missing
- If VS Code settings got reset
- If the welcome page isn't showing
- If a new user needs to authenticate

## Critical rules for VS Code settings

- **NEVER set `remote.autoForwardPorts: false`**. Port forwarding is essential — apps, previews, and services all depend on it. To suppress the port notification toasts, use `remote.otherPortsAttributes.onAutoForward: "silent"` — this hides the dialog while keeping forwarding fully functional.

## Wiki page

https://lcs-wiki-bpd1iwhcgswk.adom.cloud/apps/lcs-bootstrap
