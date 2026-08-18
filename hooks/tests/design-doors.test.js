// design-doors.test.js — proves skills/checkup/scripts/design_doors.py notices a design door
// coming back, and stays quiet when nothing has.
//
// Not a hook. It lives here because hooks/tests/ is what verify.sh check 1 globs, the same
// reason borrowed-check and the route-check suites share the folder.
//
// The first version of this checker classified by keyword and reported nine rivals, all nine
// wrong. Silence when healthy is therefore a REQUIREMENT, not a nicety: a check that is wrong
// every run is one nobody reads, which is the same outcome as no check at all. Both halves are
// asserted below.

const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const SCRIPT = path.join(__dirname, '..', '..', 'skills', 'checkup', 'scripts', 'design_doors.py');

const ROSTER_HEADER = '| Surface | Route | Verdict | Why |\n|---|---|---|---|\n';

/** A throwaway repo root: a roster, and skills with whatever frontmatter the case needs. */
function fixture(rosterRows, skills) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'doors-'));
  fs.mkdirSync(path.join(root, 'docs'), { recursive: true });
  fs.writeFileSync(
    path.join(root, 'docs', 'DESIGN_SURFACES.md'),
    '# fixture\n\n' + ROSTER_HEADER + rosterRows.join('\n') + '\n'
  );
  for (const [name, fm] of Object.entries(skills)) {
    fs.mkdirSync(path.join(root, 'skills', name), { recursive: true });
    fs.writeFileSync(path.join(root, 'skills', name, 'SKILL.md'), `---\n${fm}\n---\n\nbody\n`);
  }
  return root;
}

const run = (root) =>
  spawnSync('python3', [SCRIPT], { encoding: 'utf8', env: { ...process.env, CHECKUP_ROOT: root } });

const DESC = 'description: Redesign UI surfaces and interface layout.';

test('a reference skill that lost its flag is reported as a rival', () => {
  const root = fixture(
    ['| `motion-ref` | 2 | reference | motion values |'],
    { 'motion-ref': `name: motion-ref\n${DESC}` }   // flag missing = model-invocable again
  );
  const r = run(root);
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /motion-ref.*RIVAL REAPPEARED/);
  assert.match(r.stdout, /lost disable-model-invocation/);
});

test('the same skill with its flag intact produces no row at all', () => {
  const root = fixture(
    ['| `motion-ref` | 2 | reference | motion values |'],
    { 'motion-ref': `name: motion-ref\ndisable-model-invocation: true\n${DESC}` }
  );
  const r = run(root);
  assert.strictEqual(r.status, 0, r.stderr);
  assert.doesNotMatch(r.stdout, /motion-ref/, 'a held demotion must be silent, not a green row');
  assert.match(r.stdout, /0 rival\(s\) reappeared, 0 unclassified/);
});

test('a design skill nobody has classified is reported, not guessed at', () => {
  const root = fixture(
    ['| `design` | 1 — own skill | door | the door |'],
    { design: 'name: design\ndescription: The design door.',
      newcomer: `name: newcomer\n${DESC}` }
  );
  const r = run(root);
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /newcomer.*UNCLASSIFIED/);
  assert.match(r.stdout, /classify it in DESIGN_SURFACES\.md/);
});

test('a non-design skill is not flagged just for mentioning design words', () => {
  const root = fixture(
    ['| `design` | 1 — own skill | door | the door |'],
    { design: 'name: design\ndescription: The design door.',
      explainer: 'name: explainer\ndescription: Explains anything in plain words.' }
  );
  const r = run(root);
  assert.strictEqual(r.status, 0, r.stderr);
  assert.doesNotMatch(r.stdout, /explainer/);
});

test('an unreadable roster aborts rather than calling everything a rival', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'doors-'));
  const r = run(root);
  assert.notStrictEqual(r.status, 0);
  assert.match(r.stderr, /the roster IS the check/);
});

test('a roster with no parsable rows aborts', () => {
  const root = fixture([], {});
  const r = run(root);
  assert.notStrictEqual(r.status, 0);
  assert.match(r.stderr, /refusing to report every surface as unclassified/);
});

test("this repo's own roster parses and reports zero rivals", () => {
  const r = spawnSync('python3', [SCRIPT], { encoding: 'utf8' });
  assert.strictEqual(r.status, 0, r.stderr);
  assert.match(r.stdout, /0 rival\(s\) reappeared/);
});
