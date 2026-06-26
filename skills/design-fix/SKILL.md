---
name: design-fix
description: Use this skill when the user types /design-fix, says 'fix this component', 'move this button', 'redesign just the nav', or describes a targeted change to one UI area. Generates 7 variants (5 structural + 2 wild) for ONE component or area — respects current design tokens, no build chain.
user-invocable: true
argument-hint: "[describe the specific change — e.g. move login button to header]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
---

# design-fix

Target: $ARGUMENTS

**SCOPE RULE:** This skill targets ONE component or area only. It does NOT redesign the whole app. It does NOT nuke design tokens. Colors, fonts, and spacing from the current design are LOCKED — only structure/layout/placement may change.

**LIGHT + DARK RULE:** Every mockup HTML file must include both a light-mode section and a dark-mode section with a toggle button. Both themes must use the current design's actual colors. Non-negotiable.

---

## Step 0 — Validate target

If `$ARGUMENTS` is empty or does not describe a specific component or change → ask:

> "What specifically needs fixing? Describe the component and change — e.g. 'move login button to header', 'redesign the sidebar nav', 'fix the data table layout'."

Wait for answer before proceeding.

---

## Step 1 — Detect project + read current tokens

```bash
SLUG=$(python3 -c "import json; print(json.load(open('package.json')).get('name','').replace('/','-').replace('@',''))" 2>/dev/null || basename "$PWD")
head -20 CLAUDE.md 2>/dev/null
```

Read current design tokens — these are LOCKED for this skill:
```bash
cat design-system/MASTER.md 2>/dev/null || cat DESIGN.md 2>/dev/null
grep -r ":root" --include="*.css" -l 2>/dev/null | head -3 | xargs grep -h "^\s*--" 2>/dev/null | head -30
```

Extract and state the locked values:
```
LOCKED:
  Colors: [hex values from tokens]
  Fonts:  [font names from tokens]
  Spacing scale: [values from tokens]
```

---

## Step 2 — Read target component

Find and read the source file(s) for the targeted component. If unclear which file → search:
```bash
grep -r "$ARGUMENTS" --include="*.tsx" --include="*.jsx" --include="*.vue" --include="*.html" -l 2>/dev/null | head -5
```

State: `Target component: [file:line]`

---

## Step 3 — Fan out 7 parallel Sonnet agents

ONE parallel call. Each agent writes `.mockups/design-fix-<slug>/vN.html` — self-contained, inline CSS, realistic content with the LOCKED colors and fonts from Step 1.

`<!-- VARIANT: vN — paradigm name -->` header comment in each file.

Every file must show both light AND dark versions using LOCKED colors — light variant uses current light tokens, dark variant uses current dark tokens (or derives dark from light if dark tokens absent).

**v1–v5 — Structural redesigns:** five different approaches to the SAME targeted component/change. Different layout, hierarchy, placement — but same colors, fonts, spacing scale. Must be materially different from each other.

**v6–v7 — Wild structural:** throw out convention for this component type entirely. Still uses LOCKED colors and fonts. Just the structure/layout is unconventional.

Each agent brief: locked colors + locked fonts + target component description + "do NOT change any color or font value — structural changes only."

---

## Step 4 — Slop judge

Judge agent reviews all 7. Kills variants that:
- Look identical to each other
- Changed a locked color or font (violates SCOPE RULE) → respawn with "you changed a color — reset to [locked value] and try a different layout"
- Are structurally boring / same as current

Respawn rejects with specific brief. Max 2 rounds.

---

## Step 5 — Build all.html → screenshot

Write `.mockups/design-fix-<slug>/all.html` showing all 14 sections — every variant in both light AND dark mode.

Structure: v1-light, v1-dark, v2-light, v2-dark … v7-light, v7-dark.
Sticky jump nav with 14 anchors. Each section labeled "vN — [paradigm] — [LIGHT/DARK]".
★ recommended marking on the winning variant's light section.

```bash
open ".mockups/design-fix-<slug>/all.html"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --window-size=1400,900 \
  --screenshot=".mockups/design-fix-<slug>/all.png" \
  "file://$PWD/.mockups/design-fix-<slug>/all.html"
```

Show screenshot inline.

---

## PICK GATE — Hard stop (no code)

Print variant table: `| Variant | Paradigm | One-line description | Recommended |`

Ask: **"Which variant? (v1–v7 / redirect)"**

**STOP HERE.** No production code written in this skill. To build the chosen variant → take the chosen vN.html to `/build` Phase 4.
