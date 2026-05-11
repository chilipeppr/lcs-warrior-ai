---
name: lcs-definitions
description: Use when the user asks "what is [term]", "define [term]", "what does [term] mean", "glossary", "definitions", or needs clarification on LCS platform or school terminology. Also use to verify you are using the correct term in conversation or code.
---

# LCS Definitions

Canonical glossary of Liberty Christian School platform terms. Use these definitions consistently in conversation, code, documentation, and wiki content.

## Core Platform

| Term | Definition |
|------|-----------|
| **LCS** | Liberty Christian School, Argyle, Texas. A private Christian school serving Pre-K through 12th grade. |
| **LCS App** (aka **Workspace**) | The full web app: toolbar, panels, VS Code, profile. Internal codename "Hydrogen". "Workspace" emphasizes the persistent panel layout. |
| **Warriors** | LCS school mascot. Used in branding throughout all LCS apps and materials. |
| **Panel** | A rectangular area in the LCS App (Workspace) layout. Panels can be split, resized, moved, and closed. |

## School Spaces

| Term | Definition |
|------|-----------|
| **STRIVE Center** | Science, Technology, Research, Innovation, Virtual Learning, and Entrepreneurship. The 4,000 sq ft innovation lab at LCS. Director: Jamie Michalek. |
| **TAPPS** | Texas Association of Private and Parochial Schools. LCS competes in TAPPS athletics and academics. |
| **Chapel** | Weekly school-wide worship gathering. Mandatory for all students. |
| **Fine Arts** | Band, choir, theatre, dance programs at LCS. |

## LCS Wiki Content Types

| Term | Definition |
|------|-----------|
| **Course** | A course page on the LCS Wiki with syllabus, resources, assignments, and study materials. |
| **Flashcard** | A flashcard deck for study -- vocabulary, formulas, key concepts. Published to the LCS Wiki. |
| **Strive Project** | A STRIVE Center project page -- 3D printing, robotics, electronics, entrepreneurship. |
| **Resource** | General educational resource -- study guide, reference sheet, tutorial. |
| **Skill** | A SKILL.md document that teaches Claude Code how to perform a specialized task for LCS. |

## Apps and Tools

| Term | Definition |
|------|-----------|
| **lcs-wiki** | CLI for the LCS Wiki at `https://lcs-wiki-bpd1iwhcgswk.adom.cloud`. Search, publish, manage school content. |
| **lcs-gchat** | CLI for posting to LCS Google Chat spaces (#teachers, #students, #parents, #strive-center). |
| **pup** | Puppeteer browser control. Opens/closes Chrome windows, reloads pages, takes screenshots. Always lowercase. |
| **shotlog** | Screenshot log viewer and injector. Always lowercase. |

## URLs

| URL Pattern | What it is |
|-------------|-----------|
| `https://lcs-wiki-bpd1iwhcgswk.adom.cloud` | LCS Wiki -- school content hub |
| `https://hydrogen.adom.inc/{owner}/{repo}/edit` | Editor -- the full LCS App (Workspace) with panels and VS Code |

## Brand

| Term | Definition |
|------|-----------|
| **Navy** | Primary brand color `#002855`. Used for backgrounds, headers, primary buttons. |
| **Gold** | Accent brand color `#C5A44E`. Used for highlights, active states, links, Warriors shield. |
| **Warriors Shield** | The LCS logo mark -- a shield with a "W". Used in app headers and branding. |

## Academic

| Term | Definition |
|------|-----------|
| **AP** | Advanced Placement -- college-level courses offered at LCS. |
| **Honors** | Advanced-track courses with weighted GPA. |
| **GPA** | Grade Point Average. LCS uses a 4.0 weighted scale for honors/AP. |
| **Conrad Challenge** | International STEM competition. STRIVE Center students regularly participate. |

## Infrastructure

| Term | Definition |
|------|-----------|
| **Skill** | A Markdown document (SKILL.md) that teaches Claude Code how to perform a specialized task. Lives in gallia or liberty-christian repos, deployed to ~/.claude/skills/. |
| **MCP** | Model Context Protocol -- the tool interface that connects Claude to services. |
