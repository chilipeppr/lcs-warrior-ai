---
name: lcs-app-header
user-invocable: true
description: "LCS app header pattern — the canonical Warriors-branded header bar for all LCS webview apps. 44px max height, three zones: brand (Warriors shield + app name), subject (current item), actions. Must be used on every LCS app. Trigger words: app header, LCS header, warriors header, branded header, app navbar, app title bar."
---

# LCS App Header — Canonical Pattern

Every LCS app gets a consistent Warriors-branded header. This is non-negotiable — it's how students and teachers know they're using an official LCS platform app.

## Layout (44px max height)

```
┌──────────────────────────────────────────────────────────┐
│ [Shield] App Name         Subject / Context      [Actions] │
│  28px    subtitle          current item           buttons  │
└──────────────────────────────────────────────────────────┘
```

Three zones, left to right:
1. **Brand block** (left) — Warriors shield icon + app name + optional subtitle
2. **Subject** (center/left) — what the user is currently looking at
3. **Actions** (right) — buttons, toggles, search

## HTML Template

```html
<div class="lcs-header">
  <div class="lcs-header-brand">
    <img src="https://www.txhslogoproject.com/wp-content/uploads/2019/02/Argyle-Liberty-Christian-Warriors1-large-1.png"
         alt="LCS" class="lcs-header-logo"
         crossorigin="anonymous" onerror="this.style.display='none'">
    <div class="lcs-header-text">
      <span class="lcs-header-name">App Name</span>
      <span class="lcs-header-subtitle">subtitle</span>
    </div>
  </div>
  <div class="lcs-header-subject">
    <!-- current context -->
  </div>
  <div class="lcs-header-actions">
    <!-- action buttons -->
  </div>
</div>
```

## CSS

```css
.lcs-header {
  display: flex;
  align-items: center;
  height: 44px;
  padding: 0 16px;
  background: #001E60;
  border-bottom: 2px solid #C5A44E;
  font-family: 'Source Sans Pro', sans-serif;
  gap: 12px;
  flex-shrink: 0;
}

.lcs-header-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
}

.lcs-header-logo {
  height: 28px;
  width: auto;
  filter: drop-shadow(0 1px 3px rgba(0,0,0,.4));
}

.lcs-header-text {
  display: flex;
  flex-direction: column;
  line-height: 1.2;
}

.lcs-header-name {
  font-size: 14px;
  font-weight: 700;
  color: #C5A44E;
  letter-spacing: 0.3px;
}

.lcs-header-subtitle {
  font-size: 11px;
  color: #8899AA;
}

.lcs-header-subject {
  flex: 1;
  font-size: 13px;
  color: #E8E8E8;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.lcs-header-actions {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
}

.lcs-header-actions button {
  padding: 4px 12px;
  border-radius: 6px;
  border: 1px solid #243A6A;
  background: rgba(197,164,78,0.1);
  color: #C5A44E;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s ease;
  font-family: 'Source Sans Pro', sans-serif;
}

.lcs-header-actions button:hover {
  background: rgba(197,164,78,0.2);
  border-color: #C5A44E;
}
```

## Rules
- **44px max height** — never taller. Content scrolls below the header; the header stays fixed.
- **Warriors shield always present** — top-left, 28px height. No exceptions.
- **Gold app name** — `#C5A44E`, Source Sans Pro 700, 14px
- **Navy background** — `#001E60`, gold bottom border `2px solid #C5A44E`
- **No hamburger menus** — if you need navigation, use tabs below the header
- **Responsive** — on small screens, hide the subject zone and keep brand + actions
