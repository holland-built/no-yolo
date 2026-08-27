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
| The vendored avoid-ai-writing skill's own `CLAUDE.md` cites `claude.ai/code`, which does not resolve | That file is installed by `npx skills`, gitignored, and overwritten on the next update, so a local patch would be silently reverted. The line is boilerplate inside a skill directory, which is not a path Claude Code loads as instructions. Belongs upstream. Its path is left unquoted above on purpose: it is untracked, so backticking it would turn the dangling-reference row red on every clone but this one |
| 68% of the `hooks` block in `settings.json` is Orca's dispatcher, repeated across 11 events | Generated by Orca's installer and re-added on its next run. Editing it buys one clean diff and loses it again |
| Five skills declare unrestricted `Bash`, 5 of agnix's 11 auto-fixable warnings | `/checkup` is the test case, and this very run needed `python3`, `vale`, `find`, `git` and three different `npx` packages. An allowlist tight enough to satisfy the linter would have broken the command mid-audit. Read-only is enforced by the absence of `Write` and `Edit` from `allowed-tools`, which is where it should be enforced |
| 22 of the 24 hard-coded `~/.claude` paths in `INSTALL.md` and `SHIP.md` | Two in `SHIP.md` were genuinely runnable and now use `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`. The rest are prose, recorded results of measured runs, or, in `SHIP.md` step 8, the config template check, a grep pattern that has to match the literal string `"~/.claude/hooks` inside `settings.example.json`. Converting the two in `INSTALL.md` was tried and reverted: it grew the block past jscpd's threshold and turned the `dupe-check self-scan` row red |

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
`hooks/tests/zzselftest.test.sh` is planted untracked, so `git checkout` would never remove <!-- gone-on-purpose -->
it. Judging only the paths the run recorded also means a concurrent edit somewhere else is
never misreported as leftover sabotage.

`SELFTEST_ALLOW_DIRTY=1` overrides the first guard and reopens the hole exactly as described.
It exists because developing a new row against a dirty tree is a real need; it is spelled out
rather than silent so that using it is a decision.

Not done, and worth knowing: none of this survives `SIGKILL` or a power cut, because no
finalizer runs at all. The fix for that class is to sabotage a disposable worktree instead of
this one, which is a larger change than this pass took on.

## The instruction comes before its story, 2026-08-25

A Codex audit raised eight findings against this repo's own documents, five of them the same
fault in five places: `README.md`, `docs/WRITING.md` and `SHIP.md` each put a dated incident
inside the instruction, so a reader looking for the command read the history first.

The sections below are those histories, moved here. Every command and every measured number
came across unchanged. Nothing was deleted, because a rule without its evidence gets deleted
by the next person who finds it inconvenient, and that is the whole reason this file exists.

**Consequence:** an instruction file states the action, the expected result, whether it
blocks, and one sentence of risk. The incident that produced it lives here with a pointer
back.

## The Codex sandbox was widened for an hour, 2026-08-21

Moved here from `rules/codex.md` on 2026-08-26, under the rule above. Every measured number
came across unchanged.

The sandbox was widened to `workspace-write` to give Codex a network, because a read-only
sandbox has none and it had just reviewed seven invented package names without being able to
look up one of them. Measured, not assumed: under `read-only`, `curl` returns 000 and
`npm view` returns ENOTFOUND. The `network_access` setting belongs to `workspace-write`
alone, so the two cannot be separated.

Within the hour, during two reviews whose prompts asked for findings and nothing else, Codex
wrote a new step into `SHIP.md` and rewrote a section of this file. Both edits turned out to
be substantially correct, and neither was requested. An advisor that edits is not an advisor,
and a review you have to diff afterwards costs more than it returns.

**Verification moved instead of the sandbox.** `hooks/external-check.sh` resolves every
external name against the registry on every run of `verify.sh`, so the job that needed a
network now belongs to this repo and runs on every push, rather than to a model that runs
only when a skill invokes it. Codex is back to what it is good at, which is judgement about a
plan or a diff, and that needs no network at all.

`danger-full-access` was considered and declined at the same time. It reaches the whole disk,
including `~/.ssh` and `~/.aws`, and `codex exec` runs with `approval: never`, so nothing
would sit between a generated command and the filesystem. `hooks/safety-net.sh` is no help
there: it is a Claude Code hook on Claude's own commands and never sees Codex's.

**Consequence:** `rules/codex.md` states the setting and one sentence of why. The hour that
produced it lives here.

## The release playbook twice named files that had been deleted

**2026-08-05.** `SHIP.md` was written against the catalogue system that the fresh-start
rebuild deleted: eight of its ten steps called `/md-check`, `/update`, `skills/my-skills/`,
`skills/my-md/` or `docs/HOOKS.md`, none of which existed. Two of those were hard blocks, so <!-- gone-on-purpose -->
every release would have stopped forever.

**2026-08-21. It happened a second time.** The rebuild cut 13 skills to 6 (counted from
`git ls-tree -d --name-only 7fb7448^:skills`; that line said 26 until 2026-08-22, and no commit
on this branch ever held that many) and replaced the rule files. The playbook was left naming
`docs/ANTISLOP.md` and `docs/README_FORMAT.md`, along with a mockup-pruning script that went <!-- gone-on-purpose -->
with `/design`. All deleted. Three of nine steps, two of them hard blocks.

The sweep that should have caught it is the dangling-reference check, and it did not run,
because it lived in `SHIP.md` and only in `SHIP.md`, so it ran only when somebody ran a
release, and nobody released in between.

**Consequence, two of them.** A step belongs in `SHIP.md` only if the thing it runs is on disk
right now; check before adding one, and check again after any rebuild. And the sweep moved
into `verify.sh` on 2026-08-21, so it now runs on every push and in CI on both platforms, with
`verify-selftest.sh` sabotaging it to prove it can still go red.

### The copy of the sweep that SHIP.md kept, and why it is gone

Until 2026-08-25 `SHIP.md` carried a second copy of the sweep's command under the sentence "It
is the same code the row runs." It was not. `verify.sh` reads `git ls-files -- '*.md' '*.sh'
'*.js'` and extracts nine extensions; the `SHIP.md` copy read `'*.md'` alone and extracted six.
Two versions of one check, one of them describing itself as the other, is the failure this
whole section is about repeating itself one level down.

The copy is kept here as evidence rather than as a command to run. `bash verify.sh` is the
only live instruction:

<!-- jscpd:ignore-start -->
```bash
git ls-files -- '*.md' | while read -r src; do
  grep -v 'gone-on-purpose' "$src" \
    | grep -oE '`(docs|rules|skills|hooks|agents)/[A-Za-z0-9._/-]+\.(md|sh|js|py|mjs|json)`' \
    | tr -d '`' | while read -r p; do
        [ -e "$p" ] || [ -e "$(dirname "$src")/$p" ] || echo "DANGLING: $p  (in $src)"
      done
done | sort -u
```
<!-- jscpd:ignore-end -->

The markers hide that block from the duplicate scanner alone, and the reason is worth
recording because it is the scanner misfiring rather than a judgement call. Two nested
`while read` loops sharing `"$p"`, `"$src"` and `done` match themselves: on 2026-08-25 jscpd
reported the region `[341:1 - 349:3]` as a 332-token clone of `[341:2 - 349:4]`, the same nine
lines offset by one character. A block cannot be a copy of itself.

Three details in it are each hard-won, and the live row in `verify.sh` keeps all three:

- **Only backtick-quoted paths count.** This repo cites every real file in backticks. Matching
  bare text instead produces a flood of substring hits, the tail of "ingest-docs/SKILL.md"
  looks like a docs path, and the tail of "~/.agents/skills/x" looks like an agents path.
- **Driven off `git ls-files`, not a directory walk.** Only tracked files can break a release
  for someone else, and walking directories drags in gitignored third-party folders whose
  contents are never edited here.
- **The marker is filtered per line, before extraction.** `grep -o` prints only the matched
  path and throws its line away, so filtering afterwards can never see the marker.

Gitignored-by-design paths are the one real gap, because they exist locally and are absent on
a fresh clone, so the check passes for you and fails for a stranger. Two live cases:
`memory/MEMORY.md` and `memory/facts/`. Neither is matched by the pattern, and that is
deliberate rather than lucky, so anything that starts citing them has to name the tracked
template beside them, the way `settings.example.json` sits beside `settings.json`.

A third case IS matched: the vendored skill directories, which are gitignored per-name near
the foot of `.gitignore`. Citing a file inside one in backticks passes locally and fails in
CI, which is how it was found on 2026-08-23. Name such a file in plain words rather than
backticks, and say it is vendored.

To catch that whole class before pushing, ask whether each cited path is TRACKED rather than
merely present. That is the same sweep with one line changed: replace the existence test in
the innermost loop with

```bash
git ls-files --error-unmatch "$p" >/dev/null 2>&1 \
  || echo "UNTRACKED BUT CITED: $p  (in $src)"
```

The two versions were written out in full, side by side, until 2026-08-25, when the duplicate
scanner reported them as a 361-token clone of each other. It was right to. Twelve identical
lines around one differing test hide the only thing a reader needs to see.

## The remote pointed at its own working directory, 2026-08-05

Every push from this repo silently went nowhere, and the rebuilt setup sat unpublished while
looking pushed. A self-referencing remote still resolves `origin/*`, still reports "up to
date", and still exits 0. Nothing about it looks wrong.

`main` became the rebuilt setup the same day. The two histories were unrelated, since the
rebuild started from an empty room, so this was a force-push and not a merge. The pre-rebuild
setup is kept in two places, per the plan's promise that nothing is destroyed: tag
`pre-rebuild-2026-08-05` holds `main` exactly as it stood before the swap, and branch
`migrate-wshobson-agents` holds the same plus three commits of in-flight work.

**Consequence:** if a branch claims to be in sync but GitHub disagrees, check `git remote -v`
before anything else.

## The README inventory row replaced a count run by hand, 2026-08-21

The check on README's skills table used to be `ls -d skills/*/ | wc -l`, typed during a
release. It was weak in two ways.

A count cannot see a swap: rename one skill in the table and the number is still six while two
rows are wrong. And `ls -d skills/*/` counts the `npx skills` symlinks that `.gitignore`
lists, which exist on this machine and not in a fresh clone, so the local answer and the CI
answer could disagree without anything being broken.

**Consequence:** the `README skills inventory` row in `verify.sh` compares skill NAMES in both
directions against tracked `skills/*/SKILL.md`, then checks the spelled number against how
many it found. It counts what is tracked, because what is tracked is what ships. The
`README outside-pieces count` row beside it does the same for the other number the front page
publishes; that one went stale twice before anything watched it.

## The README prose sweep, and why its command reads oddly

**2026-08-21.** Seven install references reached publication whose every surrounding path was
valid and six of whose package names were not. A dangling-path check cannot catch a sentence
whose every path resolves and whose description is wrong.

**2026-08-22.** A release changed 36 files across `hooks/`, `verify.sh`,
`skills/build/stages/` and `INSTALL.md`. README moved by three lines, every one of them a
number. Nothing asked whether the page still described the setup, because nothing there ever
had.

**Consequence:** `SHIP.md` step 7 prints every README line naming a changed skill or rule, and
requires a written "still true" or the edit made when the release touches any of those four
paths. It is warn-only, on purpose: whether a sentence still reads true is a judgement, and a
block on a judgement gets satisfied by editing the sentence until the gate stops complaining.

Four details in that step's command, each because the obvious version fails:

- **The change set is `origin/HEAD`, not `--cached`.** Staging happens after the read-only
  steps, so a `--cached` diff reads empty and a step that examined nothing looks exactly like a
  step that found nothing. Comparing against the remote covers staged, unstaged and
  already-committed-but-unpushed alike, which is what the release will actually publish. Step 1
  read `--cached` for the same reason and was corrected on 2026-08-22.
- **The names come off a pipe, not out of a variable.** The obvious version collects them into
  `changed` and runs `for n in $changed`, which works in bash and silently does not in zsh: zsh
  performs no word splitting on an unquoted expansion, so the loop runs once with every name
  glued into one string and greps for something that cannot match. Reproduced on 2026-08-21:
  the same loop over "a b c" runs once under zsh and three times under bash.
- **`grep -nF`, with `|| true`.** Fixed-string, and a no-match exit status is swallowed. A
  warn-only step whose last name happens to miss must not report failure.
- **A removed skill is not a finding.** `[ -e "$p" ]` separates a skill the page never
  introduced, which is a gap, from one deleted on purpose, which is expected.

The base for the acknowledgement command falls back to `origin/HEAD` because a shallow CI
clone has no tags, and a step that errors into an empty list reads exactly like a step that
found nothing to say.

Some skill names are ordinary English words, so `design` and `release` match prose that is not
about them. Read the line, never the count. That noise is the price of a substring match, and
a stricter pattern would miss the sentence naming a skill without backticks, which is the
sentence the step exists to catch.

## Stage scope: every path in that list was omitted once

`SHIP.md` stages explicit paths rather than a `*.md` shell glob, which expands in the CWD
rather than the repo root. Each entry below was left out once and something silently never
shipped.

| Path | What its omission cost |
|---|---|
| `.github/` | Holds `workflows/ci.yml`, the workflow that runs `verify.sh`. Omitted once, so a CI-config fix could never ship |
| `verify.sh`, `verify-selftest.sh` | Both tracked, both run by CI. Omitted once, so a fix to the verifier itself silently never shipped. CI ran only the first of the two until 2026-08-21 while the playbook claimed both; the `selftest` job in `.github/workflows/ci.yml` is what made the sentence true. Before it existed, every row's proof-of-falsifiability depended on a person remembering to type `bash verify-selftest.sh` |
| `memory/MEMORY.example.md` | The only tracked thing under `memory/`. Until 2026-08-21 a compiled view shipped instead; the compiler is gone and the index that replaced it is written by hand |
| `rules/` | Holds the files two or more skills share. A rule that lives in one skill stays in that skill; a rule two files need lives here, so the number in one cannot drift from the number in the other |
| `LICENSE` | The MIT terms the README's licence badge reads. Omit it and the badge renders "unknown" against a file git never received |
| `archive/` | Skills kept for their text rather than for loading. From 2026-08-25 it also holds `archive/styleseed/`, a hash-verified snapshot of 23 skills that were never in git at all. `.gitignore` un-ignores `archive/styleseed/.agents/` for it, because the blanket `.agents/` rule was swallowing 52 of its 104 files, engine included, and an archive that lives on one laptop is not an archive |
| `output-styles/` | Added 2026-08-25. Loaded every session by `settings.json`, so omitting it would ship a repo whose `outputStyle` names a file a fresh clone does not have |
| `refs/` | Vendored reference data rather than code. It sits at the top level and not under a skill on purpose: the previous copy lived at `skills/design/vendor/`, was gitignored, and vanished with the skill on 2026-08-21 without anything noticing |
| `agents/` | In the list until 2026-08-22, holding two borrowed subagent definitions whose text was 78% identical to the pre-rebuild copies. Nothing tracked referenced them beyond the list itself, so the machinery rebuild removed them rather than rewriting them. A lean local agent can return when a named workflow shows a plugin cannot supply it |
| `commands/` | Named in the list until 2026-08-21, when no such directory existed. The rebuild deleted it and the line outlived it |

The `jscpd:ignore` markers around the staging command hide it from the duplicate scanner
alone. It shares enough generic git tokens with the `git rebase upstream/main` snippet, which
sat in `README.md` until 2026-08-25 and now sits in `docs/MAINTAINING.md`, to be reported as a
267-token clone of it, though one is a path list and the other pulls upstream changes in. The
pair went red the first time a change touched both files at once, which was 2026-08-23.

Two blocks in this repo carry those markers, and both are shell inside markdown that the
scanner reads as generic git tokens: that staging command, and the retired sweep above. Every
other duplicate finding is answered by deleting the duplicate.

## The changelog file that made every change five changes

**2026-08-21.** The rebuild deleted `docs/DAILY_CHANGELOG.md`, which was the single <!-- gone-on-purpose -->
most-edited file in the repo.

**Consequence:** release notes are the commit subjects since the previous tag, rewritten so a
stranger understands them. There is no changelog file to read from, and no plan to add one.

## The context budget had no number until 2026-08-25

`docs/WRITING.md` explained that a context budget existed and never said what it was, so
nothing could be over it and the always-loaded chain grew from nobody's decision.

**Consequence:** 2,200 words across the four files loaded on every session, `CLAUDE.md`,
`rules/codex.md`, `rules/mockups.md` and `output-styles/plain.md`, enforced by a `verify.sh`
row. The number is a ratchet, not a target: it is what the chain measured on the day it was set
plus a little room, so it stops growth without claiming the current size is right. Lowering it
means rewriting the two long files, and that is a separate job.

**It is a local choice, arrived at by measuring this repo, and not a published benchmark.** A
figure of 300 to 350 words was quoted to the owner twice as measured fact during the same
period. It came from a video attributing it to Anthropic and was never found on an Anthropic
page.

## Ctxlint was never the package name

`docs/WRITING.md` named a tool as `Ctxlint`, which is neither its package name nor its
capitalisation, and stood that way from the day it was written. The real name is
`@yawlabs/ctxlint`.

**Consequence:** naming an outside tool is itself a claim. Query it before writing it
(`CLAUDE.md` rule 5), add it to `hooks/externals.txt` with the project it resolves to, and
`hooks/external-check.sh` holds you to it on every run of `verify.sh`.

## The front page counted its own skills wrong, twice

**"26 skills" until 2026-08-22.** No commit on this branch ever had 26 skills in it. Counted
with `git ls-tree -d --name-only <commit>:skills | wc -l` across the last sixty commits, the
tracked total goes 17, then 18, then 13 on 2026-08-20 when eight commands were archived, then 6
at the rebuild. Thirteen is what stood on the day. The likeliest source of 26 is a count that
included the borrowed skills symlinked into `skills/` alongside this repo's own, which are
gitignored and cannot be recovered from history, so the number that replaced it is the one that
can be recomputed.

**"Roughly 390 commits" until 2026-08-22.** There are only 341 commits in this repository
across every ref (`git rev-list --count --all`), so the figure was larger than the entire
history it was drawn from. The real claim underneath it stands: 61 of those 341 commits touched
a catalogue, index, manifest or lock file, roughly one commit in six spent on files whose only
job was describing other files. The 61 comes from counting distinct commits touching
`*CATALOG*`, `*index*`, `*MANIFEST*` and `*lock*` paths; the pattern is deliberately generous
and still lands nowhere near the old number.

**Consequence:** there is deliberately no catalogue to update, no lock file to re-seal and no
index to regenerate. `/checkup` derives the inventory from the folder at read time, and
`verify.sh` holds the one number the front page still publishes.

### Where the deleted skills went

Thirteen skills stood until 2026-08-21. The rebuild kept the six that were used and deleted the
rest. Archived commands are not gone: each has a one-line restore command in
`archive/MANIFEST.md`. `watch` is the proof, archived on 2026-08-20 and restored on 2026-08-25
by running the line the manifest had been holding for it.

`eli5` left on 2026-08-25 and did not go to `archive/`. Its rules moved to
`output-styles/plain.md`, which loads by itself every session. A skill has to be invoked, and
the owner had said plainly that they cannot remember to invoke anything, so the rules were
sitting in the one slot least able to reach them. Nothing was lost; the same words now arrive
without being asked for.

**Consequence:** before adding a skill, ask whether an existing one should gain a mode instead.
Six commands with modes beat twenty-six commands, and that is the entire lesson of this repo's
first six weeks.

## A copied settings.json drifted between two accounts, 2026-08-05

`settings.json` is the file people copy instead of linking when they run a second account, then
edit in one folder and not the other. That drift left the work folder pointing at five hooks
this repo had deleted: two errors on every session start, `MODULE_NOT_FOUND`, and none of the
guards the main folder had.

**Consequence:** `docs/MAINTAINING.md` links `settings.json` rather than copying it, and says
so in bold. Because the file is gitignored, cloning the repo cannot recreate those links, which
is why they are written down rather than automated.
