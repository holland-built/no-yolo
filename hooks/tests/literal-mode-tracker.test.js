// Contract for hooks/literal-mode-tracker.js, run as a black box: a prompt goes
// in on stdin, and the exit code, stdout, and the flag file's existence come out.
//   node --test 'hooks/tests/*.test.js'
//
// Rewritten from a blank page 2026-08-22 (machinery rebuild), AFTER the hook and
// judged against it. The hook was rewritten first with the old suite as referee,
// so neither side was ever re-authored with nothing watching.
//
// WHAT MUST HOLD:
//   - the mode's state is the EXISTENCE of the flag file, never its contents;
//   - a sticky toggle (/literal) persists; an inline safeword does not;
//   - a safeword must not fire on ordinary prose that merely contains the word
//     "literal", which is the false positive that would make the feature unusable;
//   - CLAUDE_CONFIG_DIR is honoured, so a second profile keeps its own mode;
//   - nothing ever throws, and the exit code is always 0.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const HOOK = path.join(__dirname, '..', 'literal-mode-tracker.js');

function profile() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'literal-mode-'));
}
function flagOf(dir) {
  return path.join(dir, '.literal-active');
}
function run(dir, prompt, raw) {
  return spawnSync(process.execPath, [HOOK], {
    env: { ...process.env, CLAUDE_CONFIG_DIR: dir },
    input: raw !== undefined ? raw : JSON.stringify({ prompt }),
    encoding: 'utf8',
  });
}
const reminded = (r) => /LITERAL MODE ACTIVE/.test(r.stdout);

// ---------------------------------------------------------------- the toggle

test('/literal creates the flag and reminds', () => {
  const dir = profile();
  const r = run(dir, '/literal');
  assert.strictEqual(r.status, 0);
  assert.ok(fs.existsSync(flagOf(dir)), 'flag must exist afterwards');
  assert.ok(reminded(r));
});

test('/literal on is the same toggle', () => {
  const dir = profile();
  run(dir, '/literal on');
  assert.ok(fs.existsSync(flagOf(dir)));
});

test('/literal off removes an existing flag', () => {
  const dir = profile();
  fs.writeFileSync(flagOf(dir), '1');
  const r = run(dir, '/literal off');
  assert.strictEqual(r.status, 0);
  assert.strictEqual(fs.existsSync(flagOf(dir)), false);
});

for (const phrase of ['stop literal', 'ok normal mode please']) {
  test(`"${phrase}" turns the mode off`, () => {
    const dir = profile();
    fs.writeFileSync(flagOf(dir), '1');
    run(dir, phrase);
    assert.strictEqual(fs.existsSync(flagOf(dir)), false);
  });
}

test('while the flag is present, an ordinary prompt still gets the reminder', () => {
  const dir = profile();
  fs.writeFileSync(flagOf(dir), '1');
  const r = run(dir, 'fix the header');
  assert.strictEqual(r.status, 0);
  assert.ok(reminded(r), 'the mode is sticky: every turn is reminded');
});

test('with no flag, an ordinary prompt says nothing at all', () => {
  const dir = profile();
  const r = run(dir, 'make the header blue');
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stdout.trim(), '');
});

// ------------------------------------------------------------- the safewords
// These reminded FOR ONE TURN. If one ever created the flag, a passing remark
// would silently switch the session into a mode nobody asked to keep.

for (const phrase of [
  'just do it, no more debate',
  'do exactly what I say',
  'no pushback please',
  'literally do what I asked',
]) {
  test(`inline safeword "${phrase}" reminds without creating the flag`, () => {
    const dir = profile();
    const r = run(dir, phrase);
    assert.strictEqual(r.status, 0);
    assert.ok(reminded(r), 'should remind this turn');
    assert.strictEqual(fs.existsSync(flagOf(dir)), false, 'must NOT become sticky');
  });
}

// The false positive that matters. "literal" is an ordinary word in programming
// prose, so a bare substring match would fire constantly and the feature would be
// switched off within a day.
for (const phrase of [
  'fix the literal string in the parser',
  'the literal value 42 is wrong',
  'use a string literal here',
]) {
  test(`ordinary prose is not a safeword: "${phrase}"`, () => {
    const dir = profile();
    const r = run(dir, phrase);
    assert.strictEqual(r.stdout.trim(), '');
    assert.strictEqual(fs.existsSync(flagOf(dir)), false);
  });
}

// ------------------------------------------------------------------ the flag
// Existence is the state, so the flag path is somewhere an attacker would plant
// a link. Following one would read or delete whatever it points at.

test('a symlink at the flag path is not treated as the mode being on', () => {
  const dir = profile();
  const decoy = path.join(dir, 'decoy');
  fs.writeFileSync(decoy, 'SECRET-CANARY');
  fs.symlinkSync(decoy, flagOf(dir));
  const r = run(dir, 'fix the header');
  assert.strictEqual(r.status, 0);
  assert.ok(!reminded(r), 'a symlinked flag must not count as on');
  assert.ok(!/CANARY/.test(r.stdout), 'and must never leak the target');
});

test('/literal off does not delete through a symlink', () => {
  const dir = profile();
  const decoy = path.join(dir, 'decoy');
  fs.writeFileSync(decoy, 'keep me');
  fs.symlinkSync(decoy, flagOf(dir));
  run(dir, '/literal off');
  assert.ok(fs.existsSync(decoy), 'the symlink target must survive');
});

test('a directory at the flag path is not the mode being on', () => {
  const dir = profile();
  fs.mkdirSync(flagOf(dir));
  const r = run(dir, 'fix the header');
  assert.strictEqual(r.status, 0);
  assert.ok(!reminded(r));
});

test('CLAUDE_CONFIG_DIR is honoured, so profiles do not share a mode', () => {
  const work = profile();
  const personal = profile();
  run(work, '/literal');
  assert.ok(fs.existsSync(flagOf(work)));
  assert.strictEqual(fs.existsSync(flagOf(personal)), false, 'the other profile is untouched');
  assert.ok(!reminded(run(personal, 'fix the header')));
});

// --------------------------------------------------------------- fail quiet

for (const [name, raw] of [
  ['empty stdin', ''],
  ['garbage stdin', '{ not json at all'],
  ['no prompt key', JSON.stringify({ other: 1 })],
  ['prompt of the wrong type', JSON.stringify({ prompt: 42 })],
]) {
  test(`${name} -> exit 0, nothing written`, () => {
    const dir = profile();
    const r = run(dir, undefined, raw);
    assert.strictEqual(r.status, 0);
    assert.strictEqual(fs.existsSync(flagOf(dir)), false);
  });
}
