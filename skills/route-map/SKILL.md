---
name: route-map
description: Use this skill when the user types /route-map, says 'check the routes', 'do the pages show the right thing', 'verify every page', or 'route map'. Enumerates every Next.js route, opens each one in a real headless browser, and proves the page's rendered text matches a reviewed per-route expectation — it proves CONTENT, not merely that a page loaded. Mismatches go to a two-model adjudication; anything it cannot prove is RED.
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
| `0` | completed, zero RED | clean |
| `1` | completed, at least one RED | **not clean** — list every RED row |
| `2` | could NOT run | RED for **every** route, reason `checker could not run — <FATAL line>` |

## ROUTEMAP.md — the map, at the app repo root

Same place and precedent as SHIP.md. `#` starts a comment, `!` a directive, everything else is a row `route-pattern | auth | expected | note`.
Duplicate keys, unknown directives, and a row with fewer than 3 or more than 4 cells are each fatal, never tolerated quietly.

```
!auth none
/          | none | "Hair that moves with your life." "Salty Mane" |
/book      | none | "Book an Appointment" "Select your service, choose a stylist" |
/faq       | none | "Frequently Asked Questions" |
/quiz      | none | "Find Your Perfect Stylist" "6 questions" |
/services  | none | "Services & Pricing" |
```

- **expected** — quoted substrings, ALL of which must appear in the rendered text, matched case-insensitively with whitespace
  collapsed (so the `/` heading split by `<br/>` still matches). An API row uses `status=NNN` plus optional body substrings; a redirect row uses `-> /target`.
- **note** — carries `draft`, `empty-ok`, `fixture <param>=<value>`, and adjudication records.
- **auth** — `none`, or any other word to attach the session named by the `!auth` directive.

| Directive | Meaning |
|---|---|
| `!base <url>` | check a server that is already running; it must answer or the run dies. Absent → the driver starts `npm run dev -- -p 4923` on `localhost:4923`, waits for a real route to answer under 400, then tears that process group down. |
| `!auth none` | no stored session. The default. |
| `!auth session <path>` | repo-relative Playwright `storageState` JSON. |
| `!auth test-account` + `!login <command>` | the repo-declared login command runs once and writes `.routemap/session.json`. Credentials reach it through the env-var NAMES it reads — never values written into the map. |
| `!seed <command>` | state seeding, run once before any visit. |
| `!empty never` | the default and only accepted value: no page is legitimately blank. Under 40 characters of visible text is RED unless that row's note says `empty-ok`. |
| `!ack <keyword>` | acknowledges a `redirects`, `rewrites`, `basePath` or `trailingSlash` keyword in `next.config.*` and commits the map to carrying rows for it. Unacked presence kills the run. |

**Drafting a map.** With no ROUTEMAP.md, enumerate, read each route's source, and write one row per route carrying `draft` in its
note. `draft` marks an expectation nobody has reviewed yet and is always RED, so an unreviewed map can never report green.
The user corrects rows and deletes the markers; the user never authors the map from scratch.

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
| `layout.*`, `loading.*`, `error.*`, `not-found.*`, css, components | not route-producing, never rows. Their behaviour is still proven, because the rendered page contains them |
| `robots.*`, `sitemap.*`, `favicon.ico`, `manifest.*`, `icon*`, `apple-icon*`, `opengraph-image*`, `twitter-image*` | a NAMED exclusion: reported as INFO, never checked, never map-required |

## Verdicts

**GREEN** — the route was visited and every expectation on its row held. **RED** — everything else, with one of these exact driver reasons:

| Reason | Meaning |
|---|---|
| `NO_ROW` / `GONE` | a route in the tree that no row covers / a row naming a route no longer in the tree |
| `DRAFT` | that row's expectation has not been reviewed |
| `NO_FIXTURE` / `BAD_FIXTURE` | a dynamic segment has no declared fixture value, or a fixture is malformed or matches no segment |
| `NO_EXPECTATION` | the row carries no quoted substrings, so it could prove nothing |
| `MISMATCH` | the page rendered, but a required substring, status, or redirect target was absent |
| `EMPTY` | under 40 characters of visible text and no `empty-ok` |
| `VISIT_FAILED` | the browser could not load the URL; the error text is the reason |
| `no verdict` | adjudication reached no ruling — see the ruling table below |

## What a green run actually guarantees

Every route is enumerated from the tree and given a verdict on every run; a route that cannot be visited gets RED naming the reason.
Screenshots and text captures exist for every route that was VISITED; routes never visited (`NO_ROW`, `DRAFT`, `NO_FIXTURE`) say so
in `report.json` rather than implying their evidence went missing. Artifacts land in `.routemap/latest/` as `<slug>-<url-hash>.png`,
`.txt` and `.console.txt`, alongside `report.json` and `dev-server.log`. Recommend the app gitignore `.routemap/` — never edit its `.gitignore` unprompted.

## Adjudication — runs on a `MISMATCH` row, nothing else

1. **Claude rules first, privately.** From the rendered text, the screenshot, the route source (`file` in `report.json`) and the
   step-2 evidence, write the ruling — `MAP_WRONG` (the app is right, the expectation is stale) or `APP_BROKEN` (the expectation is
   right, the app regressed) — plus reasoning to `.routemap/latest/<slug>.claude.txt`. That path is NEVER named in the Codex prompt,
   so the withholding is structural rather than honour-system.
2. **Build the evidence mechanically** — all of: the rendered text capture, the screenshot, the route's source file, `git -C "$APP"
   log -p -3 -- <source>`, `git -C "$APP" status --porcelain`, `git -C "$APP" diff` (working tree), and the diff of every in-repo file
   the route's source imports, one level deep, resolved by reading its import statements. Nothing Claude wrote enters this set.
   **If causality cannot be established from that evidence, REFUSE to auto-correct**: RED, reason `causality not established`.
3. **One Codex call.** The prompt goes into a TEMP FILE and is passed by path — route patterns and expected cells are user-editable
   text, never interpolated into shell source:

```bash
P="$(mktemp)"     # write the prompt into "$P" with the Write tool, then:
cd "$APP" && bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/xcheck/scripts/codex-run.sh" \
  -m gpt-5.6-sol -s read-only -t 300 -i ".routemap/latest/<artifact>.png" "$(cat "$P")"
```

The prompt names the step-2 evidence and nothing else, quotes the expectation on file, and closes: `ASSUME THE APP IS BROKEN and the
expectation is right; let only this evidence argue you out of that position. Reply with exactly one line: VERDICT | MAP_WRONG or
APP_BROKEN | <one sentence citing the evidence>`. Bash timeout ≥ 310000. Parse `^VERDICT` lines and nothing else.

| Claude | Codex | Action |
|---|---|---|
| `MAP_WRONG` | `MAP_WRONG` | rewrite the row's expected cell with substrings taken from the ACTUAL rendered text; append to the note `adj <date> claude:MAP_WRONG codex:MAP_WRONG was:"<old cell>"`, using the pipe-free `expectedCellSafe` value from `report.json` so a pipe cannot break the parser next run; re-run that route, which must now be GREEN. The user is never asked per row. |
| `APP_BROKEN` | `APP_BROKEN` | RED. Show the row, the missing substring, and the screenshot path. |
| either | the other | RED, with both rulings shown. |
| — | no `VERDICT` line, non-zero exit, timeout, `codex` missing, or a quota error | RED, `no verdict — <reason>` |

That last row deliberately INVERTS the skip-silently rule in `/xcheck`, where an unreachable Codex is a quiet no-op: a checker that
cannot reach a verdict must never pass quietly. Do not "fix" it back. Summarise ADJUSTED rows apart from GREEN ones, so a
self-corrected row is seen at least once.

## What this deliberately does not do

- **No source-file hash or staleness cache, ever.** A page file's hash is blind to layouts, middleware and every imported component
  — one broken shared component changes every page while every page file's hash stays identical. Behaviour is re-proven live instead.
- **No soft-navigation rendering.** A parallel slot's client-side render and an intercepting route's modal presentation exist only
  during in-app navigation, which a hard-load checker cannot reach. Both fail loudly, never silently.
- **Deferred and known absent:** a strict pages-router classifier, symlinked route directories, an allowlist covering every future
  Next.js convention, and a per-route rerun selector (a full re-run is used). The first repo needing one is the trigger to build it.
- **Residual risk, stated not hidden.** Both models can agree `MAP_WRONG` while the app is genuinely broken. The correction is never
  silent: the row keeps `was:"<old cell>"`, both rulings and the date, so a wrong self-correction is one visible line to revert.
