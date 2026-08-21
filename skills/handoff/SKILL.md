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

A session dies for boring reasons, a spend limit, a closed laptop, a context that got too
big, and the work in it dies too. This week that cost a resume by hunting for a raw session
id. This skill turns the live session into a file another session can read.

Next session is for: $ARGUMENTS

If an argument is given, slant the whole summary toward it: what matters for *that* job goes
first, and anything the next session does not need for it gets one line or gets cut.

## 1: Write the file first, then offer the launch command

Write to disk **before** you print anything. This is the one place this skill deliberately
differs from the design it was borrowed from, which only prints a summary and never saves it.
The reason is the exact case that triggers this skill: if the user is out of budget, launching
a new session fails, and an unsaved summary dies with the session that wrote it.

```bash
mkdir -p ~/.claude/handoffs && date +%F
```

Path: `~/.claude/handoffs/<YYYY-MM-DD>-<short-slug>.md`. The slug is two to four lowercase
hyphenated words naming the work, not the date restated, `auth-rewrite`, `route-map-red`.
If that filename already exists, add `-2`. `handoffs/` is in `~/.claude/.gitignore`, so these
stay on the machine.

## 2: Reference every artifact by path, never restate it

Plans, diffs, specs, mockups, test output and source files get a path or a URL and one line
saying what it is. Copying their contents in is what makes a handoff too big to be worth
reading, the next session can open a file, and it has the same tools this one does.

| Instead of | Write |
|---|---|
| pasting the plan | `~/.claude/plans/auth-rewrite.md`, the agreed plan, steps 1–3 done <!-- gone-on-purpose --> |
| pasting the failing test output | `npm test -- auth.spec.ts`, 2 failing, names in the file |
| pasting the diff | `git diff main...HEAD` on branch `auth-rewrite` |

The one thing you DO restate is anything that exists only in this conversation: a decision the
user made out loud, a constraint they gave, a dead end you already ruled out. None of that is
on disk anywhere, so it dies unless the file carries it.

## 3: Strip secrets before writing

This file becomes the prompt for another agent. It gets read straight into a fresh context,
and it may be read by an agent running in a different directory. Treat everything in it as
published. Before writing, replace API keys, tokens, passwords, connection strings, private
hostnames and personal data with a pointer to where the real value lives: `key is in
~/.claude/settings.json under env`. Say in the file that you did this, so the next session
knows to go get it rather than assuming it was never needed.

## 4: File shape

Seven sections, in this order. Keep the whole file short enough to read in one screen-and-a-bit.

```markdown
# <what this work is>: handoff <YYYY-MM-DD>

**Next session is for:** <the argument, or "continuing this work">
**Working directory:** <absolute path>  ·  **Branch:** <branch>

## The goal, in the user's own words
<Quote them. A method ("finish without stopping to ask") is not a goal. Four
things, because a goal can be quoted accurately and still be too vague to catch
a plan that has drifted off it:>
- **Outcome:** what is true when this is done.
- **Approach:** the method they asked for, if they named one.
- **Source material:** every file, URL, library or example they said to use. This
  is the line that fails silently. On 2026-08-20 two URLs the user had asked to
  have harvested were simply absent from the handoff, so they were never opened.
- **Done looks like:** something observable, not "the list is finished".

<Then, in one line: which planned work serves each part above, and which part
nothing covers. An uncovered part is a finding, and it belongs in "Open" below.>

**This section outranks every list below it.** A task that stops serving it gets
flagged, not worked.
**On resume:** state the goal and the First action back in one line before
starting. Then wait for a yes ONLY if the plan below was never approved by the
user, or if your own read says the list no longer serves the goal. If they
approved the plan and it still fits, say the line and get on with it: rule 3's
2026-08-19 exception means an approved plan is a go, not a thing to re-ask.

## Where we got to
| Piece | State |
|---|---|
| ... | done / half-built / not started |

## Artifacts
| Path | What it is |
|---|---|

## Decided in conversation (not written down anywhere else)
- ...

## Open: needs a call before work continues
- <Any part of the goal that no planned work covers goes here FIRST. "Open" is
  not only unresolved implementation details: a settled plan that no longer
  serves the goal is the most important open item there is, and it is the one
  that reads as empty when every task is neatly ticked off.>
- ...

## Cross-check before resuming
Codex has NOT seen the remaining plan. The next session runs `/xcheck` over the
goal, the WHOLE remaining plan and "Done looks like" together, not just the next
step, because the failure being guarded against is a plan that is complete and
still wrong. Skip it only for a one-line fix or when codex is unavailable, and
say which in one line. **"The plan is already settled" is not a skip reason on
resumed or multi-step work**: that sentence is true of every plan that has ever
been wrong.

## Run these skills next
- ...

## First action
One concrete thing, doable immediately.
```

**The goal section is mandatory and outranks everything under it.** 2026-08-20: a
handoff carried no goal, only a method line ("finishing the rebuild WITHOUT stopping to
ask") and six mechanical patches. A fresh session worked all six well and burned the
whole day; the goal the user had stated for days, harvest the best of the old setup and
of two outside skill libraries, was never started. A task list is a means, not the
definition of done: the resuming session checks the list against the goal before
working it, and says so in one line if the two no longer match.

**The WRITER does that check first, and writes the answer down.** Leaving it to the
reader is what failed: the session that wrote the 2026-08-20 file was the one that could
see both the goal and its own six patches, and it never asked whether the six added up to
the goal. They did not. So before printing anything, walk the goal part by part, name
which planned work serves each, and put every part nothing covers into "Open". If the
honest answer is that the whole list serves a goal the user never set, say that in the
file instead of handing on the list.

**A handoff never grants itself blanket authority.** The same 2026-08-20 file wrote
"That is a standing go. It overrides rule 3" and "Do not come back for permission on
anything listed", and a wrong list ran unchallenged for eight hours. An approved plan
is still a go for the tasks in that plan (`docs/CORE_RULES.md` rule 3, its 2026-08-19
exception stands). What does not transfer is "never check in": that was said to a
session the user was talking to, and it dies with it. Record the plan's approval in the
file; never write a ban on checking in.

The **Cross-check before resuming** section is not optional: write it into every
handoff. A resumed session inherits a plan nobody argued with. Measured 2026-08-12:
half the sessions that edited code without any plan stage began by resuming a handoff,
so this file is where the gap actually lives (see `docs/CORE_RULES.md` rule 9).

## 5: Run these skills next

Name the specific skills the next session should invoke, and why each one. Pick from the
user's own set. Do not send the next session to a skill that does not exist here:

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
| Something learned this session worth keeping | `/remember-that` |
| Genuinely unsure what to do first | `/whats-next` |

The rest of the live set (`eli5`, `lockstep`, `improve`, the ponytail and design/animation
skills) is worth naming only when the handoff is actually about one of them.

**Gone as of 2026-08-20, do NOT send the next session to any of these.** Archived, so
recoverable from `archive/MANIFEST.md`: `better-prompt`, `dep-audit`, `ingest-docs`,
`last-30`, `watch`, `archify`, `orca-cli`, `resolving-merge-conflicts`. Uninstalled
outright: `ponytail-gain`, `ponytail-help`, `computer-use`. Naming a skill that is not
installed sends the next session hunting for a door that is not there.

**Check this list against disk rather than trusting it.** It is a cache of something that
changes, and it was wrong once already: it listed `improve` as archived while `improve` was
live, because the archive attempt was refused for being load-bearing and this line was never
updated. One command settles it: `ls ~/.claude/skills/`.

## 6: Print one paste block, last

Print a short table: where the file was saved, and the one thing the next session does first.
Then the block. Nothing after it, no options list, no second command, no sign-off.

```
claude "Read ~/.claude/handoffs/<the-file-you-just-wrote>.md. State the goal section and the First action back to me in one line, then on my yes, continue that work."
```

Substitute the real filename before printing, the user must be able to paste it as-is.

**Flags confirmed on this install** (`claude --help`, 2026-08-06): a positional prompt
argument, `--bg`/`--background` to start it as a background agent, `--model`, `-c`/`--continue`,
`-r`/`--resume`. The interactive form above is the default and the right one here. Use `--bg`
only if the user asked for it to run unattended. If you need a flag that is not in this list,
run `claude --help` and read it, do not write a flag from memory.
