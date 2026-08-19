---
name: build
description: Use this skill when the user types /build, says 'build', 'build this feature end to end', 'do it all', 'plan if needed and do it', or asks for the whole job done in one go. Also the door for small changes — 'make the header blue', 'the wording is off', 'too much spacing' — it sizes the job itself rather than sending you elsewhere. Second mode — plan only — fires on /build --plan-only, 'plan this', 'plan before we build', 'help me think through', or 'interview me about'; it runs evidence, interview and plan, then stops at the alignment gate without writing code. Full pipeline: evidence → grill-me → Fable plan → approval gate → UI mockup gate → TDD → Opus build → regression gate → prove.
user-invocable: true
argument-hint: "[describe the feature to build] | --plan-only"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
---

Feature: $ARGUMENTS

**Agent rule:** never write code inline. All planning → Fable agent. All implementation →
Opus agent(s). The coordinator reads and dispatches only.

**Long-session rule:** at a stage boundary, when the session has already run long, offer
`/handoff` instead of opening the next stage. Name the stage just finished and the one next,
then wait. A boundary is the cheapest place to stop, and a handoff written at one survives a
session that dies mid-stage.

## Mode select

| Signal | Mode |
|---|---|
| `--plan-only`, "plan this", "plan before we build", "help me think through", "interview me about" | **Plan only** — phases −1 → 3, then stop at the alignment gate |
| Anything else | **Full** — the whole pipeline |

---

## −1 — Read the room, then declare (HARD gate, every run)

**One door.** `/build` takes everything from "make the header blue" to a new subsystem. It
never sends the user elsewhere to retype their request. It works out how big the job is,
says so, and waits to be corrected.

**Read before classifying** (silently, no narration): the project's own `CLAUDE.md`, its
`design-system/MASTER.md` or CSS tokens, and the files the ask actually names. Global rules
are already in context. Read the project first — its rules beat the global defaults wherever
they collide.

**Then pick exactly one size:**

| Size | Test for it | Pipeline |
|---|---|---|
| **tweak** | 1–2 files, cause already obvious, no new behaviour — colour, wording, spacing, copy | 0 → 5 → 6. Skip grill-me, plan, mockups |
| **fix** | Something is broken and the cause is NOT yet located | 0 → 2 → 3 → 4 → 5 → 5.5 → 6 |
| **feature** | New behaviour that did not exist | full pipeline |
| **redesign** | How an existing surface looks is what changes | full pipeline WITH the 3.5 mockup gate |

Unsure between two sizes? Pick the **smaller**, and say which one you nearly picked. An
under-called tweak costs one more round; an over-called tweak costs the user an hour of gates.

**Choosing the pieces — best tool wins, and you name why.** No fixed order, no native-first
rule. A built-in is usually safest because nothing drifts under it; a local skill wins when it
carries a rule the built-in never heard of; a downloaded skill wins when it's genuinely better
at that one thing. Say which and why in one line — an unexplained pick is the failure, not a
wrong pick.

**Print exactly this and STOP:**

```
Size:       <tweak|fix|feature|redesign> — <one line: what made it that size>
Using:      <piece>, <piece>, <piece>
Instead of: <the obvious alternative> — <one line: why the pick beat it>
Go, or redirect?
```

Do not read past this gate until the user answers. "Go", "yes", or a corrected size all
count; silence does not. If they name a different size, take theirs and don't argue twice.

## Stack — auto-detect (FIRST, silently)

Before phase 0, detect and record for the run:

- **Dev server URL** — from `package.json` scripts, README, or a project skill.
- **Test command** and **build/typecheck command** (or none).
- **Hotpatch** if containerized — e.g. `docker cp <file> <container>:/app/<file> && docker restart <container>`.
- **Primary source files** — single-file SPA vs component tree — and **golden-master tests
  NOT to touch**; write new behaviour tests in a separate file.
- **Critical path** — the project's money path that must never break, and how to exercise it.
- **Latest-stable gate** (greenfield or new core dep) — never pin a version from memory, it
  lags. Query the registry and pin the current stable dist-tag, never a prerelease. npm
  `npm view <pkg> version`; Node `node -v` or `.nvmrc`; Python `pip index versions <pkg>`;
  Rust `cargo add <pkg>`; Go `go list -m -versions <module>`. **Compat beat:** if the newest
  major just dropped and a core dep can't support it, pin the highest version everything
  supports and say why — newest-that-works, not newest-that-exists.
- **Prefab component library** — detect per `~/.claude/skills/design/PREFAB_SOURCING.md`.
  Record `PREFAB` and state it in the stack line. Every interactive element in UI work comes
  from PREFAB by default; hand-building a primitive it provides is a flagged exception. Never
  install a second component library beside an existing one. Never block the build on a library.

If a project `CLAUDE.md` names these, use those values verbatim. State the detected stack in
one line before proceeding.

`<slug>` = kebab of the feature. `<date>` = today.

## 0 — Evidence (HARD gate for any bug or change to existing code)

**The bug is not where the symptom shows — it's where the measurement breaks.** This phase
gathers FACTS so the planner works against reality, not the user's words. Skip only for
greenfield with no existing surface.

**A. UI / layout / "it looks wrong"** → open the surface in Playwright at the failing
viewport; `browser_evaluate` to dump LIVE DOM numbers (`clientWidth` vs `scrollWidth`,
computed `display`/`overflow`/`position`, every element wider or taller than its parent).
Walk UP from the symptom to the FIRST ancestor where the measurement breaks — that ancestor
is the cause. State it as **"X breaks because property Y = Z (measured)"**. **Stress-test:**
inject worst-case content (64-char unbreakable string), re-measure; if it still breaks, the
diagnosis is wrong — redo it.

**B. Backend / logic / data** → map the real call graph by grepping callers; read the actual
function and its callers; reproduce with a failing test or a logged value (OBSERVED wrong
output vs expected); inspect the schema and types. State the cause as **"function/path X
produces Y because Z (observed at file:line)"** — never "probably" or "should be".

**C. Either** → produce a **minimal reproduction** before any fix. A bug you can't reproduce
on demand, you can't prove fixed.

Checkpoint to `brainstorms/<slug>-diagnosis-<date>.md`: reproduction steps, the measured
numbers, the offending element or function (`file:line`), the single root cause, the
stress-test result, and the **falsifiable success predicate** — the exact measurable
condition true when fixed (`scrollW <= clientW`, `fn(x) === expected`, `endpoint returns 200
with N rows`).

Do NOT plan a fix whose cause you have not located with evidence.

## 1 — Grill-me (BEFORE any planning)

**Independent pre-read first — do not parrot the problem statement back.**

1. Read the relevant code and files independently.
2. Form your own diagnosis. What does the evidence say the actual problem is?
3. State that read *before* Q1: "Here's what I see in the code: X. My working theory is Y.
   Now let me probe the gaps."
4. If your read differs from the user's description, name the conflict and ask about it first.

Then interview one question at a time with `AskUserQuestion` — 3–4 clickable options,
recommended answer placed **in the middle**, never first or last. Walk every branch. If a
question can be answered by exploring the codebase, explore instead of asking.

Checkpoint each answer to `brainstorms/<slug>-<date>.md` under Decisions / Open flags / Q&A
log. Stop when every branch resolves, or the user says done. No fixed question count.

### Decisions that outlive the session

The brainstorm file is a session artifact — nobody reads it in six months. Two things escape
it into the repo, **the moment the decision locks, not at the end**:

**ADRs.** A decision earns one only if all three hold:
1. Hard or expensive to reverse (schema shape, storage engine, auth model, public API
   contract, a dependency you'd have to rip out).
2. A reasonable person could have chosen differently — real alternatives existed.
3. The code alone won't say why; a future reader asks "why is it like this?" and finds nothing.

All three → write `docs/adr/NNNN-<slug>.md`: **Context** (the forces, one paragraph),
**Decision** (present tense), **Alternatives rejected** (each with why it lost),
**Consequences** (what this makes easy, and what it makes hard). Fewer than three → normal
decision, brainstorm file only. An ADR per choice is as useless as none.

**Glossary.** Every project noun this interview names or sharpens goes into the repo's
`CONTEXT.md` glossary, one line each. Read the existing entries first — if the repo already
has a word for the thing, use the repo's word rather than minting a synonym.

Both are real files in the diff. Say so when you summarise, so phase 5 doesn't rewrite them.

## 2 — Plan (Fable agent)

Spawn ONE `Agent` (model: fable, effort: high) with the full interview transcript **and the
phase-0 diagnosis**. Tell the planner the located root cause is ground truth — fix at the
SOURCE, not with a stack of leaf-level patches. The plan MUST contain:

- **Root cause** restated as `X breaks because Y = Z (file:line)` plus the single source
  change that addresses it
- **Success predicate** — the falsifiable measurable condition that proves done, carried from
  phase 0. Every plan ends in a number or a boolean, never "should work"
- **Target file list**, each with an "already exists — do NOT recreate" note
- **Blast radius** — an explicit "do NOT touch" list of adjacent files, functions and
  behaviours that must stay byte-identical, so the build agent can't drift
- **Regression pre-mortem** — which existing tests or behaviours this could plausibly break,
  named BEFORE coding, so phase 5.5 is targeted rather than hopeful
- **Ordered steps**, smallest-reversible-first, each independently verifiable, ~300-word cap
  per downstream subagent
- flag: `ui_change: true/false`

Then a **self-check pass** (same agent, second turn): "What in this plan is assumed rather
than grounded in a file:line? What's the strongest reason this fix is wrong or incomplete?
What did it miss?" Fold the answers in, or note why dismissed.

Reject and re-plan if the cause isn't grounded in evidence, there's no measurable success
predicate, the blast radius is unbounded, or any claim cites an API or file that wasn't
verified to exist. Save to `brainstorms/<slug>-plan-<date>.md`.

## 2.5 — Cross-model check

Run the `xcheck` skill on the saved plan. Accepted blocking and major findings fold into the
plan file — re-invoke the planning agent only if a fold-in changes ordering or blast radius.
Minors get noted or dropped. Carry the dissent block into the approval gate so the user sees
what Codex flagged and why anything was rejected. No-ops silently if Codex is unavailable.

## 3 — Approval gate (HARD)

**Plan-only mode ends here.** Output this structure exactly, no prose outside it:

```
**What we're building:**
[2–3 plain sentences. What problem does this solve? What does it actually touch? No jargon.]

**What actually happens:**
- [concrete step — real verb, real file or system]

**Watch out for:**
[Only if something is irreversible, visible to others, or can't be undone. Skip if nothing qualifies.]

**Decisions locked:**
- [decision]: [answer]

**Open flags:**
- [thing to look up before building]

Are we aligned? (yes / keep going / fix X)
```

"Yes" is the only approval needed — do not ask a second confirmation question. Write the
final summary to the brainstorm file and stop. "Keep going" or a correction → back to phase 1.

**Full mode:** show the plan and ask exactly **"Approve this plan or redirect?"** Write no
code until the user says yes. A redirect loops back to phase 1 or 2.

## 3.5 — UI mockup gate (only if `ui_change: true`)

Skip entirely for backend-only changes.

Create the mockup folder with the shared script, never a plain `mkdir -p` — it also adds
`.mockups/` to the project's `.gitignore` if missing, which is the step everyone forgets:

```bash
bash ~/.claude/skills/design/scripts/mockup-dir.sh "build-<slug>"
```

Check for a persisted design system, falling back to CSS tokens:

```bash
[ -f design-system/MASTER.md ] && echo "MASTER_FOUND" || echo "NO_MASTER"
```

- **MASTER.md exists** → read it. Its palette, typography, spacing scale and layout rules are
  hard constraints for all 8 variants. Print `Using design system from design-system/MASTER.md`.
- **No MASTER.md** → extract tokens from the project's CSS: `:root` variables, font-family
  declarations, colour palette, spacing scale.

Either way every variant uses these tokens verbatim — no invented hex codes or font names.

**Design references (read-only).** Read `~/.claude/skills/design/DESIGN_REFS.md` and follow
its routing to pull only the references this task needs. Do not read all of them, and never
let a reference override the tokens above.

### Step A — Generate 8 variants

`.mockups/build-<slug>/<slug>-v1.html` … `v6.html` plus `v9.html`/`v10.html`, fanned out in
ONE parallel call:

- **v1–v6** — conservative to polished, all on real tokens, each a DISTINCT layout paradigm.
  Not the same card grid with different spacing.
- **v9–v10** — WILDLY different: a different layout paradigm, spatial arrangement or visual
  language entirely (terminal, full-bleed hero with bold type, Bloomberg data grid, floating
  action panel, bento grid, magazine editorial). They must look like a different product team
  made them, never a card-grid or accordion variation.
- **Codex authors v9–v10** — run `/design` Step 2's Codex wild-slot block with paths adapted
  to `.mockups/build-<slug>/`. Any failure → that slot regenerates via the normal agent. Skip
  silently without codex.

### Step B — Slop judge (HARD gate, minimum 3 survivors of 4)

Spawn ONE adversarial judge agent with all 4 files. It rejects any variant matching ANY
pattern in the canonical lists, read fresh at run time and never inlined here:
`~/.claude/docs/GUI_SLOP.md` — every section, including its `### Mockup-only kill rules`.
It also deduplicates functionally identical layouts, returning survivors with a one-line
reason each.

Fewer than 3 survive → respawn the rejects naming the exact slop pattern matched: "Go
structurally different — change the layout paradigm entirely, not just the colour."

### Step C — Combined view + screenshot

Build ONE page `.mockups/build-<slug>/<slug>-all.html`, survivors only, stacked vertically.
Each section: variant label, one-line description, iframe. Mark the recommend with ★.

**Mandatory, both:**
```bash
open ".mockups/build-<slug>/<slug>-all.html"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu \
  --window-size=1400,900 --screenshot=.mockups/build-<slug>/<slug>-all.png \
  "file://$PWD/.mockups/build-<slug>/<slug>-all.html"
```

Show the screenshot inline.

**Codex second judge** (skip silently if `command -v codex` fails) — a different model family
grading visuals Claude both generated and judged:
```bash
bash ~/.claude/skills/xcheck/scripts/codex-run.sh -m gpt-5.6-sol -s read-only \
  -i ".mockups/build-<slug>/<slug>-all.png" \
  "This image shows UI mockup variants, labeled. For each: verdict slop|clean + one-line reason (slop = generic AI-generated look: card grids, gradient CTAs, hero+centered-CTA, shadcn starter DNA). Then name your single top pick + one sentence why. No preamble."
```

Codex is advisory and never kills a variant alone — Claude's judge stays the gate, including
for Codex's own v9–v10, which gets no self-grading weight. Output
`| Variant | Description | Survived judge? | Codex | Pick |`, ★ on the recommend.

Both models picking the same variant = high-confidence recommend. A split shows both reasons
— that disagreement is signal — and triggers `/design` Step 3's synthesis round (crossover
v11/v12); run it, append both, gate on all 10.

Stop and ask **"Which mockup variant? (or redirect)"** Do not proceed until the user names
one. Lock it — the build agents match it exactly.

### Step D — Component sourcing gate (HARD)

Emit the sourcing table (`skills/design/PREFAB_SOURCING.md` format) for the approved variant,
one row per interactive element. Hand-build rows need a closed-list reason; a hand-build row
on a primitive the detected library already provides is a gate failure. No phase 4 without
the table shown.

Mockup files stay in `.mockups/build-<slug>/` until after phase 6.

## 4 — TDD (vertical slices)

**Do NOT write all tests first, then all code.** That is horizontal slicing — it verifies
imagined behaviour and produces a wall of red that gives no feedback until everything is done.

One vertical slice at a time:

```
1. Write ONE failing test for the smallest useful behaviour
2. Run it → confirm it fails, for the reason you intended (red)
3. Write the minimum code to pass
4. Run it → confirm green
5. Refactor if needed, staying green
6. Repeat for the next behaviour
```

**Agree the seams first.** Name where you will test — the public function, the HTTP boundary,
the DB adapter — and what you will fake, then get the user's OK before writing a single test.
Tests are the hardest thing in a diff to move later; picking the seam alone means rewriting
them when the user wanted a different level. If they name a different seam, use theirs.

**Two ways a test can be worthless:**

- **Tautological — banned.** If the assertion recomputes the expected value using the same
  logic as the code under test, it passes no matter what the code does, including wrong.
  Expected values are hand-written literals: `expect(total).toBe(17.5)`, never
  `expect(total).toBe(price * qty * (1 + rate))`. Same ban on asserting against the
  implementation's own output, a shared helper both sides call, or a snapshot you just
  regenerated to make it pass. If you can't state the expected value without running the code,
  you don't yet understand the behaviour — go work it out first.
- **Unvalidated red — doesn't count.** A test you wrote but never executed is not red, it's
  unknown. Run it and read the failure. It must fail *because the behaviour is missing* — not
  on an import error, typo, wrong fixture path or bad mock. A green-on-first-run test is a bug
  in the test: it asserts something already true. Fix the test before writing implementation.

Run only the relevant file or pattern while iterating, not the whole suite. Never target a
golden-master or snapshot suite — treat it as a regression guard and write new behaviour
tests in a separate file alongside the module.

A test failing unexpectedly → stop writing tests. Run `/health` on it to build the feedback
loop and find the root cause. A red test you don't understand is worth more as a diagnostic
than as a TODO.

### 4.5 — Adversarial tests (Codex; skip silently without codex)

Implementer-authored tests share the implementer's assumptions. Break that with one
cross-model call. Write the SPEC ONLY — the plan's behaviour list plus public interface
signatures, never the implementation — to `.xcheck/<slug>-spec.md`, then:

```bash
bash ~/.claude/skills/xcheck/scripts/codex-run.sh -m gpt-5.6-sol -s read-only \
  "Read .xcheck/<slug>-spec.md — a spec and public interface. Write edge-case tests the author likely missed (boundaries, empty/null, ordering, concurrency, malformed input). Return test code only, max 8 tests, in <framework> syntax. No preamble."
```

Review each returned test: drop any that misread the spec, adapt the rest to project
conventions, run them. Failures are real findings — fix in phase 5. Passing tests covering a
genuine gap stay in the suite; redundant ones go. Delete the temp file.

## 5 — Build (Opus agents)

**Cap: 5 agents at once.** More than 5 independent steps → batch into rounds of 5, waiting
for each round. Sequential dependencies respect ordering.

**Before dispatching ANY agent**, write a per-agent spec covering:
- Target file (absolute path) and the exact change, quoting the plan step and its context
- Adjacent functions and components that must NOT be touched, plus an explicit
  `Already exists — do NOT recreate: <file>` note
- If `ui_change`: which mockup variant section to match exactly, plus its sourcing-table rows
  — import the mapped prefab components, never hand-roll. If phase 3.5 was skipped, or new
  interactive elements appeared since, emit the sourcing table now. No UI dispatch without it.

Fan out in one parallel call, never one at a time. Every agent reads its target file and
direct imports before editing, and caps output at ~300 words.

After all agents complete: if any used `isolation: worktree`, merge each branch into the
working branch, confirm with `git merge-base --is-ancestor <sha> HEAD`, then `git worktree
remove` each dir and `git branch -D` its branch. Run the build/typecheck command to catch
errors before testing. Hotpatch if containerized.

### Rival implementation (Codex; skip silently without codex)

Fires ONLY when the plan's target file list names 3 or more files, or phase 2.5 accepted at
least one blocking or major finding — that is what "contested" means. Otherwise skip in
silence; most builds never see this.

**Launch this before dispatching the agents above** — it authors against the pre-build tree, and
sits down here only because its verdict lands after the build. Background it and write the
per-agent specs while it runs. Foreground is not an option: the Bash tool's ceiling is 10
minutes, so a blocking call is killed before the runner's own 15-minute timeout can fire, and it
would freeze the coordinator that has specs to write. Codex is not an `Agent` dispatch, so the
5-agent cap is unaffected. Typical duration 2–5 minutes.

```bash
bash ~/.claude/skills/xcheck/scripts/codex-run.sh -m gpt-5.6-sol -s read-only -t 900 \
  "Read brainstorms/<slug>-plan-<date>.md — an approved implementation plan for this repository (your working directory; you are read-only). Author a rival implementation of its ordered steps as ONE unified diff against the current tree — your own approach, not a guess at another author's. Honour the plan's blast-radius do-NOT-touch list and end at its success predicate. Hard caps: at most 3 files and 200 changed lines; if the plan is larger, diff only the steps you would do differently and say which you skipped. Return only the unified diff. If the plan cannot be implemented inside its blast radius, return BLOCKED: <reason>. No preamble." \
  > brainstorms/<slug>-rival-<date>.md 2>&1 &
```

Once the build agents have returned, poll that file until it is non-empty. The runner buffers
its whole session and prints it in ONE write as it exits, so empty means still running and
non-empty means finished — there is no partial read to guard against:

```bash
for _ in $(seq 60); do [ -s brainstorms/<slug>-rival-<date>.md ] && break; sleep 15; done
```

Still empty after that (15 minutes, the runner's own cap) → treat it as the not-run case below.

### Adjudicate the rival diff

Extract the diff first. The runner returns codex's whole session — a stdin banner, the
reasoning, then the final message printed TWICE (once inline, once as the tail block). Take the
LAST block and strip everything before its first `diff --git` line — not the first `---`, which
lands *inside* a hunk header and is absent entirely from a rename-only diff. Feeding raw output
to `git apply` fails on the banner, not on the diff. The LAST block matters: the runner echoes
the prompt back too, so on a probe run here the first `diff --git` in the file was the echoed
prompt at line 14 and the real diff was at line 20.

Validate before reading it: `git apply --check` in a throwaway worktree. It fails to apply,
isn't a diff, timed out (exit 124), or returned `BLOCKED:` → carry on with Claude's
implementation and record one advisory line in the phase 7 summary: `rival: not run — <reason>`.
That is explicitly NOT a 5.6 gate flag. A missing second opinion is not a defect in the diff,
and 5.6's any-flag-blocks-ship rule would otherwise hold every ship hostage to whether Codex
answered. Never `git apply` unreviewed output into the working tree.

Applies clean → read it hunk by hunk against the actual implementation diff. For each
divergence pick Claude's version or the rival's, with a one-line reason. Adopted rival hunks
land through normal Edits — an Opus agent if 3 or more files.

Append the verdict table to the rival file. Codex is advisory: Claude adjudicates and stays the
gate, exactly as 3.5 states for the visual judge. The merged result enters 5.5 unchanged, so
the regression gate and its Codex rescue path test whatever was adopted.

## 5.5 — Regression gate + fix loop (HARD)

Run the full test suite. Any failure → fix loop, repeat until green:

1. Spawn `Agent` (model: opus) with the failing output and the full diff so far. It produces
   a fix plan targeting only the broken behaviour. Save to `brainstorms/<slug>-fix-<N>-<date>.md`.
2. Spawn `Agent` (model: opus) per fix step, fanning out independent ones. Every dispatch
   reads the target file first and carries the "already exists — do NOT recreate" note.
3. Hotpatch if needed; re-run the full suite.
4. Still failing → increment N, back to step 1. Cap at 3 iterations.
5. Still red after 3 → **Codex rescue, once, before bothering the user.** If the
   `codex:codex-rescue` agent is available, spawn it with the failing output, the full diff
   and the located root cause — fresh eyes from a different model family, exactly the
   stuck-loop case it exists for. Green after rescue → proceed. Codex unavailable or still
   red → stop: "3 fix attempts + Codex rescue failed. Paste output to continue."

Do NOT proceed to phase 6 with a red suite or a failing build.

## 5.6 — Quality gates (after green, before prove)

ALWAYS gates run every time. CONDITIONAL gates run only when the diff touches the named
surface. Fan the agent-based ones out in ONE parallel call. Any real issue → fix it (back to
phase 5) or explicitly triage with a written reason.

**ALWAYS:**
- **Lint + typecheck** — zero new errors, warnings triaged.
- **Duplicate / recreate scan** — for every NEW symbol the build introduced, grep the tree for
  an existing one with the same name or role. A sibling already does it → STOP, reuse it.
- **Secret scan** — `bash ~/.claude/hooks/secret-scan.sh` over the diff. Nothing secret enters
  a commit.
- **Reviewer pass** — spawn one `Agent` (general-purpose, model: opus) scoped to the diff with
  this brief: *"Review only this diff for correctness, error handling, and edge cases. Report
  severity-tagged findings with file:line. Do not suggest refactors outside the diff."*

**CONDITIONAL:**
- **Security** — IF the diff touches auth, API routes, secrets/env, DB queries or user input →
  spawn one `Agent` (general-purpose, model: opus) scoped to those files: *"Audit for
  authorization gaps, injection, unsafe secret handling, and missing input validation.
  file:line + severity per finding."*
- **Accessibility** — IF `ui_change: true` → spawn the `accessibility-tester` agent. Keyboard
  reachability, roles and aria, contrast, focus order.
- **Perf** — IF the change touches a hot path → measure before and after (render time, query
  count, bundle delta) and confirm no regression.
- **Code health** — IF the diff adds ≥3 new functions or components, or is a major refactor →
  run `/health` on the changed paths.
- **Prefab-first compliance** — IF `ui_change: true` → scan the diff for hand-written
  button/dropdown/modal/switch markup where the sourcing table mapped a prefab. Found → back
  to phase 5.

**Disagreement rule — any flag blocks ship.** Gates fan out in parallel and they WILL
disagree, with each other and with you. Resolve it this way, never by argument:

- A finding closes **only** by fixing the code, or by the USER waiving it. You may not close
  your own gate's finding by deciding it's wrong. "Triage with reason" means *write the reason
  and act on it*, not *talk past it*.
- Two gates disagreeing about the same code = **flagged**. The stricter verdict wins. Do not
  average them, do not pick the one you agree with.
- Disagree with a finding? Say so in one line, then still surface it:
  `GATE FLAG — <gate>: <finding>. My read: <why I think it's wrong>. Ship anyway? (y/n)`
  and wait. Silence is not a yes.
- **A gate that could not run is a flag, not a pass.** Agent errored, tool missing, timed out
  → report it unresolved. Never record a gate you did not run as clean.

## 6 — Prove (mandatory, NUMERIC not visual)

Confirm the success predicate holds against reality. The metric is the gate; screenshots and
prose are supporting evidence only.

- **UI/layout** — re-run the SAME `browser_evaluate` measurement from phase 0 against the dev
  URL. Re-run the stress test; the fix must survive it. Capture a supporting screenshot.
- **Backend/logic** — re-run the phase-0 reproduction and show the OBSERVED output now matches
  expected: the value, the status code, the row count. Not just "tests pass".

**Lock it against regression (mandatory).** Convert the success predicate into a committed
automated test — a Playwright assertion for a layout invariant, a unit or integration test for
a logic predicate. Confirm it goes RED on the pre-fix code where feasible (stash the fix, run,
confirm fail, restore), then GREEN.

**Critical-path smoke test (mandatory).** Exercise the project's critical path end to end and
confirm it still works. A change can pass its own test and still break the money path.

**Page-content check (mandatory when `ui_change: true` and the repo is Next.js).** A
measurement proves the layout holds and a screenshot proves it renders; neither proves the
*words on the page* are still right. Run `route-map` scoped to the routes this run touched —
never the whole site:

```bash
node "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/route-map/scripts/route-check.mjs" "$PWD" --enumerate
```

Keep only routes whose page or component files appear in this run's diff, and check against a
`ROUTEMAP.md` holding just those rows. Exit `0` is the only pass; `1` lists every RED row and
blocks; `2` means the checker could not run, which is a flag, not a pass. Non-Next.js repos
skip and say so in one line — never record a skipped check as clean.

Not done until: success predicate met, stress test or repro survived, **regression test
committed and green**, critical path smoke-tested, full suite green.

The reasoning — root cause, what you rejected, the before→after numbers — goes in the COMMIT
MESSAGE, attached to the diff where `git blame` will find it. Do not also write it into a
changelog file: the old one hit 704 lines in a month, and a sampled entry shared 66 of its 72
distinctive words with its own commit.

## 7 — Summary

Run `/eli5` (Mode B) on the results and present that table FIRST. Then a technical table
`| Phase | What happened | Files changed | Tests |`, one row per phase actually run, citing
the brainstorm, mockup and test files each produced plus pass status.

## Memory checkpoint

Ask exactly once: **"Anything from this /build run worth saving to memory? Reply with the
fact or `skip`."** Content → create the fact file, append to the memory index. `skip` → end
silently.
