# Stage 2: Plan

## Who writes it

One agent, model Fable, effort high. It receives the interview transcript and the stage 0
diagnosis, and it is told the located cause is ground truth: fix at the source, rather than
stacking patches at the leaves.

## What the plan contains

| Part | Content |
|---|---|
| Ground truth | Whichever stage 0 produced. A defect: `X breaks because Y = Z (file:line)`, and the single source change addressing it. New behaviour: the seam at `file:line`, the baseline read there, and what attaches to it |
| Success condition | Carried from stage 0. Ends in a number or a boolean |
| Target files | Each with `Already exists, do NOT recreate` |
| Blast radius | The adjacent files, functions and behaviours that stay byte-identical |
| Regression pre-mortem | Which existing tests or behaviours this could break, named before any code |
| Steps | Numbered, smallest-reversible first, each independently checkable. Every step carries **Depends on**: the step numbers whose output it reads, or `none` |
| `ui_change` | true or false |

## Waves

`Depends on` groups the steps into waves, by the rule in `docs/PARALLEL.md`. Print them under
the steps:

```
Wave 1: 1, 3, 4
Wave 2: 2, 5      (2 depends on 1; 5 depends on 3)
Wave 3: 6, 7      (6 depends on 2 and 5; 7 depends on 4, from wave 1)
```

Stage 5 dispatches a wave, so this grouping decides how much runs at once. A step depending on
every earlier step was written too big: split it, or say in one line what it shares with them.

## Two critiques, running together

Neither reads the other's output, so both start at once:

**The self-check**, same agent, second turn: "What in this plan is assumed rather than
grounded in a `file:line`? What is the strongest reason this fix is wrong or incomplete?
What did it miss?"

**Codex**, per `rules/codex.md`, on the written plan.

Fold accepted findings into the plan file. Re-invoke the planner only when a fold-in changes
the ordering or the blast radius. Carry the disagreements into the approval gate, so the
owner sees what Codex flagged and why anything was rejected.

## Send it back when

- The ground truth is not anchored to a `file:line` or a measured value: an unlocated cause
  for a defect, or an assumed seam for new behaviour.
- There is no measurable success condition.
- The blast radius is open-ended.
- Every step depends on the one before it, with no reason given. That is a serial plan by
  accident, and it costs the whole build's parallelism.
- A claim cites an API or a file nobody confirmed exists.

Save to `brainstorms/<slug>-plan-<date>.md`.

## The approval gate

Print exactly this, with nothing around it:

```
**What we're building:**
[2-3 plain sentences. What problem this solves, what it touches. No jargon.]

**What actually happens:**
- [concrete step, real verb, real file]

**Watch out for:**
[Only when something is irreversible, visible to others, or hard to undo.]

**Decisions locked:**
- [decision]: [answer]

**Codex flagged:**
- [finding]: [folded in / rejected because]

**Open:**
- [thing to look up before building]

Approve this plan, or redirect?
```

"Yes" is the whole approval. `--plan-only` ends here.

## What launches the moment it is approved

Four things, none of which reads anything a later stage produces:

| Launch | Where it is read |
|---|---|
| Codex edge-case tests from the spec, below | End of stage 4 |
| The Codex rival implementation, when `ui_change` is false and the plan names 3+ files or accepted a blocking finding. Command in `stages/5-build.md`. A UI rival waits for the stage 3 pick | Stage 5, after the build agents return |
| The reuse search for every symbol the plan introduces (`stages/5-build.md`) | Stage 5 briefs |
| Briefs for the backend plan steps (`stages/5-build.md`) | Stage 5 dispatch |

Codex writes edge-case tests from the spec. It needs the behaviour list and the public
interface signatures, never the implementation, so it can run now and be read at the end of
stage 4.

Write the spec first, and confirm the file exists before launching anything against it:

```bash
mkdir -p .xcheck
grep -q '^\.xcheck/' .gitignore 2>/dev/null || echo '.xcheck/' >> .gitignore
```

Write `.xcheck/<slug>-spec.md`: the plan's behaviour list, plus the public signatures of
anything it adds or changes. The implementation stays out of it, since sharing the
implementation is what makes the second opinion share the first one's assumptions.

Then, with the file confirmed on disk:

```bash
bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/codex.sh" \
  "Read .xcheck/<slug>-spec.md — a spec and public interface. Write edge-case tests the author is likely to miss: boundaries, empty and null, ordering, concurrency, malformed input. Return test code only, max 8 tests, in <framework> syntax. No preamble." \
  ".xcheck/<slug>-tests.out" &
```

## Done

This stage has finished when the plan is saved, both critiques are settled, and the owner has
said yes.
