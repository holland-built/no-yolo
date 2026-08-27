---
name: audit
description: 'Use when the owner types /audit, says "audit this screen", "review this page", "is this design any good", "check the UI", "audit the whole app", or names a URL, an app screen, a mockup or a repo to be judged. Reads each screen against docs/SCREENS.md and reports ranked findings. It never edits source, and fixes go to /build.'
user-invocable: true
model: opus
effort: high
argument-hint: "<url, screen, image, or repo> [--sweep] [--change]"
allowed-tools: [Bash, Read, Grep, Glob, mcp__playwright__browser_navigate, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_snapshot, mcp__playwright__browser_click, mcp__playwright__browser_hover, mcp__playwright__browser_press_key, mcp__playwright__browser_resize, mcp__playwright__browser_evaluate, mcp__playwright__browser_console_messages]
---

# audit

Target: $ARGUMENTS

This command reports and stops. It holds no `Write` and no `Edit`, so a fix it names is
carried out by `/build` afterwards, on the owner's word. That separation is the reason this is
its own command rather than a `/build` mode: `/build` writes source, and an audit must not.

**The guarantee is no source edits, and that is narrower than read-only.** `--sweep` starts the
project's own dev server, which runs the project's code and lets its framework write caches
and build output. Name the exact command before running it.

## 0. `--sweep`: a whole app, one screen at a time

Fires on `--sweep`, on a repo path, or on any request naming the whole app rather than one
screen. It is a mode here rather than a second command because it reuses steps 1 to 7 verbatim,
one route at a time, and `docs/WRITING.md` prefers a mode over a command that would restate
them.

**1. Get it running.** Read the package manager from the lockfile, and the script from
`package.json`, preferring `dev`. Print the exact command, run it on a port you picked and
proved free, and wait for that port to answer, up to 60 seconds. On failure, say which step
failed and stop. Kill only the process group this run started, in a `trap` that fires on every
exit path.

**2. Inventory the routes, best effort.** Two sources, merged, and neither is complete:

| Source | Finds | Misses |
|---|---|---|
| The framework's file convention: `app/`, `pages/`, `routes/` | Every declared route, including unlinked ones | Anything a rewrite, a redirect or middleware produces |
| A same-origin crawl from the root, breadth-first, hash and query stripped, each URL visited once | What a visitor can actually reach | Anything behind a login, a conditional link, or an action |

**Report it as a best-effort inventory, never as every page.** Print the count, which source
found each route, and the blind spots above as blind spots.

**3. Resolve the templates.** A dynamic route such as `/project/[id]` has no visitable URL of
its own. Take a real instance from the crawl. Where the crawl found none, list the template as
**not measured**, reason "no visitable instance", and audit no substitute.

**4. Preflight the cost, before the first screenshot.** Print the route count and what it will
take: roughly two screenshots, one keyboard pass and one Lighthouse run each. Twelve routes or
fewer, audit them all and say so. Above twelve, print the list and take one instruction: all of
them, a named batch, or one representative route per family. Never trim the list silently.

**5. Audit each route** with steps 1 to 7 below, one ranked list per route.

Routes run one at a time, and so do the passes inside a route. This is the shared-state case in
`docs/PARALLEL.md`, not an oversight: one browser holds one viewport and one page, so a resize
or a navigation by one pass changes what another captures, and a Lighthouse run measures
whatever else is loading the server at the time. Route inventory in step 2 is the exception,
where the file-convention read and the crawl do run as one wave.

**6. Close with one table**, screens worst-first, blocking counts first, then the routes that
came back not measured with their reasons.

## 1. Name the target and its surface class

One question at most, and only when the answer is not in the arguments or on screen already.

| Surface class | Recognised by | Decides |
|---|---|---|
| Web, running locally | A URL that loads | Every step below runs |
| Native or desktop screen | An app window | Lighthouse and the browser passes are replaced by step 5's inspector line |
| Image or static mockup | A `.png`, `.jpg` or a standalone `.html` file | Interaction and motion are reported **not measured** |

Also say which of the two content classes it is, because `docs/SCREENS.md` scopes a whole
section to the first: a conversion surface whose job is to get a decision, or product UI.
Naming it wrong produces a sales pitch where a tool should be.

## 2. See it before judging it

```
mcp__playwright__browser_navigate  <url>
mcp__playwright__browser_take_screenshot
```

Shoot it at 1440 wide and again at 390 wide. For an image or a file, open it with `Read`.

**A screen is judged from its render, never from its source.** Source says what was intended;
the render is what the owner gets. Reading the code to explain a finding is welcome, after the
finding exists.

## 3. Judge against the standard, read fresh

Read `docs/SCREENS.md` in full, this run, and apply every section its surface class reaches.
It is the standard; this file does not restate any of it, so a rule that lives there is not
weakened by being absent here.

Each finding carries what it was measured on: the screenshot, a computed value, a command's
output. A judgement with no evidence beside it is an impression, and it is labelled one.

## 4. Exercise it

Keyboard alone, then the pointer. Each interactive element gets reached, focused and operated.

| Pass | Evidence |
|---|---|
| Tab order and focus ring | Screenshot of each focused element, in the order Tab reached them |
| Every control resolves | The state change it produced, named. A control that produced nothing is a finding |
| Target size | The measured box of each target, against the project's own hit-area token |
| Reduced motion | The surface re-shot with `prefers-reduced-motion: reduce` set |

An image or a native screen cannot be exercised here. Report those rows **not measured**, with
the reason, and take the native accessibility inspector's own output when the owner can supply
it.

## 5. Measure

```bash
npx --yes lighthouse <url> --quiet --output=json --output-path=stdout \
  --only-categories=performance,accessibility,best-practices,seo
```

Report the count of failed accessibility audits, not the score. Report INP as **not measured**,
because it needs real visits. `docs/SCREENS.md` carries what a local run can honestly claim.

Contrast is a measurement, so each tested pair prints foreground, background, ratio, threshold
and verdict. Read the pair from the live surface with `browser_evaluate`; for an image, read it
from the file that produced it, and report **not measured** when no such file exists.

Lighthouse absent or failing: report "Lighthouse: did not run", with the reason, and carry on.
The rest of the audit stands.

## 6. When the subject is a change

`--change`, or any request phrased as one, adds this. Name the base commit being compared
against, in the report, and read the minus side of that diff: a focus ring or an `aria-label`
that used to be there and is not now looks exactly like code that never had one.

Every finding is labelled **caused by this change** or **pre-existing**. A protection the
change removed is caused by it. Pre-existing findings below blocking are capped at three,
because thirty is a different review; a blocking finding is never capped and never held back.

## 7. Report, then stop

Ranked by severity, worst first. Each row: what is wrong, what it was measured on, and the
fix in one line. Then the two counts, said plainly: how many findings, and how many rows came
back not measured.

Close with the command that acts on it, and wait:

```
/build fix <the finding>
```
