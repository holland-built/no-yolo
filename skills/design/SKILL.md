---
name: design
description: Use this skill when the user types /design, says 'design this', 'new design', 'redesign', 'fresh look', 'start over on the UI', 'mock this up', or 'show me design options'. Fresh generation only — never preserves the existing design. Pipeline: brand seed -> Taste generators -> 10 Opus mockups (8 distinct paradigms + 2 wild) -> slop validator -> AI picks best -> Chrome auto-opens -> you confirm or pick different -> Opus plan -> Sonnet build. Nothing builds before you confirm. Auto-redirects audit/review to /design-audit, existing-UI polish to the impeccable plugin. Second mode — component-pull: also fires on natural language like 'put a button here', 'add a chat box', 'drop in a card', 'add a component', or 'drop in a component'; in a React project it pulls a finished, project-themed component from the project's own component library (shadcn/Radix/MUI/etc. — auto-detected), or Meta's open-source Astryx design system when the project has none, instead of hand-building it, and previews the themed component for your approval before placing it (React-only; falls back to normal /design otherwise). Third mode — mockup-match (MOCKUP-MATCH MODE): fires on 'make it match this mockup', 'match this mockup', 'port this mockup', 'make my site look like this mockup' when the user supplies an HTML mockup file/URL and names an existing surface; ports that surface VERBATIM into a new <Name>V2 component (never patches the old one) and gates done on a shown overlay screenshot of live-vs-mockup.
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

Fresh generation. This skill **never preserves the existing design** — every mockup is a clean-sheet take. Existing tokens are read only to build a ban list.

## Mode select (route first)
Decide the mode from `$ARGUMENTS` before anything else:
- **"put a <component> here"**, **"add a button / chat box / card"**, **"drop in / add a component"** (naming a single UI piece to place into an app you're already building) -> **COMPONENT-PULL MODE**. Skip fresh-gen entirely.
- **"make it match this mockup"**, **"match / port this mockup"**, **"make <surface> look like <mockup>"** — the user SUPPLIES an existing HTML mockup (file path or URL) AND points at an EXISTING surface/component -> **MOCKUP-MATCH MODE**. Skip fresh-gen entirely. Disambiguation: "mock this up" with NO existing mockup file = fresh-gen; "add a <component>" = COMPONENT-PULL; a supplied mockup + a named existing surface = mockup-match wins.
- Everything else (`design this`, `new design`, `redesign`, `mock this up`, a URL, a screenshot, `--apply-spec`) -> fall through to `## Redirects` and fresh-gen (Steps 0-5).
- Ambiguous ("update the button" could be polish) -> the Redirects block still owns polish/edit/tweak wording; only additive "add / put / drop-in a NEW component" phrasing routes here.

## Redirects (check first)
`/design` is the single entry point for all UI work. A redirect means: invoke that skill now, in this same response — never tell the user to type a different command themselves.
- `$ARGUMENTS` contains `audit`, `review`, `analyze`, `what's wrong`, `find problems` -> invoke `/design-audit` now.
- `$ARGUMENTS` contains `polish`, `tighten`, `existing`, `impeccable`, `fix the design`, `clean up the ui`, `update`, `edit`, `change`, `tweak`, `adjust` (and no BOLD-mode word below is also present) -> invoke `impeccable:impeccable` now (`/plugin marketplace add pbakaus/impeccable` if not present). That's real-code polish over what's already built — an independent tool with its own rules. Never run both engines on the same request: they produce incompatible artifacts (throwaway mockup HTML vs live edits).
- `--apply-spec <file>` present -> jump to the APPLY-SPEC branch (skip Steps 0-4).
- Anything else -> this skill's own pipeline (Steps 0-4), taste-skill-driven.

## BOLD mode
If `$ARGUMENTS` contains any of: `new`, `redesign`, `fresh`, `different`, `something new`, `new look`, `start over`, `rethink` -> BOLD MODE on. Every mockup must be impossible to mistake for an incremental refresh of the current UI. The validator (Step 3) also kills any variant resembling the current design, not just generic slop.

## LIGHT + DARK rule
Every mockup HTML includes a fully realized light section AND dark section with a `<button>` toggle switching `data-theme` on `<html>`. Both themes hand-tuned, not CSS inversion.

---

## COMPONENT-PULL MODE (prefab-first)
Reached only from **Mode select**; fresh-gen (Steps 0-5) does not run here. Everything below is discovered **per project** — never hardcode any project's paths. Pull from the project's detected prefab library (see `skills/design/PREFAB_SOURCING.md`); Astryx is the greenfield default when the project has no library, not a universal source. Render and screenshot the themed component in an isolated throwaway preview for approval **before** placing anything in the real app — the same confirm-before-build gate fresh-gen uses.

**What Astryx is:** Meta's open-source React design system (`github.com/facebook/astryx`, MIT, 102 finished accessible components — buttons, chat, hover cards, command palette). Drop-in per its docs: a few CSS imports plus a theme provider — no build plugin, no PostCSS/Babel config; override with `className` (Tailwind, CSS modules, plain CSS). StyleX-based; ships `dist/astryx.css` + a theme/token system (`Theme` provider, `defineTheme`) — coexists with Tailwind/Radix/shadcn. React-only.

### 1. Detect React (guard — STOP-style, never crash)
Read the project's `package.json` (or a `frontend/`/`web/`/`app/` subdir's) for `react` in dependencies. If **not** React: do NOT use Astryx. Tell the user *"This isn't a React project — Astryx only works in React,"* fall back to `/design`'s normal behavior (`## Redirects` / fresh-gen), and do not proceed past this step.

### 2. Detect the project's color/design source (generically)
Use whichever exists first — this is how the pulled component gets painted to match the project:
1. `COLOR_CONTRACT.md`
2. `DESIGN.md`
3. a Tailwind theme (`tailwind.config.{js,ts,cjs,mjs}` -> `theme.extend.colors`)
4. CSS custom properties in the global stylesheet (`:root { --... }` in `globals.css`/`app.css`/`index.css`).
Extract palette + radius + type tokens. Never assume a filename — glob and use what's there.

### 3. Detect the prefab library
Run the detection in `skills/design/PREFAB_SOURCING.md` and emit the sourcing table here — usually one row, the single component being pulled. **Outcome (a)** (an existing library was found) -> pull the component from that project library; steps 4-5 do NOT run. Outcomes (b) (no library, React + npm) and (c) feed steps 4-5 and the which-source rule (step 6).

### 4. Ensure Astryx is installed AND WIRED in THIS project
**Astryx path only (outcome b / project already on Astryx).**
If `@astryxdesign/core` is absent from the project's `package.json`: detect the package manager from the lockfile (`pnpm-lock.yaml`->pnpm, `yarn.lock`->yarn, else `package-lock.json`->npm), tell the user you are adding it, then run **in that project dir**: `npx astryx init` — installs `@astryxdesign/core` + `@astryxdesign/theme-neutral`, imports `dist/astryx.css`, wires the `Theme` provider / token system. A bare `npm install` is NOT enough: Astryx is StyleX-based and components render UNSTYLED unless the shipped CSS + theme are wired. If `astryx init` is unavailable or fails, wire manually: install the two packages, import `@astryxdesign/core/dist/astryx.css` at the app root, mount the `Theme` provider per `npx astryx docs theme` — verify a `Button` renders styled before proceeding.
**Never install globally.** If install fails (offline / registry / peer-dep conflict), STOP and report — do not hand-build a substitute silently.

### 5. Pull + theme (do NOT place yet)
**Astryx path only (outcome b / project already on Astryx).**
1. Confirm the exact component exists and get its real API first: `node node_modules/@astryxdesign/core/docs.mjs <Name>` (or `npx astryx component <Name>` for docs + related block templates). **Never import a name that isn't in `skills/design/ASTRYX_CATALOG.md` / docs.mjs output.** Then pull it.
2. Theme it to step 2's detected colors using Astryx's real theme system: inspect tokens via `npx astryx docs tokens`, define a project theme with `theme/defineTheme` (build with `npx astryx theme build` if the project needs the compiled output) — never ship the default neutral theme. Result: Meta-built, **project-colored.**

Placing happens only AFTER the preview gate below. Do not write the component into its final location before the user confirms.

### 5.5 Preview + confirm (never place before the user sees it)
Mirror the fresh-gen HARD GATE (Step 4): *nothing lands before you confirm.*
1. **Build a throwaway isolated preview.** A temp route/page rendering ONLY the themed component in a **sensible mockup context** with realistic placeholder content — never floating in a void: chat box -> a plausible chat surface with 3–4 sample messages; button -> inside a small form or card; card -> inside a short list/grid of siblings. Use a disposable route (e.g. `__astryx-preview`) or a standalone entry file in a temp location — NEVER the component's final path, never a route left wired into the real router.
2. **Screenshot it the same way fresh-gen screenshots mockups** (reuse Step 3's machinery): point at / start the project's dev server, capture the preview URL with headless Chrome `--screenshot=` (same invocation fresh-gen uses on `all.html`) or the Playwright CLI — NOT the `ecc:playwright` MCP. Show the PNG inline, then `open` it.
3. **Confirm gate (HARD — place nothing before this):** ask **"Use this component? (yes / show a different Astryx option / tweak the theme / no)"**
   - `yes` -> 5.6 (place). `different` -> pull a different Astryx component/variant, re-theme, re-preview. `tweak` -> adjust the theme mapping (step 5.2), re-preview. `no` -> discard, place nothing.
4. **Cleanup (HARD).** Remove the temp preview route/entry file in EVERY case (accepted OR rejected) — it must never be committed, and no `__astryx-preview` route may be left wired in. If it cannot be removed, **STOP and report** rather than leaving cruft behind.
5. **Graceful degradation.** No runnable dev server / Playwright to render a live preview: do NOT place silently. Describe the component, show Astryx's own documented preview image/URL if available, and STILL run the confirm gate (step 3) before placing.

### 5.6 Place (only after 5.5 confirmed)
1. Place in the project's conventional location (mirror where sibling components live — `src/components/...`, `app/...`, etc.; discover, don't assume).
2. Per-instance tweaks: override with the project's own styling via `className` (its Tailwind / CSS modules / plain CSS) — the drop-in override Astryx documents.

### 6. Which-source rule (never mismatched twins — HARD)
The sourcing gate's library is the ONLY prefab source for this run. Existing lib -> EVERY pulled component comes from it, simple or complex; if it lacks the requested component, check that lib's own ecosystem/registry first, else compose from its primitives themed to the project — NEVER install Astryx (or any second library) beside it. No lib + React -> Astryx for everything (greenfield). Always theme to the project's tokens (step 2). State which outcome applied in your summary.

### 7. Reuse gate + verify
- **Reuse gate (HARD, mirrors Step 4.6):** before placing, grep the tree for an existing component with the same/similar name or role. A sibling already doing this job means reuse or extend it — do NOT drop in an Astryx twin next to it.
- After placing: run `tsc` + lint + build (zero new errors), then `npx playwright test` smoke on the changed surface (load it, assert no console errors, toggle dark mode). Use the Playwright CLI — NOT the `ecc:playwright` MCP. Fix any error before finishing.
- Run `/eli5` on the completed-work summary before presenting.

---

## MOCKUP-MATCH MODE (port an existing surface to a supplied mockup)
Reached only from **Mode select** when the user supplies an existing HTML mockup (file/URL) AND names an existing surface to make match it. Fresh-gen (Steps 0-5), COMPONENT-PULL, and APPLY-SPEC do not run here. Also NOT Step 5's token-first build: token-first applies a fresh design app-wide via the design system; mockup-match converges ONE existing surface onto ONE given mockup, structure-first. Everything below is discovered per project — never hardcode any project's paths, ports, or component names.

**Core inversion — PORT, don't patch.** Nudging the existing component toward a mockup failed 10+ times over 3 days; copying the mockup's structure into a NEW component and pouring the app's real data into it works. Canonical write-up: `~/.claude/projects/-Users-sholland-AI-Wayfinder/memory/feedback_html_mockup_matching.md`.

### The 6 laws (all HARD)
1. **Build a NEW component** (`<Name>V2`, a sibling file) that copies the mockup's HTML structure + CSS VERBATIM — exact `grid-template-columns`, row heights, gaps, hex values, computed values. Pour in the real data + EVERY handler the old component has (drag-and-drop, inline-edit, expand/collapse, selects, menus) + EVERY `data-testid` it exposes. NEVER edit the old component to "nudge" it toward the mockup. Structure is part of the port: if the mockup is a div-grid, the new component is a div-grid — not a `<table>` CSS-patched to look like one.
2. **DONE = the overlay screenshot, SHOWN.** Done means one thing: a screenshot of the LIVE new component beside/overlaid on the mockup, pixel-indistinguishable, captured and SHOWN to the user. tsc-clean, tests-pass, "measured 44px" are NOT done.
3. **Verify the running instance before iterating.** Detect the project's dev server + port (package.json scripts, running processes). A machine may run two checkouts of the same app on different ports — confirm the browser hits the instance you are editing: drop a marker file in the app's public/static dir and curl it through the served URL, or take a fresh screenshot and confirm your latest change is visible. Rule out stale cache / wrong port FIRST, and re-check any time an edit doesn't appear.
4. **Measure computed values, never guess.** Open the mockup in a real browser and read its COMPUTED values via `getComputedStyle` (grid templates, row heights, gaps, fonts, colors); copy them verbatim into the new component.
5. **DELETE/replace the old rendering** once the new component matches — never keep both, never patch, never leave the old rendering reachable.
6. **Give the AI EYES.** Screenshot the live app EVERY iteration — headless Chrome `--screenshot=` or the Playwright CLI, NOT the `ecc:playwright` MCP. Without a per-iteration screenshot the builder is blind and overclaims "it matches".

### FORBIDDEN (each one caused or extended the 3-day failure)
- Patching/nudging the OLD component instead of porting into a new one.
- Declaring "done"/"it matches" without SHOWING the overlay screenshot.
- Matching individual numbers ("gap is now 8px") and calling the whole surface matched.
- Touching the project's sizing/golden-master snapshot tests to make them pass.
- Dropping any `data-testid` the old component exposed.
- Adding new features. **Zero-new-features rule:** golden-master snapshots preserved byte-identical, every testid preserved, same props/API surface — a pure visual port.

### Procedure (verbatim port)
1. **Inventory (read-only).** Read the mockup file, the old component + its direct imports. List every handler, prop, and `data-testid` it exposes. Detect the dev server + port and run the Law-3 instance check.
2. **Measure.** Open/serve the mockup, extract computed values (Law 4) into a short spec: structure outline + exact CSS values + a data-mapping table (mockup slot -> app data) + the full testid list + what gets deleted at the end.
3. **Plan.** The current model writes the verbatim-port plan from that spec — structure to copy, data/handler mapping, testid list, deletion list. No code yet.
4. **Build.** Dispatch a stronger model (Opus agent) to build `<Name>V2` from the plan: verbatim structure + CSS first, then pour in data, handlers, and testids.
5. **LOOP until indistinguishable.** Render the live V2, screenshot it (Law 6), place it beside/over the mockup, fix ONLY what visibly differs, re-shoot. Any time a change doesn't show up, re-run the Law-3 instance check before touching more code.
6. **Swap + delete.** Point the app at V2 and delete the old rendering (Law 5). Run the project's existing tests — golden-master/snapshot tests must pass UNCHANGED (never edit them) and every testid must still resolve.
7. **Show DONE.** Present the final side-by-side/overlay screenshot (Law 2) — that image, not any metric, is the completion claim. Then run `/eli5` on the summary before presenting.

---

## Step 0 — Brand seed
```bash
SLUG=$(python3 -c "import json; print(json.load(open('package.json')).get('name','').replace('/','-').replace('@',''))" 2>/dev/null || basename "$PWD")
mkdir -p .mockups
head -20 CLAUDE.md 2>/dev/null
cat package.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('name','?'), d.get('description',''))" 2>/dev/null
```
1. Check for a matching brand in the Awesome DESIGN.md library (voltagent/Awesome-DESIGN.md, 9-section DESIGN.md format). If a brand DESIGN.md exists in-repo or matches the product: pull the FULL system — agent prompt guide + layout principles + type hierarchy + component states + do's/don'ts.
2. If no brand match: local CSS token-hunt extraction, otherwise seed from Radix Colors (React) or Open Color.
   - **Reference URL**: if `$ARGUMENTS` contains an `http(s)://` URL, scrape it and extract its real tokens (mirrors `skills/ingest-docs/SKILL.md` — Python `firecrawl-py`, self-hosted, no API key). Run the install guard, then scrape for HTML:
     ```bash
     python3 -c "import firecrawl" 2>/dev/null || pip3 install firecrawl-py --break-system-packages
     ```
     ```python
     from firecrawl import FirecrawlApp
     app = FirecrawlApp(api_url="http://<your-firecrawl-host>:<port>")  # self-hosted, no API key
     result = app.scrape_url(url, formats=["html"])  # HTML — need raw CSS, not just markdown
     # result.html → parse inline + linked CSS for: palette hex, type families (font-family
     #   stacks), spacing scale (recurring px/rem gaps, padding, margins)
     ```
     Fold the extracted palette/type/spacing into the seed. If the scrape fails (service unreachable / non-2xx / empty `result`), do NOT abort the skill — fall back to the Radix/Open-Color seed and note "reference URL scrape failed, used fallback" in the seed file.

Write the seed to `.mockups/design-seed.md`: palette hex, type families, spacing scale, layout principles, component states, do's/don'ts. State one line summarizing the seed source.

## Step 1 — Taste generators
`TASTE_CORE.md` (next to this file) holds the distilled brief-inference, dials, and design-system map — tracked and always present, so Step 1 works even with no vendor dir. Full source is vendored at `skills/design/vendor/taste-skill/` (MIT, Leonxlnx/taste-skill, see `vendor/taste-skill/SOURCE.md`); it is gitignored — open it only for the screenshot path or detail `TASTE_CORE.md` omits. FALLBACKS below is the last resort if both are gone.

1. Read `TASTE_CORE.md` (~7KB instead of the ~100KB vendor dir). Apply **Section 0 (Brief Inference)**: state the one-line **Design Read** — page kind, audience, vibe, leaning design-system/aesthetic. Apply **Section 1 (Three Dials)**: set `DESIGN_VARIANCE` / `MOTION_INTENSITY` / `VISUAL_DENSITY` from the inference table (baseline 8/6/4 if nothing overrides). Apply **Section 2 (Brief -> Design System Map)**: if the brief matches a real design system (Fluent/Material/Carbon/Polaris/Atlassian/Primer/GOV.UK/USWDS/Radix/shadcn), name it and use the official package — do not hand-roll its CSS.
2. If a screenshot is provided -> read `vendor/taste-skill/image-to-code-skill.md` and follow it (generate reference image, analyze structure, translate faithfully).
3. Use `TASTE_CORE.md` **Section 3** to set mockup generation direction (six categories: typography, color/surfaces, layout, interactivity, content, components). Only open `vendor/taste-skill/redesign-skill.md` if you need its itemized problem/fix lists.
4. If `MOTION_INTENSITY` > baseline (real animation, not just static layout): invoke the `emil-design-eng` skill for transition/easing/timing decisions on the interactivity category. Skip silently if not installed — `/design` never depends on it (`npx skills@latest add emilkowalski/skills` to add it).

The Design Read line, the three dial values, and the design-system decision all feed the Step 2 briefs alongside the six-category direction.

## Step 2 — 10 Opus mockups
ONE parallel Agent call, `model: "opus"`. Each writes `.mockups/design-<slug>/vN.html`: self-contained, inline `<style>`, **no external deps**, `file://` openable, `<!-- VARIANT: vN — paradigm -->` header. **Real data, not lorem ipsum.** Bake the Step 0 seed tokens throughout.

**v1–v8**: each anchored to a DISTINCT paradigm — pick 8 from: Terminal/CLI · Bloomberg data grid · editorial/magazine · bento grid · command palette · split-pane reference · single-column full-bleed · floating action panel · timeline · kanban.

**v9–v10**: WILD. A completely alien layout paradigm — impossible to mistake for a variation of v1–v8. Examples: physical-object skeuomorph, radial/circular nav, newspaper broadsheet, game HUD, brutalist raw grid with zero decoration. Label each with `WILD` in the header comment.

**Codex authors v9–v10 (cross-model generation; skip if `command -v codex` fails → Opus authors them as before).** All-Claude batches share one model's taste DNA — the WILD slots go to a different family. Codex stays read-only and returns HTML on stdout; **Claude writes the files** (write authority never delegates). Launch in the BACKGROUND *before* the Opus fan-out so it costs zero wall-clock, and give the Opus call only v1–v8:

```bash
codex exec --skip-git-repo-check --sandbox read-only -m gpt-5.6-sol "Output two WILD UI mockup variants as complete self-contained HTML documents, delimited by lines ===V9=== and ===V10===. Each: completely alien layout paradigm (not card grids/dashboards), inline <style> only, no external deps, light + dark sections with a data-theme toggle button, a labeled states strip (hover/focus/empty/error/loading), 2-3 <!-- ANNOTATION: --> comments, header comment '<!-- VARIANT: vN — paradigm (WILD, codex) -->'. Use these tokens verbatim: <paste seed tokens>. Real data, no lorem ipsum. Banned: <paste slop reject list>. Output ONLY the delimited HTML." < /dev/null > .mockups/design-<slug>/codex-wild.out 2>&1 &
```

After the Opus agents finish, wait for the Codex job; split `codex-wild.out` and Write `v9.html` / `v10.html` yourself. **Split gotcha (verified):** codex echoes the prompt (which contains the delimiter strings) AND prints the answer twice (streamed + final) — match delimiters as whole lines only and use the LAST `===V9===`/`===V10===` pair; trim v10 at its final `</html>` — but first READ what came back: each document must be plain HTML/CSS/minimal-JS (no scripts fetching remote URLs, no external deps) and contain `<html`. Fails the check or missing → regenerate that slot with Opus (never block the round). Codex variants pass through the SAME validator as everyone.

**Every variant must include:**
- Light + dark sections with toggle (LIGHT+DARK rule above)
- **States strip**: a thin labeled row at the bottom showing all 5 interactive states as small labeled boxes: `hover` · `focus` · `empty` · `error` · `loading`, each showing the relevant component in that state. Real styled boxes, not placeholder text.
- **2–3 annotation callouts**: inline HTML comments at the most non-obvious decision points (why this column count, type scale, component placement): `<!-- ANNOTATION: [one sentence explaining this layout/hierarchy choice] -->`.

Each brief carries: design seed + Design Read line + the three dial values + any named design system from Step 1 + Taste/Swiss/UIwiki rule text (FALLBACKS if vendor absent) + the slop reject list below + LIGHT+DARK rule. BOLD constraint added when BOLD MODE is on.

Each brief also carries the **Astryx awareness line**: if this is a React + npm project (a `package.json` with `react` in deps and a lockfile — NOT a CDN/babel page), read `skills/design/ASTRYX_CATALOG.md` first; where the design calls for a rich interaction (hover preview, typeahead/power search, chat, command palette, stacked toasts, carousel/lightbox, token input), the mockup must **mock that Meta-quality behavior** (simulate it visually / with minimal inline JS) so the winning design already assumes the component exists — it will be pulled from the project's prefab library (or Astryx when the project has none — see `skills/design/PREFAB_SOURCING.md`), not hand-built, at build time. Only interactions in the generated `skills/design/ASTRYX_CATALOG.md` count — it lists the package's real 90+ components. Non-React or CDN-React projects: ignore this line, hand-build as normal.

## Step 3 — Validator + combined view + AI pick

### Validator pass
Spawn a judge agent running Taste + Swiss + UIwiki lenses on all 10. Reject any variant that hits the **slop reject list** and regenerate it (max 2 rounds, specific brief per reject):
> card grids · accordion-only · sidebar-nav + icon rows · gradient CTAs (blue->purple / teal->green) · rounded corners >8px everywhere · glassmorphism · sans-only type hierarchy · hero + centered-CTA layout · shadcn/MUI/Tailwind-UI starter DNA · badge/pill stat rows · progress bars everywhere · skeleton loaders · "Powered by" badges · hover scale transforms.

If BOLD MODE: also reject any variant that reads as a minor refresh of the current app. Minimum 6 survivors required before proceeding.

### Combined view
Build `.mockups/design-<slug>/all.html` — layout: **5 rows x 2 columns**. Each row = one variant pair: left column = light theme, right column = dark theme. States strip and annotation callouts visible in both columns. Sticky jump nav with v1–v10 anchors. Per-variant theme toggle preserved.

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

**Codex second judge (parallel with the scoring agent; skip silently if `command -v codex` fails):** a different model family grading visuals Claude both generated and judged — the self-grading bias breaker:

```bash
# prompt MUST come before -i: the variadic -i flag swallows a trailing prompt string
codex exec --skip-git-repo-check --sandbox read-only -m gpt-5.6-sol "This image shows UI mockup variants, labeled v1-v10 (light|dark pairs). For each: verdict slop|clean + one-line reason (slop = generic AI look: card grids, gradient CTAs, hero+centered-CTA, glassmorphism, shadcn starter DNA). Then name your single top pick + one sentence why. No preamble." -i ".mockups/design-<slug>/all.png" < /dev/null
```

Codex is advisory — never kills a variant alone; the validator pass remains the gate. **Cross-grading rule:** nobody grades their own homework — Claude's validator/scorer gates the Codex-authored v9–v10; the Codex judge's verdict counts only for Claude-authored variants (its opinion of its own v9/v10 is noted but carries no weight). Returns the winner variant number + a single sentence why. Update `all.html` to mark the winner with * in its section header. Show this table (Codex column from the second judge; both models agreeing on the winner = high-confidence, a split = show both picks and reasons — the disagreement is the signal):
```
| Variant | Paradigm | Score | Codex | Recommended |
|---------|----------|-------|-------|-------------|
| v1      | Terminal/CLI | 34 | clean | |
| v3      | Bloomberg grid | 41 | clean · Codex pick | * "Strongest data-ink discipline and only variant with true asymmetric balance" |
```

### Synthesis round (only when the judges split)
Compare the scoring agent's winner with the Codex judge's top pick:
- **Same variant** → converged; skip this round entirely, note "judges converged on vN".
- **Different variants** → the disagreement is the trigger. Generate two crossover variants — **crossover, never consensus**: each keeps ONE parent's paradigm whole and grafts specific elements from the other. Averaging two layouts produces design-by-committee mush; banned.
  1. **v11 (Claude-led):** read the Codex pick's HTML, name the 2–3 strongest concrete elements in it (a specific navigation pattern, a data-display treatment, a state-strip idea — not "the vibe"). Spawn one Opus agent: keep the Claude pick's paradigm, graft exactly those named elements. Header `<!-- VARIANT: v11 — synthesis, claude-led -->`.
  2. **v12 (Codex-led):** one codex call (read-only; same stdout/delimiter/write-it-yourself machinery and split gotcha as the wild slots):
     ```bash
     codex exec --skip-git-repo-check --sandbox read-only -m gpt-5.6-sol "Read <codex-pick path> (your earlier pick) and <claude-pick path>. Name the 2-3 strongest concrete elements in <claude-pick>, then output ONE complete self-contained HTML document after a line ===V12===: keep <codex-pick>'s layout paradigm whole and graft exactly those elements in. Same rules as before: inline style only, no external deps, light+dark toggle, states strip, annotations. Do NOT average the two layouts." < /dev/null > .mockups/design-<slug>/codex-synth.out 2>&1
     ```
  3. Validate both (same checks as the wild slots; a failed synthesis slot is dropped, not regenerated — synthesis is a bonus, never a blocker), append to `all.html` marked `SYNTH`, re-screenshot, and include both in the Step 4 gate — the user picks from 12.

### Chrome auto-open
```bash
open ".mockups/design-<slug>/all.html"
```
Opens immediately — you see all variants before answering anything.

## HARD GATE — Step 4 (no code before this)
Ask: **"Which variant? (confirm * vN / pick different vN / mix vA layout + vB colors / redo)"**
- `redo` -> regenerate Step 2 with a different paradigm set.
- **Do not write a single line of production code until the user names a variant.**

### Component sourcing gate (HARD — prefab-first, before any build dispatch)
Before dispatching the build, run detection per `skills/design/PREFAB_SOURCING.md` and emit the **full sourcing table** for EVERY interactive element in the chosen mockup — not just the "rich interaction" pieces. Mandatory gate; do not dispatch build agents before the table is shown.
- **Outcome (a)** (an existing library was found) -> pull every mapped row from that library.
- **Outcome (b)** (no library, React + npm/bundler project) -> pull via COMPONENT-PULL MODE steps 4-5: wire via `npx astryx init`, confirm each export via `node node_modules/@astryxdesign/core/docs.mjs <Name>`, theme to the project's detected tokens.
- **Outcome (c)** (no prefab library applicable) -> the one-line hand-build note from `PREFAB_SOURCING.md`.

**Never import a component name that isn't in the catalog / docs.mjs output — if it's not there, hand-build.**
**Guard:** not React, or React delivered via CDN/babel with no `package.json` (e.g. an internal MCP dashboard) -> do NOT attempt an Astryx install; hand-build the interaction. Never block a build on Astryx.
**Note:** the full-build path skips the per-component 5.5 preview gate (unusable at 10+ components) — Step 4's mockup confirm + Step 5.6's visual-diff gate are the visual gates here.

## Step 5 — Implement
1. **Token-first (BEFORE building any component).** Extract the chosen mockup's exact tokens — palette hex, type families + sizes, spacing scale, radius, shadow/elevation, motion — to `.mockups/design-<slug>/approved-tokens.md`, THEN write those exact values into the project's real design system so components inherit the look via tokens, not hand-matched per component:
   - **shadcn / CSS-variable projects** (a `globals.css`/`app.css` with `:root { --... }`, or a `components.json`): set the mockup's values on the existing CSS custom properties (`--background`, `--foreground`, `--primary`, `--radius`, `--font-*`, etc.) in `:root` and the dark block — the same palette/token-swap the APPLY-SPEC branch performs; reuse it.
   - **Tailwind projects:** also mirror the scale into `tailwind.config.{js,ts}` `theme.extend` (colors, borderRadius, fontFamily, spacing) so utility classes resolve to the mockup's values.
   - After writing, **ban arbitrary one-off values** in the build: components must reference tokens (`bg-background`, `text-foreground`, `rounded-[var(--radius)]`), NOT inline `bg-[#3a2f1e]`. A one-off arbitrary value in the built diff means a token is missing — add the token instead.
   - If the project has NO detectable design-system file (no globals.css `:root`, no tailwind config): build from `approved-tokens.md` directly and note it.
2. Component library = the sourcing gate's PREFAB (already detected + table emitted above). React: never introduce a second library beside it. Non-React fallbacks unchanged:
   - Vue -> Naive UI + PrimeVue
   - Tailwind only -> DaisyUI + HyperUI
   - none -> warn, hand-build with tokens.
3. Spawn an Opus agent to write `brainstorms/design-<slug>-plan-<date>.md` (presentation layer only; cites approved-tokens.md as source of truth; lists target files as "already exists — do NOT recreate"; embeds the component sourcing table, with each target-file entry listing its rows).
4. Dispatch Sonnet subagents to build the approved mockup against the plan. Disjoint file clusters, no overlap. Each agent spec carries its sourcing-table rows; agents MUST import the mapped components, not hand-roll them.
4.5. After all subagents complete, run tsc + lint + build (zero new errors) before the Playwright smoke. If any errors -> fix before proceeding.
4.6. **Reuse + simplicity gate (HARD):** for every NEW component/hook/util the build introduced, grep the tree for an existing one with the same/similar name or role — a sibling already doing this means reuse it, don't add a twin. If the diff added 3+ new components or duplicated an existing pattern (a second card/modal/table variant instead of extending the shared one), run `/trim` on the new files before proceeding. Fix or explicitly triage with reason before continuing. The diff must not contain a bespoke implementation of any primitive the sourcing table mapped to PREFAB — a violation means swap in the mapped component before proceeding.
5. `npx playwright test` smoke after build (load each changed surface, assert no console errors, toggle dark mode). Use CLI — NOT `ecc:playwright` MCP.
6. **Visual-diff gate (looks-like-the-mockup, not just no-errors).** For each built surface, screenshot the rendered React page with the Playwright/Chrome CLI (same machinery Step 3 uses on `all.html` — NOT the `ecc:playwright` MCP) and place it beside the chosen mockup's PNG (`.mockups/design-<slug>/`). Compare: palette, type scale, spacing rhythm, radius, key layout. If they diverge, the tokens did not fully land — fix (usually a missing/incorrect token from 5.1, or a shadcn component default overriding a token) and re-shoot. Do NOT declare done on a visible mismatch. State the result in one line ("rendered matches mockup" / "fixed N drifts").
7. Run `/eli5` on the completed-work summary before presenting.

---

## APPLY-SPEC branch (`--apply-spec <file>`)
Skip Steps 0-4 entirely. The spec file is a DESIGN.md (or token doc).
1. Read the spec.
2. 8-dimension token audit of the current app: color, typography, spacing, radius, shadow/elevation, component states, layout grid, motion. Map current -> spec for each.
3. Palette/token swap: replace current values with spec values across CSS/theme files.
4. WCAG AA gate: every changed surface contrast >= 4.5:1 (text), focus-visible preserved.
5. Cleanup dead CSS left by the swap.
6. Build verify: tsc + lint + build green, then `npx playwright test` smoke. (CLI — NOT `ecc:playwright` MCP.)
7. `/eli5` summary.

---

## FALLBACKS (when Taste/Swiss/UIwiki sub-skills absent)
**Taste:** em-dash ban; no beige+brass default palette; no serif-as-default (no Fraunces/Instrument_Serif); no three equal cards; no filler verbs / fake-perfect numbers / placeholder brands; motion via Motion/GSAP/IntersectionObserver, never scroll listeners.
**Swiss:** strict grid, <=3 type sizes, <=3 colors, asymmetric balance, generous negative space, function over decoration.
**UIwiki (20 rules):** hierarchy, contrast, alignment, proximity, consistency, affordance, feedback, error prevention, recognition over recall, minimal load, progressive disclosure, data-ink ratio, status colors, responsive, motion purpose, label clarity, empty states, loading states, keyboard nav, touch targets.
