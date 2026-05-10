#!/usr/bin/env bash
# lcs-check-updates — fires on UserPromptSubmit.
# Runs lcs-refresh-wiki-catalog.mjs on a 30-min cadence to keep the
# lcs-wiki-discover skill fresh and surface stale-tool upgrade prompts.
set -euo pipefail

LCS_DIR="${HOME}/.lcs"
WIKI_STAMP="${LCS_DIR}/last-wiki-check"
WIKI_FAIL_STAMP="${LCS_DIR}/last-wiki-fetch-fail"
WIKI_INTERVAL="${LCS_WIKI_INTERVAL:-1800}"
WIKI_RETRY_INTERVAL=300
LCS_WIKI="https://lcs-wiki-bpd1iwhcgswk.adom.cloud"

mkdir -p "$LCS_DIR"

# ─────────────────────────────────────────────────────────────────
# First-run: set Claude Code mode (clean VS Code layout)
# The bootstrap sets ~/.lcs/.needs-claudecode-mode on first install.
# After the user reloads their browser and adom-vscode is active,
# this fires once to set up the clean Claude Code layout, then
# removes the flag and writes ~/.lcs/.bootstrapped so it never
# runs again.
# ─────────────────────────────────────────────────────────────────
CLAUDECODE_FLAG="${LCS_DIR}/.needs-claudecode-mode"
BOOTSTRAPPED_FLAG="${LCS_DIR}/.bootstrapped"
if [ -f "$CLAUDECODE_FLAG" ] && command -v adom-vscode &>/dev/null; then
  adom-vscode mode claudecode >/dev/null 2>&1 || true
  rm -f "$CLAUDECODE_FLAG"
  touch "$BOOTSTRAPPED_FLAG"
fi

# ─────────────────────────────────────────────────────────────────
# Wiki catalog refresh + stale-tool audit
# ─────────────────────────────────────────────────────────────────
STALE_REMINDER=""

should_check_wiki=0
if [ -n "${LCS_HOOK_FORCE:-}" ]; then
  should_check_wiki=1
elif [ ! -f "$WIKI_STAMP" ]; then
  should_check_wiki=1
else
  AGE=$(( $(date +%s) - $(stat -c %Y "$WIKI_STAMP" 2>/dev/null || echo 0) ))
  if [ "$AGE" -ge "$WIKI_INTERVAL" ]; then
    if [ -f "$WIKI_FAIL_STAMP" ]; then
      FAIL_AGE=$(( $(date +%s) - $(stat -c %Y "$WIKI_FAIL_STAMP" 2>/dev/null || echo 0) ))
      [ "$FAIL_AGE" -ge "$WIKI_RETRY_INTERVAL" ] && should_check_wiki=1
    else
      should_check_wiki=1
    fi
  fi
fi

if [ "$should_check_wiki" = "1" ]; then
  WIKI_SCRIPT="${LCS_DIR}/hooks/lcs-refresh-wiki-catalog.mjs"
  if [ -f "$WIKI_SCRIPT" ]; then
    WIKI_OUT=$(node "$WIKI_SCRIPT" 2>/dev/null || echo '{"ok":false}')
    if echo "$WIKI_OUT" | grep -q '"ok":true'; then
      touch "$WIKI_STAMP"
    fi

    # Auto-upgrade lcs-wiki if stale (same pattern as adom-wiki auto-upgrade)
    if echo "$WIKI_OUT" | grep -q '"name":"lcs-wiki"'; then
      LCS_WIKI_INSTALLED=$(lcs-wiki --version 2>/dev/null | grep -oP '[\d.]+' || echo "0.0.0")
      LCS_WIKI_CATALOG=$(echo "$WIKI_OUT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for t in d.get('stale',[]):
  if t['name']=='lcs-wiki': print(t['catalog']); break
" 2>/dev/null || echo "")
      if [ -n "$LCS_WIKI_CATALOG" ] && [ "$LCS_WIKI_CATALOG" != "$LCS_WIKI_INSTALLED" ]; then
        (
          curl -fsSL "${LCS_WIKI}/static/apps/lcs-wiki/lcs-wiki" \
            -o /tmp/lcs-wiki-upgrade && \
          chmod +x /tmp/lcs-wiki-upgrade && \
          sudo install -m 0755 /tmp/lcs-wiki-upgrade /usr/local/bin/lcs-wiki && \
          rm -f /tmp/lcs-wiki-upgrade
        ) >/dev/null 2>&1 || true
      fi
    fi

    STALE_REMINDER=$(WIKI_OUT_JSON="$WIKI_OUT" python3 <<'PY'
import json, os, re, sys, urllib.request, urllib.error

PLACEHOLDER_PATTERNS = [
  re.compile(r'^\s*release\s+v?[\d.]+\s*$', re.IGNORECASE),
  re.compile(r'^\s*v?[\d.]+\s+release\s*$', re.IGNORECASE),
  re.compile(r'^\s*initial\s+publication\s*$', re.IGNORECASE),
]

def is_placeholder(text):
  if not text or not text.strip():
    return True
  return any(p.match(text) for p in PLACEHOLDER_PATTERNS)

def parse_semver(v):
  try:
    parts = re.match(r'^v?(\d+)\.(\d+)\.(\d+)', (v or '').strip()).groups()
    return tuple(int(p) for p in parts)
  except Exception:
    return (0, 0, 0)

def fetch_versions(wiki_base, slug, installed_v):
  try:
    url = f"{wiki_base}/api/v1/pages/{slug}/versions"
    req = urllib.request.Request(url, headers={
      'Accept': 'application/json',
      'User-Agent': 'lcs-update-hook/1.0',
    })
    with urllib.request.urlopen(req, timeout=4) as resp:
      data = json.loads(resp.read().decode('utf-8', errors='replace'))
  except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, json.JSONDecodeError, OSError):
    return []
  versions = data.get('versions') or []
  installed_t = parse_semver(installed_v)
  picked = []
  for v in versions:
    vt = parse_semver(v.get('version', ''))
    if vt <= installed_t:
      continue
    text = (v.get('changelog') or '').strip()
    if is_placeholder(text):
      continue
    picked.append((vt, v.get('version', ''), text))
  picked.sort(reverse=True)
  return picked

def truncate(text, n=250):
  text = text.replace('\n', ' ').replace('  ', ' ').strip()
  return text[:n-3].rsplit(' ', 1)[0] + '...' if len(text) > n else text

def wiki_base_from_hint(hint):
  m = re.search(r'(https?://[^/\s]+)', hint or '')
  return m.group(1) if m else ''

try:
  d = json.loads(os.environ.get('WIKI_OUT_JSON') or '{}')
  stale = d.get('stale') or []
  if not stale:
    sys.exit(0)
  lines = [
    "**Adom tool updates are available on the Adom Wiki.**",
    "Ask the user if they'd like to upgrade NOW. Do NOT run any install commands without explicit confirmation. Phrase it like: \"Shall I upgrade <tool> from <installed> → <catalog>? It'll run: `<install_hint>`\". If the user declines, respect that — don't re-ask this session.",
    "",
  ]
  for t in stale[:3]:
    name = t['name']
    lines.append(f"- **{name}** {t['installed']} → {t['catalog']}")
    base = wiki_base_from_hint(t.get('install_hint') or '')
    if base:
      picked = fetch_versions(base, name, t['installed'])
      if picked:
        lines.append("  What's new:")
        shown = picked[:5]
        for _, ver, text in shown:
          lines.append(f"    v{ver} — {truncate(text)}")
        if len(picked) > len(shown):
          lines.append(f"    (+{len(picked)-len(shown)} more versions)")
    lines.append(f"  Install: `{t['install_hint']}`")
  if len(stale) > 3:
    lines.append(f"- (+{len(stale)-3} more stale)")
  print("\n".join(lines))
except Exception:
  pass
PY
    )
  fi
fi

# ─────────────────────────────────────────────────────────────────
# Compose system-reminder if stale tools found
# ─────────────────────────────────────────────────────────────────
if [ -z "$STALE_REMINDER" ]; then
  exit 0
fi

REMINDER="<system-reminder>
$STALE_REMINDER
</system-reminder>"

SUMMARY="LCS tool updates available on the wiki — offer upgrade"

REMINDER="$REMINDER" SUMMARY="$SUMMARY" python3 <<'PY'
import json, os
print(json.dumps({
    "systemMessage": os.environ.get('SUMMARY', ''),
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": os.environ.get('REMINDER', ''),
    },
}))
PY
