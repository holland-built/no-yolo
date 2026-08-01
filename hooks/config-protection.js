#!/usr/bin/env node
// config-protection — PreToolUse guard for Edit/Write/MultiEdit.
//
// Purpose: stop the "agent turns the rule off instead of fixing the code"
// failure mode. When a lint/format/type check fails, the cheapest way to make
// it green is to edit the config that defines the check. This hook makes that
// mechanically impossible without the user's knowledge.
//
// The distinction that matters:
//   - CREATING one of these files for the first time is ALLOWED. A project with
//     no formatter config is not being weakened by gaining one.
//   - MODIFYING an existing one is BLOCKED. That is the only shape the failure
//     mode takes.
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
} catch {
  code = 0; // never throw; a crashing guard is worse than no guard
}
process.exit(code);
