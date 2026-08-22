# Screens

Read before designing, reviewing, or judging any UI, mockup, or generated image.

This file covers what makes a generated screen recognisably machine-made, and the gates a
screen passes before it ships.

For the design judgement itself, the `styleseed` skill covers colour, type, spacing and
motion. It is one of the optional installs in `INSTALL.md`; when it is absent, the axes
table below is the whole standard.

This sentence claimed "74 rules" until 2026-08-22. The installed skill is a 68-line router
that dispatches to 22 `ss-*` skills, and its rules are generated per project into
`.styleseed/effective-rules.md` or a per-artifact bundle, so there is no fixed number to
name. Searched the whole install for the figure on 2026-08-22 and found nothing supporting
it, so it is gone rather than corrected.

## The look to reach for

A design direction is a set of choices held consistently. Pick one family per axis and hold
it across the whole surface: corner radius, shadow depth, spacing step, icon weight, type
scale, control height. A surface mixing two radius families is a defect, not a variation.

| Axis | Reach for |
|---|---|
| Layout | One named page-shape, chosen on purpose and stated before you write markup |
| Colour | Three or fewer, from the project's own tokens |
| Type | Three or fewer sizes, from the project's own stack |
| Space | One step scale, generous, asymmetric balance over centred symmetry |
| Motion | Springs that start from the current value and stay grabbable, honouring reduced-motion |

## The tells of a machine-made screen

Each is a shape that appears because a model reached for the most average answer. Judge a
variant by asking what the shape is doing, not by matching the list.

- Three equal cards in a row, doing the work a table or a list would do better.
- A hero with a centred headline and a gradient button below it.
- Cards nested inside cards, each with its own border and shadow.
- Gradient text on a heading.
- Emoji standing in for icons.
- Purple-to-blue gradients, and glassmorphic frosted panels.
- Every element the same distance apart, so nothing reads as more important.
- A component library's starter theme shipped unchanged.
- Body text under 14px, or grey text on grey background.

## Mockup content

The look must be the project's: its tokens, its palette, its type, without exception.

The data does not have to be real. Invent records with realistic labels at realistic lengths,
because realistic lengths are what break a layout. "Northgate Refit / £14,280 / 3 days
overdue" exposes what "Lorem ipsum dolor sit" hides.

## The gates

| Gate | Passes when |
|---|---|
| **Variants** | The set described in `rules/mockups.md` exists, on one page, both themes |
| **Judge** | The survival bar in `rules/mockups.md` is met, judged against this file read fresh |
| **Second judge** | Codex grades the screenshot. Advisory: it flags, the first judge decides |
| **Owner picks** | The owner names one variant. No production code before this |
| **Rendered matches** | The built screen, screenshotted, sits beside the chosen mockup and matches on palette, type scale, spacing, radius, and layout |

Nobody grades their own work: a Codex-authored variant is judged by Claude, and Claude's
variants carry Codex's verdict.

## Building the real thing

Mockups live outside the running app, as one standalone page. They are a cheap contract to
point at before real code exists.

The build goes into the real component, one surface at a time, screenshotted in the browser
before the next one starts. The owner judges by what runs.

Extract the chosen mockup's exact values into the project's own design tokens first, then
build components that reference those tokens. A one-off hex code in the finished diff means
a token is missing: add the token.

## Accessibility

Every interactive element reachable by keyboard, in a sensible order, with a visible focus
ring. Text contrast at 4.5:1 or better. Roles and labels present. Touch targets at least
44px.
