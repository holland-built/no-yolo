---
name: build
description: Use when the owner types /build, says "build", "build this feature", "do it all", "make this change", or describes something to fix, add, or redesign. Also the door for small changes ("make the header blue", "the wording is off"). Sizes the job itself. Add --plan-only to stop at the plan.
user-invocable: true
model: opus
effort: high
argument-hint: "[what to build] | --plan-only"
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob, Agent, AskUserQuestion, TaskList, TaskUpdate]
---

# build

Work: $ARGUMENTS

One door for everything from a wording change to a new subsystem. This file routes; each
stage lives in its own file and is read when that stage runs.

**Writing happens in agents.** Planning goes to Fable, implementation to Opus. This file
reads, decides, and dispatches. See `docs/AGENTS.md`.

## Size the job, then say so

Read first, silently: the project's `CLAUDE.md`, its design tokens, and the files the request
names. The project's rules beat the defaults here wherever they collide.

| Size | Recognised by | Stages |
|---|---|---|
| **tweak** | 1-2 files, cause already visible, no new behaviour | 5, 6, on the short contract below |
| **fix** | Something is broken and the cause is not yet located | 0, 2, 4, 5, 6, plus 3 when `ui_change` |
| **feature** | Behaviour that did not exist | 0, 1, 2, 4, 5, 6, plus 3 when `ui_change` |
| **redesign** | How an existing surface looks is what changes | all, and 3 always runs |

Torn between two sizes: take the smaller and name the one you nearly took. An under-called
tweak costs one more round; an over-called one costs the owner an hour.

**A tweak's proof contract.** Stage 6 measures a success condition that stage 0 wrote, and a
tweak skips stage 0. So a tweak writes its own, in one line, before any edit: what is
observably true afterwards that is false now. Look at the current value first, so the
"before" is read rather than assumed. Stage 6 then re-reads that same value.

A tweak whose condition cannot be stated in one line was mis-sized. Take it back to the gate
as a fix.

Print exactly this and wait:

```
Size:       <tweak|fix|feature|redesign> — <what made it that size>
Using:      <pieces>
Instead of: <the obvious alternative> — <why the pick beat it>
Go, or redirect?
```

"Go", "yes", or a corrected size all count.

## What runs while that gate waits

Neither of these uses the owner's answer, so both start now rather than after (`docs/AGENTS.md`,
the Wait Test):

- **Stack detection.** Dev server URL, test command, build command, the project's critical
  path, and the component library in use. Read from `package.json`, the README, and the
  project's own `CLAUDE.md`, whose values win verbatim.
- **Stage 0 evidence**, for any size above tweak. Read-only measurement.

## The stages

Read one file when its stage begins. Skip the files for stages this size does not run.

| Stage | File | Produces |
|---|---|---|
| 0 | `stages/0-evidence.md` | The located cause, measured, with a reproduction |
| 1 | `stages/1-interview.md` | Every branch of the decision resolved |
| 2 | `stages/2-plan.md` | The plan, Codex-checked, owner-approved |
| 3 | `stages/3-mockups.md` | The variant set from `rules/mockups.md`, judged, one chosen. Runs when stage 2 set `ui_change` |
| 4 | `stages/4-tests.md` | Failing tests that went red for the right reason |
| 5 | `stages/5-build.md` | The code, reviewed on two axes |
| 6 | `stages/6-prove.md` | The success condition, met and locked |

`--plan-only` stops after stage 2 with the plan written and nothing built.

## What starts early

Each of these is launched before the stage that consumes it, because none reads the previous
stage's output. The Wait Test in `docs/AGENTS.md` is what put them here:

| Launch at | What | Read at |
|---|---|---|
| Plan approved | Codex writes edge-case tests from the spec | End of stage 4 |
| Plan approved, `ui_change` false | Codex authors a rival implementation, when 3+ files are touched. It reads the plan and nothing later. A UI rival needs the chosen variant, so it launches at the stage 3 pick instead | Stage 5, after the build agents return |
| Plan approved | The reuse search for the symbols the plan names. Symbols that turn up later, from the variant or from an agent, get the same search the moment they are proposed | Stage 5, when the briefs are written |
| Plan approved | Briefs for backend plan steps. UI briefs wait for the chosen variant | Stage 5 dispatch |
| Before the Opus mockup call | Codex authors the slot `rules/mockups.md` assigns it | Stage 3 judging |
| Stage 3 judging | Drafting stage 4's seam question, asked at the variant gate in the same turn when the seam does not depend on the variant | Stage 4 |

`stages/2-plan.md` carries the approval-time launches as procedure, since that is the file
open when approval lands.

Two things that look parallel and are not: the standards and spec reviews wait for a green
suite, because the fix loop rewrites the diff they would read; and stage 6's "Lock it" stashes
the fix, so it runs after the checks that read the tree, never beside them.

## Long sessions

At a stage boundary in a session that has run long, name the stage just finished and the one
next, and offer `/handoff` instead of opening the next one. See `docs/CONTEXT.md`.

## Done

`stages/6-prove.md` holds the completion contract for the whole command. This file does not
restate it.
