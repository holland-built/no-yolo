// borrowed-check.test.js — proves skills/checkup/scripts/borrowed_check.py REFUSES to be
// silent. It is not a hook; it lives here because hooks/tests/ is what verify.sh check 1
// globs and what /checkup Step 1.5 runs, and the route-check suites already share the
// folder on the same grounds.
//
// The check this replaces had four defects and every one of them was invisible: a
// directory with no .git printed nothing, a missing tracking branch printed a blank
// where a count belonged, and the 144K vendored directory was never looked at. So the
// assertions below are not "does it work" — they are "does it say so out loud", one
// per failure mode, each driven against a throwaway fixture tree.

const { test } = require('node:test');
const assert = require('node:assert');
const { execFileSync, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const SCRIPT = path.join(__dirname, '..', '..', 'skills', 'checkup', 'scripts', 'borrowed_check.py');

const HEADER =
  '| Name | Kind | Path | Upstream | Pinned | Content hash | How checked | Licence |\n' +
  '|---|---|---|---|---|---|---|---|\n';

/** Build a throwaway repo root with a manifest and whatever directories a case needs. */
function fixture(rows, dirs = []) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'borrowed-'));
  fs.mkdirSync(path.join(root, 'docs'), { recursive: true });
  fs.writeFileSync(path.join(root, 'docs', 'BORROWED.md'), '# fixture\n\n' + HEADER + rows.join('\n') + '\n');
  for (const d of dirs) fs.mkdirSync(path.join(root, d), { recursive: true });
  return root;
}

function run(root) {
  // gh is never reachable from a fixture upstream, so the network-dependent branches are
  // deliberately not asserted here; the cases below all resolve before any gh call.
  return spawnSync('python3', [SCRIPT], {
    encoding: 'utf8',
    env: { ...process.env, CHECKUP_ROOT: root },
  });
}

// --- it says so out loud ----------------------------------------------------

test('a source with no upstream recorded says so, rather than printing nothing', () => {
  const root = fixture(
    ['| lonely | vendored | vendor/lonely | unknown | unknown | unknown | hash | MIT |'],
    ['vendor/lonely']
  );
  fs.writeFileSync(path.join(root, 'vendor', 'lonely', 'a.md'), 'hello');
  const r = run(root);
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /\| lonely \|/, 'the source must appear at all — silence was the original bug');
  assert.match(r.stdout, /CANNOT CHECK — no upstream recorded/);
});

test('a git checkout with a remote but no tracking branch names that exact problem', () => {
  const root = fixture(
    ['| detached | marketplace | vendor/detached | https://example.invalid/x | unknown | n/a | git | MIT |'],
    ['vendor/detached']
  );
  const d = path.join(root, 'vendor', 'detached');
  execFileSync('git', ['init', '-q', '-b', 'main'], { cwd: d });
  execFileSync('git', ['remote', 'add', 'origin', 'https://example.invalid/x.git'], { cwd: d });
  fs.writeFileSync(path.join(d, 'a.md'), 'hello');
  execFileSync('git', ['add', '-A'], { cwd: d });
  execFileSync('git', ['-c', 'user.email=t@t', '-c', 'user.name=t', 'commit', '-qm', 'init'], { cwd: d });
  const r = run(root);
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /CANNOT CHECK — no tracking branch configured/);
  assert.doesNotMatch(r.stdout, /no upstream recorded/, 'a configured remote is a different problem');
});

test('a manifest entry whose directory is gone reports MISSING', () => {
  const root = fixture(['| ghost | vendored | vendor/ghost | unknown | unknown | unknown | hash | MIT |']);
  const r = run(root);
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /MISSING — in manifest, not on disk/);
});

test('a directory nobody registered is reported UNREGISTERED', () => {
  const root = fixture(
    ['| known | vendored | skills/design/vendor/known | unknown | unknown | unknown | hash | MIT |'],
    ['skills/design/vendor/known', 'skills/design/vendor/stowaway']
  );
  fs.writeFileSync(path.join(root, 'skills/design/vendor/known', 'a.md'), 'x');
  const r = run(root);
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /stowaway.*UNREGISTERED — on disk, not in the manifest/);
});

test('locally edited vendored files are caught by the content hash', () => {
  const root = fixture(
    ['| pinned | vendored | vendor/pinned | unknown | unknown | ' +
      'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef | hash | MIT |'],
    ['vendor/pinned']
  );
  fs.writeFileSync(path.join(root, 'vendor', 'pinned', 'a.md'), 'tampered');
  const r = run(root);
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /EDITED LOCALLY — recorded deadbeefdead/);
});

test('no output row ever contains a blank cell', () => {
  const root = fixture(
    [
      '| lonely | vendored | vendor/lonely | unknown | unknown | unknown | hash | MIT |',
      '| ghost | vendored | vendor/ghost | unknown | unknown | unknown | hash | MIT |',
    ],
    ['vendor/lonely']
  );
  fs.writeFileSync(path.join(root, 'vendor', 'lonely', 'a.md'), 'hello');
  const r = run(root);
  assert.strictEqual(r.status, 0, r.stderr);
  const body = r.stdout.split('\n').filter((l) => l.startsWith('|') && !/^\|-/.test(l));
  assert.ok(body.length >= 3, 'header plus both sources');
  for (const line of body) {
    assert.doesNotMatch(line, /\|\s*\|/, `blank cell in: ${line}`);
  }
});

test('a machine-managed directory is not hashed, and says why', () => {
  const root = fixture(
    ['| auto | marketplace | vendor/auto | unknown | unknown | machine-managed | hash | MIT |'],
    ['vendor/auto']
  );
  fs.writeFileSync(path.join(root, 'vendor', 'auto', 'a.md'), 'whatever a tool wrote');
  const r = run(root);
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /not checked — directory is machine-managed/);
  assert.doesNotMatch(r.stdout, /EDITED LOCALLY/, 'a tool rewriting its own files is not a local edit');
});

test('an unreadable pin file is named, not silently treated as unpinned', () => {
  const root = fixture(
    ['| pinfile | marketplace | vendor/pinfile | https://github.com/o/r | .missing-sha | machine-managed | hash | MIT |'],
    ['vendor/pinfile']
  );
  const r = run(root);
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /CANNOT CHECK — pin file \.missing-sha unreadable/);
});

// --- a manifest it cannot trust is a hard error, not a shrug ----------------

test('a malformed row aborts instead of silently dropping the sources it could not read', () => {
  const root = fixture(['| too | few | cells |']);
  const r = run(root);
  assert.notStrictEqual(r.status, 0);
  assert.match(r.stderr, /malformed manifest row/);
});

test('a duplicate source name aborts', () => {
  const root = fixture([
    '| twin | vendored | vendor/a | unknown | unknown | unknown | hash | MIT |',
    '| twin | vendored | vendor/b | unknown | unknown | unknown | hash | MIT |',
  ]);
  const r = run(root);
  assert.notStrictEqual(r.status, 0);
  assert.match(r.stderr, /duplicate manifest entries: twin/);
});

test('an unknown check method aborts and names the allowed ones', () => {
  const root = fixture(['| odd | vendored | vendor/a | unknown | unknown | unknown | vibes | MIT |']);
  const r = run(root);
  assert.notStrictEqual(r.status, 0);
  assert.match(r.stderr, /unknown check method/);
});

test('an empty manifest aborts — nothing being watched is a finding, not a pass', () => {
  const root = fixture([]);
  const r = run(root);
  assert.notStrictEqual(r.status, 0);
  assert.match(r.stderr, /nothing is being watched/);
});

test('a missing manifest aborts', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'borrowed-'));
  const r = run(root);
  assert.notStrictEqual(r.status, 0);
  assert.match(r.stderr, /manifest not found/);
});

// --- the real manifest in this repo actually parses -------------------------

test("this repo's own docs/BORROWED.md parses and every source produces a row", () => {
  const r = spawnSync('python3', [SCRIPT], { encoding: 'utf8' });
  assert.strictEqual(r.status, 0, r.stderr);
  const body = r.stdout.split('\n').filter((l) => l.startsWith('|') && !/^\|-/.test(l));
  assert.ok(body.length > 1, 'the real manifest must produce rows');
  for (const line of body) assert.doesNotMatch(line, /\|\s*\|/, `blank cell in: ${line}`);
});
