---
name: design-audit
description: Use this skill when the user types /design-audit, says 'audit this UI', 'review the design', or 'find design problems'. Read-only design audit — Playwright screenshot + Lazyweb deep references + Taste/Swiss/UIwiki/a11y/code-health lenses → ranked violations table + top-10 improvements. No gates, no code.
user-invocable: true
argument-hint: "[surface to audit]"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Agent
---

# design-audit

Target: $ARGUMENTS

Read-only. No gates, no code. Output is a ranked findings table you can hand directly to `/design-full` (or `/design-full --fast`).

---

## Step 0 — Detect project, build Lazyweb query profile

```bash
head -30 CLAUDE.md 2>/dev/null
cat package.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('name','?'), d.get('description',''))" 2>/dev/null
head -10 README.md 2>/dev/null
```

Derive: framework, product type (e.g. "dark NOC dashboard", "SaaS admin panel"), audience, use context, density.

State one line: `Project: [type] · stack: [X] · Lazyweb profile: [keywords]`

---

## Step 1 — Screenshot running app (light AND dark)

If a dev server URL is detectable (check package.json scripts, CLAUDE.md, README.md), use Playwright to screenshot the target surface **twice** — once in light mode and once in dark mode (toggle `prefers-color-scheme` via Playwright `colorScheme` option).

If only one mode exists → flag "no dark mode support" as a **HIGH** severity finding.

If app is not running, note it and audit from component source + CSS instead.

---

## Step 2 — Lazyweb deep — real-world reference screens

Query Lazyweb MCP (deep mode) using the Step 0 query profile. Pull 3–6 reference screens of comparable products.

If Lazyweb not installed → skip with: `⚠️ Lazyweb unavailable — skipping references.`

---

## Step 3 — Five lenses in parallel

Spawn 5 parallel Sonnet agents, each returning a findings list in format: `severity | rule | location (file:line) | observed | expected`

**3a — Taste lens**
Sub-skill if installed (`~/.claude/skills/taste`); else use FALLBACKS taste fingerprint below.

**3b — Swiss lens**
Sub-skill if installed (`~/.claude/skills/swiss-design-system`); else use FALLBACKS Swiss principles below.

**3c — UIwiki lens**
Sub-skill if installed (`~/.claude/skills/userinterface-wiki`); else use FALLBACKS 20-rule summary below.

**3d — Accessibility lens**
WCAG 2.1 AA: color contrast ≥ 4.5:1, focus-visible states, keyboard nav, aria labels, motion/prefers-reduced-motion, form labels, error messaging.

**3e — code-health on CSS**
Run `/code-health` on component CSS files for the target surface. Flag hardcoded color values, magic numbers in spacing, inconsistent token usage.

---

## Step 4 — Merge, dedupe, rank

Coordinator merges all lens output, dedupes overlapping findings, ranks by impact:
- CRITICAL: a11y violations, broken hierarchy
- HIGH: legibility, contrast, density issues, missing dark mode
- MEDIUM: consistency, alignment, spacing
- LOW: polish, typography details

Tag each finding with **Mode:** `light` / `dark` / `both` — lens agents must identify which mode the violation appears in.

---

## Step 5 — Output

Print both tables:

**Violations table:**
`| # | Lens | Finding | Severity | Mode | File:line |`

**Top 10 prioritized improvements:**
`| # | Improvement | Why it matters | Effort (S/M/L) | Lens |`

---

## Step 6 — eli5

Run `/eli5` on the summary before presenting — plain English recap.

---

## Auto-save (always on)

Always write full report to `design-system/AUDIT-<project-slug>-<date>.md`.

Project slug derived from:
```bash
python3 -c "import json; print(json.load(open('package.json')).get('name','').replace('/','-').replace('@',''))" 2>/dev/null \
  || basename "$PWD"
```

This file is picked up automatically by `/design-full` — no paste needed.

## Optional `--persist`

`--persist` is now a no-op (kept for backwards compatibility) — all audits auto-save.

---

## FALLBACKS (graceful degradation when sub-skills absent)

**Taste fallback** — slop fingerprint: generic card grids, blue/purple/teal default palette, >8px radius softening on everything, gradient CTAs, glassmorphism panels, sans-only type hierarchy, hero+centered-CTA layout, visible Tailwind/shadcn starter DNA.

**Swiss fallback** — principles: strict grid alignment, restrained type scale (max 3 sizes), asymmetric balance, generous negative space, limited palette (≤3 colors), function over decoration, no gratuitous ornamentation.

**UIwiki fallback** — 20 rules: visual hierarchy, contrast ratio, alignment, proximity, consistency, affordance clarity, feedback on interaction, error prevention, recognition over recall, minimal cognitive load, progressive disclosure, data-ink ratio for tables, status color semantics, responsive breakpoints, motion purpose, label clarity, empty state handling, loading state feedback, keyboard accessibility, touch target size.
