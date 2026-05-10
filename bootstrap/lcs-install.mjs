#!/usr/bin/env node
// ──────────────────────────────────────────────────────────────
// lcs-install.mjs — Wiki-driven installer for LCS Warrior AI containers
//
// Fetches all skills from the LCS Wiki API and deploys them locally.
// Installs/upgrades Tier A CLIs. Configures Claude Code settings + hooks.
//
// Admin gate: only admins can UPDATE this file on the wiki (publish API
// requires admin auth). All users can RUN it to stay current.
//
// Called from:
//   1. LCS bootstrap (initial setup)
//   2. lcs-check-updates.sh (every 30 min when installer hash changes)
//   3. Manual: node ~/.lcs/lcs-install.mjs
// ──────────────────────────────────────────────────────────────

import { createHash } from 'node:crypto';
import { execSync } from 'node:child_process';
import {
  existsSync, mkdirSync, readFileSync, readdirSync, renameSync,
  unlinkSync, writeFileSync,
} from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { homedir } from 'node:os';

const HOME = homedir();
const WIKI = process.env.LCS_WIKI_URL || 'https://lcs-wiki-bpd1iwhcgswk.adom.cloud';
const FETCH_TIMEOUT_MS = 15_000;

const BOLD = '\x1b[1m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const GOLD = '\x1b[0;33m';
const DIM = '\x1b[2m';
const NC = '\x1b[0m';

const ok = (msg) => console.log(`  ${GREEN}✓${NC} ${msg}`);
const warn = (msg) => console.log(`  ${YELLOW}⚠${NC} ${msg}`);
const header = (msg) => console.log(`\n${BOLD}${GOLD}══ ${msg} ══${NC}\n`);

// ── PID lock ────────────────────────────────────────────────
const LOCK_PATH = '/tmp/lcs-install.pid';
function pidAlive(pid) {
  try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
}
if (existsSync(LOCK_PATH)) {
  const other = parseInt(readFileSync(LOCK_PATH, 'utf-8').trim(), 10);
  if (other && other !== process.pid && pidAlive(other)) {
    console.error(`\n✗ lcs-install.mjs is already running (pid ${other}).`);
    console.error(`  If stale: kill ${other} && rm ${LOCK_PATH}\n`);
    process.exit(1);
  }
  try { unlinkSync(LOCK_PATH); } catch {}
}
writeFileSync(LOCK_PATH, String(process.pid));
function releaseLock() {
  try {
    if (existsSync(LOCK_PATH)) {
      const held = parseInt(readFileSync(LOCK_PATH, 'utf-8').trim(), 10);
      if (held === process.pid) unlinkSync(LOCK_PATH);
    }
  } catch {}
}
process.on('exit', releaseLock);
for (const sig of ['SIGINT', 'SIGTERM', 'SIGHUP']) {
  process.on(sig, () => { releaseLock(); process.exit(1); });
}

async function fetchWithTimeout(url, timeoutMs = FETCH_TIMEOUT_MS) {
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), timeoutMs);
  try { return await fetch(url, { signal: ac.signal }); }
  finally { clearTimeout(timer); }
}

function sha256(data) {
  return createHash('sha256').update(data).digest('hex');
}

function parseSemver(s) {
  const m = String(s || '').match(/(\d+)\.(\d+)\.(\d+)/);
  return m ? [parseInt(m[1]), parseInt(m[2]), parseInt(m[3])] : null;
}

function compareSemver(a, b) {
  const pa = parseSemver(a), pb = parseSemver(b);
  if (!pa || !pb) return 0;
  for (let i = 0; i < 3; i++) {
    if (pa[i] < pb[i]) return -1;
    if (pa[i] > pb[i]) return 1;
  }
  return 0;
}

function installedVersion(bin) {
  try {
    const out = execSync(`${bin} --version`, { stdio: ['ignore', 'pipe', 'pipe'], timeout: 3000, encoding: 'utf8' });
    const m = out.match(/(\d+\.\d+\.\d+)/);
    return m ? m[1] : null;
  } catch { return null; }
}

function isInstalled(bin) {
  try { execSync(`command -v ${bin}`, { stdio: 'pipe' }); return true; }
  catch { return false; }
}

// ══════════════════════════════════════════════════════════════
// Section 1: Deploy ALL skills from the wiki
// ══════════════════════════════════════════════════════════════
async function deploySkills() {
  header('Section 1 · Skills');

  let pages;
  try {
    const r = await fetchWithTimeout(`${WIKI}/api/v1/pages?type=skill`);
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const data = await r.json();
    pages = Array.isArray(data) ? data : (data.pages || []);
  } catch (e) {
    warn(`Could not fetch skills from wiki: ${e.message}`);
    return;
  }

  const skillsDir = join(HOME, '.claude', 'skills');
  const deployedSlugs = new Set();
  let installed = 0, skipped = 0;

  for (const page of pages) {
    if (!page.skill_source || !page.slug) continue;
    const slug = page.slug;
    deployedSlugs.add(slug);
    const dir = join(skillsDir, slug);
    const file = join(dir, 'SKILL.md');

    // Skip if content unchanged
    if (existsSync(file)) {
      try {
        const existing = readFileSync(file, 'utf-8');
        if (sha256(existing) === sha256(page.skill_source)) {
          skipped++;
          continue;
        }
      } catch {}
    }

    // Atomic write
    mkdirSync(dir, { recursive: true });
    const tmp = file + '.tmp';
    writeFileSync(tmp, page.skill_source);
    renameSync(tmp, file);
    installed++;
  }

  // Clean up skills that no longer exist on the wiki
  // Only remove lcs-* prefixed skills (don't touch adom-* or other skills)
  let removed = 0;
  try {
    for (const entry of readdirSync(skillsDir)) {
      if (entry.startsWith('lcs-') && !deployedSlugs.has(entry)) {
        const skillDir = join(skillsDir, entry);
        try {
          unlinkSync(join(skillDir, 'SKILL.md'));
          try { unlinkSync(skillDir); } catch {} // rmdir if empty
          removed++;
        } catch {}
      }
    }
  } catch {}

  // Also deploy warrior-ai and liberty-christian (non lcs- prefix)
  // These are already in deployedSlugs from the wiki fetch

  ok(`${installed} skills installed, ${skipped} unchanged${removed ? `, ${removed} removed` : ''} (${pages.length} total on wiki)`);
}

// ══════════════════════════════════════════════════════════════
// Section 2: Tier A CLIs
// ══════════════════════════════════════════════════════════════
async function deployTierACLIs() {
  header('Section 2 · Tier A CLIs');

  const ADOM_WIKI = 'https://wiki-ufypy5dpx93o.adom.cloud';

  const clis = [
    { name: 'adom-cli', url: `${ADOM_WIKI}/static/skills/adom-cli/adom-cli` },
    { name: 'adom-wiki', url: `${ADOM_WIKI}/static/apps/adom-wiki/adom-wiki` },
    { name: 'adom-vscode', url: `${ADOM_WIKI}/static/apps/adom-vscode/adom-vscode` },
  ];

  for (const cli of clis) {
    if (isInstalled(cli.name)) {
      ok(`${cli.name} already installed`);
      continue;
    }
    try {
      console.log(`  Installing ${cli.name}...`);
      const r = await fetchWithTimeout(cli.url);
      if (!r.ok) { warn(`${cli.name}: HTTP ${r.status}`); continue; }
      const buf = Buffer.from(await r.arrayBuffer());
      const tmp = `/tmp/${cli.name}-install`;
      writeFileSync(tmp, buf, { mode: 0o755 });
      execSync(`sudo install -m 0755 ${tmp} /usr/local/bin/${cli.name}`, { stdio: 'pipe' });
      unlinkSync(tmp);
      ok(`${cli.name} installed`);
    } catch (e) {
      warn(`${cli.name}: ${e.message}`);
    }
  }

  // lcs-wiki wrapper (always re-create to ensure correct wiki URL)
  const lcsWikiScript = `#!/bin/bash\nexport ADOM_WIKI_API="${WIKI}"\nexec adom-wiki "$@"\n`;
  writeFileSync('/tmp/lcs-wiki-install', lcsWikiScript, { mode: 0o755 });
  try {
    execSync('sudo install -m 0755 /tmp/lcs-wiki-install /usr/local/bin/lcs-wiki', { stdio: 'pipe' });
    unlinkSync('/tmp/lcs-wiki-install');
    ok('lcs-wiki wrapper installed');
  } catch (e) {
    warn(`lcs-wiki: ${e.message}`);
  }
}

// ══════════════════════════════════════════════════════════════
// Section 3: Claude Code settings + hooks
// ══════════════════════════════════════════════════════════════
async function configureSettings() {
  header('Section 3 · Claude Code Settings');

  // Ensure PATH
  for (const rcFile of ['.bashrc', '.profile']) {
    const rc = join(HOME, rcFile);
    try {
      const content = existsSync(rc) ? readFileSync(rc, 'utf-8') : '';
      if (!content.includes('/.local/bin')) {
        writeFileSync(rc, content + '\nexport PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH"\n');
      }
    } catch {}
  }

  // Claude Code settings.json
  const settingsPath = join(HOME, '.claude', 'settings.json');
  let settings = {};
  try { settings = JSON.parse(readFileSync(settingsPath, 'utf-8')); } catch {}

  // Register UserPromptSubmit hook
  const hooks = settings.hooks = settings.hooks || {};
  const ups = hooks.UserPromptSubmit = hooks.UserPromptSubmit || [];
  const hookCmd = `bash ${HOME}/.lcs/hooks/lcs-check-updates.sh`;
  const hookExists = ups.some(h =>
    Array.isArray(h?.hooks) && h.hooks.some(hh => hh?.command === hookCmd)
  );
  if (!hookExists) {
    ups.push({ hooks: [{ type: 'command', command: hookCmd, timeout: 15 }] });
  }

  writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
  ok('Claude Code settings configured');

  // VS Code settings
  const vsSettingsPath = join(HOME, '.local/share/code-server/User/settings.json');
  let vsSettings = {};
  try { vsSettings = JSON.parse(readFileSync(vsSettingsPath, 'utf-8')); } catch {}

  const forced = {
    'remote.otherPortsAttributes': { onAutoForward: 'silent' },
    'claudeCode.allowDangerouslySkipPermissions': true,
    'claudeCode.initialPermissionMode': 'bypassPermissions',
  };
  let changed = false;
  for (const [k, v] of Object.entries(forced)) {
    if (JSON.stringify(vsSettings[k]) !== JSON.stringify(v)) {
      vsSettings[k] = v;
      changed = true;
    }
  }
  if (changed) {
    mkdirSync(dirname(vsSettingsPath), { recursive: true });
    writeFileSync(vsSettingsPath, JSON.stringify(vsSettings, null, 4));
  }
  ok('VS Code settings configured');
}

// ══════════════════════════════════════════════════════════════
// Section 4: Discovery catalog
// ══════════════════════════════════════════════════════════════
async function refreshDiscovery() {
  header('Section 4 · Discovery Catalog');

  const refreshScript = join(HOME, '.lcs/hooks/lcs-refresh-wiki-catalog.mjs');
  if (existsSync(refreshScript)) {
    try {
      execSync(`node ${refreshScript}`, { stdio: 'pipe', timeout: 20000 });
      ok('Wiki discovery catalog refreshed');
    } catch (e) {
      warn(`Discovery refresh failed: ${e.message}`);
    }
  } else {
    warn('lcs-refresh-wiki-catalog.mjs not found — run bootstrap first');
  }
}

// ══════════════════════════════════════════════════════════════
// Section 5: Stamp
// ══════════════════════════════════════════════════════════════
function stampInstall() {
  const stampDir = join(HOME, '.lcs');
  mkdirSync(stampDir, { recursive: true });

  // Hash this installer file so check-updates can detect changes
  try {
    const self = readFileSync(new URL(import.meta.url).pathname, 'utf-8');
    writeFileSync(join(stampDir, 'last-install-hash'), sha256(self));
  } catch {}
}

// ══════════════════════════════════════════════════════════════
// Main
// ══════════════════════════════════════════════════════════════
async function main() {
  console.log(`\n${BOLD}${GOLD}  LCS Warrior AI Installer${NC}`);
  console.log(`${DIM}  Wiki: ${WIKI}${NC}\n`);

  await deploySkills();
  await deployTierACLIs();
  await configureSettings();
  await refreshDiscovery();
  stampInstall();

  header('Install Complete');
  ok('All skills and tools are up to date');
}

main().catch(e => {
  console.error(`\n✗ Install failed: ${e.message}\n`);
  process.exit(1);
});
