---
name: checkup
description: 'Use when the owner types /checkup, says "checkup", "is my setup healthy", "check my skills", "list my skills", "what hooks do I have", "am I out of date", or "check for updates". A read-only pass over this setup: what exists, what is broken, what has drifted, what is out of date. Reports and stops.'
user-invocable: true
model: opus
effort: high
allowed-tools: [Bash, Read, Grep, Glob]
---

# checkup

Read-only. This command reports and stops; the owner picks what to fix.

Scope is the setup itself, not project code.

## Waves

Resolve the config path first, because every command below reads it:

```bash
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
```

Pass it to each call rather than relying on a shell that carries it. Then every section, 1
through 7, is one wave by `docs/PARALLEL.md`: none reads another's output. Section 1's
"before any judgement" orders the report, not the run.

## 1. Inventory, before any judgement

The owner has asked what is in these files more often than anything else. Lead with contents.

```bash
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
ls "$CFG"/skills/ 2>/dev/null
wc -l "$CFG"/skills/*/SKILL.md "$CFG"/docs/*.md "$CFG"/rules/*.md 2>/dev/null | tail -1
ls "$CFG"/hooks/ 2>/dev/null
```

| Column | Holds |
|---|---|
| Command | The name typed |
| Does what | One plain sentence |
| Size | Lines |

A command whose job takes more than one plain sentence has a finding of its own.

## 2. Mechanical checks

Two linters read rule files and hooks and report structural faults, and one check proves the
tools this repo names are the tools that exist. Run all three:

```bash
npx --yes agnix "$CFG" 2>&1
npx --yes @yawlabs/ctxlint "$CFG" 2>&1
bash "$CFG/hooks/external-check.sh" 2>&1
```

`agnix` takes a path. It carried a `check` subcommand here until 2026-08-21 and has never had
one, so the word was read as a second path to scan and the command looked like it worked.

Report each tool's own output. A tool that is unavailable, errors, or scans nothing reports
"did not run", followed by the reason; a clean result means it executed and found nothing. `external-check.sh`
exits 3 for exactly that case, and 3 is not a pass.

## 3. Nothing said twice

Every rule that appeared in two files has drifted eventually, in this setup and in the one
before it. Hunt for it:

```bash
grep -rn "four\|4 variants\|four variants" "$CFG"/rules "$CFG"/docs "$CFG"/skills 2>/dev/null
```

Repeat for whatever else two files might both assert. A rule found in two places is a
finding with a named fix: keep one, point the other at it.

## 4. Pointers that lead nowhere

Every path mentioned in a file, checked against the filesystem. A pointer to a file that was
deleted is worse than no pointer, because a session follows it and reports a missing target
rather than answering.

Also check the reverse: a file nobody points at is either unreachable or an orphan.

## 5. Drift against the source

For anything borrowed from outside, compare the local copy against its origin and report how
far behind it is. Vet anything newly borrowed with `skillspector` before it is installed.

Installed skills carry their source, so one command lists them and where each came from:

```bash
npx --yes skills@latest ls -g
```

**There is no read-only way to learn which of them are behind.** `skills update -g` is the only
command that answers it, and it APPLIES what it finds: `-y` skips the scope prompt, not the
update. This file said the opposite until 2026-08-24, and the checkup run that caught it had
already updated three skills while claiming to change nothing.

So this step reports what is installed and stops. Print the command, say that running it
updates rather than reports, and leave it to the owner:

```
Drift: not measured. `npx --yes skills@latest update -g` is the only check and it applies
updates, so it is yours to run.
```

An update can also relocate a skill: on 2026-08-22 `orca-cli` moved from `~/.agents/skills`
into `~/.claude/skills`, arriving untracked and unignored, where one `git add -A` would have
published it. Report any new untracked directory under `skills/` as a finding with the
`.gitignore` line that closes it.

For anything pinned to a version, ask the registry for the current stable release and report
the gap. See `CLAUDE.md` rule 5 for the read-only queries.

## 6. Prose

Read `docs/PROSE.md` and check the setup's own written files against it.

## 7. Memory

Report facts that name a file, function, or flag that no longer exists, and any two facts
that assert different things about the same subject.

## Output

One table, ordered by severity, with a plain sentence per row:

| What | State | What it means for you |
|---|---|---|

Then one line: how many checks ran, and how many could not.

## Done

This command has finished when every check has reported either a result or a reason it did
not run, and the owner has a ranked list of what to fix. Nothing has been changed.
