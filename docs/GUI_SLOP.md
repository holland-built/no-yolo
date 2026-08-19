# GUI Slop Reference
> Split out of `docs/ANTISLOP.md` on 2026-08-18. That file is imported into every session; this
> one is not — it is read on demand, only when there is a screen involved. `docs/ANTISLOP.md`
> keeps the writing tells and points here.
> 65 GUI tells (12 default patterns + 7 template & framing + 8 marketing-page + 23 landing-page
> + 7 component + 8 media), plus the mockup-only kill rules.
> Every rule states the TELL — what makes the pattern suspicious — so a borderline case can be judged
> instead of pattern-matched.

---

## GUI Slop
> **This list is canonical.** `/design`, `/build`, `/health` and `/debate --ui` all read it — add new patterns HERE and nowhere else.
> The mockup-only kill rules moved in from `UI_MOCKUPS.md` on 2026-08-05 and are now the `### Mockup-only kill rules` subsection below, so this file is the single home. `UI_MOCKUPS.md` keeps mockup *workflow* only — counts, paths, output format — and holds no tells. Do not copy this list into a skill.
> The 23 rules under `### Landing-page tells` were harvested from `taste-skill` §9 on 2026-08-19. Until then this line said they were "deliberately not merged (third-party, never edited)", which left the hardest anti-slop list in the setup reachable only on a machine that had vendored an 87 KB third-party file — `TASTE_CORE.md` never carried §9. Harvesting derives rules in this file's words rather than copying a body, so the never-edit rule still holds. The fuller upstream list stays worth opening for a landing page specifically: `skills/design/vendor/taste-skill/taste-skill.md` §9, gitignored, so absent on a fresh clone.

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

### Landing-page tells
> Derived 2026-08-19 from `Leonxlnx/taste-skill` §9 (MIT), which came out of real LLM-generated
> landing-page tests. Written in this file's own words, not copied: the vendored source is
> gitignored and third-party bodies are never edited or committed. Upstream states most of these
> as flat bans; every one below is restated as a TELL with the case where the pattern is right,
> because a rule that cannot be argued with gets pattern-matched instead of judged.
> Deliberately absent because they already exist above: three-equal-feature-cards, shadcn in its
> default state, oversized H1s, numbered step labels, fake review counts, and serif misuse.

**Fake product previews**
- **Div-built product preview** — a dashboard, terminal, task list, or chat window assembled out of styled `<div>`s to fill a hero. Upstream calls this the single most common LLM-design tell. The tell is that the interface depicted does not exist: nothing in it can be clicked, and no screenshot of it could ever be taken. A real rendered component, a real screenshot, or an openly illustrative drawing are all fine
- **Fabricated build stamps** — `v0.6.2-rc.1`, `last sync 4s ago · main`, a fake commit hash inside the fake preview. Sibling of **Fabricated trust chrome** above, which covers invented social proof; this one covers invented engineering detail. The tell is invented status detail added for texture. Real build or status information on a page that genuinely reports it is not this

**Agency-portfolio costume**
- **Ornamental section numbers** — `001 · Capabilities`, `00 / INDEX`, `002 · Featured commission` on sections that are not a sequence. The tell is enumeration standing in for naming: the number tells the reader nothing the heading did not, and there is no order to follow. Genuinely ordered content — steps taken in order, chapters, a ranked list — is numbered for a reason, and the existing **"How it works"** tell already covers stock numbered-step rows
- **Vertical rotated text** — a label turned 90° down the side of a section. The tell is rotation chosen because it reads as "designed", on a page whose composition does not need it. An experimental or agency brief where the rotated element carries real composition is the exception, not the default
- **Hero-bottom decoration strip** — a small mono-caps row across the bottom of the hero: `BRAND. MOTION. SPATIAL.`, `TYPE / FORM / MOTION`. The tell is a strip that neither navigates nor informs. A sticky bottom nav with real links, or a real status/cookie bar, is a different thing wearing the same shape
- **Locale, time and weather strips** — `Lisbon 14:23 · 18°C` in the nav, "working with founders in Lisbon" in the hero. The tell is atmosphere formatted to look like data. Allowed when the brief is genuinely about place or timezone — a distributed studio, a travel brand, a physical venue. A plain contact address in the footer is not this
- **Poetic section labels** — "Field notes", "From the field", "On our desks" heading a quotes or blog block. The tell is a label reaching for craftsman atmosphere while telling the reader less than a plain one would. A distinctive label is fine when it is comprehensible in place and backed by something real: an established brand voice, a recurring series that is actually called that, or a genuine content category
- **Photo-credit caption as decoration** — `Field study no. 12 · Ines Caetano`, `Frame XII · 35mm` under a stock or placeholder image. The tell is credit for a photographer who does not exist, which is fabricated provenance, not styling. Real attribution for a real photo is correct and should stay
- **Pills overlaid on images** — a `<span>` tag floating on a photo: `Brand · 02`, `PLATE · BRAND`. The tell is a label placed on the image for editorial texture rather than to say anything. A caption below the image works; so does a badge carrying real information, like a video duration or a live flag
- **Crosshair and hairline grids as decoration** — thin rules and corner ticks drawn across the layout. The tell is lines that organise nothing: remove them and no relationship is lost. Rules that separate real columns or rows are structure, not decoration

**Micro-typography tics**
- **Middle-dot as the universal separator** — `foo · bar · baz · qux` repeated down the page. The tell is one separator doing every job, so nothing is grouped by anything else. One `·` in a metadata line is normal; a page that separates everything this way needs line breaks, hairlines, or columns instead
- **Decorative status dots** — a small coloured dot before nav items, list rows, or badges. The tell is a dot where there is no state to report, not the number of them. Judge each one by whether it stands for a real state a reader needs to scan: a monitoring table, a service list, or a presence roster may legitimately carry one on every single row
- **Scroll cues** — `Scroll`, `↓ scroll to explore`, an animated mouse wheel at the fold. The tell is labelling an affordance every reader already has. Genuinely non-obvious movement — horizontal scroll, a scroll-driven narrative — can be worth signalling
- **`<br>`-split italicised headline** — `for thirty<br><em>years.</em>`. The tell is that both the break and the italic are decoration rather than emphasis; the headline reads the same without them. A break that fixes a genuinely bad line rag is typesetting
- **Version label in the hero** — `V0.6`, `BETA`, `EARLY ACCESS`, `INVITE-ONLY PREVIEW` as the eyebrow. The tell is launch-status chrome on a page whose brief is not about launch status. When the brief *is* the launch or the preview, it is the headline, not a tell
- **Micro-meta sentence under an eyebrow** — an extra explanatory line sitting between the eyebrow and the headline, usually explaining the section's own restraint. The tell is that the headline already said it. Eyebrow, headline, body is enough
- **Floating corner paragraph** — a giant left-aligned section headline with a small explainer paragraph in the top-right corner, aligned to nothing. The tell is the non-alignment. Put the sub-text under the headline, or build a real two-column header where both sides line up

**Lazy list and table structure**
- **Hairline on every row** — `border-top` *and* `border-bottom` down every row of a long list or spec table. The tell is that boxing every row groups nothing, so a 10-row table reads as 10 unrelated things. Pick one border direction and use it sparsely, or reach for a component built for the content
- **Progress bars standing in for a chart** — a filled track with a partial fill, used to compare values that are not progress toward anything. The tell is a component whose visual grammar promises completion being pointed at ratings, capacities, or scores. Bars are the correct encoding for quantitative comparison; the fix is usually to drop the track, or to keep it only where every bar shares one meaningful maximum. A real progress indicator for something genuinely running is what the component is for

**Default visual reaches**
- **Undifferentiated black ground** — `#000000` as the dark base with every surface, card, and border sitting flat on it. The tell is black arriving as the default and flattening the tonal steps the design needed, not the hex value itself. Black works when the design builds hierarchy over it — elevated greys, borders, imagery, type weight — and it is the right call outright for OLED power saving, high-contrast accessibility themes, and brands that genuinely are black
- **Neon and outer glow** — glow used for emphasis or depth. The tell is light standing in for hierarchy that weight, colour, and spacing should carry. A genuinely neon brand, and a focus ring that has to be seen, are both legitimate
- **Custom mouse cursor** — replacing the system cursor with a dot, ring, or trailing blob. The tell is a cursor changed for style, at a real cost in accessibility and frame rate. A cursor that conveys a mode in a tool — crosshair, eyedropper, grab — is doing a job

**Em-dashes in interface text**
- **Em-dash, at all.** Zero `—` in any text the user can see: headlines, eyebrows, pills, button text, nav items, captions, quote attribution, body copy, alt text. `–` as a separator is banned too. Use a full stop, a comma, a colon, parentheses, or rewrite the line. Ranges take a plain hyphen. A single visible `—` fails the surface. **Owner's ruling, 2026-08-19.** This entry originally scoped the ban to decorative use and kept a judgement call, on the grounds that `docs/ANTISLOP.md` ruled the other way for prose. The owner overruled both: the em-dash is the most recognisable machine-writing tell there is, and every softened version of this rule has been argued away in practice. `ANTISLOP.md` was rewritten to match, so the two files now agree and the binary version is the one that holds. `taste-skill` §9.G reached the same conclusion from production tests, so the upstream pointer no longer conflicts with anything here

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
