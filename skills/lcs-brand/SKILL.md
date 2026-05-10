---
name: lcs-brand
user-invocable: true
description: "Liberty Christian School brand identity — colors, typography, logo usage, and design system tokens. Read this BEFORE writing any UI, CSS, HTML, or visual output for LCS. Trigger words: LCS brand, school colors, warriors colors, navy gold, LCS font, LCS logo, LCS design system, LCS CSS variables."
---

# LCS Brand Identity

Official brand guidelines for Liberty Christian School. Every app, page, and visual output must follow these rules.

## Logo

### Warriors Shield
- **Primary:** Warriors shield crest (PNG at `/static/lcs-logo.png` on the wiki)
- **Source:** `https://www.txhslogoproject.com/wp-content/uploads/2019/02/Argyle-Liberty-Christian-Warriors1-large-1.png`
- Use on dark backgrounds with `filter: drop-shadow(0 2px 4px rgba(0,0,0,.4))`
- Always pair with "Wiki" text when used in app headers (gold, 700 weight)

### Text Mark
- "LIBERTY CHRISTIAN" in Source Sans Pro 700, all caps
- "WARRIORS WIKI" for the platform identity

## Color Palette

### Primary
| Token | Hex | Usage |
|---|---|---|
| `--lcs-navy` | `#001E60` | Headers, nav, hero backgrounds |
| `--lcs-navy-dark` | `#0A1628` | Page backgrounds (dark mode) |
| `--lcs-navy-surface` | `#112040` | Cards, panels |
| `--lcs-navy-elevated` | `#1A2D55` | Hover cards, modals |
| `--lcs-navy-border` | `#243A6A` | Card borders, dividers |

### Accent
| Token | Hex | Usage |
|---|---|---|
| `--lcs-gold` | `#C5A44E` | Primary accent, buttons, highlights, active states |
| `--lcs-gold-light` | `#DFC478` | Hover states, secondary highlights |
| `--lcs-gold-pale` | `#F0E6C8` | Subtle gold tint backgrounds |

### Text
| Token | Hex | Usage |
|---|---|---|
| `--lcs-text` | `#E8E8E8` | Primary text on dark backgrounds |
| `--lcs-text-secondary` | `#8899AA` | Secondary text, labels |
| `--lcs-text-muted` | `#53565A` | Disabled text, placeholders |

### Secondary
| Token | Hex | Usage |
|---|---|---|
| `--lcs-blue` | `#0B76BF` | Links, interactive elements |
| `--lcs-blue-light` | `#5DA9DD` | Hover links |

### Semantic
| Token | Hex | Usage |
|---|---|---|
| `--lcs-success` | `#3FB950` | Correct, positive, "Got It!" |
| `--lcs-warning` | `#D29922` | Caution, "Getting There" |
| `--lcs-danger` | `#D34147` | Error, "Still Learning" |

## Typography

### Font Stack
```css
--lcs-font-heading: 'Source Sans Pro', sans-serif;  /* 700 weight */
--lcs-font-body: 'Source Sans Pro', sans-serif;      /* 400, 600 weight */
--lcs-font-mono: 'JetBrains Mono', monospace;        /* 400 weight — code only */
```

### Loading
```html
<link href="https://fonts.googleapis.com/css2?family=Source+Sans+Pro:wght@400;600;700&display=swap" rel="stylesheet">
```

### Rules
- Headings: Source Sans Pro 700
- Body: Source Sans Pro 400
- Bold body: Source Sans Pro 600
- Code blocks only: JetBrains Mono 400
- NEVER use monospace for labels, descriptions, or UI text
- NEVER ALL CAPS on body text or descriptions (headings OK sparingly)

## CSS Variables Template

Every LCS app should include this at the top of its CSS:

```css
:root {
  --bg: #0A1628;
  --bg-surface: #112040;
  --bg-elevated: #1A2D55;
  --border: #243A6A;
  --accent: #C5A44E;
  --accent-bright: #DFC478;
  --text: #E8E8E8;
  --text-secondary: #8899AA;
  --text-muted: #53565A;
  --success: #3FB950;
  --warning: #D29922;
  --danger: #D34147;
  --link: #0B76BF;
  --link-hover: #5DA9DD;
  --font-heading: 'Source Sans Pro', sans-serif;
  --font-body: 'Source Sans Pro', sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
}
```

## Design Rules
- **Dark theme always** — navy backgrounds, light text
- **Gold is the primary accent** — use for buttons, active states, links, highlights
- **Warriors shield in every app header** — top-left, 28-32px height
- **Transitions:** 0.15s ease for all hover effects
- **Border radius:** 12px cards, 8px buttons, 4px inputs
- **Card shadow:** `0 4px 20px rgba(0,30,96,0.3)`
- **Gold accent border:** `2px solid #C5A44E` for headers, active tabs, featured content
- **Monochrome icons** — `#E8E8E8` white or `currentColor`. NO colored icons, NO emoji in UI chrome

## Voice & Tone
- **Encouraging:** "Great work, Warrior!" not "Test completed"
- **Student-first:** Written for students, not IT administrators
- **Faith-integrated:** Natural references to faith and school values
- **Action-oriented:** "Start studying" not "Welcome to the application"
