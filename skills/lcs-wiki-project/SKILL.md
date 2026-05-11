---
name: lcs-wiki-project
description: >
  Download, modify, and re-publish source code projects on the Warriors Wiki.
  Use when the user wants to get a project's source code, fork a tool, publish
  changes, or browse available projects. Trigger words: project source, download
  source, get source code, fork project, publish source, project history, lcs-wiki
  project, browse projects, modify source, build from source.
---

# LCS Wiki Projects — Source Code Management

The Warriors Wiki stores source code as versioned tarballs. Students and teachers
download, modify with Claude's help, and re-publish — no git or GitHub needed.

## CLI Commands

```bash
# List all projects
lcs-wiki project list

# Download a project's source code
lcs-wiki project get lcs-wiki-cli
cd lcs-wiki-cli/
# ... source code is extracted here

# Modify with Claude, then publish changes
lcs-wiki project publish lcs-wiki-cli . --changelog "Added student role checks"

# See version history
lcs-wiki project history lcs-wiki-cli
```

## Workflow for Students

1. **Browse:** `lcs-wiki project list` — see what's available
2. **Download:** `lcs-wiki project get <slug>` — extracts to `./<slug>/`
3. **Explore:** Read the code with Claude's help ("explain this file", "what does this function do")
4. **Modify:** Ask Claude to add features, fix bugs, or customize behavior
5. **Build:** Follow the project's build instructions (e.g. `cargo build --release` for Rust)
6. **Test:** Run the modified tool locally
7. **Publish:** `lcs-wiki project publish <slug> . --changelog "what I changed"` — uploads new version

## Version History

Each publish creates a new tarball version. Old versions are preserved — you can
always go back. Every publish requires a changelog entry explaining what changed.

```bash
lcs-wiki project history lcs-shotlog
# Shows all versions with changelogs, dates, and download URLs
```

## Available Projects

Check the wiki for current projects: https://lcs-wiki-bpd1iwhcgswk.adom.cloud/projects

## Rules

1. **Always include a meaningful changelog** — "fixed stuff" is not acceptable
2. **Don't publish build artifacts** — only source code (exclude `target/`, `node_modules/`, etc.)
3. **Test before publishing** — make sure your changes work
4. **Published source goes through moderation** — teachers approve student submissions
