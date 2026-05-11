---
name: lcs-bug-filing
description: Use when a student or teacher needs to file a bug report or feature request for an LCS project. Covers the full workflow from identifying a problem to filing a polished report with screenshots and clear descriptions. Good practice for real-world software development. Trigger words: file a bug, report a bug, create an issue, something is broken, feature request, bug report, file github issue.
---

# Filing Bug Reports — LCS Student Guide

How to file clear, helpful bug reports for your projects. This is a real-world software development skill that will serve you well in any tech career.

## When to Use This

- Something in your project is broken and you need to document it
- You want to request a new feature for an LCS tool
- You found a bug in a shared school tool and want to report it
- A teacher asks you to document issues as part of a software project

## The Workflow

### 1. Reproduce the Bug

Before filing, make sure you can reproduce the problem:

1. Write down the exact steps to trigger the bug
2. Try it at least twice to confirm it's consistent
3. Note whether it happens every time or only sometimes
4. Check if it happens on different devices (Chromebook vs laptop)

### 2. Capture the Current State

Take a screenshot showing the problem:

```bash
# Screenshot the current view
adom-cli hydrogen screenshot screen -o /tmp/bug-screenshot.png
```

### 3. Write a Clear Bug Report

Every good bug report has these sections:

```markdown
## What Happened (Actual Behavior)
Describe what actually happened. Be specific.

## What Should Have Happened (Expected Behavior)
Describe what you expected to happen instead.

## Steps to Reproduce
1. Go to [specific page/feature]
2. Click [specific button]
3. Enter [specific data]
4. Observe [the bug]

## Environment
- Device: Chromebook / Windows laptop / etc.
- Browser: Chrome version XX
- Date/Time: When you saw it

## Screenshots
[Attach screenshots showing the problem]
```

### 4. Annotate Screenshots (Optional but Helpful)

If the problem is visual, annotate the screenshot to point out exactly what's wrong:

```python
from PIL import Image, ImageDraw, ImageFont

img = Image.open('/tmp/bug-screenshot.png')
d = ImageDraw.Draw(img)

# Red circle or box around the problem area
d.rectangle([x1, y1, x2, y2], outline=(248, 81, 73), width=3)

# Add a label
d.text((x1, y1 - 20), 'BUG: Button does nothing', fill=(248, 81, 73))

img.save('/tmp/bug-annotated.png')
```

**Key rules:**
- Use solid backgrounds on overlays (never transparent — text bleeds through)
- Circle or box the exact problem area
- Add a brief label explaining what's wrong

### 5. Review Before Filing

Show the bug report to yourself (or a classmate) before filing:

- Is the title clear and specific?
- Can someone who has never seen this bug understand what's wrong?
- Are the steps to reproduce complete?
- Is the screenshot helpful?

### 6. File the Issue

```bash
# Write the bug report to a file
cat > /tmp/bug.md << 'EOF'
## What Happened
The submit button on the quiz page doesn't respond when clicked.

## What Should Have Happened
The quiz should submit and show my score.

## Steps to Reproduce
1. Go to the Biology Quiz page
2. Answer all questions
3. Click "Submit"
4. Nothing happens — no response, no error

## Environment
- Device: Chromebook
- Browser: Chrome 124
- Date: 2026-05-09
EOF

# File it on GitHub
gh issue create --repo lcs-org/project-name \
  --title "Quiz submit button doesn't respond" \
  --body-file /tmp/bug.md
```

### 7. Share the Link

Always share the issue URL so others can find it:

```text
Filed: https://github.com/lcs-org/project-name/issues/42
```

## Bug Report Quality Checklist

Before filing, check:

- [ ] **Title is specific** — "Quiz submit button broken" not "something doesn't work"
- [ ] **Steps are numbered** and complete enough for someone else to follow
- [ ] **Expected vs actual behavior** is clearly stated
- [ ] **Screenshot attached** if the bug is visual
- [ ] **Environment noted** (device, browser)
- [ ] **No duplicate** — searched existing issues first
- [ ] **Polite and constructive** — describe the problem, don't blame

## Common Mistakes

- **Vague titles** — "It's broken" tells nobody anything. Be specific.
- **No steps to reproduce** — "It just stopped working" doesn't help fix it. Write exact steps.
- **Skipping screenshots** — a picture is worth 1,000 words for visual bugs
- **Duplicate filing** — search existing issues before creating a new one
- **Emotional language** — "This stupid thing never works" vs "The save button fails when the title field is empty"

## For Teachers: Using Bug Reports in Class

Bug filing is an excellent software engineering skill to teach:

1. **Assign students to file bugs** as part of any coding project
2. **Grade on report quality** — clarity, completeness, reproducibility
3. **Have students fix each other's bugs** — file a bug, swap with a partner, fix theirs
4. **Review as a class** — show examples of good vs poor bug reports

## Colors for Annotations

```python
RED = (248, 81, 73)       # Problems, bugs
GREEN = (63, 185, 80)     # Working correctly, proposed fix
GOLD = (197, 164, 78)     # LCS brand accent (#C5A44E)
WHITE = (230, 237, 243)   # Text
DARK = (13, 17, 23)       # Background
```
