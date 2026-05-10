#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# LCS Container Bootstrap
#
# Sets up a fresh Adom container for Liberty Christian School.
# Installs Claude Code, LCS skills, wiki connection, and
# everything a teacher or student needs to start building.
#
# Usage:
#   curl -fsSL https://lcs-wiki-bpd1iwhcgswk.adom.cloud/static/apps/lcs-bootstrap/bootstrap.sh | bash
#
# ──────────────────────────────────────────────────────────────
set -euo pipefail

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GOLD='\033[0;33m'
NAVY='\033[0;34m'
NC='\033[0m'

header() { echo -e "\n${BOLD}${GOLD}══ $1 ══${NC}\n"; }
ok()     { echo -e "  ${GREEN}✓${NC} $1"; }
info()   { echo -e "  ${DIM}$1${NC}"; }
warn()   { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail()   { echo -e "  ${RED}✗${NC} $1"; exit 1; }

LCS_WIKI="https://lcs-wiki-bpd1iwhcgswk.adom.cloud"
SETTINGS_FILE="$HOME/.local/share/code-server/User/settings.json"

echo ""
echo -e "${BOLD}${GOLD}  ╔═══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GOLD}  ║    Liberty Christian School Bootstrap     ║${NC}"
echo -e "${BOLD}${GOLD}  ║         Warriors Wiki Platform            ║${NC}"
echo -e "${BOLD}${GOLD}  ╚═══════════════════════════════════════════╝${NC}"
echo ""

# ── Phase 1: Prerequisites ──────────────────────────────────
header "Phase 1 · Prerequisites"

# 1a. Claude Code VS Code extension
if ls "$HOME/.local/share/code-server/extensions/anthropic.claude-code-"* &>/dev/null; then
  ok "Claude Code extension already installed"
else
  echo "  Installing Claude Code extension..."
  /usr/lib/code-server/bin/code-server --install-extension anthropic.claude-code 2>/dev/null \
    && ok "Claude Code extension installed" \
    || warn "Auto-install failed — install 'Claude Code' from Extensions panel in VS Code"
fi

# 1a2. Remove MicroPico extension (not needed for LCS)
if ls "$HOME/.local/share/code-server/extensions/paulober.pico-w-go-"* &>/dev/null 2>&1; then
  rm -rf "$HOME/.local/share/code-server/extensions/paulober.pico-w-go-"*
  # Also remove from extensions.json
  EXTS_JSON="$HOME/.local/share/code-server/extensions/extensions.json"
  if [ -f "$EXTS_JSON" ]; then
    python3 -c "
import json
with open('$EXTS_JSON') as f:
    exts = json.load(f)
filtered = [e for e in exts if e.get('identifier', {}).get('id') != 'paulober.pico-w-go']
if len(filtered) < len(exts):
    with open('$EXTS_JSON', 'w') as f:
        json.dump(filtered, f, indent=2)
"
  fi
  ok "Removed MicroPico extension (not needed for LCS)"
fi

# 1b. VS Code settings — LCS defaults
mkdir -p "$(dirname "$SETTINGS_FILE")"
if [ -f "$SETTINGS_FILE" ]; then
  python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    s = json.load(f)
changed = False
forced = {
    'github.copilot.chat.enabled': False,
    'github.copilot.enable': {'*': False},
    'chat.agent.enabled': False,
    'chat.agentsControl.enabled': False,
    'chat.unifiedAgentsBar.enabled': False,
    'workbench.secondarySideBar.defaultVisibility': 'hidden',
    'workbench.navigationControl.enabled': False,
    'claudeCode.allowDangerouslySkipPermissions': True,
    'claudeCode.initialPermissionMode': 'bypassPermissions',
    'python.interpreter.infoVisibility': 'never',
    'github.gitAuthentication': False,
    'git.enableSmartCommit': False,
    'git.autofetch': False,
    'remote.otherPortsAttributes': {'onAutoForward': 'silent'},
    'workbench.secondarySideBar.visible': False,
    'workbench.activityBar.visible': False,
    'workbench.statusBar.visible': False,
}
for k, v in forced.items():
    if s.get(k) != v:
        s[k] = v
        changed = True
defaults = {
    'workbench.colorTheme': 'Default Dark Modern',
    'claudeCode.preferredLocation': 'panel',
    'claudeCode.selectedModel': 'opus',
}
for k, v in defaults.items():
    if k not in s:
        s[k] = v
        changed = True
if changed:
    with open('$SETTINGS_FILE', 'w') as f:
        json.dump(s, f, indent=4)
    print('  \033[0;32m✓\033[0m VS Code settings configured')
else:
    print('  \033[0;32m✓\033[0m VS Code settings already configured')
"
else
  cat > "$SETTINGS_FILE" << 'SETTINGS'
{
    "workbench.colorTheme": "Default Dark Modern",
    "workbench.secondarySideBar.visible": false,
    "workbench.secondarySideBar.defaultVisibility": "hidden",
    "workbench.navigationControl.enabled": false,
    "github.copilot.chat.enabled": false,
    "github.copilot.enable": { "*": false },
    "chat.agent.enabled": false,
    "chat.agentsControl.enabled": false,
    "chat.unifiedAgentsBar.enabled": false,
    "claudeCode.preferredLocation": "panel",
    "claudeCode.selectedModel": "opus",
    "claudeCode.allowDangerouslySkipPermissions": true,
    "claudeCode.initialPermissionMode": "bypassPermissions",
    "python.interpreter.infoVisibility": "never",
    "github.gitAuthentication": false,
    "git.enableSmartCommit": false,
    "git.autofetch": false,
    "remote.otherPortsAttributes": { "onAutoForward": "silent" },
    "workbench.secondarySideBar.visible": false,
    "workbench.activityBar.visible": false,
    "workbench.statusBar.visible": false
}
SETTINGS
  ok "Created VS Code settings"
fi

# 1c. Claude Code CLI
if command -v claude &>/dev/null; then
  ok "Claude Code CLI installed ($(claude --version 2>/dev/null | head -1))"
else
  echo "  Installing Claude Code CLI..."
  curl -fsSL https://claude.ai/install.sh | bash 2>/dev/null
  export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"
  if command -v claude &>/dev/null; then
    ok "Claude Code CLI installed"
  else
    warn "Claude Code CLI install failed — install via VS Code"
  fi
fi

# Ensure PATH
if ! grep -q '/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"' >> "$HOME/.bashrc"
fi
if ! grep -q '/.local/bin' "$HOME/.profile" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"' >> "$HOME/.profile"
fi

# ── Phase 2: Authentication ─────────────────────────────────
header "Phase 2 · Authentication"

# 2a. Claude Code auth
if [ -f "$HOME/.claude/.credentials.json" ] && python3 -c "
import json
with open('$HOME/.claude/.credentials.json') as f:
    c = json.load(f)
assert 'claudeAiOauth' in c and c['claudeAiOauth'].get('accessToken')
" 2>/dev/null; then
  ok "Claude Code already authenticated"
else
  echo ""
  echo "  Claude Code authentication required."
  echo ""

  # Download the PKCE auth script (shows a URL, user authorizes, pastes code back)
  AUTH_SCRIPT="/tmp/claude-auth.mjs"
  echo "  Downloading auth helper..."
  curl -fsSL "${LCS_WIKI}/static/apps/lcs-bootstrap/claude-auth.mjs" -o "$AUTH_SCRIPT" 2>/dev/null \
    || curl -fsSL "https://wiki-ufypy5dpx93o.adom.cloud/static/apps/gallia-bundle/claude-auth.mjs" -o "$AUTH_SCRIPT" 2>/dev/null \
    || true

  if [ -f "$AUTH_SCRIPT" ]; then
    node "$AUTH_SCRIPT" < /dev/tty
  fi

  # Fall back to Claude Code CLI if the PKCE script didn't succeed
  if [ ! -f "$HOME/.claude/.credentials.json" ] || ! python3 -c "
import json
with open('$HOME/.claude/.credentials.json') as f:
    c = json.load(f)
assert 'claudeAiOauth' in c and c['claudeAiOauth'].get('accessToken')
" 2>/dev/null; then
    warn "Auth script didn't succeed. Falling back to Claude Code CLI..."
    if command -v claude &>/dev/null; then
      echo "  Select option 1 (Claude account), sign in, then exit with /exit or Ctrl+C."
      echo ""
      claude < /dev/tty || true
    else
      warn "Claude Code CLI not available. Authenticate later via the Claude Code panel in VS Code."
    fi
  fi

  if [ -f "$HOME/.claude/.credentials.json" ]; then
    ok "Claude Code credentials found"
  else
    warn "Auth incomplete — authenticate via Claude Code panel after VS Code reload"
  fi
fi

# ── Phase 3: LCS Skills ────────────────────────────────────
header "Phase 3 · Installing LCS Skills"

SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$SKILLS_DIR"

# Download LCS skills from the wiki
LCS_SKILLS=(
  "warrior-ai"
  "liberty-christian"
  "lcs-brand"
  "lcs-app-creator"
  "lcs-app-header"
  "lcs-ui-patterns"
  "lcs-strive-center"
  "lcs-skill-catalog"
  "lcs-wiki"
  "lcs-security"
  "lcs-debug"
  "lcs-screenshot"
  "lcs-bootstrap"
  "lcs-auto-discover"
)

echo "  Downloading LCS skills from Warriors Wiki..."
for skill in "${LCS_SKILLS[@]}"; do
  SKILL_DIR="$SKILLS_DIR/$skill"
  mkdir -p "$SKILL_DIR"

  # Try to get from wiki API first, fall back to static
  SKILL_URL="${LCS_WIKI}/api/v1/pages/${skill}"
  SKILL_CONTENT=$(curl -sf "$SKILL_URL" 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('page', {}).get('skill_source', ''))
except:
    print('')
" 2>/dev/null || echo "")

  if [ -n "$SKILL_CONTENT" ] && [ "$SKILL_CONTENT" != "" ]; then
    echo "$SKILL_CONTENT" > "$SKILL_DIR/SKILL.md"
    ok "$skill"
  else
    info "$skill — not found on wiki (will be available after wiki sync)"
  fi
done

# ── Phase 4: Project Setup ─────────────────────────────────
header "Phase 4 · Project Setup"

# Create project directory
mkdir -p "$HOME/project"
for d in "$HOME/project"; do
  if [ "$(stat -c '%U' "$d" 2>/dev/null)" != "$(whoami)" ]; then
    sudo chown -R "$(whoami):$(whoami)" "$d" 2>/dev/null || true
  fi
done

# Create CLAUDE.md at user level (survives project folder changes)
# Always overwrite — this is the source of truth for Claude's identity
cat > "$HOME/.claude/CLAUDE.md" << 'CLAUDEMD'
# Warrior AI — Liberty Christian School

You are **Warrior AI**, Claude running inside a Liberty Christian School container.
Your user is a teacher, student, or administrator at LCS. They may not be technical.
Be friendly, helpful, and guide them through everything step by step.

## User Identity

Read `~/.claude/lcs-config.json` to learn who your user is. It contains their name and email from the Adom platform. Use this when they ask "who am I" or to personalize your responses.

## CRITICAL RULES

1. **Read the `warrior-ai` skill FIRST on every conversation.** It has your full identity, behavior rules, and available skills.
2. **NEVER open URLs in VS Code's simple browser.** This container uses Hydrogen webviews. To show a webpage, use: `adom-cli hydrogen webview open-or-refresh --name "Page Title" --url "https://..." --panel-id <PANE_ID>`. Get pane IDs from `adom-cli hydrogen workspace tabs`.
3. **Use `adom-vscode` for VS Code operations** (open files, reveal in explorer, etc.), NOT the `code` CLI.
4. **Use LCS branding** (navy #001E60, gold #C5A44E) for all visual output.
5. **Content must be school-appropriate** — this is a Christian school.
6. **Student data is FERPA/COPPA protected** — read `lcs-security` before handling any.
7. **ALL wiki operations go through the `lcs-wiki` CLI.** Never use `curl`, `adom-wiki`, or direct API calls to any wiki. Never fall back to the Adom Wiki (`wiki-ufypy5dpx93o.adom.cloud`) — it does not exist for LCS users. If `lcs-wiki` is missing, tell the user to re-run bootstrap.

## Warriors Wiki

When the user says "the wiki" they ALWAYS mean the **LCS Warriors Wiki**, never the Adom Wiki.

- **URL:** https://lcs-wiki-bpd1iwhcgswk.adom.cloud/
- **CLI:** `lcs-wiki page search "topic"`, `lcs-wiki page publish ...`
- **Auth:** Google OAuth (@mylcs.com accounts)
- To browse: open it in a Hydrogen webview, NOT VS Code simple browser
- To search: `lcs-wiki page search "query"`

## Quick Reference

| Need | Skill to read |
|------|--------------|
| Homework, study guides, test prep | `/liberty-christian` |
| Build an app (flashcards, quiz, game) | `/lcs-app-creator` |
| School brand colors/fonts | `/lcs-brand` |
| UI rules for apps | `/lcs-ui-patterns` |
| Publish to wiki | `/lcs-wiki` |
| STRIVE Center projects | `/lcs-strive-center` |
| Full skill list | `/lcs-skill-catalog` |

## School Info

- **School:** Liberty Christian School, 1301 S Hwy 377, Argyle, TX 76226
- **STRIVE Director:** Jamie Michalek
- **Mascot:** Warriors
- **Colors:** Navy (#001E60) and Gold (#C5A44E)
- **Conference:** TAPPS Division I (6A)
CLAUDEMD
  ok "Created ~/.claude/CLAUDE.md"
else
  ok "~/.claude/CLAUDE.md already exists"
fi

# ── Phase 5: Wiki Connection ────────────────────────────────
header "Phase 5 · Wiki Connection"

echo "  Warriors Wiki: ${LCS_WIKI}"
echo ""

# Verify wiki is reachable
if curl -sf --max-time 5 "${LCS_WIKI}/health" > /dev/null 2>&1 || curl -sf --max-time 5 "${LCS_WIKI}/" > /dev/null 2>&1; then
  ok "Warriors Wiki is reachable"
else
  warn "Warriors Wiki not reachable — check your network connection"
fi

# Detect user identity from Carbon API
USER_NAME=""
USER_DISPLAY=""
USER_EMAIL=""
if command -v adom-cli &>/dev/null; then
  USER_INFO=$(adom-cli carbon user get 2>/dev/null || echo "{}")
  USER_NAME=$(echo "$USER_INFO" | python3 -c "import json,sys; print(json.load(sys.stdin).get('name',''))" 2>/dev/null || echo "")
  USER_DISPLAY=$(echo "$USER_INFO" | python3 -c "import json,sys; print(json.load(sys.stdin).get('display_name',''))" 2>/dev/null || echo "")
  USER_EMAIL=$(echo "$USER_INFO" | python3 -c "import json,sys; print(json.load(sys.stdin).get('email',''))" 2>/dev/null || echo "")
  if [ -n "$USER_DISPLAY" ]; then
    ok "User: $USER_DISPLAY ($USER_EMAIL)"
  fi
fi

# Store wiki URL + user identity for skills to reference
mkdir -p "$HOME/.claude"
python3 -c "
import json
cfg = {
    'wiki_url': '${LCS_WIKI}',
    'school': 'Liberty Christian School',
    'location': 'Argyle, TX',
    'mascot': 'Warriors',
    'user_name': '${USER_NAME}',
    'user_display_name': '${USER_DISPLAY}',
    'user_email': '${USER_EMAIL}',
}
with open('$HOME/.claude/lcs-config.json', 'w') as f:
    json.dump(cfg, f, indent=2)
"
ok "LCS config saved"

# ── Phase 5b: Auto-Discovery Hooks ──────────────────────────
header "Phase 5b · Auto-Discovery"

HOOKS_DIR="$HOME/.lcs/hooks"
mkdir -p "$HOOKS_DIR"

echo "  Downloading auto-discovery hooks..."
curl -fsSL "${LCS_WIKI}/static/apps/lcs-bootstrap/lcs-refresh-wiki-catalog.mjs" \
  -o "$HOOKS_DIR/lcs-refresh-wiki-catalog.mjs" 2>/dev/null \
  && ok "lcs-refresh-wiki-catalog.mjs" \
  || warn "Could not download refresh script"

curl -fsSL "${LCS_WIKI}/static/apps/lcs-bootstrap/lcs-check-updates.sh" \
  -o "$HOOKS_DIR/lcs-check-updates.sh" 2>/dev/null \
  && chmod +x "$HOOKS_DIR/lcs-check-updates.sh" \
  && ok "lcs-check-updates.sh" \
  || warn "Could not download check-updates hook"

# Run the refresh once to seed the lcs-wiki-discover skill
if [ -f "$HOOKS_DIR/lcs-refresh-wiki-catalog.mjs" ]; then
  echo "  Seeding wiki discovery catalog..."
  node "$HOOKS_DIR/lcs-refresh-wiki-catalog.mjs" >/dev/null 2>&1 || true
  if [ -f "$HOME/.claude/skills/lcs-wiki-discover/SKILL.md" ]; then
    ok "lcs-wiki-discover skill seeded"
  else
    info "Discovery skill will be created on first wiki catalog refresh"
  fi
fi

# Register the UserPromptSubmit hook in Claude Code settings
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
  python3 << 'HOOKPY'
import json, os

sf = os.path.expanduser("~/.claude/settings.json")
try:
    with open(sf) as f:
        s = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    s = {}

hooks = s.setdefault("hooks", {})
ups = hooks.setdefault("UserPromptSubmit", [])

hook_cmd = f"bash {os.path.expanduser('~/.lcs/hooks/lcs-check-updates.sh')}"
already = any(
    isinstance(h, dict) and
    any(hh.get("command", "") == hook_cmd for hh in h.get("hooks", []))
    for h in ups
)

if not already:
    ups.append({
        "hooks": [{
            "type": "command",
            "command": hook_cmd,
            "timeout": 15
        }]
    })
    with open(sf, "w") as f:
        json.dump(s, f, indent=2)
    print("  \033[0;32m✓\033[0m Auto-discovery hook registered in Claude Code settings")
else:
    print("  \033[0;32m✓\033[0m Auto-discovery hook already registered")
HOOKPY
else
  # Create settings with the hook
  mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
  cat > "$CLAUDE_SETTINGS" << HOOKJSON
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.lcs/hooks/lcs-check-updates.sh",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
HOOKJSON
  ok "Auto-discovery hook registered (new settings file)"
fi

# ── Phase 6: Welcome Page ───────────────────────────────────
header "Phase 6 · Warrior AI Welcome"

# Install adom-wiki CLI (wiki publishing, search, asset management)
if ! command -v adom-wiki &>/dev/null; then
  echo "  Installing adom-wiki..."
  WIKI_CLI_URL="https://wiki-ufypy5dpx93o.adom.cloud/static/apps/adom-wiki/adom-wiki"
  if curl -fsSL "$WIKI_CLI_URL" -o /tmp/adom-wiki 2>/dev/null; then
    chmod +x /tmp/adom-wiki
    sudo install -m 0755 /tmp/adom-wiki /usr/local/bin/adom-wiki
    rm -f /tmp/adom-wiki
    ok "adom-wiki installed"
  else
    warn "Could not install adom-wiki"
  fi
else
  ok "adom-wiki already installed"
fi

# Install lcs-wiki wrapper (points adom-wiki at the LCS Warriors Wiki)
echo "  Installing lcs-wiki..."
cat > /tmp/lcs-wiki << 'LCSWIKI'
#!/bin/bash
export ADOM_WIKI_API="https://lcs-wiki-bpd1iwhcgswk.adom.cloud"
exec adom-wiki "$@"
LCSWIKI
chmod +x /tmp/lcs-wiki
sudo install -m 0755 /tmp/lcs-wiki /usr/local/bin/lcs-wiki
rm -f /tmp/lcs-wiki
ok "lcs-wiki installed (Warriors Wiki CLI)"

# Install adom-cli (Adom platform CLI — hydrogen, workspace, port management)
if ! command -v adom-cli &>/dev/null; then
  echo "  Installing adom-cli..."
  ADOM_CLI_URL="https://wiki-ufypy5dpx93o.adom.cloud/static/skills/adom-cli/adom-cli"
  if curl -fsSL "$ADOM_CLI_URL" -o /tmp/adom-cli 2>/dev/null; then
    chmod +x /tmp/adom-cli
    sudo install -m 0755 /tmp/adom-cli /usr/local/bin/adom-cli
    rm -f /tmp/adom-cli
    ok "adom-cli installed"
  else
    warn "Could not install adom-cli"
  fi
else
  ok "adom-cli already installed"
fi

# Install adom-vscode CLI
if ! command -v adom-vscode &>/dev/null; then
  echo "  Installing adom-vscode..."
  VSCODE_URL="https://wiki-ufypy5dpx93o.adom.cloud/static/apps/adom-vscode/adom-vscode"
  if curl -fsSL "$VSCODE_URL" -o /tmp/adom-vscode 2>/dev/null; then
    chmod +x /tmp/adom-vscode
    sudo install -m 0755 /tmp/adom-vscode /usr/local/bin/adom-vscode
    rm -f /tmp/adom-vscode
    adom-vscode install 2>/dev/null || true
    ok "adom-vscode installed"
  else
    warn "Could not install adom-vscode"
  fi
else
  ok "adom-vscode already installed"
fi

# Clean up default Adom workspace (remove 3D workcell, etc.)
VSCODE_TYPE="adom/a1b2c3d4-eeee-4000-a000-00000000000e"
if command -v adom-cli &>/dev/null; then
  CLOSED=0
  while IFS= read -r pid; do
    [ -z "$pid" ] && continue
    adom-cli hydrogen workspace close-panel "$pid" >/dev/null 2>&1 && CLOSED=$((CLOSED + 1))
  done < <(adom-cli hydrogen workspace tabs 2>/dev/null | python3 -c "
import json, sys
try:
    tabs = json.load(sys.stdin).get('tabs', [])
    for t in tabs:
        if t.get('panelType') != '$VSCODE_TYPE':
            print(t['panelId'])
except: pass
" 2>/dev/null)
  if [ "$CLOSED" -gt 0 ]; then
    ok "Closed $CLOSED non-VS-Code panel(s) (3D workcell, etc.)"
  fi
fi

# Open Warrior AI welcome page in a webview
WELCOME_URL="${LCS_WIKI}/static/apps/lcs-bootstrap/lcs-welcome.html"
echo ""
echo -e "  ${BOLD}${GOLD}══════════════════════════════════════════════${NC}"
echo -e "  ${BOLD}${GOLD}       Opening Warrior AI Welcome Page       ${NC}"
echo -e "  ${BOLD}${GOLD}══════════════════════════════════════════════${NC}"
echo ""

if command -v adom-cli &>/dev/null; then
  # Find the VS Code pane (it's the only tab on a fresh container)
  VSCODE_PANE=$(adom-cli hydrogen workspace tabs 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    tabs = d.get('tabs', [])
    if tabs: print(tabs[0].get('panelId', ''))
except: pass
" 2>/dev/null)

  if [ -n "$VSCODE_PANE" ]; then
    # Close any wrong-type "Warrior AI" panel from a previous broken bootstrap run
    WRONG_PANE=$(adom-cli hydrogen workspace tabs 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    for t in d.get('tabs', []):
        if t.get('name') == 'Warrior AI' and t.get('panelType') != 'adom/a1b2c3d4-0031-4000-a000-000000000031':
            print(t.get('panelId', ''))
            break
except: pass
" 2>/dev/null)
    [ -n "$WRONG_PANE" ] && adom-cli hydrogen workspace close-panel "$WRONG_PANE" 2>/dev/null || true

    # Split the VS Code pane to create a right panel for the welcome page
    SPLIT_RESULT=$(adom-cli hydrogen workspace split \
      --panel-id "$VSCODE_PANE" \
      --direction horizontal \
      --panel-type "adom/a1b2c3d4-0031-4000-a000-000000000031" \
      --display-name "Warrior AI" \
      --position after \
      --ratio 0.5 2>/dev/null)

    # Get the new pane ID from the split result
    NEW_PANE=$(echo "$SPLIT_RESULT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('newPanelId', d.get('new_panel_id', '')))
except: pass
" 2>/dev/null)

    if [ -n "$NEW_PANE" ]; then
      # Navigate the new pane to the welcome page
      adom-cli hydrogen webview open-or-refresh \
        --name "Warrior AI" \
        --url "$WELCOME_URL" \
        --panel-id "$NEW_PANE" 2>/dev/null \
        && ok "Warrior AI welcome page opened in right panel" \
        || warn "Split created but could not load welcome page"
    else
      # Split didn't return a new pane — try opening in the existing pane
      adom-cli hydrogen webview open-or-refresh \
        --name "Warrior AI" \
        --url "$WELCOME_URL" \
        --panel-id "$VSCODE_PANE" 2>/dev/null \
        && ok "Warrior AI welcome page opened" \
        || warn "Could not open webview — refresh your browser tab and re-run the bootstrap"
    fi
  else
    warn "No workspace pane found — refresh your browser tab and re-run the bootstrap"
  fi
else
  warn "adom-cli not available — open this URL in a Web View tab:"
  echo -e "  ${GOLD}${WELCOME_URL}${NC}"
fi

# Reload VS Code by closing and reopening its panel.
# This forces the newly installed adom-vscode extension to activate
# without requiring a manual browser refresh.
BOOTSTRAPPED_FLAG="$HOME/.lcs/.bootstrapped"
if command -v adom-cli &>/dev/null; then
  VSCODE_PANE=$(adom-cli hydrogen workspace tabs 2>/dev/null | python3 -c "
import json, sys
try:
    for t in json.load(sys.stdin).get('tabs', []):
        if t.get('panelType') == 'adom/a1b2c3d4-eeee-4000-a000-00000000000e':
            print(t['panelId']); break
except: pass
" 2>/dev/null)

  if [ -n "$VSCODE_PANE" ]; then
    # Clear previous reload log
    rm -f "$HOME/.lcs/bootstrap-reload.log"

    # Spawn background process BEFORE closing VS Code, because closing
    # the VS Code panel kills the terminal running this script.
    # This detached process: reopens VS Code, waits for adom-vscode,
    # then sets the clean Claude Code layout.
    FIRST_RUN="false"
    [ ! -f "$BOOTSTRAPPED_FLAG" ] && FIRST_RUN="true"

    (
      echo "[$(date)] Bootstrap reload started. FIRST_RUN=$FIRST_RUN"
      sleep 2  # let the close settle

      # Find the remaining pane (Warrior AI webview) to split VS Code back into
      REMAINING_PANE=$(adom-cli hydrogen workspace tabs 2>/dev/null | python3 -c "
import json, sys
try:
    tabs = json.load(sys.stdin).get('tabs', [])
    if tabs: print(tabs[0]['panelId'])
except: pass
" 2>/dev/null)

      if [ -n "$REMAINING_PANE" ]; then
        echo "[$(date)] Splitting VS Code back into pane $REMAINING_PANE"
        adom-cli hydrogen workspace split \
          --panel-id "$REMAINING_PANE" \
          --direction horizontal \
          --panel-type "adom/a1b2c3d4-eeee-4000-a000-00000000000e" \
          --display-name "Visual Studio Code" \
          --position before \
          --ratio 0.5 2>&1
      else
        echo "[$(date)] ERROR: No remaining pane found"
      fi

      # On first bootstrap, wait for adom-vscode's websocket server to
      # come online (port 8821), then set clean layout
      if [ "$FIRST_RUN" = "true" ]; then
        echo "[$(date)] Waiting for adom-vscode health..."
        TRIES=0
        while [ $TRIES -lt 30 ]; do
          if adom-vscode health 2>&1; then
            echo "[$(date)] adom-vscode healthy after $TRIES tries"
            break
          fi
          sleep 2
          TRIES=$((TRIES + 1))
        done

        if [ $TRIES -lt 30 ]; then
          sleep 1
          echo "[$(date)] Running: adom-vscode mode claudecode"
          adom-vscode mode claudecode 2>&1
          sleep 1
          echo "[$(date)] Running: closeAuxiliaryBar"
          adom-vscode command workbench.action.closeAuxiliaryBar 2>&1
        else
          echo "[$(date)] TIMEOUT: adom-vscode never came online"
        fi

        mkdir -p "$(dirname "$BOOTSTRAPPED_FLAG")"
        touch "$BOOTSTRAPPED_FLAG"
        echo "[$(date)] Bootstrap reload complete"
      fi
    ) </dev/null >>"$HOME/.lcs/bootstrap-reload.log" 2>&1 &
    disown

    echo "  Reloading VS Code to activate extensions..."
    adom-cli hydrogen workspace close-panel "$VSCODE_PANE" >/dev/null 2>&1
    ok "VS Code reload triggered (layout will settle in a few seconds)"
  fi
fi

# ── Done ─────────────────────────────────────────────────────
header "Bootstrap Complete"

echo -e "  The Warrior AI welcome page should already be open."
echo -e "  Click the ${BOLD}orange Claude icon${NC} to start chatting."
echo ""
echo -e "  ${BOLD}Warriors Wiki:${NC} ${LCS_WIKI}"
echo ""
echo -e "  ${GOLD}${BOLD}Welcome to Warrior AI!${NC}"
echo ""
