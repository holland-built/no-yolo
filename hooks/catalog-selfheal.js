#!/usr/bin/env node
// catalog-selfheal — PostToolUse hook for Edit/Write/MultiEdit.
//
// Keeps the rendered skill menus honest. The catalog's five pipe-delimited
// sources (CATEGORIES/TAGLINES/TAGLINES_SHORT/WHEN_TO_USE/WHY_TO_USE) and each
// skill's SKILL.md feed regen.py, which renders RENDERED.md, RENDERED_FAST.md
// and docs/FLAGS.md. Editing a source without re-running regen leaves those
// three stale, and nothing complains until verify.sh runs — which may be days
// later, or in the middle of a release. This hook closes that window: edit a
// source, the menus regenerate on the spot.
//
// Deliberately quiet. The common case (nothing drifted) prints nothing at all;
// only an actual heal, or a failure to heal, produces a single line.
//
// Never blocks. This is a PostToolUse hook — the edit has already happened, and
// a self-heal that turns a successful edit into an error is worse than stale
// menus. Every failure path is one warning line and exit 0.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');

// 20s per python call. regen.py takes well under a second; the timeout exists so
// a wedged interpreter can never hang an edit.
const PY_TIMEOUT_MS = 20000;

// ---------------------------------------------------------------------------
// LOOP GUARD. These are regen.py's own outputs (plus the catalog lock). If one
// of them ever shows up as the edited path, stop immediately — regenerating in
// response to a generated file is how a hook re-triggers itself forever.
// ---------------------------------------------------------------------------
const GENERATED = [
  'skills/my-skills/RENDERED.md',
  'skills/my-skills/RENDERED_FAST.md',
  'docs/FLAGS.md',
  'skills/my-skills/catalog-lock.json',
];

// Sources that feed regen.py. Anything else is none of this hook's business.
const SKILL_MD = /^skills\/[^/]+\/SKILL\.md$/;
const CATALOG_SOURCE =
  /^skills\/my-skills\/(TAGLINES|TAGLINES_SHORT|WHEN_TO_USE|WHY_TO_USE|STORIES|CATEGORIES)\.md$/;

// Resolve symlinks where possible so a symlinked config dir (or /var -> /private/var
// on macOS) still compares equal. realpath throws on a path that does not exist yet.
function real(p) {
  try {
    return fs.realpathSync(p);
  } catch {
    return p;
  }
}

// Path of the edited file RELATIVE to the config dir, or null if it lives
// outside it. Outside -> this hook is inert, which is what makes it safe to wire
// globally: it must do nothing at all in every other repo on this machine.
function relToConfigDir(target) {
  const root = real(claudeDir);
  const abs = real(path.resolve(target));
  const rel = path.relative(root, abs);
  if (!rel || rel.startsWith('..') || path.isAbsolute(rel)) return null;
  return rel.replace(/\\/g, '/');
}

// Returns exit code. Never throws out of here for an expected failure.
function py(args) {
  try {
    execFileSync('python3', args, {
      cwd: claudeDir,
      timeout: PY_TIMEOUT_MS,
      encoding: 'utf8',
      stdio: ['ignore', 'ignore', 'ignore'],
    });
    return 0;
  } catch (err) {
    // Non-zero exit -> err.status. Timeout / missing python3 -> no status, and a
    // null here is treated as "failed", which is the safe reading either way.
    return typeof err.status === 'number' ? err.status : 1;
  }
}

function main() {
  let payload = {};
  try {
    const raw = fs.readFileSync(0, 'utf8');
    if (raw.trim()) payload = JSON.parse(raw);
  } catch {
    return; // no readable payload -> nothing to judge
  }

  const input = payload.tool_input || payload.toolInput;
  if (!input || typeof input !== 'object') return;

  const target = input.file_path || input.path || input.notebook_path;
  if (!target || typeof target !== 'string') return;

  const rel = relToConfigDir(target);
  if (rel === null) return; // outside ~/.claude -> inert

  if (GENERATED.includes(rel)) return; // loop guard, before anything else
  if (!SKILL_MD.test(rel) && !CATALOG_SOURCE.test(rel)) return; // not a catalog source

  if (py(['skills/my-skills/regen.py', '--check']) === 0) return; // nothing drifted — stay silent

  const name = path.basename(rel);

  py(['skills/my-skills/regen.py']);
  if (py(['skills/my-skills/regen.py', '--check']) !== 0) {
    process.stdout.write(
      `catalog self-heal FAILED after ${name} — run: python3 skills/my-skills/regen.py\n`
    );
    return;
  }

  process.stdout.write(`catalog self-heal: regenerated menus after ${name}\n`);

  // NEVER `catalog_lock.py --relock` here. The lock records that a HUMAN read and
  // approved each skill's description; auto-relocking would bless drift nobody
  // read — the rubber-stamp failure this repo's fail-closed rules exist to
  // prevent. Regenerating derived output is deterministic and safe; blessing a
  // description is a judgement call and stays with a person. So: check only, and
  // tell the human the one command to run.
  if (py(['skills/my-skills/catalog_lock.py', '--check']) !== 0) {
    process.stdout.write(
      'catalog lock is stale — run: python3 skills/my-skills/catalog_lock.py --relock\n'
    );
  }
}

try {
  main();
} catch (err) {
  // Any unexpected error: one line, exit 0. This hook must never break an edit.
  process.stdout.write(`catalog self-heal skipped (hook error: ${err && err.message})\n`);
}
process.exit(0);
