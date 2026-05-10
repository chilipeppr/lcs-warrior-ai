---
name: lcs-ui-patterns
user-invocable: true
description: "Non-negotiable UI rules for every LCS app. Tooltips, hover states, button feedback, accessibility, mobile responsiveness, NEVER ALL CAPS on body text. Read before building any UI. Trigger words: UI rules, tooltip, hover state, button style, accessibility, responsive design, LCS UI, app design rules."
---

# LCS UI Patterns — Non-Negotiable Rules

Read this before building any LCS app UI. These rules exist because students tested the apps and hit every edge case.

## 1. Tooltips

- **Position:** `position: fixed`, appended to `<body>`, z-index 99999
- **NOT** CSS `::after` pseudo-elements (those clip, inherit transforms, and break in scrollable containers)
- **Delay:** 600ms hover before showing
- **Auto-flip:** If tooltip would overflow the viewport, flip it to the other side
- **Content:** Short, helpful, newbie-friendly. "Click to flip the card" not "Toggle card state"
- **Never ALL CAPS** in tooltip text
- **Every interactive element gets a tooltip** — buttons, icons, cards, links

## 2. Click Previews

- Before any destructive or significant action, show a preview of what will happen
- "Are you sure?" dialogs are lazy — show the actual consequence instead
- Example: before deleting a flashcard deck, show which cards will be lost

## 3. Button States

Every button must visually reflect its state:
- **Default:** styled per LCS brand (gold border, transparent bg)
- **Hover:** lighter gold bg (`rgba(197,164,78,0.2)`)
- **Active/pressed:** `transform: scale(0.96)` — brief press feedback
- **Disabled:** `opacity: 0.4`, `cursor: not-allowed`
- **Loading:** show a spinner or pulsing animation, disable click

## 4. NEVER ALL CAPS

- Body text, descriptions, labels, tooltips: **never all caps**
- Headings: caps OK sparingly (e.g., "WARRIORS WIKI" in the hero)
- Button text: sentence case ("Start studying" not "START STUDYING")
- Category labels: title case ("Study Guides" not "STUDY GUIDES")

## 5. Feedback for Every Action

- Every click/tap must produce visible feedback within 100ms
- If an operation takes >500ms, show a loading indicator
- Success states: brief green flash or check animation
- Error states: red border + clear message explaining what went wrong

## 6. Responsive Design

All LCS apps must work on three surfaces:
- **Desktop** (1200px+) — full layout
- **Tablet** (768-1199px) — stacked layout OK
- **Phone** (320-767px) — single column, touch-friendly targets (44px min)

Use CSS grid or flexbox. Never fixed widths. Test by resizing the browser.

## 7. Accessibility Basics

- **Contrast:** text must be readable against its background (min 4.5:1 ratio)
- **Focus indicators:** visible ring on keyboard-focused elements
- **Alt text:** all images get descriptive alt text
- **Keyboard navigation:** Space/Enter activates buttons, arrows navigate lists
- **Touch targets:** minimum 44px x 44px on mobile

## 8. Draggable/Collapsible Panels

- Any HUD, overlay, or floating panel must be:
  - **Draggable** by its header
  - **Collapsible** (click header to toggle)
  - **Dismissible** (X button, Escape key)
- Remember panel position across sessions (localStorage)

## 9. Multi-Unit Displays

When showing measurements (3D models, print dimensions):
- Primary unit: **mm** (millimeters)
- Secondary unit: **in** (inches) in parentheses
- Example: "120mm (4.72 in)"

## 10. Dark Theme Only

LCS apps use dark theme exclusively:
- Background: `#0A1628`
- Surface: `#112040`
- Text: `#E8E8E8`
- No light mode toggle needed
- Gold accent (`#C5A44E`) provides warmth against the navy

## 11. Transitions

- All hover effects: `transition: all 0.15s ease`
- Card hover: subtle border color change + slight elevation
- Button hover: background color shift
- No jarring instant state changes
