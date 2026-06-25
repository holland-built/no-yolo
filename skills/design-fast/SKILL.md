---
name: design-fast
description: Use this skill when the user types /design-fast, says 'design options', 'mockup this fast', 'show me design directions', or 'quick mockup'. 7 parallel Sonnet mockups (5 redesign + 2 wild), slop-judged, Chrome screenshot, HARD pick-gate. No code — run /design-full to build.
user-invocable: true
argument-hint: "[surface/feature to design — optionally paste /design-audit output]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Grep
  - Glob
  - Agent
---

# design-fast

Target: $ARGUMENTS

7 variants (5 redesign + 2 wild), one approval gate. No code written. Sonnet — cheap and fast.

**Token rule:** DESIGN.md / MASTER.md / CSS are read as **context, not constraint.** Agents may propose replacing them entirely. State tokens found in one line before fanning out.

---

## Step 0 — Detect project, accept prior audit

```bash
head -20 CLAUDE.md 2>/dev/null
cat package.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('name','?'), d.get('description',''))" 2>/dev/null
```

If the user pasted `/design-audit` output in `$ARGUMENTS` → use it directly. **Skip re-running audit.**

---

## Step 1 — Lazyweb lite — reference screens

Query Lazyweb MCP (lite mode) using the project profile. Quick visual grounding.

If unavailable → skip with: `⚠️ Lazyweb unavailable — skipping references.`

---

## Step 2 — Interface Design MCP — prior decisions

Read prior design decisions for this project. If unavailable → continue.

---

## Step 3 — Read design tokens (context only)

Check for `design-system/MASTER.md` → `DESIGN.md` → extract `:root` CSS vars and Tailwind config. These are **reference only** — agents can propose replacing them. State what was found in one line.

---

## Step 4 — Fan out 7 parallel Sonnet agents

ONE parallel call. Each agent writes `.mockups/design-fast-<slug>/vN.html` — self-contained, inline CSS, realistic content, `<!-- VARIANT: vN — paradigm name -->` header comment.

Each brief includes Taste + Swiss + UIwiki as **reference text** (use FALLBACKS section below if sub-skills absent).

**v1–v5 — Redesigns:** five distinct layout paradigms — materially different, not variations on a theme. Examples: data-dense grid, split-pane command console, editorial hierarchy, timeline/log view, triptych sidebar. Each must look visibly different from the others.

**v6–v7 — Wild:** throw out convention entirely. Different product team energy. Challenge assumptions about what this kind of app should look like.

---

## Step 5 — Slop judge

Judge agent reviews all 7 for slop fingerprint (from FALLBACKS or installed Taste sub-skill). Kills variants that are generic or share too much DNA with another. Respawns rejects with brief: "go weirder — do not reuse [specific pattern]." Max 2 rounds. Proceed with survivors after round 2.

---

## Step 6 — Build all.html → screenshot

Write `.mockups/design-fast-<slug>/all.html` with sticky `v1…v7` jump nav, labeled sections, ★ recommended marking.

```bash
open ".mockups/design-fast-<slug>/all.html"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --window-size=1400,900 \
  --screenshot=".mockups/design-fast-<slug>/all.png" \
  "file://$PWD/.mockups/design-fast-<slug>/all.html"
```

Show screenshot inline.

---

## Step 7 — Design+Refine MCP — side-by-side compare

If installed, run side-by-side comparison across survivors and surface key differences.

If unavailable → skip.

---

## GATE — Hard stop (no code)

Print variant table:
`| Variant | Paradigm | One-line description | Recommended |`

Then ask exactly: **"Which variant? (v1–v7 / redirect)"**

**STOP HERE.** No production code is written in this skill.

- If the user picks a variant → confirm and end.
- If the user wants it built → tell them: **"Run `/design-full` to build from here."**
- If redirect → rewrite briefs and loop from Step 4.

---

## FALLBACKS

Same embedded Taste / Swiss / UIwiki rule text as `design-audit`.

**Taste:** slop fingerprint — generic card grids, blue/purple/teal defaults, >8px radius, gradient CTAs, glassmorphism, sans-only hierarchy, hero+centered-CTA, shadcn-starter DNA.

**Swiss:** grid discipline, max 3 type sizes, asymmetric balance, generous whitespace, ≤3 colors, function over decoration.

**UIwiki:** 20 rules — hierarchy, contrast, alignment, proximity, consistency, affordance, feedback, error prevention, recognition over recall, minimal load, progressive disclosure, data-ink ratio, status colors, responsive, motion, labels, empty states, loading states, keyboard nav, touch targets.
