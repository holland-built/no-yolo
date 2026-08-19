> Distilled from `vendor/taste-skill/taste-skill.md`, plus section 4 salvaged from
> `redesign-skill.md` before that file was deleted on 2026-08-18. This is the
> load-bearing subset for text/copy-brief mockup generation. The vendor dir remains the
> source of truth, and is still read directly for the screenshot/image-to-code path
> (`image-to-code-skill.md`) and for anything not covered here.

## 0. Brief Inference (read the room first)

Before touching code or dials, infer intent from: page kind (landing/portfolio/redesign/
editorial), vibe words used, reference URLs/screenshots/products named, audience (picks the
aesthetic, not your taste), existing brand assets, quiet constraints (accessibility-first,
public-sector, regulated, kids, these OVERRIDE aesthetic preference).

State one line before generating: **"Reading this as: \<page kind> for \<audience>, with a
\<vibe> language, leaning toward \<design system/aesthetic family>."**

If ambiguous, ask exactly **one** clarifying question. Never a dump. If you can confidently
infer, don't ask.

**Anti-default:** do not default to AI-purple gradients, centered hero over dark mesh, three
equal feature cards, generic glassmorphism everywhere, infinite-loop micro-animations, Inter +
slate-900. Reach past these deliberately.

## 1. The Three Dials

- `DESIGN_VARIANCE` (1=Perfect Symmetry, 10=Artsy Chaos)
- `MOTION_INTENSITY` (1=Static, 10=Cinematic/Physics)
- `VISUAL_DENSITY` (1=Art Gallery/Airy, 10=Cockpit/Packed Data)

**Baseline: 8 / 6 / 4.** Overrides happen conversationally, never by editing a file.

### Inference table (design read → dial values)
| Signal | VARIANCE | MOTION | DENSITY |
|---|---|---|---|
| minimalist / clean / calm / editorial / Linear-style | 5-6 | 3-4 | 2-3 |
| premium consumer / Apple-y / luxury / brand | 7-8 | 5-7 | 3-4 |
| playful / wild / Dribbble / Awwwards / experimental / agency | 9-10 | 8-10 | 3-4 |
| landing/portfolio/marketing (default) | 7-9 | 6-8 | 3-5 |
| trust-first / public-sector / regulated / accessibility-critical | 3-4 | 2-3 | 4-5 |
| redesign - preserve | match existing | +1 | match existing |
| redesign - overhaul | +2 | +2 | match existing |

### Use-case presets
| Use case | VARIANCE | MOTION | DENSITY |
|---|---|---|---|
| Landing (SaaS, mainstream) | 7 | 6 | 4 |
| Landing (Agency/creative) | 9 | 8 | 3 |
| Landing (Premium consumer) | 7 | 6 | 3 |
| Portfolio (Designer/studio) | 8 | 7 | 3 |
| Portfolio (Developer) | 6 | 5 | 4 |
| Editorial/Blog | 6 | 4 | 3 |
| Public-sector service | 3 | 2 | 5 |
| Redesign - preserve | match | match+1 | match |
| Redesign - overhaul | +2 | +2 | match |

Use these exact variable names in cross-references. Never invent aliases.

### Dial semantics (technical reference)
- **VARIANCE 1-3 (Predictable):** symmetrical CSS Grid, equal fr-units/paddings, centered.
- **VARIANCE 4-7 (Offset):** negative-margin overlaps, varied aspect ratios (4:3 next to 16:9),
  left-aligned headers over center-aligned data.
- **VARIANCE 8-10 (Asymmetric):** masonry, fractional-unit grids (`2fr 1fr 1fr`), massive empty
  zones (`padding-left: 20vw`).
- **Mobile override:** VARIANCE 4-10 layouts MUST collapse to strict single-column below `md:`
  (`< 768px`).
- **MOTION 1-3 (Static):** no automatic animation; `:hover`/`:active` only.
- **MOTION 4-7 (Fluid CSS):** `transition: all 0.3s cubic-bezier(0.16,1,0.3,1)`, cascading
  `animation-delay` load-ins, animate `transform`/`opacity` only.
- **MOTION 8-10 (Advanced):** scroll-triggered reveals, parallax, scroll-driven animation
  (`animation-timeline` or GSAP ScrollTrigger). `window.addEventListener('scroll')` is a hard ban.
- **DENSITY 1-3 (Art Gallery):** huge section gaps (`py-32` to `py-48`).
- **DENSITY 4-7 (Daily App):** standard spacing (`py-16` to `py-24`).
- **DENSITY 8-10 (Cockpit):** tight paddings, no card boxes (1px line separators), mandatory
  `font-mono` for numbers.

## 2. Brief → Design System Map

Once you have the design read and dials, pick the foundation. Never hand-recreate a system's
CSS if an official package exists. One system per project. Never mix two component libraries.

### 2.A Real design systems: brief maps to system, install (Appendix A)
| Brief reads as… | Reach for | Install |
|---|---|---|
| Microsoft/enterprise SaaS/dashboards | `@fluentui/react-components` (or `-web-components`) | `npm install @fluentui/react-components` |
| Google-ish/Material-flavored product | `@material/web` + Material 3 tokens | `npm install @material/web` |
| IBM-style B2B/enterprise analytics | `@carbon/react` + `@carbon/styles` | `npm install @carbon/react @carbon/styles` |
| Shopify app surfaces | Polaris web components/React | add `<meta name="shopify-api-key" content="%SHOPIFY_API_KEY%" />` + `<script src="https://cdn.shopify.com/shopifycloud/polaris.js"></script>` to app head |
| Atlassian/Jira-style product | `@atlaskit/*` + `@atlaskit/tokens` | `yarn add @atlaskit/css-reset @atlaskit/tokens @atlaskit/button @atlaskit/badge @atlaskit/section-message @atlaskit/card` |
| GitHub-style devtool/community page | `@primer/css` (product) or `@primer/react-brand` (marketing) | `npm install --save @primer/css` / `npm install @primer/react-brand` |
| Public-sector UK service | `govuk-frontend` | `npm install govuk-frontend` |
| US public-sector/trust-first | `uswds` | `npm install uswds` |
| Fast local-business/agency MVP | Bootstrap 5.3 | `npm install bootstrap` |
| Modern accessible React foundation | `@radix-ui/themes` | `npm install @radix-ui/themes` |
| Modern SaaS you own the components for | shadcn/ui | `npx shadcn@latest init` then `npx shadcn@latest add button card badge separator input` |
| Tailwind-based modern SaaS/AI marketing | Tailwind v4 utilities + `dark:` variant | (already a devDependency in most setups) |

### 2.B Aesthetic, not a system (no official package: build honestly)
| Aesthetic | Honest implementation |
|---|---|
| Glassmorphism | `backdrop-filter` + layered borders/highlights; solid-fill fallback for `prefers-reduced-transparency` |
| Bento (Apple tile grids) | CSS Grid, mixed cell sizes |
| Brutalism | Native CSS, monospace, raw borders |
| Editorial/magazine | Serif type, asymmetric grid, generous whitespace |
| Dark tech/hacker | Mono + accent neon, terminal motifs |
| Aurora/mesh gradients | SVG or layered radial gradients |
| Kinetic typography | Native CSS animation, scroll-driven animation, GSAP for hijacks |
| Apple Liquid Glass | Apple-platforms-only; no official web CSS exists, approximate with `backdrop-filter` + layered borders/highlights and label it an approximation |

## 3. Redesign: Six Categories (varying each means)

- **Typography:** font choice/weight range/tracking/case (has character vs. default Inter,
  headline presence, weight variety, tabular numbers for data, sentence case over all-caps).
- **Color & surfaces:** background tone, saturation ceiling, single accent color, consistent
  gray family and light source, tinted (not flat-black) shadows, texture/depth vs. flat.
- **Layout:** symmetry vs. asymmetry, grid choice, max-width containment, card-height/overlap
  handling, whitespace density, alignment rhythm across side-by-side elements.
- **Interactivity:** hover/active/focus feedback, transition duration, loading/empty/error
  states, `transform`/`opacity`-only animation.
- **Content:** realism of names/numbers/dates/avatars, banned AI-copy cliches, active voice,
  sentence case, no Lorem Ipsum.
- **Components:** card elevation only when it communicates hierarchy, button/badge variety,
  non-carousel testimonial patterns, non-tower pricing emphasis, non-modal-default interactions.

## 4. Salvaged 2026-08-18, when `redesign-skill.md` was dropped

That vendored file was judged a shallower duplicate of `taste-skill.md` and deleted. Three
things in it existed nowhere else in this setup, so they are carried here rather than lost.
Names and ordering only, the upstream prose is not reproduced, and the file is recoverable
from the pinned commit in `docs/BORROWED.md` if the detail is ever wanted.

### Three audit categories Section 3 does not cover
- **Iconography:** one icon family, consistent stroke weight and optical size, never mixed sets.
- **Code quality:** as a *visual* signal: hardcoded values, magic numbers, and token drift show
  up on screen as inconsistency before they show up in review.
- **Strategic omissions:** what AI typically forgets rather than gets wrong: the empty state,
  the error state, the long-name case, the zero case, the loading case.

### Upgrade techniques: a vocabulary for "make it feel less flat"
Names only; each is a known industry technique you can look up or brief someone with.

| Area | Techniques |
|---|---|
| Typography | Variable font animation · outlined-to-fill transitions · text mask reveals |
| Layout | Broken grid / asymmetry · whitespace maximization · parallax card stacks · split-screen scroll |
| Motion | Staggered entry · spring physics · scroll-driven reveals |
| Surface | True glassmorphism · spotlight borders · grain and noise overlays · coloured, tinted shadows |

Two upstream suggestions are **deliberately not carried**: smooth scroll with inertia, which
hijacks the browser's own scrolling and is an accessibility and performance problem, and
"add texture to every flat design", which is taste stated as a rule. Both were flagged in the
2026-08-18 comparison as the weakest advice in that file.

Check any of these against `~/.claude/docs/GUI_SLOP.md` before using one, several sit close to
a tell, and the difference is always whether the effect carries information.

### Fix priority: cheapest visible win first
1. Font swap, biggest instant improvement, lowest risk
2. Colour palette cleanup, remove clashing and oversaturated colours
3. Hover, active and focus states, makes it feel alive
4. Layout and spacing, grid, max-width, consistent padding
5. Replace generic components, swap cliché patterns
6. Add loading, empty and error states, makes it feel finished
7. Typography scale and rhythm, the last 10%
