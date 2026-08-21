# The rebuild plan: SUPERSEDED, kept for the reasoning

> **Do not build from this file.** It is the plan as written on the morning of 2026-08-20,
> before any of it was executed. The rebuild then happened, and about half of what follows was
> overturned during it, usually because the plan had a fact wrong. **What was actually decided
> lives in `docs/DECISIONS.md`; what was actually archived lives in `archive/MANIFEST.md`.**
>
> The file is kept rather than deleted because the *reasoning* in it is still good: the
> four-way test, the dependency budget, and the mattpocock verdict all survived contact and
> none of them are recorded anywhere else. A plan left lying around as if it were the spec is
> how the next session rebuilds yesterday's mistakes, so the reality table comes first.

## What it said, against what actually happened

| The plan said | What actually happened |
|---|---|
| Archive `improve`, `checkup`, `design`, `route-map` | **All four refused.** Each is load-bearing: 31 inbound files for `design` alone. Reasons per skill in `archive/MANIFEST.md` |
| Delete `ponytail` and its 5 helpers, "never typed once" | **4 of 6 kept.** `/health` invokes `ponytail-review`, `-audit` and `-debt`; `/design` invokes `/ponytail`. It is a standard applied to coding, not a command anyone types, so a usage count was the wrong measure. Only `-gain` and `-help` went |
| Delete the `accessibility-tester` and `react-specialist` subagents | **Neither deleted.** `accessibility-tester` turned out to be wired into `/build`, and `react-specialist` is marked KEEP in `docs/KEEP_LIST.md` item 66. The plan and the keep list contradicted each other and the plan was wrong |
| Delete `config-protection.js`, built-in deny rules replace it | **Kept.** The deny rules were never written. Full record and the five tests in `docs/DECISIONS.md` |
| Replace `eli5-activate.js` with an Output Style | **Not done.** The hook is still the mechanism and there is no `output-styles/` directory |
| Cut `CORE_RULES.md` to ~40 lines, delete the other 17 rule files | **Not done, and now argued against.** The premise was context bloat; that was measured false. Every line was added after a specific failure |
| The `lockstep` command goes, plan mode covers it | **Kept.** It is a hook-enforced hard block, which plan mode is not |
| Install `visual-explainer` (dependency 2) | **Not installed, owner's decision.** The built-in Artifact tool already produces the pages |
| Install `avoid-ai-writing` (dependency 3), point slop-guard at its pattern list | **Not installed, owner's decision.** The 24-pattern hook is tuned and tested; a 62-pattern swap was not. "Point slop-guard at its pattern list" was also not a wiring job as described |
| Install Snip (dependency 5) | **Rejected on portability.** Mac-only, per-person. `docs/DECISIONS.md` carries the rule that came out of it |
| StyleSeed **or** UI Craft, after a head-to-head | **Done as written.** The owner picked StyleSeed from two rendered screens. Installed for its rules only, all 23 skill doors deleted |
| Rebuild the mockup workflow on top of `prototype` | **Rebuilt, but not on `prototype`.** None of the four mattpocock skills were installed. The four mockup rules are in `skills/build/SKILL.md` §3.5 |

Two things in the plan were simply wrong on the day it was written: dependency 2 named the
wrong `visual-explainer`, and "deleting the 17 rule files" was costed as a saving that turned
out not to be measurable.

## Everything below is the original text, unedited

Decided 2026-08-20. Replaces `docs/FRESH_START_PLAN.md` (Aug 4) and closes `docs/KEEP_LIST.md`.
Research complete: all 166 awesome-claude-code entries, all 20 mattpocock skills, 8 candidate
repos read in depth, full plan reviewed by Codex gpt-5.6.

## The test everything was judged by

Codex rejected the first version of this test ("does it run, or does it just ask nicely?") as
too absolute, and it was right. The corrected version:

1. **Objective and cheap to check** -> make it a gate that runs. Secrets, test claims, formatting.
2. **Needs judgement** -> keep a short instruction. Tone, when to ask, how to explain.
3. **The user types it** -> keep the name, whatever changes underneath.
4. **Neither** -> archive it.

Evidence for leaning on gates: StyleSeed measured 120 rendered screens. Design rules alone made
Claude Code worse (-3.7). The same rules behind a score-then-revise gate made it better (+5.3).

## What survives, and why

| Thing | Reason |
|---|---|
| whats-next, release, build, eli5, handoff, debate, xcheck, health | Most used, high consequence, or a stated requirement |
| The mockup workflow | The user's own. Rebuilt: ONE page, exactly 4 options, nothing wild. |
| slop-guard hook + phrase list | It runs. The document around it goes; the list the hook reads stays. |
| secret-scan + pre-commit | It runs. |
| format-typecheck hook | It runs. No better tool found. |
| memory/ (19 facts) | Still to be reviewed fact by fact. |
| lockstep-guard hook | It runs. The `lockstep` command goes (built-in plan mode covers it). |
| CORE_RULES, cut to ~40 lines | Only judgement rules and facts Claude cannot know. |

## What is archived, not deleted

Moved to `archive/`, out of the loaded path, with a manifest. Recoverable by name.

`last-30` · `better-prompt` · `watch` · `ingest-docs` · `archify` · `improve` · `checkup` ·
`design` (folds into build) · `resolving-merge-conflicts` (job moves inside release) ·
`dep-audit` · `route-map` · `orca-cli` · the 17 rule files

Codex's correction, accepted: rarely typed is not the same as low value. Releases and document
ingestion are seasonal. Two weeks of usage proves nothing about a quarterly job.

## What is deleted outright

`ponytail` and its 5 helpers (never typed once) · `computer-use` (never typed) ·
6 of the 8 design helper files · `accessibility-tester` and `react-specialist` subagents ·
`config-protection.js` (built-in deny rules replace it) · `eli5-activate.js` (Output Style
replaces it)

Kept from the design helpers: `interface-design`, `pick-ui-library`, as reference files
`build` reads rather than commands to type.

## What gets installed

Dependency budget: five. Codex's correction, accepted. Adding a sixth requires removing one.

| # | Tool | Job | Status |
|---|---|---|---|
| 1 | Output Style (built-in) | How Claude writes: max 5 rows, 3 columns, one table. Longer becomes a page. | Now |
| 2 | visual-explainer | Long output as a browser page instead of terminal text | Now |
| 3 | avoid-ai-writing | 62 AI-writing patterns, 112-word replacement table, rewrites rather than flags | Next |
| 4 | StyleSeed OR UI Craft | Design quality and "make it look like that site". ONE of them, after a head-to-head. | After the user picks |
| 5 | Snip | User annotates the mockup directly on screen, agent gets the marks back as JSON | After the mockup rebuild |

**On the waiting list, deliberately not installed:** Superpowers, presence, dev-browser,
Agent Guard, Ctxlint/agnix/Schliff, Diagram Design. Each is good. Each waits until something
it would replace has proven unnecessary.

## The mattpocock verdict, after reading all 20

**Take 4:** `code-review` (two parallel reviewers plus a Fowler code-smell list),
`diagnosing-bugs` (build a pass/fail loop before guessing), `tdd`, `prototype` (its UI mode
already builds several designs on one page with a switcher, which is the mockup skeleton).

**Skip 16.** Most of the set (`to-spec`, `to-tickets`, `triage`, `wayfinder`, `implement`,
`ask-matt`) requires an issue tracker and a project glossary configured first. That is team
process. `implement` in particular is 7 lines chaining two other skills, weaker than the
`build` it would replace.

**`build` stays the user's own.** Codex was firm on this and it holds: do not make a
non-engineer learn a methodology brand's vocabulary. Keep the front door, improve the room.

## Order of work

1. Tag and branch the current state. Nothing proceeds until rollback is proven.
2. Write the Output Style. Test it on a real answer before keeping it.
3. Install visual-explainer, confirm it loads.
4. Move the archive set. Leave a note at each old command name saying where the job went.
5. Cut CORE_RULES to ~40 lines. Delete the other 17 rule files.
6. Install avoid-ai-writing, point slop-guard at its pattern list.
7. Head-to-head: same screen built with StyleSeed and with UI Craft. User picks one.
8. Rebuild the mockup workflow on top of `prototype`, add Snip.
9. Review the 19 memory facts one at a time.

Steps 1-6 are unattended, roughly two hours. Step 7 needs two minutes of the user's eyes.
