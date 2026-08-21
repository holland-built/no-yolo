# UI / GUI Change Discipline

## The Rule

**Any UI or GUI change requires a mockup page with four variants BEFORE writing production code.** Four, on ONE page, light and dark side by side. The owner's five rules for that page are in the table further down and they govern every skill here.

No exceptions for new components, redesigns, layout changes, or visual refactors. One-line CSS tweaks and pure bug fixes are exempt.

**The mockup does not replace building in the real app; it comes before it.** These are two different steps and they have been confused in both directions:

| Step | Where | What it is for |
|---|---|---|
| The mockup, this doc | A standalone page outside the app | A cheap contract to point at before real code exists |
| The build, `/build` phases 5-6 | Straight into the real component, one surface at a time, checked in the browser before the next | Where "verify it in the real app" applies |

So `memory/facts/feedback-realapp-incremental-ui.md` ("build redesigns into the running app") and the rule above are not in conflict: the fact governs the build, this doc governs what happens before it. `skills/build/SKILL.md` §3.5 Step A0 carries both halves and the session that got it backwards.

**No wild or experimental variants.** All four are real candidates. This line said the opposite until 2026-08-20 ("at least 1-2 must be wildly different... wild variations reveal where the real ceiling is"), and the owner reversed it: a variant nobody would ship is a wasted quarter of the page. Four genuinely different but plausible directions, not three safe ones plus a stunt.

## Slop prohibition (applies to every mockup, every skill)

**Moved 2026-08-05, re-addressed 2026-08-18.** The mockup kill rules, the survivor quota, and the
"not slop" paradigm list live in `~/.claude/docs/GUI_SLOP.md` → `### Mockup-only kill rules`.
Read them there. Nothing about them changed except the address. (They were in `ANTISLOP.md` until
2026-08-18, when the GUI half was split into its own read-on-demand file.)

Why the move: the canonical GUI list says patterns are added "HERE and nowhere else", and this
file held six of them, so the canonical list had two homes. That is the exact duplication the
rebuild's deciding rule forbids: a rule lives in exactly one file; everything else points at it.

Everything below this line is mockup **workflow**, not slop judgement: where files go, how many
variants, what to output. It stays here because it is a different job from a list of tells.

## ALWAYS: pop it in Chrome + keep a master index

Two hard rules, every time a mockup is created or changed:

1. **Open it in Chrome immediately.** After writing/updating any mockup, run `open "<absolute-path>.html"` (macOS) so it pops up in the browser. Never just hand back a path. Show it.
2. **Maintain ONE master index page** that launches every mockup in a single Chrome tab. Regenerate it and `open` it whenever mockups are added/changed.
   - Location: `.mockups/_index.html` (in the current project root)
   - It links/iframes every `*.html` under `.mockups/**` (grouped by folder, with a sticky jump-nav TOC + an "open standalone ↗" per mockup).
   - This is the canonical "show me all the designs" entry point. When the user asks "where are the mockups," send them here.

## Where mockups go: ONE shape, no exceptions

```
.mockups/<skill>-<slug>/<name>.html
```

`.mockups/design-checkout/`, `.mockups/build-nav/`, `.mockups/design-quick-login/`, `.mockups/design-match-cards/`.

- **The leading dot is load-bearing.** `.mockups/` is what every project's ignore rule matches. `/build` once said `mockups/` without it on one line and `.mockups/` on another; the un-dotted path was not covered by the ignore rule, so those files were committable. Audited and fixed 2026-08-01. If you add a skill that writes mockups, this is the line that stops it happening again.
- **The `<skill>-` prefix is load-bearing too.** `/build` used a bare `<slug>`, so building a feature called `quick` would have landed inside `/design` (quick sketch mode)'s folder. Prefix everything.
- **Every project needs `.mockups/` in its own ignore list.** This repo's covers this repo only. Check any project you have run `/design` or `/build` in.
- **Delete intermediate files before finishing:** `codex-wild.out`, `codex-synth.out`, marker files dropped into an app's public dir to verify which server is serving. They are debris, not artifacts, and nothing else cleans them up.

## Why

- Forces visual exploration before committing to one direction
- Side-by-side comparison reveals taste preferences the user can't articulate cold
- Cheap to throw away 3 of the 4; expensive to throw away merged code
- Matches Karpathy Rule 1 (think before coding) for visual work: present multiple interpretations side-by-side; never pick one direction silently

## Tool decision tree

| Situation | Tool | Variants |
|---|---|---|
| Fast throwaway layout sketch, no build | `/design` (quick sketch mode) | 4 style-matched functional variants, one page |
| Manual or ad-hoc mockup (no skill) | this doc's manual flow | 4 |
| Full feature pipeline | `/build` | 4, one page or route (phase 3.5 gate) |
| Fresh design + build pipeline | `/design` | 4 paradigms, the confirmed one feeds the build |

Four everywhere, so there is no count to override. The column used to read 5-8 for the manual
flow and "3 paradigms + 1 adventurous" for `/design`; both were left behind by the 2026-08-20
ruling below and corrected on the same day the rest of this file was.

**Four, and the shape of the page.** The owner set four on 2026-08-18 for `/design`; `/build`
still said ten here and eight in its own gate until 2026-08-20, while that same gate judged
"3 survivors of 4". Three different counts for one job. All three files now say four.

**The owner's rules for a mockup page, stated 2026-08-20 and not up for reinterpretation.** They were described as four when set; the fifth row is the relaxation made in the same conversation, so the table carries five:

| Rule | What it means |
|---|---|
| All options on ONE page | Never one file per variant, never a link to click per option |
| Light AND dark | Both themes visible together, side by side, not a toggle to hunt for |
| Throwaway | It is a contract to point at, not code that gets promoted |
| Looks like the real design | The project's own tokens, palette and type. Its LOOK is real |
| Data need NOT be real | Plausible stand-in content is fine. Real records are not required |

That last row was a relaxation, made 2026-08-20. Both skills had demanded real data. **Lorem
ipsum is still banned**, and the two are not the same rule: fake latin destroys the thing a
mockup is for, because real labels and real name lengths are what break a layout. Plausible
invented content ("Northgate Refit", "£14,280", "3 days overdue") keeps that and costs nothing.

Mockups are also NOT rendered inside the running app. Asked directly on 2026-08-18, the owner
said no; a version of this file briefly said otherwise on 2026-08-20 and was corrected. Building
into the real app is phases 5-6 of `/build`, one surface at a time. See
`memory/facts/feedback-realapp-incremental-ui.md`.

## Manual flow

1. Create a single HTML file at `.mockups/manual-<feature-name>/index.html` in the current project root.
2. Include exactly 4 distinct variants side-by-side, each labeled (Option A, B, C, D).
3. Vary one or more of: layout, color, density, motion, copy, hierarchy.
4. Show plausible content, never lorem ipsum. It does not have to be real records; it does have to have realistic labels and realistic lengths.
5. Show it to the user. Get a pick. Discard the rest.
6. Only then start implementation.

## File Location Convention

- **Source = served location.** No duplicates. Single file at `.mockups/manual-<feature-name>/index.html` in the current project root.
- If the project has a dev server, it may serve mockups at `http://localhost:<port>/.mockups/manual-<feature-name>/index.html`. Check the project's `CLAUDE.md` or `ARCHITECTURE.md` for the port.
- Use kebab-case for the slug.

## Required Output Format

Every time a mockup is created or updated, output **exactly this table** so the user can click straight to it:

```
| File | Path |
|---|---|
| Source | .mockups/manual-<slug>/index.html |
| URL | http://localhost:<port>/.mockups/manual-<slug>/index.html (if dev server serves it) |
```

Substitute the actual port from the project's `CLAUDE.md` or `ARCHITECTURE.md`. Keep the table format.

## Variation Dimensions to Cover

Pick from this list, enough to make the four genuinely different:

- **Layout:** left-rail vs top-rail vs grid vs single-column
- **Density:** compact vs spacious
- **Color:** primary accent (green / teal / coral / neutral)
- **Hierarchy:** visual weight of title vs body vs CTA
- **Motion:** static vs hover vs scroll-triggered
- **Copy:** long-form vs short-form vs icon-only
- **Background:** light vs dark vs tinted
- **Borders:** none vs subtle vs strong
- **Corner radius:** sharp vs soft vs pill
- **Type pairing:** different font combos

## File Output

- One file per feature/change
- HTML preferred (renders in browser)
- Inline CSS or shared stylesheet: single file, no build step needed to preview

## After User Picks

1. Capture the pick in the plan file (`<project-root>/brainstorms/<slug>-plan-<YYYY-MM-DD>.md`, per PLANNING.md)
2. Delete the losing variants
3. Write production code matching the chosen variation exactly
4. Verify in browser preview before claiming done (per TESTING.md)

## Skill Reference

- `/build`: runs the 4-variant mockup gate at phase 3.5
- `/design` (audit mode): read-only audit, 5 lenses → violations table + top-10 improvements
- `/design` (quick sketch mode): fast disposable layout mockups, 4 style-matched lightly-functional candidates on one combined page with an AI pick, reads the project's CSS tokens
- `/design`: fresh design pipeline, 4 mockups -> slop validator -> confirm -> Fable plan -> Opus build
