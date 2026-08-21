# Decisions and Sweep Logs

Why the rules are shaped the way they are, and what was measured when they were set.

This file is **not** imported into every session. It is read when someone is about to change a
rule and needs to know what the rule cost to learn. The rules themselves live in
`~/.claude/docs/CORE_RULES.md`, `~/.claude/docs/ANTISLOP.md` and `~/.claude/CLAUDE.md`; only the
history moved here, on 2026-08-19, because 2,458 bytes of work-log were loading in every session.

**Nothing here is decoration.** This repo has been burned before by cutting the reasoning and
then repeating the mistake. If a rule above ever looks arbitrary, the answer is in this file.

---

## 2026-08-19: the em-dash rule went binary

*Moved from the em-dash bullet in `~/.claude/docs/ANTISLOP.md`.*

**Owner's ruling, overriding the previous version of that line.** That version said to judge the
connector's monotony and explicitly not to flag on a raw count. The owner rejected that: the
em-dash is the single most recognisable machine-writing tell there is, the judgement call was
being lost every time, and a rule phrased as "use sparingly" has never once held. This one is
binary so it cannot be argued down. It matches `taste-skill` §9.G, which reached the same
conclusion from production tests.

## 2026-08-19: em-dash sweep status

*Moved from the same bullet.*

Prose is clean. `docs/` and `CLAUDE.md` went from 368 to 0; the 18 own skills went from 1,182
to 0.

Kept on purpose: 15 specimens in `docs/`, 48 in `skills/`, every one inside backticks or a
fenced block, under the specimen carve-out in the rule itself.

Deliberately untouched: 591 in the 19 borrowed skills, whose bodies
`~/.claude/docs/THIRD_PARTY_SKILLS.md` forbids editing and which a reinstall would overwrite
anyway, plus everything under a vendored third-party directory.

Still outstanding: 147 in `.py` and `.sh` sources, several of which are strings a running script
prints and which `~/.claude/docs/BORROWED.md` quotes back verbatim, so those two have to move
together or the docs stop matching the tool.

**Update, 2026-08-19 (same day, later session):** `hooks/eli5-activate.js` was found to hold 7
em-dashes inside the string it injects into every session, which reach the model as ordinary
prose. Those were fixed as part of the duplicate sweep. The `.py` and `.sh` count above is
unchanged.

**Update, 2026-08-20: the sweep's scope was narrower than the rule's.** The status above was
accurate and still misleading, because it reported on `docs/`, `CLAUDE.md` and the own skills,
and the rule says "everywhere". A `/checkup` pass counted **79 em-dashes in ordinary prose** in
the files nobody had swept: `README.md` (22), `SHIP.md` (21), `INSTALL.md` (12), `docs/KEEP_LIST.md`
(8), `commands/memory-compile.md` (5), `memory/SCHEMA.md` (4), both files in `agents/` (2 each),
and one each in `CORE_RULES.md`, `FRESH_START_PLAN.md` and `REBUILD_PLAN.md`. Two of those were
introduced the same morning by the session doing the rebuild, in headings it had just written,
which is the clearest evidence available that a binary rule still needs a check that runs.

All 79 are gone. Headings and glossary lead-ins took a colon, sentence-internal ones took a
comma or a full stop, and the eight worst comma splices the mechanical pass produced were
rewritten by hand. Specimens inside backticks and fenced blocks were left alone, per the
carve-out. The counting method is worth repeating rather than a plain `grep -c`: strip fenced
blocks by line, strip inline code spans, then count what is left, otherwise the specimens the
rule protects are scored as violations.

Still outstanding, unchanged: the 147 in `.py` and `.sh` sources, and the borrowed skills.

## 2026-08-19: why CLAUDE.md has exactly three imports

*Moved from the blockquote under "Always loaded" in `~/.claude/CLAUDE.md`.*

Three imports and no more: learned preferences, the rules that survived the 2026-07-29
experiment, and the writing-slop list. Anti-slop is imported rather than pointed at because a
pointer gets read after the writing has already started.

Its GUI half was split into `~/.claude/docs/GUI_SLOP.md` on 2026-08-18 and is pointed at from the
conditions list instead. 10,249 bytes that only matter when there is a screen do not belong in
every backend session.

## 2026-08-04: what the July experiment dropped, and why

*Moved from "## Dropped, deliberately" in `~/.claude/docs/CORE_RULES.md`.*

Simplicity-first, goal-driven phrasing, and the planner/builder model split were dropped after
the 2026-07-29 experiment (35 rules unloaded, kept off for six days). Six days without them
produced no visible regression, and the memory fact store already covers the model split.

If any of them starts costing you, add it back to `CORE_RULES.md` with the evidence, not
wholesale.

## Kept in place on purpose: rule 9's evidence paragraph

Rule 9 in `~/.claude/docs/CORE_RULES.md` (cross-check with Codex before writing) carries its own
2026-08-12 measurement inline: 503 of 563 edits across 39 sessions made with no plan stage and no
second model, and the defect Codex found the first day it was shown one.

That paragraph was considered for this file and deliberately left where it is. It is the only
thing that makes rule 9 persuasive enough to actually obey. A rule that says "run the
cross-check" without the measurement proving the cross-check catches real defects is a rule that
gets skipped. 250 bytes is a cheap price for a rule that works.

## 2026-08-20: config-protection kept, and the "REPLACE" verdict withdrawn

`docs/KEEP_LIST.md` item 60 and `docs/REBUILD_PLAN.md` both said `hooks/config-protection.js`
should go, replaced by built-in deny rules in `settings.json`, saving about 100 lines. That
verdict is withdrawn. **Nobody ever wrote those deny rules.** `settings.json` has no
`permissions.deny` array at all and `settings.example.json` has one entry, `Read(.env)`. So the
choice was never "hook versus deny rules", it was "a guard that works versus a guard that has
not been written", and the repo's own rule settles that: do not delete a working guard on the
strength of an untested replacement.

What was measured, in order:

| # | Test | Result |
|---|---|---|
| A | existing `.eslintrc.json`, payload piped in | exit 2, teaching message |
| B | guarded name under a directory that does not exist | exit 0, creation allowed |
| C | ordinary `index.js` | exit 0 |
| D | the real Edit tool on a real `.eslintrc.json`, live in a session | **blocked**, message returned to the model |
| E | `sed -i '' 's/error/off/' .eslintrc.json` in Bash, guard active | **not blocked, the rule was turned off** |

D matters because it proves the whole path, the settings wiring and the node shim included,
not just the script in isolation. `node --test hooks/tests/config-protection.test.js` is 32
tests, 32 passing.

E is the finding that changed the file. The header comment said this hook makes the failure
mode "mechanically impossible". It does not: it is a PreToolUse hook on Edit/Write/MultiEdit,
so every Bash write walks past it. That word is gone, and four limits are now written in the
hook itself: Bash writes are unguarded, creating a nested config can still weaken an inherited
one, checker settings inside dual-purpose files like `package.json` are not covered, and
`CLAUDE_ALLOW_CONFIG_EDIT=1` opens the gate for the rest of the process rather than for one
file. The hook also stayed silent when it errored, so a broken guard and a passed edit looked
identical from outside; it now writes a stderr notice and still exits 0.

Treat it as a habit correction that catches the common case loudly, not as an enforcement
boundary. Real enforcement needs something that sees Bash, and that is separate work nobody
has scoped.

Found by `/xcheck`, two rounds, 5 findings accepted and 3 rejected. The rejected three:
prototype targeted `Bash(sed:*)` deny rules (the bypass list is open-ended, so a blocklist of
commands is whack-a-mole, and denying `sed` everywhere to protect one file is a worse trade);
require approval for creating configs too (that is the false block the hook's own design note
argues gets the escape hatch exported permanently); and fail closed on unreadable input (this
guard fails open by design, unlike `hooks/lockstep-guard.js`, which is a user-issued stop
order and fails closed).

## 2026-08-20: Snip rejected, and the portability rule it produced

`Snip` (`rixinhahaha/snip`, MIT) was dependency 5 in `docs/REBUILD_PLAN.md`: the user annotates
a mockup on screen (circle, arrow, note) and the agent gets the marks back as structured JSON.
It does exactly that, and `snip render --format html` blocks until the review is finished, which
plugs straight into the mockup gate. It is a good tool.

It was rejected by the owner on the day it was found, on a ground nobody had written down:

| Fact | Measured 2026-08-20 |
|---|---|
| Windows build | none, ever. Mac and Linux only |
| Mac build | Apple Silicon only, no Intel |
| Size | 181.9 MB `.dmg`, plus a 52 MB AI runtime |
| Shape | an Electron desktop app installed per person, not a skill file |

**The rule this produced: a dependency of this repo has to be installable by whoever the repo is
for.** `no-yolo` exists so other people can set up a working configuration from `setup.sh`. A
per-person 182 MB desktop app with no Windows build is a hard stop on day one for anyone on
Windows or an Intel Mac, and "half the team cannot start" outweighs any feature the tool adds.
Judge a candidate on who can install it, not only on what it does.

This was not on the "check built-in first, then a maintained outside tool, then our own script"
ladder, and it should have been. The ladder asks whether a thing is *good*; it never asked
whether the people this repo serves could *run* it.

**Nothing was installed.** The Homebrew tap was never added. If a cross-platform equivalent
turns up, the mockup gate in `skills/build/SKILL.md` §3.5 is where it would attach: at the
"stop and ask which variant" step, which today takes typed feedback.
