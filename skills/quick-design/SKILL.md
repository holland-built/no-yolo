---
name: quick-design
description: Use this skill when the user types /quick-design, says 'show me options', 'mockup this', or 'design options'. Generates 3 parallel UI variants (conservative / modern / wild), opens in Chrome — hard approval gate before any code.
user-invocable: true
argument-hint: "[describe the UI you want to design]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Agent
---

# quick-design

Feature / UI to design: $ARGUMENTS

Three variants, one approval gate. No code until you pick.

**Token rule:** Every variant MUST use the project's real design tokens verbatim — no invented hex codes, no made-up font names. Wild means different *structure*, not different *brand*.

---

## Step 1 — Extract design tokens (do this FIRST, silently)

Search the project for design tokens in this order of preference:

```bash
# CSS custom properties (:root vars)
grep -rh "^\s*--" . --include="*.css" --include="*.scss" \
  -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -60

# Font families
grep -rh "font-family" . --include="*.css" --include="*.scss" \
  -not -path "*/node_modules/*" 2>/dev/null | grep -v "@import" | head -10

# Tailwind config colors/fonts (if no CSS vars found)
find . -name "tailwind.config*" -not -path "*/node_modules/*" 2>/dev/null | head -3
```

Build a token block: `--color-primary`, `--color-bg`, `--color-text`, `--font-sans`, `--radius`, `--spacing-*`, etc.

If NO tokens found: use safe defaults (`#1a1a2e` / `#ffffff` / system-ui) and add a visible `⚠️ No design tokens found — using defaults` note to all variants.

State the token block in ONE line before proceeding: `Tokens: [list of vars found]`

---

## Step 2 — Fan out 3 parallel agents

Spawn all 3 in ONE parallel call. Each writes its own file: `.mockups/quick-<slug>/v1.html`, `v2.html`, `v3.html`.

`<slug>` = kebab-case of the feature description. `<date>` = today.

Give each agent:
- The feature description
- The full token block (paste vars verbatim)
- Its specific design brief (below)
- Hard rule: use ONLY the provided tokens for colors/fonts/spacing

### Agent brief — v1 (Conservative)
> Build a clean, safe implementation. Familiar layout patterns users already know. Prioritize clarity and predictability. Use a structured table, row-list, or timeline — no card boxes. No surprises. Apply the design tokens for all colors, fonts, and spacing.

### Agent brief — v2 (Modern / Polished)
> Build a refined, contemporary design. Strong visual hierarchy, generous whitespace, clear CTA prominence. Use a split-pane layout, editorial typography hierarchy, or data-dense row structure — no floating card boxes. Still recognizable but elevated. Apply the design tokens.

### Agent brief — v3 (Wild)
> Throw out convention. Pick a completely different layout paradigm — examples: command-line terminal aesthetic, full-bleed hero sections with oversized type, data-dense Bloomberg grid, floating action panels, single-column with bold section breaks, bento-grid cards, magazine-style editorial layout. It must look like a different product team designed it. Still apply the design tokens (same colors/fonts) but use them in a radically different spatial arrangement.

Each agent output spec:
- Single self-contained HTML file (no external deps, inline CSS)
- Includes a `<!-- VARIANT: v1|v2|v3 — one-line description -->` comment at top
- Mobile-friendly (min-width: 320px)
- Shows realistic content, not lorem ipsum — invent plausible data matching the feature

---

## Step 2.5 — Slop self-check (HARD gate — before showing user)

After all 3 agents complete, self-check each variant against the slop fingerprint. If a variant's PRIMARY design expression matches any item — kill it, respawn that agent with: "Your concept matched [specific pattern]. Change the layout paradigm entirely." Min 1 non-slop survivor required for this set of 3.

**Slop fingerprint — instant reject:**
- Card grid (same `.card` box repeated N times)
- Accordion-only with no other structure
- Floating cards on a slightly different background as the only device
- Looks like a Tailwind UI, shadcn, or Material UI starter
- Rounded corners (>8px) as the primary softening device
- Badge/pill stat rows as the only data visualization
- Sans-serif + size-only hierarchy (no weight contrast, spacing, or color differentiation)
- Sidebar nav with icon + label rows as the structural feature
- Hero section with centered headline + subtext + CTA button
- Gradient CTA buttons
- Glassmorphism blur panels
- Any layout that could describe 2+ other variants in this same set

---

## Step 3 — Build combined view

After all 3 agents complete, write `.mockups/quick-<slug>/all.html`:

Structure: sticky top nav with `v1 | v2 | v3` jump links, then each variant in a labeled section with a one-line description. Mark recommended with ★.

---

## Step 4 — Pop in Chrome (MANDATORY — both steps)

```bash
open ".mockups/quick-<slug>/all.html"
```

Then screenshot:
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --window-size=1400,900 \
  --screenshot=".mockups/quick-<slug>/all.png" \
  "file://$PWD/.mockups/quick-<slug>/all.html"
```

Show the screenshot inline. Then print the variant table:

| Variant | Layout paradigm | Tokens used | Pick |
|---|---|---|---|
| v1 — Conservative | [one-line description] | ✓ | |
| v2 — Modern | [one-line description] | ✓ | |
| v3 — Wild | [one-line description] | ✓ | ★ recommended |

---

## Step 5 — Approval gate (HARD)

Stop. Ask exactly: **"Which variant? (v1 / v2 / v3 / redirect)"**

Do NOT write any production code until the user picks. If they redirect, loop back to Step 2 with revised briefs. Mockup files stay until after implementation is done.
