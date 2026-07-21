---
name: match-all
description: Use this skill when the user types /match-all, says 'make the others match this', 'match all of these to this one', or 'apply this one everywhere'. Point at ONE perfected UI instance (the golden); the skill conforms every sibling instance of that component to the golden's design LANGUAGE — adapted per sibling, never a clone. Too-basic siblings are elevated to the standard; null/empty/missing content is hidden, given a sensible fallback, or resized — never a copied placeholder or empty box. Visual/UI only. Discovery proposes candidate siblings and you uncheck exceptions; a before/after preview renders to disposable .mockups artifacts and no production file is touched until you confirm; every changed surface is screenshotted and side-by-side compared to the golden before done.
user-invocable: true
model: opus
argument-hint: "[golden: component name | file:line | 'this rendered thing'] [--scope <dir>] [--batch <n>]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
---

# match-all

Golden: $ARGUMENTS

## What this is

One perfected instance goes in; every sibling instance of that component comes out conformed to its design language. The language broadcasts across siblings — the content each sibling already holds stays exactly its own.

## Guardrails (HARD)

- Visual/UI only. Never touch logic, data, or behavior. If asked to also propagate a code pattern, that's out of scope — say so and stop.
- No production file is written until the uncheck-gate is confirmed (Step 4).
- Never copy a placeholder or dummy string from the golden, and never leave an empty box.
- Done means every changed surface is screenshotted and visually matches the golden. A clean `tsc`/lint run is NOT done on its own.
- Disposable previews live under `.mockups/match-all/<slug>/` and are cleaned up in every path (applied, skipped, or cancelled).

## Step 1 — Identify the golden + discover siblings

- **1a. Resolve the golden from $ARGUMENTS.**
  - `file:line` given → read that file, identify the component at that location.
  - Component name given → grep for its definition.
  - `"this rendered thing"` or no argument → ask the user for a `file:line` or component name in ONE plain question. Don't guess.
- **1b. Establish component identity** using the PREFAB import-grep primitive (reference `skills/design/PREFAB_SOURCING.md:17-40`): grep the golden's own import statement plus its JSX tag / component name / ARIA role.
- **1c. Enumerate siblings** — every OTHER instance of that same identity across the tree, matched by component name, JSX tag, or role. Do not stop at the first match; keep searching the whole scope.
- **1d. Bounded scope + default exclusions.**
  - Restrict to `--scope <dir>` if given, else the golden's app/package root.
  - Exclude by default: `node_modules`, `dist`/`build`/generated output, third-party/library components (imported from a package, not project source), and intentional variants (explicit `variant`/`size` prop, `*Compact`/`*Mini` names, `data-variant` attribute).
  - List every exclusion with its reason — never silently drop a candidate.
- **1e. Emit a candidate table:**

  | # | file:line | why included (matched name/tag/role) | included/excluded + reason |
  |---|-----------|----------------------------------------|------------------------------|

  Cap the batch at `--batch <n>` (default 8). If more candidates exist, process the first n and note the remainder as a follow-up run. Discovery only PROPOSES — the user confirms at Step 4.

## Step 2 — Extract the golden's language

- **2a.** Render the golden in isolation and getComputedStyle-harvest it (reference mockup-match Law 4, `skills/design/SKILL.md:107`, repointed from a mockup FILE to the rendered app component): read computed spacing, sizing, color, radius, type, shadow, and the structural pattern.
- **2b.** Write an approved-tokens.md-style doc to `.mockups/match-all/<slug>/language.md` (reference /design's approved-tokens.md format, `SKILL.md:260`).
- **2c.** Split explicitly:
  - **LANGUAGE (broadcast):** palette, type scale, spacing rhythm, radius, shadow, structural pattern.
  - **CONTENT (per-sibling, never broadcast):** text, labels, counts, images, item data.
  - A value that is content dressed as a token (e.g. a hardcoded "3 items") stays content.

## Step 3 — Per-sibling adaptive transform

For each confirmed sibling, apply the language — adapting, never cloning.

- **ELEVATE** a too-basic sibling: if it lacks the golden's structural pattern (missing states, no spacing rhythm, flat where the golden is layered — fewer structural elements than the golden's pattern), rebuild it to the golden's structure, then pour in the sibling's OWN real content.
- **Variable / empty / missing content**, per field, pick ONE in this order:
  1. **Hide** — if the golden's layout still reads without it.
  2. **Sensible fallback** — if load-bearing and a real neutral default exists (em-dash for an empty metric, initials avatar for a missing image).
  3. **Resize/reflow** — so the absence isn't an empty box.
- Never copy the golden's literal content as a placeholder. Never leave a visible empty box.
- Content the sibling already has is kept verbatim — only the language around it changes.
- If a sibling genuinely can't take the language (fundamentally different data shape), flag it as an exception in the summary instead of forcing it.

## Step 4 — Uncheck-gate + before/after preview (HARD)

- **4a.** Render BEFORE and AFTER for every candidate to disposable artifacts under `.mockups/match-all/<slug>/` (never a production path). Screenshot both with the Chrome CLI (invocation in Step 5). Build one `all.html` (before | after per sibling), same pattern as /design's all.html. Show it inline and `open` it.
- **4b.** Show the Step 1e candidate list and ask ONCE: "Apply to these? Uncheck any to skip. (all / skip #,# / cancel)".
- **4c.** No production file is touched before this confirm. On cancel, discard everything.
- **4d. Cleanup (HARD):** remove `.mockups/match-all/<slug>/` in every path — applied, skipped, or cancelled (reference /design's COMPONENT-PULL cleanup law, `SKILL.md:81`). If it can't be removed, STOP and report.

## Step 5 — Apply + verify

- **5a.** Dispatch Sonnet subagents to edit confirmed siblings, split into disjoint file clusters with no overlap. Each agent gets `language.md` plus its sibling's Step-3 decisions. The coordinator reads each target file plus its direct imports first, and marks "already exists — do NOT recreate."
- **5b.** Reuse gate: siblings that map to a PREFAB component get the language applied via tokens/props, not a hand-rolled twin.
- **5c.** Run `tsc` + lint + build — zero new errors — before the visual gate.
- **5d. Visual-diff gate** (reference /design Step 5.6, `SKILL.md:274`): screenshot each changed surface with the Chrome CLI, place it beside the golden's PNG, compare palette, type scale, spacing rhythm, radius, and structure. Do not declare done on a visible mismatch — fix and re-shoot; loop until it matches.
- **5e.** Screenshot invocation, verbatim:

  ```
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --window-size=1400,900 --screenshot="<out>.png" "file://<in>"
  ```

- **5f.** Run /eli5 on the completed-work summary before presenting it.

## Scope redirects

- "Match this mockup" / a supplied HTML mockup targeting one surface → redirect to /design MOCKUP-MATCH.
- "Redesign all fresh" with no golden → redirect to /design fresh-gen.
- Non-visual "make them behave the same" (logic/state) → out of scope. Say so and stop.
