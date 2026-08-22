#!/usr/bin/env node
// Blocks edits to an EXISTING lint / format / type-check config.
// PreToolUse hook on Edit|Write|MultiEdit, run through node-shim.sh.
//
// Rewritten from a blank page 2026-08-22 (machinery rebuild). The contract is
// hooks/tests/config-protection.test.js: which names block, which names
// deliberately do not, and which malformed inputs must pass silently.
//
// THE FAILURE MODE THIS EXISTS FOR. When a check fails, the cheapest green is
// to edit the config that defines the check. So:
//   - creating a config that does not exist yet is ALLOWED — a project gaining
//     a formatter is not being weakened;
//   - modifying one that exists is BLOCKED, with the two legitimate ways
//     forward spelled out in the message.
//
// WHAT IT IS NOT. This sees Edit/Write/MultiEdit and nothing else. A Bash
// `sed -i` on the same file walks straight past it, demonstrated and accepted:
// it is a loud habit correction, not an enforcement boundary. Also accepted:
//   - a NEW nested config can still weaken an inherited one (tsconfig with
//     "strict": false) — allowed anyway, because blocking creation fires on
//     ordinary work far more often than on the failure mode;
//   - checker settings living inside dual-purpose files (pyproject.toml,
//     setup.cfg, package.json's eslintConfig key) are not covered, because
//     ordinary work edits those files constantly and a guard that cries wolf
//     gets its escape hatch exported permanently;
//   - CLAUDE_ALLOW_CONFIG_EDIT=1 opens the gate for the whole process tree
//     that inherits it, not for one file. An escape hatch, not an approval.
//
// FAIL OPEN, SILENTLY, ON ANYTHING UNREADABLE. A guard that crashes the
// session is worse than the thing it guards, and the tests pin stderr EMPTY on
// every ordinary allow path. The one loud case is an unexpected exception
// escaping the guard itself, which reports that it failed open — otherwise
// "the guard broke" and "the guard passed you" look identical from outside.

const fs = require('fs');
const path = require('path');

// Basenames that ARE the check. `*` is a wildcard; matching is whole-name and
// case-insensitive. Add or remove entries here; nothing else needs to change.
const GUARDED = [
  '.eslintrc*',
  'eslint.config.*',
  'prettier.config.*',
  '.prettierrc*',
  'biome.json',
  'biome.jsonc',
  '.ruff.toml',
  'ruff.toml',
  'tsconfig*.json',
  '.flake8',
];
// Considered and left out: pyproject.toml, setup.cfg, .editorconfig. The tests
// assert these stay unguarded, so putting one back forces the argument.

const MATCHERS = GUARDED.map((entry) => {
  const escaped = entry
    .split('*')
    .map((part) => part.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
    .join('.*');
  return new RegExp(`^${escaped}$`, 'i');
});

function guard() {
  if (process.env.CLAUDE_ALLOW_CONFIG_EDIT === '1') return 0;

  let payload;
  try {
    payload = JSON.parse(fs.readFileSync(0, 'utf8'));
  } catch {
    return 0; // nothing readable arrived: nothing to judge
  }
  if (!payload || typeof payload !== 'object') return 0;

  const input = payload.tool_input || payload.toolInput;
  if (!input || typeof input !== 'object') return 0;
  const named = input.file_path || input.notebook_path || input.path;
  if (typeof named !== 'string' || !named.trim()) return 0;

  const target = payload.cwd ? path.resolve(payload.cwd, named) : path.resolve(named);

  if (!MATCHERS.some((m) => m.test(path.basename(target)))) return 0;
  if (!fs.existsSync(target)) return 0; // first-time creation is allowed

  process.stderr.write(
    `CONFIG PROTECTION — blocked an edit to an existing checker config.\n` +
      `  file: ${target}\n` +
      `This file defines a lint / format / type check. Editing it to make a failing check pass ` +
      `turns the check off instead of fixing the code, and the next person inherits both problems.\n` +
      `Two legitimate ways forward:\n` +
      `  1. Fix the code so the existing rule passes. This is almost always the right one.\n` +
      `  2. If the rule itself is genuinely wrong, tell the user WHICH rule, WHY it should change, ` +
      `and what the code would look like under it — then let them decide. Do not decide for them.\n` +
      `Do not retry this tool call. If the user agrees the config must change, they can re-run with ` +
      `CLAUDE_ALLOW_CONFIG_EDIT=1 set, which disables this guard.`
  );
  return 2;
}

let exitCode = 0;
try {
  exitCode = guard();
} catch (err) {
  exitCode = 0; // fail open, but never silently
  try {
    process.stderr.write(
      `config-protection: guard errored and allowed the edit through — ${err && err.message}\n`
    );
  } catch {
    /* stderr is gone too; nowhere left to say it */
  }
}
process.exit(exitCode);
