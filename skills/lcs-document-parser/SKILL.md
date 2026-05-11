---
name: lcs-document-parser
description: Parse teacher-uploaded PDFs (textbook chapters, worksheets, handouts) into structured wiki study guide content. Extracts key terms, chapter summaries, review questions, vocabulary lists, and important diagrams. Publishes structured content to the LCS Wiki. Trigger words: parse textbook, convert worksheet, extract study guide, parse handout, create study guide from PDF, textbook to wiki, parse chapter, extract vocabulary, generate review questions, document to study guide.
---

# LCS Document Parser

Parse teacher-uploaded PDFs (textbook chapters, worksheets, handouts, study packets) into structured wiki content that students can use for studying. Extracts key terms, chapter summaries, review questions, vocabulary lists, and important diagrams.

## What This Does

Takes a PDF document and produces:
- **Chapter Summary** — a concise overview of the main topics
- **Key Terms / Vocabulary** — definitions extracted from the text
- **Review Questions** — comprehension questions based on the content
- **Important Concepts** — highlighted key ideas and themes
- **Diagrams** — extracted and captioned figures, charts, and illustrations

The output is published to the LCS Wiki as a study guide page.

## Arguments

- `--subject` — Subject area (biology, history, math, etc.)
- `--grade` — Grade level (for age-appropriate vocabulary)
- `--chapter` — Chapter number or title
- `--teacher` — Teacher name (for attribution)

## Workflow

### Step 1: Acquire the PDF

```bash
# User provides a path
ls -la /tmp/chapter5-biology.pdf

# Or download from a URL
curl -sL -o /tmp/chapter5.pdf "https://example.com/textbook-ch5.pdf"
```

Verify the file is a valid PDF:
```bash
file /tmp/chapter5.pdf  # Should show "PDF document"
pdfinfo /tmp/chapter5.pdf | grep Pages
```

### Step 2: Extract Raw Text

```bash
pdftotext /tmp/chapter5.pdf /tmp/chapter5.txt
```

Read the extracted text to get a rough overview. The raw text will have formatting issues — that's expected. It's a guide, not the source of truth.

### Step 3: Render Pages as Images

```bash
mkdir -p /tmp/chapter5-pages
pdftoppm -png -r 200 /tmp/chapter5.pdf /tmp/chapter5-pages/page

# Resize for Claude vision (max 1500px)
for png in /tmp/chapter5-pages/page-*.png; do
  convert "$png" -resize '1500x1500>' "$png"
done
```

### Step 4: Visual Analysis

Read each page image with Claude vision to extract accurate content:

For each page, extract:

1. **Headings and subheadings** — the document's structure
2. **Key terms** — bolded, italicized, or highlighted vocabulary words with their definitions
3. **Important facts** — numbered lists, bullet points, key statements
4. **Diagrams and figures** — identify bounding boxes for cropping
5. **Tables** — reconstruct as proper markdown tables
6. **Formulas** — convert to readable format

### Step 5: Generate Study Guide Markdown

Build a structured markdown file with these standard sections:

```markdown
**Subject:** Biology
**Chapter:** 5 — Cellular Respiration
**Teacher:** Mrs. Johnson
**Date Parsed:** 2026-05-09

## Summary

[2-3 paragraph summary of the chapter's main topics and themes]

## Key Concepts

### [Concept 1 Title]
[Explanation of the concept in student-friendly language]

### [Concept 2 Title]
[Explanation]

## Vocabulary

| Term | Definition |
| --- | --- |
| Mitochondria | The organelle where cellular respiration occurs |
| ATP | Adenosine triphosphate — the cell's energy currency |
| Glycolysis | The first stage of cellular respiration, occurring in the cytoplasm |

## Important Diagrams

[Extracted and captioned figures from the textbook]

## Review Questions

1. What is the overall equation for cellular respiration?
2. Where does glycolysis take place in the cell?
3. How many ATP molecules are produced in each stage?
4. Compare and contrast aerobic and anaerobic respiration.
5. Why is oxygen necessary for the electron transport chain?

## Key Formulas

[Any mathematical formulas or equations from the chapter]

## Study Tips

- Focus on understanding the three stages in order
- Draw the process from memory
- Practice labeling the mitochondria diagram
```

### Step 6: Crop Important Diagrams

For each diagram identified during visual analysis:

```bash
# Crop the diagram from the full-page image
convert /tmp/chapter5-pages/page-05.png -crop WxH+X+Y +repage /tmp/chapter5-diagrams/fig1.png

# Clean up and optimize
convert /tmp/chapter5-diagrams/fig1.png \
  -resize 1200x1200\> -trim +repage \
  -bordercolor white -border 20 /tmp/chapter5-diagrams/fig1.png
```

### Step 7: Publish to LCS Wiki

```bash
# Save the study guide
cp /tmp/chapter5-studyguide.md /home/adom/project/study-guides/biology-ch5.md

# Publish to the wiki
adom-wiki page publish "study-guides/biology-ch5" \
  --title "Biology Chapter 5 — Cellular Respiration" \
  --brief "Study guide covering cellular respiration, ATP production, and the three stages of energy metabolism" \
  --body-md /tmp/chapter5-studyguide.md \
  --changelog "Parsed from textbook chapter 5" \
  --sample-prompt "Study guide for biology chapter 5" \
  --sample-prompt "Cellular respiration review" \
  --sample-prompt "Biology vocabulary chapter 5"

# Upload diagrams as screenshots
for fig in /tmp/chapter5-diagrams/*.png; do
  adom-wiki asset upload study-guides/biology-ch5 \
    --asset-type screenshot \
    --file "$fig" \
    --caption "$(basename "$fig" .png)"
done
```

**Wiki URL:** `https://lcs-wiki-bpd1iwhcgswk.adom.cloud`

## Content Rules

### What to Extract

- **Vocabulary** — every bolded/highlighted term with its definition
- **Key concepts** — main ideas, themes, and important relationships
- **Review questions** — generate 5-10 comprehension questions that test understanding (not just recall)
- **Formulas** — any mathematical or scientific formulas
- **Diagrams** — labeled figures, charts, and illustrations

### What NOT to Do

- **Do not copy the entire textbook verbatim** — extract and summarize key content
- **Do not generate test answers** — review questions should prompt thinking, not provide answers
- **Do not include copyrighted publisher content beyond fair use** — summaries, key terms, and study questions are fair use for educational purposes
- **Keep language grade-appropriate** — match the reading level to the grade
- **Do not alter factual content** — if the textbook says something, represent it accurately

## Supported Document Types

| Document Type | What Gets Extracted |
|---------------|-------------------|
| Textbook chapter | Full study guide with vocabulary, concepts, questions |
| Worksheet | Questions and answer structure |
| Handout | Key information organized by topic |
| Lab manual | Procedure, safety notes, data tables |
| Study packet | Consolidated review content |
| Syllabus | Course schedule, topics, due dates |

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| Text extraction is garbled | Scanned PDF (image-only) | Use the visual analysis path (Step 3+4); pdftotext won't work on scanned docs |
| Diagrams are blurry | Low source resolution | Increase DPI in pdftoppm: `-r 300` |
| Tables are mangled | Complex table layout | Use visual analysis to reconstruct tables from the page image |
| Wrong vocabulary extracted | OCR misread bold/italic formatting | Cross-check with the visual page and correct manually |
| Wiki page has no sections | Heading format mismatch | Use `## ` (h2) for main sections |

## Dependencies

Required on the container:
- `pdftotext` (from poppler-utils)
- `pdfinfo` (from poppler-utils)
- `pdftoppm` (from poppler-utils)
- `convert` (from ImageMagick)
- `adom-wiki` CLI (for publishing)
