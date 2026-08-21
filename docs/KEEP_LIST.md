# Keep list: decisions as they are made

Rule: **everything is deleted unless marked KEEP.**

## Round 1: background bits (decided 2026-08-20)

| # | Thing | Verdict | Change wanted |
|---|---|---|---|
| 57 | eli5-activate.js | REPLACE | Current version fails: user still asks for a restate ~90% of the time. Replace the hook with a native Output Style (`/output-style`), which changes how Claude writes at the source instead of nagging each turn. |
| 58 | slop-guard.js | KEEP, may improve | Check the two reference repos for a better version first. |
| 59 | lockstep-guard.js | KEEP | Works. Stops unasked-for coding. |
| 60 | config-protection.js | ~~REPLACE~~ **KEEP** | Reversed 2026-08-20 on evidence. The deny rules that were meant to replace it were never written, and the hook was watched blocking a real edit through the live wiring. Its four real limits are now written into the file. Full record: `docs/DECISIONS.md`. |
| 61 | format-typecheck.js | KEEP as is | No better tool found. Tidies and checks code after each reply. |
| 62 | mockup-autoopen.js | KEEP but REBUILD | ONE page holding all mockups, not one file each. Exactly 4 options. No wild/experimental ones. |
| 63 | secret-scan + pre-commit | KEEP, may improve | |
| 64 | statusline.sh | KEEP | |
| 65 | accessibility-tester agent | DELETE | Never used. |
| 66 | react-specialist agent | KEEP | |
| 67 | memory/ (19 facts) | KEEP | User wants to see what is in it before finalising. |
| - | literal-mode-tracker.js | undecided | Turns off challenging when you say "just do it". |

## Standing rule for every round

For anything marked KEEP, first ask: **is there a built-in Claude Code feature, or a
better-maintained outside tool, that does this without our own code?** Prefer built-in,
then outside tool, then our own script. Applied to 57 and 60 already.

**Nothing survives unchanged by default.** KEEP means "this job still needs doing", not
"this code is fine". Every keeper gets an improvement pass before it goes back in. If the
pass finds nothing worth changing, say so plainly rather than inventing a change.

Shortlist to check against later rounds:
- visual-explainer: turns long output into a readable web page
- Agent Guard: stronger secret-leak blocking (see #63)
- StyleSeed: design judgment rules (see the design commands)
- agnix / Schliff: linters for rule and skill files

## Round 2: commands (in progress 2026-08-20)

Usage counts came from `history.jsonl`. Note: the raw `/design` count of 48 was wrong,
most hits were file paths like `/design/Labcorp.pdf`. Real: build ~22, design ~12.

| # | Command | Verdict |
|---|---|---|
| 28 | whats-next | KEEP, improve |
| 9 | eli5 | REBUILD as option C below |
| 23 | release | KEEP, improve |
| 3 | build | KEEP, absorbs design |
| 8 | design | DELETE as a separate door, becomes a stage inside build |
| 10 | handoff | KEEP, improve |
| 14 | last-30 | KEEP, improve |
| 2 | better-prompt | KEEP, improve |
| 15 | lockstep | KEEP, improve |
| 27 | watch | KEEP, improve |
| 6 | debate | KEEP, improve |

### The readable-output decision (option C)

Chosen 2026-08-20 after the user said the tables were still unreadable.

1. Terminal answers are hard-capped: max 5 rows, max 3 columns, ONE table per answer,
   no cross-references to numbered items in other tables.
2. Anything longer becomes a real web page (Artifact) with a one-line summary in the
   terminal. Today's 71-row inventory was exactly this case and was dumped as terminal
   text instead.
3. Improve further using whatever the reference repos offer once they are read
   (visual-explainer is the lead candidate).

### Round 2b (decided)

| # | Command | Verdict |
|---|---|---|
| 29 | xcheck | KEEP as its own command. build calls it, but the user also needs it with no code involved. |
| 11 | health | KEEP, and it absorbs the checkup job (aims at code OR at this settings folder). |
| 1 | archify | KEEP. This is the "chart builder" the user said they like. |
| 24 | remember-that | KEEP, small. |
| 12 | improve | DELETE. whats-next covers it; the user only ever used the short one. |
| 4 | checkup | DELETE as a command, job moves into health. |

Running total: 37 commands -> 11.

### Round 2c (decided)

| # | Command | Verdict |
|---|---|---|
| 25 | resolving-merge-conflicts | JOB RESCUED. Runs automatically inside `release` when a merge jams. No command to type. |
| 13 | ingest-docs | KEEP. Turns PDF/Word/PowerPoint/Excel/images into .md notes. |
| 17-22 | ponytail family | Command deleted, JOB RESCUED into `health` (the cut-the-bloat pass). Revisit when the outside skills are read. |
| 7 | dep-audit | DELETE |
| 26 | route-map | DELETE |
| 16 | orca-cli | DELETE |
| 5 | computer-use | DELETE |
| 35 | interface-design | KEEP as a reference file build reads. Craft standard for dashboards, admin panels, settings, data tables. |
| 36 | pick-ui-library | KEEP as a reference file build reads. Picks a code package for one widget (charts, date pickers, command menus). NOT a theme/colour tool. |
| 30-34, 37 | other 6 design helpers | DELETE (5 animation files + apple-design) |

**Replacement wanted for the 8 design helpers.** The user wants a UI-hygiene reference for
code that already exists: text-box styling, hover states, how a box moves, general polish,
without redesigning from scratch. Lead candidate from the awesome-claude-code list:
**StyleSeed** (~74 unwritten pro rules plus a motion vocabulary). Verify before adopting.

Round 2 final: 37 commands -> 14.
Survivors: whats-next, release, build, handoff, last-30, better-prompt, lockstep, watch,
debate, eli5, xcheck, health, archify, remember-that, ingest-docs.

## Round 3: rule files, not started
## Round 4: borrowed plugins, not started
