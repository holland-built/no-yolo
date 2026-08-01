#!/usr/bin/env node
// relock-guard — PreToolUse guard for Bash.
//
// Blocks `catalog_lock.py --relock` while any skills/<name>/SKILL.md is UNTRACKED
// by git.
//
// Why this exists: catalog_lock.py enumerates skills with
//   git ls-files "skills/*/SKILL.md"          (catalog_lock.py:61)
// so a brand-new skill whose SKILL.md has never been `git add`ed is INVISIBLE to
// the lock. This shipped once: the lock was blessed while a new skill's file was
// invisible to git, every check stayed green, and the skill shipped broken. The
// lock recorded "all current" for a set that silently excluded the one file that
// mattered.
//
// Scope is deliberately narrow:
// - only `catalog_lock.py` AND `--relock` together trip it.
// - `--check` (the read-only path everything uses) is never blocked.
// - modified-but-tracked SKILL.md is fine: git can see it, so the lock hashes it.
//
// Fail open: not a git repo, git missing, git errors, unreadable payload -> exit 0
// silently.
//
// Escape hatch: CLAUDE_ALLOW_RELOCK=1.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');

// `?? skills/<name>/SKILL.md` — one level deep, mirroring catalog_lock.py's glob.
const SKILL_MD = /^skills\/[^/]+\/SKILL\.md$/;

// git quotes paths containing specials: `?? "skills/a b/SKILL.md"`.
function dequote(p) {
  if (p.length >= 2 && p[0] === '"' && p[p.length - 1] === '"') {
    return p.slice(1, -1).replace(/\\(.)/g, '$1');
  }
  return p;
}

function untrackedSkillMds() {
  let out;
  try {
    // -uall lists individual files. Without it git collapses a brand-new skill
    // directory to `?? skills/<name>/` and the SKILL.md never appears — which is
    // the exact blind spot this guard is here to close.
    out = execFileSync('git', ['-C', claudeDir, 'status', '--porcelain', '-uall'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    });
  } catch {
    return null; // no git / not a repo / git errored -> fail open
  }

  const hits = [];
  for (const line of out.split('\n')) {
    if (!line.startsWith('?? ')) continue; // untracked ONLY; ' M' etc. is fine
    const p = dequote(line.slice(3).trim());
    if (SKILL_MD.test(p)) hits.push(p);
  }
  return hits;
}

function main() {
  if (process.env.CLAUDE_ALLOW_RELOCK === '1') return 0;

  let payload = {};
  try {
    const raw = fs.readFileSync(0, 'utf8');
    if (raw.trim()) payload = JSON.parse(raw);
  } catch {
    return 0;
  }

  const input = payload.tool_input || payload.toolInput;
  if (!input || typeof input !== 'object') return 0;

  const cmd = input.command;
  if (typeof cmd !== 'string') return 0;
  if (!cmd.includes('catalog_lock.py') || !cmd.includes('--relock')) return 0;

  const untracked = untrackedSkillMds();
  if (untracked === null || untracked.length === 0) return 0;

  process.stderr.write(
    'RELOCK BLOCKED — a SKILL.md is untracked by git:\n' +
      untracked.map((p) => `  ?? ${p}`).join('\n') +
      '\n' +
      'catalog_lock.py finds skills with `git ls-files "skills/*/SKILL.md"`, so an untracked\n' +
      'SKILL.md is invisible to it. Relocking now would bless a lock that silently omits the\n' +
      'file above — the checks go green and the skill ships broken. This has happened before.\n' +
      'Fix: git add the path(s) above first, then re-run the relock.\n' +
      'Override (you are sure the file should stay untracked): CLAUDE_ALLOW_RELOCK=1.'
  );
  return 2;
}

let code = 0;
try {
  code = main();
} catch {
  code = 0; // fail open, always
}
process.exit(code);
