# Stage 5: Build

Dispatch rules, the brief's contents, and the model-per-job table live in `docs/AGENTS.md`.
This file is the build-specific procedure.

## One slice at a time

Stage 4 handed over the agreed seam and the first failing test. Each remaining behaviour in
the plan goes through the same loop: write the failing test, watch it go red for the intended
reason, write the least code that turns it green, confirm green, then the next one.

The loop itself and what makes a test worthless are in `docs/TESTING.md`.

## Before dispatching

Read every target file and its direct imports yourself. Write one brief per agent, each
carrying the target path, the exact change quoted from its plan step, the
`Already exists, do NOT recreate` note, and the blast radius.

UI work: the brief names the variant section to match and its sourcing rows. Agents import
the mapped components rather than hand-rolling them.

Fan independent agents out in one call, five at a time.

## Reuse before writing

For every new symbol the build would introduce, search the tree for an existing one with the
same name or role. A sibling already doing the job means using it.

`cxpak` builds the dependency graph that makes this search reliable in a large repo. Run it
when the tree is bigger than a grep can hold.

## The rival implementation

Fires when the plan names three or more target files, or when stage 2 accepted a blocking
finding. Otherwise it does not run.

Launch it before dispatching the build agents, because it authors against the pre-build
tree, and background it so the briefs get written while it runs:

```bash
bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/codex.sh" \
  "Read brainstorms/<slug>-plan-<date>.md — an approved implementation plan for this repository. Author a rival implementation of its ordered steps as ONE unified diff against the current tree: your own approach, not a guess at another author's. Honour the plan's blast-radius list and end at its success condition. At most 3 files and 200 changed lines; diff only the steps you would do differently if the plan is larger, and say which you skipped. Return only the unified diff, or BLOCKED: <reason>. No preamble." \
  "brainstorms/<slug>-rival-<date>.md" &
```

Read it after the build agents return. The runner buffers its whole session and prints it in
one write, so an empty file means still running.

Take the last block and strip everything before its first `diff --git`. Validate with `git
apply --check` in a throwaway worktree before reading it. Anything that fails to apply, times
out, or returns `BLOCKED:` is recorded as `rival: not run — <reason>` and the build proceeds.

Applies clean: read it hunk by hunk against what was built. For each divergence, pick one
with a one-line reason. Adopted hunks land through normal edits.

## After the agents return

Merge any worktree branches, run the build or typecheck command, and fix errors before
testing.

## Regression gate

Run the full suite. Any failure starts a fix loop: an Opus agent produces a fix plan scoped
to the broken behaviour, Opus agents apply it, the suite re-runs.

Three iterations is the cap. Still red after three: hand it to Codex once, with the failing
output, the diff, and the located cause. Fresh eyes from another model family is exactly the
stuck-loop case. Still red after that, stop and say so.

## Quality gates

Fan these out in one call once the suite is green. The secret scan and the lint run during
the fix loop instead, since neither reads a test result.

**Every time:**

| Gate | Passes when |
|---|---|
| Lint and typecheck | Zero new errors, warnings triaged |
| Duplicate scan | No new symbol duplicates an existing one |
| Secret scan | Nothing secret in the diff |
| Standards review | An agent that has not seen the plan finds no correctness or edge-case defect |
| Spec review | A separate agent confirms the diff is what was asked for, with no missing requirement and no scope creep |

The last two run as separate agents that cannot see each other. A change passes one and fails
the other, and merged reviewers hide that.

**When the diff touches it:** auth, routes, secrets, queries or user input get a security
pass. A UI change gets an accessibility pass. A hot path gets a before-and-after measurement.

## Disagreement

A finding closes by fixing the code or by the owner waiving it. A gate does not close its own
finding by deciding it was wrong.

Two gates disagreeing about the same code is a flag, and the stricter verdict wins.

Disagreeing with a finding: say so in one line, then surface it anyway as
`GATE FLAG — <gate>: <finding>. My read: <why>. Ship anyway? (y/n)` and wait.

A gate that could not run is a flag, not a pass.

## Done

This stage has finished when the suite is green, every gate has reported a result or a reason
it did not run, and every open flag has been fixed or waived by the owner.
