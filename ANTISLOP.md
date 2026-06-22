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
> This section mirrors the slop fingerprint in `~/.claude/UI_MOCKUPS.md`. Canonical copy for `/antislop` extraction. Update both files when adding patterns.

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
