---
name: design
description: Use this skill when the user types /design, says 'design this', 'new design', 'redesign', 'fresh look', 'start over on the UI', 'mock this up', or 'show me design options'. Fresh generation only — never preserves the existing design. Pipeline: brand seed -> Taste generators -> 7 Opus mockups (distinct paradigms) -> slop validator -> HARD pick gate -> Opus plan -> Sonnet build. Nothing builds before the gate. Auto-redirects fix/patch to /impeccable and audit/review to /design-audit.
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
- `$ARGUMENTS` contains `fix`, `patch`, `tweak`, `adjust`, `polish`, `move`, `nudge` and
  names ONE component/area -> stop and run `/impeccable` instead.
- `$ARGUMENTS` contains `audit`, `review`, `analyze`, `what's wrong`, `find problems` ->
  stop and run `/design-audit` instead.
- `--apply-spec <file>` present -> jump straight to the APPLY-SPEC branch (skip Steps 0-4).

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
- If a screenshot is provided -> invoke Taste **image-to-code-skill** (generate reference
  image, analyze structure, translate faithfully).
- Invoke Taste **redesign-skill** to set mockup generation direction (six categories:
  typography, color/surfaces, layout, interactivity, content, components).
Both feed the Step 5 briefs. If Taste sub-skills are not installed, use the FALLBACKS block.

## Step 2 — 7 Opus mockups
ONE parallel Agent call, `model: "opus"`. Each writes `.mockups/design-<slug>/vN.html`:
self-contained, inline `<style>`, **no external deps**, `file://` openable, `<!-- VARIANT:
vN — paradigm -->` header. **Real data, not lorem ipsum.** Bake the Step 0 seed tokens
throughout. Each variant anchored to a DISTINCT paradigm — pick 7 from:
Terminal/CLI · Bloomberg data grid · editorial/magazine · bento grid · command palette ·
split-pane reference · single-column full-bleed · floating action panel · timeline · kanban.
Each brief carries: design seed + Taste/Swiss/UIwiki rule text (FALLBACKS if absent) + the
slop reject list below + LIGHT+DARK rule. BOLD constraint added when BOLD MODE is on.

## Step 3 — Validator pass
Spawn a judge agent running Taste + Swiss + UIwiki lenses on all 7. Reject any variant that
hits the **slop reject list** and regenerate it (max 2 rounds, specific brief per reject):
> card grids · accordion-only · sidebar-nav + icon rows · gradient CTAs (blue->purple /
> teal->green) · rounded corners >8px everywhere · glassmorphism · sans-only type hierarchy ·
> hero + centered-CTA layout · shadcn/MUI/Tailwind-UI starter DNA · badge/pill stat rows ·
> progress bars everywhere · skeleton loaders · "Powered by" badges · hover scale transforms.
If BOLD MODE: also reject any variant that reads as a minor refresh of the current app.

Build `.mockups/design-<slug>/all.html` — 14 sections (v1-light, v1-dark … v7-light,
v7-dark), sticky 14-anchor jump nav, per-variant theme toggle, ★ on the recommended variant.
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --window-size=1400,900 \
  --screenshot=".mockups/design-<slug>/all.png" \
  "file://$PWD/.mockups/design-<slug>/all.html"
open ".mockups/design-<slug>/all.html"
```
Show the screenshot inline.

## ⛔ HARD GATE — Step 4 (no code before this)
Print: `| Variant | Paradigm | One-line description | Recommended |`
Ask: **"Which variant? (v1–v7 / mix — name which / redo)"**
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
4.5. After all subagents complete, run tsc + lint + build (zero new errors) before the Playwright smoke. If any errors → fix before proceeding.
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
4. WCAG AA gate: every changed surface contrast ≥ 4.5:1 (text), focus-visible preserved.
5. Cleanup dead CSS left by the swap.
6. Build verify: tsc + lint + build green, then `npx playwright test` smoke. (CLI — NOT `ecc:playwright` MCP.)
7. `/eli5` summary.

---

## FALLBACKS (when Taste/Swiss/UIwiki sub-skills absent)
**Taste:** em-dash ban; no beige+brass default palette; no serif-as-default (no Fraunces/
Instrument_Serif); no three equal cards; no filler verbs / fake-perfect numbers / placeholder
brands; motion via Motion/GSAP/IntersectionObserver, never scroll listeners.
**Swiss:** strict grid, ≤3 type sizes, ≤3 colors, asymmetric balance, generous negative
space, function over decoration.
**UIwiki (20 rules):** hierarchy, contrast, alignment, proximity, consistency, affordance,
feedback, error prevention, recognition over recall, minimal load, progressive disclosure,
data-ink ratio, status colors, responsive, motion purpose, label clarity, empty states,
loading states, keyboard nav, touch targets.
