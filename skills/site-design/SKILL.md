---
name: site-design
description: Design a page by building several variants and judging them side by side. Use when building or redesigning a page, landing page, dashboard, or screen, or when the user asks what something should look like.
---

# Site Design

One design always looks fine on its own. You only see a weak design next to a strong one.

So never build one. Build three, and judge them together.

## Build three

Default to **three** variants. Stop at five. Past five they stop being different and become noise.

Make them **radically different**. Three versions of the same idea teach nothing. Vary the thing
that actually decides the page: the layout, the density, what leads, what is cut.

## Build them on the real page

A blank route is a vacuum. Every variant looks fine in a vacuum.

Mount the variants inside the page that will really host them, with its real header, real
navigation, real data, and real density. Switch between them with a `?variant=` URL parameter and
a floating bar, so the user flips between them in the browser.

Only build a new route when the thing genuinely has no page to live inside. Before you do, check
again — an empty route hides the faults a populated one exposes.

## Use real content

Never lorem ipsum. Never invented sample text.

Fake content hides that the layout does not fit the real thing. Use the user's own copy, real
records, longest title and emptiest state.

## Judge, pick, delete

Show all three. The user picks one, or takes parts from each. Delete the rest.

A variant is throwaway code that answered a question. It is not a deliverable.

The variant that stays becomes real code the user maintains alone. Write it with the least code
that does the job: reuse the page's existing components and styles before adding new ones, and
add no settings or features nobody asked for. Never cut accessibility or input checks to get
there — those fail silently. Touch only the page being designed, and when the variants are
deleted, remove anything that only they used. This is here because evals run without
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

If the brand already uses one, keep it. This list matches the one in `~/.claude/CLAUDE.md`, so
change both together.

The fix is one move. Name a detail that could appear on **this page and no other** — its real
units, its real vocabulary, its real numbers, the convention its own field uses. Put that detail
in, and rebuild the variants around it.

## Done

The user has picked a variant, and it works on a narrow screen, with the longest real content,
and in its empty, loading and error states, because those are where a layout that looked fine
side by side breaks. Its controls pass the accessibility list above. The other variants and
anything only they used are deleted, and nothing outside the designed page changed. No variant
adds a style from that list. Tell the user what the chosen variant used instead, and ask whether
to ban that too.
