---
name: handoff
description: Use this skill when the user types /handoff, says 'hand this off', 'save where we are', "I'm about to run out", 'pick this up later', 'write a handoff', or 'I'm hitting the limit'. Saves a dying session to a file on disk so a fresh session can carry on from it, then prints one copy-paste command to start that session.
user-invocable: true
argument-hint: "[what the next session is for] (omit to summarize everything)"
allowed-tools:
  - Bash
  - Read
  - Write
---

# handoff

A session dies for boring reasons — a spend limit, a closed laptop, a context that got too
big — and the work in it dies too. This week that cost a resume by hunting for a raw session
id. This skill turns the live session into a file another session can read.

Next session is for: $ARGUMENTS

If an argument is given, slant the whole summary toward it: what matters for *that* job goes
first, and anything the next session does not need for it gets one line or gets cut.

## 1 — Write the file first, then offer the launch command

Write to disk **before** you print anything. This is the one place this skill deliberately
differs from the design it was borrowed from, which only prints a summary and never saves it.
The reason is the exact case that triggers this skill: if the user is out of budget, launching
a new session fails, and an unsaved summary dies with the session that wrote it.

```bash
mkdir -p ~/.claude/handoffs && date +%F
```

Path: `~/.claude/handoffs/<YYYY-MM-DD>-<short-slug>.md`. The slug is two to four lowercase
hyphenated words naming the work, not the date restated — `auth-rewrite`, `route-map-red`.
If that filename already exists, add `-2`. `handoffs/` is in `~/.claude/.gitignore`, so these
stay on the machine.

## 2 — Reference every artifact by path, never restate it

Plans, diffs, specs, mockups, test output and source files get a path or a URL and one line
saying what it is. Copying their contents in is what makes a handoff too big to be worth
reading — the next session can open a file, and it has the same tools this one does.

| Instead of | Write |
|---|---|
| pasting the plan | `~/.claude/plans/auth-rewrite.md` — the agreed plan, steps 1–3 done <!-- gone-on-purpose --> |
| pasting the failing test output | `npm test -- auth.spec.ts` — 2 failing, names in the file |
| pasting the diff | `git diff main...HEAD` on branch `auth-rewrite` |

The one thing you DO restate is anything that exists only in this conversation: a decision the
user made out loud, a constraint they gave, a dead end you already ruled out. None of that is
on disk anywhere, so it dies unless the file carries it.

## 3 — Strip secrets before writing

This file becomes the prompt for another agent — it gets read straight into a fresh context,
and it may be read by an agent running in a different directory. Treat everything in it as
published. Before writing, replace API keys, tokens, passwords, connection strings, private
hostnames and personal data with a pointer to where the real value lives: `key is in
~/.claude/settings.json under env`. Say in the file that you did this, so the next session
knows to go get it rather than assuming it was never needed.

## 4 — File shape

Six sections, in this order. Keep the whole file short enough to read in one screen-and-a-bit.

```markdown
# <what this work is> — handoff <YYYY-MM-DD>

**Next session is for:** <the argument, or "continuing this work">
**Working directory:** <absolute path>  ·  **Branch:** <branch>

## Where we got to
| Piece | State |
|---|---|
| ... | done / half-built / not started |

## Artifacts
| Path | What it is |
|---|---|

## Decided in conversation (not written down anywhere else)
- ...

## Open — needs a call before work continues
- ...

## Run these skills next
- ...

## First action
One concrete thing, doable immediately.
```

## 5 — Run these skills next

Name the specific skills the next session should invoke, and why each one. Pick from the
user's own set — do not send the next session to a skill that does not exist here:

| Situation the file describes | Name this skill |
|---|---|
| Work half-built, plan already agreed | `/build` |
| Nothing planned yet, or the shape is still fuzzy | `/build --plan-only`, then `/debate` if the call is contested |
| A diff waiting for review, or something broken | `/health` |
| A decision that needs a second model | `/xcheck` |
| UI to design, audit or port | `/design` |
| Next.js pages to prove actually render | `/route-map` |
| Ready to publish | `/release` |
| Setup itself feels off, or skills are drifting | `/checkup` |
| Packages or licences to check | `/dep-audit` |
| Something learned this session worth keeping | `/remember-that` |
| Genuinely unsure what to do first | `/whats-next` |

The rest of the set — `better-prompt`, `eli5`, `ingest-docs`, `last-30`, `lockstep`, `watch` —
are worth naming only when the handoff is actually about one of them.

## 6 — Print one paste block, last

Print a short table: where the file was saved, and the one thing the next session does first.
Then the block. Nothing after it — no options list, no second command, no sign-off.

```
claude "Read ~/.claude/handoffs/<the-file-you-just-wrote>.md and continue that work. Start with the First action section."
```

Substitute the real filename before printing — the user must be able to paste it as-is.

**Flags confirmed on this install** (`claude --help`, 2026-08-06): a positional prompt
argument, `--bg`/`--background` to start it as a background agent, `--model`, `-c`/`--continue`,
`-r`/`--resume`. The interactive form above is the default and the right one here. Use `--bg`
only if the user asked for it to run unattended. If you need a flag that is not in this list,
run `claude --help` and read it — do not write a flag from memory.
