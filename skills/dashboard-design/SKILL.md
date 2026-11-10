---
name: dashboard-design
description: Design, redesign or critique a dashboard, status page, NOC screen, KPI tiles, stats or metrics page, or any data-heavy screen, in the style the owner picked. Covers KPI tiles, charts, comparisons, heatmaps, status strips, goal bars, ranked lists, hover tips, empty and loading states, light and dark. Use when the user says dashboard, Overview page, status page, KPI, metrics, "make the numbers clearer", or asks whether a data screen is good. Not for single charts in a document (dataviz) or non-data pages (site-design, improve).
---

# Dashboard design

A dashboard answers one question per screen at first glance ("is the network OK right now?"), shows what needs
attention, and puts the action one click away. Every element answers the question, flags a problem, or goes.

Adapted from Otabek Abdiraimov's dashboard-design skill (MIT, see `LICENSE`), with the owner's picks of
2026-11-09 in place of its defaults. The reference files are the author's, lightly edited.

## The owner's picks

The owner compared the author's style with Bloxsmith's, option by option in light and dark, and chose the author's on every one.
These five choices override the banned-style list (kept in `~/.claude/shared/AGENTS.md`, read by both Claude and
Codex) for dashboards only, because the owner chose them knowing each was on that list. The rest of the list, and
the whole list everywhere outside dashboards, still holds.

| Choice | What it means |
|---|---|
| Page and cards | The author's look: soft page (warm off-white in light, near-black in dark), cards with a hairline border, generous round corners and one faint shadow |
| Toolbar | The author's pill group: range, filter, and an "updated" pill with a live dot |
| Selected item | The author's soft tinted fill with a faint ring, on tiles and in menus |
| Words on screen | The author's wordless rule: a number, a unit and one- or two-word labels on screen; every explanation in a tip |
| Patterns kept | Use each where the data calls for it, not on every screen: chart tip with a dashed unfinished period, grey "was N" for tiny bases, pale when healthy and bright only for problems, a goal-line bar instead of dials, no data is not good news, thin share bars under ranked rows, every number says compared to what, a status strip of days per service |

Tokens for both themes are in [references/tokens.md](references/tokens.md). A project with its own design system
keeps its tokens for meaning (Bloxsmith's ok, warn and crit colours) and takes the look above for surfaces,
controls and selection, unless the owner says otherwise for that project.

## Rules that carry the picks

**Wordless still has to be readable by everyone.** A tip that only appears on hover hides the explanation from a
phone, a keyboard user and a screen reader. Every tip opens on hover, on keyboard focus and on tap, and closes on
Escape. The visible label stays the element's accessible name and the tip text is its accessible description
(`aria-describedby`), so a screen reader hears a short name first. A tip holding a link or button stays open while
the pointer moves into it. The few words left on screen are everyday words a US
network engineer says out loud, because the owner rejected jargon menus once already ("Estate").

**Colour means a state.** Grey and one hue for healthy data; amber and red only on what needs a look; blue for
what you click. When a screen is mostly bright, nothing stands out, so healthy stays pale. Each state also carries
a shape, icon or word, because red and green alone are lost on colour-blind readers.

**Numbers are honest.** A number shown twice agrees. Every headline number has one comparison over the same
length of time ("vs same hours yesterday", not "vs first hour"). A base under about 5 shows as grey "was 1", never
a red percentage. Missing data never reads as "all fine": show the cause when it's known (not set up yet, no permission, the
query failed) with the step that fixes it, and otherwise say the data is unavailable. Unfinished periods are dashed.

**The problem carries its action.** Flag the problem where it shows (a red cell in a status strip, an amber goal
bar) with the action beside it, instead of restating it in a sentence elsewhere.

The perception science behind these (encoding ladder, colour rules, bullet graphs, accessibility) is in
[references/perception.md](references/perception.md). Component patterns are in
[references/components.md](references/components.md), layout and widths in
[references/layout.md](references/layout.md), reusable React and Tailwind code in
[references/snippets.md](references/snippets.md), and sources in [references/sources.md](references/sources.md).

## Building or redesigning

Before any UI, write the screen's one question, the three to six numbers that answer it, each problem as a number
("subnet above 90% used", "DNS server down over 5 minutes") and the action for each. These are what the QA pass
checks against, so without them there is nothing to verify.

The owner decides by looking. When the look of a screen is still open, show two or three versions on the real
page before building one for good, as the site-design skill describes, using real data where the page has it and
representative data where it doesn't. A fix inside a direction the owner already picked needs no new round. Keep
any plan to three plain steps.

Design every state: loading, stale (old data dimmed while new loads), error (one note per page), empty, tiny data,
and both themes. A layout that works full of data often breaks empty.

## Critiquing

Look at the screen, then give a one-line verdict, two to four things that work, and issues ranked by harm:
numbers that disagree first, then where the eye lands (is the problem the palest thing?), then hierarchy, then
sentences that should be a tip, then the smells in the table in [references/qa.md](references/qa.md), then polish.
Cover the whole screen, including layout, buttons and colour, because the owner has had to point out a stack of
identical buttons that a wording-only review missed.

## Done

Done is a screen where:

- the QA pass in [references/qa.md](references/qa.md) ran: each component's numbers match an expected answer
  worked out separately, the on-screen sentence count is zero outside tips and empty states, and a one-second look
  lands on the problem;
- screenshots at 1440 and 375 wide, in light and dark, were looked at, not only taken;
- every tip opens on hover, focus and tap;
- when the look was open, the owner picked a version from two or three shown on the real page.
