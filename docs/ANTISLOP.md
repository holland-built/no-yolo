# Anti-Slop Reference
> Canonical extraction target for `/prompt-scan` and `/antislop`. One bullet per tell. Writing section = 25 tells. GUI section mirrors UI_MOCKUPS.md slop fingerprint.

---

## Writing Tells (25)

- **Filler openers** — "Certainly!", "Great question!", "Of course!", "Absolutely!", "Sure thing!"
- **Fake enthusiasm** — "I'd be happy to help", "I'm excited to share", "What a fascinating question"
- **Hedge stacking** — "It's worth noting that", "It's important to understand that", "It should be mentioned"
- **Vague intensifiers** — "really", "very", "quite", "basically", "simply", "truly", "literally" as emphasis
- **Forbidden words** — delve, leverage, robust, utilize, facilitate, implement, spearhead, synergy, paradigm
- **Em-dash spam** — 3+ em-dashes in a short passage used as a default connector instead of varied punctuation
- **Unnecessary recaps** — "So, to summarize what we just discussed…", "As I mentioned earlier…"
- **Passive-voice conclusions** — "It can be seen that", "It should be noted", "It has been shown"
- **Rule-of-three padding** — forcing three examples or bullet points when one or two suffice
- **Not-only-but-also** — "not only X but also Y" construction overused as sentence template
- **Epochal framing** — "In today's fast-paced world", "In the digital age", "In an era of rapid change"
- **Oxford comma everywhere** — applying it even to two-item lists
- **Let's dive in** — "Let's dive in", "Let's explore", "Let's unpack this", "Let's break it down"
- **Sign-off CTAs** — "Feel free to ask if you have any questions!", "Don't hesitate to reach out!", "Let me know if you need anything else!"
- **Fake caveats** — "While X is true, it's important to consider Y" when Y adds nothing
- **Bullet abuse** — bulleting 2-item lists, single-sentence lists, or content that reads better as prose
- **At-its-core opener** — "At its core", "At the heart of", "Fundamentally speaking"
- **AI self-reference** — "As an AI language model", "As an AI assistant", "I don't have personal opinions but"
- **It-goes-without-saying** — saying something "goes without saying" then saying it at length
- **Use-case hedging** — "This may vary depending on your specific use case", "Your mileage may vary"
- **Conclusion markers** — "In conclusion", "To wrap up", "To summarize", "In summary" at the end of short responses
- **Symmetrical padding** — forcing every sentence into the same parallel structure to appear thorough
- **This-is-particularly-important** — "This is particularly important because", "This is especially relevant when"
- **Moving-forward filler** — "Moving forward", "Going forward", "As we move ahead"
- **Self-congratulatory meta** — "That's a great point", "Excellent question", "You raise an important issue"

---

## GUI Slop
> **This list is canonical.** `/antislop`, `/design`, `/build`, and `UI_MOCKUPS.md` all read it — add new patterns HERE and nowhere else.
> `UI_MOCKUPS.md` holds a small set of deliberate mockup-specific kill rules *on top of* this list; it does not mirror it. Do not copy this list into a skill.

- **Gradient hero banner** — purple→blue full-bleed top section as default page header
- **Uniform card grid** — rounded cards with drop shadows as the default layout for any list
- **Icon + heading + paragraph triplet** — three-column "Features" section with emoji or icon, bold title, description
- **Centered hero CTA** — large centered headline, subtitle paragraph, two buttons (primary + outline)
- **Sidebar nav + content area** — left sidebar navigation as default even for simple UIs
- **Toast notification stack** — bottom-right floating toasts for every state change
- **Full-bleed section alternation** — white section, grey section, white section rhythm with no variation
- **Avatar + name + role card** — team member card with circular avatar, name bold, role muted
- **Progress bar everywhere** — horizontal progress bars for steps, onboarding, and profile completion
- **Floating action button** — bottom-right FAB for primary action regardless of context
- **Empty state with illustration** — SVG illustration + heading + CTA button for every empty list
- **Skeleton loader shimmer** — animated grey bars as loading state for all content
- **Modal confirmation for everything** — modal dialogs for delete confirmations, form submissions, alerts
- **Breadcrumb on every page** — breadcrumb navigation even on flat single-level UIs
- **Stats row** — four metric cards in a row (number large, label muted) as dashboard default
- **Hover scale transform** — `transform: scale(1.05)` on card hover as default interaction
- **Dark mode toggle in header** — sun/moon icon toggle as a feature rather than system pref
- **Rounded pill buttons** — `border-radius: 9999px` on all buttons regardless of context
- **Table with alternating row shading** — zebra stripe tables as default, even for small datasets
- **"Powered by" footer badge** — attribution badge in bottom-right corner

### Template & framing tells
- **Starter-template look** — could pass as a Tailwind UI, shadcn, or Material UI starter with the copy swapped
- **Accent-only color** — blue, purple, or teal as the ONLY accent, with zero typographic contrast
- **Radius as the design** — rounded corners (>8px) carrying the entire visual identity
- **Flat type** — sans-serif body with no hierarchy beyond font size
- **Glassmorphism panels** — frosted blur panels used as decoration
- **Fake dark mode** — navy (#1a1a2e) standing in for true dark
- **Accordion-only** — everything collapsed behind chevrons with no other structural idea

### Marketing-page tells
- **"Trusted by X companies"** — logo strip / social-proof row
- **Testimonial cards** — avatar + star rating + quote
- **Three-tier pricing** — Starter / Pro / Enterprise, exactly three
- **"Get started free"** — that or "Start for free" as primary CTA copy
- **"How it works"** — numbered circle steps
- **Four-column link footer**
- **Feature grid** — icon + title + 2-line description in 3 equal columns
- **Full-bleed image banner** — dark overlay + white centered headline
- **Sticky nav opacity shift** — nav that fades or recolors on scroll

### Component tells
- **Hollow outline icons** — as the only iconography
- **Uniform icon weight** — monochrome set where every icon reads identically
- **Gradient CTA** — blue-to-purple, teal-to-green button fills
- **Avatar overlap stack** — "+3 users" member-count pile
- **Chip-only categorization** — colored tag badges as the only category signal
- **Pill search bar** — full-width rounded search input
- **Shadow-only dropdown** — white background plus a subtle box-shadow, nothing else
- **Light-blue row hover** — table rows that highlight in pale blue only
- **Bottom-right success toast** — green checkmark, corner placement
- **Right-sliding modal/drawer** — with an × close button
- **"Learn more →"** — generic link text
- **Decorative animation** — fade-in on scroll, entrance bounces, motion serving no information purpose
