---
name: design-full
description: Use this skill when the user types /design-full, says 'full design pipeline', 'design and build this', 'redesign and ship', 'design options', 'mockup this fast', 'show me design directions', or 'quick mockup'. Three modes: default = full pipeline (audit → debate → 7 Opus mockups → 4 hard gates → token extraction → Opus plan → /build); --fast = 7 Sonnet mockups + slop judge + pick gate only, no code; --steal = runs /token-hunt first to steal tokens from a reference site before mockups. Nothing builds without an approved mockup.
user-invocable: true
argument-hint: "[surface/feature — optionally paste /design-audit output] [--fast] [--steal [source-url]]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
---

# design-full

Target: $ARGUMENTS

**Mode detection:** If `$ARGUMENTS` contains `--fast` → run **Fast mode** (Steps F0–F7 below). Otherwise → run **Full pipeline** (Steps 0–13 below).

**STEAL MODE:** If `$ARGUMENTS` contains `--steal` → run `/token-hunt` first (before Step 0). Token-hunt writes `.mockups/token-hunt/stolen-tokens.md`. When it completes and the user picks a token set, continue to Step 0 — but Step 0d is replaced: read the stolen palette seed from `.mockups/token-hunt/stolen-tokens.md` instead of generating one from Radix/Open Color. All other steps and gates are unchanged.

**BOLD REDESIGN RULE:** If `$ARGUMENTS` contains any of: `new`, `redesign`, `fresh`, `different`, `something new`, `new look`, `start over`, `rethink` → **BOLD MODE is active.** In Bold Mode: every variant (v1–v7) must be impossible to mistake for an incremental update of the current design. Different layout paradigm. Different color logic. Different type hierarchy. The slop judge **also kills any variant that looks like it could be a minor refresh** — not just generic slop. Similarity to the existing UI = instant reject + respawn with explicit brief: "this looks like the current app — go completely different."

**LIGHT + DARK RULE:** Every mockup HTML file must include **both** a light-mode section and a dark-mode section. Use a `<button>` toggle at the top that switches `data-theme="light|dark"` on `<html>`. Both themes must be fully realized — not just CSS inversion. This is non-negotiable in both Fast and Full mode.

---

## FAST MODE (`--fast`)

7 variants (5 redesign + 2 wild), one approval gate. No code written. Sonnet — cheap and fast.

**Token rule:** DESIGN.md / MASTER.md / CSS are read to know what to **AVOID** — do not copy any existing colors, fonts, or layout patterns into new mockups.

### Step F0 — Detect project, load prior audit

```bash
SLUG=$(python3 -c "import json; print(json.load(open('package.json')).get('name','').replace('/','-').replace('@',''))" 2>/dev/null || basename "$PWD")
head -20 CLAUDE.md 2>/dev/null
cat package.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('name','?'), d.get('description',''))" 2>/dev/null
```

**Audit auto-pickup (no paste needed):**
```bash
ls -t design-system/AUDIT-${SLUG}-*.md 2>/dev/null | head -1
```
- File found → read it, print `Using saved audit: <filename>`. Skip re-running.
- Multiple files → use the most recent (already sorted by `ls -t`).
- No file → proceed to Step F1, then run `/design-audit` before mockups.

If the user pasted `/design-audit` output explicitly → that takes priority over the saved file.

### Step F1 — Lazyweb lite — reference screens

Query Lazyweb MCP (lite mode). If unavailable → skip with: `⚠️ Lazyweb unavailable — skipping references.`

### Step F3 — Read design tokens (to AVOID, not to copy)

Check `design-system/MASTER.md` → `DESIGN.md` → CSS `:root` vars. Read these to know what the current design looks like — **do not use any of these values in new mockups.** Every variant must use a completely different palette, type system, and layout from what's found here. State what was found in one line, then state what's banned.

### Step F4 — Fan out 7 parallel Sonnet agents

ONE parallel call. Each agent writes `.mockups/design-fast-<slug>/vN.html` — self-contained, inline CSS, realistic content, `<!-- VARIANT: vN — paradigm name -->` header comment. Every file must satisfy the **LIGHT + DARK RULE** (both themes + toggle button). If **BOLD MODE** is active, each brief carries the bold redesign constraint.

Each brief includes: Taste + Swiss + UIwiki reference text (use FALLBACKS if absent) + palette seed from Step 0d + ban list from Step 0e + component library from Step 0c. Agents must use the palette hex values and must not use any banned value.

**v1–v5 — Redesigns:** five distinct layout paradigms — materially different, not variations on a theme.

**v6–v7 — Wild:** throw out convention entirely. Challenge what this kind of app should look like.

### Step F5 — Slop judge

Judge agent reviews all 7 for slop fingerprint. Kills generic or DNA-sharing variants, respawns rejects with "go weirder — do not reuse [specific pattern]." Max 2 rounds.

If BOLD MODE active: also kill any variant that resembles the existing UI. Explicit rejection brief: "too close to the current design — completely different layout, colors, and type system required."

### Step F6 — Build all.html → screenshot

Write `.mockups/design-fast-<slug>/all.html` showing all 14 sections — every variant in both light AND dark mode. Structure: v1-light, v1-dark, v2-light, v2-dark … v7-light, v7-dark. Sticky jump nav with 14 anchors. Each section labeled "vN — [paradigm] — [LIGHT/DARK]". Toggle button per variant switches `data-theme` on that variant's wrapper. ★ recommended marking on the winning variant's light section.

```bash
open ".mockups/design-fast-<slug>/all.html"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --window-size=1400,900 \
  --screenshot=".mockups/design-fast-<slug>/all.png" \
  "file://$PWD/.mockups/design-fast-<slug>/all.html"
```

Show screenshot inline.

### FAST GATE — Hard stop (no code)

Print variant table: `| Variant | Paradigm | One-line description | Recommended |`

Ask: **"Which variant? (v1–v7 / redirect)"**

**STOP HERE.** No production code in this mode. Want it built? → run `/design-full` (without `--fast`).

---

## FULL PIPELINE

Full design-to-code pipeline. Four hard gates. Opus mockups. Chains to `/build`.

**Nothing builds without an approved mockup (Gate 3). This is non-negotiable.**

**Token rule:** DESIGN.md / MASTER.md / CSS are read to build an **explicit ban list** — do not copy any existing colors, fonts, or layout patterns. Full nuke, every run, no exceptions.

---

## Step 0 — Detect project

```bash
SLUG=$(python3 -c "import json; print(json.load(open('package.json')).get('name','').replace('/','-').replace('@',''))" 2>/dev/null || basename "$PWD")
head -20 CLAUDE.md 2>/dev/null
cat package.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('name','?'), d.get('description',''))" 2>/dev/null
head -10 README.md 2>/dev/null
```

State: project type, stack, target surface, slug.

---

## Step 0b — Audit auto-pickup

Priority order:
1. User pasted `/design-audit` output in `$ARGUMENTS` → use it. Print `Using pasted audit.`
2. Saved audit file exists for this project slug:
   ```bash
   ls -t design-system/AUDIT-${SLUG}-*.md 2>/dev/null | head -1
   ```
   → read it, print `Using saved audit: <filename>`. Skip re-running.
3. No saved audit → run `/design-audit` now on the target surface.

---

## Step 0c — Stack detection

```bash
STACK_REACT=$(cat package.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print('yes' if 'react' in str(d.get('dependencies',{})) or 'react' in str(d.get('devDependencies',{})) else 'no')" 2>/dev/null || echo "no")
STACK_VUE=$(cat package.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print('yes' if 'vue' in str(d.get('dependencies',{})) else 'no')" 2>/dev/null || echo "no")
STACK_TAILWIND=$(cat package.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print('yes' if 'tailwindcss' in str(d.get('dependencies',{})) or 'tailwindcss' in str(d.get('devDependencies',{})) else 'no')" 2>/dev/null || echo "no")
```

Based on results, select component library candidates:
- React + Tailwind → shadcn/ui, MagicUI, Aceternity UI, Mantine
- Tailwind only (no React) → DaisyUI, HyperUI
- Vue → Naive UI, PrimeVue
- None detected → warn: "No web framework detected — proceeding without component library reference." Continue.

Check which candidates are installed in node_modules. Prefer installed ones. If none installed, use the candidate list as reference knowledge only.

State one line: `Stack: [X] · Library: [Y or "none installed — using as reference"]`

---

## Step 0d — Palette injection

From the detected stack, select a color scale from Radix Colors (React projects) or Open Color (other):
- Radix Colors: radix-ui.com/colors — pick a scale NOT present in the current ban list below
- Open Color: yeun.github.io/open-color — 13 colors × 10 shades

Generate a concrete palette agents will use:
```
Palette seed:
  background: [hex]
  surface:    [hex]
  accent:     [hex]
  text:       [hex]
  muted:      [hex]
```

Agents receive these exact hex values — not a vague "use a fresh palette."

---

## Step 0e — Explicit ban list

Read current tokens from Step 4 findings. Emit a literal ban list:

```
BANNED (do not use any of these in new designs):
  Colors: [list actual hex values found in tokens]
  Fonts:  [list font names found in tokens]
  Layouts: [list patterns e.g. sidebar-left, dark-background, top-nav-dark]
```

Every fan-out agent brief in Steps 5 and F4 must include this ban list verbatim.

---

## GATE 1 — Approve audit

Show audit findings summary. Stop and ask: **"Approve audit findings, or redirect?"**

---

## Step 1 — Debate design direction

Run `/debate` on the **design direction only** (not implementation). Frame: "Given these audit findings [paste top 10], what design direction should this [product type] take?" The 6 personas argue. Winning direction becomes the mockup brief.

---

## GATE 2 — Approve direction

Show winning direction from debate. Stop and ask: **"Approve this design direction, or redirect?"**

---

## Step 2 — Lazyweb deep — reference screens

Query Lazyweb MCP (deep mode) using the project profile + direction keywords. Pull 3–6 reference screens.

If unavailable → skip with: `⚠️ Lazyweb unavailable — skipping references.`

---

## Step 4 — Read design tokens (to AVOID, not to copy)

Check `design-system/MASTER.md` → `DESIGN.md` → CSS `:root` vars. Read these to know what the current design looks like — **do not use any of these values in new mockups.** Every variant must use a completely different palette, type system, and layout from what's found here. State what was found in one line, then state explicitly what's banned from the new designs.

---

## Step 5 — Fan out 7 parallel Opus agents

ONE parallel call (Opus). Each agent writes `.mockups/design-full-<slug>/vN.html` — self-contained, inline CSS, realistic content. Every file must satisfy the **LIGHT + DARK RULE** (both themes + toggle button). If **BOLD MODE** is active, each brief carries the bold redesign constraint.

Each brief carries: Gate-2 direction + full Taste/Swiss/UIwiki sub-skill calls (FALLBACKS if absent) + palette seed from Step 0d + ban list from Step 0e + component library from Step 0c. Agents must use the palette hex values and must not use any banned value.

**v1–v5 — Redesigns:** five distinct paradigms grounded in the approved direction. Must be materially different from each other.

**v6–v7 — Wild:** challenge assumptions about what this kind of product should look like. Break convention.

---

## Step 6 — Slop judge

Kill generic or shared-DNA variants, respawn rejects with specific brief, max 2 rounds.

If BOLD MODE active: also kill any variant that resembles the existing UI. Explicit rejection brief: "too close to the current design — completely different layout, colors, and type system required."

---

## Step 7 — Build all.html → screenshot

Write `.mockups/design-full-<slug>/all.html` showing all 14 sections — every variant in both light AND dark mode. Structure: v1-light, v1-dark, v2-light, v2-dark … v7-light, v7-dark. Sticky jump nav with 14 anchors. Each section labeled "vN — [paradigm] — [LIGHT/DARK]". Toggle button per variant switches `data-theme` on that variant's wrapper. ★ recommended marking on the winning variant's light section.

```bash
open ".mockups/design-full-<slug>/all.html"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --window-size=1400,900 \
  --screenshot=".mockups/design-full-<slug>/all.png" \
  "file://$PWD/.mockups/design-full-<slug>/all.html"
```

Show screenshot inline.

---

## GATE 3 — Pick mockup (HARD STOP — nothing builds without this)

Print variant table: `| Variant | Paradigm | One-line description | Recommended |`

Stop and ask: **"Which variant? (v1–v7 / mix — name which ones / redirect)"**

**No token extraction, no plan, no build until this is answered.**

---

## Step 9 — Extract approved tokens

From chosen mockup, extract: palette (hex values), type scale (font families + sizes), spacing scale, layout paradigm name.

Write to `.mockups/design-full-<slug>/approved-tokens.md`.

---

## Step 11 — Opus plan

Spawn Opus agent to write `brainstorms/design-<slug>-plan-<date>.md`. Plan scope: presentation-layer only. Must reference `approved-tokens.md` as the source of truth. List target files as "already exists — do NOT recreate."

---

## GATE 4 — Approve plan

Show plan. Stop and ask: **"Approve plan, or redirect?"**

---

## Step 12 — Chain to /build Phase 4

Hand approved plan + approved-tokens.md to `/build` entering at Phase 4 (TDD → build → regression → prove). The upstream gates are satisfied — do not regenerate mockups.

---

## Step 13 — eli5 final summary

Run `/eli5` on the completed-work summary before presenting.

---

## FALLBACKS

Same embedded Taste / Swiss / UIwiki rule text as `design-audit`.

**Taste:** slop fingerprint — generic card grids, blue/purple/teal defaults, >8px radius, gradient CTAs, glassmorphism, sans-only hierarchy, hero+centered-CTA, shadcn-starter DNA.

**Swiss:** grid discipline, max 3 type sizes, asymmetric balance, generous whitespace, ≤3 colors, function over decoration.

**UIwiki:** 20 rules — hierarchy, contrast, alignment, proximity, consistency, affordance, feedback, error prevention, recognition over recall, minimal load, progressive disclosure, data-ink ratio, status colors, responsive, motion, labels, empty states, loading states, keyboard nav, touch targets.
