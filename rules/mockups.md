# Mockups: count and format

The single source for how many variants exist and what they look like. `/build` and any
design work both read this file. Changing the number is a one-file edit.

## Four variants, and who writes each

Four genuinely different directions beat eight where half are near-twins, and everything
downstream costs half as much.

| Slot | Direction | Author |
|---|---|---|
| v1, v2, v3 | Each anchored to a distinct layout paradigm | Opus, one parallel call |
| v4 | The adventurous slot, far enough from v1-v3 that nobody calls it a variation | Codex |

**Survival bar: three of the four.** Below that, the rejected slots are regenerated with the
matched pattern named.

Paradigms to pick from: terminal, data grid, editorial, bento, command palette, split-pane,
single-column full-bleed, floating panel, timeline, kanban.

## One page

All four live in one file, `.mockups/<slug>/all.html`, laid out as four rows by two columns:
light on the left, dark on the right. Sticky jump navigation with v1-v4 anchors.

Each variant carries a states strip along the bottom (hover, focus, empty, error, loading, as
real styled boxes) and two or three inline `<!-- ANNOTATION: -->` comments at its least
obvious decisions.

Each is self-contained: inline `<style>`, no external files, openable from disk.

Launch the Codex slot in the background before the Opus call, so it costs no waiting. Claude
writes every file to disk, including Codex's.

Codex absent, or its output failing the read-back check: Opus writes that slot and the round
continues.

## Tokens are the project's

Palette, type, spacing, and radius come from the project's own design system or its CSS. The
data can be invented, with realistic labels at realistic lengths.
