#!/usr/bin/env node
// lcs-refresh-wiki-catalog.mjs — pull the discovery catalog from the LCS
// Warriors Wiki and compare installed tool versions against it.
//
// Called from:
//   1. LCS bootstrap (initial seed)
//   2. ~/.lcs/hooks/lcs-check-updates.sh — every ~30 min on UserPromptSubmit
//
// Responsibilities:
//   1. Refresh ~/.claude/skills/lcs-wiki-discover/SKILL.md from the wiki's
//      /discover endpoint, atomic-write, only if content changed (sha256).
//   2. Audit every wiki page whose metadata contains `releases.adom_docker`.
//      For each such page, if the tool is installed locally AND its installed
//      version is older than the page's `pub_version`, report it as stale.

import { createHash } from 'node:crypto';
import { execFileSync, execSync } from 'node:child_process';
import {
  existsSync, mkdirSync, openSync, readFileSync, renameSync,
  statSync, unlinkSync, writeFileSync, closeSync,
} from 'node:fs';
import { dirname, resolve } from 'node:path';
import { homedir } from 'node:os';

const WIKI = process.env.LCS_WIKI_URL || 'https://lcs-wiki-bpd1iwhcgswk.adom.cloud';
const FETCH_TIMEOUT_MS = 10_000;
const HEAD_TIMEOUT_MS = 5_000;
const VERSION_CMD_TIMEOUT_MS = 2_000;

const HOME = homedir();
const SKILL_FILES = [
  resolve(HOME, '.claude/skills/lcs-wiki-discover/SKILL.md'),
];
const LOCK_FILE = resolve(HOME, '.lcs/.wiki-catalog.lock');
const FAIL_STAMP = resolve(HOME, '.lcs/last-wiki-fetch-fail');

function acquireLockOrExit() {
  mkdirSync(dirname(LOCK_FILE), { recursive: true });
  try {
    const fd = openSync(LOCK_FILE, 'wx');
    const release = () => { try { closeSync(fd); } catch {} try { unlinkSync(LOCK_FILE); } catch {} };
    process.on('exit', release);
    process.on('SIGINT', () => { release(); process.exit(0); });
    process.on('SIGTERM', () => { release(); process.exit(0); });
    return;
  } catch (e) {
    if (e.code === 'EEXIST') {
      try {
        const ageMs = Date.now() - statSync(LOCK_FILE).mtimeMs;
        if (ageMs > 60_000) { unlinkSync(LOCK_FILE); return acquireLockOrExit(); }
      } catch {}
      emit({ ok: true, snippet_updated: false, stale: [], skipped: 'locked' });
      process.exit(0);
    }
    throw e;
  }
}

function emit(obj) { process.stdout.write(JSON.stringify(obj) + '\n'); }
function sha256(buf) { return createHash('sha256').update(buf).digest('hex'); }

function parseSemver(s) {
  if (!s) return null;
  const m = String(s).match(/(\d+)\.(\d+)\.(\d+)/);
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

function pluralOf(type) {
  switch (type) {
    case 'library': return 'libraries';
    case '3dcomp': return '3dcomps';
    default: return type + 's';
  }
}

async function fetchWithTimeout(url, opts = {}, timeoutMs = FETCH_TIMEOUT_MS) {
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), timeoutMs);
  try { return await fetch(url, { ...opts, signal: ac.signal }); }
  finally { clearTimeout(timer); }
}

function isInstalled(bin) {
  try {
    execSync(`command -v ${JSON.stringify(bin)}`, { stdio: 'pipe' });
    return true;
  } catch { return false; }
}

function installedVersion(bin, versionCmd) {
  const cmd = versionCmd || `${bin} --version`;
  try {
    const out = execSync(cmd, { stdio: ['ignore', 'pipe', 'pipe'], timeout: VERSION_CMD_TIMEOUT_MS, encoding: 'utf8' });
    const m = out.match(/(\d+\.\d+\.\d+)/);
    return m ? m[1] : null;
  } catch { return null; }
}

function markFail(err) {
  try { mkdirSync(dirname(FAIL_STAMP), { recursive: true }); writeFileSync(FAIL_STAMP, String(Date.now())); } catch {}
  emit({ ok: false, error: String(err?.message || err) });
  process.exit(0);
}

function clearFail() {
  try { if (existsSync(FAIL_STAMP)) unlinkSync(FAIL_STAMP); } catch {}
}

async function refreshSnippet() {
  const r = await fetchWithTimeout(`${WIKI}/discover`);
  if (!r.ok) throw new Error(`/discover HTTP ${r.status}`);
  const html = await r.text();
  const match = html.match(/<pre id="skillmd">([\s\S]*?)<\/pre>/);
  if (!match) throw new Error('/discover page missing <pre id="skillmd"> block');
  const body = match[1]
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&amp;/g, '&');

  const newHash = sha256(body);
  let changed = false;
  for (const skillFile of SKILL_FILES) {
    mkdirSync(dirname(skillFile), { recursive: true });
    let oldHash = null;
    if (existsSync(skillFile)) {
      try { oldHash = sha256(readFileSync(skillFile)); } catch {}
    }
    if (oldHash === newHash) continue;
    const tmp = skillFile + '.tmp';
    writeFileSync(tmp, body);
    renameSync(tmp, skillFile);
    changed = true;
  }
  return { snippet_updated: changed };
}

async function auditTools() {
  const r = await fetchWithTimeout(`${WIKI}/api/v1/pages`);
  if (!r.ok) throw new Error(`/api/v1/pages HTTP ${r.status}`);
  const data = await r.json();
  const pages = Array.isArray(data) ? data : (data.pages || []);

  const stale = [];
  for (const page of pages) {
    if (!page?.metadata) continue;
    let meta;
    try { meta = JSON.parse(page.metadata); } catch { continue; }
    const release = meta?.releases?.adom_docker;
    if (!release?.asset_name) continue;

    const catalogVersion = page.pub_version;
    const assetName = release.asset_name;
    const installHint = release.install_hint || '';
    const versionCmd = release.version_command || null;
    const plural = pluralOf(page.type);
    const downloadUrl = `${WIKI}/static/${plural}/${page.slug}/${assetName}`;

    if (!isInstalled(assetName)) continue;

    let headOk = false;
    try {
      const h = await fetchWithTimeout(downloadUrl, { method: 'HEAD' }, HEAD_TIMEOUT_MS);
      headOk = h.ok;
    } catch {}
    if (!headOk) continue;

    const installed = installedVersion(assetName, versionCmd);
    if (!installed) continue;
    if (compareSemver(installed, catalogVersion) < 0) {
      stale.push({
        name: assetName, installed, catalog: catalogVersion,
        install_hint: installHint, download_url: downloadUrl,
        page_type: page.type, page_slug: page.slug,
      });
    }
  }
  return stale;
}

async function main() {
  acquireLockOrExit();
  let snippetUpdated = false, stale = [];
  try { snippetUpdated = (await refreshSnippet()).snippet_updated; }
  catch (e) { markFail(e); return; }
  try { stale = await auditTools(); }
  catch (e) { markFail(e); return; }
  clearFail();
  emit({ ok: true, snippet_updated: snippetUpdated, stale });
}

main();
