#!/usr/bin/env node
/* route-check.mjs — mechanical Next.js route enumerator + browser checker.
 * Uses the APP's own `playwright` library via createRequire — never
 * @playwright/test, never a playwright.config, nothing installed.
 *
 * Usage:
 *   node route-check.mjs <app-root> --enumerate
 *   node route-check.mjs <app-root> <ROUTEMAP.md> <out-dir> [--update=<route>|--update=all]
 *
 * Exit codes (B1 — a caller must NEVER treat 1 as clean):
 *   0 = ran to completion, ZERO red verdicts
 *   1 = ran to completion, at least one RED (report.json is still written)
 *   2 = could NOT run — caller treats this as RED-everything, never pass
 *
 * Every operational error funnels through die() -> exit 2 (B2); nothing throws
 * uncaught, and the dev server is always torn down (B3).
 *
 * WHAT IS PROVEN (v2): the page's derived aria snapshot, compared line-by-line to a
 * baseline the user reviews and commits in the app repo (ROUTEMAP.snapshots/<slug>.aria.yml).
 * Quoted substrings in the map's expected cell are now OPT-IN pins, checked AFTER the
 * snapshot. An empty expected cell is legal for a page row (snapshot-only); an API row
 * still needs one (NO_EXPECTATION).
 *
 * Baselines are NEVER auto-approved. A freshly written baseline, or one that is still
 * UNTRACKED/MODIFIED in git, reports NEW — never GREEN — and the run summary says
 * "N baselines pending review". NEW/UPDATED never force exit 1; only RED does.
 *
 * The aria guarantee is structural only: roles, names, tree shape. Fonts, colours,
 * spacing, overlap and layout are NOT covered here — that is /design audit mode's job.
 *
 * While each page is open its links are also collected; internal links and in-page
 * anchors are verified, hrefs are safety-classified, and every resolved URL is fed to
 * the shared secret scanner (B10). A broken or unsafe link is RED and so makes the exit
 * 1 — it never gets its own exit code. `!links off` skips it; `!links external` widens it.
 * Hard-loaded DOM only: menus built by a click are not collected.
 */
import { createRequire } from 'node:module';
import { readdirSync, readFileSync, writeFileSync, mkdirSync, existsSync, openSync, closeSync } from 'node:fs';
import { spawn, spawnSync } from 'node:child_process';
import { join, relative, resolve } from 'node:path';
import { createHash } from 'node:crypto';
import { connect } from 'node:net';
import { homedir } from 'node:os';
import { pathToFileURL } from 'node:url';

class Fatal extends Error {}
const die = m => { throw new Fatal(m); };
const sleep = ms => new Promise(r => setTimeout(r, ms));
const norm = s => String(s).replace(/\s+/g, ' ').trim();
const hash8 = s => createHash('sha256').update(s).digest('hex').slice(0, 8);
const PORT = 4923;

/* ================= pure helpers (exported for hooks/tests/route-check-units.test.js) =========
 * Nothing below touches the filesystem, the network or a browser — that is what makes the
 * unit test possible at all, and it is why they live above main().
 */

/** Volatile per-render attributes playwright stamps into an aria snapshot. */
const ARIA_VOLATILE = [/ \[ref=[^\]]*\]/g, / \[active\]/g, / \[cursor=[^\]]*\]/g];
/** The Next.js dev overlay — a real node in the tree that says nothing about the app. */
const DEV_OVERLAY = /^- (button|dialog|alert) "[^"]*(Next\.js|Dev Tools|Build Error|Fast Refresh)/;

/**
 * Normalise a playwright aria snapshot into a diffable baseline:
 * leading tabs expanded (indent carries the tree structure, so it is preserved),
 * volatile [ref=]/[active]/[cursor=] stripped, the dev-overlay subtree dropped by indent,
 * internal whitespace runs collapsed, blank lines removed. Returns a string (no trailing \n).
 */
function normalizeAria(text) {
  const out = [];
  let dropAt = -1;                                        // indent of the subtree being dropped
  for (const raw of String(text ?? '').split('\n')) {
    const lead = (raw.match(/^[\t ]*/) || [''])[0];
    const indent = lead.replace(/\t/g, '  ').length;      // amendment 2 — tabs never break indent
    let body = raw.slice(lead.length);
    if (!body.trim()) continue;
    if (dropAt >= 0) {
      if (indent > dropAt) continue;                      // still inside the dropped subtree
      dropAt = -1;
    }
    for (const re of ARIA_VOLATILE) body = body.replace(re, '');
    body = body.replace(/\s+/g, ' ').trim();
    if (!body) continue;
    if (DEV_OVERLAY.test(body)) { dropAt = indent; continue; }
    out.push(' '.repeat(indent) + body);
  }
  return out.join('\n');
}

const toLines = v => (Array.isArray(v) ? v.slice() : String(v ?? '').replace(/\n+$/, '').split('\n'));

/**
 * Minimal line diff, zero dependencies: trim the common prefix and suffix, then LCS over
 * whatever window is left. Output is '- old' / '+ new' lines only; identical input → [].
 * Guard (amendment 1): a window over `max` lines on either side skips the LCS entirely and
 * dumps the window — an absurdly large snapshot must not allocate an absurdly large table.
 */
function lineDiff(a, b, max = 2000) {
  const A = toLines(a), B = toLines(b);
  let s = 0;
  while (s < A.length && s < B.length && A[s] === B[s]) s++;
  let ea = A.length, eb = B.length;
  while (ea > s && eb > s && A[ea - 1] === B[eb - 1]) { ea--; eb--; }
  const x = A.slice(s, ea), y = B.slice(s, eb);
  if (!x.length && !y.length) return [];
  if (x.length > max || y.length > max)
    return [...x.map(l => '- ' + l), ...y.map(l => '+ ' + l)];
  const n = x.length, m = y.length;
  const table = [new Uint32Array(m + 1)];
  for (let i = 1; i <= n; i++) {
    const prev = table[i - 1], cur = new Uint32Array(m + 1);
    for (let j = 1; j <= m; j++)
      cur[j] = x[i - 1] === y[j - 1] ? prev[j - 1] + 1 : Math.max(prev[j], cur[j - 1]);
    table.push(cur);
  }
  const out = [];
  let i = n, j = m;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && x[i - 1] === y[j - 1]) { i--; j--; }
    else if (j > 0 && (i === 0 || table[i][j - 1] >= table[i - 1][j])) { out.push('+ ' + y[j - 1]); j--; }
    else { out.push('- ' + x[i - 1]); i--; }
  }
  return out.reverse();
}

/** US-simple digit normalisation: strip non-digits, drop a leading country 1. */
function digitsOf(s) {
  const d = String(s ?? '').replace(/\D+/g, '');
  return d.length === 11 && d.startsWith('1') ? d.slice(1) : d;
}

const CONTACT_SCHEME = /^(tel|sms|mailto):(.*)$/i;

/**
 * Does a tel:/sms:/mailto: href match one of the map's !contact pins?
 * Non-contact hrefs are not this function's business and answer true.
 * A phone pin under 7 digits DIES: three digits would match almost every number.
 */
function contactOk(href, pins) {
  const list = (Array.isArray(pins) ? pins : [pins]).filter(Boolean).map(String);
  for (const p of list) {
    if (p.includes('@')) continue;
    const d = digitsOf(p);
    if (d.length < 7) die(`'!contact ${p}' pins only ${d.length} digit(s) — under 7 digits a pin matches almost any number`);
  }
  const m = CONTACT_SCHEME.exec(String(href ?? '').trim());
  if (!m) return true;
  const scheme = m[1].toLowerCase();
  let value = m[2].split('?')[0];                          // R6 — ?body=/?subject= never compared
  if (scheme === 'mailto') {
    try { value = decodeURIComponent(value); } catch { /* keep the raw form */ }
    const want = value.trim().toLowerCase();
    return list.some(p => p.includes('@') && p.trim().toLowerCase() === want);
  }
  const want = digitsOf(value);
  if (!want) return false;
  return list.some(p => !p.includes('@') && digitsOf(p) === want);
}

const LOCAL_HOST = /^(localhost|127\.0\.0\.1|\[::1\]|::1|0\.0\.0\.0)$/i;
const SCHEME = /^([A-Za-z][A-Za-z0-9+.-]*):/;

/**
 * Pure href classifier. `baseOrigin` may be an origin OR the full URL of the page the href
 * was found on (relative hrefs resolve against it; the bucket compares origins either way).
 * Returns { bucket, verdict, reason } where verdict is RED (a hole), WARN (hygiene, never
 * changes the exit code) or null (nothing to say — reachability is judged elsewhere).
 */
function classifyHref(href, baseOrigin, target = '', rel = '') {
  const h = String(href ?? '').trim();
  const tgt = String(target ?? '').trim().toLowerCase();
  const rels = new Set(String(rel ?? '').toLowerCase().split(/\s+/).filter(Boolean));
  if (h.startsWith('#')) return { bucket: 'anchor', verdict: null, reason: '' };
  const m = SCHEME.exec(h);
  const scheme = m ? m[1].toLowerCase() : '';
  if (scheme === 'javascript' || scheme === 'data' || scheme === 'vbscript')
    return { bucket: 'non-http', verdict: 'RED', reason: `LINK_UNSAFE — ${scheme}: href runs content the page did not author` };
  if (scheme && scheme !== 'http' && scheme !== 'https')
    return { bucket: 'non-http', verdict: null, reason: '' };
  let base = null, u = null;
  try { base = new URL(String(baseOrigin)); } catch { base = null; }
  try { u = new URL(h, base || undefined); } catch { u = null; }
  if (!u) return { bucket: 'bad-url', verdict: 'RED', reason: `unresolvable href "${h}"` };
  const bucket = base && u.origin === base.origin ? 'internal' : 'external';
  if (u.protocol === 'http:' && !LOCAL_HOST.test(u.hostname))
    return { bucket, verdict: 'RED', reason: 'LINK_UNSAFE — plain http: (mixed content; the response is modifiable in transit)' };
  if (tgt === '_blank') {
    if (rels.has('opener'))
      return { bucket, verdict: 'RED', reason: 'LINK_UNSAFE — target=_blank with an explicit rel="opener" hands window.opener to the destination (tabnabbing)' };
    if (!rels.has('noopener') && !rels.has('noreferrer'))
      return { bucket, verdict: 'WARN', reason: 'target=_blank without rel="noopener" — modern browsers imply noopener, so this is hygiene, not a hole' };
  }
  return { bucket, verdict: null, reason: '' };
}

/* ---------- dev-server lifecycle (B3) ---------- */
const server = { child: null, pid: null, logFd: null, stopped: false, earlyExit: null };
const closeLog = () => { if (server.logFd !== null) { try { closeSync(server.logFd); } catch {} server.logFd = null; } };
const killGroup = sig => {
  if (!Number.isInteger(server.pid) || server.pid <= 0) return;
  try { process.kill(-server.pid, sig); } catch {}
};
const portOpen = (port, host = '127.0.0.1') => new Promise(res => {
  const s = connect({ port, host });
  const done = v => { try { s.destroy(); } catch {} res(v); };
  s.setTimeout(1500);
  s.once('connect', () => done(true));
  s.once('error', () => done(false));
  s.once('timeout', () => done(false));
});
/** SIGTERM the group, poll the port, escalate to SIGKILL, fail if unconfirmed. */
async function stopServer() {
  if (!server.child || server.stopped) { closeLog(); return true; }
  server.stopped = true;
  killGroup('SIGTERM');
  for (const [sig, waitMs] of [[null, 10000], ['SIGKILL', 5000]]) {
    if (sig) killGroup(sig);
    const end = Date.now() + waitMs;
    while (Date.now() < end) {
      await sleep(300);
      if (!(await portOpen(PORT))) { closeLog(); return true; }
    }
  }
  closeLog();
  return false;
}

/* ---------- enumeration constants ---------- */
const PAGE_EXT = new Set(['js', 'jsx', 'ts', 'tsx']);          // page.<ext>
const ROUTE_EXT = new Set(['js', 'ts']);                       // route.<ext>
const META = /^(robots\.|sitemap\.|manifest\.|favicon\.ico$|icon\.|icon\d|apple-icon|opengraph-image|twitter-image)/;
/* B4 (v2) — the ONLY non-route file stems allowed inside the app router tree. Anything else
 * dies: a colocated component is indistinguishable from a route file this walker got wrong,
 * and guessing is how the old fail-open let default.tsx (a soft-nav-only slot fallback that
 * this tool CANNOT drive) pass as "not route-producing". Colocated components are therefore
 * unsupported — loudly. Put them in src/components/. */
const SPECIAL_STEM = new Set(['layout', 'template', 'loading', 'error', 'not-found', 'global-error', 'forbidden', 'unauthorized']);
const ASSET_EXT = new Set([
  'css', 'scss', 'sass', 'less', 'styl', 'svg', 'png', 'jpg', 'jpeg', 'gif', 'webp', 'avif',
  'ico', 'bmp', 'woff', 'woff2', 'ttf', 'otf', 'eot', 'json', 'md', 'mdx', 'txt', 'map', 'webmanifest',
]);

async function main() {
  /* ---------- CLI shape (B2) ---------- */
  const argv = process.argv.slice(2);
  const flags = argv.filter(a => a.startsWith('--'));
  const pos = argv.filter(a => !a.startsWith('--'));
  const USAGE = 'usage: route-check.mjs <app-root> --enumerate | route-check.mjs <app-root> <ROUTEMAP.md> <out-dir> [--update=<route>|--update=all]';
  let UPDATE = null;
  for (const f of flags) {
    if (f === '--enumerate') continue;
    if (f === '--update') die(`'--update' needs a value — use '--update=all' or '--update=/some/route' — ${USAGE}`);
    const m = /^--update=(.+)$/.exec(f);
    if (!m) die(`unknown flag '${f}' — ${USAGE}`);
    if (UPDATE !== null) die("'--update' may be given at most once");
    UPDATE = m[1];
  }
  const ENUM_ONLY = flags.includes('--enumerate');
  if (ENUM_ONLY && UPDATE !== null) die("'--update' rewrites baselines, which --enumerate never reads — use one or the other");
  if (pos.length === 0) die(USAGE);
  if (ENUM_ONLY && pos.length !== 1) die(`--enumerate takes exactly one positional (<app-root>), got ${pos.length}: ${pos.join(' ')}`);
  if (!ENUM_ONLY && pos.length !== 3) die(`${USAGE} — got ${pos.length} positional argument(s)`);
  const appRoot = resolve(pos[0]);
  if (!existsSync(appRoot)) die(`app root does not exist: ${appRoot}`);

  /* ---------- guarded constructs (fail loudly, never skip) ---------- */
  for (const f of ['middleware.ts', 'middleware.js', 'src/middleware.ts', 'src/middleware.js'])
    if (existsSync(join(appRoot, f))) die(`unsupported construct: ${f} — middleware can rewrite any route`);
  const roots = [];
  for (const r of ['app', 'src/app', 'pages', 'src/pages']) if (existsSync(join(appRoot, r))) roots.push(r);
  if (roots.length === 0) die(`no app/, src/app, pages/ or src/pages tree found under ${appRoot}`);
  if (roots.length > 1) die(`ambiguous router roots — exactly one required, found: ${roots.join(', ')}`);   // B7
  const ROOT = roots[0];
  const APP = ROOT === 'app' || ROOT === 'src/app' ? join(appRoot, ROOT) : null;
  const PAGES = APP ? null : join(appRoot, ROOT);

  /* ---------- enumeration ---------- */
  const routes = [], meta = [], intercepts = [];
  const splitExt = n => { const i = n.lastIndexOf('.'); return i === -1 ? [n, ''] : [n.slice(0, i), n.slice(i + 1)]; };
  function walkApp(dir, parts) {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      const p = join(dir, e.name), rel = relative(appRoot, p);
      if (e.isFile()) {
        const [stem, ext] = splitExt(e.name);
        if (stem === 'page') {                                                        // B4 — never a silent skip
          if (!PAGE_EXT.has(ext)) die(`unsupported route file '${rel}' — page.${ext} is not a supported extension (${[...PAGE_EXT].join(', ')})`);
          routes.push({ kind: 'page', pattern: '/' + parts.join('/'), file: rel });
        } else if (stem === 'route') {
          if (!ROUTE_EXT.has(ext)) die(`unsupported route file '${rel}' — route.${ext} is not a supported extension (${[...ROUTE_EXT].join(', ')})`);
          routes.push({ kind: 'api', pattern: '/' + parts.join('/'), file: rel });
        } else if (META.test(e.name)) meta.push(rel);
        else if (stem === 'default')
          die(`unsupported route file '${rel}' — default.${ext} renders only on a soft navigation into an unmatched parallel slot, which this tool cannot drive; it cannot be proven, so it is not skipped`);
        else if (!SPECIAL_STEM.has(stem) && !ASSET_EXT.has(ext.toLowerCase()))
          die(`unrecognised file '${rel}' inside the router tree — colocated components are unsupported (move it to src/components/), and an unknown file may be a route file this walker mis-read; allowed here: page/route/default + ${[...SPECIAL_STEM].join('/')} + metadata files + assets`);
        continue;                                     // layout/loading/error/css — not route-producing
      }
      const n = e.name;
      if (/^\(\.{1,3}\)/.test(n)) {                                                   // intercepting route
        const target = n.replace(/^\(\.{1,3}\)/, ''), dots = n.match(/^\((\.{1,3})\)/)[1];
        const base = dots === '.' ? parts : dots === '..' ? parts.slice(0, -1) : [];
        intercepts.push({ dir: rel, target: '/' + [...base, target].join('/') });
        continue;
      }
      if (n.startsWith('(') && n.endsWith(')')) { walkApp(p, parts); continue; }      // route group
      if (n.startsWith('@')) {                                                        // parallel slot
        for (const s of readdirSync(p, { withFileTypes: true })) {
          if (s.isDirectory()) die(`unsupported: nested segment '${s.name}' inside parallel slot ${rel} (soft-nav only)`);
          const [stem, ext] = splitExt(s.name);
          if (stem === 'page') {
            if (!PAGE_EXT.has(ext)) die(`unsupported route file '${relative(appRoot, join(p, s.name))}' — page.${ext} is not a supported extension`);
            routes.push({ kind: 'slot', pattern: '/' + parts.join('/'), file: relative(appRoot, join(p, s.name)) });
          }
        }
        continue;
      }
      if (n.startsWith('_')) continue;                                                // private folder
      if (/^\[\[\.\.\..+\]\]$/.test(n) || /^\[\.\.\..+\]$/.test(n) || /^\[.+\]$/.test(n) || /^[A-Za-z0-9._-]+$/.test(n)) { walkApp(p, [...parts, n]); continue; }
      die(`unsupported segment '${n}' at ${rel}`);
    }
  }
  function walkPages(dir, parts) {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      if (e.isDirectory()) { walkPages(join(dir, e.name), [...parts, e.name]); continue; }
      const m = e.name.match(/^(.+)\.(js|jsx|ts|tsx)$/); if (!m) continue;
      if (m[1].startsWith('_')) continue;
      const segs = m[1] === 'index' ? parts : [...parts, m[1]];
      routes.push({ kind: parts[0] === 'api' ? 'api' : 'page', pattern: '/' + segs.join('/'), file: relative(appRoot, join(dir, e.name)) });
    }
  }
  APP ? walkApp(APP, []) : walkPages(PAGES, []);
  // slot pages fold into their parent-URL page row; dedupe patterns keeping page kind
  const byPattern = new Map();
  for (const r of routes) {
    const prev = byPattern.get(r.pattern);
    if (!prev) byPattern.set(r.pattern, r); else prev.file += ' + ' + r.file;
  }
  if (ENUM_ONLY) {
    console.log(JSON.stringify({ routes: [...byPattern.values()], meta, intercepts }, null, 2));
    return 0;
  }
  // amendment 3 — a typo in --update must not silently rewrite nothing (or everything)
  if (UPDATE !== null && UPDATE !== 'all' && !byPattern.has(UPDATE))
    die(`--update=${UPDATE}: no such route in the enumeration — known routes: ${[...byPattern.keys()].join(', ')}`);
  const updateTargets = pattern => UPDATE !== null && (UPDATE === 'all' || UPDATE === pattern);

  /* ---------- map ---------- */
  const mapPath = resolve(pos[1]), OUT = resolve(pos[2]);
  let mapText;
  try { mapText = readFileSync(mapPath, 'utf8'); }
  catch (err) { die(`cannot read route map '${mapPath}': ${err.message}`); }
  try { mkdirSync(OUT, { recursive: true }); }
  catch (err) { die(`cannot create out-dir '${OUT}': ${err.message}`); }

  const DIRECTIVES = new Set(['base', 'auth', 'seed', 'login', 'ack', 'empty', 'links', 'contact']);
  const dirv = {}, acks = new Set(), rows = [], rowByPattern = new Map();
  for (const [i, raw] of mapText.split('\n').entries()) {
    const line = raw.trim(), ln = i + 1;
    if (!line || line.startsWith('#')) continue;
    if (line.startsWith('!')) {                                                        // B7 — strict directives
      const [k, ...v] = line.slice(1).split(/\s+/);
      if (!DIRECTIVES.has(k)) die(`${mapPath}:${ln}: unknown directive '!${k}' (known: ${[...DIRECTIVES].join(', ')})`);
      if (k === 'ack') {
        if (!v.length) die(`${mapPath}:${ln}: '!ack' needs at least one keyword`);
        for (const t of v) { if (acks.has(t)) die(`${mapPath}:${ln}: duplicate '!ack ${t}'`); acks.add(t); }
        continue;
      }
      if (k in dirv) die(`${mapPath}:${ln}: duplicate '!${k}' directive — exactly one allowed`);
      dirv[k] = v.join(' ') || 'true';
      continue;
    }
    const c = line.split('|').map(s => s.trim());
    if (c.length > 1 && c[c.length - 1] === '') c.pop();                               // tolerated trailing pipe
    if (c.length < 3 || c.length > 4) die(`${mapPath}:${ln}: expected 'route | auth | expected [| note]'`);
    if (rowByPattern.has(c[0])) die(`${mapPath}:${ln}: duplicate row for route '${c[0]}' (first seen at line ${rowByPattern.get(c[0]).line})`);
    const row = {
      pattern: c[0], auth: c[1], raw: c[2], note: c[3] || '', line: ln,
      expected: [...c[2].matchAll(/"([^"]+)"/g)].map(m => m[1]),
    };
    rows.push(row); rowByPattern.set(row.pattern, row);
  }
  if (dirv.empty && dirv.empty !== 'never') die(`${mapPath}: '!empty ${dirv.empty}' is not supported — only '!empty never' (the default)`);
  if (dirv.links && dirv.links !== 'off' && dirv.links !== 'external')
    die(`${mapPath}: '!links ${dirv.links}' is not supported — use '!links off' or '!links external'`);
  const LINKS = dirv.links === 'off' ? 'off' : dirv.links === 'external' ? 'external' : 'on';   // default: internal + anchors
  const contactPins = dirv.contact && dirv.contact !== 'true' ? dirv.contact.split(/\s+/).filter(Boolean) : [];
  if (dirv.contact && !contactPins.length) die(`${mapPath}: '!contact' needs at least one phone number or email address`);
  for (const p of contactPins) {                                                       // amendment 4 — short pins die at parse
    if (p.includes('@')) continue;
    const d = digitsOf(p);
    if (d.length < 7) die(`${mapPath}: '!contact ${p}' pins only ${d.length} digit(s) — under 7 digits a pin matches almost any number`);
  }

  const cfgFile = ['next.config.js', 'next.config.mjs', 'next.config.ts'].map(f => join(appRoot, f)).find(existsSync);
  const cfgText = cfgFile ? readFileSync(cfgFile, 'utf8') : '';
  for (const kw of ['redirects', 'rewrites', 'basePath', 'trailingSlash'])
    if (new RegExp('\\b' + kw + '\\b').test(cfgText) && !acks.has(kw))                 // B7 — exact token, not includes
      die(`next.config declares ${kw} — add '!ack ${kw}' plus covering rows to ${mapPath}, or it cannot be verified`);

  /* ---------- server ---------- */
  const probePath = [...byPattern.values()].find(r => r.kind !== 'api' && !r.pattern.includes('['))?.pattern
    || [...byPattern.values()].find(r => !r.pattern.includes('['))?.pattern || '/';
  const probe = async b => {                                                            // B3 — real route, <400
    try { return (await fetch(b + probePath, { signal: AbortSignal.timeout(3000) })).status < 400; }
    catch { return false; }
  };
  let base = dirv.base && dirv.base !== 'true' ? dirv.base.replace(/\/+$/, '') : null;
  if (base) { if (!await probe(base)) die(`!base ${base} declared but ${base + probePath} did not answer with a status under 400`); }
  else {
    base = `http://localhost:${PORT}`;
    if (await portOpen(PORT)) die(`port ${PORT} already in use — stop it or declare !base. Runbook: lsof -ti tcp:${PORT} | xargs kill`);
    server.logFd = openSync(join(OUT, 'dev-server.log'), 'w');
    const child = spawn('npm', ['run', 'dev', '--', '-p', String(PORT)],
      { cwd: appRoot, detached: true, stdio: ['ignore', server.logFd, server.logFd] });
    server.child = child;
    if (!Number.isInteger(child.pid) || child.pid <= 0) { server.child = null; closeLog(); die('dev server could not be spawned (no pid) — see dev-server.log'); }
    server.pid = child.pid;
    child.on('error', e => { if (!server.stopped) server.earlyExit = `spawn failed: ${e.message}`; });
    child.on('exit', (code, sig) => { if (!server.stopped) server.earlyExit = `dev server exited early (code=${code}, signal=${sig})`; });
    let up = false;
    for (let i = 0; i < 90 && !up; i++) {
      if (server.earlyExit) die(`${server.earlyExit} — see ${join(OUT, 'dev-server.log')}`);   // B3 — fail fast
      await sleep(1000);
      up = await probe(base);
    }
    if (!up) die(`dev server not ready after 90s (probed ${base + probePath}) — see ${join(OUT, 'dev-server.log')}`);
  }

  /* ---------- seed / auth ---------- */
  const runStep = (label, cmd) => {
    const r = spawnSync(cmd, { cwd: appRoot, shell: true, stdio: 'inherit', timeout: 120000, killSignal: 'SIGKILL' });
    if (r.error) die(`${label} could not run: ${cmd} — ${r.error.message}`);
    if (r.signal) die(`${label} timed out after 120s (killed with ${r.signal}): ${cmd}`);
    if (r.status !== 0) die(`${label} failed: ${cmd}`);
  };
  if (dirv.seed) runStep('!seed', dirv.seed);
  let storageState = null;
  const authParts = (dirv.auth || 'none').split(/\s+/), authMode = authParts[0];
  if (authMode === 'session') storageState = join(appRoot, authParts[1] || die('!auth session needs a path'));
  else if (authMode === 'test-account') {
    if (!dirv.login) die('!auth test-account requires a !login command that writes .routemap/session.json');
    runStep('!login', dirv.login);
    storageState = join(appRoot, '.routemap', 'session.json');
  } else if (authMode !== 'none') die(`unknown !auth mode '${authMode}'`);
  if (storageState && !existsSync(storageState)) die(`session file missing: ${storageState}`);

  /* ---------- visit + verdicts ---------- */
  const requireApp = createRequire(join(appRoot, 'package.json'));
  let pw;
  try { pw = requireApp('playwright'); }
  catch { die("app has no 'playwright' library installed — Runbook: npm i -D playwright && npx playwright install chromium"); }

  const slug = p => p === '/' ? 'root' : p.replace(/^\//, '').replace(/[^A-Za-z0-9]+/g, '-');
  const artifactOf = (pattern, url) => `${slug(pattern)}-${hash8(url)}`;               // B8 — collision-proof
  const encSeg = (v, catchAll) => catchAll
    ? v.split('/').filter(Boolean).map(encodeURIComponent).join('/')
    : encodeURIComponent(v);
  const DYN = /\[\[\.\.\.([A-Za-z0-9_]+)\]\]|\[\.\.\.([A-Za-z0-9_]+)\]|\[([A-Za-z0-9_]+)\]/g;
  const expand = (pattern, note) => {                                                   // B8 — encode, reject bad fixtures
    const decls = [...note.matchAll(/\bfixture\b(?:\s+(\S+))?/g)].map(m => m[1] || '');
    const fx = {}, malformed = [];
    for (const d of decls) {
      const m = d.match(/^([A-Za-z0-9_]+)=(.+)$/);
      if (!m) malformed.push(d || 'fixture (no value)'); else fx[m[1]] = m[2];
    }
    const missing = [], used = new Set();
    const sub = pattern.replace(DYN, (m, opt, cat, one) => {
      const k = opt || cat || one;
      if (!(k in fx)) { missing.push(k); return m; }
      used.add(k);
      return encSeg(fx[k], !!(opt || cat));
    });
    const unused = Object.keys(fx).filter(k => !used.has(k));
    const urls = [];
    if (!missing.length && !malformed.length && !unused.length) {
      if (/\[\[\.\.\.[A-Za-z0-9_]+\]\]/.test(pattern)) urls.push(pattern.replace(/\/?\[\[\.\.\.[A-Za-z0-9_]+\]\]/, '') || '/');
      urls.push(sub);
    }
    return { urls, missing, malformed, unused };
  };
  async function stableText(page, budgetMs = 10000) {                                   // B9 — bounded stable-text poll
    let prev = null, end = Date.now() + budgetMs;
    for (;;) {
      const t = norm(await page.innerText('body').catch(() => ''));
      if (t && t === prev) return t;
      prev = t;
      if (Date.now() >= end) return t;
      await sleep(350);
    }
  }

  /* ---------- aria baselines (the reviewed expectation, kept in the APP repo) ---------- */
  const SNAPDIR = join(appRoot, 'ROUTEMAP.snapshots');
  const slugOwner = new Map();
  const baselineOf = urlPath => {
    const s = slug(urlPath);
    const prev = slugOwner.get(s);
    if (prev !== undefined && prev !== urlPath)
      die(`snapshot slug collision — '${urlPath}' and '${prev}' both want ROUTEMAP.snapshots/${s}.aria.yml; rename one of the routes`);
    slugOwner.set(s, urlPath);
    return join(SNAPDIR, s + '.aria.yml');
  };
  const readBaseline = f => readFileSync(f, 'utf8').replace(/\n+$/, '');
  /** A baseline is APPROVED only once it is committed. Untracked/modified — or a tree we
   *  cannot ask git about — is pending, never green. */
  const gitPending = file => {
    const r = spawnSync('git', ['-C', appRoot, 'status', '--porcelain', '--', file], { encoding: 'utf8', timeout: 15000 });
    if (r.error || r.status !== 0) return true;
    return String(r.stdout || '').trim().length > 0;
  };
  const pendingFiles = [];

  /* ---------- link checking (B10 — a dead or unsafe link is RED, never a silent skip) ---------- */
  const baseOrigin = new URL(base).origin;
  const linkRecs = new Map();                                                           // ONE record per resolved URL
  const fragOf = h => { try { return decodeURIComponent(h.slice(1)); } catch { return h.slice(1); } };
  /** Gather every a[href] on the open page and bucket it. Anchors are judged HERE,
   *  because `#foo` can only be resolved against the page it was found on. */
  async function collectLinks(page, pageUrl, pattern) {
    const got = await page.evaluate(() => ({
      links: [...document.querySelectorAll('a[href]')].map(el => ({
        href: el.getAttribute('href') || '',
        target: el.getAttribute('target') || '',
        rel: el.getAttribute('rel') || '',
        text: [el.textContent || '', el.getAttribute('aria-label') || '', el.querySelector('img')?.alt || '']
          .join(' ').replace(/\s+/g, ' ').trim().slice(0, 60),
      })),
      ids: [...document.querySelectorAll('[id], a[name]')].map(el => el.id || el.getAttribute('name') || ''),
    }));
    const idSet = new Set(got.ids.filter(Boolean));
    for (const { href, text, target, rel } of got.links) {
      const h = href.trim();
      const cls = classifyHref(h, pageUrl, target, rel);
      let key, display = h, anchorTarget = null;
      if (cls.bucket === 'anchor') {
        anchorTarget = fragOf(h);
        key = pageUrl.split('#')[0] + '#' + anchorTarget;                                // per-page by construction
      } else if (cls.bucket === 'non-http') key = 'non-http:' + h;
      else if (cls.bucket === 'bad-url') key = 'bad-url:' + h;
      else {
        const u = new URL(h, pageUrl);
        key = u.href;
        display = cls.bucket === 'internal' ? u.pathname + u.search + u.hash : u.href;
      }
      let rec = linkRecs.get(key);
      if (!rec) {
        rec = {
          url: key, href: h, display, bucket: cls.bucket, text, anchorTarget, pages: [],
          verdict: null, reason: '', status: null, finalUrl: null,
          safetyVerdict: cls.verdict, safetyReason: cls.reason, target, rel,
        };
        linkRecs.set(key, rec);
      }
      if (!rec.pages.includes(pattern)) rec.pages.push(pattern);
      if (!rec.text && text) rec.text = text;
      if (cls.verdict === 'RED') { rec.safetyVerdict = 'RED'; rec.safetyReason = cls.reason; }   // worst wins
      if (cls.bucket === 'anchor' && rec.verdict === null) {
        const ok = anchorTarget === '' || anchorTarget.toLowerCase() === 'top' || idSet.has(anchorTarget);
        rec.verdict = ok ? 'GREEN' : 'RED';
        rec.reason = ok ? '' : `no element with id "${anchorTarget}"`;
      }
    }
  }
  /** HEAD first, GET on 405/501 (dev servers can be picky), redirects followed. */
  let contactLinksSeen = 0;
  async function verifyLinks() {
    const cache = new Map();                                                            // one request per distinct path
    const hit = async url => {
      const bare = url.split('#')[0];
      if (cache.has(bare)) return cache.get(bare);
      let out;
      try {
        const opt = { redirect: 'follow', signal: AbortSignal.timeout(20000) };
        let res = await fetch(bare, { method: 'HEAD', ...opt });
        if (res.status === 405 || res.status === 501) res = await fetch(bare, { method: 'GET', ...opt });
        out = { verdict: res.status >= 400 ? 'RED' : 'GREEN', status: res.status, finalUrl: res.url || bare, err: '' };
      } catch (err) { out = { verdict: 'RED', status: null, finalUrl: bare, err: err.message }; }
      cache.set(bare, out);
      return out;
    };
    for (const rec of linkRecs.values()) {
      if (rec.safetyVerdict === 'RED') { rec.verdict = 'RED'; rec.reason = rec.safetyReason; continue; }
      if (rec.bucket === 'anchor') { applyWarn(rec); continue; }                         // already judged, on its page
      if (rec.bucket === 'non-http') {
        const scheme = (SCHEME.exec(rec.href) || [, '?'])[1].toLowerCase();
        if (scheme === 'tel' || scheme === 'sms' || scheme === 'mailto') {
          contactLinksSeen++;
          if (contactPins.length) {
            const ok = contactOk(rec.href, contactPins);
            rec.verdict = ok ? 'GREEN' : 'RED';
            rec.reason = ok ? '' : `CONTACT_MISMATCH — "${rec.href}" matches no !contact value (${contactPins.join(', ')})`;
            continue;
          }
        }
        rec.verdict = 'INFO'; rec.reason = `${scheme}: link — reported, never checked`;
        continue;
      }
      if (rec.bucket === 'bad-url') { rec.verdict = 'RED'; rec.reason = rec.safetyReason || `unresolvable href "${rec.href}"`; continue; }
      if (rec.bucket === 'external' && LINKS !== 'external') {
        rec.verdict = 'SKIPPED'; rec.reason = "external — not checked, '!links external' is not set"; continue;
      }
      const r = await hit(rec.url);
      rec.verdict = r.verdict; rec.status = r.status; rec.finalUrl = r.finalUrl;
      const why = r.status ? String(r.status) : `request failed — ${r.err}`;
      rec.reason = r.verdict === 'GREEN' ? ''
        : rec.bucket === 'external' ? `LINK_ROT — ${why} (an expired domain is hijackable, so a dead external link is a security finding, not a nit)`
          : why;
      applyWarn(rec);
    }
  }
  const applyWarn = rec => {
    if (rec.safetyVerdict === 'WARN' && rec.verdict === 'GREEN') { rec.verdict = 'WARN'; rec.reason = rec.safetyReason; }
  };
  /** Every resolved URL through the shared scanner. Fail CLOSED: only 0/1 are answers. */
  const sniffSecrets = () => {
    const urls = [...linkRecs.values()].filter(l => l.bucket === 'internal' || l.bucket === 'external').map(l => l.url);
    if (!urls.length) return [];
    if (urls.length > 10000) die(`${urls.length} distinct link URLs exceeds the 10000 cap for the secret sniff — narrow the map or set '!links off'`);
    const scanner = join(process.env.CLAUDE_CONFIG_DIR || join(homedir(), '.claude'), 'hooks', 'secret-scan.sh');
    if (!existsSync(scanner)) die(`secret scanner not found at ${scanner} — set CLAUDE_CONFIG_DIR to the checkout that holds hooks/secret-scan.sh`);
    const r = spawnSync('bash', [scanner], { input: urls.join('\n') + '\n', encoding: 'utf8', timeout: 30000, maxBuffer: 32 * 1024 * 1024 });
    if (r.error) die(`secret sniff could not run: ${r.error.message} (${scanner})`);
    if (r.signal) die(`secret sniff timed out after 30s (killed with ${r.signal}) — ${scanner}`);
    if (r.status === 1) return [];
    if (r.status !== 0) die(`secret sniff failed with exit ${r.status} — ${scanner}: ${String(r.stderr || '').trim()}`);
    return String(r.stdout || '').split('\n').map(s => s.trim()).filter(Boolean);
  };
  const linkLine = l => `${l.verdict}\tlink ${l.display}\t${l.reason}`
    + (l.pages.length ? ` from ${l.pages.join(', ')}` : '') + (l.text ? ` — text "${l.text}"` : '');

  const records = new Map();                                                            // B8 — ONE record per pattern
  const put = (pattern, rec) => { records.set(pattern, { pattern, ...rec }); return records.get(pattern); };
  const summarise = () => {
    const report = [...records.values()];
    const links = [...linkRecs.values()];
    const red = report.filter(r => r.verdict === 'RED').length;
    const pending = report.filter(r => r.verdict === 'NEW' || r.verdict === 'UPDATED').length;
    const nBucket = b => links.filter(l => l.bucket === b).length;
    const linkSummary = {
      mode: LINKS, total: links.length, internal: nBucket('internal'), anchor: nBucket('anchor'),
      external: nBucket('external'), nonHttp: nBucket('non-http'), badUrl: nBucket('bad-url'),
      externalSkipped: links.filter(l => l.verdict === 'SKIPPED').length,
      warned: links.filter(l => l.verdict === 'WARN').length,
      broken: links.filter(l => l.verdict === 'RED').length,
    };
    return { report, links, red, pending, linkSummary };
  };
  /** B11 — report.json is rewritten after EVERY route, so a run killed halfway still leaves
   *  the rows it did prove. `complete:false` says plainly that it is a partial file. */
  const writeReport = complete => {
    const { report, links, red, pending, linkSummary } = summarise();
    writeFileSync(join(OUT, 'report.json'), JSON.stringify({
      complete, base, router: ROOT, update: UPDATE, meta, intercepts,
      summary: { total: report.length, green: report.length - red - pending, red, pending },
      pendingBaselines: pendingFiles, report, linkSummary, links,
    }, null, 2));
    return { report, links, red, pending, linkSummary };
  };

  const checkRedirect = async (row, url) => {
    const want = row.raw.replace(/^->/, '').trim();
    try {
      const res = await fetch(url, { redirect: 'manual' });
      const loc = res.headers.get('location') || '';
      const is3xx = res.status >= 300 && res.status < 400;
      let got = null;
      if (loc) { try { got = new URL(loc, url).pathname; } catch {} }
      const wantPath = new URL(want, base).pathname;
      const ok = is3xx && got === wantPath;                                             // B8 — exact pathname, 3xx required
      return { verdict: ok ? 'GREEN' : 'RED', reason: ok ? '' : `MISMATCH — expected a 3xx to '${wantPath}', got status ${res.status} Location '${loc}'`, url };
    } catch (err) { return { verdict: 'RED', reason: 'VISIT_FAILED — ' + err.message, url }; }
  };

  const RANK = { RED: 3, UPDATED: 2, NEW: 1, GREEN: 0 };
  let browser;
  try { browser = await pw.chromium.launch(); }                                         // headless by default
  catch (err) { die(`chromium could not launch: ${err.message} — Runbook: npx playwright install chromium`); }
  try {
    for (const r of byPattern.values()) {
      const row = rowByPattern.get(r.pattern);
      const common = { kind: r.kind, file: r.file };
      if (!row) { put(r.pattern, { ...common, verdict: 'RED', reason: 'NO_ROW — route exists in the tree but has no ROUTEMAP row', visited: false }); writeReport(false); continue; }
      if (/\bdraft\b/.test(row.note)) { put(r.pattern, { ...common, verdict: 'RED', reason: 'DRAFT — expectation not yet reviewed', visited: false }); writeReport(false); continue; }
      const { urls, missing, malformed, unused } = expand(r.pattern, row.note);
      if (malformed.length) { put(r.pattern, { ...common, verdict: 'RED', reason: `BAD_FIXTURE — malformed fixture declaration(s): ${malformed.join(', ')}`, visited: false }); writeReport(false); continue; }
      if (missing.length) { put(r.pattern, { ...common, verdict: 'RED', reason: 'NO_FIXTURE — dynamic segment has no declared fixture value', visited: false }); writeReport(false); continue; }
      if (unused.length) { put(r.pattern, { ...common, verdict: 'RED', reason: `BAD_FIXTURE — fixture(s) ${unused.join(', ')} match no dynamic segment in the pattern`, visited: false }); writeReport(false); continue; }

      if (r.kind === 'api') {
        const url = base + urls.at(-1), art = artifactOf(r.pattern, url);
        try {
          const res = await fetch(url);
          const body = await res.text();
          writeFileSync(join(OUT, art + '.body.txt'), body);
          const want = row.raw.match(/status=(\d+)/);
          const hay = norm(body).toLowerCase();                                         // B8 — same norm as the page path
          let verdict = 'GREEN', reason = '';
          if (!want && row.expected.length === 0) { verdict = 'RED'; reason = 'NO_EXPECTATION — an API row has no aria snapshot to fall back on, so it needs status=<n> or a quoted substring'; }
          else if (!((!want || res.status === +want[1]) && row.expected.every(e => hay.includes(norm(e).toLowerCase())))) { verdict = 'RED'; reason = 'MISMATCH — status/body did not satisfy the row'; }
          put(r.pattern, { ...common, verdict, reason, visited: true, urls: [url], artifacts: [art + '.body.txt'], status: res.status });
        } catch (err) { put(r.pattern, { ...common, verdict: 'RED', reason: 'VISIT_FAILED — ' + err.message, visited: false, urls: [url] }); }
        writeReport(false);
        continue;
      }

      if (row.raw.startsWith('->')) {
        const url = base + urls.at(-1), v = await checkRedirect(row, url);
        put(r.pattern, { ...common, verdict: v.verdict, reason: v.reason, visited: true, urls: [url] });
        writeReport(false);
        continue;
      }

      const ctx = await browser.newContext({                                            // R5 — pin every knob that moves
        ...(row.auth !== 'none' && storageState ? { storageState } : {}),
        timezoneId: 'America/New_York', locale: 'en-US', reducedMotion: 'reduce', colorScheme: 'light',
      });
      const page = await ctx.newPage();
      const log = [];
      page.on('console', m => log.push(`[console.${m.type()}] ${m.text()}`));            // B9 — hydration failures visible
      page.on('pageerror', e => log.push(`[pageerror] ${e.message}`));
      page.on('requestfailed', q => log.push(`[requestfailed] ${q.url()} — ${q.failure()?.errorText || ''}`));
      const visits = [];
      for (const u of urls) {                                                            // B8 — visit EVERY variant
        const url = base + u, art = artifactOf(r.pattern, url), mark = log.length;
        let verdict = 'GREEN', reason = '', detail = '';
        try {
          await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });       // B9
          const text = await stableText(page);
          writeFileSync(join(OUT, art + '.txt'), text);
          await page.screenshot({ path: join(OUT, art + '.png'), fullPage: true });
          if (LINKS !== 'off') await collectLinks(page, page.url(), r.pattern);
          if (text.length < 40 && !/\bempty-ok\b/.test(row.note)) { verdict = 'RED'; reason = 'EMPTY — under 40 chars of visible text and no empty-ok'; }
          else {
            /* --- aria snapshot, captured twice 500ms apart (R5): a page that cannot agree
                   with itself is not a baseline, it is a flake, and it is reported as one. --- */
            const first = normalizeAria(await page.ariaSnapshot());
            await sleep(500);
            const second = normalizeAria(await page.ariaSnapshot());
            writeFileSync(join(OUT, art + '.aria.yml'), first + '\n');                   // evidence, EVERY run
            const jitter = lineDiff(first, second);
            const bfile = baselineOf(u), bshow = relative(appRoot, bfile);
            if (jitter.length) {
              verdict = 'RED';
              reason = `SNAPSHOT_UNSTABLE — the aria tree changed between two captures 500ms apart (${jitter.length} line(s)); it is dynamic, not a baseline`;
              detail = jitter.slice(0, 40).map(l => '\t' + l).join('\n');
            } else if (!existsSync(bfile) || updateTargets(r.pattern)) {
              const had = existsSync(bfile);
              const changed = had ? lineDiff(readBaseline(bfile), first).length : 0;
              mkdirSync(SNAPDIR, { recursive: true });
              writeFileSync(bfile, first + '\n');
              pendingFiles.push(bshow);
              verdict = had ? 'UPDATED' : 'NEW';
              reason = had
                ? `baseline rewritten by --update (${changed} line(s) changed) — review the git diff of ${bshow}, commit it, then re-run WITHOUT --update to reach green`
                : `baseline recorded — review & commit ${bshow}`;
            } else {
              const d = lineDiff(readBaseline(bfile), first);
              if (d.length) {
                verdict = 'RED';
                reason = `MISMATCH — aria snapshot differs from baseline (${d.length} lines)`;
                detail = d.slice(0, 40).map(l => '\t' + l).join('\n');
              } else if (gitPending(bfile)) {
                pendingFiles.push(bshow);
                verdict = 'NEW';
                reason = `baseline matches but is not committed yet — review & commit ${bshow}`;
              }
            }
            /* --- pins are OPT-IN and checked AFTER the snapshot --- */
            if (verdict !== 'RED' && row.expected.length) {
              const missSub = row.expected.find(e => !text.toLowerCase().includes(norm(e).toLowerCase()));
              if (missSub) { verdict = 'RED'; reason = `PIN_MISMATCH — missing "${missSub}"`; detail = ''; }
            }
          }
        } catch (err) { verdict = 'RED'; reason = 'VISIT_FAILED — ' + err.message; detail = ''; }
        writeFileSync(join(OUT, art + '.console.txt'), log.slice(mark).join('\n') + '\n');
        visits.push({ url, artifact: art, verdict, reason, detail });
      }
      await ctx.close();
      const worst = visits.reduce((a, v) => (RANK[v.verdict] > RANK[a.verdict] ? v : a), visits[0]);
      put(r.pattern, {
        ...common, verdict: worst.verdict, reason: worst.reason, detail: worst.detail, visited: true,
        urls: visits.map(v => v.url), artifacts: visits.map(v => v.artifact + '.png'), visits,
      });
      writeReport(false);
    }

    /* rows with no live route: redirect rows are still checked (their source is code, not tree) */
    for (const row of rows) {
      if (byPattern.has(row.pattern)) continue;
      const common = { kind: 'row-only' };
      if (row.raw.startsWith('->')) {
        const url = base + row.pattern, v = await checkRedirect(row, url);
        put(row.pattern, { ...common, kind: 'redirect', verdict: v.verdict, reason: v.reason, visited: true, urls: [url] });
      } else put(row.pattern, { ...common, verdict: 'RED', reason: 'GONE — row names a route that no longer exists', visited: false });
      writeReport(false);
    }
    /* intercept targets fold into the target's existing record — never a second row for one pattern */
    for (const ic of intercepts) {
      if (rowByPattern.has(ic.target)) continue;
      const extra = `intercepting route ${ic.dir} resolves here but no row covers the target`;
      const rec = records.get(ic.target);
      if (rec) { rec.verdict = 'RED'; rec.reason = rec.reason ? `${rec.reason}; ${extra}` : extra; (rec.interceptedBy ||= []).push(ic.dir); }
      else put(ic.target, { kind: 'intercept-target', verdict: 'RED', reason: extra, visited: false, interceptedBy: [ic.dir] });
    }
    writeReport(false);
  } finally {
    if (browser) await browser.close().catch(() => {});
  }

  let secretHits = [];
  if (LINKS !== 'off') {                                                                // server is still up here
    await verifyLinks();
    secretHits = sniffSecrets();
    for (const line of secretHits) {
      const rec = [...linkRecs.values()].find(l => l.url === line);
      if (rec) { rec.verdict = 'RED'; rec.reason = `LINK_SECRET — a credential-shaped value is embedded in this URL`; }
      else linkRecs.set('leaked|' + line, {
        url: line, href: line, display: line, bucket: 'internal', text: '', pages: [],
        verdict: 'RED', reason: 'LINK_SECRET — a credential-shaped value is embedded in this URL',
        status: null, finalUrl: null, safetyVerdict: 'RED', safetyReason: 'LINK_SECRET',
      });
    }
  }

  const { report, links, red, pending, linkSummary } = writeReport(true);
  for (const r of report) {
    console.log(`${r.verdict}\t${r.pattern}\t${r.reason || 'ok'}`);
    if (r.detail) console.log(r.detail);
  }
  if (LINKS === 'off') console.log("INFO\tlinks\tSKIPPED — '!links off' is set in the map, so NO link was checked");
  else {
    for (const l of links) if (l.verdict === 'RED') console.log(linkLine(l));
    for (const l of links) if (l.verdict === 'WARN') console.log(linkLine(l));
    for (const l of links) if (l.verdict === 'SKIPPED' || l.verdict === 'INFO') console.log(linkLine(l));
    if (contactLinksSeen && !contactPins.length)
      console.log(`WARN\tcontact\t${contactLinksSeen} tel:/sms:/mailto: link(s) found and NOTHING pins them — add '!contact <number> <email>' to the map to prove the money links`);
    console.log(`INFO\tlinks\t${linkSummary.total} found — ${linkSummary.internal} internal, ${linkSummary.anchor} in-page anchor, `
      + `${linkSummary.external} external (${linkSummary.externalSkipped} skipped by default), ${linkSummary.nonHttp} non-http`
      + (linkSummary.badUrl ? `, ${linkSummary.badUrl} unresolvable` : '') + '; '
      + `${linkSummary.warned} WARN, ${linkSummary.broken} BROKEN`);
  }
  const linkRed = links.filter(l => l.verdict === 'RED').length;
  const head = `${report.length} route(s) — ${report.length - red - pending} green, ${red + linkRed} RED`;
  if (pending)
    console.log(`INFO\tsummary\t${head}, ${pending} baselines pending review — review & commit ROUTEMAP.snapshots/, then re-run`
      + (UPDATE !== null ? ' WITHOUT --update' : ''));
  else console.log(`INFO\tsummary\t${head}${red + linkRed ? '' : ' — clean'}`);
  return red + linkRed ? 1 : 0;                                                          // B1 — NEW/UPDATED never exit 1
}

/* R8 — main runs only when this file IS the entry point, so the unit test can import the
 * pure helpers above without spawning a dev server. */
const isMain = process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href;
if (isMain) {
  process.on('exit', () => { if (server.child && !server.stopped) killGroup('SIGKILL'); closeLog(); });
  for (const sig of ['SIGINT', 'SIGTERM']) process.on(sig, () => {
    killGroup('SIGTERM'); killGroup('SIGKILL'); closeLog();
    process.exit(2);
  });
  let code = 2;
  try { code = await main(); }
  catch (err) { console.error('FATAL: ' + (err instanceof Fatal ? err.message : (err?.stack || err))); code = 2; }
  finally {
    if (!(await stopServer())) {
      console.error(`FATAL: dev server teardown could not be confirmed — something is still listening on port ${PORT}`);
      code = 2;
    }
  }
  process.exit(code);
}

export { normalizeAria, lineDiff, digitsOf, contactOk, classifyHref };
