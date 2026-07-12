# Astryx component catalog — the Meta UX menu /design and /build reach for

> Meta's open-source React design system (`github.com/facebook/astryx`, MIT, 150+ components).
> This file exists so the fresh-gen mockup agents and the build agents KNOW these advanced
> interactions are available and reach for them proactively — not only when the user names one.
>
> **This is an awareness menu, not a frozen API.** Exact export/prop names must be verified
> against the live Astryx docs at pull time (COMPONENT-PULL MODE step 5). If a component below
> isn't in the installed Astryx version, pick the nearest one or hand-build — never block.
>
> **Only reach for these in a React + npm/bundler project.** Not React, or React-via-CDN with no
> `package.json` (e.g. a babel-standalone page): do NOT use Astryx — mock the behavior / hand-build.

## When to reach for Astryx (proactive rule)
A design "calls for a rich interaction" when it includes any of: a preview-on-hover, live/typeahead
search, an infinite or virtualized feed, a chat/messaging surface, a rich text composer, reactions,
a command palette, or stacked toasts. For those, **prefer the finished Astryx component over
hand-building** — it's accessible, animated, and battle-tested. Theme it to the project's tokens
so it looks like the project, not like Facebook. For plain/static pieces, hand-build as normal.

## The menu

### Hover / preview
- **HoverCard** — rich preview card on hover (profile / link / product peek — the FB profile hover)
- **ReactionBar** — hover / long-press to open an emoji reaction tray

### Search / navigation
- **Typeahead** — live dropdown results as you type; keyboard-nav; recent + suggested sections
- **CommandPalette** — global search / jump-to overlay
- **Tabs / PillNav** — animated active indicator

### Feed / content flow
- **InfiniteFeed** — auto-load-on-scroll, virtualized, skeleton placeholders
- **StoryBar** — horizontal snap-scroll tiles
- **RichCard** — media + actions + reactions, expandable

### Messaging / input
- **ChatBox / Messenger** — threaded bubbles, typing indicator, seen-state, composer
- **RichComposer** — mentions, emoji picker, attachments

### Overlays / feedback
- **Popover / Tooltip / Menu** — smart-positioned, focus-trapped, dismissible
- **Toast / Snackbar** — stacked transient notifications
- **Skeleton** — shimmer placeholders while loading

### Buttons
- **Button** — loading / success morph states, icon+label, segmented, split variants
