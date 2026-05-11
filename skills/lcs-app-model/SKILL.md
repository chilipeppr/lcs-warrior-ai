---
name: lcs-app-model
description: Canonical reference for how LCS apps are structured, published, and installed. Use when creating a new LCS app from scratch, deciding how to distribute a school tool, or publishing to the LCS Wiki. Trigger words: LCS app model, how to build an LCS app, LCS app architecture, school app structure, wiki app, publish an LCS app.
---

# LCS App Model

Every LCS app follows the same shape. This skill is the canonical reference for building apps that serve the Liberty Christian School community — study tools, dashboards, STRIVE Center projects, teacher utilities, and student-facing apps.

## The Five Principles

### 1. One directory per app

Each app lives in its own directory with a clear structure:

```text
lcs-{app}/
  VERSION                # "X.Y.Z" — single source of truth
  SKILL.md               # user-facing skill
  index.html             # main app entry point (if web app)
  style.css              # app styles (gold #C5A44E brand)
  app.js                 # app logic
  docs/icon.svg          # Warriors-branded favicon
```

### 2. Publish to the LCS Wiki

Every app is published to the LCS Wiki for discovery and access:

```text
https://lcs-wiki-bpd1iwhcgswk.adom.cloud/apps/lcs-{app}
```

The wiki is the single source of truth for what apps are available. Students and teachers discover apps through the wiki.

### 3. Web-first architecture

LCS apps are web apps that run in a browser tab or Hydrogen webview. This ensures they work on student Chromebooks, teacher laptops, and any device with a browser. No native installs required.

Key constraints:
- Must work on Chromebooks (Chrome browser)
- Must be responsive (phones, tablets, laptops, projectors)
- Must follow LCS brand guidelines (gold #C5A44E, navy #1B2A4A)
- Must be school-appropriate at all times

### 4. Each app has a SKILL.md

Every app ships a skill file so Claude Code knows how to help users with it. The skill covers:
- What the app does
- How to launch it
- Common commands and workflows
- Troubleshooting

### 5. Version numbers track releases

Single source of truth: `VERSION` file. It flows into:
- The wiki page metadata
- The app's about/settings page
- Any health check endpoint

## How the Pieces Fit

```text
 +-----------------------------------------+
 |  lcs-{app}/  (app directory)            |
 |  - index.html, style.css, app.js        |
 |  - SKILL.md                             |
 |  - VERSION                              |
 +------------------+----------------------+
                    |  publish to wiki
                    v
 +-----------------------------------------+
 |  LCS Wiki (apps/lcs-{app})              |
 |  - hosted app files                     |
 |  - discovery metadata                   |
 |  - install/access instructions          |
 +-----------------------------------------+
                    |
      +-------------+-------------+
      |                           |
 +----+------+           +-------+-------+
 | Students  |           | Teachers      |
 | Chromebook|           | Laptop/iPad   |
 +----------+           +---------------+
```

## When You're Starting a New LCS App

1. Use `lcs-app-creator` for code-level conventions (brand, header, layout)
2. Use `lcs-tool-publisher` for the publish checklist
3. Use `lcs-brand` for colors, fonts, and design tokens
4. Follow `lcs-ui-patterns` for UI rules (tooltips, accessibility, responsiveness)

This skill is the "read first" for the big picture; each of those covers its piece in depth.

## Related Skills

- `lcs-app-creator` — code-level conventions (brand, header, responsive layout)
- `lcs-tool-publisher` — the full publish lifecycle to the LCS Wiki
- `lcs-brand` — colors, fonts, spacing tokens
- `lcs-ui-patterns` — non-negotiable UI rules
- `lcs-cli-design` — CLI conventions for any command-line tools
