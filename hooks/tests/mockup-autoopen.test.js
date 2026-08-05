// Tests for hooks/mockup-autoopen.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
//
// The real hook shells out to `open`, which would launch Chrome. Every test here
// points CLAUDE_MOCKUP_OPEN_CMD at a stub script that appends its argument to a
// log file, so the suite stays silent AND we can still prove the open fired.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'mockup-autoopen.js');

function setup() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'mockup-autoopen-'));
  const mockups = path.join(root, '.mockups');
  fs.mkdirSync(mockups, { recursive: true });
  const log = path.join(root, 'open.log');
  const stub = path.join(root, 'fake-open.sh');
  fs.writeFileSync(stub, `#!/bin/sh\nprintf '%s\\n' "$1" >> ${JSON.stringify(log)}\n`);
  fs.chmodSync(stub, 0o755);
  return { root, mockups, log, stub };
}

function writeMockup(mockups, rel, body = '<h1>hi</h1>') {
  const p = path.join(mockups, rel);
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, body);
  return p;
}

function run(env, file) {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_MOCKUP_NO_OPEN: '', ...env },
    input: JSON.stringify({ tool_name: 'Write', tool_input: { file_path: file } }),
    encoding: 'utf8',
  });
}

// The `open` child is detached+unref'd, so it can land after the hook exits.
function waitForLog(log, expectedLines, ms = 3000) {
  const deadline = Date.now() + ms;
  while (Date.now() < deadline) {
    const lines = fs.existsSync(log) ? fs.readFileSync(log, 'utf8').trim().split('\n').filter(Boolean) : [];
    if (lines.length >= expectedLines) return lines;
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 50);
  }
  return fs.existsSync(log) ? fs.readFileSync(log, 'utf8').trim().split('\n').filter(Boolean) : [];
}

// --- POSITIVE CONTROLS ------------------------------------------------------
// This hook's failure mode is doing nothing quietly: a path check that stops
// matching produces a silent no-op that every "ignores X" test below still
// passes. These two prove it actually fires.

test('POSITIVE CONTROL: mockup write -> index written AND open fired', () => {
  const { mockups, log, stub } = setup();
  const f = writeMockup(mockups, 'v1.html');
  const r = run({ CLAUDE_MOCKUP_OPEN_CMD: stub }, f);

  assert.strictEqual(r.status, 0);
  const idx = path.join(mockups, '_index.html');
  assert.ok(fs.existsSync(idx), 'index regenerated');
  assert.match(fs.readFileSync(idx, 'utf8'), /href="v1\.html"/);
  assert.deepStrictEqual(waitForLog(log, 1), [f]);
});

test('POSITIVE CONTROL: VARIANT header comment becomes the label', () => {
  const { mockups, stub } = setup();
  const f = writeMockup(mockups, 'design-x/v3.html', '<!-- VARIANT: v3 — bento grid -->\n<h1>x</h1>');
  run({ CLAUDE_MOCKUP_OPEN_CMD: stub }, f);

  const idx = fs.readFileSync(path.join(mockups, '_index.html'), 'utf8');
  assert.match(idx, /v3 — bento grid/);
  assert.match(idx, /href="design-x\/v3\.html"/);
});

test('index lists nested mockups newest first and excludes itself', () => {
  const { mockups, stub } = setup();
  const older = writeMockup(mockups, 'a/old.html');
  const past = Date.now() - 60_000;
  fs.utimesSync(older, past / 1000, past / 1000);
  const newer = writeMockup(mockups, 'b/new.html');
  run({ CLAUDE_MOCKUP_OPEN_CMD: stub }, newer);

  const idx = fs.readFileSync(path.join(mockups, '_index.html'), 'utf8');
  assert.ok(idx.indexOf('b/new.html') < idx.indexOf('a/old.html'), 'newest first');
  assert.ok(!idx.includes('_index.html'), 'index does not link itself');
});

// --- DEBOUNCE ---------------------------------------------------------------

test('a burst of 8 mockups opens ONCE but regenerates the index every time', () => {
  const { mockups, log, stub } = setup();
  let last;
  for (let i = 1; i <= 8; i++) {
    last = writeMockup(mockups, `v${i}.html`);
    run({ CLAUDE_MOCKUP_OPEN_CMD: stub }, last);
  }
  const lines = waitForLog(log, 2, 1500); // wait for a SECOND one that must not come
  assert.strictEqual(lines.length, 1, `expected exactly 1 open, got ${lines.length}`);

  const idx = fs.readFileSync(path.join(mockups, '_index.html'), 'utf8');
  for (let i = 1; i <= 8; i++) assert.match(idx, new RegExp(`href="v${i}\\.html"`));
});

test('an expired stamp allows a new open (debounce is a window, not a latch)', () => {
  const { mockups, log, stub } = setup();
  const a = writeMockup(mockups, 'a.html');
  run({ CLAUDE_MOCKUP_OPEN_CMD: stub }, a);
  waitForLog(log, 1);

  const stamp = path.join(mockups, '.autoopen-stamp');
  const old = (Date.now() - 60_000) / 1000;
  fs.utimesSync(stamp, old, old);

  const b = writeMockup(mockups, 'b.html');
  run({ CLAUDE_MOCKUP_OPEN_CMD: stub }, b);
  assert.deepStrictEqual(waitForLog(log, 2), [a, b]);
});

// --- NEGATIVE CONTROLS ------------------------------------------------------

test('a .html OUTSIDE .mockups is ignored entirely', () => {
  const { root, mockups, log, stub } = setup();
  const outside = path.join(root, 'src', 'page.html');
  fs.mkdirSync(path.dirname(outside), { recursive: true });
  fs.writeFileSync(outside, '<h1>real page</h1>');

  const r = run({ CLAUDE_MOCKUP_OPEN_CMD: stub }, outside);
  assert.strictEqual(r.status, 0);
  assert.ok(!fs.existsSync(path.join(mockups, '_index.html')), 'no index written');
  assert.deepStrictEqual(waitForLog(log, 1, 400), []);
});

test('writing _index.html itself does not re-trigger', () => {
  const { mockups, log, stub } = setup();
  const idx = writeMockup(mockups, '_index.html');
  run({ CLAUDE_MOCKUP_OPEN_CMD: stub }, idx);
  assert.deepStrictEqual(waitForLog(log, 1, 400), []);
});

test('a non-.html file under .mockups is ignored', () => {
  const { mockups, log, stub } = setup();
  const f = writeMockup(mockups, 'notes.md', 'x');
  run({ CLAUDE_MOCKUP_OPEN_CMD: stub }, f);
  assert.ok(!fs.existsSync(path.join(mockups, '_index.html')));
  assert.deepStrictEqual(waitForLog(log, 1, 400), []);
});

test('CLAUDE_MOCKUP_NO_OPEN=1 (platform-guard path) -> index yes, open no', () => {
  const { mockups, log, stub } = setup();
  const f = writeMockup(mockups, 'v1.html');
  const r = run({ CLAUDE_MOCKUP_OPEN_CMD: stub, CLAUDE_MOCKUP_NO_OPEN: '1' }, f);
  assert.strictEqual(r.status, 0);
  assert.ok(fs.existsSync(path.join(mockups, '_index.html')), 'index still regenerated');
  assert.deepStrictEqual(waitForLog(log, 1, 400), []);
});

test('missing open command -> exit 0, no crash', () => {
  const { mockups } = setup();
  const f = writeMockup(mockups, 'v1.html');
  const r = run({ CLAUDE_MOCKUP_OPEN_CMD: '/nonexistent/definitely-not-open' }, f);
  assert.strictEqual(r.status, 0);
  assert.ok(fs.existsSync(path.join(mockups, '_index.html')));
});

// --- ROBUSTNESS -------------------------------------------------------------

test('a path that no longer exists on disk -> exit 0, no index', () => {
  const { mockups, stub } = setup();
  const r = run({ CLAUDE_MOCKUP_OPEN_CMD: stub }, path.join(mockups, 'ghost.html'));
  assert.strictEqual(r.status, 0);
  assert.ok(!fs.existsSync(path.join(mockups, '_index.html')));
});

test('empty stdin -> exit 0', () => {
  const r = spawnSync(process.execPath, [hookPath], { input: '', encoding: 'utf8' });
  assert.strictEqual(r.status, 0);
});

test('garbage stdin -> exit 0', () => {
  const r = spawnSync(process.execPath, [hookPath], { input: '<<<not json>>>', encoding: 'utf8' });
  assert.strictEqual(r.status, 0);
});
