---
name: lcs-cli-design
description: Guidelines for building CLI tools in the LCS ecosystem. Use when creating a new CLI tool for school use, adding commands to an existing one, or deciding how a SKILL.md ships with the tool. Covers CLI conventions, AI-oriented output, skill files, and distribution. Trigger words: build a cli, new cli tool, cli design, cli guidelines, LCS tool, school cli, make a tool for the ai.
---

# Building CLI Tools for LCS

## Why CLI

We use CLIs as the primary interface between Claude Code and LCS tools. The AI reads the skill to learn the commands, then runs them via Bash.

| | CLI |
|---|---|
| Context cost | Zero — skill file loaded only when triggered |
| Discoverability | Skill-triggered, on-demand |
| Reliability | Process runs and exits cleanly |
| Debugging | Just run the command in terminal |
| Distribution | Single script or binary |

## CLI Conventions

### Language

- **Node.js/Bun** for quick tools (quiz generators, study helpers, data processors)
- **Python** for data science and ML tools (STRIVE Center projects)
- **Rust** for performance-critical tools (if needed)
- **Bash** for simple automation scripts

### Output: AI-Oriented

CLI output is consumed by Claude Code. Design accordingly:

**Every response starts with `OK:` or `ERROR:`** — the AI can instantly determine success/failure.

**Success output is descriptive:**
```text
OK: Generated 25 flashcards from Chapter 5 of Biology textbook.
OK: Published quiz to LCS Wiki at apps/bio-quiz-ch5.
OK: Exported attendance report for Period 3.
```

**Error output includes a `Hint:` line:**
```text
ERROR: Cannot find textbook PDF at /tmp/biology-ch5.pdf
Hint: Check the path exists. Use `ls /tmp/` to list files.

ERROR: Wiki server not responding.
Hint: Check wiki health with `curl https://lcs-wiki-bpd1iwhcgswk.adom.cloud/health`
```

**Never output ambiguous or empty responses.** If a command succeeds silently, still print `OK:`.

### Colored Output

Use ANSI escape codes for colored terminal output, but **strip colors when stdout is not a TTY** (piped, redirected, or captured by Claude Code):

```bash
# Simple bash pattern
if [ -t 1 ]; then
  GREEN='\033[32m'
  RED='\033[31m'
  RESET='\033[0m'
else
  GREEN=''
  RED=''
  RESET=''
fi

echo -e "${GREEN}OK:${RESET} Task completed."
```

- `OK:` in green, paths/values in cyan
- `ERROR:` in red, hints in dim
- The AI reads `OK:` / `ERROR:` prefixes; colors are for human readability only

### Subcommand Structure

Use subcommands for logical grouping:
```text
toolname <verb> [options] [args]

lcs-quiz generate --subject biology --chapter 5
lcs-quiz publish --wiki
lcs-quiz list --subject math

lcs-attendance export --period 3
lcs-attendance summary --date today
```

### Health Check

Every CLI that talks to a server should have a `health` subcommand:
```text
toolname health
```
Returns `OK: ...` if reachable, `ERROR: ...` with a hint if not.

## Skill File

Every CLI **must** have a `SKILL.md` so Claude Code knows how to use it.

### Where It Lives

- Source: in the tool's own directory (e.g., `lcs-{tool}/SKILL.md`)
- Deployed to `~/.claude/skills/lcs-{tool}/SKILL.md`

### What It Contains

```markdown
---
name: lcs-tool-name
description: "One-line description with trigger words..."
---

# Tool Name

Brief description of what it does.

## Commands

### `toolname verb`
What it does.

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--flag` | yes | — | What it controls |

**Example:**
\`\`\`bash
toolname verb --flag value /path/to/thing
\`\`\`
```

Include **concrete examples** for every command. The AI copies from examples — if the example is wrong or missing, the AI will guess and get it wrong.

## Distribution

### LCS Wiki (recommended)

Publish tools to the LCS Wiki so students and teachers can discover and use them:

```text
https://lcs-wiki-bpd1iwhcgswk.adom.cloud/apps/lcs-{tool}
```

### The install pattern

Tools should be installable with a simple command:

```bash
# Download and install
curl -fsSL https://lcs-wiki-bpd1iwhcgswk.adom.cloud/static/apps/lcs-{tool}/install.sh | bash
```

The install script handles:
1. Downloading the tool
2. Placing it on PATH
3. Deploying the SKILL.md to `~/.claude/skills/`

## Examples of This Pattern

| Tool | What it does |
|------|-------------|
| `lcs-quiz` | Generate and publish quizzes from textbook content |
| `lcs-attendance` | Attendance tracking and reporting |
| `lcs-flashcards` | Flashcard generator from study guides |
