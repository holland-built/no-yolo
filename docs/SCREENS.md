# Screens

Read before designing, reviewing, or judging any UI, mockup, or generated image.

This file covers what makes a generated screen recognisably machine-made, and the gates a
screen passes before it ships.

The axes table below is the whole standard for design judgement. It used to be the fallback
for an installed skill; that skill was retired on 2026-08-25 and `docs/DECISIONS.md` records
why, along with the count this file published wrongly while it was here.

For a look rather than a judgement, `/design` renders three real brand specifications out of
`refs/brands/` and you point at one.

## The look to reach for

A design direction is a set of choices held consistently. Pick one family per axis and hold
it across the whole surface: corner radius, shadow depth, spacing step, icon weight, type
scale, control height. A surface mixing two radius families is a defect, not a variation.

| Axis | Reach for |
|---|---|
| Layout | One named page-shape, chosen on purpose and stated before you write markup |
| Colour | Three or fewer, from the project's own tokens |
| Type | Three or fewer sizes, from the project's own stack |
| Space | One step scale, generous, asymmetric balance over centred symmetry |
| Motion | Nothing animates until it passes the gate below. What survives starts from the current value, stays grabbable, and respects reduced-motion |

## The tells of a machine-made screen

Each is a shape that appears because a model reached for the most average answer. Judge a
variant by asking what the shape is doing, not by matching the list.

**The brief outranks everything below.** Where the brief names a direction, follow it exactly,
including when it asks for one of the three combinations named next. This section governs the
axes the brief left free. It is about what gets reached for by default, and a default is only
a default when nobody chose it.

### The three combinations, from `frontend-design`

Anthropic's `frontend-design` skill, Apache-2.0, cited in `docs/BORROWED.md`, names what
generated design converges on. **Each is a combination, and the combination is the tell.** A
cream background is not a fault, a serif is not a fault, and terracotta is not a fault. All
three together, unasked, is the fault.

1. A warm cream background near `#F4F1EA`, a high-contrast serif display face, a terracotta
   accent.
2. A near-black background with one bright acid-green or vermilion accent.
3. A broadsheet layout: hairline rules, zero corner radius, dense newspaper columns.

The hex code is there so the check is measurable. Sampling `#F4F1EA` off your own render, on a
brief that never asked for it, is evidence rather than an impression.

### The shapes

- Three equal cards in a row, doing the work a table or a list would do better.
- A hero with a centred headline and a gradient button below it.
- Cards nested inside cards, each with its own border and shadow.
- Gradient text on a heading.
- Emoji standing in for icons.
- Purple-to-blue gradients, and glassmorphic frosted panels.
- An accent rail down one edge of a card, in the same colour the card's own value is already
  printed in. It marks nothing, sorts nothing and links to nothing.
- Every element the same distance apart, so nothing reads as more important.
- A component library's starter theme shipped unchanged.
- Body text under 14px, or grey text on grey background.

## Spend the boldness in one place

From `frontend-design`, Apache-2.0. A surface gets **one** signature element, the thing it
will be remembered by. Everything around it stays quiet and disciplined. Boldness spread
evenly across a surface reads as noise, and nothing in it is memorable.

Before the set is shown, name the one nonessential element you cut. If everything on the
surface is doing a job, record that instead: "nothing cut, every element named a job." Both
answers pass. Only silence fails, because silence is what a surface nobody subtracted from
looks like.

## Colour earns its place by encoding something

The rail above is worth its own rule, because it is the shape a model reaches for whenever a
surface looks flat and it has no fact to make it less so.

**Every use of an accent colour answers "what does this one mean that its neighbours do not?"**
A status, a category, a threshold crossed, a selected row, a series in a chart: each of those
is a fact, and the colour is how the fact is read. A stripe applied to every card in the grid
answers nothing, so it is paint.

Two consequences worth stating, because both were reached for instead:

- **Hierarchy comes from size, weight and space.** A number that should dominate gets to be
  larger, heavier, or better spaced than what surrounds it. Painting it and then painting a bar
  beside it says the same thing twice and still has not made it bigger.
- **One meaning, one channel.** When the value is already in the accent colour, a rail in that
  colour carries no second reading. Give the rail a different job or take it out.

Checking it: for each coloured element in a variant, name the fact it encodes. Anything whose
answer is "it looked plain" comes out before the set is shown.

### The project's tokens decide the notation

**The rule above this one still wins: colour comes from the project's own tokens, without
exception.** The tokens carry their notation with them, and that notation is the project's
too. From `better-colors`, MIT:

> A consistent hex system beats hex with `oklch()` scattered through it.

So `oklch()` is the right default only when a token system is being created from nothing.
Dropping it into a project whose tokens are hex makes the palette harder to reason about and
buys nothing. Converting a whole system is a migration, and a migration is its own job.

### One filled action per decision

Where a surface asks the reader to decide, at most one action carries the filled accent and
its peers stay neutral, with the colour on the button's background rather than on its label.
Accent-coloured text on a neutral button reads as a link.

Scope this to decisions. A surface that asks for no decision needs no filled action, and
inventing one to satisfy this rule is worse than leaving it out. Several coloured backgrounds
at once are correct when each encodes a distinct state or category, which is the rule above
this one doing its job.

## Motion: the gate, then the invariants

Adapted from Emil Kowalski's `find-animation-opportunities`, MIT, cited in
`docs/BORROWED.md`. The order matters: eligibility is decided first, and the invariants then
constrain whatever survived. Applying the invariants to a candidate the gate would have
rejected produces a well-behaved animation that should not exist.

### 1. Exposure decides eligibility

Not how often the animation runs, but **how often one user meets this component in ordinary
use of the product**. A scroll reveal a reader passes once per visit is a rare moment, even
though the animation fires on every visit.

| How often one user meets it | Verdict |
|---|---|
| Constantly: command palettes, keyboard shortcuts, core navigation, focus jumps | **Never animate.** Not a judgement call. Repetition turns motion into lag |
| Many times a session: hover states, list navigation, frequent toggles | Reject, or motion so fast it is barely perceived |
| Occasionally: modals, drawers, toasts, settings | Eligible |
| Rarely, or once: onboarding, empty states, success, a marketing scroll | Eligible. The budget for delight lives here and nowhere else |

### 2. Purpose must be one of six words

Name it explicitly. If none of these fits, the candidate is rejected.

Feedback. Spatial consistency. State indication. Preventing a jarring change. Explanation.
Delight, and delight only at the rarest tier.

"It looks good" is not on the list.

### 3. Duration has a budget

**The project's own motion tokens set the durations and the easing curves.** Read them and
extend them. Inventing a parallel scale beside an existing one is the same defect as a
one-off hex code beside a colour token.

Where a project carries no motion tokens, the numbers below are a starting point to propose,
not a standard to enforce. They are one design engineer's house style, and they are here so
the conversation starts somewhere specific rather than at "how long should this be?".

| Element | Starting point |
|---|---|
| Press feedback | 100 to 160ms |
| Tooltips, small popovers | 125 to 200ms |
| Dropdowns, selects | 150 to 250ms |
| Modals, drawers | 200 to 500ms |
| Marketing and explanatory sequences | Longer is allowed, because the tier permits it |

The rule that survives whatever numbers a project picks: a moment that only works as a slow,
showy animation has failed this question.

### 4. Does motion help or hinder here?

**Data the reader is trying to read or act on does not move for style.** That covers a
figure, a status, a chart the reader is interrogating, and a table being scanned. The
surrounding row may still slide, fade or reorder: the prohibition is on the value, not on the
layout. A value changes in one step from the old number to the new one. It never counts up,
rolls, or blurs through intermediate numbers that were never true.

### The invariants, applied to what survived

1. An animation starts from the element's current value, never from a reset origin.
2. Anything draggable stays grabbable mid-flight.
3. `prefers-reduced-motion` is respected. Respecting it means reducing, replacing or removing
   the motion, whichever keeps the meaning. Motion carrying no meaning is removed outright.
   Motion explaining where something came from is replaced by something static that says the
   same thing, not deleted and left unexplained.

### Choosing the technique

Easing curves are chosen on purpose. A CSS default easing keyword is the tell that nobody
chose. Scroll-linked techniques, meaning parallax, pinned sections and smooth scroll, are
permitted at the rarest tier and are not required there. Adding a scroll library to a project
that carries none is a dependency decision, so it goes to the owner rather than being made
here.

> Buttons and menus are not a film. Your story section is not a form.

### Record the refusals

A rejected candidate is a result. List two to five places motion was considered and refused,
each naming the gate question that killed it. Without that list this section is a wish list
with a heading on it.

## The words on the screen are design material

From `frontend-design`, Apache-2.0. Words are in a surface to make it easier to use, so they
carry the same intent as spacing and colour. This applies to every surface, including the ones
"Does it argue?" below explicitly excludes.

- **Name things by what the reader controls, never by how the system is built.** A person
  manages notifications. They do not manage webhook config.
- **A control says what it does, in a verb and its object.** "Save changes" beats "Submit",
  because "Submit" names no object and could do anything. Specific beats clever, every time.
- **The action's stem survives into its confirmation.** A control labelled "Publish" produces
  "Published", never "Success" and never "Your content is live". The reader learns one word
  and meets it again. This is the same rule as one word, one meaning, applied to a flow.
- **Errors state what happened and what to do next.** They do not apologise and they are never
  vague. An empty state is an invitation to act, not a mood.
- **A control and its copy do exactly one job.** A label labels. An example demonstrates.
  Nothing quietly does both.

## Does it argue?

**Scope: marketing pages, landing pages, pricing pages, onboarding and any surface whose job
is to get a decision.** A settings panel, a dashboard, an internal tool or a generated image
has no argument to make, and this section does not apply to it. Say which case a surface is
before applying this, because applying it to product UI produces a sales pitch where a tool
should be.

A conversion surface is an argument, and the order is problem, then proof, then action.
A page that looks finished and cannot be acted on is the most expensive defect available,
because everything upstream of it worked.

- **Enumerate every interactive element and resolve each one.** Each resolves either to a
  real destination, or to an observable state change on the same surface: a toggle that
  toggles, a filter that filters, an accordion that opens, a dialog that appears. Neither
  counts until it has been exercised. A control that scrolls back to a section already on
  screen has resolved to nothing.
- **At least one real commit path exists**, and can be reached from every section.
- **Count the distinct competing actions, not the repeats.** One commit path offered in six
  places is one action, and repeating it is the rule above doing its job. Two different things
  the reader is asked to do instead of each other is the leak, because the reader has to
  choose before they can act.
- **Count the form fields, and justify each one.** For every field ask whether it is needed
  *now*, or whether it could be collected after the reader commits. Everything past the
  minimum costs completions. "After payment" is the version of this for a checkout; for
  onboarding or a signup it is "after the current step".
- **The largest objection sits first** wherever objections are handled. First positions are
  what a reader remembers.
- **Risk reversal sits where commitment happens**, directly under the commit control, not in
  the footer.
- **Testimonials are attributable or absent.** An anonymous quotation reads as invented and
  costs more trust than it earns.

## Mockup content

The look must be the project's: its tokens, its palette, its type, without exception.

The data does not have to be real. Invent records with realistic labels at realistic lengths,
because realistic lengths are what break a layout. "Northgate Refit / £14,280 / 3 days
overdue" exposes what "Lorem ipsum dolor sit" hides.

## The gates

| Gate | Passes when |
|---|---|
| **Variants** | The set described in `rules/mockups.md` exists, on one page, both themes |
| **Judge** | The survival bar in `rules/mockups.md` is met, judged against this file read fresh |
| **Second judge** | Codex grades the screenshot. Advisory: it flags, the first judge decides |
| **Owner picks** | The owner names one variant. No production code before this |
| **Rendered matches** | The built screen, screenshotted, sits beside the chosen mockup and matches on palette, type scale, spacing, radius, and layout. The fix loop below has run first |
| **Proof** | The automated checks below come back clean, or each failure is named and fixed. A waived failure fails the gate |

Nobody grades their own work: a Codex-authored variant is judged by Claude, and Claude's
variants carry Codex's verdict.

### The fix loop, before the gate

Claude has eyes on a running web surface and must use them. The tooling is already installed:
`mcp__playwright__browser_take_screenshot` against the surface running locally.

Shoot it, put the screenshot beside the chosen mockup, and compare on the five named axes
above and nothing else: palette, type scale, spacing, radius, layout. Fix what differs.
Re-shoot. **Three rounds at most.**

The loop is a fix loop, not a gate. It exists to stop a first render reaching the owner with
faults Claude could see. It does not decide anything: whatever survives three rounds goes to
the owner, and to Codex, exactly as before. Anything still wrong after the third round is
reported as still wrong rather than fixed silently or looped on.

Not a running web surface, meaning a native screen, a desktop app, a generated image, or a
static mockup file: open the artefact, put it beside the mockup, compare the same five axes.
The loop is the same. Only the screenshot tool changes.

### What Proof means per surface

| Surface | Proof is |
|---|---|
| A web surface with a URL running locally | The Lighthouse run below. Accessibility must report **zero failed audits**. Best practices and SEO at 95 or better |
| A native or desktop screen | The platform's own accessibility inspector, clean. Contrast measured on the real render. Core Web Vitals do not apply |
| A generated image or a static mockup | Contrast measured on the exported pixels. No automated audit exists, so the Accessibility section below is checked by hand. Core Web Vitals do not apply |

```bash
npx lighthouse <url> --only-categories=performance,accessibility,best-practices,seo --output=json
```

Lighthouse is additive and never a substitute. A score of 100 says nothing about keyboard
order, focus-ring visibility, or whether labels describe what they label, which is why the
Accessibility section below is still checked by hand on every surface. An accessibility score
above 95 can and does coexist with real failures, so the number is not the gate: zero failed
audits is.

### Speed, and what a local run can honestly claim

Adapted from `addyosmani/web-quality-skills`, MIT, cited in `docs/BORROWED.md`. Read the
distinction before quoting any number from it.

**Core Web Vitals are field measurements.** Their published thresholds are the 75th percentile
of real visits from real people over 28 days. A Lighthouse run on your own machine is a
laboratory measurement of one load, so it can indicate and it cannot certify.

| Metric | Good, in the field | What a local run can do |
|---|---|---|
| LCP, largest contentful paint | 2.5s or less | A usable proxy. Treat a local LCP over 2.5s as a real finding |
| CLS, cumulative layout shift | 0.1 or less | A usable proxy, and often the most transferable of the three |
| INP, interaction to next paint | 200ms or less | **Cannot be measured locally at all.** It needs real interactions from real people. Total blocking time is the lab stand-in, and it is a stand-in |

So the gate on a local run is: LCP and CLS within the thresholds above, no unexplained total
blocking time, and INP reported as **not measured** rather than guessed. A page with no field
data has no INP, and saying so is the honest answer.

**Lighthouse 13 changed the audits, not the category.** Performance is still there. Many
individual audit IDs were retired and replaced by shared Performance Insights, some of them
because they were noisy or inactionable. Do not require a retired audit ID, and do not
reconstruct its advice from memory.

**The Chrome DevTools MCP route is a different tool with different limits**, and mixing the
two produces claims neither supports. Its `lighthouse_audit` excludes performance by design,
so it cannot answer this section at all. Its navigation mode reloads the page, which destroys
any authenticated or user-created state you were trying to measure. Use the command-line run
above for speed, and reach for the MCP tool only for the categories it covers.

## Building the real thing

Mockups live outside the running app, as one standalone page. They are a cheap contract to
point at before real code exists.

The build goes into the real component, one surface at a time, screenshotted in the browser
before the next one starts. The owner judges by what runs.

Extract the chosen mockup's exact values into the project's own design tokens first, then
build components that reference those tokens. A one-off hex code in the finished diff means
a token is missing: add the token.

## Accessibility

Every interactive element reachable by keyboard, in a sensible order, with a visible focus
ring. Text contrast at 4.5:1 or better. Roles and labels present.

**Touch targets come from the project's own design system**, the same way its colour, type and
spacing do. Read the project's control-height or hit-area token and hold every target to it.
A number typed here instead would be one vendor's house style imposed on every project this
file governs.

Two things bound that token rather than replace it:

- **The floor is the standard's, not a preference.** WCAG 2.2 criterion 2.5.8 sets 24 by 24
  CSS pixels, with named exceptions. A project token below that fails an audit, so the token
  is wrong and worth raising.
- **The unit is the platform's.** CSS pixels on the web, points on Apple platforms,
  density-independent pixels on Android. A number carried across platforms unconverted
  measures nothing.

Where a project has no such token, that is the finding. Say so and ask, rather than inventing
a number and letting it harden into one.

### WCAG 2.2 additions, and where each applies

These postdate the list above. The surface column matters: several cannot apply to a still
image, and reporting them as passed there would be false.

| Criterion | What it asks | Applies to |
|---|---|---|
| Focus not obscured, 2.4.11 | A focused element is not hidden behind a sticky header, footer or cookie bar | Any interactive surface |
| Target size, 2.5.8 | 24 by 24 CSS pixels minimum, with the five exceptions below | Any interactive surface |
| Dragging movements, 2.5.7 | Anything draggable has a single-pointer alternative that is not a drag | Any surface with a drag |
| Redundant entry, 3.3.7 | Information already given in a process is not asked for again | Multi-step flows only |
| Accessible authentication, 3.3.8 | No cognitive test, such as recalling a password unaided or solving a puzzle, without an alternative | Sign-in and sign-up flows only |

### The five exceptions to 2.5.8, because most small targets land on one

They are the specification's, not a house preference, and the first one clears most icon
buttons. Measure the gap around a target as well as its box, or targets that pass get reported
as failures.

| Exception | Passes when |
|---|---|
| Spacing | A 24px circle centred on the target touches no other target's circle |
| Equivalent | The same action is available elsewhere on the same page at full size |
| Inline | The target sits inside a sentence or a block of text, as a link in a paragraph does |
| User agent | The browser's own default control, with its size unmodified by the page |
| Essential | The size is required to convey the information, as a map pin is |

A criterion that cannot apply to the surface is recorded as **not applicable**, with the
reason. It is never recorded as passed. A pass nobody could have tested and a genuine pass
read identically later, and only one of them is honest.

## Reviewing a change to a screen

When the subject is a change rather than a fresh surface, **read the minus side of the diff**.
A regression is invisible in the post-change state: a focus ring, an `aria-label`, a
reduced-motion guard or an error string that used to be there and is not now looks exactly
like code that never had one. From `jakubkrehel/skills`, MIT, cited in `docs/BORROWED.md`.

Say which findings the change caused and which it merely sat next to. A fault the change did
not introduce is worth naming once and is not this change's job to fix.
