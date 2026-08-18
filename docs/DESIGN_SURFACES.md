# Design surfaces — what counts as one, and which are allowed to be doors

The decision this file records: **there is one door for design work, `/design`.** Everything
else that knows about interfaces is reference material that door reads on demand. This file
exists so that "everything else" is a list somebody can check, rather than a feeling.

It is written for a machine as much as a person. `/checkup` reads it to answer one question
each run: *has a second door appeared?* A door that reappears quietly is the failure mode —
five design skills were installed here over time and none of them was ever invoked once.

## What a design surface is

Anything that can be **invoked** by the user or auto-selected by the model to produce, review,
or judge a visual interface. The test is invocability, not subject matter:

| Is | Is not |
|---|---|
| A skill whose description would fire on "redesign this page" | A doc about design that only gets read when something else names it |
| A plugin skill that appears in the session's available-skills list | A reference file inside a skill's own folder |
| An agent a user can address by name to do UI work | A vendored ruleset with no frontmatter |

A file full of design rules is **reference**. A thing that can be called is a **surface**.
Demoting a rival means turning the second into the first — it does not mean deleting it.

## Every way something becomes a surface here

Seven routes, all of them live on this machine, with the live count measured 2026-08-18. A
rival can arrive through any of them, which is why the check has to look at all seven rather
than just `skills/`.

| # | Route | Where it is registered | How to enumerate it | Live |
|---|---|---|---|---|
| 1 | Own skill | `skills/<name>/SKILL.md` with `user-invocable: true` | `grep -l "user-invocable: true" skills/*/SKILL.md` | 20 |
| 2 | Installed skill | a symlink at `skills/<name>` into `~/.agents/skills/`, recorded in `~/.agents/.skill-lock.json` | `for d in skills/*/; do [ -L "${d%/}" ] && basename "${d%/}"; done` | 19 |
| 3 | Enabled plugin | `settings.json` → `enabledPlugins`, drawing from a marketplace under `plugins/marketplaces/` | `python3 -c "import json;print(json.load(open('settings.json')).get('enabledPlugins'))"` | 2 |
| 4 | Dormant plugin | a marketplace in `settings.json` → `extraKnownMarketplaces`, cloned to disk but **not** enabled | `find plugins/marketplaces -name SKILL.md` | 51 files |
| 5 | Slash command | a file in `commands/` | `ls commands/` | 1 |
| 6 | Agent | `agents/*.md`, addressable by name | `ls agents/*.md` | 2 |
| 7 | **Bundled with the CLI** | compiled into the `claude` binary itself — no file anywhere in this repo | `strings -a "$(readlink -f "$(command -v claude)")" \| grep -x '<name>'` | see below |

Two of these are easy to miss, and both were missed until 2026-08-18.

**Route 4** is a marketplace that is cloned but switched off. It is not harmless — it is a
single `enabledPlugins` entry away from being a door, and nothing in the current session shows
it exists.

**Route 7 is not this repo's to control.** `dataviz` is a design surface that appears in every
session's skill list, and it is not a file in `~/.claude` or `~/.agents` at all; it is compiled
into `claude` v2.1.234 along with `simplify`, `run`, `init`, `claude-api`, `security-review`,
`update-config`, `keybindings-help`, `loop` and `fewer-permission-prompts`. Editing this repo
cannot demote it. The only lever found in the binary is a `disableBundledSkills` setting, which
is all-or-nothing and would take every one of those built-ins with it — a blunt instrument, not
a demotion. A `skillOverrides` key also exists in the binary; its shape was not determined, so
nothing here claims it works.

## The allowlist

**Allowed to be a design entry point:**

| Surface | Route | Standing |
|---|---|---|
| `design` | 1 — own skill | The door. Fresh generation, audit, quick sketch, conform, component pull, mockup port |
| `impeccable:impeccable` | 3 — enabled plugin | **Allowed by observation, not by design.** See the honest note below |

**Reference, and must not be invocable.** As of 2026-08-18: `interface-design`,
`emil-design-eng`, `apple-design`, `animation-vocabulary`, `find-animation-opportunities`,
`improve-animations`, `review-animations`, `pick-ui-library`, `archify`. Verified — none of
these carries `user-invocable: true` today. The plan's step 4b converts them from ambient
competitors into files `/design` reads.

**Out of this repo's reach:** `dataviz`, via route 7. It is a genuine design surface and it
cannot be demoted from here at all. Recorded as a permanent exception rather than left to look
like an oversight — and the plan's step 4b, which lists it in Cohort A, is wrong on this point.

**Dormant and must stay dormant:** `design-plugins/design-and-refine/skills/design-lab` and
`claude-plugins-official/plugins/frontend-design`. Both are cloned to disk. Neither is enabled.
Enabling either one is a decision to have a second door, and should be made on purpose.

## The honest note on `impeccable`

The plan says one door. The measurement says `impeccable:impeccable` was invoked 3 times in 13
days and `design` twice — the plugin is used *more* than the door it supposedly competes with.

Recorded rather than resolved. Declaring it a rival and demoting it would be acting against the
only usage evidence there is; declaring the one-door rule satisfied while two doors are open
would be untrue. It sits on the allowlist with this paragraph attached so the next reader
inherits the tension instead of a tidy lie. Revisit it with a fresh count, not an argument.

## What `/checkup` does with this file

One check, added by the plan's step 4c: enumerate all seven routes, and report any invocable
design surface that is not named on the allowlist above as **RIVAL REAPPEARED**.

Three rules keep that check honest:

- **A new surface is a finding, never an auto-removal.** Something installed a rival on
  purpose, possibly the owner. The check reports; the owner decides.
- **A route that cannot be enumerated says so.** If `settings.json` is unreadable or
  `~/.agents/.skill-lock.json` is missing, that route prints `CANNOT CHECK — <reason>` and does
  not silently contribute zero rivals. Route 4 in particular reads a directory that is
  gitignored and absent on a fresh clone; absent is `CANNOT CHECK`, not `clean`.
- **Route 7 is checked against the installed binary's version.** A CLI upgrade can add a
  bundled design skill without anything in this repo changing. Record the version the route-7
  list was read from, and re-read it when that version moves — a list checked against an old
  binary is a list that reports `clean` for a rival that shipped last week.

## Changing the allowlist

Edit the table above in the same commit that adds or demotes the surface. An allowlist updated
afterwards would have flagged its own change as a rival, and the habit of silencing that flag is
how the list stops meaning anything.
