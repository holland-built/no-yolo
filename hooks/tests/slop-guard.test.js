// Tests for hooks/slop-guard.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
// process.exit() means this hook is driven as a child process, not require()'d.
//
// The POSITIVE CONTROL block below is the point of this file. slop-guard warns
// only when something matches, so a pattern file that silently matches NOTHING
// looks exactly like a clean session. This repo has been bitten by that before:
// verify.sh §8a documents a leak scan whose \b metacharacter matched nothing at
// all under git grep on macOS, so it reported "no findings" forever on the very
// machine doing the committing — nothing could tell "clean" from "blind". Here
// every shipped pattern must prove it can still fire, and a pattern added
// without a fixture fails the suite rather than shipping unproven.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'slop-guard.js');
const realPatternsPath = path.join(__dirname, '..', 'slop-patterns.json');

// text that SHOULD match, keyed by the tell name in slop-patterns.json
const POSITIVE_CONTROLS = {
  'Filler opener': 'Certainly! Here is the patch you asked for.',
  'Fake enthusiasm': "I'd be happy to help with that migration.",
  'Hedge stacking': "It's worth noting that the cache is cold on first boot.",
  'AI self-reference': 'As an AI language model, I cannot run that command.',
  'Epochal framing': "In today's fast-paced deployment landscape, speed matters.",
  'Sign-off CTA': 'Let me know if you need anything else.',
  'Conclusion marker': 'In summary, the parser was the problem.',
  'Sycophantic opener / agree-then-fold': "That's a great question. The answer is no.",
  'Unnecessary recap': 'As I mentioned earlier, the token expires hourly.',
  'Use-case hedging': 'The right choice depends on your specific use case.',
  'It-goes-without-saying': 'It goes without saying that the tests must pass.',
  'At-its-core opener': 'At its core, the scheduler is a priority queue.',
  'Passive-voice conclusion': 'It can be seen that latency grows with batch size.',
  'Emphasis filler': 'This is particularly important for the retry path.',
  'Framing-label opener': "Here's the thing: the retry loop never exits.",
  'Performed candor': 'Let me be direct: the migration is not finished.',
  'Pre-emptive apology': 'Apologies for the confusion in my last message.',
  'Forbidden words (pruned 2026 set)': 'Let us delve into the retry semantics.',
  'Stacked intensifiers': 'The build is really very slow on a cold cache.',
  'Unverified success claim': 'I patched the import path, so it should work now.',
  'Negation reframe': "This isn't a caching problem — it's a clock skew problem.",
  'Hype adjective': 'We shipped a cutting-edge retry layer this week.',
  'Emoji heading': '## 🚀 Deploy notes\n\nThe deploy ran at 09:00.',
  'Current AI vocabulary (density)':
    'The seamless handoff is a testament to the holistic design of the queue.',
};

// text that must NOT match anything
const CLEAN_REPLY = [
  'Fixed the retry loop in src/queue.js:412 — the exit condition compared',
  'attempt count against maxRetries before incrementing, so it ran one extra pass.',
  '',
  '- Ran `npm test`: 34 passing, 0 failing.',
  '- Did not touch the backoff timing; that path has no test coverage yet.',
  '',
  'Next: the same off-by-one shape exists in src/worker.js:88 — want me to fix it?',
].join('\n');

function makeSandbox(opts = {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'slop-guard-test-'));
  fs.mkdirSync(path.join(dir, 'hooks'), { recursive: true });
  if (opts.patterns === undefined) {
    fs.copyFileSync(realPatternsPath, path.join(dir, 'hooks', 'slop-patterns.json'));
  } else if (opts.patterns !== null) {
    fs.writeFileSync(path.join(dir, 'hooks', 'slop-patterns.json'), opts.patterns);
  } // null -> no patterns file at all
  return dir;
}

function writeTranscript(dir, text) {
  const file = path.join(dir, 'transcript.jsonl');
  const lines = [
    JSON.stringify({ type: 'user', message: { role: 'user', content: 'do the thing' } }),
    JSON.stringify({
      type: 'assistant',
      isSidechain: false,
      message: { role: 'assistant', content: [{ type: 'text', text }] },
    }),
  ];
  fs.writeFileSync(file, lines.join('\n') + '\n');
  return file;
}

function runGuard(dir, payload) {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_CONFIG_DIR: dir },
    input: payload === undefined ? '' : JSON.stringify(payload),
    encoding: 'utf8',
  });
}

function runOnText(text, opts = {}) {
  const dir = makeSandbox(opts);
  const transcript = writeTranscript(dir, text);
  return runGuard(dir, { transcript_path: transcript });
}

// --- positive controls: every shipped pattern must be able to fire ----------

const shipped = JSON.parse(fs.readFileSync(realPatternsPath, 'utf8'));

test('pattern file is a non-empty array and every entry has a positive control', () => {
  assert.ok(Array.isArray(shipped) && shipped.length > 0, 'slop-patterns.json must be a non-empty array');
  const missing = shipped.map(p => p.tell).filter(t => !(t in POSITIVE_CONTROLS));
  assert.deepStrictEqual(missing, [], 'every shipped tell needs a positive control fixture in this file');
});

test('every shipped pattern compiles and is loaded by the hook', () => {
  const { loadPatterns } = require(hookPath);
  assert.strictEqual(loadPatterns(realPatternsPath).length, shipped.length);
});

for (const entry of shipped) {
  test(`positive control fires: ${entry.tell}`, () => {
    const result = runOnText(POSITIVE_CONTROLS[entry.tell]);
    // Exit status stays 0 in every path — a Stop hook blocks via stdout JSON,
    // never via exit code, and a non-zero exit would look like a crashed hook.
    assert.strictEqual(result.status, 0, 'exit status must stay 0');
    assert.ok(
      result.stderr.includes(entry.tell),
      `expected a warning naming "${entry.tell}", got: ${JSON.stringify(result.stderr)}`
    );
    assert.strictEqual(
      JSON.parse(result.stdout || '{}').decision, 'block',
      `expected a block decision for "${entry.tell}", got: ${JSON.stringify(result.stdout)}`
    );
  });
}

// --- blocking contract: block once, then let the rewrite through ------------

test('the rewrite pass warns but does not block again', () => {
  const dir = makeSandbox();
  const transcript = writeTranscript(dir, POSITIVE_CONTROLS['Sign-off CTA']);
  const result = runGuard(dir, { transcript_path: transcript, stop_hook_active: true });
  assert.strictEqual(result.status, 0);
  assert.ok(result.stderr.includes('Sign-off CTA'), 'it must still say what it found');
  assert.strictEqual(result.stdout, '', 'a second block would loop the turn forever');
});

test('SLOP_GUARD=warn restores warn-only behaviour', () => {
  const prev = process.env.SLOP_GUARD;
  process.env.SLOP_GUARD = 'warn';
  try {
    const result = runOnText(POSITIVE_CONTROLS['Sign-off CTA']);
    assert.strictEqual(result.status, 0);
    assert.ok(result.stderr.includes('Sign-off CTA'));
    assert.strictEqual(result.stdout, '', 'warn mode must not emit a block decision');
  } finally {
    if (prev === undefined) delete process.env.SLOP_GUARD; else process.env.SLOP_GUARD = prev;
  }
});

test('a clean reply blocks nothing', () => {
  const result = runOnText('Fixed the retry loop in src/queue.js:412 — the exit condition compared');
  assert.strictEqual(result.stdout, '');
  assert.strictEqual(result.stderr, '');
});

test('warning is modest — it disclaims being a verdict', () => {
  const result = runOnText(POSITIVE_CONTROLS['Sign-off CTA']);
  assert.match(result.stderr, /not a verdict/i);
  assert.match(result.stderr, /GUI slop/);
});

// --- negative controls ------------------------------------------------------

for (const rulebook of ['ANTISLOP.md', 'GUI_SLOP.md']) {
  test(`negative control: this repo's own docs/${rulebook} trips nothing`, () => {
    const text = fs.readFileSync(path.join(__dirname, '..', '..', 'docs', rulebook), 'utf8');
    const result = runOnText(text);
    assert.strictEqual(result.status, 0);
    assert.strictEqual(result.stderr, '', 'the rulebook that names these tells must not trip them');
  });
}

test('negative control: a normal engineering reply trips nothing', () => {
  const result = runOnText(CLEAN_REPLY);
  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
});

test('negative control: a slop phrase merely quoted or in code is not flagged', () => {
  const result = runOnText(
    'The user asked me to avoid "let me know if you need anything else" and\n' +
      'the `should work now` string in the linter fixture.'
  );
  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
});

// --- failure modes: all silent, all exit 0 ---------------------------------

test('malformed patterns file -> exit 0, no output', () => {
  const result = runOnText(POSITIVE_CONTROLS['Sign-off CTA'], { patterns: '{ not json at all' });
  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
  assert.strictEqual(result.stdout, '');
});

test('patterns file that is valid JSON but the wrong shape -> exit 0, no output', () => {
  const result = runOnText(POSITIVE_CONTROLS['Sign-off CTA'], { patterns: '{"tell":"x"}' });
  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
});

test('one uncompilable regex drops itself, the rest still fire', () => {
  const patterns = JSON.stringify([
    { tell: 'Broken', pattern: '([unclosed', flags: 'i', note: 'never compiles' },
    { tell: 'Sign-off CTA', pattern: 'Let me know if you (need|have any)', flags: 'i', note: '' },
  ]);
  const result = runOnText(POSITIVE_CONTROLS['Sign-off CTA'], { patterns });
  assert.strictEqual(result.status, 0);
  assert.match(result.stderr, /Sign-off CTA/);
  assert.doesNotMatch(result.stderr, /Broken/);
});

test('missing patterns file -> exit 0, no output', () => {
  const result = runOnText(POSITIVE_CONTROLS['Sign-off CTA'], { patterns: null });
  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
});

test('missing transcript file -> exit 0, no output', () => {
  const dir = makeSandbox();
  const result = runGuard(dir, { transcript_path: path.join(dir, 'nope.jsonl') });
  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
});

test('unreadable / garbage transcript -> exit 0, no output', () => {
  const dir = makeSandbox();
  const file = path.join(dir, 'garbage.jsonl');
  fs.writeFileSync(file, 'not json\n{"half":\n\n');
  const result = runGuard(dir, { transcript_path: file });
  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
});

test('no transcript_path in payload -> exit 0, no output', () => {
  const dir = makeSandbox();
  const result = runGuard(dir, { session_id: 'abc' });
  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
});

test('empty stdin (run by hand, no args) -> exit 0, no output', () => {
  const dir = makeSandbox();
  const result = runGuard(dir);
  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
  assert.strictEqual(result.stdout, '');
});

test('transcript whose last assistant turn is tool_use only -> exit 0, no output', () => {
  const dir = makeSandbox();
  const file = path.join(dir, 'toolonly.jsonl');
  fs.writeFileSync(
    file,
    JSON.stringify({
      type: 'assistant',
      message: { role: 'assistant', content: [{ type: 'tool_use', name: 'Read', input: {} }] },
    }) + '\n'
  );
  const result = runGuard(dir, { transcript_path: file });
  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
});

test('sidechain (subagent) messages are skipped in favour of the main-thread reply', () => {
  const dir = makeSandbox();
  const file = path.join(dir, 'sidechain.jsonl');
  fs.writeFileSync(
    file,
    [
      JSON.stringify({
        type: 'assistant',
        isSidechain: false,
        message: { role: 'assistant', content: [{ type: 'text', text: CLEAN_REPLY }] },
      }),
      JSON.stringify({
        type: 'assistant',
        isSidechain: true,
        message: {
          role: 'assistant',
          content: [{ type: 'text', text: POSITIVE_CONTROLS['Sign-off CTA'] }],
        },
      }),
    ].join('\n') + '\n'
  );
  const result = runGuard(dir, { transcript_path: file });
  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
});
