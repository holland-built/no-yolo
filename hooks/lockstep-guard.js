#!/usr/bin/env node
// lockstep — PreToolUse guard for Edit/Write/NotebookEdit AND Bash.
//
// Blocks file mutation while ~/.claude/.lockstep-active exists, and blocks the
// destructive Bash commands named in skills/lockstep/SKILL.md ("Destructive Bash
// is inside the hold"). An edit you can undo is blocked, so a delete you can't
// must be. Toggle with the /lockstep skill.
//
// Fail CLOSED — the opposite of config-protection.js, deliberately. Lockstep is
// a user-issued stop order, not a habit correction. If the flag is present and
// this hook cannot tell what it is looking at (no payload, unparseable payload,
// unknown tool), it DENIES. A stop order that goes quiet the day the payload
// shape changes is the verify.sh §8a failure: "clean" indistinguishable from
// "blind". It still never throws — every path ends in an explicit exit code.
//
// Flag ABSENT -> exit 0 immediately, always. This is a hold, not a permanent
// destructive-command guard; when the user releases it, `rm -rf` is their call.

const fs = require('fs');
const path = require('path');
const os = require('os');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const flagPath = path.join(claudeDir, '.lockstep-active');

const EDIT_BLOCK_MESSAGE =
  'LOCKSTEP ACTIVE — file edits are blocked until the user agrees. ' +
  'Do not retry this tool call. Summarize what you were about to change and why, ' +
  'then wait for the user to say "go" / "agreed" or run /lockstep off before editing anything.';

// A command name counts as starting a command if it begins the segment or follows
// whitespace, a separator, or a QUOTE. Quotes count on purpose: `sh -c "rm -rf /"`
// is a real delete, so a quoted `rm -rf` is treated as one. The cost is a false
// positive on `echo "rm -rf"` / `grep "rm -rf" src`, which costs the user one
// sentence; the false negative costs a filesystem. No shell parsing is attempted —
// quote-stripping is exactly how a guard like this grows a bypass.
const START = "(?:^|[\\s;&|('\"\\x60])";
const at = (body, flags) => new RegExp(START + body, flags);

// Word boundaries and \b are safe HERE (JS RegExp, one engine, both platforms).
// The verify.sh §8a "no \b" rule is about `git grep` on BSD/macOS, not this file.
//
// NOT detected, deliberately: truncating redirects (`> file` onto an existing
// tracked path). Telling `> out.log` (fine) from `> src/index.ts` (data loss)
// needs the shell's own redirection parsing plus repo state, and a half-right
// guess here would either block ordinary work or give false confidence. It stays
// a model-enforced line in SKILL.md. Same for a bare `rm file` with no flags.
const DESTRUCTIVE = [
  {
    label: 'rm with -r / -f (recursive or forced delete)',
    // `rm` plus any flag token containing r, R or f — covers -rf, -fr, -Rf,
    // -r -f, --recursive, --force, and trailing flags (`rm dir -rf`).
    re: at(String.raw`rm\s+(?:[^\n]*\s)?-{1,2}[A-Za-z-]*[rRf]`),
    // `/lockstep off` IS `rm -f .../.lockstep-active`. Blocking the release
    // command would make the hold impossible to lift from inside a session —
    // the one deadlock this guard must never create. Scoped to the segment, so
    // `rm -rf / ; rm -f ~/.claude/.lockstep-active` still dies on segment one.
    exempt: /\.lockstep-active/,
  },
  {
    label: 'git push --force / -f / +refspec (overwrites remote history)',
    // --force also covers --force-with-lease and --force-if-includes.
    re: at(String.raw`git\s+push\b.*?(?:--force|(?:^|\s)-[A-Za-z]*f(?:\s|$)|\s\+[^\s:]+:)`),
  },
  {
    label: 'git reset --hard (discards working-tree and index changes)',
    re: at(String.raw`git\s+reset\b.*--hard\b`),
  },
  {
    label: 'git clean -f (deletes untracked files)',
    // `git clean -n` / `--dry-run` carry no `f` flag and pass — they are the
    // blast-radius check SKILL.md asks for before proposing the real thing.
    re: at(String.raw`git\s+clean\b.*(?:(?:^|\s)-[A-Za-z]*f|--force)`),
  },
  {
    label: 'git checkout -- / git checkout . (discards working-tree changes)',
    // Plain `git checkout <branch>` and `-b` pass: git refuses to lose changes.
    re: at(String.raw`git\s+checkout\s+(?:.*\s)?(?:--(?:\s|$)|\.(?:\s|$))`),
  },
  {
    label: 'git restore (discards working-tree changes)',
    re: at(String.raw`git\s+restore\b`),
    // `git restore --staged` only unstages; the file keeps its contents.
    exempt: /--staged(?![\s\S]*--worktree)/,
  },
  {
    label: 'git filter-repo / filter-branch (rewrites history irreversibly)',
    re: at(String.raw`git\s+filter-(?:repo|branch)\b`),
  },
  {
    label: 'git branch -D (force-deletes a possibly unmerged branch)',
    // Case-sensitive on purpose: -d refuses to drop unmerged work, -D does not.
    re: at(String.raw`git\s+branch\b.*(?:(?:^|\s)-[A-Za-z]*D|--delete\s+--force|--force\s+--delete)`),
  },
  {
    label: 'dd (raw overwrite of a device or file)',
    re: at(String.raw`(?:sudo\s+)?dd\s+.*\b(?:if|of)=`),
  },
  {
    label: 'mkfs (formats a filesystem)',
    re: at(String.raw`(?:sudo\s+)?mkfs(?:\.[A-Za-z0-9]+)?\b`),
  },
  {
    label: 'DROP TABLE / DATABASE / SCHEMA',
    re: /\bdrop\s+(?:table|database|schema)\b/i,
  },
  {
    label: 'TRUNCATE (SQL table or coreutils file truncation)',
    re: /\btruncate\s+(?:table\b|-s\b|[\w".\x60]+\s*;)/i,
  },
];

// Chained commands count. Split so `foo && rm -rf bar`, `foo; rm -rf bar`,
// `foo | rm ...` and `$(rm -rf bar)` are each judged as their own command, and
// so a per-segment exemption cannot launder the rest of the line.
function segments(command) {
  return command
    .split(/&&|\|\||\$\(|[;&|\n()\x60]/)
    .map((s) => s.trim())
    .filter(Boolean);
}

function destructiveMatch(command) {
  for (const segment of segments(command)) {
    for (const rule of DESTRUCTIVE) {
      if (rule.exempt && rule.exempt.test(segment)) continue;
      if (rule.re.test(segment)) return { label: rule.label, segment };
    }
  }
  return null;
}

function readPayload() {
  try {
    const raw = fs.readFileSync(0, 'utf8');
    if (!raw.trim()) return null;
    const parsed = JSON.parse(raw);
    return parsed && typeof parsed === 'object' ? parsed : null;
  } catch {
    return null;
  }
}

function main() {
  let held;
  try {
    held = fs.existsSync(flagPath);
  } catch {
    held = true; // can't read the flag -> assume the stop order stands
  }
  if (!held) return 0;

  const payload = readPayload();
  const toolName = payload && (payload.tool_name || payload.toolName);
  const toolInput = (payload && (payload.tool_input || payload.toolInput)) || null;

  if (toolName !== 'Bash') {
    // Edit / Write / NotebookEdit, and anything unrecognized: deny (fail closed).
    process.stderr.write(EDIT_BLOCK_MESSAGE);
    return 2;
  }

  const command = toolInput && typeof toolInput.command === 'string' ? toolInput.command : null;
  if (command === null) {
    process.stderr.write(EDIT_BLOCK_MESSAGE); // a Bash call we cannot read is not a safe one
    return 2;
  }

  const hit = destructiveMatch(command);
  if (!hit) return 0; // reads, builds, tests, git status — the mode has to stay usable

  process.stderr.write(
    'LOCKSTEP ACTIVE — blocked a destructive command.\n' +
      `  matched: ${hit.label}\n` +
      `  command: ${hit.segment.slice(0, 300)}\n` +
      'An edit you can undo is already blocked, so a delete you cannot must be. ' +
      'Lockstep is holding. It lifts only when the user says "go" / "agreed" or runs /lockstep off. ' +
      'Do not retry this tool call, and do not reach for a different command with the same effect. ' +
      'State what you were about to run, its blast radius from a real dry run ' +
      '(git clean -n, git diff --stat, ls), and whether it can be rolled back — then wait.'
  );
  return 2;
}

let code = 2; // if anything below throws, the stop order wins
try {
  code = main();
} catch {
  code = 2;
}
process.exit(code);
