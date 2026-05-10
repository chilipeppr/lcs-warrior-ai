---
name: lcs-auto-discover
description: >
  How auto-discovery works on the LCS Warrior AI platform. Covers how wiki
  pages opt in with discovery_triggers metadata, how the lcs-wiki-discover
  skill is auto-generated every 30 minutes, how stale tool versions are
  detected, and how to add discovery metadata when publishing.
  Trigger words: auto-discover, auto discover, discovery triggers, discovery
  pitch, how does discovery work, make my page discoverable, wiki discovery,
  lcs-wiki-discover skill, stale tool, tool update, upgrade prompt.
---

# LCS Auto-Discovery System

Auto-discovery makes every wiki page findable by Claude without manual skill
writing. When a student says "help me study biology," Claude automatically
suggests relevant flashcards, quizzes, and study guides from the wiki.

## How It Works

### 1. Wiki pages opt in with metadata

Any wiki page can become discoverable by adding two fields to its metadata:

```json
{
  "discovery_triggers": ["biology quiz", "cell structure", "mitosis test"],
  "discovery_pitch": "10-question quiz on cell biology with instant grading."
}
```

- **`discovery_triggers`** — 4-7 phrases a user would naturally say
- **`discovery_pitch`** — one-liner Claude shows when suggesting the page

### 2. The wiki generates a discovery skill

The wiki's `/discover` endpoint aggregates ALL pages with discovery metadata
into a single `lcs-wiki-discover` SKILL.md. This skill lists every trigger
phrase and its matching wiki page.

### 3. Containers refresh every 30 minutes

Each LCS container runs `lcs-check-updates.sh` as a UserPromptSubmit hook.
Every 30 minutes it:
1. Fetches `/discover` from the wiki
2. SHA-256 compares against the local skill file
3. Atomic-writes `~/.claude/skills/lcs-wiki-discover/SKILL.md` if changed
4. Audits installed CLI tools against wiki version numbers
5. Surfaces upgrade prompts if tools are stale

### 4. Claude proactively suggests matches

When a user mentions any trigger phrase, Claude sees the match in the
`lcs-wiki-discover` skill and says something like:

> "There's a Biology Cell Structure Quiz on the Warriors Wiki that covers
> organelles, mitosis, and DNA. Want me to open it?"

## Adding Discovery to Your Pages

When publishing ANY page to the wiki, always include discovery metadata:

```bash
lcs-wiki page create \
  --type quiz \
  --slug my-biology-quiz \
  --title "Biology: Cell Structure Quiz" \
  --brief "10 questions on organelles and mitosis" \
  --metadata '{"discovery_triggers":["biology quiz","cell quiz","organelles"],"discovery_pitch":"10-question cell biology quiz with instant grading."}'
```

### Good trigger phrases
- Subject names: "biology", "US history", "revelation"
- Specific topics: "cell structure", "Civil War", "mitosis"
- Action phrases: "study for biology test", "practice quiz"
- Informal language: "bio quiz", "history flashcards"

### Bad trigger phrases
- Too generic: "quiz", "test", "study" (matches everything)
- Too long: "help me study for my biology test on chapter 5" (nobody says this exactly)
- Internal jargon: "lcs-quiz-bio-cells" (students don't say slugs)

## Tool Version Detection

Pages with CLI tools can also opt into automatic version checking:

```json
{
  "releases": {
    "adom_docker": {
      "asset_name": "lcs-wiki",
      "install_hint": "curl -fsSL https://lcs-wiki.../lcs-wiki -o /tmp/lcs-wiki && chmod +x /tmp/lcs-wiki && sudo install -m 0755 /tmp/lcs-wiki /usr/local/bin/lcs-wiki"
    }
  }
}
```

When a newer version exists on the wiki than what's installed locally,
Claude offers: "Shall I upgrade lcs-wiki from 1.0.0 → 1.1.0?"

## Key Files

| File | Location | Purpose |
|------|----------|---------|
| `lcs-wiki-discover` skill | `~/.claude/skills/lcs-wiki-discover/SKILL.md` | Auto-generated, lists all trigger phrases |
| Refresh script | `~/.lcs/hooks/lcs-refresh-wiki-catalog.mjs` | Polls wiki, writes skill, audits versions |
| Check-updates hook | `~/.lcs/hooks/lcs-check-updates.sh` | Runs refresh on 30-min cadence |
| Wiki endpoint | `https://lcs-wiki-.../discover` | Public page listing all discoverable items |

## Rules

1. **Every published page should have discovery metadata** — pages without it are invisible to auto-discover
2. **Pick 4-7 trigger phrases** — too few and it won't match, too many and it's noisy
3. **Never edit `lcs-wiki-discover` manually** — it's auto-generated and will be overwritten
4. **The refresh runs every 30 minutes** — new pages won't appear instantly but will within half an hour
