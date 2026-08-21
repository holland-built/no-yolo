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
| Steps | Ordered, smallest-reversible first, each independently checkable |
| `ui_change` | true or false |

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
