// Unit tests for the pure helpers route-check.mjs exports (R8).
// node:test, no npm deps. Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
//
// CJS HARNESS, ESM SUBJECT — and that is not a style choice. hooks/package.json pins
// "type": "commonjs", which switches OFF Node's module-syntax detection for every .js file
// under hooks/, so `import` statements here are a SyntaxError. The name cannot move to
// .mjs either: verify.sh check 1 globs 'hooks/tests/*.test.js' and a .mjs file would run
// nowhere. So the harness is require(), and the driver — a real ES module with top-level
// await, which require(esm) refuses — is pulled in with a dynamic import() of its file://
// URL inside a before() hook.
//
// WHY THESE FIVE FUNCTIONS AND NOTHING ELSE. They are the only parts of the driver that
// touch neither the filesystem, the network nor a browser — normalising an aria snapshot,
// diffing two of them, and judging an href are all decisions made on strings. Everything
// else in that file needs a running Next.js app, and is proved by the live run instead.
const { test, before } = require('node:test');
const assert = require('node:assert');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

const DRIVER = path.join(__dirname, '..', '..', 'skills', 'route-map', 'scripts', 'route-check.mjs');

let mod;
let normalizeAria, lineDiff, digitsOf, contactOk, classifyHref;

before(async () => {
  mod = await import(pathToFileURL(DRIVER).href);
  ({ normalizeAria, lineDiff, digitsOf, contactOk, classifyHref } = mod);
});

// --- THE MAIN GUARD ---------------------------------------------------------
// This assertion is not decorative. Without the import.meta.url/argv[1] guard, the import
// above would run main(), which spawns `npm run dev`, waits up to 90 seconds and then calls
// process.exit(2) — this run would die before printing a single result. Getting here at all
// is the proof; the assert pins the export surface it is allowed to have.

test('importing the driver exports the pure helpers and does NOT start main', () => {
  assert.deepStrictEqual(
    Object.keys(mod).sort(),
    ['classifyHref', 'contactOk', 'digitsOf', 'lineDiff', 'normalizeAria'],
  );
  assert.strictEqual(mod.default, undefined);
  for (const fn of [normalizeAria, lineDiff, digitsOf, contactOk, classifyHref])
    assert.strictEqual(typeof fn, 'function');
});

// --- normalizeAria ----------------------------------------------------------

test('normalizeAria strips [ref=], [active] and [cursor=]', () => {
  const got = normalizeAria([
    '- generic [ref=e1]:',
    '  - button "Save" [ref=e2] [active] [cursor=pointer]',
    '  - link "Home" [cursor=default]',
  ].join('\n'));
  assert.strictEqual(got, [
    '- generic:',
    '  - button "Save"',
    '  - link "Home"',
  ].join('\n'));
});

test('normalizeAria drops the dev-overlay subtree, including deeper-indented children', () => {
  const got = normalizeAria([
    '- generic:',
    '  - link "Home"',
    '  - button "Open Next.js Dev Tools" [ref=e9]:',
    '    - img "next logo"',
    '      - text: buried three levels down',
    '  - link "About"',
  ].join('\n'));
  assert.strictEqual(got, [
    '- generic:',
    '  - link "Home"',
    '  - link "About"',
  ].join('\n'));
  assert.ok(!got.includes('buried'), 'a deeper-indented overlay child survived the drop');
});

test('normalizeAria drops every broadened overlay variant (R5)', () => {
  // One overlay line per variant, each with a child, plus one real sibling that must live.
  for (const overlay of [
    '- button "Open Next.js Dev Tools"',
    '- dialog "Build Error"',
    '- alert "Fast Refresh had to perform a full reload"',
    '- button "Dev Tools"',
  ]) {
    const got = normalizeAria([
      '- generic:',
      '  ' + overlay + ':',
      '    - text: overlay innards',
      '  - heading "Real page"',
    ].join('\n'));
    assert.strictEqual(got, '- generic:\n  - heading "Real page"', `not dropped: ${overlay}`);
  }
});

test('normalizeAria keeps a non-overlay node whose name merely mentions the framework', () => {
  // The regex is anchored to button/dialog/alert nodes — ordinary content is not overlay.
  const got = normalizeAria('- heading "Why we left Next.js"');
  assert.strictEqual(got, '- heading "Why we left Next.js"');
});

test('normalizeAria expands leading tabs to two spaces (amendment 2)', () => {
  const got = normalizeAria('- root:\n\t- link "Home"\n\t\t- text: deep');
  assert.strictEqual(got, [
    '- root:',
    '  - link "Home"',
    '    - text: deep',
  ].join('\n'));
});

test('normalizeAria collapses internal whitespace, preserves leading indent, drops blanks', () => {
  const got = normalizeAria('- root:\n\n    - text:    lots     of   space\n\n');
  assert.strictEqual(got, '- root:\n    - text: lots of space');
});

// --- lineDiff ---------------------------------------------------------------

test('lineDiff of identical input is []', () => {
  assert.deepStrictEqual(lineDiff('a\nb\nc', 'a\nb\nc'), []);
  assert.deepStrictEqual(lineDiff(['a', 'b'], ['a', 'b']), []);
  assert.deepStrictEqual(lineDiff('', ''), []);
});

test('lineDiff of one changed line is exactly one - and one +', () => {
  const d = lineDiff(['a', 'b', 'c'], ['a', 'B', 'c']);
  assert.deepStrictEqual(d, ['- b', '+ B']);
  assert.strictEqual(d.filter(l => l.startsWith('- ')).length, 1);
  assert.strictEqual(d.filter(l => l.startsWith('+ ')).length, 1);
});

test('lineDiff of an all-changed file reports every line on both sides', () => {
  const d = lineDiff(['a', 'b'], ['x', 'y']);
  assert.strictEqual(d.filter(l => l.startsWith('- ')).length, 2);
  assert.strictEqual(d.filter(l => l.startsWith('+ ')).length, 2);
  assert.deepStrictEqual(d.slice().sort(), ['+ x', '+ y', '- a', '- b'].sort());
});

test('lineDiff trims the common prefix and suffix — only the changed window is diffed', () => {
  const a = [], b = [];
  for (let i = 0; i < 400; i++) { a.push('line ' + i); b.push('line ' + i); }
  b[200] = 'line 200 CHANGED';
  assert.deepStrictEqual(lineDiff(a, b), ['- line 200', '+ line 200 CHANGED']);
});

test('lineDiff falls back to a plain window dump past the 2000-line cap (amendment 1)', () => {
  const N = 2500;                       // both sides over the cap, and nothing in common
  const a = [], b = [];
  for (let i = 0; i < N; i++) { a.push('old ' + i); b.push('new ' + i); }
  const t0 = Date.now();
  const d = lineDiff(a, b);
  const ms = Date.now() - t0;
  assert.strictEqual(d.length, N * 2, 'the fallback must still report every line on both sides');
  assert.strictEqual(d[0], '- old 0');
  assert.strictEqual(d[N - 1], '- old ' + (N - 1));
  assert.strictEqual(d[N], '+ new 0');
  assert.strictEqual(d[N * 2 - 1], '+ new ' + (N - 1));
  // The whole point of the guard: an LCS over 2500x2500 would allocate ~6.25M cells.
  assert.ok(ms < 2000, `fallback took ${ms}ms — the LCS guard did not fire`);
});

test('lineDiff honours a custom cap, so the guard is a threshold and not a coincidence', () => {
  const a = ['a', 'b', 'c'], b = ['x', 'y', 'z'];
  assert.deepStrictEqual(lineDiff(a, b, 2), ['- a', '- b', '- c', '+ x', '+ y', '+ z']);
});

// --- digitsOf / contactOk ---------------------------------------------------
// Every number below is from the NANP 555-01xx fictional block: real enough to exercise the
// 11-digit country-code drop, real to nobody.

test('digitsOf strips punctuation and the leading US country code', () => {
  assert.strictEqual(digitsOf('+15555550100'), '5555550100');
  assert.strictEqual(digitsOf('(555) 555-0100'), '5555550100');
  assert.strictEqual(digitsOf('555.555.0100'), '5555550100');
  assert.strictEqual(digitsOf(''), '');
});

test('contactOk matches a tel: href against a differently-formatted pin', () => {
  assert.strictEqual(contactOk('tel:+15555550100', ['(555) 555-0100']), true);
  assert.strictEqual(contactOk('TEL:5555550100', ['+15555550100']), true);
});

test('contactOk compares an sms: href with its ?body= stripped', () => {
  assert.strictEqual(contactOk('sms:+15555550100?body=Quote%20please', ['5555550100']), true);
});

test('contactOk compares mailto case-insensitively with ?subject stripped', () => {
  assert.strictEqual(contactOk('mailto:Hello@Example.COM?subject=Quote', ['hello@example.com']), true);
  assert.strictEqual(contactOk('mailto:hello%40example.com', ['hello@example.com']), true);
  assert.strictEqual(contactOk('mailto:someone@example.com', ['hello@example.com']), false);
});

test('contactOk rejects a number that matches no pin', () => {
  assert.strictEqual(contactOk('tel:+15555550199', ['5555550100']), false);
  assert.strictEqual(contactOk('tel:', ['5555550100']), false);
});

test('contactOk ignores hrefs that are not contact links', () => {
  assert.strictEqual(contactOk('/about', ['5555550100']), true);
  assert.strictEqual(contactOk('https://example.com/', ['5555550100']), true);
});

test('contactOk dies on a pin under 7 digits (amendment 4)', () => {
  // Three digits would match almost every number on the page, so it is not a pin.
  assert.throws(() => contactOk('tel:+15555550100', ['555']), /under 7 digits/);
});

// --- classifyHref -----------------------------------------------------------

const BASE = 'https://site.example/plans';

test('classifyHref calls javascript: and data: hrefs unsafe', () => {
  for (const h of ['javascript:void(0)', 'data:text/plain,hello']) {
    const c = classifyHref(h, BASE);
    assert.strictEqual(c.bucket, 'non-http', h);
    assert.strictEqual(c.verdict, 'RED', h);
    assert.match(c.reason, /LINK_UNSAFE/);
  }
});

test('classifyHref warns (never reds) on target=_blank with no rel (R6)', () => {
  const c = classifyHref('https://partner.example/', BASE, '_blank', '');
  assert.strictEqual(c.verdict, 'WARN');
  assert.match(c.reason, /noopener/);
});

test('classifyHref is silent on target=_blank with rel=noopener', () => {
  assert.strictEqual(classifyHref('https://partner.example/', BASE, '_blank', 'noopener').verdict, null);
  assert.strictEqual(classifyHref('https://partner.example/', BASE, '_blank', 'noreferrer nofollow').verdict, null);
});

test('classifyHref reds an explicit rel=opener (tabnabbing)', () => {
  const c = classifyHref('https://partner.example/', BASE, '_blank', 'opener');
  assert.strictEqual(c.verdict, 'RED');
  assert.match(c.reason, /tabnabbing/);
});

test('classifyHref reds plain http: from an https page (mixed content)', () => {
  const c = classifyHref('http://partner.example/deal', BASE);
  assert.strictEqual(c.verdict, 'RED');
  assert.match(c.reason, /mixed content/);
});

test('classifyHref exempts http: on localhost — that is the dev server', () => {
  const c = classifyHref('http://localhost:4923/about', 'http://localhost:4923/');
  assert.strictEqual(c.bucket, 'internal');
  assert.strictEqual(c.verdict, null);
});

test('classifyHref buckets anchors, same-origin, cross-origin and non-http', () => {
  assert.deepStrictEqual(classifyHref('#pricing', BASE), { bucket: 'anchor', verdict: null, reason: '' });
  assert.strictEqual(classifyHref('/about', BASE).bucket, 'internal');
  assert.strictEqual(classifyHref('https://site.example/faq', BASE).bucket, 'internal');
  assert.strictEqual(classifyHref('https://other.example/', BASE).bucket, 'external');
  assert.strictEqual(classifyHref('https://other.example/', BASE).verdict, null);
  const mail = classifyHref('mailto:hello@example.com', BASE);
  assert.strictEqual(mail.bucket, 'non-http');
  assert.strictEqual(mail.verdict, null);
});
