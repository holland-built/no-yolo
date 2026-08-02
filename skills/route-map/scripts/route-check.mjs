#!/usr/bin/env node
/* route-check.mjs — mechanical Next.js route enumerator + browser checker.
 * Uses the APP's own `playwright` library via createRequire — never
 * @playwright/test, never a playwright.config, nothing installed.
 *
 * Usage:
 *   node route-check.mjs <app-root> --enumerate
 *   node route-check.mjs <app-root> <ROUTEMAP.md> <out-dir>
 *
 * Exit codes (B1 — a caller must NEVER treat 1 as clean):
 *   0 = ran to completion, ZERO red verdicts
 *   1 = ran to completion, at least one RED (report.json is still written)
 *   2 = could NOT run — caller treats this as RED-everything, never pass
 *
 * Every operational error funnels through die() -> exit 2 (B2); nothing throws
 * uncaught, and the dev server is always torn down (B3).
 *
 * While each page is open its links are also collected; internal links and in-page
 * anchors are verified (B10). A broken link is RED and so makes the exit 1 — it
 * never gets its own exit code. `!links off` skips it; `!links external` widens it.
 *
 * report.json rows carry `expectedCellSafe`: the pipe-free form of the row's
 * expected cell. Adjudication MUST use that value when appending was:"<old
 * cell>" to a note, so a pipe can never break the row parser on the next run (B5).
 */
import { createRequire } from 'node:module';
import { readdirSync, readFileSync, writeFileSync, mkdirSync, existsSync, openSync, closeSync } from 'node:fs';
import { spawn, spawnSync } from 'node:child_process';
import { join, relative, resolve } from 'node:path';
import { createHash } from 'node:crypto';
import { connect } from 'node:net';

class Fatal extends Error {}
const die = m => { throw new Fatal(m); };
const sleep = ms => new Promise(r => setTimeout(r, ms));
const norm = s => String(s).replace(/\s+/g, ' ').trim();
const mapSafe = s => norm(String(s).replace(/\|/g, '/'));                 // B5
const hash8 = s => createHash('sha256').update(s).digest('hex').slice(0, 8);
const PORT = 4923;

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
process.on('exit', () => { if (server.child && !server.stopped) killGroup('SIGKILL'); closeLog(); });
for (const sig of ['SIGINT', 'SIGTERM']) process.on(sig, () => {
  killGroup('SIGTERM'); killGroup('SIGKILL'); closeLog();
  process.exit(2);
});

/* ---------- enumeration constants ---------- */
const PAGE_EXT = new Set(['js', 'jsx', 'ts', 'tsx']);          // page.<ext>
const ROUTE_EXT = new Set(['js', 'ts']);                       // route.<ext>
const META = /^(robots\.|sitemap\.|manifest\.|favicon\.ico$|icon\.|icon\d|apple-icon|opengraph-image|twitter-image)/;

async function main() {
  /* ---------- CLI shape (B2) ---------- */
  const argv = process.argv.slice(2);
  const flags = argv.filter(a => a.startsWith('--'));
  const pos = argv.filter(a => !a.startsWith('--'));
  const USAGE = 'usage: route-check.mjs <app-root> --enumerate | route-check.mjs <app-root> <ROUTEMAP.md> <out-dir>';
  for (const f of flags) if (f !== '--enumerate') die(`unknown flag '${f}' — ${USAGE}`);
  const ENUM_ONLY = flags.includes('--enumerate');
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
        continue;                                     // layout/loading/error/css/components — not route-producing
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

  /* ---------- map ---------- */
  const mapPath = resolve(pos[1]), OUT = resolve(pos[2]);
  let mapText;
  try { mapText = readFileSync(mapPath, 'utf8'); }
  catch (err) { die(`cannot read route map '${mapPath}': ${err.message}`); }
  try { mkdirSync(OUT, { recursive: true }); }
  catch (err) { die(`cannot create out-dir '${OUT}': ${err.message}`); }

  const DIRECTIVES = new Set(['base', 'auth', 'seed', 'login', 'ack', 'empty', 'links']);
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
    if (await portOpen(PORT)) die(`port ${PORT} already in use — stop it or declare !base`);
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
    const r = spawnSync(cmd, { cwd: appRoot, shell: true, stdio: 'inherit' });
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
  try { pw = requireApp('playwright'); } catch { die("app has no 'playwright' library installed"); }

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

  /* ---------- link checking (B10 — a dead link is RED, never a silent skip) ---------- */
  const baseOrigin = new URL(base).origin;
  const linkRecs = new Map();                                                           // ONE record per resolved URL
  const SCHEME = /^([A-Za-z][A-Za-z0-9+.-]*):/;
  const fragOf = h => { try { return decodeURIComponent(h.slice(1)); } catch { return h.slice(1); } };
  /** Gather every a[href] on the open page and bucket it. Anchors are judged HERE,
   *  because `#foo` can only be resolved against the page it was found on. */
  async function collectLinks(page, pageUrl, pattern) {
    const got = await page.evaluate(() => ({
      links: [...document.querySelectorAll('a[href]')].map(el => ({
        href: el.getAttribute('href') || '',
        text: [el.textContent || '', el.getAttribute('aria-label') || '', el.querySelector('img')?.alt || '']
          .join(' ').replace(/\s+/g, ' ').trim().slice(0, 60),
      })),
      ids: [...document.querySelectorAll('[id], a[name]')].map(el => el.id || el.getAttribute('name') || ''),
    }));
    const idSet = new Set(got.ids.filter(Boolean));
    for (const { href, text } of got.links) {
      const h = href.trim();
      let bucket = 'internal', key, display = h, badUrl = false, anchorTarget = null;
      if (h.startsWith('#')) {
        bucket = 'anchor'; anchorTarget = fragOf(h);
        key = pageUrl.split('#')[0] + '#' + anchorTarget;                                // per-page by construction
      } else {
        const m = SCHEME.exec(h);
        if (m && !/^https?$/i.test(m[1])) { bucket = 'non-http'; key = 'non-http:' + h; }
        else {
          let u = null;
          try { u = new URL(h, pageUrl); } catch { badUrl = true; }
          if (u) {
            bucket = u.origin === baseOrigin ? 'internal' : 'external';
            key = u.href;
            display = bucket === 'internal' ? u.pathname + u.search + u.hash : u.href;
          } else key = 'bad-url:' + h;              // unparseable → counted as OURS, so it goes RED, never skipped
        }
      }
      let rec = linkRecs.get(key);
      if (!rec) {
        rec = { url: key, href: h, display, bucket, text, badUrl, anchorTarget, pages: [], verdict: null, reason: '', status: null, finalUrl: null };
        linkRecs.set(key, rec);
      }
      if (!rec.pages.includes(pattern)) rec.pages.push(pattern);
      if (!rec.text && text) rec.text = text;
      if (bucket === 'anchor' && rec.verdict === null) {
        const ok = anchorTarget === '' || anchorTarget.toLowerCase() === 'top' || idSet.has(anchorTarget);
        rec.verdict = ok ? 'GREEN' : 'RED';
        rec.reason = ok ? '' : `no element with id "${anchorTarget}"`;
      }
    }
  }
  /** HEAD first, GET on 405/501 (dev servers can be picky), redirects followed. */
  async function verifyLinks() {
    const cache = new Map();                                                            // one request per distinct path
    const probe = async url => {
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
      if (rec.bucket === 'anchor') continue;                                            // already judged, on its page
      if (rec.bucket === 'non-http') {
        rec.verdict = 'INFO'; rec.reason = `${(SCHEME.exec(rec.href) || [, '?'])[1].toLowerCase()}: link — reported, never checked`; continue;
      }
      if (rec.bucket === 'external' && LINKS !== 'external') {
        rec.verdict = 'SKIPPED'; rec.reason = "external — not checked, '!links external' is not set"; continue;
      }
      if (rec.badUrl) { rec.verdict = 'RED'; rec.reason = `unresolvable href "${rec.href}"`; continue; }
      const r = await probe(rec.url);
      rec.verdict = r.verdict; rec.status = r.status; rec.finalUrl = r.finalUrl;
      rec.reason = r.verdict === 'GREEN' ? '' : (r.status ? String(r.status) : `request failed — ${r.err}`);
    }
  }
  const linkLine = l => `${l.verdict}\tlink ${l.display}\t${l.reason}`
    + (l.pages.length ? ` from ${l.pages.join(', ')}` : '') + (l.text ? ` — text "${l.text}"` : '');

  const records = new Map();                                                            // B8 — ONE record per pattern
  const put = (pattern, rec) => { records.set(pattern, { pattern, ...rec }); return records.get(pattern); };
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

  const browser = await pw.chromium.launch();                                           // headless by default
  try {
    for (const r of byPattern.values()) {
      const row = rowByPattern.get(r.pattern);
      const common = { kind: r.kind, file: r.file, expectedCellSafe: row ? mapSafe(row.raw) : '' };
      if (!row) { put(r.pattern, { ...common, verdict: 'RED', reason: 'NO_ROW — route exists in the tree but has no ROUTEMAP row', visited: false }); continue; }
      if (/\bdraft\b/.test(row.note)) { put(r.pattern, { ...common, verdict: 'RED', reason: 'DRAFT — expectation not yet reviewed', visited: false }); continue; }
      const { urls, missing, malformed, unused } = expand(r.pattern, row.note);
      if (malformed.length) { put(r.pattern, { ...common, verdict: 'RED', reason: `BAD_FIXTURE — malformed fixture declaration(s): ${malformed.join(', ')}`, visited: false }); continue; }
      if (missing.length) { put(r.pattern, { ...common, verdict: 'RED', reason: 'NO_FIXTURE — dynamic segment has no declared fixture value', visited: false }); continue; }
      if (unused.length) { put(r.pattern, { ...common, verdict: 'RED', reason: `BAD_FIXTURE — fixture(s) ${unused.join(', ')} match no dynamic segment in the pattern`, visited: false }); continue; }

      if (r.kind === 'api') {
        const url = base + urls.at(-1), art = artifactOf(r.pattern, url);
        try {
          const res = await fetch(url);
          const body = await res.text();
          writeFileSync(join(OUT, art + '.body.txt'), body);
          const want = row.raw.match(/status=(\d+)/);
          const hay = norm(body).toLowerCase();                                         // B8 — same norm as the page path
          let verdict = 'GREEN', reason = '';
          if (!want && row.expected.length === 0) { verdict = 'RED'; reason = 'NO_EXPECTATION — row has no quoted substrings'; }
          else if (!((!want || res.status === +want[1]) && row.expected.every(e => hay.includes(norm(e).toLowerCase())))) { verdict = 'RED'; reason = 'MISMATCH — status/body did not satisfy the row'; }
          put(r.pattern, { ...common, verdict, reason, visited: true, urls: [url], artifacts: [art + '.body.txt'], status: res.status });
        } catch (err) { put(r.pattern, { ...common, verdict: 'RED', reason: 'VISIT_FAILED — ' + err.message, visited: false, urls: [url] }); }
        continue;
      }

      if (row.raw.startsWith('->')) {
        const url = base + urls.at(-1), v = await checkRedirect(row, url);
        put(r.pattern, { ...common, verdict: v.verdict, reason: v.reason, visited: true, urls: [url] });
        continue;
      }

      const ctx = await browser.newContext(row.auth !== 'none' && storageState ? { storageState } : {});
      const page = await ctx.newPage();
      const log = [];
      page.on('console', m => log.push(`[console.${m.type()}] ${m.text()}`));            // B9 — hydration failures visible
      page.on('pageerror', e => log.push(`[pageerror] ${e.message}`));
      page.on('requestfailed', q => log.push(`[requestfailed] ${q.url()} — ${q.failure()?.errorText || ''}`));
      const visits = [];
      for (const u of urls) {                                                            // B8 — visit EVERY variant
        const url = base + u, art = artifactOf(r.pattern, url), mark = log.length;
        let ok = true, reason = '';
        try {
          await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });       // B9
          const text = await stableText(page);
          writeFileSync(join(OUT, art + '.txt'), text);
          await page.screenshot({ path: join(OUT, art + '.png'), fullPage: true });
          if (LINKS !== 'off') await collectLinks(page, page.url(), r.pattern);
          if (text.length < 40 && !/\bempty-ok\b/.test(row.note)) { ok = false; reason = 'EMPTY — under 40 chars of visible text and no empty-ok'; }
          else if (row.expected.length === 0) { ok = false; reason = 'NO_EXPECTATION — row has no quoted substrings'; }
          else {
            const missSub = row.expected.find(e => !text.toLowerCase().includes(norm(e).toLowerCase()));
            if (missSub) { ok = false; reason = `MISMATCH — missing "${missSub}"`; }
          }
        } catch (err) { ok = false; reason = 'VISIT_FAILED — ' + err.message; }
        writeFileSync(join(OUT, art + '.console.txt'), log.slice(mark).join('\n') + '\n');
        visits.push({ url, artifact: art, verdict: ok ? 'GREEN' : 'RED', reason });
      }
      await ctx.close();
      const bad = visits.find(v => v.verdict === 'RED');
      put(r.pattern, {
        ...common, verdict: bad ? 'RED' : 'GREEN', reason: bad ? bad.reason : '', visited: true,
        urls: visits.map(v => v.url), artifacts: visits.map(v => v.artifact + '.png'), visits,
      });
    }

    /* rows with no live route: redirect rows are still checked (their source is code, not tree) */
    for (const row of rows) {
      if (byPattern.has(row.pattern)) continue;
      const common = { kind: 'row-only', expectedCellSafe: mapSafe(row.raw) };
      if (row.raw.startsWith('->')) {
        const url = base + row.pattern, v = await checkRedirect(row, url);
        put(row.pattern, { ...common, kind: 'redirect', verdict: v.verdict, reason: v.reason, visited: true, urls: [url] });
      } else put(row.pattern, { ...common, verdict: 'RED', reason: 'GONE — row names a route that no longer exists', visited: false });
    }
    /* intercept targets fold into the target's existing record — never a second row for one pattern */
    for (const ic of intercepts) {
      if (rowByPattern.has(ic.target)) continue;
      const extra = `intercepting route ${ic.dir} resolves here but no row covers the target`;
      const rec = records.get(ic.target);
      if (rec) { rec.verdict = 'RED'; rec.reason = rec.reason ? `${rec.reason}; ${extra}` : extra; (rec.interceptedBy ||= []).push(ic.dir); }
      else put(ic.target, { kind: 'intercept-target', verdict: 'RED', reason: extra, visited: false, interceptedBy: [ic.dir] });
    }
  } finally {
    await browser.close().catch(() => {});
  }

  if (LINKS !== 'off') await verifyLinks();                                             // server is still up here
  const links = [...linkRecs.values()];
  const linkRed = links.filter(l => l.verdict === 'RED');
  const nBucket = b => links.filter(l => l.bucket === b).length;
  const linkSummary = {
    mode: LINKS, total: links.length, internal: nBucket('internal'), anchor: nBucket('anchor'),
    external: nBucket('external'), nonHttp: nBucket('non-http'),
    externalSkipped: links.filter(l => l.verdict === 'SKIPPED').length, broken: linkRed.length,
  };

  const report = [...records.values()];
  const red = report.filter(r => r.verdict === 'RED').length;
  writeFileSync(join(OUT, 'report.json'), JSON.stringify({
    base, router: ROOT, meta, intercepts,
    summary: { total: report.length, green: report.length - red, red },
    report, linkSummary, links,
  }, null, 2));
  for (const r of report) console.log(`${r.verdict}\t${r.pattern}\t${r.reason || 'ok'}`);
  if (LINKS === 'off') console.log("INFO\tlinks\tSKIPPED — '!links off' is set in the map, so NO link was checked");
  else {
    for (const l of linkRed) console.log(linkLine(l));
    for (const l of links) if (l.verdict === 'SKIPPED' || l.verdict === 'INFO') console.log(linkLine(l));
    console.log(`INFO\tlinks\t${linkSummary.total} found — ${linkSummary.internal} internal, ${linkSummary.anchor} in-page anchor, `
      + `${linkSummary.external} external (${linkSummary.externalSkipped} skipped by default), ${linkSummary.nonHttp} non-http; `
      + `${linkSummary.broken} BROKEN`);
  }
  return red + linkRed.length ? 1 : 0;                                                  // B1 — a broken link is RED
}

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
