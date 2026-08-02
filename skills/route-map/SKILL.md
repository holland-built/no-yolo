---
name: route-map
description: Use this skill when the user types /route-map, says 'check the routes', 'do the pages show the right thing', 'verify every page', or 'route map'. Enumerates every Next.js route, opens each one in a real headless browser, and diffs the page's derived aria snapshot against a baseline you reviewed and committed as an ordinary git diff — it proves CONTENT, not merely that a page loaded. Anything it cannot prove is RED.
user-invocable: true
effort: high
argument-hint: "[app repo path — defaults to the current repo]"
allowed-tools: [Bash, Read, Grep, Glob, Edit, Write]
---

Arguments: $ARGUMENTS. Installs nothing — plain node driving the app's own `playwright` library, headless chromium, no test runner and no config file.

## Preflight

```bash
T="$(echo "$ARGUMENTS" | xargs)"; T="${T:-.}"
APP="$(cd "$T" && (git rev-parse --show-toplevel 2>/dev/null || pwd))"
DRIVER="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/route-map/scripts/route-check.mjs"
node "$DRIVER" "$APP" --enumerate                                   # routes only, no browser
node "$DRIVER" "$APP" "$APP/ROUTEMAP.md" "$APP/.routemap/latest"; echo "RC|$?"
```

Resolve the driver from the installed config dir — **never** a repo-relative path, since this skill runs inside OTHER repos.
Allow the Bash call ≥ 600000 ms. Exit-code contract, fail closed — RC `1` is NOT clean, and no run is called passing unless RC is `0`:

| RC | Meaning | How to report it |
|---|---|---|
| `0` | completed, zero RED | clean **only if** the summary line does not also report pending baselines |
| `1` | completed, at least one RED | **not clean** — list every RED row |
| `2` | could NOT run | RED for **every** route, reason `checker could not run — <FATAL line>` |

## ROUTEMAP.md — the map, at the app repo root

Same place and precedent as SHIP.md. `#` starts a comment line, `!` a directive, everything else is a row `route-pattern | auth | expected | note`.
Duplicate keys, unknown directives, and a row with fewer than 3 or more than 4 cells are each fatal, never tolerated quietly.

```
!auth none
!contact 555-0100 hello@example.com
/           | none | "Salty Mane"     | pin the brand name; it must never silently change
/book       | none |                  |
/faq        | none |                  |
/api/health | none | status=200 "ok"  |
```

- **expected** — now OPT-IN pins. Quoted substrings are must-never-change values, ALL of which must appear in the rendered text, matched
  case-insensitively with whitespace collapsed (so a heading split by `<br/>` still matches). An EMPTY cell is legal and normal for a page
  row: that route is proven by its snapshot alone. An API row uses `status=NNN` plus optional body substrings; a redirect row uses `-> /target`.
- **note** — carries `draft`, `empty-ok` and `fixture <param>=<value>`.
- **auth** — `none`, or any other word to attach the session named by the `!auth` directive.

| Directive | Meaning |
|---|---|
| `!base <url>` | check a server that is already running; it must answer or the run dies. Absent → the driver starts `npm run dev -- -p 4923` on `localhost:4923`, waits for a real route to answer under 400, then tears that process group down |
| `!auth none` | no stored session. The default |
| `!auth session <path>` | repo-relative Playwright `storageState` JSON |
| `!auth test-account` + `!login <command>` | the repo-declared login command runs once and writes `.routemap/session.json`. Credentials reach it through the env-var NAMES it reads — never values written into the map |
| `!seed <command>` | state seeding, run once before any visit |
| `!empty never` | the default and only accepted value: no page is legitimately blank. Under 40 characters of visible text is RED unless that row's note says `empty-ok` |
| `!ack <keyword>` | acknowledges a `redirects`, `rewrites`, `basePath` or `trailingSlash` keyword in `next.config.*` and commits the map to carrying rows for it. Unacked presence kills the run |
| `!links off` / `!links external` | `off` skips link checking entirely and says so in the output. `external` widens it to external links as well. Absent (the default) checks internal links and in-page anchors but not external ones. Any other value is fatal |
| `!contact <numbers/emails>` | whitespace-separated phone numbers and email addresses. Every `tel:`, `sms:` and `mailto:` href on the site must match one of them, else `CONTACT_MISMATCH`. With no `!contact` and such links present, one `WARN` line names how many are unpinned — the money links are the ones a typo silently kills |

**Contact matching is deliberately US-simple:** non-digits stripped, a leading country `1` dropped, a query string (`?body=`, `?subject=`) ignored, `mailto:` compared lowercase. A pin under 7 digits dies at parse, because 3 digits match almost any number. Short codes and non-US formats need an exact pin; the first international repo is the trigger to build real E.164 parsing, not before.

**Drafting a map.** With no ROUTEMAP.md, enumerate, read each route's source, and write one row per route carrying `draft` in its note — expected cells may be left empty. `draft` marks a row nobody has reviewed yet and is always RED, so an unreviewed map can never report green. The user corrects rows and deletes the markers; the user never authors the map from scratch.

## Snapshots — derived, not stored by hand

The expectation is DERIVED. Every visited page's aria snapshot (roles, accessible names, tree shape) is normalised — volatile refs and the Next.js dev overlay stripped — and written to `ROUTEMAP.snapshots/<slug>.aria.yml` **inside the app repo**; every later run diffs against it and prints the first 40 `+`/`-` lines of any difference. Nobody hand-copies page text into the map, and a deliberate copy edit reads as a git diff instead of a mystery RED.

- **The first capture is `NEW`** — never GREEN, never RED: `baseline recorded — review & commit <file>`. Nothing existed to regress against, so it cannot fail; nothing has reviewed it, so it cannot pass. This is what replaced the old first-run red wall.
- **A baseline is PENDING until it is COMMITTED in the app repo.** The driver asks git — `git -C <app> status --porcelain -- <file>` — and untracked or modified means pending; a baseline that MATCHES but is not committed still reports `NEW`. A tree git cannot answer for counts as pending. Committing is the approval, the user owns it, and no per-row prompt exists.
- **The summary never says clean while anything is pending.** It says `N baselines pending review — review & commit ROUTEMAP.snapshots/, then re-run`. Only a run with zero RED *and* zero pending prints `— clean`.
- **`--update=<route>` / `--update=all`** rewrites baselines and reports `UPDATED`, never GREEN, with the changed-line count per route; a plain follow-up run without `--update` is required to reach green. A bare `--update`, an unknown flag, `--update` alongside `--enumerate`, or an `--update=<route>` naming a route not in the enumeration each die with RC `2`.
- `NEW` and `UPDATED` never force exit `1`. Only RED does.

**Say this to the user in plain words: running `--update=all` without reading the diff is the one way to bless a regression here.** Whenever any baseline was written or rewritten, SHOW them the diff summary — `git -C "$APP" diff --stat -- ROUTEMAP.snapshots/` plus the driver's per-route changed-line counts, and the actual `git diff` for anything they ask about — before they commit. Never commit baselines on their behalf.

## Supported constructs — how a route becomes a URL

Anything outside this table is fatal (RC `2`) and named in the failure. Nothing is skipped silently.

| Construct | Becomes |
|---|---|
| `app/`, `src/app/`, `pages/`, `src/pages/` | exactly one router root; two or more → fatal, all of them named |
| `page.{js,jsx,ts,tsx}` | a page row at the accumulated URL. `page.mdx` or any other extension → fatal |
| `route.{js,ts}` | an API row: plain `fetch`, `status=NNN` plus optional body substrings, body saved, no screenshot |
| `(group)`, `_private` | a group contributes no URL segment and is recursed through; a `_`-prefixed folder is skipped, per Next's own convention |
| `@slot` | no URL segment; a `page.*` directly inside folds into the PARENT URL's row. A nested directory inside a slot → fatal (soft-nav only) |
| `(.)x`, `(..)x`, `(...)x` | never its own row. The target is resolved (sibling / parent / root) and a row for that target is REQUIRED, else RED |
| `[param]`, `[...slug]`, `[[...slug]]` | the pattern is the map key; the note must carry `fixture param=value`, else RED — never visited blind. Values are URL-encoded. An optional catch-all is visited twice, bare parent path and expanded path, and both must satisfy the row |
| `next.config.*` `redirects` / `rewrites` / `basePath` / `trailingSlash` | keyword-detected; fatal unless `!ack`ed. Redirect rows are fetched with `redirect:'manual'` and need a 3xx plus an exactly matching `Location` pathname |
| `middleware.{ts,js}` (root or `src/`) | not supported → fatal, named. It can rewrite any route |
| `layout.*`, `template.*`, `loading.*`, `error.*`, `not-found.*`, `global-error.*`, `forbidden.*`, `unauthorized.*`, css and other assets | not route-producing, never rows. Their behaviour is still proven, because the rendered page contains them |
| `default.*`, or ANY other file inside the router tree | fatal, named. `default.*` renders only on a soft navigation this tool cannot drive; an unrecognised file may be a route file the walker mis-read, so a colocated component dies here too — move it to `src/components/` |
| `robots.*`, `sitemap.*`, `favicon.ico`, `manifest.*`, `icon*`, `apple-icon*`, `opengraph-image*`, `twitter-image*` | a NAMED exclusion: reported as INFO, never checked, never map-required |

## Verdicts

**GREEN** — visited, the snapshot is identical to a committed baseline, and every pin on the row held. **NEW** / **UPDATED** — a baseline was written or rewritten and is waiting on human review; neither is green, neither exits `1`. **RED** — everything else, with one of these exact driver reasons:

| Reason | Meaning |
|---|---|
| `NO_ROW` / `GONE` | a route in the tree that no row covers / a row naming a route no longer in the tree |
| `DRAFT` | that row has not been reviewed |
| `NO_FIXTURE` / `BAD_FIXTURE` | a dynamic segment has no declared fixture value, or a fixture is malformed or matches no segment |
| `NO_EXPECTATION` | an API row carrying neither `status=NNN` nor a quoted substring — an API response has no aria snapshot to fall back on. Page rows never get this |
| `MISMATCH` | the aria snapshot differs from the committed baseline (line count given, first 40 diff lines printed), or an API row's status/body, or a redirect's 3xx target, did not satisfy the row |
| `PIN_MISMATCH` | the snapshot matched, but a quoted pin from the expected cell is absent from the rendered text |
| `SNAPSHOT_UNSTABLE` | the aria tree changed between two captures 500 ms apart — that page is dynamic, and is reported as dynamic rather than flaking one run in three |
| `CONTACT_MISMATCH` | a `tel:`, `sms:` or `mailto:` href matches no `!contact` value |
| `LINK_UNSAFE` / `LINK_SECRET` / `LINK_ROT` | see link checking below |
| `EMPTY` | under 40 characters of visible text and no `empty-ok` |
| `VISIT_FAILED` | the browser could not load the URL; the error text is the reason |

## Link checking — internal links, in-page anchors and href safety, on by default

Every `a[href]` is collected with its `target` and `rel`, de-duplicated run-wide by resolved URL, so a nav bar repeated on 5 pages is checked ONCE — `report.json`'s `links` section still records every page a link appeared on, plus its bucket, status and visible text. Each link lands in exactly one bucket below, never a silent skip, and a broken one prints `RED<TAB>link <link><TAB><reason> from <pages> — text "<text>"`, the same shape as a route row. A broken or unsafe link is RED, so one dead link alone makes the whole run exit `1`.
**Honesty: hard-loaded DOM only.** Links that only exist after a click — a menu, a drawer, a dialog — are not collected, and this skill never implies they were.

| Bucket | What it is, and what happens to it |
|---|---|
| internal | same origin as the base URL, a root-relative path, or an `href` too malformed to parse — counted as ours so it can never escape unchecked. CHECKED with `fetch`: HEAD, retried as GET on `405` or `501` because a dev server may refuse HEAD, redirects followed. A final status ≥ 400, or a request that throws, is broken |
| in-page anchor | an `href` starting with `#`. CHECKED against the page it was found on — an element with that `id` or `name` must exist; `#` alone and `#top` always pass. A dead anchor is a real broken link and is the check most link checkers miss |
| external | a different origin. NOT checked unless `!links external` is set, because a third party being down must never redden your own run. Each one is listed as `SKIPPED`, counted, and never implied to have passed |
| non-http | any scheme that is not `http`/`https`. `tel:`, `sms:` and `mailto:` are matched against `!contact`; everything else is reported as `INFO`, never fetched |

| Safety finding | When it fires |
|---|---|
| `LINK_UNSAFE` | a `javascript:`, `data:` or `vbscript:` href (it runs content the page did not author); plain `http:` to any host that is not the loopback name or address (mixed content — the response is modifiable in transit); `target=_blank` carrying an explicit `rel="opener"`, which hands `window.opener` to the destination |
| WARN, not RED | `target=_blank` with neither `noopener` nor `noreferrer`. Modern browsers imply noopener for `_blank`, so this is hygiene, and a WARN never changes the exit code |
| `LINK_SECRET` | every resolved internal and external URL is piped through the shared scanner at `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/secret-scan.sh`. It matches VENDOR KEY FORMATS only, never entropy, so tracking parameters cannot false-positive. Fail closed: a scanner that is missing, times out, or exits anything but 0/1 kills the run with RC `2`; over 10000 distinct URLs also dies rather than hanging |
| `LINK_ROT` | an external link that answered ≥ 400 or would not connect, reachable only under `!links external`. An expired domain is hijackable, so a dead external link is a security finding, not a nit |

## What a green run actually guarantees

**Aria structure and text ONLY** — roles, accessible names, tree shape and rendered text. Fonts, colours, spacing, layout, overlap, z-order and animation are NOT covered, and a green run says nothing whatever about them. `/design-audit` is the tool for those.

Every route is enumerated from the tree and given a verdict on every run; a route that cannot be visited gets RED naming the reason. Screenshots and text captures exist for every route that was VISITED; routes never visited (`NO_ROW`, `DRAFT`, `NO_FIXTURE`) say so in `report.json` rather than implying their evidence went missing. Artifacts land in `.routemap/latest/` as `<slug>-<url-hash>.png`, `.txt`, `.aria.yml` (the run's own copy of the snapshot) and `.console.txt`, alongside `report.json` — rewritten after every route, so a killed run still holds what it proved — and `dev-server.log`. Recommend the app gitignore `.routemap/` — never edit its `.gitignore` unprompted. `ROUTEMAP.snapshots/` is the opposite: it is committed, because it is the reviewed expectation.

| Run died with | Runbook |
|---|---|
| `port 4923 already in use` | `lsof -ti tcp:4923 \| xargs kill`, or point `!base` at what is already serving |
| `chromium could not launch` | `npx playwright install chromium` |
| `app has no 'playwright' library installed` | `npm i -D playwright && npx playwright install chromium` |

## What this deliberately does not do

- **No source-file hash or staleness cache, ever.** A page file's hash is blind to layouts, middleware and every imported component — one broken shared component changes every page while every page file's hash stays identical. Behaviour is re-proven live instead.
- **No soft-navigation rendering.** A parallel slot's client-side render and an intercepting route's modal presentation exist only during in-app navigation, which a hard-load checker cannot reach. Both fail loudly, never silently.
- **No pixel comparison.** See the aria-only guarantee above — that boundary is deliberate, and `/design-audit` owns the other side of it.
- **Deferred and known absent:** components colocated inside the router tree (they die loudly today, which is the desired first behaviour); a fake-browser integration test for the visit path (the live proving run on a real app covers it); E.164 phone parsing; a strict pages-router classifier; symlinked route directories; an allowlist covering every future Next.js convention; and a per-route rerun selector (a full re-run is used). The first repo that needs one is the trigger to build it.
- **Residual risk, stated not hidden.** A blind `--update=all` followed by a blind commit will bless a real regression, because the driver cannot tell an intended copy edit from a broken component. The defence is entirely the diff review described above — which is why this skill shows the diff every time rather than trusting anyone to go looking for it.
