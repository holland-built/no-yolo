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

Fake content hides that the layout does not fit the real thing. Use the user's own copy, their
real records, their longest title and their emptiest state.

## Judge, pick, delete

Show all three. The user picks one, or takes parts from each. Delete the rest.

A variant is throwaway code that answered a question. It is not a deliverable.

## When all three look the same

This is the failure mode, and it is the one comparison cannot catch. Three generic variants still
produce a winner, and it is still generic.

The cause is always the same: every variant came from the same defaults, so none of them carries
anything of the subject.

The fix is one move. Name a detail that could appear on **this page and no other** — its real
units, its real vocabulary, its real numbers, the convention its own field uses. Put that detail
in, and rebuild the variants around it.
