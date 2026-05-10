#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# LCS Container Unbootstrap
#
# Reverses the LCS bootstrap to restore a container to its
# pre-bootstrap state. Use this to test the bootstrap experience
# from scratch without spinning up a new container.
#
# Does NOT touch: Claude Code CLI, Claude Code extension,
#                 Claude Code auth credentials, or PATH entries.
#
# Usage:
#   curl -fsSL https://lcs-wiki-bpd1iwhcgswk.adom.cloud/static/apps/lcs-bootstrap/unbootstrap.sh | bash
#
# ──────────────────────────────────────────────────────────────
set -euo pipefail

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GOLD='\033[0;33m'
NC='\033[0m'

header() { echo -e "\n${BOLD}${GOLD}══ $1 ══${NC}\n"; }
ok()     { echo -e "  ${GREEN}✓${NC} $1"; }
info()   { echo -e "  ${DIM}$1${NC}"; }
warn()   { echo -e "  ${YELLOW}⚠${NC} $1"; }

SETTINGS_FILE="$HOME/.local/share/code-server/User/settings.json"

echo ""
echo -e "${BOLD}${GOLD}  ╔═══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GOLD}  ║   Liberty Christian School Unbootstrap    ║${NC}"
echo -e "${BOLD}${GOLD}  ║     Resets container to pre-bootstrap     ║${NC}"
echo -e "${BOLD}${GOLD}  ╚═══════════════════════════════════════════╝${NC}"
echo ""

# ── Phase 1: Close Warrior AI Webview ──────────────────────
# Must happen before adom-cli is removed in Phase 4
header "Phase 1 · Closing Warrior AI Webview"

if command -v adom-cli &>/dev/null; then
  WARRIOR_PANE=$(adom-cli hydrogen workspace tabs 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    for t in d.get('tabs', []):
        if t.get('name') == 'Warrior AI':
            print(t.get('panelId', ''))
            break
except: pass
" 2>/dev/null)
  if [ -n "$WARRIOR_PANE" ]; then
    adom-cli hydrogen workspace close-panel "$WARRIOR_PANE" 2>/dev/null \
      && ok "Closed Warrior AI webview pane" \
      || warn "Could not close Warrior AI pane — close it manually"
  else
    info "Warrior AI webview pane — not present"
  fi
else
  info "adom-cli not installed — no webview to close"
fi

# ── Phase 2: Remove LCS Skills ──────────────────────────────
header "Phase 2 · Removing LCS Skills"

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
  "lcs-wiki-discover"
  "adom-vscode"
)

SKILLS_DIR="$HOME/.claude/skills"
for skill in "${LCS_SKILLS[@]}"; do
  SKILL_DIR="$SKILLS_DIR/$skill"
  if [ -d "$SKILL_DIR" ]; then
    rm -rf "$SKILL_DIR"
    ok "Removed $skill"
  else
    info "$skill — not present"
  fi
done

# ── Phase 3: Remove CLAUDE.md ───────────────────────────────
header "Phase 3 · Removing CLAUDE.md"

if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  rm -f "$HOME/.claude/CLAUDE.md"
  ok "Removed ~/.claude/CLAUDE.md"
else
  info "~/.claude/CLAUDE.md — not present"
fi

# Also remove from project folder (written by older bootstrap versions)
if [ -f "$HOME/project/CLAUDE.md" ]; then
  rm -f "$HOME/project/CLAUDE.md"
  ok "Removed ~/project/CLAUDE.md (old bootstrap location)"
fi

# ── Phase 4: Remove LCS Config ─────────────────────────────
header "Phase 4 · Removing LCS Config"

if [ -f "$HOME/.claude/lcs-config.json" ]; then
  rm -f "$HOME/.claude/lcs-config.json"
  ok "Removed ~/.claude/lcs-config.json"
else
  info "lcs-config.json — not present"
fi

# ── Phase 4b: Remove Auto-Discovery ──────────────────────────
header "Phase 4b · Removing Auto-Discovery"

# Remove hooks directory
if [ -d "$HOME/.lcs/hooks" ]; then
  rm -rf "$HOME/.lcs/hooks"
  ok "Removed ~/.lcs/hooks/"
  # Remove ~/.lcs if empty
  rmdir "$HOME/.lcs" 2>/dev/null && ok "Removed empty ~/.lcs/" || true
else
  info "~/.lcs/hooks — not present"
fi

# Remove UserPromptSubmit hook from Claude Code settings
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
  python3 << 'CLEANPY'
import json, os

sf = os.path.expanduser("~/.claude/settings.json")
try:
    with open(sf) as f:
        s = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    s = {}

hooks = s.get("hooks", {})
ups = hooks.get("UserPromptSubmit", [])
hook_cmd = f"bash {os.path.expanduser('~/.lcs/hooks/lcs-check-updates.sh')}"

filtered = [
    h for h in ups
    if not (isinstance(h, dict) and
            any(hh.get("command", "") == hook_cmd for hh in h.get("hooks", [])))
]

if len(filtered) < len(ups):
    if filtered:
        hooks["UserPromptSubmit"] = filtered
    else:
        hooks.pop("UserPromptSubmit", None)
    if not hooks:
        s.pop("hooks", None)
    with open(sf, "w") as f:
        json.dump(s, f, indent=2)
    print("  \033[0;32m✓\033[0m Removed auto-discovery hook from Claude Code settings")
else:
    print("  \033[2mAuto-discovery hook — not present in settings\033[0m")
CLEANPY
fi

# ── Phase 5: Remove Installed CLIs ─────────────────────────
header "Phase 5 · Removing LCS CLIs"

for bin in adom-wiki lcs-wiki adom-cli adom-vscode; do
  if [ -f "/usr/local/bin/$bin" ]; then
    sudo rm -f "/usr/local/bin/$bin"
    ok "Removed $bin"
  else
    info "$bin — not present"
  fi
done

# Remove adom-vscode VS Code extension (files + extensions.json entry)
if ls "$HOME/.local/share/code-server/extensions/adom.adom-vscode-"* &>/dev/null 2>&1; then
  rm -rf "$HOME/.local/share/code-server/extensions/adom.adom-vscode-"*
  ok "Removed adom-vscode VS Code extension files"
else
  info "adom-vscode VS Code extension files — not present"
fi
# Always clean the extensions.json entry — stale entry blocks reinstall
EXTS_JSON="$HOME/.local/share/code-server/extensions/extensions.json"
if [ -f "$EXTS_JSON" ]; then
  python3 -c "
import json
with open('$EXTS_JSON') as f:
    exts = json.load(f)
filtered = [e for e in exts if e.get('identifier', {}).get('id') != 'adom.adom-vscode']
if len(filtered) < len(exts):
    with open('$EXTS_JSON', 'w') as f:
        json.dump(filtered, f, indent=2)
    print('  \033[0;32m✓\033[0m Removed adom.adom-vscode from extensions.json')
else:
    print('  \033[2madom.adom-vscode not in extensions.json\033[0m')
"
fi

# ── Phase 6: Remove Welcome Page ───────────────────────────
header "Phase 6 · Removing Welcome Page"

if [ -f "$HOME/project/warrior-ai-welcome.html" ]; then
  rm -f "$HOME/project/warrior-ai-welcome.html"
  ok "Removed warrior-ai-welcome.html"
else
  info "warrior-ai-welcome.html — not present"
fi

# ── Phase 7: Restore VS Code Settings ──────────────────────
header "Phase 7 · Restoring VS Code Settings"

if [ -f "$SETTINGS_FILE" ]; then
  python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    s = json.load(f)

keys_to_remove = [
    'github.copilot.chat.enabled',
    'github.copilot.enable',
    'chat.agent.enabled',
    'chat.agentsControl.enabled',
    'chat.unifiedAgentsBar.enabled',
    'workbench.secondarySideBar.defaultVisibility',
    'workbench.secondarySideBar.visible',
    'workbench.navigationControl.enabled',
    'claudeCode.allowDangerouslySkipPermissions',
    'claudeCode.initialPermissionMode',
    'claudeCode.preferredLocation',
    'claudeCode.selectedModel',
    'python.interpreter.infoVisibility',
    'github.gitAuthentication',
    'git.enableSmartCommit',
    'git.autofetch',
    'remote.otherPortsAttributes',
    'workbench.secondarySideBar.visible',
    'workbench.activityBar.visible',
    'workbench.statusBar.visible',
]

removed = [k for k in keys_to_remove if k in s]
for k in removed:
    del s[k]

with open('$SETTINGS_FILE', 'w') as f:
    json.dump(s, f, indent=4)

if removed:
    print('  \033[0;32m✓\033[0m Removed LCS VS Code settings: ' + ', '.join(removed))
else:
    print('  \033[2mVS Code settings — nothing to remove\033[0m')
"
else
  info "VS Code settings file — not present"
fi

# ── Done ─────────────────────────────────────────────────────
header "Unbootstrap Complete"

echo -e "  Container is reset to pre-bootstrap state."
echo -e "  Claude Code auth and CLI are preserved."
echo ""
echo -e "  ${BOLD}Refresh your browser tab now${NC} to reload VS Code cleanly."
echo ""
echo -e "  Then re-run bootstrap:"
echo -e "  ${GOLD}curl -fsSL https://lcs-wiki-bpd1iwhcgswk.adom.cloud/static/apps/lcs-bootstrap/bootstrap.sh | bash${NC}"
echo ""
