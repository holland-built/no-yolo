#!/usr/bin/env bash
# verify.sh — one-command verification for the no-yolo repo.
# Runs locally (repo at ~/.claude) AND in CI (repo at $GITHUB_WORKSPACE).
# Repo root is derived from this script's own location — never hardcoded.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || { echo "cannot cd to $ROOT"; exit 1; }

fail=0
results=()
record() { results+=("$1|$2"); [ "$1" = FAIL ] && fail=1; return 0; }

# 1. hook unit tests (glob form REQUIRED on this node build)
if node --test 'hooks/tests/*.test.js' >/tmp/verify-tests.log 2>&1; then
  record PASS "hook unit tests"
else
  record FAIL "hook unit tests (see /tmp/verify-tests.log)"
fi

# 1b. hook shell tests — check 1's glob is *.test.js only, so *.test.sh ran nowhere.
ok=1
shopt -s nullglob
sh_tests=(hooks/tests/*.test.sh)
for t in "${sh_tests[@]}"; do
  bash "$t" >>/tmp/verify-sh-tests.log 2>&1 || { echo "FAILED: $t"; ok=0; }
done
shopt -u nullglob
if [ "${#sh_tests[@]}" -eq 0 ]; then
  record PASS "hook shell tests (none present)"
elif [ "$ok" = 1 ]; then
  record PASS "hook shell tests (${#sh_tests[@]})"
else
  record FAIL "hook shell tests (see /tmp/verify-sh-tests.log)"
fi

# 2. bash -n over every tracked .sh
ok=1
while IFS= read -r f; do [ -z "$f" ] && continue; bash -n "$f" || ok=0; done < <(git ls-files '*.sh')
[ "$ok" = 1 ] && record PASS "shell syntax (bash -n)" || record FAIL "shell syntax (bash -n)"

# 3. settings.example.json parses
if python3 -c "import json;json.load(open('settings.example.json'))" 2>/dev/null; then
  record PASS "settings.example.json parses"
else
  record FAIL "settings.example.json parses"
fi

# 4. reject quoted "~/.claude/hooks/ (tilde never expands inside double quotes,
#    and hook commands are the only strings in this file that get shell-executed;
#    other quoted "~/... values, e.g. additionalDirectories, are read directly by
#    Claude Code's own config loader, not a shell, so they are out of scope here)
if grep -nE '"~/\.claude/hooks/' settings.example.json >/dev/null 2>&1; then
  record FAIL 'settings.example.json has a quoted "~/.claude/hooks/ path — use $HOME (see plan 007)'
else
  record PASS 'no quoted ~ in settings.example.json hook commands'
fi

# 5. every hook path referenced in settings.example.json exists in the CHECKOUT
ok=1
for p in $(grep -oE '(\$HOME|~)/\.claude/hooks/[a-zA-Z0-9._-]+' settings.example.json | sort -u); do
  rel="hooks/${p##*/hooks/}"
  [ -f "$ROOT/$rel" ] || { echo "missing hook: $rel"; ok=0; }
done
[ "$ok" = 1 ] && record PASS "hook paths exist" || record FAIL "hook paths exist"

# 6c. setup.sh bash-3.2 clean — stock macOS ships bash 3.2 and the documented
#     install command is `bash setup.sh`; a bash-4-only construct hard-blocks
#     every un-provisioned Mac (shipped once: declare -A in the preflight).
#     Guards the whole class: declare -A, mapfile/readarray, ${var^^}/${var,,}.
if ! grep -qE 'declare -A|mapfile|readarray|\$\{[a-zA-Z_]+(\^\^|,,)\}' setup.sh && /bin/bash -n setup.sh 2>/dev/null; then
  record PASS "setup.sh bash-3.2 clean"
else
  record FAIL "setup.sh bash-3.2 clean — bash-4-only construct or syntax error (stock Mac bash is 3.2)"
fi

# 7. shellcheck — BLOCKING at warning severity and above.
#    Was warn-only for months: `record WARN` never sets fail=1, so it ran on every
#    CI push (ubuntu-latest ships shellcheck), found real things, and could not fail
#    the build. Nobody read it. A check that cannot go red is decoration.
#    -S warning: errors+warnings block; style/info notes (SC2015 A&&B||C, SC2016
#    single-quoted regexes, SC2013 for-over-grep) are deliberate here and don't.
if command -v shellcheck >/dev/null 2>&1; then
  if git ls-files '*.sh' | xargs shellcheck -S warning >/tmp/verify-shellcheck.log 2>&1; then
    record PASS "shellcheck"
  else
    record FAIL "shellcheck findings (see /tmp/verify-shellcheck.log)"
  fi
else
  record WARN "shellcheck not installed — skipped (CI has it; install locally: brew install shellcheck, or sudo apt install shellcheck)"
fi

# 7b. external references — every tool a tracked install command names must be declared in
#     hooks/externals.txt and must still resolve to the project pinned there.
#
#     WHY THIS ROW EXISTS. On 2026-08-21 this repo published seven install references and six
#     were wrong: four GitHub repos under an owner who does not own them, one npm package under
#     a name that is not its published name, and cxpak, which has never existed anywhere, with
#     a build stage written to run it. Every other check in this file was green throughout.
#     Nothing here had ever asked whether a name resolves.
#
#     EXIT 3 IS A FAILURE, NOT A SKIP. The script separates "this name is wrong" (1) from "I
#     could not reach the registry" (3), and both go red. An unrun check and a clean check look
#     identical, which is the argument this whole file is built on. Set EXTERNAL_CHECK_OFFLINE=1
#     to downgrade the unreachable case to WARN when you are deliberately working offline; it is
#     opt-in on purpose, so it cannot become the silent default in CI.
"$ROOT/hooks/external-check.sh" >/tmp/verify-external.log 2>&1
ext_rc=$?
case "$ext_rc" in
  0) record PASS "external references resolve" ;;
  1) record FAIL "external references — a tracked install command names something that does not exist or points elsewhere (see /tmp/verify-external.log)" ;;
  *)
    if [ -n "${EXTERNAL_CHECK_OFFLINE:-}" ]; then
      record WARN "external references — could not reach the registry, downgraded by EXTERNAL_CHECK_OFFLINE (see /tmp/verify-external.log)"
    else
      record FAIL "external references COULD NOT RUN (exit $ext_rc) — this is not a clean result; set EXTERNAL_CHECK_OFFLINE=1 if you are deliberately offline (see /tmp/verify-external.log)"
    fi ;;
esac

# 8. tracked-content scan — CI backstop for the local pre-commit hook
#    (pre-commit only guards staged diffs on machines that ran setup.sh; a
#    --no-verify commit or a pre-setup commit would otherwise publish a leak).
#    NEITHER rule set is mirrored anywhere any more. The credential rules live in
#    hooks/secret-patterns.txt; the private-network / internal-infra rules live in
#    hooks/infra-patterns.txt. Both are reachable only by executing
#    hooks/secret-scan.sh (--infra selects the second), which pre-commit, this file
#    and /health all call. No caller holds a copy of either, so there is no second
#    copy left to drift.
#    Excludes are ONLY files that legitimately document the patterns.
#
# WHY THE INFRA RULES CARRY NO \b — kept here because this is the scan that went
# blind. The rules themselves have moved to hooks/infra-patterns.txt, whose header
# now carries this warning, and hooks/secret-scan.sh's lint enforces it
# mechanically (it refuses to load any rule file containing \b). git grep on macOS
# does not honour \b — it silently matches nothing, so the hostname rules were DEAD
# on the very machine that does the committing: a leaked <host>.home or
# <host>.internal sailed through the scan and only a Linux run would ever have
# caught it. Meanwhile GNU grep on Linux honoured \b and matched a plain pathlib
# home() call, reporting private data in a file that had none. Failing open on one
# platform and crying wolf on the other, from one metacharacter. Explicit character
# classes behave the same everywhere — which is why the character-class form is the
# one that survived into the rule file, and the \b form was deleted.
#
# Both rule files are excluded for the same reason as the probe fixtures, but NEITHER
# is pinned by sha256: a file of regexes matches its own rules (the ghp_ rule looks
# exactly like a ghp_ token; the RFC1918 rules look like RFC1918 addresses), and unlike
# the fixtures they are MEANT to change — every new vendor prefix lands in one of them.
# Their compensating control is inside the scanner instead — secret-scan.sh lints
# whichever file it loads on every single run: bare literals with no metacharacter
# (i.e. a pasted value, not a rule), \b, a rule count under that file's own floor, a
# pattern that will not compile, and any string in a COMMENT that matches the file's own
# rules all make it refuse to scan.
# `:!skills/health/SKILL.md` sat in this list until 2026-08-21 and in hooks/pre-commit's <!-- gone-on-purpose: naming the deleted skill is the point of this note -->
# matching list beside it. That skill was deleted by the rebuild, so the pathspec matched
# nothing and excluded nothing: inert, and therefore silent. It is gone from both lists
# together, because the comment in pre-commit calls them mirrors of each other.
SCAN_EXCLUDE=(':!hooks/pre-commit' ':!verify.sh' ':!.no-yolo-deny.example.txt' ':!hooks/tests/infra-scan-probe.txt' ':!hooks/tests/infra-scan-clean.txt' ':!hooks/secret-patterns.txt' ':!hooks/infra-patterns.txt')

# The two pattern files are the single source for every leak rule in this repo. If either
# is missing, gutted, or holds an uncompilable rule, the scanner refuses to scan at all —
# these rows are where that surfaces, and they fail CLOSED.
if "$ROOT/hooks/secret-scan.sh" --check >/tmp/verify-secretscan.log 2>&1; then
  record PASS "secret pattern file healthy"
else
  record FAIL "secret pattern file healthy — pattern file missing/gutted/invalid (see /tmp/verify-secretscan.log)"
fi

if "$ROOT/hooks/secret-scan.sh" --infra --check >/tmp/verify-infrascan.log 2>&1; then
  record PASS "infra pattern file healthy"
else
  record FAIL "infra pattern file healthy — pattern file missing/gutted/invalid (see /tmp/verify-infrascan.log)"
fi

# One probe line through ONE rule set of the scanner. $1 is the rule-set flag ("--infra"
# or empty), $2 the line. Returns the scanner's own status verbatim: 0 caught, 1 not
# caught, anything else the scan COULD NOT RUN — which every caller below turns into its
# own FAIL, never a silent missed line.
scan_line() {
  if [ -n "$1" ]; then
    printf '%s\n' "$2" | "$ROOT/hooks/secret-scan.sh" "$1" >/dev/null 2>&1
  else
    printf '%s\n' "$2" | "$ROOT/hooks/secret-scan.sh" >/dev/null 2>&1
  fi
}

# 8a. POSITIVE CONTROL — prove the pattern can still MATCH, before trusting a
#     clean result from it.
#
#     Check 8 below passes when it finds nothing. So does a pattern that has been
#     broken: delete a metacharacter, or run it on a platform whose regex engine
#     reads it differently, and the scan reports "no findings" forever. That is
#     exactly what happened once already — the \b in the hostname rules matched
#     NOTHING under git grep on macOS, so the scan went green on the very machine
#     doing the committing. It was found by hand, not by this file, because nothing
#     here could tell "clean" from "blind".
#
#     The planted values live in hooks/tests/infra-scan-probe.txt rather than
#     inline, because inline values get blocked by the very hook this tests (they
#     did — hooks/pre-checkin refused the first version of this commit, correctly).
#     Those fixture files are excluded from the scans by name and PINNED by sha256,
#     so the one place a real leak could hide is a file that cannot change without
#     failing the build. See their headers.
PROBE_LEAK="hooks/tests/infra-scan-probe.txt"
PROBE_CLEAN="hooks/tests/infra-scan-clean.txt"
PROBE_SUMS="hooks/tests/infra-scan-probe.sha256"

probe_ready=1
for f in "$PROBE_LEAK" "$PROBE_CLEAN" "$PROBE_SUMS"; do
  [ -f "$f" ] || { echo "missing scan-probe fixture: $f"; probe_ready=0; }
done

# shasum on macOS, sha256sum on Linux — neither is present on both.
sha256_of() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  else sha256sum "$1" | awk '{print $1}'; fi
}

if [ "$probe_ready" = 0 ]; then
  record FAIL "infra scan positive control — fixtures missing, so the scan is unfalsifiable"
else
  # The fixtures are excluded from the scan, so they are pinned. A changed fixture
  # is either a deliberate edit (update the hash) or an attempt to hide a value
  # inside the one file the scan does not read.
  sums_ok=1
  for f in "$PROBE_LEAK" "$PROBE_CLEAN"; do
    want=$(awk -v f="$f" '$2==f {print $1}' "$PROBE_SUMS")
    got=$(sha256_of "$f")
    if [ -z "$want" ]; then echo "no pinned hash for $f in $PROBE_SUMS"; sums_ok=0
    elif [ "$want" != "$got" ]; then
      echo "scan-probe fixture CHANGED: $f"
      echo "  pinned $want"
      echo "  actual $got"
      echo "  These files are excluded from the leak scan, so their contents are pinned."
      echo "  If the edit is deliberate, update $PROBE_SUMS."
      sums_ok=0
    fi
  done
  if [ "$sums_ok" = 0 ]; then
    record FAIL "infra scan probe fixtures changed — pinned hash mismatch (see above)"
  else
    # BOTH rule sets get exercised per line, because neither one alone can catch the
    # fixture: the infra values (RFC1918/CGNAT addresses, internal-TLD hostnames) live
    # in hooks/infra-patterns.txt and the credential values in hooks/secret-patterns.txt.
    # Testing one would silently declare the other's planted lines "missed", so a line
    # counts as caught if EITHER rule set sees it. Both halves are now the SAME
    # executable, so this control tests the thing the hook actually runs — the git grep
    # sandbox it used to need (a tempdir, one file per probe line, `git -C` so the
    # pathspec sat inside the tree git grep searched) is gone with the second engine.
    scan_missed=""
    scan_broke=0
    scan_i=0
    while IFS= read -r probe_line; do
      case "$probe_line" in ''|'#'*) continue ;; esac
      # Strip the `@@` escape marker — see the fixture header for why it exists.
      probe_line=${probe_line//@@/}
      scan_i=$((scan_i + 1))
      # 0 = matched, 1 = no match, ANYTHING ELSE = the scan could not run. A broken
      # scanner exits non-zero on every line, which reads identically to "the rules
      # are blind" — so it gets its own flag and its own FAIL, never counted as a miss.
      scan_hit=0
      scan_line --infra "$probe_line"
      scan_rc=$?
      case "$scan_rc" in
        0) scan_hit=1 ;;
        1) ;;
        *) scan_broke=1 ;;
      esac
      if [ "$scan_hit" -eq 0 ]; then
        scan_line '' "$probe_line"
        scan_rc=$?
        case "$scan_rc" in
          0) scan_hit=1 ;;
          1) ;;
          *) scan_broke=1 ;;
        esac
      fi
      if [ "$scan_hit" -eq 0 ] && [ "$scan_broke" -eq 0 ]; then
        scan_missed="${scan_missed}
    MISSED: $probe_line"
      fi
    done < "$PROBE_LEAK"

    scan_false=""
    scan_j=0
    while IFS= read -r probe_line; do
      case "$probe_line" in ''|'#'*) continue ;; esac
      probe_line=${probe_line//@@/}
      scan_j=$((scan_j + 1))
      # A clean line is a false positive if EITHER rule set fires on it — the negative
      # control has to cover both, or half the crying-wolf goes unseen.
      scan_hit=0
      scan_line --infra "$probe_line"
      scan_rc=$?
      case "$scan_rc" in
        0) scan_hit=1 ;;
        1) ;;
        *) scan_broke=1 ;;
      esac
      if [ "$scan_hit" -eq 0 ]; then
        scan_line '' "$probe_line"
        scan_rc=$?
        case "$scan_rc" in
          0) scan_hit=1 ;;
          1) ;;
          *) scan_broke=1 ;;
        esac
      fi
      if [ "$scan_hit" -eq 1 ]; then
        scan_false="${scan_false}
    FALSE POSITIVE: $probe_line"
      fi
    done < "$PROBE_CLEAN"

    if [ "$scan_broke" -eq 1 ]; then
      record FAIL "infra scan positive control — hooks/secret-scan.sh could not run (exit >1); the control is unfalsifiable, not clean"
    elif [ "$scan_i" -eq 0 ] || [ "$scan_j" -eq 0 ]; then
      record FAIL "infra scan positive control — fixtures held no usable lines ($scan_i leak, $scan_j clean)"
    elif [ -n "$scan_missed" ]; then
      printf 'infra scan is BLIND to values it must catch (on %s):%s\n' "$(uname -s)" "$scan_missed"
      record FAIL "infra scan positive control — the pattern matches nothing it should"
    elif [ -n "$scan_false" ]; then
      printf 'infra scan flags values it must not (on %s):%s\n' "$(uname -s)" "$scan_false"
      record FAIL "infra scan negative control — the pattern cries wolf"
    else
      record PASS "infra scan positive control ($scan_i planted caught, $scan_j clean ignored)"
    fi
  fi
fi

# Both halves are now ONE executable over ONE file list — the same executable, and the
# same two rule files, pre-commit runs. The list is built with a NUL-safe read loop and
# not xargs — xargs exits 123 when the child exited 1..125, so "nothing found" (grep 1)
# and "the scanner blew up" (grep 2) both arrive as 123, which is a fail-open in disguise.
#
# The status of each half is captured explicitly, because this row used to FAIL OPEN on
# exactly that inversion: it was `if git grep ...; then FAIL; else PASS; fi`, which routes
# exit 1 (searched everything, found nothing) and exit >=2 (the scan ERRORED — bad
# pathspec, unreadable tree, a regex that would not compile) into the same PASS branch.
# The scan breaking looked identical to the repo being clean. PASS is now reachable only
# from a real, completed, empty result on BOTH halves.
cred_files=()
while IFS= read -r -d '' f; do cred_files+=("$f"); done < <(git ls-files -z -- . "${SCAN_EXCLUDE[@]}")
infra_rc=1
cred_rc=1
if [ "${#cred_files[@]}" -eq 0 ]; then
  # bash 3.2 (stock macOS) errors on "${arr[@]}" for an empty array under set -u, so this
  # is guarded — but an empty list is also an anomaly in its own right. A scan of zero
  # files finds zero leaks and that is not a clean bill of health.
  cred_rc=99
else
  "$ROOT/hooks/secret-scan.sh" --infra --files "${cred_files[@]}" >/tmp/verify-scan.log 2>&1
  infra_rc=$?
  "$ROOT/hooks/secret-scan.sh" --files "${cred_files[@]}" >>/tmp/verify-scan.log 2>&1
  cred_rc=$?
fi

if [ "$cred_rc" -eq 99 ]; then
  record FAIL "tracked-content scan — git ls-files returned NO files to scan; the result is empty, not clean"
elif [ "$infra_rc" -ge 2 ] || [ "$cred_rc" -ge 2 ]; then
  record FAIL "tracked-content scan COULD NOT RUN (infra scan exit $infra_rc, credential scan exit $cred_rc) — see /tmp/verify-scan.log"
elif [ "$infra_rc" -eq 0 ]; then
  record FAIL "tracked-content scan — private/infra value in a tracked file (see /tmp/verify-scan.log)"
elif [ "$cred_rc" -eq 0 ]; then
  record FAIL "tracked-content scan — credential in a tracked file (see /tmp/verify-scan.log)"
else
  record PASS "tracked-content scan"
fi

# 8b. The COMMIT-BLOCKING path gets the same control, run the way pre-commit runs it.
#     This check used to lift the hook's patterns out with sed, because pre-commit
#     carried them as text: first `PATTERNS`, then — after the credential rules moved
#     — just `INFRA_PATTERNS`. Both parses are now gone, because pre-commit holds NO
#     pattern copy at all: step 2 executes hooks/secret-scan.sh and step 3 executes it
#     again with --infra. There is nothing left to parse out of the hook, and nothing
#     left that can go stale between the two files.
#
#     8a and 8b are no longer two engines against one fixture; they are two CALLERS of
#     one engine. 8b keeps its own row because it asserts the exact pair of invocations
#     that block a commit, and a caller can still be wired up wrong.
if [ -f hooks/pre-commit ] && [ -f "$PROBE_LEAK" ]; then
  pc_missed=""
  pc_broke=0
  pc_n=0
  while IFS= read -r probe_line; do
    case "$probe_line" in ''|'#'*) continue ;; esac
    probe_line=${probe_line//@@/}
    pc_n=$((pc_n + 1))
    pc_hit=0
    # The exact invocation pre-commit's step 3 uses on its added lines. Same three-way
    # handling as 8a: a scanner that cannot run is a FAIL of its own, never a silent
    # missed line.
    scan_line --infra "$probe_line"
    pc_rc=$?
    case "$pc_rc" in
      0) pc_hit=1 ;;
      1) ;;
      *) pc_broke=1 ;;
    esac
    if [ "$pc_hit" -eq 0 ]; then
      # The exact invocation pre-commit's step 2 uses.
      scan_line '' "$probe_line"
      pc_rc=$?
      case "$pc_rc" in
        0) pc_hit=1 ;;
        1) ;;
        *) pc_broke=1 ;;
      esac
    fi
    if [ "$pc_hit" -eq 0 ] && [ "$pc_broke" -eq 0 ]; then
      pc_missed="${pc_missed}
    MISSED: $probe_line"
    fi
  done < "$PROBE_LEAK"
  if [ "$pc_broke" -eq 1 ]; then
    record FAIL "pre-commit scan positive control — hooks/secret-scan.sh could not run (exit >1); the commit-blocking scan is unfalsifiable"
  elif [ "$pc_n" -eq 0 ]; then
    record FAIL "pre-commit scan positive control — no usable probe lines"
  elif [ -n "$pc_missed" ]; then
    printf 'pre-commit scan is BLIND (on %s, secret-scan.sh both rule sets):%s\n' "$(uname -s)" "$pc_missed"
    record FAIL "pre-commit scan positive control — the commit-blocking pattern misses values it must catch"
  else
    record PASS "pre-commit scan positive control ($pc_n planted caught via secret-scan.sh, credential + infra)"
  fi
fi

# 8c. the INSTALLED hook is the TRACKED hook. setup.sh COPIES hooks/pre-commit into
#     .git/hooks/pre-commit, so the two drift the moment the tracked one is edited
#     and nothing re-runs setup.sh. On the machine that wrote this check the copy
#     was frozen at Jul 30: every later edit to the tracked source — including the
#     credential rules added the same hour — changed nothing at commit time, and a
#     planted ghp_ token committed cleanly. Checks 8a/8b both passed throughout,
#     because both test the tracked PATTERN and neither tests the installed FILE.
#     Local-only: a CI checkout has no .git/hooks/pre-commit and never commits.
if [ -f .git/hooks/pre-commit ]; then
  if cmp -s .git/hooks/pre-commit hooks/pre-commit; then
    record PASS "installed pre-commit matches tracked source"
  else
    # The label opens with the same words as the PASS above, deliberately. A row whose
    # two outcomes read differently cannot be asserted by name, and verify-selftest.sh
    # asserts every row by name.
    record FAIL "installed pre-commit matches tracked source — it does NOT; your commits are not running the tracked scan; fix: cp hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit"
  fi
elif [ -d .git ]; then
  record WARN "no .git/hooks/pre-commit installed — commits are unscanned locally; run setup.sh"
fi

# 9. dangling references — no tracked .md may cite a doc, skill, agent, hook or
#    script that is not on disk.
#
#    THIS CHECK ALREADY EXISTED, AS PROSE. It is step 4 of SHIP.md, written out
#    there as a shell command with three hard-won details in it, and it runs only
#    when a human runs a release. SHIP.md says so itself: "Step 4 below is the
#    sweep that should have caught it and did not run, because nobody released in
#    between." A gate that fires only when someone remembers to fire it is the
#    same decoration this file exists to replace, so it moves here and runs on
#    every push. SHIP.md step 4 now points at this row rather than restating it.
#
#    The three details are kept verbatim from SHIP.md, each because the naive
#    version fails:
#      - Only backtick-quoted paths count. Bare text produces a flood of
#        substring hits: the tail of "ingest-docs/SKILL.md" looks like a docs
#        path, and the tail of "~/.agents/skills/x" looks like an agents path.
#      - Driven off `git ls-files`, not a directory walk. Only tracked files can
#        break a release for a stranger, and a walk drags in gitignored
#        third-party folders nobody edits here.
#      - The gone-on-purpose marker is filtered PER LINE, before extraction.
#        `grep -o` prints the match and throws its line away, so a filter applied
#        afterwards can never see the marker.
#
#    Prose that names a deleted file on purpose carries <!-- gone-on-purpose -->
#    on that line. SHIP.md's own header needs it six times, and its rule holds:
#    history and rationale only, never to silence a reference something follows.
#
#    CI-safe on a fresh clone: every path it can match is tracked, and the two
#    gitignored-by-design paths (`memory/MEMORY.md`, `memory/facts/`) are outside
#    the pattern's directory list deliberately, not by luck.
#    COVERAGE, STATED HONESTLY. This reads tracked `.md` files only, and matches
#    only backtick-quoted paths under those five directories carrying one of the
#    extensions below. It does NOT see: references inside .sh/.js/.json, bare
#    (unbackticked) prose paths, extensionless files such as `hooks/pre-commit`,
#    or directories such as `docs/raw/`. The extension requirement is what keeps
#    runtime output directories out, so widening it is not free. The row's label
#    says "in tracked .md" for that reason — a gate whose name overstates its
#    reach is the same lie in a different place.
#
#    FAILS CLOSED ON AN EMPTY RESULT. The obvious version records PASS whenever
#    it printed nothing, which is also what it does when `git ls-files` returns
#    nothing, when the grep pipeline breaks, or when someone edits the pattern
#    into one that cannot match. That is the exact shape of the leak scan that
#    went blind on macOS, and rows 8a/8b already count their probe lines for this
#    reason. So both counts are asserted: zero source files or zero extracted
#    references is a FAIL, never a clean sweep. The floor is 1 rather than
#    today's 20, because 20 is a fact about this commit and a floor that tracks
#    the corpus would have to be updated by hand on every edit.
#    TWO SOURCE CLASSES, TWO EXTRACTION RULES, BECAUSE THE TWO FILE TYPES CITE
#    PATHS DIFFERENTLY. Prose puts a path in backticks; shell puts it in quotes,
#    in a pathspec, or bare after a variable. Requiring backticks everywhere
#    would read .sh files and find nothing in them, which is worse than not
#    reading them, because the row's label would then claim a reach it lacks.
#
#    Reading .sh and .js is not hypothetical value. `skills/health/SKILL.md` was <!-- gone-on-purpose: naming the deleted skill is the point of this note -->
#    deleted by the rebuild and stayed referenced in verify.sh's own SCAN_EXCLUDE
#    pathspec, in hooks/pre-commit's mirror of that list, and in
#    hooks/secret-scan.sh's caller list. All three are shell. The .md-only version
#    of this row could not see any of them, and three green CI runs went past.
dangling=""
dang_src=0
dang_refs=0
scan_refs() {
  # $1 = source file. Prose: backtick-quoted only, because bare matching in prose
  # produces a flood of substring hits (the tail of "ingest-docs/SKILL.md" looks
  # like a docs path). Shell: bare, because nothing is backticked there.
  case "$1" in
    *.md)
      grep -v 'gone-on-purpose' "$1" \
        | grep -oE '`(docs|rules|skills|hooks|agents)/[A-Za-z0-9._/-]+\.(md|sh|js|py|mjs|json|txt|yml|yaml)`' \
        | tr -d '`' ;;
    *)
      # Two boundaries here that the prose branch gets free from its backticks.
      #
      # LEADING: the class excludes [A-Za-z0-9._-] but ALLOWS `/`, because the
      # commonest real reference in shell is "$ROOT/hooks/secret-scan.sh" and a
      # boundary that rejected `/` would miss every one of them. Rejecting `-`
      # and `.` is what matters: without it the substring "ingest-docs/SKILL.md"
      # yields `docs/SKILL.md`, and "~/.agents/skills/x" yields `agents/skills/x`. <!-- gone-on-purpose: an illustration of a false positive, not a reference -->
      # Both were produced by the first version of this branch, out of the very
      # comment two screens up that warns about substring hits.
      #
      # TRAILING: the extension must END the token. Without the terminator,
      # `hooks/tests/infra-scan-probe.sha256` matches as `...probe.sh`, because
      # `sh` is a prefix of `sha256` — a file that exists, reported as one that
      # does not.
      #
      # An extension is required in this branch and the prose branch requires one
      # too. Dropping it was tried on 2026-08-22: it caught nothing real and
      # added three runtime output directories from an archived skill.
      grep -v 'gone-on-purpose' "$1" \
        | grep -oE '(^|[^A-Za-z0-9._-])(docs|rules|skills|hooks|agents)/[A-Za-z0-9._/-]+\.(md|sh|js|py|mjs|json|txt|yml|yaml)([^A-Za-z0-9]|$)' \
        | sed -E 's|^[^A-Za-z]+||; s|[^A-Za-z0-9]$||' ;;
  esac
}
while IFS= read -r src; do
  [ -z "$src" ] && continue
  dang_src=$((dang_src + 1))
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    dang_refs=$((dang_refs + 1))
    # A trailing separator survives the match when a path ends a sentence.
    p="${p%.}"; p="${p%,}"; p="${p%:}"
    [ -e "$p" ] || [ -e "$(dirname "$src")/$p" ] || dangling="${dangling}
    DANGLING: $p  (in $src)"
  done < <(scan_refs "$src" | sort -u)
done < <(git ls-files -- '*.md' '*.sh' '*.js')

if [ "$dang_src" -eq 0 ]; then
  record FAIL "dangling references — git ls-files listed NO tracked sources to read; the sweep examined nothing, which is empty rather than clean"
elif [ "$dang_refs" -eq 0 ]; then
  record FAIL "dangling references — no path was extracted from $dang_src tracked sources; the extractor is broken, not the corpus empty"
elif [ -n "$dangling" ]; then
  printf 'tracked files cite paths that are not on disk:%s\n' "$dangling"
  record FAIL "dangling references — a tracked file names a doc/skill/hook/script that does not exist (see above)"
else
  record PASS "dangling references ($dang_refs cited in $dang_src tracked .md/.sh/.js, all resolve)"
fi

# 10. README skills inventory — the table in README.md lists exactly the skills
#     that exist, and the sentence above it spells the same number.
#
#     THIS IS SHIP.md STEP 6, AND ITS GAP. Step 6 says "update the skill count in
#     README.md from the live directory" and hands over `ls -d skills/*/ | wc -l`.
#     Two things are wrong with leaving it there. It runs only at release, like
#     step 4 did. And a count alone is the weakest possible assertion: swap one
#     skill for another and the number is still right while both rows are wrong.
#     So the NAMES are compared, in both directions, and the number falls out of
#     that rather than being tracked separately.
#
#     NO MANIFEST, AND NO THIRD COPY. Both sides are extracted at run time — the
#     table out of README.md, the truth out of `git ls-files`. Nothing here
#     records what the answer is supposed to be, so there is no third place to
#     drift and no line number to go stale.
#
#     COUNTED FROM TRACKED SKILL.md, NOT FROM THE DIRECTORY. `ls -d skills/*/`
#     also counts the `npx skills` symlinks that .gitignore lists (styleseed,
#     avoid-ai-writing, archify, resolving-merge-conflicts): they are local
#     install state, present here and absent in a fresh CI clone, so a directory
#     count makes this row disagree between the two for reasons that are not a
#     defect. What ships is what is tracked.
readme_skills="$(grep -oE '^\| `/[a-z0-9-]+`' README.md 2>/dev/null | sed 's/.*`\/\(.*\)`/\1/' | sort -u)"
real_skills="$(git ls-files 'skills/*/SKILL.md' | awk -F/ '{print $2}' | sort -u)"
n_real="$(printf '%s\n' "$real_skills" | grep -c . )"

if [ -z "$real_skills" ]; then
  record FAIL "README skills inventory — git ls-files found NO tracked skills/*/SKILL.md; that is an empty result, not a matching one"
elif [ -z "$readme_skills" ]; then
  record FAIL "README skills inventory — no skill rows extracted from README.md; the table moved or the extractor is broken"
elif [ "$readme_skills" != "$real_skills" ]; then
  echo "README.md's skills table and the tracked skills disagree:"
  diff <(printf '%s\n' "$readme_skills") <(printf '%s\n' "$real_skills") \
    | sed -e 's/^</    ONLY IN README: /' -e 's/^>/    ONLY ON DISK: /' | grep -E 'ONLY'
  record FAIL "README skills inventory — the table names a skill that does not exist, or omits one that does (see above)"
else
  # The spelled number in the sentence introducing the table. Written as a word
  # ("There are six."), so it is compared as a word; a digit form is accepted too
  # rather than demanding the prose change to suit the gate.
  words="zero one two three four five six seven eight nine ten eleven twelve"
  want="$(printf '%s' "$words" | awk -v n="$n_real" '{print $(n+1)}')"
  if [ -z "$want" ]; then
    record WARN "README skills inventory — $n_real skills match the table, but the count is past this row's number-word list, so the sentence went unchecked"
  elif grep -qE "There are ($want|$n_real)\b" README.md; then
    record PASS "README skills inventory ($n_real skills, table and count agree)"
  else
    echo "README.md says something other than \"There are $want\" ($n_real tracked skills):"
    grep -nE 'There are [a-z0-9]+' README.md | sed 's/^/    /'
    record FAIL "README skills inventory — the table is right and the sentence above it names a different number (see above)"
  fi
fi

printf '\n%-6s  %s\n' RESULT CHECK
for r in "${results[@]}"; do printf '%-6s  %s\n' "${r%%|*}" "${r#*|}"; done
exit "$fail"
