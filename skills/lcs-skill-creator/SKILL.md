---
name: lcs-skill-creator
description: Authors, tests, and iterates on Claude Code skills (SKILL.md files) for the LCS ecosystem. Use when a student or teacher wants to create a new skill, write or update a SKILL.md, or asks how skills work. Covers frontmatter conventions, writing effective descriptions, deploying to ~/.claude/skills/, and iterating on failures. Simplified for school use.
---

# Creating LCS Skills

Skills are Markdown documents that teach Claude Code how to perform specialized tasks. They get deployed to `~/.claude/skills/` so Claude can discover and use them when a student or teacher asks for help.

Only the `name` and `description` from each skill's frontmatter are pre-loaded at startup. The full SKILL.md is read when the description matches the user's task. This progressive disclosure is why keeping SKILL.md concise matters.

## Architecture

```
liberty-christian/skills/my-skill/
    SKILL.md              # main instructions (under 500 lines)
    reference.md          # optional, loaded only when needed
    examples.md           # optional, loaded only when needed

# After deployment:
~/.claude/skills/my-skill/SKILL.md
```

## Workflow Checklist

```
- [ ] Step 1: Decide what the skill does
- [ ] Step 2: Write the SKILL.md
- [ ] Step 3: Deploy and test
- [ ] Step 4: Iterate and improve
```

## Step 1: Decide What the Skill Does

One skill, one purpose. If the scope is growing, split it. A 50-line skill that solves one problem beats a 500-line skill covering everything.

**Good skill ideas for students:**
- A study guide generator for a specific subject
- A quiz creator from textbook chapters
- A vocabulary flashcard builder
- A math problem solver with step-by-step explanations
- A science lab report formatter
- A citation generator for research papers

Use kebab-case for the directory:

```bash
mkdir -p /home/adom/project/liberty-christian/skills/my-skill-name
```

## Step 2: Write SKILL.md

### Frontmatter

```yaml
---
name: my-skill-name
description: <what it does and when to use it, includes trigger phrases>
---
```

| Field | Required | Convention |
|-------|----------|------------|
| `name` | yes | Matches the skill directory name. Kebab-case. |
| `description` | yes | Target under 1024 chars. Third person. Include trigger phrases. |
| `user-invocable` | no | `true` if students can trigger it with `/skill-name`. |

### Writing the Description

The description is how Claude picks this skill from all candidates. Write it in **third person**, stating both what the skill does and when to use it.

**Good:**

```yaml
description: Generates vocabulary flashcards from textbook chapters with definitions, examples, and quiz questions. Use when the student says "make flashcards", "study vocabulary", or "create a word list from chapter 5".
```

**Bad:**

```yaml
description: A tool for making flashcards.              # too vague
description: I can help you make flashcards.             # first person
```

### Body: Tone and Structure

Write clear, imperative instructions for Claude.

- **Keep the body under 500 lines.** Split into reference files if longer.
- **Number steps when order matters.**
- **Always tag code blocks** with the language.
- **Use absolute file paths** starting from `/home/adom/`.
- **Include concrete examples** for every command or workflow.

### Content Patterns

**Template pattern** — for strict output formats:
```markdown
## Output Format

Generate the flashcard set as:

\`\`\`
Term: [word]
Definition: [definition]
Example: [example sentence]
\`\`\`
```

**Workflow with validation** — for multi-step tasks:
```markdown
## Steps

1. Read the source material
2. Extract key terms
3. Generate flashcards
4. Verify accuracy against the source
5. Present to the student
```

## Step 3: Deploy for Testing

Copy the skill to `~/.claude/skills/` so Claude Code picks it up:

```bash
mkdir -p ~/.claude/skills/my-skill-name
cp /home/adom/project/liberty-christian/skills/my-skill-name/SKILL.md ~/.claude/skills/my-skill-name/SKILL.md
```

Open a new Claude Code session and try a trigger phrase. Verify:

1. The skill triggers on the expected phrases
2. The instructions produce correct output
3. Edge cases are handled

## Step 4: Iterate

Edit the source file, then re-copy to `~/.claude/skills/`:

```bash
cp /home/adom/project/liberty-christian/skills/my-skill-name/SKILL.md ~/.claude/skills/my-skill-name/SKILL.md
```

Common failure modes:

| Symptom | Cause | Fix |
|---------|-------|-----|
| Skill doesn't trigger | Description too vague | Add specific trigger phrases |
| Claude ignores instructions | SKILL.md too long or vague | Be specific; split into reference files |
| Wrong file paths | Relative paths | Use absolute paths from `/home/adom/` |
| Two skills fight | Overlapping descriptions | Narrow each description |

## Skill Complexity Guidelines

| Type | Lines | Examples |
|------|-------|---------|
| **Simple** | 20-100 | Vocabulary builder, citation formatter |
| **Medium** | 100-300 | Study guide generator, lab report helper |
| **Complex** | 300-500 (split beyond) | Full course assistant, project manager |

Start small. Split into reference files before the body exceeds 500 lines.

## Anti-patterns

- **Offering too many options.** Pick one default approach, not a menu of five.
- **Writing complete assignments for students.** Guide and teach, don't do it for them.
- **Including non-school-appropriate content.** Everything must be school-safe.
- **Verbose framing.** Don't explain basic concepts Claude already knows.

## Related Skills

- `lcs-app-creator` — Building a visual skill as a web app
- `lcs-tool-publisher` — Publishing to the LCS Wiki
- `lcs-brand` — Colors, fonts, design tokens
