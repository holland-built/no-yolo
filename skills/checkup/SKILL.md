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
"did not run, <reason>"; a clean result means it executed and found nothing. `external-check.sh`
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
