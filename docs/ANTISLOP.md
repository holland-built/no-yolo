# Anti-Slop Reference
> Canonical extraction target for `/prompt-scan` and `/antislop`. One bullet per tell.
> 15 writing tells + 42 GUI tells (12 default patterns + 7 template & framing + 8 marketing-page + 7 component + 8 media).
> Every rule states the TELL — what makes the pattern suspicious — so a borderline case can be judged instead of pattern-matched.

---

## Writing Tells (15)

- **Fake precision** — any number, percentage, duration, or benchmark that was not actually measured: "~40% faster", "saves about 3 hours", "handles 10k requests/sec", a chart axis, a made-up date, a placeholder cost. **This is the worst tell in this file.** The tell is not the number's size, it is that nothing behind it was run. If it was not measured in this session or read from a real source, say what is unknown instead. Inventing a plausible number to make an answer feel finished is the single most damaging thing on this list.
- **Overclaimed completion** — "done", "fixed", "should work now", "fully working", "production-ready" when the code was not run, the test was not executed, or the page was not opened. The tell is a completion claim with no evidence sentence next to it. Either name the thing you ran, or say it is untested.
- **Agree-then-fold** — "You're absolutely right" / "Good catch" followed by reversing a position that was correct. The tell is that the reversal is triggered by the user's tone, not by new evidence. Agreement is fine when the user is right; folding under pushback without a reason is the failure.
- **Sycophantic opener** — "That's a great point", "Excellent question", "You raise an important issue". The tell is praise that carries no information and delays the answer.
- **Current AI vocabulary** — elevate, seamless, unleash, tapestry, testament, holistic, meticulous(ly), nuanced, myriad, embark, unlock, underscore, showcasing. These are the 2026 words, not the 2023 ones. Treated as a density signal: one is nothing, three in a page is a tell. (Note: `implement`, `robust`, `leverage`, `delve`, `utilize` are NOT on this list — they are either normal engineering words or dead memes.)
- **Hype adjectives** — game-changer, cutting-edge, revolutionary, next-gen, best-in-class, powerful, blazingly fast. The tell is an adjective standing in for a fact. Replace with the proof: what it does, how fast, compared to what.
- **Negation reframe** — "This isn't X — it's Y", "It's not just X, it's Y", "not X, just Y". The tell is manufacturing a contrast to sound insightful when the reader never proposed X. If nobody claimed X, delete the first half.
- **Em-dash as default connector** — em-dashes doing the work that commas, colons, and full stops should do, several times in one paragraph. The tell is monotony of connector, not the count. **Do not flag on a raw count** — a document that uses em-dashes deliberately (including this one) is not the target; a paragraph where every clause hangs off a dash is.
- **Rule-of-three padding** — a third example that adds nothing the first two didn't. The tell is the redundant third item, not the count; three genuinely different examples are correct writing.
- **Fake caveats** — "While X is true, it's important to consider Y" where Y is obvious, unrelated, or immediately dropped. The tell is balance performed for its own sake.
- **Unnecessary recaps** — "So to summarize what we just discussed", "As I mentioned earlier", restating the previous three paragraphs before continuing. The tell is re-stating something still on screen.
- **Sign-off CTAs** — "Feel free to ask if you have any questions", "Let me know if you need anything else", "Don't hesitate to reach out". The tell is a closer that adds no next step. A specific next action is not a CTA.
- **Bullet abuse** — bulleting a two-item list, a single sentence, or an argument whose steps depend on each other. The tell is bullets destroying a chain of reasoning. **Scope: prose documents only** — articles, READMEs, emails, commit bodies, docs meant to read as prose. **Never apply this to chat replies, status output, or checklists**, where this setup's house style mandates bullets and tables; flagging those would flag compliant output.
- **Bolded-lead-in bullet walls** — `- **Term** — explanation` repeated down a whole answer, every row the same shape. The tell is density: five or more in a row with no prose between them, so everything reads as equally weighted reference material and nothing is argued. One or a few is a glossary, which is fine (this file is one). A whole reply in that shape is the dominant 2026 assistant tic.
- **Code slop** — comments restating the line below them (`// increment counter by 1`), docstrings that only repeat the signature, and speculative generality: parameters, hooks, config flags, or abstractions added for requirements nobody stated. The tell is code written to look thorough rather than to do a job.

---

## GUI Slop
> **This list is canonical.** `/antislop`, `/design`, `/build`, `/debate --ui`, and `UI_MOCKUPS.md` all read it — add new patterns HERE and nowhere else.
> `UI_MOCKUPS.md` holds a small set of deliberate mockup-specific kill rules *on top of* this list; it does not mirror it. Do not copy this list into a skill.
> For deep landing-page-specific rules (100+), read `skills/design/vendor/taste-skill.md` §9 and `redesign-skill.md` on demand — deliberately not merged here (third-party, never edited).

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
