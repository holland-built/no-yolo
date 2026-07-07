---
name: design
description: Use this skill when the user types /design, says 'design this', 'new design', 'redesign', 'fresh look', 'start over on the UI', 'mock this up', or 'show me design options'. Fresh generation only — never preserves the existing design. Pipeline: brand seed -> Taste generators -> 10 Opus mockups (8 distinct paradigms + 2 wild) -> slop validator -> AI picks best -> Chrome auto-opens -> you confirm or pick different -> Opus plan -> Sonnet build. Nothing builds before you confirm. Auto-redirects audit/review to /design-audit, existing-UI polish to /impeccable.
user-invocable: true
argument-hint: "[text | URL | screenshot | domain context] [--apply-spec <file>]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
---

# design

Target: $ARGUMENTS

Fresh generation. This skill **never preserves the existing design** — every mockup is a
clean-sheet take. Existing tokens are read only to build a ban list.

## Redirects (check first)
`/design` is the single entry point for all UI work — it routes to the right engine below.
A redirect means: invoke that skill now, in this same response. Never tell the user to type
a different command themselves.
- `$ARGUMENTS` contains `audit`, `review`, `analyze`, `what's wrong`, `find problems` ->
  invoke `/design-audit` now.
- `$ARGUMENTS` contains `polish`, `tighten`, `existing`, `impeccable`, `fix the design`,
  `clean up the ui` (and no BOLD-mode word below is also present) -> invoke `/impeccable` now.
  This is real-code polish over what's already built, not fresh generation — `/impeccable` runs
  Step 1's vendored files itself (see its own Scope note), you don't re-run them here. Never
  run both engines on the same request — they produce incompatible artifacts (throwaway
  mockup HTML vs live edits to real files) — but both read the same vendored rule files so
  their visual judgment stays in sync.
- `--apply-spec <file>` present -> jump straight to the APPLY-SPEC branch (skip Steps 0-4).
- Anything else -> run this skill's own pipeline (Steps 0-4 below), taste-skill-driven.

## BOLD mode
If `$ARGUMENTS` contains any of: `new`, `redesign`, `fresh`, `different`, `something new`,
`new look`, `start over`, `rethink` -> BOLD MODE on. Every mockup must be impossible to
mistake for an incremental refresh of the current UI. The validator (Step 3) also kills any
variant resembling the current design, not just generic slop.

## LIGHT + DARK rule
Every mockup HTML includes a fully realized light section AND dark section with a `<button>`
toggle switching `data-theme` on `<html>`. Both themes hand-tuned, not CSS inversion.

---

## Step 0 — Brand seed
```bash
SLUG=$(python3 -c "import json; print(json.load(open('package.json')).get('name','').replace('/','-').replace('@',''))" 2>/dev/null || basename "$PWD")
mkdir -p .mockups
head -20 CLAUDE.md 2>/dev/null
cat package.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('name','?'), d.get('description',''))" 2>/dev/null
```
1. Check for a matching brand in the Awesome DESIGN.md library (voltagent/Awesome-DESIGN.md,
   9-section DESIGN.md format). If a brand DESIGN.md exists in-repo or matches the product:
   pull the FULL system — agent prompt guide + layout principles + type hierarchy + component
   states + do's/don'ts.
2. If no brand match: token-hunt CSS extraction. If `$ARGUMENTS` has a reference URL, extract
   its palette/type/spacing tokens. Otherwise seed from Radix Colors (React) or Open Color.

Write the seed to `.mockups/design-seed.md`: palette hex, type families, spacing scale,
layout principles, component states, do's/don'ts. State one line summarizing the seed source.

## Step 1 — Taste generators
Vendored at `skills/design/vendor/taste-skill/` (real content, MIT-licensed from
Leonxlnx/taste-skill — see `vendor/taste-skill/SOURCE.md`). If the vendor dir is missing,
fall back to the FALLBACKS block below and skip straight to Step 2.

1. Read `vendor/taste-skill/taste-skill.md`. Apply **Section 0 (Brief Inference)**: state the
   one-line **Design Read** — page kind, audience, vibe, leaning design-system/aesthetic.
   Apply **Section 1 (Three Dials)**: set `DESIGN_VARIANCE` / `MOTION_INTENSITY` /
   `VISUAL_DENSITY` from the inference table (baseline 8/6/4 if nothing overrides). Apply
   **Section 2 (Brief -> Design System Map)**: if the brief matches a real design system
   (Fluent/Material/Carbon/Polaris/Atlassian/Primer/GOV.UK/USWDS/Radix/shadcn), name it and use
   the official package — do not hand-roll its CSS.
2. If a screenshot is provided -> read `vendor/taste-skill/image-to-code-skill.md` and follow
   it (generate reference image, analyze structure, translate faithfully).
3. Read `vendor/taste-skill/redesign-skill.md` to set mockup generation direction (six
   categories: typography, color/surfaces, layout, interactivity, content, components).

The Design Read line, the three dial values, and the design-system decision all feed the
Step 2 briefs alongside the six-category direction.

## Step 2 — 10 Opus mockups
ONE parallel Agent call, `model: "opus"`. Each writes `.mockups/design-<slug>/vN.html`:
self-contained, inline `<style>`, **no external deps**, `file://` openable, `<!-- VARIANT:
vN — paradigm -->` header. **Real data, not lorem ipsum.** Bake the Step 0 seed tokens
throughout.

**v1–v8**: each anchored to a DISTINCT paradigm — pick 8 from:
Terminal/CLI · Bloomberg data grid · editorial/magazine · bento grid · command palette ·
split-pane reference · single-column full-bleed · floating action panel · timeline · kanban.

**v9–v10**: WILD. Must use a completely alien layout paradigm — impossible to mistake for
a variation of v1–v8. Examples: physical-object skeuomorph, radial/circular nav, newspaper
broadsheet, game HUD, brutalist raw grid with zero decoration. Label each with `WILD` in
the header comment.

**Every variant must include:**
- Light + dark sections with toggle (LIGHT+DARK rule above)
- **States strip**: a thin labeled row at the bottom of the HTML showing all 5 interactive
  states as small labeled boxes: `hover` · `focus` · `empty` · `error` · `loading`. Each box
  shows the relevant component in that state. Real styled boxes, not placeholder text.
- **2–3 annotation callouts**: HTML comments placed inline at key design decisions:
  `<!-- ANNOTATION: [one sentence explaining this layout/hierarchy choice] -->`. Place at
  the most non-obvious decision points (why this column count, why this type scale, why this
  component placement).

Each brief carries: design seed + Design Read line + the three dial values + any named design
system from Step 1 + Taste/Swiss/UIwiki rule text (FALLBACKS if vendor absent) + the slop
reject list below + LIGHT+DARK rule. BOLD constraint added when BOLD MODE is on.

## Step 3 — Validator + combined view + AI pick

### Validator pass
Spawn a judge agent running Taste + Swiss + UIwiki lenses on all 10. Reject any variant that
hits the **slop reject list** and regenerate it (max 2 rounds, specific brief per reject):
> card grids · accordion-only · sidebar-nav + icon rows · gradient CTAs (blue->purple /
> teal->green) · rounded corners >8px everywhere · glassmorphism · sans-only type hierarchy ·
> hero + centered-CTA layout · shadcn/MUI/Tailwind-UI starter DNA · badge/pill stat rows ·
> progress bars everywhere · skeleton loaders · "Powered by" badges · hover scale transforms.
If BOLD MODE: also reject any variant that reads as a minor refresh of the current app.
Minimum 6 survivors required before proceeding.

### Combined view
Build `.mockups/design-<slug>/all.html` — layout: **5 rows x 2 columns**.
Each row = one variant pair: left column = light theme, right column = dark theme.
States strip and annotation callouts visible in both columns.
Sticky jump nav with v1–v10 anchors. Per-variant theme toggle preserved.

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --window-size=1400,900 \
  --screenshot=".mockups/design-<slug>/all.png" \
  "file://$PWD/.mockups/design-<slug>/all.html"
```
Show the screenshot inline.

### AI recommendation
Spawn ONE scoring agent. It reads all 10 variant HTML files and scores each on:
- Taste (anti-slop, typography, motion discipline) — 0–10
- Swiss (grid, type scale, color count, negative space) — 0–10
- UIwiki (20 rules, scored 1 each) — 0–20

Returns the winner variant number + a single sentence explaining why it won.
Update `all.html` to mark the winner with * in its section header.

Show this table:
```
| Variant | Paradigm | Score | Recommended |
|---------|----------|-------|-------------|
| v1      | Terminal/CLI | 34 | |
| v3      | Bloomberg grid | 41 | * "Strongest data-ink discipline and only variant with true asymmetric balance" |
```

### Chrome auto-open
```bash
open ".mockups/design-<slug>/all.html"
```
Opens immediately — you see all 10 before answering anything.

## HARD GATE — Step 4 (no code before this)
Ask: **"Which variant? (confirm * vN / pick different vN / mix vA layout + vB colors / redo)"**
- `redo` -> regenerate Step 2 with a different paradigm set.
- **Do not write a single line of production code until the user names a variant.**

## Step 5 — Implement
1. Extract approved tokens from the chosen mockup to `.mockups/design-<slug>/approved-tokens.md`.
2. Detect stack (package.json) and select component library:
   - React + Tailwind -> shadcn/ui + MagicUI + Aceternity UI + Mantine
   - Tailwind only -> DaisyUI + HyperUI
   - Vue -> Naive UI + PrimeVue
   - none -> warn, proceed without a library.
3. Spawn an Opus agent to write `brainstorms/design-<slug>-plan-<date>.md` (presentation
   layer only; cites approved-tokens.md as source of truth; lists target files as "already
   exists — do NOT recreate").
4. Dispatch Sonnet subagents to build the approved mockup against the plan. Disjoint file
   clusters, no overlap.
4.5. After all subagents complete, run tsc + lint + build (zero new errors) before the Playwright smoke. If any errors -> fix before proceeding.
5. `npx playwright test` smoke after build (load each changed surface, assert no console errors,
   toggle dark mode). Use CLI — NOT `ecc:playwright` MCP.
6. Run `/eli5` on the completed-work summary before presenting.

---

## APPLY-SPEC branch (`--apply-spec <file>`)
Skip Steps 0-4 entirely. The spec file is a DESIGN.md (or token doc).
1. Read the spec.
2. 8-dimension token audit of the current app: color, typography, spacing, radius, shadow/
   elevation, component states, layout grid, motion. Map current -> spec for each.
3. Palette/token swap: replace current values with spec values across CSS/theme files.
4. WCAG AA gate: every changed surface contrast >= 4.5:1 (text), focus-visible preserved.
5. Cleanup dead CSS left by the swap.
6. Build verify: tsc + lint + build green, then `npx playwright test` smoke. (CLI — NOT `ecc:playwright` MCP.)
7. `/eli5` summary.

---

## FALLBACKS (when Taste/Swiss/UIwiki sub-skills absent)
**Taste:** em-dash ban; no beige+brass default palette; no serif-as-default (no Fraunces/
Instrument_Serif); no three equal cards; no filler verbs / fake-perfect numbers / placeholder
brands; motion via Motion/GSAP/IntersectionObserver, never scroll listeners.
**Swiss:** strict grid, <=3 type sizes, <=3 colors, asymmetric balance, generous negative
space, function over decoration.
**UIwiki (20 rules):** hierarchy, contrast, alignment, proximity, consistency, affordance,
feedback, error prevention, recognition over recall, minimal load, progressive disclosure,
data-ink ratio, status colors, responsive, motion purpose, label clarity, empty states,
loading states, keyboard nav, touch targets.
