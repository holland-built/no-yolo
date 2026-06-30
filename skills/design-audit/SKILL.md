---
name: design-audit
description: Use this skill when the user types /design-audit, says 'audit this UI', 'review the design', 'find design problems', or 'what's wrong with this UI'. Audits the current UI across 5 lenses -> adversarial verification of every Critical -> ranked violations table + P0/P1/P2 plan -> eli5 summary. Then asks if you want to fix: yes triggers 10-mockup fix pipeline (same as /design) scoped to audit findings, you pick a variant, then builds and verifies.
user-invocable: true
argument-hint: "[surface to audit]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
---

# design-audit

Target: $ARGUMENTS

Audits your existing UI and optionally fixes it. Audit phase is always read-only. Fix phase
generates 10 mockups, you pick one, then builds against your confirmed choice.

## Step 0 — Detect project
```bash
head -20 CLAUDE.md 2>/dev/null
cat package.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('name','?'), d.get('description',''))" 2>/dev/null
```
State one line: `Project: [type] · stack: [X]`. Detect whether a brand DESIGN.md
(Awesome DESIGN.md 9-section format) is in use.

## Step 1 — 5 parallel lens agents
ONE parallel Agent call. Each returns `severity | rule | file:line | observed | expected`.
1. **Taste** — anti-slop fingerprint (FALLBACKS if sub-skill absent).
2. **Swiss** — grid / type scale / color count.
3. **UIwiki** — 20 rules scored.
4. **WCAG 2.1 AA** — contrast, focus-visible, keyboard, aria, reduced-motion.
5. **CSS health** — hardcoded values, magic numbers, inconsistent tokens.
If a brand DESIGN.md is in use, add a **6th lens**: compare the UI against that brand's
do's/don'ts and component states.

## Step 2 — Adversarial verify
Spawn an independent agent that challenges every **Critical** finding. Each Critical must be
confirmed with file:line evidence or downgraded. Record the verdict per finding.

## Step 3 — Output artifacts + fix gate

### Output artifacts
1. **Ranked violations table:** `| # | Lens | Finding | Severity | file:line |`
   (Critical / High / Medium / Low).
2. **Dependency-ordered implementation plan:** `| Priority | Change | Depends on | Scope (S/M/L) |`
   grouped P0 / P1 / P2.

Then run `/eli5` on the summary.

### Fix gate
After the eli5 summary, ask exactly:

**"Fix Critical + High? Generates 10 mockups, you pick one, then builds. (y/n)"**
- **n** -> done. Hand the P0/P1 plan to `/design` if you want a clean-sheet redesign instead.
- **y** -> proceed to Fix Flow below.

---

## Fix Flow (only runs when user answers y above)

Full mockup-first fix pipeline. Every step is mandatory — do not skip.

### F1 — Brand seed
Same as `/design` Step 0. Read CSS tokens, check Awesome DESIGN.md, write `.mockups/design-seed.md`.
The seed tells agents which audit findings are token-level (fixable by swap) vs structural
(require layout change). Note this distinction in the seed file.

### F2 — Taste direction
Same as `/design` Step 1. Invoke redesign-skill for direction. Use FALLBACKS if absent.

### F3 — 10 mockups
ONE parallel Agent call, `model: "opus"`. Same spec as `/design` Step 2 with one addition:

Each agent brief carries the full P0 findings list from Step 3:
> "The audit found these P0 issues: [list each P0 finding with file:line]. Your mockup MUST
> visually resolve all of them. This is not a redesign — your mockup should feel like an
> evolution of the current design that fixes the problems found, not a reinvention."

**v1–v8**: distinct paradigms (same paradigm list as `/design`).
**v9–v10**: WILD — alien layout paradigm, still must address P0 findings.

Every variant includes: light + dark sections, states strip (hover/focus/empty/error/loading),
2–3 annotation callouts at key decisions.

### F4 — Slop validate
Same as `/design` Step 3 validator. Minimum 6 survivors.

### F5 — Combined view + Chrome auto-open
Same as `/design` Step 3 combined view. 5 rows x 2 columns (light | dark).
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --window-size=1400,900 \
  --screenshot=".mockups/design-<slug>/all.png" \
  "file://$PWD/.mockups/design-<slug>/all.html"
open ".mockups/design-<slug>/all.html"
```

### F6 — AI recommendation
Spawn ONE scoring agent. Scores all 10 on Taste + Swiss + UIwiki (same rubric as `/design`).
**Recommendation reason must be grounded in audit findings:**
> "v6 — directly resolves the P0 contrast failures and type hierarchy issues flagged in the
> audit, and has the strongest Swiss grid discipline of the survivors."

Mark * winner in `all.html`. Show variant table with scores.

### F7 — You pick
**"Which variant? (confirm * vN / pick different vN / mix vA layout + vB colors / redo)"**
- `redo` -> regenerate F3 with a different set.
- **Do not write a single line of production code until you name a variant.**

### F8 — Opus plan
Spawn Opus agent to write `brainstorms/design-audit-<slug>-plan-<date>.md`. Plan must:
- List every P0 and P1 finding being addressed (from Step 3)
- Cite approved variant tokens as source of truth
- List every target file as "already exists — do NOT recreate: <path>"
- Order changes so structural fixes (layout) precede token fixes (color/type)

### F9 — Sonnet build
Dispatch Sonnet subagents per plan. Disjoint file clusters, no file overlap between agents.

### F10 — tsc + lint + build gate
Zero new errors before proceeding. If any errors -> fix before Playwright.

### F11 — Playwright + contrast recheck
`npx playwright test` smoke — load each changed surface, assert no console errors, toggle
dark mode. (Use CLI — NOT `ecc:playwright` MCP.)
WCAG AA contrast re-check on every changed surface — >= 4.5:1 for text.

### F12 — Re-audit changed files
Re-run Step 1 lenses on changed files only. Every P0 finding from the original audit must
show as resolved. If any P0 remains -> fix it before declaring done.

### F13 — eli5 summary
Run `/eli5` on: P0s resolved, P1s resolved, files changed, build status, contrast status.

---

## FALLBACKS
Same Taste / Swiss / UIwiki rule text as `/design`.
