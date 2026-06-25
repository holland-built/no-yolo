---
name: design-full
description: Use this skill when the user types /design-full, says 'full design pipeline', 'design and build this', or 'redesign and ship'. Full pipeline — audit → debate direction → 7 Opus mockups (5 redesign + 2 wild) → slop judge → 4 hard gates → token extraction → Opus plan → chains to /build. Nothing builds without an approved mockup.
user-invocable: true
argument-hint: "[surface/feature — optionally paste /design-audit output]"
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

Full design-to-code pipeline. Four hard gates. Opus mockups. Chains to `/build`.

**Nothing builds without an approved mockup (Gate 3). This is non-negotiable.**

**Token rule:** DESIGN.md / MASTER.md / CSS are **context, not constraint.** Agents may propose replacing them entirely. Nothing is locked until Gate 3.

---

## Step 0 — Detect project

```bash
head -20 CLAUDE.md 2>/dev/null
cat package.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('name','?'), d.get('description',''))" 2>/dev/null
head -10 README.md 2>/dev/null
```

State: project type, stack, target surface.

---

## Step 0b — Audit

If the user pasted `/design-audit` output in `$ARGUMENTS` → accept it. **Skip re-running the audit.**

Otherwise → run `/design-audit` now on the target surface.

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

## Step 3 — Interface Design MCP — prior decisions

Read prior design decisions for this project. If unavailable → continue.

---

## Step 4 — Read design tokens (context only)

Check `design-system/MASTER.md` → `DESIGN.md` → CSS `:root` vars. **Reference only, not a constraint.**

---

## Step 5 — Fan out 7 parallel Opus agents

ONE parallel call (Opus). Each agent writes `.mockups/design-full-<slug>/vN.html` — self-contained, inline CSS, realistic content.

Each brief carries the Gate-2 direction + **full Taste/Swiss/UIwiki sub-skill calls** (FALLBACKS if absent).

**v1–v5 — Redesigns:** five distinct paradigms grounded in the approved direction. Must be materially different from each other.

**v6–v7 — Wild:** challenge assumptions about what this kind of product should look like. Break convention.

---

## Step 6 — Slop judge

Kill generic or shared-DNA variants, respawn rejects with specific brief, max 2 rounds.

---

## Step 7 — Build all.html → screenshot

Write `.mockups/design-full-<slug>/all.html` with sticky `v1…v7` jump nav.

```bash
open ".mockups/design-full-<slug>/all.html"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --window-size=1400,900 \
  --screenshot=".mockups/design-full-<slug>/all.png" \
  "file://$PWD/.mockups/design-full-<slug>/all.html"
```

Show screenshot inline.

---

## Step 8 — Design+Refine MCP — side-by-side compare

If installed, run side-by-side comparison. If unavailable → skip.

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

## Step 10 — Write decision to Interface Design MCP

Persist the chosen direction + tokens to Interface Design MCP for this project.

If unavailable → skip with note.

---

## Step 11 — Opus plan

Spawn Opus agent to write `brainstorms/design-<slug>-plan-<date>.md`. Plan scope: presentation-layer only. Must reference `approved-tokens.md` as the source of truth. List target files as "already exists — do NOT recreate."

---

## GATE 4 — Approve plan

Show plan. Stop and ask: **"Approve plan, or redirect?"**

---

## Step 12 — Chain to /build Phase 4

Hand approved plan + approved-tokens.md to `/build` entering at Phase 4 (TDD → build → regression → prove). The upstream gates are satisfied — do not regenerate mockups.

Use Magic MCP for component stubs where useful.

---

## Step 13 — eli5 final summary

Run `/eli5` on the completed-work summary before presenting.

---

## FALLBACKS

Same embedded Taste / Swiss / UIwiki rule text as `design-audit`.

**Taste:** slop fingerprint — generic card grids, blue/purple/teal defaults, >8px radius, gradient CTAs, glassmorphism, sans-only hierarchy, hero+centered-CTA, shadcn-starter DNA.

**Swiss:** grid discipline, max 3 type sizes, asymmetric balance, generous whitespace, ≤3 colors, function over decoration.

**UIwiki:** 20 rules — hierarchy, contrast, alignment, proximity, consistency, affordance, feedback, error prevention, recognition over recall, minimal load, progressive disclosure, data-ink ratio, status colors, responsive, motion, labels, empty states, loading states, keyboard nav, touch targets.
