---
name: release
description: Use when the owner types /release, says "release", "push this", "commit and push", "ship it", or "get this to github". Reads the repo's own SHIP.md playbook and runs it. Without a SHIP.md it stops and builds one with the owner before anything is committed.
user-invocable: true
model: opus
effort: high
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob]
---

# release

Every repo publishes differently. This command reads the repo's own instructions rather than
carrying a universal recipe that is wrong somewhere.

## 1. Find the playbook

```bash
ls SHIP.md 2>/dev/null
```

Present: read it and follow it exactly. Its steps outrank everything below.

Absent: go to section 5, which builds one. Publishing resumes at section 1 once that file
exists and the owner has approved it.

## 2. Check what is going out

```bash
git status --short
git diff --stat
git log origin/HEAD..HEAD --oneline 2>/dev/null
```

Read the diff itself, not just the file names. Publishing sends this to a place other people
can see, and it survives deletion through caches and forks.

## 3. Secrets

Run the repo's secret check over the diff before anything is staged.

| Result | The release |
|---|---|
| Clean, and the scanner ran | Continues |
| A finding | Stays closed until the owner has seen the finding and removed the credential |
| The scanner could not run | Stays closed, and the reason is reported |

An unrun scan and a clean scan look identical from the outside, and the cost of guessing
wrong is a published credential. This gate keeps its own policy, separate from the Codex
second opinion in `rules/codex.md`.

## 4. Run the playbook

Follow `SHIP.md` step by step. Report each step's real result.

The commit message carries the reasoning: the root cause, what was rejected, and the
before-and-after numbers. `git blame` finds it there.

The owner has a standing instruction that "push to `<branch>`" means commit everything local
first, generate the message, and push, without asking. Take it.

Release notes name plainly any number that will visibly jump, and why.

## 5. No SHIP.md: build one first

The working tree stays as it is while this runs. Interview the owner one question at a time,
and write their answers into `SHIP.md` at the repo root:

| Ask | Goes into SHIP.md as |
|---|---|
| Where does this publish to? | The target, named exactly |
| What has to pass first? | The gate commands, in order |
| Which branch, and does it merge anywhere? | The branch rules |
| Version numbers: who bumps them, and how? | The version step |
| Anything a person has to do by hand? | The manual steps, spelled out |
| What does a bad release look like, and how is it undone? | The rollback |
| How would you check afterwards that it actually landed? | The verify step: one command or URL that reads the target and shows what is now there |

The verify step is what section 4's ending checks. A playbook without one leaves "did it
publish" unanswerable, so the interview keeps going until it has that answer.

Then show the finished `SHIP.md`, get a yes, and start again at section 1.

## Done

This command has finished when every mandatory step in `SHIP.md` succeeded, and its verify
step was run and showed the expected commit, tag, or version at the target. Confirm by
reading the target, rather than by the push command exiting zero.

A step that failed leaves the command unfinished. Report which step, its real output, and
what state the target is in now.

Writing `SHIP.md` is a step on the way there, not the end: an approved playbook sends the run
back to section 1, and the command finishes after that pass. The one exception is an owner who
asked for the playbook alone, in which case say plainly that nothing was published.
