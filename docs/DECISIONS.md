# Why the rules read the way they do

Read when a rule looks wrong, redundant, or worth changing. Each entry names the evidence
behind a rule, so changing it is an informed decision rather than a guess.

## Six rules, not thirty-five

**2026-07-29.** Thirty-five rules were unloaded and the setup ran without them for six days.
Nine were missed enough to earn their way back. The other twenty-six described behaviour the
model produced unprompted, so every line they cost bought nothing.

**Consequence:** a rule joins `CLAUDE.md` after it is observed breaking without it. The
default for a new rule is a doc behind a pointer.

## Rules stated as targets, never as bans

**Source:** `mattpocock/skills` → `writing-for-agents`.

Naming a behaviour makes it available to the model, so a prohibition half-reads as an
instruction. The previous setup's strongest rule was an outright ban on one punctuation
character, restated in three files, and the character kept appearing.

**Consequence:** every rule states the target. The unwanted behaviour goes unnamed. A
prohibition survives only as a hard guardrail with no positive phrasing available.

**Test before changing this:** rewrite one rule as a ban, run a week, count the failures.

## The condition comes before the file

**Measured on this harness, 18 trials.** A pointer table written `topic -> file` made
sessions open every sibling doc at once. Written `when this happens -> read that`, they
opened almost none.

**Consequence:** every row of the pointer table leads with the condition.

## One meaning, one place

**2026-08-18 to 2026-08-20.** The four-mockup rule was written in two command files. One was
updated to four; the other kept saying eight for two days while its own judge scored "3 of
4". Neither file was wrong on its own.

**Consequence:** a rule two files need lives in `rules/`, and both point at it.

## Act versus propose, settled as one rule

**Codex review, 2026-08-21.** The first draft of this file carried "build the tactical fix on
request" and "propose an alternative and stop" as separate rules with no shared trigger. The
previous setup carried the same collision for months, which produced repeated requests to
approve things already approved.

**Consequence:** rule 2 is one table keyed on what the request contains. There is no second
rule about when to act.

## Version and docs lookup, narrowed

**Codex review, 2026-08-21.** The first draft read as "check the registry before every code
edit", including edits touching no dependency at all.

**Consequence:** rule 5 names its trigger. `cargo add` was replaced with `cargo search` in
the same pass: `add` writes to the project's manifest, so a rule about reading versions was
quietly modifying state.

## Output format follows the owner

**Codex review, 2026-08-21, confirming the owner's own instruction that day.** The draft
forced any two facts into exactly one five-row table. The owner had repeatedly asked for full
documents printed in the terminal, which that rule forbade.

**Consequence:** a stated format wins. The table is the default only when nothing was stated
and a comparison is being made.

## The Codex stage runs before the writing

**2026-08-12.** Across 39 sessions, 503 of 563 edits were made with no plan stage and no
second model. The first time one of those edits was shown to Codex, it found a real defect: a
version guard that checked nothing.

**2026-08-21.** The first Codex call in this rebuild returned eight findings on a
seventy-line rules file. All eight were accepted, two of them collisions between rules that
looked fine in isolation.

**Consequence:** rule 6 runs the check before the code exists, where a finding costs a
rewrite of the approach rather than a rewrite of the work.

## A check that could not run is a flag

**Repeatedly, in the previous setup.** A scanner reported clean when its input was empty. A
detector exited zero on a missing path. A wrapper command that does not exist on macOS made a
scan that never ran look normal for weeks.

**Consequence:** every gate reports "did not run" distinctly from "ran and found nothing". A
clean result means the check executed.

## The destructive-command guard was rewritten three times

**2026-08-21.** Its first version matched fixed strings, so `rm -fr /` walked past it. Its
second used `sed -E 's/.*\brm\b//'`, which BSD sed on macOS does not support, so every
destructive command passed through while the script looked correct. Its third checked only
the first command in a line, so `rm -rf /tmp/x && rm -rf /etc` hid behind its harmless half.
A fourth pass stripped the trailing slash from `/` and turned it into an empty target.

Each was found by running it, never by reading it.

**Consequence:** `INSTALL.md` carries the commands that make each hook refuse, and the guard
is tested against 17 destructive forms and 10 ordinary ones. A guard nobody has watched fail
is a belief.

**Accepted, not fixed:** `echo "rm -rf /etc"` is blocked, because the script matches tokens
rather than parsing shell quoting. A false block costs one retype; a false allow costs the
machine.

## Nothing was carried over, except the guards

**2026-08-21, the owner's decision.** A previous rebuild copied 12,053 lines forward
unchanged. The owner named that as the reason it failed to be a rebuild.

**Consequence:** every rule, doc and skill here was written from a blank page. Names and
measured evidence crossed over; no text did.

The consequence covers instruction-bearing prose: anything a session reads and follows.
`hooks/` is the sole exception, and it is an exception to the blank-page requirement only.
Everything else in this file still applies to a hook, its comments included.

**Measured 2026-08-21**, diffing the whole `hooks/` subtree against the pre-rebuild tree at
`~/.claude-old-2026-08-05`. Fifteen files are byte-identical, four are edited rather than
rewritten, and nine were written here:

| Where | Byte-identical | Edited | Written here |
|---|---|---|---|
| `hooks/` | 8 | 3 | 5 |
| `hooks/tests/` | 7 | 1 | 4 |

Two different reasons, and only the first is about tests:

**Six carry a test that has been watched failing**, so rewriting them from a blank page would
discard the failure each was proven to catch: `format-typecheck.js`,
`literal-mode-tracker.js`, `secret-scan.sh`, `config-protection.js`, `node-shim.sh`,
`pre-commit`. The pattern files `secret-patterns.txt` and `infra-patterns.txt` are data those
tests read, exercised through `secret-scan.test.sh` and the two probe fixtures beside it.

**Three carry no test of any kind:** `statusline.sh`, `literal-statusline.sh`, and the
25-byte `package.json` that marks the directory as CommonJS. They were kept because they were
working and nothing asked them to change, which is a weaker reason than the one above and is
recorded here as such rather than borrowed from it.
