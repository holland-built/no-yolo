#!/usr/bin/env node
// config-protection — PreToolUse guard for Edit/Write/MultiEdit.
//
// Purpose: stop the "agent turns the rule off instead of fixing the code"
// failure mode. When a lint/format/type check fails, the cheapest way to make
// it green is to edit the config that defines the check.
//
// The distinction that matters:
//   - CREATING one of these files for the first time is ALLOWED. A project with
//     no formatter config is not being weakened by gaining one.
//   - MODIFYING an existing one is BLOCKED. That is the shape the failure mode
//     usually takes.
//
// WHAT THIS DOES NOT COVER, and the header claimed otherwise until 2026-08-20.
// It said this hook makes the failure "mechanically impossible". It does not.
// It is a PreToolUse hook on Edit/Write/MultiEdit and nothing else, so any
// Bash command that writes the same file walks straight past it. Demonstrated,
// not assumed: with the guard active, `sed -i '' 's/error/off/' .eslintrc.json`
// turned a rule off with no block and no message. Three further limits, raised
// by a cross-model review the same day and accepted:
//   1. Bash writes are unguarded (above). sed, mv, cp, tee, a heredoc, a
//      redirect, or a formatter's own --write all bypass it.
//   2. Creation is allowed, and a NEW config can still weaken an inherited one
//      — a nested tsconfig.json with "strict": false is the clean example. So
//      allowing creation is a deliberate false negative, accepted because
//      blocking it fires on ordinary work far more often than on the failure
//      mode (see the note below on guards that cry wolf). It is not a case
//      where nothing can go wrong.
//   3. Checker settings living inside dual-purpose files are not covered:
//      package.json (eslintConfig, prettier), pyproject.toml, setup.cfg,
//      deno.json. See the deliberately-not-guarded note below.
//   4. CLAUDE_ALLOW_CONFIG_EDIT=1 is inherited by every later call in the same
//      process, so it opens the gate for the rest of the session, not for one
//      file. It is an escape hatch, not a scoped approval.
// Treat this as a habit correction that catches the common case loudly, not as
// an enforcement boundary. Anything that must actually be enforced needs a
// mechanism that sees Bash.
//
// Escape hatch: CLAUDE_ALLOW_CONFIG_EDIT=1 passes silently. It is named in the
// block message so a stuck agent can tell the user how to unblock it.
//
// Fail-open by design: any unexpected error exits 0. A guard that crashes the
// session is worse than the thing it guards against. Contrast lockstep-guard,
// which fails CLOSED — lockstep is a user-issued stop order, this is a habit
// correction, and a false block on a legitimate first-time config write costs
// more than a missed one.

const fs = require('fs');
const path = require('path');

// Guarded config basenames. Case-insensitive. `*` matches any suffix.
// Edit THIS array to add or remove a guarded config — nothing else in the file
// needs to change.
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
// Deliberately NOT guarded: pyproject.toml, setup.cfg, .editorconfig. Each is
// dual-purpose — pyproject.toml and setup.cfg carry dependencies and packaging
// metadata that legitimate work edits constantly, and .editorconfig is
// whitespace, not a check anyone cheats. Guarding them would fire on ordinary
// edits far more often than on the failure mode, and a guard that cries wolf
// gets the escape hatch exported permanently, which is worse than no guard.
// If a project keeps its ruff/flake8 rules in pyproject.toml and you want that
// covered, add it back here — the trade is yours to make, not the default.

// A guarded entry is a literal basename with optional `*` wildcards. Build a
// full-string, case-insensitive matcher — no path separators, basename only.
function toMatcher(pattern) {
  const rx = pattern
    .split('*')
    .map((chunk) => chunk.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
    .join('.*');
  return new RegExp(`^${rx}$`, 'i');
}

const MATCHERS = GUARDED.map(toMatcher);

function isGuarded(basename) {
  return MATCHERS.some((m) => m.test(basename));
}

function targetPath(input) {
  if (!input || typeof input !== 'object') return null;
  const p = input.file_path || input.notebook_path || input.path;
  return typeof p === 'string' && p.trim() ? p : null;
}

function main() {
  if (process.env.CLAUDE_ALLOW_CONFIG_EDIT === '1') return 0;

  let payload = {};
  try {
    const raw = fs.readFileSync(0, 'utf8');
    if (raw.trim()) payload = JSON.parse(raw);
  } catch {
    return 0; // no readable payload -> nothing to judge -> allow
  }
  if (!payload || typeof payload !== 'object') return 0;

  let target = targetPath(payload.tool_input || payload.toolInput);
  if (!target) return 0; // can't see a target -> allow (fail open)

  target = payload.cwd ? path.resolve(payload.cwd, target) : path.resolve(target);
  const base = path.basename(target);

  if (!isGuarded(base)) return 0;

  // First-time creation is allowed. Only an EXISTING file can be weakened.
  if (!fs.existsSync(target)) return 0;

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

let code = 0;
try {
  code = main();
} catch (err) {
  // Never throw; a crashing guard is worse than no guard. But say so on the way
  // past. Until 2026-08-20 this swallowed the error and exited 0 in silence,
  // which made "the guard broke" and "the guard passed you" look identical from
  // outside. The exit code stays 0 — this is a notice, not a block.
  //
  // Scope: this covers errors escaping main() only. Unreadable or unparseable
  // stdin is handled by its own catch above and stays silent on purpose, since
  // an empty payload is a normal thing for a hook to be handed and a notice on
  // every one of those would be noise, not signal.
  code = 0;
  try {
    process.stderr.write(
      `config-protection: guard errored and allowed the edit through — ${err && err.message}\n`
    );
  } catch {
    /* stderr itself is gone; there is nowhere left to report to */
  }
}
process.exit(code);
