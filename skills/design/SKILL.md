---
name: design
description: Use this skill when the user types /design, says 'design this', 'new design', 'redesign', 'fresh look', 'start over on the UI', 'mock this up', or 'show me design options'. Fresh generation only — never preserves the existing design. Pipeline: brand seed -> Taste generators -> 10 Opus mockups (8 distinct paradigms + 2 wild) -> slop validator -> AI picks best -> Chrome auto-opens -> you confirm or pick different -> Opus plan -> Sonnet build. Nothing builds before you confirm. Auto-redirects audit/review to /design-audit, existing-UI polish to the impeccable plugin. Second mode — component-pull: also fires on natural language like 'put a button here', 'add a chat box', 'drop in a card', or 'add a component'; in a React project it pulls a finished, project-themed component from Meta's open-source Astryx design system instead of hand-building it (React-only; falls back to normal /design otherwise).
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

## Mode select (route first)
Decide the mode from `$ARGUMENTS` before anything else:
- Phrasing like **"put a <component> here"**, **"add a button"**, **"add a chat box"**,
  **"add a card"**, **"drop in a component"**, **"add a component"** (naming a single UI piece
  to place into an app you are already building) -> **COMPONENT-PULL MODE** (section below).
  Skip the fresh-gen pipeline entirely.
- Everything else (`design this`, `new design`, `redesign`, `mock this up`, a URL, a
  screenshot, `--apply-spec`) -> fall through to `## Redirects` and the fresh-gen pipeline
  (Steps 0-5) unchanged.
- Ambiguous ("update the button" could be polish) -> the Redirects block still owns
  polish/edit/tweak wording; only the additive "add / put / drop-in a NEW component" phrasing
  routes here.

## Redirects (check first)
`/design` is the single entry point for all UI work — it routes to the right engine below.
A redirect means: invoke that skill now, in this same response. Never tell the user to type
a different command themselves.
- `$ARGUMENTS` contains `audit`, `review`, `analyze`, `what's wrong`, `find problems` ->
  invoke `/design-audit` now.
- `$ARGUMENTS` contains `polish`, `tighten`, `existing`, `impeccable`, `fix the design`,
  `clean up the ui`, `update`, `edit`, `change`, `tweak`, `adjust` (and no BOLD-mode word below
  is also present) -> invoke `impeccable:impeccable`
  now (the installed plugin — `/plugin marketplace add pbakaus/impeccable` if not present).
  This is real-code polish over what's already built, not fresh generation. It's an independent
  tool with its own rules, not something that shares this skill's vendored taste-skill files —
  never run both engines on the same request regardless, since they produce incompatible
  artifacts (throwaway mockup HTML vs live edits to real files).
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

## COMPONENT-PULL MODE (Astryx)
Additive second mode. Reached only from **Mode select** on "add/put/drop-in a <component>"
phrasing. The fresh-gen pipeline (Steps 0-5) is untouched and does not run here. Everything
below is discovered **per project** — never hardcode any project's paths.

**What Astryx is:** Meta's open-source React design system (`github.com/facebook/astryx`, MIT,
150+ finished accessible components — buttons, chat box, hover cards, feed scroll). Drop-in:
its docs say *"the simplest setup is a few CSS imports plus a theme provider — no build plugin,
no PostCSS or Babel config"* and *"override with `className` using Tailwind, CSS modules, or
plain CSS."* Themed purely via **CSS custom properties**, so it coexists with Tailwind/Radix/
shadcn. React-only.

### 1. Detect React (guard — STOP-style, never crash)
Read the current project's `package.json` (or a `frontend/`/`web/`/`app/` subdir's) and check
for `react` in dependencies. If **not** React: do NOT use Astryx. Tell the user
*"This isn't a React project — Astryx only works in React,"* then fall back to `/design`'s
normal behavior (route to `## Redirects` / fresh-gen). Do not proceed past this step.

### 2. Detect the project's color/design source (generically)
Look in this order; use whatever exists first — this is how the pulled component gets painted
to match the project:
1. `COLOR_CONTRACT.md`
2. `DESIGN.md`
3. a Tailwind theme (`tailwind.config.{js,ts,cjs,mjs}` -> `theme.extend.colors`)
4. CSS custom properties in the global stylesheet (`:root { --... }` in `globals.css`/`app.css`/
   `index.css`).
Extract palette + radius + type tokens. Never assume a filename — glob and use what's there.

### 3. Detect the existing component library
From `package.json`: Radix (`@radix-ui/*`), shadcn (`components.json` present), MUI (`@mui/*`),
or none. Feeds the which-source rule (step 6).

### 4. Ensure Astryx is installed in THIS project
If `@astryxdesign/core` is absent from the project's `package.json`: detect the package manager
from the lockfile (`pnpm-lock.yaml`->pnpm, `yarn.lock`->yarn, else `package-lock.json`->npm), tell
the user you are adding the dependency, then run **in that project dir** (npm shown; swap the
verb for the detected PM):
`npm install @astryxdesign/core @astryxdesign/theme-neutral` and
`npm install -D @astryxdesign/cli`.
**Never install globally.** If install fails (offline / registry / peer-dep conflict), STOP and
report — do not hand-build a substitute silently.

### 5. Pull + theme + place
1. Pull the requested finished component from Astryx (the chat box, hover card, button, etc.).
2. Map Astryx's CSS-custom-property tokens to the project's detected colors from step 2 (define
   the `--astryx-*` / theme vars against the project's palette — do not ship Astryx's default
   neutral theme). Result: Facebook-built, **project-colored — not looking like Facebook.**
3. Place the component in the project's conventional location (mirror where sibling components
   live — `src/components/...`, `app/...`, etc.; discover, don't assume).
4. Where a per-instance tweak is needed, override with the project's own styling via `className`
   (its Tailwind / CSS modules / plain CSS) — the drop-in override Astryx documents.

### 6. Which-source rule (prevent visual drift)
If the project already has a component lib (Radix/shadcn/MUI): use **Astryx for the COMPLEX,
high-polish pieces** (chat box, rich hover cards, feed-style scroll) where hand-building costs
days; **keep the existing lib for the simple pieces** (plain buttons, inputs) so two buttons
don't end up looking different. Always theme the Astryx component to the project's contract
(step 2). State which rule you applied in your summary.

### 7. Reuse gate + verify (reuse Step 4.6 spirit + the tsc/lint/build/playwright discipline)
- **Reuse gate (HARD, mirrors Step 4.6):** before placing, grep the tree for an existing
  component with the same/similar name or role. A sibling already doing this job means reuse or
  extend it — do NOT drop in an Astryx twin next to it.
- After placing: run `tsc` + lint + build (zero new errors), then `npx playwright test` smoke on
  the changed surface (load it, assert no console errors, toggle dark mode). Use the Playwright
  CLI — NOT the `ecc:playwright` MCP. Fix any error before finishing.
- Run `/eli5` on the completed-work summary before presenting.

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
2. If no brand match: token-hunt CSS extraction. Otherwise seed from Radix Colors (React) or
   Open Color.
   - **Reference URL**: if `$ARGUMENTS` contains an `http(s)://` URL, scrape it and extract its
     real tokens (mirrors `skills/ingest-docs/SKILL.md` — Python `firecrawl-py`, self-hosted, no
     API key). First run the install guard, then scrape for HTML:
     ```bash
     python3 -c "import firecrawl" 2>/dev/null || pip3 install firecrawl-py --break-system-packages
     ```
     ```python
     from firecrawl import FirecrawlApp
     app = FirecrawlApp(api_url="http://<your-firecrawl-host>:3002")  # self-hosted, no API key
     result = app.scrape_url(url, formats=["html"])  # HTML — need raw CSS, not just markdown
     # result.html → parse inline + linked CSS for: palette hex, type families (font-family
     #   stacks), spacing scale (recurring px/rem gaps, padding, margins)
     ```
     Fold the extracted palette/type/spacing into the seed. If the scrape fails (service
     unreachable / non-2xx / empty `result`), do NOT abort the skill — fall back to the
     Radix/Open-Color seed and note "reference URL scrape failed, used fallback" in the seed file.
   - No reference URL: local CSS token-hunt, then Radix/Open-Color as above.

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
4. If `MOTION_INTENSITY` > baseline (mockups will have real animation, not just static
   layout): invoke the `emil-design-eng` skill for transition/easing/timing decisions on
   the interactivity category. Skip silently if not installed — `/design` never depends
   on it (`npx skills@latest add emilkowalski/skills` to add it).

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
4.6. **Reuse + simplicity gate (HARD):** for every NEW component/hook/util the build introduced, grep the tree for an existing one with the same/similar name or role — a sibling component already doing this means reuse it, don't add a twin. If the diff added 3+ new components or duplicated an existing pattern (a second card/modal/table variant instead of extending the shared one), run `/trim` on the new files before proceeding — kills the abstraction/ceremony a mockup-to-code pass tends to add. Fix or explicitly triage with reason before continuing.
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
