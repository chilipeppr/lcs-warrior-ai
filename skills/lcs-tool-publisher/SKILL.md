---
name: lcs-tool-publisher
description: >
  Use when the user wants to publish a CLI tool or skill to the LCS Wiki for
  discovery and use by students and teachers. Covers the full lifecycle: build the
  tool, publish the wiki page with metadata, and make it accessible. Trigger words:
  publish tool, publish to LCS wiki, make tool available, distribute tool, release
  tool, publish to wiki, share tool with school.
---

# Publishing Tools to the LCS Wiki

This skill covers the **full lifecycle** for making a CLI tool or app discoverable
and usable by any LCS student or teacher — without requiring them to have any
special access beyond their school account.

## Public vs Private: The Line

Every wiki-published tool has a **public side** and optionally a **private side**:

- **Public (wiki-hosted):** the tool files, usage docs, the SKILL.md,
  screenshots, and install instructions. Anyone at LCS can see and use it by
  visiting `https://lcs-wiki-bpd1iwhcgswk.adom.cloud/apps/<slug>`.
- **Private (optional):** source code in a private repo, API keys, teacher-only
  admin tools. Keep these separate from the public wiki page.

**What this means when you publish:**

- Build the tool and verify it works
- Upload it to the wiki
- Set clear install/access instructions
- **Do not require special credentials for student access.** The access flow must
  work end-to-end from the wiki alone.

## Architecture

```text
Tool Source (local directory or private repo)
    |  build + test
    v
LCS Wiki (apps/<slug>)
    |  - hosted tool files
    |  - discovery metadata
    |  - install instructions
    v
Student/Teacher Container
    |  installs from wiki
    v
Working tool on their machine
```

## Prerequisites

Before publishing, you need:
1. A working tool (see `lcs-cli-design` skill for CLI conventions)
2. A SKILL.md describing the tool
3. Screenshots or a demo (if the tool has a visual surface)
4. Clear install instructions

## Step 1: Build the Tool

Follow the `lcs-cli-design` skill. Key requirements:

- `OK:` / `ERROR:` output format
- Health check if it talks to a server
- Works on student Chromebooks (if web-based)
- School-appropriate content at all times

## Step 2: Prepare Wiki Assets

Create the necessary files for publishing:

```bash
# Tool directory structure
lcs-{tool}/
  SKILL.md           # skill file
  icon.svg           # tool icon (Warriors gold #C5A44E)
  screenshot.png     # at least one screenshot
  README.md          # brief description for the wiki page
```

## Step 3: Publish to the LCS Wiki

```bash
# Upload the tool files
adom-wiki asset upload apps/lcs-{tool} \
  --asset-type docker_binary \
  --file ./lcs-{tool} \
  --caption "LCS tool binary"

# Publish the wiki page
adom-wiki page publish "apps/lcs-{tool}" \
  --title "LCS {Tool Name}" \
  --brief "Brief description of what the tool does" \
  --body-md ./README.md \
  --changelog "Initial publish" \
  --sample-prompt "Use {tool name}" \
  --sample-prompt "Run {tool name}" \
  --sample-prompt "Help with {tool name}"
```

**Wiki URL:** `https://lcs-wiki-bpd1iwhcgswk.adom.cloud`

## Step 4: Upload Screenshots

Every tool with a visual surface needs screenshots on its wiki page:

```bash
adom-wiki asset upload apps/lcs-{tool} \
  --asset-type screenshot \
  --file ./screenshot.png \
  --caption "Main interface showing..."
```

## Updating a Published Tool

To release a new version:

```bash
# 1. Build the new version
# 2. Upload the new files to the wiki
adom-wiki asset upload apps/lcs-{tool} \
  --asset-type docker_binary \
  --file ./lcs-{tool} \
  --caption "v0.2.0"

# 3. Update the wiki page with the new version
adom-wiki page publish "apps/lcs-{tool}" \
  --title "LCS {Tool Name}" \
  --brief "Updated description" \
  --body-md ./README.md \
  --changelog "What changed in this version"
```

## Checklist

Before publishing:

- [ ] Tool builds and runs correctly
- [ ] `--version` prints a version number
- [ ] Health check works (if applicable)
- [ ] SKILL.md is complete with examples
- [ ] At least one screenshot (for visual tools)
- [ ] Install instructions are clear and tested
- [ ] Content is school-appropriate
- [ ] Works on student Chromebooks (if web-based)
- [ ] Published to wiki and accessible
- [ ] End-to-end install tested from a fresh container

## Related Skills

- `lcs-cli-design` — CLI conventions
- `lcs-skill-creator` — How to write SKILL.md files
- `lcs-app-model` — How LCS apps are structured
