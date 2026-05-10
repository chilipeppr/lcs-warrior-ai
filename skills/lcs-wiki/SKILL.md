---
name: lcs-wiki
description: Search, read, publish, and upload assets to the LCS Wiki via the lcs-wiki CLI. Use when the user mentions "wiki", "publish to wiki", "upload video/screenshot to wiki", "search wiki", "install skill from wiki", "find a resource", or wants to share a skill/flashcard/course/study-guide with the school. Also use proactively before creating a new resource -- search the wiki first to avoid duplicating work.
---

# lcs-wiki -- one skill, one CLI

The LCS Wiki lives at `https://lcs-wiki-bpd1iwhcgswk.adom.cloud`. It holds **skills**, **courses**, **flashcards**, **study guides**, **apps**, **strive projects**, and **resources**. Every interaction goes through the `lcs-wiki` CLI at `/usr/local/bin/lcs-wiki`.

Every CLI invocation prints JSON to stdout. Pipe through `jq` for extraction.

## Author identity on publish

Every `page publish`, `page edit`, and `asset upload` gets stamped
with `pub_author_id` + `pub_author_name` on the server, derived from
the bearer token in use. The author stamp is **server-controlled**.

**The CLI hard-blocks shared-identity publishes** (v0.3.1+). If you
run `page publish` / `page edit` / `asset upload` with the shared
fallback token, the CLI exits with an error. Run `lcs-wiki set-author`
to link your identity.

### Flow on a fresh container

```bash
lcs-wiki set-author        # one-time per container
lcs-wiki page publish ...  # stamps you as the author
```

## Page references

Pages are addressed as `<type>/<slug>`, for example:
- `apps/strive-dashboard`
- `skills/study-helper`
- `courses/ap-biology`
- `flashcards/spanish-vocab-unit-3`

### What each `<type>` means in LCS

| Type | What goes here |
|---|---|
| **app** | A user-installable LCS tool with a binary or web app (e.g. quiz builder, flashcard trainer). |
| **course** | A course page with syllabus, resources, assignments, and study materials. |
| **flashcard** | A flashcard deck for study -- vocabulary, formulas, key concepts. |
| **skill** | A SKILL.md (Claude Code instructions) explaining when/how to use a thing. |
| **strive** | A STRIVE Center project page -- 3D printing, robotics, electronics, entrepreneurship. |
| **resource** | General educational resource -- study guide, reference sheet, tutorial. |
| **video** | A demo recording, lecture capture, or tutorial video. |

## Workflow 1 -- search before you build

Before creating any new resource, check the wiki:

```bash
lcs-wiki page search "AP Biology chapter 5" --limit 10
```

If snippet search returns 0 or the match looks weak, escalate to deep search:

```bash
lcs-wiki page search "cell division mitosis" --deep --limit 15
```

Inspect a hit:

```bash
lcs-wiki page get courses/ap-biology | jq '.page | {title, brief, version}'
```

## Workflow 2 -- publish a page (the full checklist)

Every wiki page MUST have all of the following:

| # | Item | CLI flag / how to set | Required? |
|---|---|---|---|
| 1 | Title | `--title "..."` | yes |
| 2 | Brief (1-line hook) | `--brief "..."` | yes |
| 3 | Body markdown | `--body-md file.md` | yes |
| 4 | **Sample prompts (3-8)** | `--sample-prompt "LABEL\|PROMPT"` x N | **yes** |
| 5 | Discovery triggers | set via `page edit --field metadata` | yes |
| 6 | Discovery pitch | set via `page edit --field metadata` | yes |
| 7 | Version (semver) | `--version 1.0.0` | yes on update |
| 8 | Changelog | `--changelog "..."` | yes on update |

### Step-by-step

**a. Draft the content** as markdown in `/tmp/page.md`.

**b. Draft 3-8 sample prompts WITH THE USER.**

**c. Draft discovery_triggers + discovery_pitch WITH THE USER.**

**d. Publish:**

```bash
lcs-wiki page publish courses/ap-biology \
  --title "AP Biology" \
  --brief "Course resources and study materials for AP Biology" \
  --body-md /tmp/page.md \
  --sample-prompt "Study guide|Create a study guide for AP Bio chapter 5" \
  --sample-prompt "Flashcards|Make flashcards for cell division" \
  --sample-prompt "Quiz prep|Help me prepare for the AP Bio exam"
```

**e. Set metadata:**

```bash
cat > /tmp/meta.json << 'EOF'
{
  "discovery_triggers": ["ap biology", "bio", "cells", "genetics"],
  "discovery_pitch": "AP Biology course resources and study tools."
}
EOF
lcs-wiki page edit courses/ap-biology --field metadata --body-md /tmp/meta.json
```

**f. Upload a thumbnail:**

```bash
lcs-wiki asset upload courses/ap-biology --asset-type thumbnail --file card.png
```

**g. Upload screenshots (at least 2):**

```bash
lcs-wiki asset upload courses/ap-biology --asset-type screenshot --file 01-main.png --caption "Course overview"
lcs-wiki asset upload courses/ap-biology --asset-type screenshot --file 02-resources.png --caption "Study resources"
```

### Updating an existing page

Use `page edit` for field-level updates:

```bash
lcs-wiki page edit courses/ap-biology --field brief --body-md /tmp/new-brief.txt
lcs-wiki page edit courses/ap-biology --field metadata --body-md /tmp/new-meta.json
```

For version-bumping changes use `page publish` again with `--version 1.1.0 --changelog "..."`.

## Workflow 3 -- upload assets

Assets attach to a page. Supported `--asset-type` values:

| type | use for |
|---|---|
| `file` | generic files (documents, handouts, answer keys) |
| `video` | uploaded video files (lectures, demos, tutorials) |
| `hero_image` | top-of-page banner + index card |
| `thumbnail` | small index card image |
| `screenshot` | gallery images; prefix filename with `01-`, `02-` for ordering |
| `viewer_html` | interactive sample tab (iframed on the page) |

Upload examples:

```bash
lcs-wiki asset upload courses/ap-biology \
  --asset-type video \
  --file /home/adom/project/recordings/cell-division-lecture.webm \
  --caption "Cell division lecture -- Chapter 5"

lcs-wiki asset upload courses/ap-biology --asset-type screenshot --file 01-overview.png --caption "Overview"
```

List and delete:

```bash
lcs-wiki asset list courses/ap-biology | jq '.assets[] | {id, asset_type, filename}'
lcs-wiki asset delete courses/ap-biology --asset-id 42
```

## Workflow 4 -- install an app from the wiki

```bash
lcs-wiki app install flashcard-trainer
lcs-wiki app list
lcs-wiki app uninstall flashcard-trainer
```

## Workflow 5 -- soft-delete a page

Pages are soft-deleted (recoverable by admin). Reason is required:

```bash
lcs-wiki page delete courses/old-elective --reason "Course no longer offered"
```

## Workflow 6 -- install content locally

Pull a skill into `~/.claude/skills/`:

```bash
lcs-wiki page search "study helper" --limit 5
lcs-wiki page get skills/study-helper | jq -r '.page.skill_source // .page.content' > ~/.claude/skills/study-helper/SKILL.md
```

## Listing

```bash
lcs-wiki page list --type course --limit 50
lcs-wiki page list --type flashcard --status validated
lcs-wiki page list --type strive --limit 20
```

## Auth

The CLI resolves the bearer token in this order:
1. `$LCS_WIKI_TOKEN`
2. `/var/run/adom/api-key` (container default)
3. `$ADOM_API_KEY`
4. `$X_API_KEY`
5. dev fallback

Read-only commands (search, get, list, asset list) don't require auth.

## Gotchas

- **Every page needs 3-8 sample prompts.** The CLI rejects `page publish` without them.
- **Never skip the discovery snippet OR install prompt user approval steps.**
- **Visual verification is REQUIRED** after publishing.
- **Slug format** is lowercase-hyphenated (`ap-biology`, `spanish-vocab`). No uppercase, no underscores.
- **Large video uploads** (>50 MB) work fine; the CLI has a 3-minute HTTP timeout.
- **Use `--deep` search liberally** for courses, flashcards, and resources.
- **Delete is soft** -- pages are hidden from public view but preserved in the database.
