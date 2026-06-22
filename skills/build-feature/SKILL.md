---
name: build-feature
description: Build an already-approved feature plan — UI mockup gate → TDD → Sonnet build → regression gate → quality gates → prove → summary. Requires an approved plan from /plan-feature. Never re-plans. Activate on "/build-feature", "build the plan".
user-invocable: true
argument-hint: "[slug from /plan-feature output, or path to plan file]"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Agent
---

**Agent rule:** Never write code inline. All implementation → Sonnet agent(s). Independent steps always fan out concurrently. Coordinator reads + dispatches only.

**Uncertainty rule:** At any phase, if intent is unclear — stop. Ask the question. Do not guess or proceed.

## Plan Detection (FIRST — before any build phase)

1. If `$ARGUMENTS` is a path to an existing file → use it as the plan file. Else treat `$ARGUMENTS` as `<slug>`.
2. Resolve plan file: `ls brainstorms/<slug>-plan-*.md` (use newest if multiple). If no slug given, glob `brainstorms/*-plan-*.md` and pick newest.
3. **Fail gracefully:** if no plan file found → stop: *"No approved plan found for '<slug>'. Run `/plan-feature <feature-description>` first."* Do nothing else.
4. Read the plan file. Verify it contains `## HANDOFF` with `status: approved`. If missing or status is not `approved` → stop: *"Plan exists but is not yet approved. Run `/plan-feature` and approve the plan first."*
5. Extract from the HANDOFF block: `slug`, `date`, `ui_change: true/false`.
6. Re-run stack detection (fresh session — detect dev server URL, test command, build command, hotpatch, source files, golden-master tests, knowledge-graph tooling, critical path). State detected stack in one line.
7. Do NOT re-run grill-me. Do NOT re-plan. The plan file is ground truth.

## 3.5 — UI mockup gate (ONLY if ui_change: true from plan)
Skip entirely for backend-only changes.

**Before building:** Extract the app's real design tokens from the project's CSS (`:root` variables, font-family declarations, color palette, spacing scale). Every variant MUST use these tokens verbatim — no made-up hex codes or font names.

### Step A — Generate 10 variants

Build **exactly 10 variants** as individual files `.mockups/<slug>/<slug>-v1.html` … `v10.html` (fan out in ONE parallel call):
- **v1–v7**: a range from conservative to polished, all using real design tokens. Each must use a DISTINCT layout paradigm — not just the same card grid with different spacing.
- **v8–v10**: WILDLY different designs — completely different layout paradigm, spatial arrangement, or visual language. Examples: command-line terminal aesthetic, full-bleed hero with bold type, data-dense Bloomberg grid, floating action panel, bento-grid, magazine editorial. These must look like a different product team designed them — NOT a card-grid or accordion variation.

### Step B — Slop judge pass (HARD gate — minimum 6 survivors required)

After all 10 are built, spawn ONE judge agent with all 10 HTML files. Instructions:
> "You are an adversarial design critic. Read each variant's HTML. Reject any variant that matches ANY pattern in the slop fingerprint list below. Also reject any variant whose layout is functionally identical to another variant already in the list (deduplicate). Return the survivors with a one-line reason each survived."

**Slop fingerprint — instant reject if ANY of these match:**
- Card grid as primary layout (3+ column card deck, the same `.card` box repeated N times with slightly different content)
- Accordion-only pattern with no other structural differentiation
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

**Cap: max 5 agents at once.** If plan has >5 independent steps, batch into rounds of 5; wait for each round before starting the next.

**Before dispatching ANY agent** — write a per-agent spec covering:
- Target file (absolute path)
- Exact change to make (quote plan step + grill-me context)
- Functions/components adjacent to the edit that must NOT be touched
- `Already exists — do NOT recreate: <file>` note
- If ui_change: which mockup variant section/element to match exactly

Fan out all agents in one parallel call (never one-at-a-time). Every agent MUST:
- read its target file + direct imports before editing
- include the explicit **"already exists — do NOT recreate: <file>"** section in its prompt
- cap output ~300 words
- if ui_change: match the approved mockup variant exactly

After all agents complete: run the detected build/typecheck command (if any) to catch errors before testing. If the project is containerized, hotpatch with the detected command. If the project has knowledge-graph tooling, refresh it now so the next run's evidence reads from an accurate graph.

## 5.5 — Regression gate + fix loop (HARD)
After build passes, run the full test suite (detected test command).
If ANY test fails → enter fix loop. Repeat until green:

1. Spawn `Agent` (model: opus) with: failing test output + full diff of changes so far. It produces a fix plan targeting only the broken behavior. Save to `brainstorms/<slug>-fix-<N>-<date>.md`.
2. Spawn `Agent` (model: sonnet) per fix step (fan out independent steps). Every dispatch MUST read target file before editing + include "already exists — do NOT recreate" note.
3. Hotpatch if needed; re-run the full test suite.
4. If still failing → increment N, loop back to step 1. Cap at 3 iterations. If still red after 3 → stop and surface to user: "3 fix attempts failed. Paste output to continue."

Do NOT proceed to phase 6 with a red suite or failing build.

## 5.6 — Quality gates (after suite green, before prove)
Run the ALWAYS gates on every run; add CONDITIONAL gates only when the diff touches the named surface. Fan the agent-based gates out in ONE parallel call.

**ALWAYS:**
- **Lint + typecheck** — run the detected linter + type checker. Zero new errors. Warnings triaged.
- **Duplicate / recreate scan** — for every NEW symbol the build introduced, grep the tree for an existing one with the same/similar name or role. If a sibling already does it, STOP — reuse it, don't add a twin.
- **Secret scan** — grep the diff for keys/tokens/passwords/connection strings. NOTHING secret enters a commit.
- **Reviewer-agent pass** — spawn one `Agent` (code-reviewer or `cavecrew-reviewer`) on the diff. Severity-tagged findings only; resolve or triage each before commit.

**CONDITIONAL:**
- **Security review** — IF the diff touches auth, API routes, secrets/env, DB queries, or user input → spawn `security-auditor` on those files.
- **Accessibility** — IF `ui_change: true` → run the a11y check: keyboard reachability, roles/aria, contrast, focus order.
- **Perf** — IF the change touches a hot path → measure before/after and confirm no regression.
- **Code health** — IF the diff adds ≥3 new functions/components OR is a major refactor → run `/code-health` on the changed paths.

Do NOT proceed to phase 6 with an unresolved gate.

## 6 — Prove (mandatory before done — NUMERIC, not visual)
Confirm the plan's **success predicate** holds against reality — the metric is the gate, screenshots/prose are supporting evidence only:
- **UI/layout:** re-run the SAME `browser_evaluate` measurement from phase 0 against the dev URL. Re-run the stress test — the fix must survive it. Capture a supporting screenshot.
- **Backend/logic:** re-run the reproduction from phase 0 and show the OBSERVED output now matches expected.

**Lock it against regression (mandatory):** convert the success predicate into a committed automated test. The bug that took this long to find must never silently return. Add it to the suite; confirm it goes RED on the pre-fix code when feasible, then GREEN.

**Critical-path smoke test (mandatory):** before declaring done, exercise the project's critical path end to end (detected during stack setup) and confirm it still works.

Then append to `DAILY_CHANGELOG.md` under `## <date> — <feature>` a table: `File | Line(s) | Change`, citing before→after numbers.

Task is NOT done until: success predicate met + stress test/repro survived + **regression test committed and green** + **critical path smoke-tested** + changelog appended + full suite green.

## 7 — Summary
Print a markdown table summarizing everything completed this build run:

| Phase | What happened | Files changed | Tests |
|---|---|---|---|
| Plan loaded | slug, date, ui_change value | `brainstorms/<slug>-plan-<date>.md` | — |
| Stack detect | detected commands | — | — |
| UI mockups | Variant vN approved / skipped | `.mockups/<slug>/` or n/a | — |
| TDD | N behaviors, N tests written | list test files | N green |
| Sonnet build | N agents, N files edited | list each file | — |
| Fix loop | N iterations / not needed | list files if any | — |
| Quality gates | lint/typecheck + dup-scan + secret-scan + review | — | clean / triaged |
| Prove | success predicate met + regression test committed + critical path smoke-tested | test file + `DAILY_CHANGELOG.md` | all green |

## 8 — Memory Checkpoint

After the Phase 7 summary table, ask exactly once:

> **Anything from this build worth saving to memory?** A non-obvious decision, a surprise/gotcha, or a reusable pattern. Reply with the fact or type `skip`.

If the user replies with content (not `skip` or empty):
1. Create `~/.claude-work/projects/-Users-sholland/memory/facts/<slug>-<date>.md` with:
```markdown
---
name: <slug>-<date>
description: <one-line summary of the fact>
metadata:
  type: project
---

<user's fact text>

**Why:** Captured after build-feature run for <slug> on <date>.
**How to apply:** <brief note on when this matters>
```
2. Append one line to `~/.claude-work/projects/-Users-sholland/memory/MEMORY.md`:
   `- [<slug> build learnings](<slug>-<date>.md) — <one-line summary>`
3. Tell user: "Saved. Run `/memory-compile` to apply."

If `skip` or no reply → end silently.
