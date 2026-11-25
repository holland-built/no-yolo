---
name: site-design
description: "Use when building or redesigning a page, landing page, dashboard or screen, or when the user asks what something should look like. Builds several variants and judges them side by side."
---

# Site Design

One design always looks fine on its own. You only see a weak design next to a strong one.

So never build one. Build three, and judge them together.

## Build three

Default to **three** variants. Stop at five. Past five they stop being different and become noise.

Make them **radically different**. Three versions of the same idea teach nothing. Vary the thing
that actually decides the page: the layout, the density, what leads, what is cut.

When the user gives a screenshot or link as a reference, write one line on what to take from it
(density, spacing, type) and what to leave (its layout, its brand), and hold every variant to it.
Never ask for a reference, because that hands the user a chore.

Compare the variants as static layouts. Add decorative animation only after the user has picked,
because motion hides a weak layout. Keep feedback that a control needs to work, such as a focus
ring or a pressed state, and build motion early only when it is the point of the page.

## Build them on the real page

A blank route is a vacuum. Every variant looks fine in a vacuum.

Mount the variants inside the page that will really host them, with its real header, real
navigation, real data, and real density. Give each one its own `?variant=` URL, then show them
together on one compare page, because the user compares by reading and loses the thread across tabs
or sideways scrolling:

- The page fills the whole browser width and never scrolls sideways at any window size.
- The current version comes first, when one exists. The numbered choices sit beside it only while
  every one stays readable at normal text size. Otherwise they stack underneath it at full width.
- Each decision is a numbered section with numbered choices, picked by clicking on the page.
- The page keeps a visible answer in section order, such as `1 1 1`, with a button that copies it.
  The user can paste that answer into the chat or type the same numbers there.

Only build a new route when the thing genuinely has no page to live inside. Before you do, check
again — an empty route hides the faults a populated one exposes.

## Use real content

Never lorem ipsum. Never invented sample text.

Fake content hides that the layout does not fit the real thing. Use the user's own copy, real
records, longest title and emptiest state.

## Use current browser features

Models lean on old patterns, so look up each dialog, form, table, layout or animation before
writing it:

```bash
DISABLE_TELEMETRY=1 npx -y modern-web-guidance@1.0.1 search "<2-5 word capability>"
DISABLE_TELEMETRY=1 npx -y modern-web-guidance@1.0.1 retrieve "<id>"
```

Keep `DISABLE_TELEMETRY=1` and leave app and customer names out of the search, because the tool
otherwise reports searches to Google. The reply does not mention this unless a guide changed what
the user will see.

## A fresh look before the user sees them

Whoever built a design is the worst judge of it, so a different model looks first. Screenshot every
variant's own `?variant=` URL at 1440 and 390 wide into a temp folder, then send only the
images to the Codex reviewer. Attach two images per variant. If the user gave a reference, attach
it too, screenshotting it first if it is a link; otherwise leave out `reference.png`:

```bash
codex exec --ephemeral --skip-git-repo-check --sandbox read-only \
  -c model=gpt-6.1-sol -c model_reasoning_effort=medium \
  --image /abs/reference.png --image /abs/a-desktop.png --image /abs/a-phone.png \
  --image /abs/b-desktop.png --image /abs/b-phone.png --image /abs/c-desktop.png \
  --image /abs/c-phone.png -- \
  "<which images are the reference and options A, B, C>. <one line on what the page is for>. <if there is a reference, the line on what to take from it and what to leave; do not flag what was taken on purpose>. Styles to flag if present: <the list under 'When all three look the same', minus any the brand or owner keeps>. Answer: 1) Are any two options too alike to be a real choice? If so, which, and what do they share? 2) For each option, the one part that looks generated, where on screen, and what to change. 3) Any listed style present, by option and name. None is a valid answer to 1, 2 or 3. Do not pick a winner and give no scores." < /dev/null
```

Send no code and none of your own opinion, so the review stays independent. Remove any listed style
it finds. Fix each generated-looking part it names, or say in one line why not. If it names two
options as too alike, rebuild one around the fix in "When all three look the same". Do this once,
then retake the screenshots of what changed and look at them yourself, with no second review. It
never picks a winner; the user does, even if they pick the one it criticised. Say in one line what
it changed.

If `codex` is missing or fails, or its output is empty, say "fresh look: couldn't tell" and show
the variants anyway. Skip this step for a fix inside a direction already picked.

These images leave the machine. If any of them, including a reference, would show customer or
private records, swap those records for made-up ones of the same length in the review screenshots
only, and keep the real content on the page. If that cannot be done, skip the review and say so.

## Judge, pick, overwrite

Show all three. The user picks one, or takes parts from each, and the pick is written over the real
page.

Never run a delete command during design work, because each one stops the user with a permission
prompt. Keep variants in a `mockups/` folder listed in `.git/info/exclude`, with the same file names
every round, so the next round replaces the last. A file left over from a bigger round stays there,
unlinked from the compare page. Run a delete only when the user asks for one.

Close your message with the compare page link and the numbers to pick from.

A variant is throwaway code that answered a question. It is not a deliverable.

The variant that stays becomes real code the user maintains alone. Write it with the least code
that does the job: reuse the page's existing components and styles before adding new ones, and
add no settings or features nobody asked for. Never cut accessibility or input checks to get
there — those fail silently. Touch only the page being designed, and once the pick is in,
edit out any code in real files that only the variants used. This is here because evals run without
`~/.claude/CLAUDE.md`, so the skill has to carry it.

Accessibility here means the page still works for someone who cannot see it or use a mouse:
every control is a real `<button>` or `<a>` with a visible focus ring, every input and icon-only
button has a label, images have `alt`, zoom is never disabled, and motion respects
`prefers-reduced-motion`. These are spelled out because a model trims them first when asked for
less code, and nobody notices until a reader hits one.

## When all three look the same

This is the failure mode, and it is the one comparison cannot catch. Three generic variants still
produce a winner, and it is still generic.

The cause is always the same: every variant came from the same defaults, so none of them carries
anything of the subject. A variant built from these is a default, not a direction, so do not add
them:

- a cream or off-white background, or a terracotta accent colour
- one italic or coloured word in a headline
- "01 / 02 / 03" labels, unless the content really is a sequence
- small ALL-CAPS labels above headings, or monospace labels
- pill-shaped buttons, or an arrow (character or icon) in button text
- identical rounded cards with the same grey shadow
- a side list where the current item is only a slightly lighter rounded row
- one grey outline on every secondary button, with plain text inside it
- the same bold heading over a small grey caption on every block
- a large account or customer name above each item in a list; the item's own title leads, with the name under it at body size
- a dark label block at the left end of a strip, with the content in plain columns to its right

If the brand already uses one, keep it. This list matches the one in `~/.claude/shared/AGENTS.md` §7,
so change both together.

The fix is one move. Name a detail that could appear on **this page and no other** — its real
units, its real vocabulary, its real numbers, the convention its own field uses. Put that detail
in, and rebuild the variants around it.

## Review the pick

Once the user has picked, run `/better-interface` on the chosen variant and fix every `HIGH`
finding. A side-by-side pick judges the look; nobody tried the page with a keyboard, at 320px or
at 200% zoom, and those are where a reader gets stuck. Fix `MEDIUM` and `LOW` findings only when
the user asks, because each fix is more code they maintain alone. If the review marks a domain
`Not reviewed`, say which one; do not call the page checked.

## Done

The compare page fills the browser with no sideways scroll and can be picked from. The user has picked a variant, `/better-interface` returns `Approve` on it, and it works on a narrow screen, with the longest real content,
and in its empty, loading and error states, because those are where a layout that looked fine
side by side breaks. Its controls pass the accessibility list above. The pick has overwritten
the real page, no real file still uses a variant, no delete command ran, and nothing outside the designed page changed. No variant
adds a style from that list.
