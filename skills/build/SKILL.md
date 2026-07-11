---
name: build
description: Use this skill when the user types /build, says 'build', or 'build this feature end to end'. Full feature pipeline: evidence → plan → Opus plan → approval gate → UI mockup gate → TDD → build → regression gate → prove.
user-invocable: true
argument-hint: "[describe the feature to build]"
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

**Agent rule:** Never write code inline. All planning → Opus agent. All implementation → Sonnet agent(s). Coordinator reads + dispatches only.

## Routing — pick the right tool BEFORE running the pipeline
- **Spatial/layout bug** (overlap, clip, truncation) → Phase 0A (Playwright DOM measurement). Trivial fix path if cause already measured.
- **Color/typography/token/spacing nits** → NOT /build. Use `/design-audit` to find issues or `/design-fast` to see options.
- **Visual/aesthetic redesign** → /build WITH the mockup gate.
- **Trivial fix** (1–2 files, cause already known) → fast path: phase 0 only → skip plan → approve → build.
- **Code quality / dead code / YAGNI audit** → STOP, run `/review` instead.
- **Genuine multi-step feature** → full pipeline below.

State which path you're taking in one line before proceeding.

## Stack — auto-detect (do this FIRST, silently)
This skill is project-agnostic. Before phase 0, detect the project's commands and record them for use throughout the run:
- **Dev server URL** — the running app (check `package.json` scripts / `README` / a `.dev`/`dev` skill; common: `http://localhost:3001`, `:8080`, `:3000`).
- **Test command** — e.g. `npm test -- --watch=false`, `python -m pytest -v`, `pytest test_regression.py -v`.
- **Build/typecheck command** — e.g. `npm run build`, `tsc --noEmit`, or none.
- **Hotpatch** (if containerized) — e.g. `docker cp <file> <container>:/app/<file> && docker restart <container>`; otherwise changes go live via dev server.
- **Primary source files** — single-file SPA (`index.html`) vs component tree (`src/**`).
- **Golden-master tests to NOT touch** — note any (e.g. `sizingGoldenMaster.test.ts`); write new behavior tests separately.
- **Knowledge-graph tooling** — note if the project has one (e.g. `graphify` + `graphify-out/`) and its update command (e.g. `graphify update .`).
- **Critical path** — the project's money path / core user flow that must never break (e.g. your app's primary user flow: checkout → payment → confirmation). Note how to exercise it.
- **Latest-stable gate** (greenfield / new core dep) — when scaffolding a NEW project or adding a core dependency (runtime, framework, language, core lib), do NOT pin the version from memory (it lags — this is how a new MCP got React 18 when 19 was current). Query the registry for the current stable version and pin that, per **CORE_RULES.md Rule 9** (`npm view <pkg> version`, `pip index versions <pkg>`, etc.; stable tag only, compat beat if the newest major isn't supported yet). Applies to greenfield with no existing surface too.
If a CLAUDE.md or project skill names these, use those values verbatim. State the detected stack in one line before proceeding.

`<slug>` = kebab of feature. `<date>` = today.

## 0 — Evidence (BEFORE plan — HARD gate for any bug / change to existing code)
**The bug is not where the symptom shows — it's where the measurement breaks.** Most multi-day loops come from fixing the symptom's location, not the cause's. This phase gathers FACTS so Opus plans against reality, not the user's words. Skip ONLY for greenfield with no existing surface.

Pick the evidence type by task:

**A. UI / layout / "it looks wrong"** → Open the surface in Playwright at the failing viewport; `browser_evaluate` to dump LIVE DOM numbers (`clientWidth` vs `scrollWidth`, computed `display`/`overflow`/`position`, every element wider/taller than its parent). Walk UP from the symptom to the FIRST ancestor where the measurement breaks — that ancestor is the cause. State it as **"X breaks because property Y = Z (measured)"**. **Stress-test:** inject worst-case content (64-char unbreakable string), re-measure; if it still breaks the diagnosis is wrong — redo.

**B. Backend / logic / data** → gather the equivalent fact pack: `graphify query`/`path`/`explain` to map the real call graph; read the actual function + its callers; reproduce with a failing test or a logged value (the OBSERVED wrong output vs expected); inspect the schema/types involved. State the cause as **"function/path X produces Y because Z (observed at file:line)"** — never "probably" or "should be".

**C. Either** → produce a **minimal reproduction** before any fix. A bug you can't reproduce on demand, you can't prove fixed.

Checkpoint to `brainstorms/<slug>-diagnosis-<date>.md`: reproduction steps, the measured/observed numbers, the offending element/function (`file:line`), the single root cause, the stress-test/repro result, and the **falsifiable success predicate** (the exact measurable condition that will be true when fixed — e.g. `scrollW <= clientW`, `fn(x) === expected`, `endpoint returns 200 with N rows`).

Do NOT plan a fix whose cause you have not located with evidence. Grill-me and Opus both consume this file.

## 1 — Grill-me (BEFORE any planning)
Never plan from the raw description. Interview one question at a time using the `AskUserQuestion` tool — present 3–4 clickable options with the recommended answer placed **in the middle** of the list (not first, not last). Walk every branch. Checkpoint each answer to `brainstorms/<slug>-<date>.md` (Decisions / Open flags / Q&A log). Stop when all branches resolved or user says "done".

## 2 — Opus plan
Spawn ONE `Agent` (model: opus) with the full plan transcript **AND the phase-0 diagnosis** as context. Tell Opus the located root cause is ground truth — fix at the SOURCE, not with a stack of leaf-level patches. The plan MUST contain:
- **Root cause** restated as `X breaks because Y = Z (file:line)` + the single source change that addresses it
- **Success predicate** — the falsifiable, measurable condition that proves done (carried from phase 0). Every plan ends in a number or a boolean, never "should work"
- **Target file list**, each with an "already exists — do NOT recreate" note
- **Blast radius** — an explicit "do NOT touch" list: files/functions/behaviors adjacent to the change that must stay byte-identical. Names the surgical boundary so Sonnet can't drift
- **Regression pre-mortem** — which existing tests/behaviors this change could plausibly break, named BEFORE coding, so phase 5.5 is targeted not hopeful
- **Ordered steps**, sequenced smallest-reversible-first (each independently verifiable), ~300-word cap per downstream subagent
- flag: `ui_change: true/false`

Then a **self-check pass** (same Opus agent, second turn): "What in this plan is assumed rather than grounded in a file:line? What's the strongest reason this fix is wrong or incomplete? What did it miss?" Fold the answers back in or note why dismissed.

Reject and re-plan if: the cause isn't grounded in evidence, there's no measurable success predicate, the blast radius is unbounded, or any claim cites an API/file that wasn't verified to exist. Save to `brainstorms/<slug>-plan-<date>.md`.

## 3 — Approval gate (HARD)
Show the plan. Then stop and ask exactly: **"Approve this plan or redirect?"**
Do NOT write code until the user says yes/go/approved. If they redirect, loop back to phase 1 or 2.

## 3.5 — UI mockup gate (ONLY if ui_change: true)
Skip entirely for backend-only changes.

**Before building:** Check for a persisted design system first, then fall back to CSS tokens:

```bash
[ -f design-system/MASTER.md ] && echo "MASTER_FOUND" || echo "NO_MASTER"
```

- **If `design-system/MASTER.md` exists** (written by `/ui-ux --persist`): read it — use its color palette, typography, spacing scale, and layout rules as hard constraints for all 10 variants. Print: `Using design system from design-system/MASTER.md`.
- **If no MASTER.md**: extract tokens from the project's CSS (`:root` variables, font-family declarations, color palette, spacing scale).

Either way, every variant MUST use these tokens verbatim — no made-up hex codes or font names.

### Step A — Generate 10 variants

Build **exactly 10 variants** as individual files `.mockups/<slug>/<slug>-v1.html` … `v10.html` (fan out in ONE parallel call):
- **v1–v7**: a range from conservative to polished, all using real design tokens. Each must use a DISTINCT layout paradigm — not just the same card grid with different spacing.
- **v8–v10**: WILDLY different designs — completely different layout paradigm, spatial arrangement, or visual language. Examples: command-line terminal aesthetic, full-bleed hero with bold type, data-dense Bloomberg grid, floating action panel, bento-grid, magazine editorial. These must look like a different product team designed them — NOT a card-grid or accordion variation.

### Step B — Slop judge pass (HARD gate — minimum 6 survivors required)

After all 10 are built, spawn ONE judge agent with all 10 HTML files. Instructions:
> "You are an adversarial design critic. Read each variant's HTML. Reject any variant that matches ANY pattern in the slop fingerprint list below. Also reject any variant whose layout is functionally identical to another variant already in the list (deduplicate). Return the survivors with a one-line reason each survived."

**Slop fingerprint — instant reject if ANY of these match:**
- Card grid as primary layout (3+ column card deck, the same `.card` box repeated N times with slightly different content)
- Accordion-only pattern with no other structural differentiation (all groups collapsed behind a chevron, nothing else going on)
- Floating white/dark cards on a slightly different background as the only visual device
- Looks like it could be a Tailwind UI, shadcn, or Material UI starter template
- Blue, purple, or teal as the ONLY accent color with zero typographic contrast
- Rounded corners (>8px) as the primary design expression
- Sans-serif body with no typographic hierarchy beyond size
- Sidebar nav with icon + label rows as the page's structural feature
- Progress bars or pill badges as the primary data visualization
- Hollow outline icons as the only iconography
- Gradient CTA buttons (blue-to-purple, teal-to-green, etc.)
- Hero section with centered headline + subtext + CTA button
- "Glassmorphism" blur panels as decoration
- Animations that serve no information purpose (fade-in on scroll, entrance bounces)
- Footer with 4 columns of links
- "Trusted by X companies" logo strip / social proof row
- Testimonial cards with avatar + star rating + quote
- Pricing table with exactly 3 tiers (Starter / Pro / Enterprise)
- "Get started free" or "Start for free" as primary CTA copy
- Dark mode that's just navy (#1a1a2e) — not true dark
- Sticky nav that changes opacity or color on scroll
- "How it works" section with numbered circle steps
- Empty state with centered illustration + "No [items] yet" text
- Search bar as a full-width rounded pill
- Feature grid: icon + title + 2-line description, 3 equal columns
- Full-width image banner with dark overlay + white centered headline
- Skeleton loader placeholders pulsing gray
- Avatar overlap stack showing "+3 users" / member count
- Dropdown menus: white background + subtle box-shadow only
- Tag/chip badges with colored backgrounds as only category visualization
- Table rows that highlight on hover with light blue only
- Success toast: bottom-right corner, green checkmark icon
- Monochrome icon set where every icon has identical visual weight
- "Learn more →" as generic link text
- Modal or drawer sliding in from the right with an × close button

If **fewer than 6 variants survive**, respawn the rejected ones with instruction: "Your last concept matched [specific slop pattern]. Go structurally different — change the layout paradigm entirely, not just the color."

Only survivors proceed to the combined view.

### Step C — Combined view + screenshot

Build ONE combined page `.mockups/<slug>/<slug>-all.html` — survivors only, stacked vertically. Each section: variant label + one-line description + iframe. Mark recommended with ★.

**MANDATORY — do both:**
- `open ".mockups/<slug>/<slug>-all.html"`
- `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --window-size=1400,900 --screenshot=.mockups/<slug>/<slug>-all.png "file://$PWD/.mockups/<slug>/<slug>-all.html"`

Show screenshot inline. Output variant table:

| Variant | Description | Survived judge? | Pick |
|---|---|---|---|
| vN | paradigm description | Yes — reason | |
| vN | wildly different paradigm | Yes — reason | ★ recommended |

Stop and ask: **"Which mockup variant? (or redirect)"**
Do NOT proceed until user names a variant. Lock the chosen variant — Sonnet builds to match it exactly.
Mockup files stay in `mockups/<slug>/` until after phase 6; delete only after prove passes.

## 4 — TDD
Per behavior: write ONE failing test → run the detected test command (scoped to the relevant file when supported) → confirm RED → minimum code to pass → confirm GREEN → repeat. No batching all tests first. Do NOT target any golden-master test noted during stack detection — write new behavior tests in a separate test file alongside the module.

## 5 — Sonnet build

**Cap: max 5 agents at once.** If plan has >5 independent steps, batch into rounds of 5; wait for each round before starting the next (sequential deps must respect ordering).

**Before dispatching ANY agent** — write a per-agent spec covering:
- Target file (absolute path)
- Exact change to make (quote plan step + plan context)
- Functions/components adjacent to the edit that must NOT be touched
- `Already exists — do NOT recreate: <file>` note
- If ui_change: which mockup variant section/element to match exactly

Fan out all agents in one parallel call (never one-at-a-time). Every agent MUST:
- read its target file + direct imports before editing
- include the explicit **"already exists — do NOT recreate: <file>"** section in its prompt
- cap output ~300 words
- if ui_change: match the approved mockup variant exactly

After all agents complete: if any used `isolation: worktree`, merge each branch into the working
branch, confirm merged (`git merge-base --is-ancestor <sha> HEAD`), then clean up —
`git worktree remove` each `.claude/worktrees/agent-*` dir + `git branch -D` its branch.
Run the detected build/typecheck command (if any) to catch errors before testing. If the project is containerized, hotpatch with the detected command. If the project has knowledge-graph tooling, refresh it now (e.g. `graphify update .` — AST-only, no API cost) so the next /build run's Phase 0 evidence reads from an accurate graph, not a stale one.

## 5.5 — Regression gate + fix loop (HARD)
After build passes, run the full test suite (detected test command).
If ANY test fails → enter fix loop. Repeat until green:

1. Spawn `Agent` (model: opus) with: failing test output + full diff of changes so far. It produces a fix plan targeting only the broken behavior. Save to `brainstorms/<slug>-fix-<N>-<date>.md`.
2. Spawn `Agent` (model: sonnet) per fix step (fan out independent steps). Every dispatch MUST read target file before editing + include "already exists — do NOT recreate" note.
3. Hotpatch if needed; re-run the full test suite.
4. If still failing → increment N, loop back to step 1. Cap at 3 iterations. If still red after 3 → stop and surface to user: "3 fix attempts failed. Paste output to continue."

Do NOT proceed to phase 6 with a red suite or failing build.

## 5.6 — Quality gates (after suite green, before prove)
Run the ALWAYS gates on every /build run; add CONDITIONAL gates only when the diff touches the named surface. Fan the agent-based gates out in ONE parallel call to keep it fast. Any gate that finds a real issue → fix it (back to phase 5 build) or explicitly triage with reason before proceeding.

**ALWAYS:**
- **Lint + typecheck** — run the detected linter + type checker (e.g. `eslint`, `tsc --noEmit` / `npm run build`). Zero new errors. Warnings triaged.
- **Duplicate / recreate scan** — for every NEW symbol (function, component, hook, type, util) the build introduced, grep the tree for an existing one with the same/similar name or role. If a sibling already does it, STOP — reuse it, don't add a twin. (This is the per-run enforcement of the "already exists — do NOT recreate" rule.)
- **Secret scan** — grep the diff for keys/tokens/passwords/connection strings (`gitleaks` if available, else pattern grep for `sk-`, `api_key`, `AKIA`, `postgres://`, etc.). NOTHING secret enters a commit.
- **Reviewer-agent pass** — spawn one `Agent` (code-reviewer or `cavecrew-reviewer`) on the diff. Severity-tagged findings only; resolve or triage each before commit.

**CONDITIONAL:**
- **Security review** — IF the diff touches auth, API routes, secrets/env, DB queries, or user input → spawn `security-auditor` on those files. Check authz, injection, secret handling, input validation.
- **Accessibility** — IF `ui_change: true` → run the a11y check (`accessibility-tester` / axe): keyboard reachability, roles/aria, contrast, focus order. Matches the project's keyboard-first / AA bar.
- **Perf** — IF the change touches a hot path (sizing calc, large list/table render, a tight loop) → measure before/after (render time, query count, bundle delta) and confirm no regression.
- **Code health** — IF the diff adds ≥3 new functions/components OR the feature is a major refactor → run `/review` on the changed paths. Fallow catches dead exports and duplication; trim catches YAGNI in the new code before it ships.

Do NOT proceed to phase 6 with an unresolved gate.

## 6 — Prove (mandatory before done — NUMERIC, not visual)
Confirm the phase-0/phase-2 **success predicate** holds against reality — the metric is the gate, screenshots/prose are supporting evidence only:
- **UI/layout:** re-run the SAME `browser_evaluate` measurement from phase 0 against the dev URL (e.g. `scrollW <= clientW`, `0 overflowing elements`). Re-run the stress test (inject worst-case content, re-measure) — the fix must survive it. Capture a supporting screenshot.
- **Backend/logic:** re-run the reproduction from phase 0 and show the OBSERVED output now matches expected (the value, the status code, the row count) — not just "tests pass".

**Lock it against regression (mandatory):** convert the success predicate into a committed automated test — a Playwright assertion for the measured layout invariant, or a unit/integration test for the logic predicate. The bug that took this long to find must never silently return. Add it to the suite; confirm it goes RED on the pre-fix code (git stash the fix, run, confirm fail, restore) when feasible, then GREEN.

**Critical-path smoke test (mandatory):** before declaring done, exercise the project's critical path end to end (detected during stack setup — e.g. your app's primary user flow: checkout → payment → confirmation) and confirm it still works. A change can pass its own test yet break the money path; this catches that before a customer does. Drive it in the browser (Playwright) or via the path's API/CLI; show the observed result.

Then append to `docs/DAILY_CHANGELOG.md` under `## <date> — <feature>` a table: `File | Line(s) | Change`, citing before→after numbers.

Task is NOT done until: success predicate met + stress test/repro survived + **regression test committed and green** + **critical path smoke-tested** + changelog appended + full suite green.

## 7 — Summary
Print a markdown table summarizing everything completed this /build run:

| Phase | What happened | Files changed | Tests |
|---|---|---|---|
| Evidence | Reproduction + located root cause (file:line) + success predicate | `brainstorms/<slug>-diagnosis-<date>.md` | — |
| Grill-me | Key decisions made | `brainstorms/<slug>-<date>.md` | — |
| Opus plan | N steps planned | `brainstorms/<slug>-plan-<date>.md` | — |
| UI mockups | Variant vN approved / skipped | `.mockups/<slug>/` or n/a | — |
| TDD | N behaviors, N tests written | list test files | N green |
| Sonnet build | N agents, N files edited | list each file | — |
| Fix loop | N iterations / not needed | list files if any | — |
| Quality gates | lint/typecheck + dup-scan + secret-scan + review (+ security/a11y/perf if triggered) | — | clean / triaged |
| Prove | success predicate met + stress/repro survived + regression test committed + critical path smoke-tested | test file + `docs/DAILY_CHANGELOG.md` | all green |

## Memory Checkpoint

After the build phase completes, ask exactly once:

> **Anything from this /build run worth saving to memory?** A non-obvious decision, a surprise/gotcha, or a reusable pattern. Reply with the fact or type `skip`.

If user replies with content: create `~/.claude-work/projects/-Users-sholland/memory/facts/<slug>-<date>.md` (same format as build-feature checkpoint). Append line to MEMORY.md index. Tell user to run `/memory-compile`. If `skip` → end silently.
