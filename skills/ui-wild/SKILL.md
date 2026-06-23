---
name: ui-wild
description: Use this skill when the user types /ui-wild, says 'go wild on the UI', 'redesign this', 'ui bananas', or 'fresh design'. Radical redesign: 10 Opus designer personas, judge pass kills generic AI output, mockup approval gate before any code.
user-invocable: true
argument-hint: "[surface or feature to redesign, e.g. 'sidebar' or 'dashboard']"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Agent
---

Target surface: $ARGUMENTS (if blank — ask user which surface before proceeding)

---

## GOVERNING RULES (non-negotiable on every run)

**Design authority:**
- `ui-ux` skill — 99 UX guidelines, 161 palettes, 57 font pairings, WCAG AA accessibility floor
- Zero reference to current UI during design phase — Opus gets PURPOSE only, not screenshots or current code

**Code safety (Karpathy Rule 3):**
- Touch ONLY the presentation layer — zero logic, zero data, zero API changes
- Never delete a feature — swap how it looks, never whether it exists
- Match existing component structure unless the mockup explicitly requires a new one
- Every changed line traces to the approved mockup — nothing extra

**Regression gate:**
- After implementation → smoke-test the critical path end to end
- Lint + typecheck must pass clean
- `/code-review` pass confirms no logic was touched

---

## Phase 0 — Extract Purpose (NOT current UI)

Read only:
- The app's `PRODUCT.md` or README — what does it do, who uses it, what's the core job
- The target surface's data model — what data flows through it
- Any accessibility or brand constraints in `DESIGN.md`

Do NOT read current component files, screenshots, or CSS. Opus must be blind to the current UI.

State in one line: `"Redesigning [surface] — purpose: [X], data: [Y], constraints: [Z]"`

---

## Phase 1 — 10 Designer Personas (parallel Opus agents)

Spawn 10 Opus agents in parallel. Each gets:
- The Phase 0 purpose brief ONLY
- A unique designer persona (see list below)
- Hard instruction: "Do not reference the current UI. Design from scratch. Your output is a concept brief: name, one-line description, color palette (3 colors), typography direction, layout paradigm, one thing that makes this wildly different from typical SaaS."

**Persona assignments (one per agent):**
1. Editorial magazine art director — whitespace as weapon, bold type hierarchy
2. Brutalist architect — raw grids, high contrast, zero decoration
3. Game UI designer — depth, glow, dynamic states, information density
4. Japanese minimalist — negative space, single accent, restraint
5. 90s rave poster artist — neon, collision, anti-grid, unapologetic color
6. Apple PM circa 2024 — system design, blurs, depth, motion-first
7. Bloomberg Terminal operator — data-dense, monospace, zero chrome
8. Luxury fashion brand director — serif, cream, slow reveal, elegance
9. Accessibility-first engineer — maximum contrast, focus-visible, keyboard-native, no color dependency
10. Figma Community wild card — pick the most upvoted design trend of 2025 and go all in

---

## Phase 2 — Judge Pass (kill AI slop)

Spawn a judge agent with all 10 concept briefs. Instructions:
"You are an adversarial design critic. Reject any concept that matches ANY item in the slop fingerprint list below, or shares visual DNA with more than one other concept in this list. Return only the survivors with a one-line reason each survived."

**Slop fingerprint list (banned patterns — instant reject):**
- Blue, purple, or teal as primary brand color
- Card grid as default layout (3-column card deck, dashboard tile layout)
- Rounded corners (border-radius > 8px) as the primary softening device
- Hero section with centered headline + subtext + CTA button
- Gradient CTA buttons (blue-to-purple, etc.)
- Floating white cards on gray background
- Sidebar nav with icon + label rows
- "Glassmorphism" blur panels as decoration
- Sans-serif everywhere with no typographic contrast
- Looks like it could ship as a Tailwind UI or shadcn starter template
- Stock photo or generic illustration as primary visual
- Progress bars or stats in colored pill badges
- Hollow outline icons as primary iconography
- Animations that serve no information purpose (fade-in on scroll, entrance bounces)
- Footer with 4 columns of links
- "Trusted by X companies" logo strip / social proof row
- Testimonial cards with avatar + star rating + quote
- Pricing table with exactly 3 tiers (Starter / Pro / Enterprise)
- "Get started free" or "Start for free" as primary CTA copy
- Dark mode that's just navy (#1a1a2e) not true dark
- Sticky nav that changes opacity or color on scroll
- "How it works" section with numbered circle steps
- Empty state with centered illustration + "No [items] yet" text
- Search bar as a full-width rounded pill
- Feature grid: icon + title + 2-line description, 3 equal columns
- Full-width image banner with dark overlay + white centered headline
- Skeleton loader placeholders pulsing gray
- Avatar overlap stack showing "+3 users" / member count
- Dropdown menus: white background + subtle box-shadow
- Tag/chip badges with colored backgrounds for category labels
- Table rows that highlight on hover with light blue
- Success toast: bottom-right corner, green checkmark icon
- Monochrome icon set where every icon has identical visual weight
- "Built with ❤️" or "Made with love" in footer copy
- "Learn more →" as generic link text
- Modal or drawer sliding in from the right with an × close button

Minimum 6 survivors required. If fewer than 6 survive, respawn the rejected personas (max **2 respawn rounds total**) with instruction: "Your last concept was rejected for being generic. Go weirder." After 2 rounds, proceed with whatever survivors exist even if fewer than 6 — do not loop further.

---

## Phase 3 — Mockup Gate (HARD STOP — do not skip)

From survivors, build mockups:
- One HTML file per concept at `.mockups/ui-wild/<slug>-vN.html`
- Real design tokens from the concept brief — not the app's current tokens
- Real content — no lorem ipsum, use actual labels/data from the target surface
- At least 2 of the mockups must be in the "wildly different" tier (opposite density, unexpected layout paradigm, unconventional color)
- One combined `.mockups/ui-wild/all.html` with all variants side-by-side, each labeled with persona name + one-line description, ★ on recommended

Open combined file in browser:
```bash
open ".mockups/ui-wild/all.html"
```

Screenshot:
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --window-size=1400,900 --screenshot=".mockups/ui-wild/all.png" "file://$PWD/.mockups/ui-wild/all.html"
```

Show screenshot inline. Show variant table:

| Variant | Persona | One-line | Pick |
|---|---|---|---|
| v1 | Editorial | ... | |
| vN | Wild card | ... | ★ recommended |

**STOP. Ask: "Which variant? (or mix elements from multiple — name them)"**
Do NOT write any production code until user names a variant or describes a mix.

---

## Phase 4 — Extract Design Tokens from Approved Mockup

From the chosen mockup only, extract:
- Color palette (hex values)
- Typography (font family, size scale, weight)
- Spacing scale
- Layout paradigm

Write to `.mockups/ui-wild/approved-tokens.md`. This is the spec Sonnet builds to.

---

## Phase 5 — Sonnet Implementation

**Before dispatching any agent** — read the target surface's current component file + direct imports.

Dispatch Sonnet agents (max 5 at once) with:
- "MUST read your target file + its direct imports before any edit — no edit before read"
- "scope: presentation layer only — no logic, no data, no API"
- Target file (absolute path)
- "Already exists — do NOT recreate: [file]"
- "Match approved mockup variant [vN] exactly — tokens in `.mockups/ui-wild/approved-tokens.md`"
- "Touch ONLY presentation — zero logic, zero data, zero API changes"
- "Do NOT delete any feature — if it exists now, it must exist after"

After all agents complete:
- Run lint + typecheck
- Run `impeccable` skill for token/copy polish

---

## Phase 6 — Regression Gate

1. Start dev server, navigate to target surface in browser
2. Exercise every feature that existed before the redesign — confirm all work
3. Run `/code-review` — confirm zero logic changes in diff, only presentation
4. Run lint + typecheck clean

If anything breaks → fix before declaring done. Do NOT ship a broken feature behind a beautiful UI.

---

## Phase 7 — Summary

| Phase | What happened | Files |
|---|---|---|
| Purpose extract | Surface + data + constraints | — |
| 10 personas | N concepts generated | — |
| Judge pass | N survived, N killed as generic | — |
| Mockups | Variant chosen: vN | `.mockups/ui-wild/` |
| Tokens | Design spec extracted | `approved-tokens.md` |
| Implementation | N files changed | list |
| Regression | All features confirmed working | — |
| code-review | Zero logic changes confirmed | — |
