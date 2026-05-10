---
name: lcs-app-creator
user-invocable: true
description: "Create LCS platform apps — interactive web apps that run on the Warriors Wiki. Study tools, flashcard decks, quizzes, sport pages, 3D viewers, dashboards, games. Every app gets LCS Warriors branding, the canonical header, and publishes to the wiki. Trigger words: create app, make app, build app, new app, LCS app, school app, student app, web app, flashcard app, quiz app, study app."
---

# LCS App Creator

Build interactive web apps for the Liberty Christian School platform. Every app runs as a self-contained HTML file on the Warriors Wiki.

## Before You Start — Read These First

1. **Read `lcs-brand`** — colors, fonts, logo, design tokens
2. **Read `lcs-app-header`** — the 44px branded header every app must have
3. **Read `lcs-ui-patterns`** — tooltips, hover states, accessibility rules

## App Architecture

LCS apps are **single HTML files** — all CSS, JS, and content inline. No build step, no dependencies, no npm. Just HTML that runs in any browser.

```
my-app/
└── index.html    ← everything in one file
```

### Why single-file?
- Students can build them in one class period
- No toolchain to install or configure
- Upload directly to the wiki
- Works on any device — phones, tablets, Chromebooks
- Easy to share, fork, and learn from

## Template

Every LCS app starts from this template:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>App Name — LCS Warriors Wiki</title>
<link href="https://fonts.googleapis.com/css2?family=Source+Sans+Pro:wght@400;600;700&display=swap" rel="stylesheet">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }

  :root {
    --bg: #0A1628;
    --bg-surface: #112040;
    --bg-elevated: #1A2D55;
    --border: #243A6A;
    --accent: #C5A44E;
    --accent-bright: #DFC478;
    --text: #E8E8E8;
    --text-dim: #8899AA;
    --success: #3FB950;
    --warning: #D29922;
    --danger: #D34147;
  }

  body {
    font-family: 'Source Sans Pro', sans-serif;
    background: var(--bg);
    color: var(--text);
    min-height: 100vh;
    display: flex;
    flex-direction: column;
  }

  /* ── LCS Header (mandatory) ── */
  .lcs-header {
    display: flex;
    align-items: center;
    height: 44px;
    padding: 0 16px;
    background: #001E60;
    border-bottom: 2px solid var(--accent);
    gap: 12px;
    flex-shrink: 0;
  }
  .lcs-header img { height: 28px; filter: drop-shadow(0 1px 3px rgba(0,0,0,.4)); }
  .lcs-header-name { font-size: 14px; font-weight: 700; color: var(--accent); }
  .lcs-header-sub { font-size: 11px; color: var(--text-dim); }

  /* ── Your app styles below ── */
  .main {
    flex: 1;
    padding: 20px;
  }
</style>
</head>
<body>

<div class="lcs-header">
  <img src="https://www.txhslogoproject.com/wp-content/uploads/2019/02/Argyle-Liberty-Christian-Warriors1-large-1.png"
       alt="LCS" crossorigin="anonymous" onerror="this.style.display='none'">
  <div>
    <div class="lcs-header-name">App Name</div>
    <div class="lcs-header-sub">Subtitle</div>
  </div>
</div>

<div class="main">
  <!-- Your app content here -->
</div>

<script>
  // Your app logic here
</script>

</body>
</html>
```

## App Categories

When building an app, target one of these wiki categories:

| Category | Examples |
|---|---|
| **Flashcards** | Study decks for any class, Bible verse memorization |
| **Study Guides** | Interactive chapter reviews, topic summaries |
| **Quizzes & Tests** | Practice tests, randomized question banks |
| **Courses** | Curriculum viewers, lesson plan browsers, syllabi |
| **Extracurriculars** | Sport fan pages, club directories, activity calendars |
| **STRIVE Center** | 3D print designs, robotics projects, electronics |
| **Apps** | Games, utilities, creative tools, dashboards |

## Publishing to the Wiki

1. Build the HTML file
2. Test it locally (open in browser, verify on phone)
3. Upload to the wiki via `lcs-wiki asset upload` or the wiki's admin UI
4. Create a wiki page with title, description, and the HTML as a viewer-html asset
5. **Always add auto-discovery metadata** so other LCS users can find this app:

```json
{
  "discovery_triggers": ["biology quiz", "cell structure", "mitosis"],
  "discovery_pitch": "10-question quiz on cell biology with instant grading and explanations."
}
```

Pick 4-7 trigger phrases — words a student would naturally say when looking for this content. The `discovery_pitch` is a one-liner shown when Claude suggests it. Every app published without discovery metadata is invisible to auto-discover.

## Design Checklist

Before publishing any LCS app:
- [ ] Warriors shield logo in header (28px, top-left)
- [ ] Gold app name in header (`#C5A44E`)
- [ ] Navy dark background (`#0A1628`)
- [ ] Source Sans Pro font loaded
- [ ] Works on mobile (responsive)
- [ ] No external dependencies (everything inline)
- [ ] "Tap to flip" or similar hint text for interactive elements
- [ ] Encouraging language ("Great work, Warrior!" not "Test passed")
