# Prefab sourcing — the component-library gate for /design and /build

This file is the shared detection + gate logic both `/design` (`skills/design/SKILL.md`) and
`/build` (`skills/build/SKILL.md`) invoke before any UI is built. It inverts the old
Astryx-only-for-complex-pieces default: **prefab-first**, sourced from whatever component
library the project already has. Astryx is the greenfield fallback, not a universal add-on.

## Default rule

**Prefab-first (DEFAULT).** Every interactive element — button, input, switch, checkbox, radio,
select/dropdown, slider, tabs, tooltip, popover, dialog/modal, toast, menu, date picker,
pagination, accordion/collapsible, table, avatar, badge — is sourced from the project's prefab
component library. Hand-building one of these is the flagged EXCEPTION, never the default.
"Quicker to hand-write," "it's just a simple button," or silence are NOT valid reasons — an
unflagged hand-built primitive is a gate failure.

## Auto-detect (deterministic, first match wins)

Read the project's `package.json` `dependencies` + `devDependencies` (also check `frontend/`,
`web/`, `app/` subdirs for a nested `package.json`) plus marker files. Walk this precedence
table top to bottom — first match wins:

| # | Signal | PREFAB |
|---|---|---|
| 1 | `@astryxdesign/core` in deps | Astryx |
| 2 | `components.json` present OR (`@radix-ui/*` + a `components/ui/` dir) | shadcn |
| 3 | `@radix-ui/themes` or bare `@radix-ui/*` (no shadcn markers) | Radix |
| 4 | `@mui/material` | MUI |
| 5 | `@chakra-ui/react` | Chakra |
| 6 | `@mantine/core` | Mantine |
| 7 | `antd` | Ant |
| 8 | `@heroui/react` or `@nextui-org/react` | HeroUI |
| 9 | `react-aria-components` | React Aria |
| 10 | `daisyui` | DaisyUI |
| 11 | `@headlessui/react` | Headless UI |
| — | any other recognizable component library in deps | that lib |

**Tiebreak** when 2+ signals match: grep `src/**` imports — whichever lib the sibling code
actually imports wins. State the evidence in the sourcing table.

**Outcomes:**
- **(a) Found** → `PREFAB=<lib>`. Source EVERY primitive from it. shadcn: reuse
  `components/ui/*` if the component already exists there, else `npx shadcn@latest add <c>`.
  Others: direct import from the library. Never install a second library beside it.
- **(b) None found, but React + a lockfile** → `PREFAB=Astryx greenfield`. Wire via
  `npx astryx init`; component names ONLY from `skills/design/ASTRYX_CATALOG.md` / real
  `docs.mjs` output.
- **(c) Not React, or React delivered via CDN/babel with no `package.json`** →
  `PREFAB=none`. Hand-build with the project's tokens. The gate collapses to one line:
  `No prefab library applicable (<reason>) — hand-building.`

## The Component Sourcing Table (exact format)

Emitted **in the visible response, before any build dispatch**:

```
## Component sourcing (mandatory gate — emitted BEFORE building)
Prefab library: <lib> — evidence: <what was detected>

| # | Interactive element (surface) | Source | Component | Note |
|---|---|---|---|---|
| 1 | Save button (SettingsPanel) | <lib> | Button | |
```

Rules:
- One row per interactive element in the surface(s) being built.
- `Source` ∈ `{<PREFAB lib>, hand-build}`.
- A hand-build row for a primitive the detected library already provides = **gate FAILURE** —
  fix the row (swap in the library component), don't build it by hand.
- Closed list of valid hand-build reasons — no others accepted:
  1. **"not in `<lib>`"** — verified by a real lookup (shadcn registry, `docs.mjs <Name>` for
     Astryx, or the library's own docs) — compose from the library's primitives where possible.
  2. **"no prefab library"** — outcome (c) only.
  3. **"library component verified insufficient: `<named missing behavior>`"** — only after
     checking the library's real API, not a guess.

## Never-mix rule (strengthened)

The table's `Source` column names **at most one** prefab library per run. Never install a
second library (including Astryx) into a project that already has one — mismatched twin
systems look broken. Always theme sourced components to the project's own tokens.
