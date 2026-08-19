# Design surfaces: what counts as one, and which are allowed to be doors

The decision this file records: **there is one door for design work, `/design`.** Everything
else that knows about interfaces is reference material that door reads on demand. This file
exists so that "everything else" is a list somebody can check, rather than a feeling.

It is written for a machine as much as a person. `/checkup` reads it to answer one question
each run: *has a second door appeared?* A door that reappears quietly is the failure mode:
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
Demoting a rival means turning the second into the first. It does not mean deleting it.

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
| 7 | **Bundled with the CLI** | compiled into the `claude` binary itself, no file anywhere in this repo | `strings -a "$(readlink -f "$(command -v claude)")" \| grep -x '<name>'` | see below |

Two of these are easy to miss, and both were missed until 2026-08-18.

**Route 4** is a marketplace that is cloned but switched off. It is not harmless. It is a
single `enabledPlugins` entry away from being a door, and nothing in the current session shows
it exists.

**Route 7 is not this repo's to control.** `dataviz` is a design surface that appears in every
session's skill list, and it is not a file in `~/.claude` or `~/.agents` at all; it is compiled
into the `claude` binary (2.1.234 when this was written; the check reports the live version) along with `simplify`, `run`, `init`, `claude-api`, `security-review`,
`update-config`, `keybindings-help`, `loop` and `fewer-permission-prompts`. Editing this repo
cannot demote it. The only lever found in the binary is a `disableBundledSkills` setting, which
is all-or-nothing and would take every one of those built-ins with it, a blunt instrument, not
a demotion. A `skillOverrides` key also exists in the binary; its shape was not determined, so
nothing here claims it works.

## The roster: every invocable thing that touches design, and its verdict

`/checkup` reads this table. Anything it finds that is not listed here is reported as
**UNCLASSIFIED**, and anything listed as `reference` that turns out to be model-invocable is
reported as **RIVAL REAPPEARED**. Those two findings are the entire check.

The first draft of the check tried to decide by keyword instead, asking whether the name or description
mentioned design, UI, layout or colour. It flagged nine surfaces and all nine were wrong: `eli5`,
`xcheck`, `build` and `debate` all discuss interfaces without being one. A check that is wrong
every run teaches the reader to skip it. So the judgement is made once, by a person, and
written here; the machine only notices what is new or what has changed underneath it.

**Verdicts:** `door` is an allowed entry point. `reference` is content `/design` reads, and must carry
`disable-model-invocation: true`. `not a surface` is invocable, mentions design, and is not one.

| Surface | Route | Verdict | Why |
|---|---|---|---|
| `design` | 1, own skill | **door** | Fresh generation, audit, quick sketch, conform, component pull, mockup port |
| `impeccable:impeccable` | 3, enabled plugin | **door** | Allowed by observation, not by design. See the honest note below |
| `animation-vocabulary` | 2 | reference | Naming effects |
| `find-animation-opportunities` | 2 | reference | Whether something should animate at all |
| `improve-animations` | 2 | reference | Whole-codebase motion audit |
| `review-animations` | 2 | reference | Reviewing motion already written |
| `apple-design` | 2 | reference | Gesture and physical-motion values |
| `emil-design-eng` | 2 | reference | Easing, duration, implementation detail |
| `interface-design` | 2 | reference | Craft, hierarchy, tokens, design-system consistency |
| `pick-ui-library` | 2 | reference | Library selection table |
| `hallmark` | n/a, vendored, not installed | reference | 21 macrostructures, a six-axis pre-emit critique and a variety rule, read by `/design` from `skills/design/vendor/hallmark/`. It ships upstream as a four-verb door; the row exists so that if it is ever installed at `skills/hallmark/` the door check reports RIVAL REAPPEARED instead of going quiet |
| `archify` | 2 | not a surface | Draws architecture diagrams. "Redesign this page" must never reach it |
| `build` | 1 | not a surface | Ships features end to end; it *calls* `/design`, it is not a design door |
| `debate` | 1 | not a surface | Argues decisions, including UI ones, and produces no interface |
| `eli5` | 1 | not a surface | Explains things in plain words |
| `xcheck` | 1 | not a surface | Sends work to a second model |
| `computer-use` | 2 | not a surface | Drives desktop windows; reads UI, never designs it |
| `orca-cli` | 2 | not a surface | Operates worktrees and terminals |
| `react-specialist` | 6, agent | not a surface | Builds React components to a given design; it implements, it does not decide the design |
| `accessibility-tester` | 6, agent | not a surface | Audits WCAG compliance. Genuinely adjacent, deliberately kept: `/design`'s AUDIT.md runs its own contrast and axe-core checks at runtime, and a second opinion on a11y is worth more than one-door tidiness |
| `dataviz` | 7, bundled | **door, unavoidable** | Compiled into the CLI. Cannot be demoted from here at all |
| `design-plugins/design-lab` | 4, dormant | reference | Cloned, not enabled. Enabling it is a decision to have a second door |
| `claude-plugins-official/frontend-design` | 4, dormant | reference | Same |
| `claude-plugins-official/build-mcp-app` | 4, dormant | not a surface | Builds MCP apps. Caught by the keyword net; it is not a design surface |
| `claude-plugins-official/build-mcp-server` | 4, dormant | not a surface | Same |
| `claude-plugins-official/plugin-structure` | 4, dormant | not a surface | Same |
| `claude-plugins-official/example-command` | 4, dormant | not a surface | A template for writing commands |

### Two different switches, and only one of them was being checked

A skill can be reached two independent ways, and closing one does nothing to the other. An
earlier draft of this file treated them as the same thing and was wrong.

| Frontmatter | Controls | Absent means |
|---|---|---|
| `user-invocable: true` | Whether the **user** can type `/name` | The user cannot type it |
| `disable-model-invocation: true` | Whether the **model** may auto-select it | The model may pick it at any time, so it is a live door |

Only the second one makes something stop competing with `/design`. Nine skills here have no
`user-invocable: true` and were therefore described as "not invocable"; every one of them was
still model-invocable, which is how five design skills sat in every session's skill list for
weeks without ever being deliberately used.

Verified 2026-08-18 across all 37 skills on disk: the only two carrying
`disable-model-invocation: true` were the only two absent from the session's skill list. Clean
separation, so that flag is the lever.

### Demoted: reference material, read by `/design`, not doors

| Skill | Demoted | Content still at |
|---|---|---|
| `animation-vocabulary` | 2026-08-18 | `skills/animation-vocabulary/SKILL.md` |
| `find-animation-opportunities` | 2026-08-18 | `skills/find-animation-opportunities/SKILL.md` |
| `improve-animations` | 2026-08-18 | `skills/improve-animations/SKILL.md` |
| `review-animations` | already shipped demoted upstream | `skills/review-animations/SKILL.md` |
| `apple-design` | 2026-08-18 (cohort B) | `skills/apple-design/SKILL.md` |
| `emil-design-eng` | 2026-08-18 (cohort B) | `skills/emil-design-eng/SKILL.md` |
| `interface-design` | 2026-08-18 (cohort C) | `skills/interface-design/SKILL.md` |

All seven are listed in `skills/design/DESIGN_REFS.md` with what to read them for, exactly once
each. Demotion is not deletion: every word of them is still reachable, through the one door.

**Undo, exactly.** These files are gitignored, so `git revert` does not restore them. Reverting
the tracked commit only removes the policy, not the flag. The local undo is one command:

```sh
perl -ni -e 'print unless /^disable-model-invocation: true$/' \
  ~/.claude/skills/{animation-vocabulary,find-animation-opportunities,improve-animations,apple-design,emil-design-eng,interface-design}/SKILL.md
```

That path goes through `skills/`, not an installer root, and it has to. There are **two**
installer roots on this machine (`~/.claude/.agents/skills/` and `~/.agents/skills/`) and
`interface-design` is the only demoted skill in the second one. An earlier version of this
command, and of both the `setup.sh` and `verify.sh` loops, hardcoded the first root and would
have skipped it in silence. The symlinks in `skills/` are followed by ordinary file operations
and do not care which root the installer picked.

`review-animations` is deliberately not in that list: upstream ships it demoted, so removing
the line would be a change, not a revert. Re-running `npx skills add` also erases the flag, but
as a side effect of a full reinstall that overwrites unrelated local metadata too (the four
`model: haiku` pins in `README.md`); it is not the controlled undo.

**Not demoted, deliberately:** `archify`. It fails the design-surface test at the top of this
file. It draws architecture diagrams, and nothing about "redesign this page" should reach it.
`pick-ui-library` needed nothing; upstream already ships it demoted.

### The door's own description was the loudest rival

Found during cohort C, and bigger than the cohort. `skills/design/SKILL.md`'s `description` is
loaded into **every** session, and it read: *"it is NOT the entry point for all UI work and
routes to no other skill. Craft review and design-system work is `interface-design`; charts are
`dataviz`; motion is the animation skills."*

Three things wrong at once. It contradicted itself in one sentence: "routes to no other skill"
followed by three routes. Two of those three destinations had just been closed, so it was
handing work to doors that no longer answer. And it disclaimed the territory the whole plan
exists to give it, in the one piece of text the model always reads.

Rewritten to claim the territory and drop all three hand-offs. Every trigger phrase after
`Fires on` was preserved byte for byte. This changes what `/design` says it is FOR, never what
makes it fire. The wording is "the entry point for visual design of UI surfaces", not "the one
door for UI work": the narrower phrase keeps backend work that merely mentions a page from
landing here, and it does not assert an inventory fact that `dataviz` and `impeccable` make
untrue.

**Out of this repo's reach:** `dataviz`, via route 7. It is a genuine design surface and it
cannot be demoted from here at all. Recorded as a permanent exception rather than left to look
like an oversight, and the plan's step 4b, which lists it in Cohort A, is wrong on this point.

**Dormant and must stay dormant:** `design-plugins/design-and-refine/skills/design-lab` and
`claude-plugins-official/plugins/frontend-design`. Both are cloned to disk. Neither is enabled.
Enabling either one is a decision to have a second door, and should be made on purpose.

## The honest note on `impeccable`

The plan says one door. The measurement says `impeccable:impeccable` was invoked 3 times in 13
days and `design` twice, so the plugin is used *more* than the door it supposedly competes with.

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
  list was read from, and re-read it when that version moves. A list checked against an old
  binary is a list that reports `clean` for a rival that shipped last week.

## Changing the allowlist

Edit the table above in the same commit that adds or demotes the surface. An allowlist updated
afterwards would have flagged its own change as a rival, and the habit of silencing that flag is
how the list stops meaning anything.
