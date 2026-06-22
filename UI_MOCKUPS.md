# UI / GUI Change Discipline

## The Rule

**Any UI or GUI change requires a mockup file with design variations BEFORE writing production code.** The count depends on which tool you use — see the decision tree below.

No exceptions for new components, redesigns, layout changes, or visual refactors. One-line CSS tweaks and pure bug fixes are exempt.

**At least 1–2 of the variations must be wildly different** — different layout paradigm, opposite density, unexpected color treatment, or unconventional structure. Safe incremental variations only reveal safe incremental taste. Wild variations reveal where the real ceiling is.

## Slop prohibition (applies to every mockup, every skill)
> Canonical GUI slop list: `~/.claude/ANTISLOP.md ## GUI Slop`. Run `/antislop` to check any output.

Before presenting mockups to the user, self-check every variant against the slop fingerprint. If a variant matches — kill it, regenerate it with a structurally different paradigm. For sets of 3: minimum 1 non-slop survivor. For sets of 5+: minimum 2.

**Slop fingerprint — instant reject if the variant's PRIMARY design expression is:**
- Card grid (same `.card` box repeated N times, slightly different content)
- Accordion-only (all groups collapsed behind a chevron, no other structure)
- Floating cards on a darker/lighter background as the only device
- Looks like a Tailwind UI, shadcn, or Material UI starter template
- Sidebar nav with icon + label rows as the structural feature (unless the app already uses this)
- Rounded corners (>8px) as the only softening device, applied everywhere
- Badge/pill stat rows as the only data visualization
- Sans-serif + size-only hierarchy (no weight contrast, spacing, or color differentiation)
- Any layout that could describe 3+ other variants in the same set

**Not slop** — structurally distinct paradigms: terminal/CLI, Bloomberg data grid, editorial/magazine, bento grid, command palette, split-pane reference, single-column full-bleed, floating action panel, timeline, kanban.

## ALWAYS: pop it in Chrome + keep a master index

Two hard rules, every time a mockup is created or changed:

1. **Open it in Chrome immediately.** After writing/updating any mockup, run `open "<absolute-path>.html"` (macOS) so it pops up in the browser. Never just hand back a path — show it.
2. **Maintain ONE master index page** that launches every mockup in a single Chrome tab. Regenerate it and `open` it whenever mockups are added/changed.
   - Location: `.mockups/_index.html` (in the current project root)
   - It links/iframes every `*.html` under `.mockups/**` (grouped by folder, with a sticky jump-nav TOC + an "open standalone ↗" per mockup).
   - This is the canonical "show me all the designs" entry point. When the user asks "where are the mockups," send them here.

Mockups live under `.mockups/<group>/<name>.html` in the current project root. The master `_index.html` aggregates them.

## Why

- Forces visual exploration before committing to one direction
- Side-by-side comparison reveals taste preferences the user can't articulate cold
- Cheap to throw away 4 of 5 mockups; expensive to throw away merged code
- Matches Karpathy Rule 1 (think before coding) for visual work — present multiple interpretations side-by-side; never pick one direction silently

## Tool decision tree

| Situation | Tool | Variations |
|---|---|---|
| Quick exploration, no full pipeline | `/quick-design` | 3 (conservative / modern / wild) |
| Manual or ad-hoc mockup (no skill) | this doc's manual flow | 5–8 |
| Full feature pipeline | `/forge` | 10 (phase 3.5 gate) |
| Radical redesign, start from scratch | `/ui-wild` | 6+ survivors after judge pass |

Use the manual flow (5–8) when no skill applies. Use the skill count when a skill is invoked — don't override it.

## How

Use `/forge` for full pipeline (includes 10-variant mockup gate at phase 3.5). Or manually:

1. Create a single HTML file at `.mockups/mockup-<feature-name>.html` in the current project root.
2. Include 5–8 distinct variations side-by-side, each labeled (Option A, B, C…). See decision tree above for skill-specific counts.
3. Vary one or more of: layout, color, density, motion, copy, hierarchy.
4. Show real content, not lorem ipsum.
5. Show it to the user. Get a pick. Discard the rest.
6. Only then start implementation.

## File Location Convention

- **Source = served location.** No duplicates. Single file at `.mockups/mockup-<feature-name>.html` in the current project root.
- If the project has a dev server, it may serve mockups at `http://localhost:<port>/mockup-<feature-name>.html` — check the project's `CLAUDE.md` or `ARCHITECTURE.md` for the port.
- Use kebab-case for the slug.

## Required Output Format

Every time a mockup is created or updated, output **exactly this table** so the user can click straight to it:

```
| File | Path |
|---|---|
| Source | .mockups/mockup-<slug>.html |
| URL | http://localhost:<port>/mockup-<slug>.html (if dev server serves it) |
```

Substitute the actual port from the project's `CLAUDE.md` or `ARCHITECTURE.md`. Keep the table format.

## Variation Dimensions to Cover

Pick 5–8 from this list, depending on what's being designed:

- **Layout** — left-rail vs top-rail vs grid vs single-column
- **Density** — compact vs spacious
- **Color** — primary accent (green / teal / coral / neutral)
- **Hierarchy** — visual weight of title vs body vs CTA
- **Motion** — static vs hover vs scroll-triggered
- **Copy** — long-form vs short-form vs icon-only
- **Background** — light vs dark vs tinted
- **Borders** — none vs subtle vs strong
- **Corner radius** — sharp vs soft vs pill
- **Type pairing** — different font combos

## File Output

- One file per feature/change
- HTML preferred (renders in browser)
- Inline CSS or shared stylesheet — single file simplicity
- Self-contained: no build step needed to preview

## After User Picks

1. Capture the pick in the plan file (`~/.claude/plans/<name>.md`)
2. Delete the 4 losers OR move them to `design-lab/_archive/`
3. Write production code matching the chosen variation exactly
4. Verify in browser preview before claiming done (per TESTING.md)

## Skill Reference

- `/forge` — full pipeline with 10-variant mockup gate (phase 3.5)
- `/ui-wild` — radical redesign: 10 Opus personas + anti-slop judge → 6+ survivors
- `/quick-design` — 3-variant fast generator (conservative / modern / wild)
- `/ui-ux` — design intelligence (palettes, font pairings, UX guidelines) — use before building
- `/impeccable` — live browser polish on a running app *(requires impeccable plugin)*
