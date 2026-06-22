---
name: plan-feature
description: Plan a feature to an approved, build-ready spec — evidence → grill-me → Opus plan → approval gate. Stops at approval; writes no code. Run /build-feature after. Project-agnostic. Activate on "/plan-feature", "plan this feature".
user-invocable: true
argument-hint: "[describe the feature to plan]"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Agent
---

Feature: $ARGUMENTS

Run all phases IN ORDER. Every gate is hard — do not skip ahead.

**Agent rule:** Never write code inline. All planning → Opus agent. All implementation → Sonnet agent(s). Independent steps always fan out concurrently. Coordinator reads + dispatches only.

**Uncertainty rule:** At any phase, if intent is unclear or a decision wasn't covered in grill-me — stop. Ask the question. Do not guess, assume, or proceed. Treat unanswered questions the same as a failed gate.

**Evidence rule:** The user's description is a HYPOTHESIS, never ground truth. Opus plans only as well as the evidence it's handed. Every plan must be built from FACTS gathered first (measurements, `file:line`, graph queries, test output, schema) — never from the raw description. A plan citing the user's words instead of the codebase is a failed gate.

## Routing — pick the right tool BEFORE running the pipeline
This skill handles planning only. For the full pipeline use `/forge`. For build-only (plan already exists) use `/build-feature`.
- **Spatial/layout bug** → use Phase 0A methodology below (Playwright DOM measurement).
- **Color/typography/token/spacing nits** → NOT this skill. Use `/ui-ux` or `/impeccable`.
- **Visual/aesthetic redesign** → `/ui-wild` for design, then return here for planning.
- **Trivial fix** (1–2 files, cause already known) → fast path: phase 0 evidence → skip grill-me → Opus plan → approval. Skip ceremony.
- **Code quality audit** → `/code-health` instead.
- **Genuine multi-step feature** → full pipeline below.

State which path you're taking in one line before proceeding.

## Stack — auto-detect (do this FIRST, silently)
Before phase 0, detect the project's commands and record them:
- **Dev server URL** — check `package.json` scripts / `README` / `.dev` skill.
- **Test command** — e.g. `npm test -- --watch=false`, `pytest -v`.
- **Build/typecheck command** — e.g. `npm run build`, `tsc --noEmit`.
- **Hotpatch** (if containerized) — `docker cp` command.
- **Primary source files** — single-file SPA vs component tree.
- **Golden-master tests to NOT touch** — note any.
- **Knowledge-graph tooling** — note if project has one and its update command.
- **Critical path** — the project's money path / core user flow.

If a CLAUDE.md or project skill names these, use those values verbatim. State the detected stack in one line before proceeding.

`<slug>` = kebab of feature. `<date>` = today.

## 0 — Evidence (BEFORE grill-me — HARD gate for any bug / change to existing code)
**The bug is not where the symptom shows — it's where the measurement breaks.** Most multi-day loops come from fixing the symptom's location, not the cause's. This phase gathers FACTS so Opus plans against reality, not the user's words. Skip ONLY for greenfield with no existing surface.

Pick the evidence type by task:

**A. UI / layout / "it looks wrong"** → Open the surface in Playwright at the failing viewport; `browser_evaluate` to dump LIVE DOM numbers (`clientWidth` vs `scrollWidth`, computed `display`/`overflow`/`position`, every element wider/taller than its parent). Walk UP from the symptom to the FIRST ancestor where the measurement breaks — that ancestor is the cause. State it as **"X breaks because property Y = Z (measured)"**. **Stress-test:** inject worst-case content (64-char unbreakable string), re-measure; if it still breaks the diagnosis is wrong — redo.

**B. Backend / logic / data** → gather the equivalent fact pack: `graphify query`/`path`/`explain` to map the real call graph; read the actual function + its callers; reproduce with a failing test or a logged value (the OBSERVED wrong output vs expected); inspect the schema/types involved. State the cause as **"function/path X produces Y because Z (observed at file:line)"** — never "probably" or "should be".

**C. Either** → produce a **minimal reproduction** before any fix. A bug you can't reproduce on demand, you can't prove fixed.

Checkpoint to `brainstorms/<slug>-diagnosis-<date>.md`: reproduction steps, the measured/observed numbers, the offending element/function (`file:line`), the single root cause, the stress-test/repro result, and the **falsifiable success predicate** (the exact measurable condition that will be true when fixed).

Do NOT plan a fix whose cause you have not located with evidence. Grill-me and Opus both consume this file.

## 1 — Grill-me (BEFORE any planning)
Never plan from the raw description. Interview one question at a time using the `AskUserQuestion` tool — present 3–4 clickable options with the recommended answer placed **in the middle** of the list (not first, not last). Walk every branch. Checkpoint each answer to `brainstorms/<slug>-<date>.md` (Decisions / Open flags / Q&A log). Stop when all branches resolved or user says "done".

## 2 — Opus plan
Spawn ONE `Agent` (model: opus) with the full grill-me transcript **AND the phase-0 diagnosis** as context. Tell Opus the located root cause is ground truth — fix at the SOURCE, not with a stack of leaf-level patches. The plan MUST contain:
- **Root cause** restated as `X breaks because Y = Z (file:line)` + the single source change that addresses it
- **Success predicate** — the falsifiable, measurable condition that proves done (carried from phase 0). Every plan ends in a number or a boolean, never "should work"
- **Target file list**, each with an "already exists — do NOT recreate" note
- **Blast radius** — an explicit "do NOT touch" list: files/functions/behaviors adjacent to the change that must stay byte-identical
- **Regression pre-mortem** — which existing tests/behaviors this change could plausibly break, named BEFORE coding
- **Ordered steps**, sequenced smallest-reversible-first (each independently verifiable), ~300-word cap per downstream subagent
- flag: `ui_change: true/false`

Then a **self-check pass** (same Opus agent, second turn): "What in this plan is assumed rather than grounded in a file:line? What's the strongest reason this fix is wrong or incomplete? What did it miss?" Fold the answers back in or note why dismissed.

Reject and re-plan if: the cause isn't grounded in evidence, there's no measurable success predicate, the blast radius is unbounded, or any claim cites an API/file that wasn't verified to exist. Save to `brainstorms/<slug>-plan-<date>.md`.

## 3 — Approval gate (HARD)
Show the plan. Then stop and ask exactly: **"Approve this plan or redirect?"**
Do NOT write code until the user says yes/go/approved. If they redirect, loop back to phase 1 or 2.

On approval, append a `## HANDOFF` block to `brainstorms/<slug>-plan-<date>.md`:

```
## HANDOFF
slug: <slug>
date: <date>
status: approved
ui_change: <true/false>
```

Then tell the user: **"Plan approved and saved to `brainstorms/<slug>-plan-<date>.md`. Run `/build-feature <slug>` to build it."**

> **Anything from this planning session worth saving to memory?** A non-obvious constraint, a decision that surprised you, or a pattern worth repeating. Reply with the fact or type `skip`.

If the user replies with content (not `skip` or empty):
1. Create `~/.claude-work/projects/-Users-sholland/memory/facts/<slug>-plan-<date>.md` with:
```markdown
---
name: <slug>-plan-<date>
description: <one-line summary of the fact>
metadata:
  type: project
---

<user's fact text>

**Why:** Captured after plan-feature approval for <slug> on <date>.
**How to apply:** <brief note on when this matters>
```
2. Append one line to `~/.claude-work/projects/-Users-sholland/memory/MEMORY.md`:
   `- [<slug> plan learnings](<slug>-plan-<date>.md) — <one-line summary>`
3. Tell user: "Saved. Run `/memory-compile` to apply."

If `skip` or no reply → end silently.

**STOP HERE. Do NOT proceed to any build phase. This skill ends at approval.**
