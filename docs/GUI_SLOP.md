# GUI Slop Reference
> Split out of `docs/ANTISLOP.md` on 2026-08-18. That file is imported into every session; this
> one is not — it is read on demand, only when there is a screen involved. `docs/ANTISLOP.md`
> keeps the writing tells and points here.
> 42 GUI tells (12 default patterns + 7 template & framing + 8 marketing-page + 7 component + 8 media),
> plus the mockup-only kill rules.
> Every rule states the TELL — what makes the pattern suspicious — so a borderline case can be judged
> instead of pattern-matched.

---

## GUI Slop
> **This list is canonical.** `/design`, `/build`, `/health` and `/debate --ui` all read it — add new patterns HERE and nowhere else.
> The mockup-only kill rules moved in from `UI_MOCKUPS.md` on 2026-08-05 and are now the `### Mockup-only kill rules` subsection below, so this file is the single home. `UI_MOCKUPS.md` keeps mockup *workflow* only — counts, paths, output format — and holds no tells. Do not copy this list into a skill.
> For deep landing-page-specific rules (100+), read `skills/design/vendor/taste-skill/taste-skill.md` §9 on demand — deliberately not merged here (third-party, never edited). That folder is gitignored, so on a fresh clone it is absent; `skills/design/TASTE_CORE.md` is the tracked distillation that always works.

- **Gradient hero banner** — purple→blue full-bleed top section as the default page header
- **Uniform card grid** — rounded cards with drop shadows as the default layout for any list
- **Icon + heading + paragraph triplet** — three equal columns of emoji-or-icon, bold title, two-line description
- **Centered hero CTA** — large centered headline, subtitle paragraph, two buttons (primary + outline)
- **Sidebar nav by default** — left sidebar navigation on a UI with too few destinations to need one
- **Toast for every state change** — toasts are a good pattern; the tell is using them for outcomes the user can already see, or for errors that need a decision
- **Floating action button** — bottom-right FAB for the primary action regardless of context
- **Stock empty-state illustration** — generic SVG blob + heading + CTA on every empty list. A purpose-drawn empty state is good work; the tell is the same bought illustration on every surface
- **Shimmer-everything loading** — animated grey bars as the blanket loading state. **Resolved (this was a real conflict — the vendor taste files correctly recommend skeletons over spinners, and this file used to ban them outright):** a skeleton that mirrors the actual final layout, on content that takes long enough to need one, is CORRECT and must not be rejected. The tell is generic grey bars unrelated to the content shape, or shimmer applied to everything including instant loads
- **Modal confirmation for everything** — modal dialogs for deletes, submits, and alerts that could be inline or undoable
- **Stats row** — four metric cards in a row (number large, label muted) as the dashboard default
- **"Powered by" footer badge** — attribution badge in the bottom-right corner

### Template & framing tells
- **Starter-template look** — could pass as a Tailwind UI, shadcn, or Material UI starter with the copy swapped
- **AI-purple** — mechanically checkable: a fill hue in **240–295°** at **≥35% saturation**, used on filled buttons, CTAs, or hero gradients. Covers every shade of the tell, not a fixed swatch list; the usual offenders are `#6366f1`, `#4f46e5`, `#4338ca`, `#8b5cf6`, `#7c3aed`, `#a855f7`. The tell is that the brand did not choose this colour, the default did
- **No hierarchy beyond size and one accent** — a single blue/purple/teal accent doing all the emphasis work, with type varying only by font-size. The tell is that weight, colour, spacing, and case are all unused
- **Radius as the design** — one large radius (>8px, often `9999px`) on every card, input, button, and image, carrying the entire visual identity. The tell is uniformity, not rounding
- **Glassmorphism as decoration** — frosted blur where there is nothing behind the panel to see. **Guardrail (resolved against the vendor files, which recommend it):** glass is a real choice when it solves overlay-on-imagery or depth-over-content; it is slop when the backdrop is a flat colour, i.e. blur applied to nothing
- **Serif as costume** — a display serif reached for to signal "premium" or "editorial" on a brief that is neither. **Guardrail:** serif is a real choice for genuine long-form reading, editorial, or an existing brand that already uses one; it is slop as a decorative upgrade over sans body copy with no reading argument behind it
- **Fake dark mode** — navy (`#1a1a2e`) standing in for a real dark palette

### Marketing-page tells
> **These are not banned — they are the defaults to break.** Stripe, Linear, and Vercel use every pattern below, well. The tell is shipping ALL of them together, unvaried, in the stock order. Vary at least one per set; a single one of these on a page is not a finding.
- **"Trusted by X companies"** — logo strip / social-proof row
- **Fabricated trust chrome** — logo walls, testimonial faces, review counts, or animated stat counters for relationships and numbers that do not exist. This one IS a hard reject — it is fake precision wearing a UI
- **Testimonial cards** — avatar + star rating + quote, often carousel'd
- **Three-tier pricing** — Starter / Pro / Enterprise, exactly three, middle one highlighted
- **"Get started free"** — that or "Start for free" as primary CTA copy
- **"How it works"** — numbered circle steps
- **Four-column link footer**
- **Full-bleed image banner** — dark overlay + white centered headline

### Component tells
- **Avatar overlap stack** — "+3 users" member-count pile
- **Chip-only categorization** — coloured tag badges as the only category signal
- **Shadow-only dropdown** — white background plus a subtle box-shadow, nothing else
- **Light-blue row hover** — table rows that highlight in pale blue only
- **Right-sliding drawer** — panel from the right with an × close button, used for content that had somewhere else to go
- **"Learn more →"** — generic link text that names no destination (low-priority nit, not a reject on its own)
- **Decorative animation** — fade-in on scroll, entrance bounces, hover `scale(1.05)`, motion serving no information purpose

### Mockup-only kill rules
> Absorbed from `UI_MOCKUPS.md` on 2026-08-05 per the rebuild plan's Chunk 4. These apply when judging a *set* of generated mockup variants, not when reviewing one shipped surface — that scoping is why they are their own subsection rather than being folded into the lists above.
> Survivor quota: a set of 3 needs **at least 1** non-slop survivor; a set of 5 or more needs **at least 2**. If a variant matches, kill it and regenerate with a structurally different paradigm — do not nudge it.

- **Accordion-only** — every group collapsed behind a chevron, with no other structure
- **Floating cards on a tinted ground** — lighter-or-darker background as the only depth device
- **Starter-template twin** — passes as Tailwind UI, shadcn, or Material UI with the copy swapped (same tell as **Starter-template look** above; kept here because in a mockup set it is an instant reject, not a discussion)
- **Radius as the only softening** — corners over 8px doing all the work, applied everywhere
- **Size-only hierarchy** — sans-serif with no weight, spacing, or colour contrast
- **Interchangeable variant** — a layout whose description would fit 3+ other variants in the same set. This is the one rule with no equivalent above: it judges a variant against its *siblings*, so a set of ten competent near-identical mockups fails even when no single one would

**Explicitly NOT slop** — structurally distinct paradigms, and the intended escape route from the rules above: terminal/CLI, Bloomberg data grid, editorial/magazine, bento grid, command palette, split-pane reference, single-column full-bleed, floating action panel, timeline, kanban.

### Media tells
> For AI-generated images, video, logos, and slide decks. Adapted from `febbhav/signs-of-ai-design`.
> These decay fastest — a tell marked *fading* is weaker each model generation and should be stacked, never used alone.
- **Scene logic that disagrees** (image) — shadows falling in different directions, reflections that don't match the scene, background architecture that doesn't resolve. Strong; the most durable image tell, because it is reasoning, not rendering
- **Garbled secondary text** (image) — signage, labels, and small type dissolving into letter-like shapes while the headline is clean. Strong for small text; headline text is now fixed
- **Hands, ears, jewelry, eyewear** (image) — errors under load: a hand gripping an object, glasses arms, earring geometry. Strong when present, but *fading* — simple poses are solved, so check interactions rather than pose
- **Yellow cast and waxy skin** (image) — a uniform warm sepia wash and pore-free skin. Moderate and *fading*; recent models reduced both
- **Frame-to-frame instability** (video) — objects appearing, vanishing, or swapping hands between frames; static walls and fabric shimmering; foliage and crowds churning while the subject stays clean. Strong, concentrated at clip boundaries
- **Dream physics and gait errors** (video) — water, smoke, cloth, and collisions almost right; weightless objects, hair moving with no wind; feet that slide or never plant. Strong, subtler each generation
- **Logo geometric drift** — repeated shapes that aren't actually identical, corner radii that vary, curves wobbling into straights, uneven wordmark spacing and mismatched stroke weights. Strong; the most reliable logo tell, because diffusion approximates geometry instead of constructing it. Related: **mockup-only delivery** — the logo exists only as a glossy render on a fake storefront, with no SVG, no flat version, no one-colour lockup, and it collapses at favicon size. (The blue-purple **gradient orb** is *weak* for authorship — human agencies designed most of the famous ones; it marks the AI-company branding trend, not machine authorship)
- **Deck tells** — charts and stat callouts with round unsourced numbers or unresolved placeholders ("Platform X", "20XX") is strong and near-conclusive; **icon soup** (flat line icons keyword-matched to text, a lightbulb for any idea) is strong when the mismatch shows; **uniform slide grammar** (every slide three or four equal icon-cards, every title six words in Title Case, emoji bullets, identical margins throughout, no slide breaking the grid) is moderate — the tell is uniformity across the whole deck, not any one slide
