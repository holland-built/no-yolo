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
is tested against 76 destructive forms and 32 ordinary ones, across
`hooks/tests/safety-net.test.sh` (47 assertions) and `hooks/tests/safety-net-exec.test.sh`
(62). A guard nobody has watched fail is a belief.

This line read "17 destructive forms and 10 ordinary ones" until 2026-08-22, which was the
count before the second file existed. Counted with `grep -c '^blocked '` and `grep -c
'^allowed '` over both files; each suite also prints its own total when run, which is the
number to trust if these two ever disagree.

**Accepted, not fixed:** `echo "rm -rf /etc"` is blocked, because the script matches tokens
rather than parsing shell quoting. A false block costs one retype; a false allow costs the
machine.

## Nothing was carried over

**2026-08-21, the owner's decision.** A previous rebuild copied 12,053 lines forward
unchanged. The owner named that as the reason it failed to be a rebuild.

**Consequence:** every rule, doc and skill here was written from a blank page. Names and
measured evidence crossed over; no text did.

### The exemption this section used to claim, and why it was wrong

**This heading read "Nothing was carried over, except the guards" until 2026-08-22, and the
section below it said `hooks/` was "the sole exception".** Both were false, and the second
was false in a way that mattered: it named a boundary narrower than the one actually in
force, so anyone reading it would conclude that everything outside `hooks/` had been
rewritten. Measured on 2026-08-22 against the pre-rebuild tree still on disk at
`~/.claude-old-2026-08-05`, by counting identical non-blank lines shared with each file's
old counterpart:

| File | Old lines still present | In `hooks/`? |
|---|---|---|
| `hooks/statusline.sh` | 86% | yes |
| `hooks/secret-scan.sh` | 79% | yes |
| `agents/*.md` | 78% | **no** |
| `hooks/pre-commit` | 74% | yes |
| `settings.example.json` | 69% | **no** |
| `.gitignore` | 69% | **no** |
| `hooks/node-shim.sh` | 63% | yes |
| `hooks/config-protection.js` | 57% | yes |
| `verify.sh` | 51% | **no** |
| `.github/workflows/ci.yml` | 40% | **no** |
| `setup.sh` | 34% | **no** |
| `verify-selftest.sh` | 29% | **no** |

Fifteen further files were byte-identical, including five test files and both pattern files.
Against that, the prose the rebuild claimed to have rewritten measured 0% to 6%: `CLAUDE.md`
and `docs/TESTING.md` share no line at all with their predecessors, and the six skills share
between 2% and 6%.

So the rebuild did exactly what it said for the half a reader looks at, and left the half a
reader trusts. The cost was not theoretical. Every stale `skills/health` reference found and
deleted on 2026-08-21 and 2026-08-22 was already sitting in that old tree, in three carried
files: `verify.sh`, `hooks/pre-commit`, `hooks/secret-scan.sh`.

### The machinery rebuild, 2026-08-22

**The owner asked for the start-over to be real, and it was done.** Every file in the table
above was rewritten from a blank page, along with the five carried test files and the
deny-list template. The two borrowed agent definitions were deleted rather than rewritten:
nothing tracked referenced them except SHIP.md's own staging list.

**Order, because the order is the only thing that made it checkable.** A rewritten
implementation judged by its own rewritten test proves nothing: both are new, and they agree
with each other by construction. So nothing was ever rewritten alongside its own referee.

| Step | Rewritten | Judged by |
|---|---|---|
| 1 | the nine hooks | their existing test suites, untouched |
| 2 | `verify.sh` | the FROZEN old `verify-selftest.sh`, 24 of 24 sabotages |
| 3 | `verify-selftest.sh` | the `verify.sh` those 24 cases had just certified |
| 4 | the five test suites | the hooks rewritten in step 1 |

The suites grew doing it: 59 node tests to 81, and the shell suites gained cases for symlink
handling, profile isolation, safeword false positives, and a scanner that cannot run.

**What was deliberately NOT re-derived, with its measured overlap, because a rebuild that
hides its own exceptions is the mistake this section exists to correct.** Every file below is
DATA, where the content is the configuration rather than a description of it, so re-typing it
from memory changes behaviour without improving anything:

| File | Still shared | Why it keeps its values |
|---|---|---|
| `LICENSE` | 100% | MIT terms. Authorship is not the point of a licence |
| `hooks/package.json` | 100% | 25 bytes, marking the directory CommonJS |
| `hooks/tests/infra-scan-probe.sha256` | 100% | hashes of the two fixtures |
| `hooks/tests/infra-scan-probe.txt` | 93% | the planted values the scan MUST catch |
| `hooks/secret-patterns.txt` | 92% | the shape of a leaked vendor key |
| `hooks/tests/infra-scan-clean.txt` | 91% | the near-misses it must NOT catch |
| `hooks/infra-patterns.txt` | 87% | the shape of a private LAN address |
| `settings.example.json` | 69% | the permission list IS the setting |
| `.gitignore` | 55% | the ignore patterns ARE the rules |

The pattern files and fixtures are threat data. Re-typing them risks silently dropping a class
the scanner used to catch, which is worse than sharing lines with an old file, and
`secret-scan.test.sh` pins that coverage by anchor so a quiet loss goes red. What WAS rewritten
in all nine is the surrounding text: every header, every comment, every rationale. The two
config files were re-decided entry by entry rather than copied; `settings.example.json` lost
its pinned model in the process, and `.gitignore` was reorganised with each retained-but-quiet
rule marked LEGACY and named.

Everything else measures between 0% and 38%, and the highest of those are the block messages
the tests assert on, the guarded-config list, and the hook wiring strings: contract, not
carried prose.

**Two defects the rebuild produced and the machinery caught**, both worth recording because
both were caught by running something rather than by reading it:

- The first draft of `.gitignore` annotated eleven retained rules with trailing comments.
  git supports no such thing: only a line STARTING with `#` is a comment, so all eleven
  became literal patterns matching nothing, and a `git add -A` staged private mockups
  carrying a real LAN address. `hooks/pre-commit` refused the commit and named the value.
- The first draft of `verify-selftest.sh` wrote its sabotage filenames as literals, making
  the file that tests the dangling-reference row a source of dangling references itself. The
  names are now assembled at run time, and the file needs no exemption markers at all, where
  the version before it had needed four.

## Four linter findings left standing, 2026-08-22

A `/checkup` pass raised ten findings and the owner said fix them all. Six were fixed. These
four are refused on purpose, and the reason is recorded here so the next pass does not spend
its time re-raising them.

| Finding | Why it stands |
|---|---|
| `skills/avoid-ai-writing/CLAUDE.md` cites `claude.ai/code`, which does not resolve | The file is vendored by `npx skills`, gitignored, and overwritten on the next update. A local patch would be silently reverted, and the line is boilerplate inside a skill directory, which is not one of the paths Claude Code loads as instructions. Belongs upstream |
| 68% of the `hooks` block in `settings.json` is Orca's dispatcher, repeated across 11 events | Generated by Orca's installer and re-added on its next run. Editing it buys one clean diff and loses it again |
| Five skills declare unrestricted `Bash`, 5 of agnix's 11 auto-fixable warnings | `/checkup` is the test case, and this very run needed `python3`, `vale`, `find`, `git` and three different `npx` packages. An allowlist tight enough to satisfy the linter would have broken the command mid-audit. Read-only is enforced by the absence of `Write` and `Edit` from `allowed-tools`, which is where it should be enforced |
| 22 of the 24 hard-coded `~/.claude` paths in `INSTALL.md` and `SHIP.md` | Two in `SHIP.md` were genuinely runnable and now use `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`. The rest are prose, recorded results of measured runs, or, at `SHIP.md` line 208, a grep pattern that has to match the literal string `"~/.claude/hooks` inside `settings.example.json`. Converting the two in `INSTALL.md` was tried and reverted: it grew the block past jscpd's threshold and turned the `dupe-check self-scan` row red |

The general rule the four share: a linter finding is a question, not a verdict. A fix that
reverts on the next vendor update, breaks a working command, or edits the record of what was
actually run costs more than the warning it silences.

## docs/AGENTS.md became docs/DELEGATION.md, 2026-08-22

Two agnix warnings, "multiple instruction layers without documented precedence" and "missing
project context section", both anchored at line 1 of a file whose contents were never the
problem. `AGENTS.md` is a filename convention for a project's agent-instruction root file.
This file is a how-to about delegating work, and it was being classified by its name.

Prose was tried first and did not clear either warning, which is the tell that a linter is
reading structure rather than sentences. The rename cleared both at once, and `ctxlint`
independently confirmed the file had been counted as always-loaded context: per-session token
usage fell from 2,652 to 2,007, a 645-token saving in every session, for a file that was only
ever meant to be read on a condition.

The precedence paragraph written during the same pass stays in `CLAUDE.md`, because it is
worth stating regardless of what a linter thinks. It records the one split a linter cannot
see: whether an agent may be dispatched at all belongs to the owner and the harness, while
`docs/DELEGATION.md` governs only how to choose and brief one after that permission exists.

## The self-test refuses a dirty tree, 2026-08-23

`verify-selftest.sh` backs a tracked file up, breaks it, asserts the row goes red, and copies
the backup over it a few seconds later. Anything edited inside that window is overwritten by
a copy of the file as it stood when the run began. Nothing is staged or committed at any
point, so git holds no object to recover from.

It happened. A run overlapped an editing session in the same checkout and reverted eight
tracked files, a `git mv` among them. The work came back only because it was still legible in
a transcript. The first diagnosis blamed `verify.sh`, and that was wrong twice over:
`verify.sh` never invokes the self-test, and neither file contains a single `git checkout`,
`stash`, `restore`, `reset`, `clean` or `worktree` command. Both checked by grep before the
correction was written.

Three guards, in the order they fire:

| Guard | What it stops |
|---|---|
| Refuse a dirty tree | The window cannot contain uncommitted work, because there is none. On a clean tree `git status` after a crash names exactly what was planted |
| A `.selftest.lock` directory, taken with `mkdir` | Two overlapping runs, where the second backs up the first's sabotage and restores it as though it were the real file |
| An exit-time audit of every touched path against its backup | A restore that silently failed. Contents and mode are compared, a file a case created must be gone, and a mismatch turns a green run red |

The audit reads the backups rather than `git status`, because `git status` cannot see either
end of this: `.git/hooks/pre-commit` is sabotaged too and sits outside the work tree, and
`hooks/tests/zzselftest.test.sh` is planted untracked, so `git checkout` would never remove
it. Judging only the paths the run recorded also means a concurrent edit somewhere else is
never misreported as leftover sabotage.

`SELFTEST_ALLOW_DIRTY=1` overrides the first guard and reopens the hole exactly as described.
It exists because developing a new row against a dirty tree is a real need; it is spelled out
rather than silent so that using it is a decision.

Not done, and worth knowing: none of this survives `SIGKILL` or a power cut, because no
finalizer runs at all. The fix for that class is to sabotage a disposable worktree instead of
this one, which is a larger change than this pass took on.
