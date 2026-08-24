#!/usr/bin/env bash
# One command that decides whether this setup is sound. CI runs it on Linux and
# macOS; `bash ~/.claude/verify.sh` runs it here. Every row prints PASS or FAIL,
# and the exit code is the verdict.
#
# Rewritten from a blank page 2026-08-22 (machinery rebuild). Its referee is
# verify-selftest.sh, which sabotages the thing each row guards and requires the
# row to go red. A row nobody has watched fail is decoration, and this file once
# reported 14 PASS while 8 of its rows could not fail at all.
#
# THREE RULES EVERY ROW OBEYS.
#
#   1. FAIL CLOSED. A check that could not run must never read as a check that
#      found nothing. Every row that shells out inspects the exit status and
#      treats "the tool broke" as its own failure. Both halves of this repo's
#      worst incidents were this shape: a leak scan blind on one platform, and a
#      diff that errored into an empty variable.
#
#   2. COUNT WHAT YOU SCANNED. An empty result and a clean result look identical
#      unless the row says how much it examined. Rows that scan a corpus print
#      their counts and go red on zero.
#
#   3. THE LABEL IS THE CONTRACT. verify-selftest.sh matches rows by the text
#      below, so a FAIL label opens with the same words as its PASS. Renaming a
#      row without renaming its sabotage silently unhooks the proof.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || { echo "cannot cd to $ROOT"; exit 1; }

fail=0
rows=()
pass() { rows+=("PASS|$1"); }
red()  { rows+=("FAIL|$1"); fail=1; }
warn() { rows+=("WARN|$1"); }   # never sets fail; CI asserts which rows may use it

# ── the slow rows start now, together ───────────────────────────────────────
# Six of the rows below shell out to something that takes seconds and reads
# the tree without writing to it: the node suites, each shell suite, shellcheck,
# the registry check, and the two tracked-content scans. None uses another's
# result, so they run as background jobs from here and each row below WAITS for
# its own job where it used to run it. Measured 2026-08-22 before this change:
# 44s wall at 37% CPU, 34s of it the suites alone, run one after another; and
# verify-selftest.sh runs this whole file once per sabotage.
#
# The rows themselves are unchanged: same labels, same order in the table, same
# fail-closed reading of exit status. Each job writes its exit status to its own
# file under $JOBS; a status file that never appears reads as "the job could not
# run", which is a failure, not a pass. Logs keep their /tmp names because the
# labels cite them.
#
# What does NOT run here: the probe loops and the reference sweep, which are
# shell loops in this process and cheap; and anything that mutates the tree,
# which is nothing in this file. The one known collision is with
# verify-selftest.sh, which sabotages files while a verify.sh run reads them,
# and that pair stays serial, as it always has.
JOBS="$(mktemp -d)"
trap 'rm -rf "$JOBS"' EXIT
job() {  # $1 name, rest: the command. Status lands in $JOBS/<name>.rc
  local name="$1"; shift
  ( "$@"; echo "$?" > "$JOBS/$name.rc" ) &
}
# $1 name -> its exit status, or 99 when the job never reported one. A file that
# is absent, EMPTY, or holds anything but digits all read as 99: a writer killed
# mid-write leaves a zero-byte .rc, and an empty string fails every numeric test
# below, which in the tracked-content row falls through to its PASS branch. That
# is rule 1's exact shape, so the value is validated here rather than at each
# reader.
job_rc() {
  local v=""
  [ -f "$JOBS/$1.rc" ] && v="$(cat "$JOBS/$1.rc" 2>/dev/null)"
  case "$v" in
    ''|*[!0-9]*) echo 99 ;;
    *) echo "$v" ;;
  esac
}

job node bash -c 'node --test "hooks/tests/*.test.js" >/tmp/verify-node.log 2>&1'

shopt -s nullglob
sh_suites=(hooks/tests/*.test.sh)
shopt -u nullglob
for suite in "${sh_suites[@]}"; do
  # One log per suite, concatenated into the cited /tmp/verify-sh.log once all
  # have returned, so interleaved output never hides which suite said what.
  job "sh-$(basename "$suite")" bash -c 'bash "$1" >"$2" 2>&1' _ "$suite" "$JOBS/$(basename "$suite").log"
done

if command -v shellcheck >/dev/null 2>&1; then
  job shellcheck bash -c 'git ls-files "*.sh" | xargs shellcheck -S warning >/tmp/verify-shellcheck.log 2>&1'
fi

job external bash -c '"$1" >/tmp/verify-external.log 2>&1' _ "$ROOT/hooks/external-check.sh"

# The duplicate-work gate, pointed at this repo's own uncommitted work. HEAD is
# resolved here rather than inside the job so a row cannot silently scan a
# different tree from the one the other rows read.
DUPE_HEAD="$(git rev-parse HEAD 2>/dev/null || echo '')"
if [ -n "$DUPE_HEAD" ]; then
  job dupe bash -c '"$1" --since "$2" >/tmp/verify-dupe.log 2>&1' _ "$ROOT/hooks/dupe-check.sh" "$DUPE_HEAD"
fi

# Files excluded from the content scan, and ONLY files that legitimately
# contain the shapes it hunts: the two pinned fixtures, the two rule files (a
# file of leak regexes matches its own rules on every line), the deny-list
# template, this file, and the hook. Mirrors hooks/pre-commit's list; change
# one, change the other.
SCAN_EXCLUDE=(
  ':!hooks/pre-commit' ':!verify.sh' ':!.no-yolo-deny.example.txt'
  ':!hooks/secret-patterns.txt' ':!hooks/infra-patterns.txt'
  ':!hooks/tests/infra-scan-probe.txt' ':!hooks/tests/infra-scan-clean.txt'
)
# A NUL-safe read loop, never xargs: xargs exits 123 when its child exits
# 1..125, so "found nothing" (grep 1) and "the scanner blew up" (grep 2) both
# arrive as 123, which is a fail-open wearing a disguise.
scan_files=()
while IFS= read -r -d '' f; do scan_files+=("$f"); done < <(git ls-files -z -- . "${SCAN_EXCLUDE[@]}")
if [ "${#scan_files[@]}" -gt 0 ]; then
  job scan-infra bash -c '"$1" --infra --files "${@:2}" >/tmp/verify-scan.log 2>&1' _ "$ROOT/hooks/secret-scan.sh" "${scan_files[@]}"
  job scan-cred  bash -c '"$1" --files "${@:2}" >/tmp/verify-scan-cred.log 2>&1' _ "$ROOT/hooks/secret-scan.sh" "${scan_files[@]}"
fi

# ── the hook suites ─────────────────────────────────────────────────────────
# Two globs, because check 1's is *.test.js only. When the shell suites were
# added, nothing ran them for weeks: the JS runner silently matched none.
wait
if [ "$(job_rc node)" -eq 0 ]; then
  pass "hook unit tests"
else
  red "hook unit tests (see /tmp/verify-node.log)"
fi

sh_ok=1
: > /tmp/verify-sh.log
for suite in "${sh_suites[@]}"; do
  cat "$JOBS/$(basename "$suite").log" >>/tmp/verify-sh.log 2>/dev/null
  # The log goes to stdout beside the FAILED line, because a CI runner shows only
  # what the run printed and /tmp/verify-sh.log stays on the machine that failed.
  [ "$(job_rc "sh-$(basename "$suite")")" -eq 0 ] || {
    echo "FAILED: $suite"
    sed 's/^/    /' "$JOBS/$(basename "$suite").log" 2>/dev/null
    sh_ok=0
  }
done
if [ "${#sh_suites[@]}" -eq 0 ]; then
  red "hook shell tests — none found, which is an empty result and not a clean one"
elif [ "$sh_ok" = 1 ]; then
  pass "hook shell tests (${#sh_suites[@]})"
else
  red "hook shell tests (see /tmp/verify-sh.log)"
fi

# ── shell and config syntax ─────────────────────────────────────────────────
syntax_ok=1
while IFS= read -r f; do
  [ -z "$f" ] && continue
  bash -n "$f" || syntax_ok=0
done < <(git ls-files '*.sh')
[ "$syntax_ok" = 1 ] && pass "shell syntax (bash -n)" || red "shell syntax (bash -n)"

if python3 -c "import json;json.load(open('settings.example.json'))" 2>/dev/null; then
  pass "settings.example.json parses"
else
  red "settings.example.json parses"
fi

# A tilde inside double quotes never expands, and hook commands are the only
# strings in that file a shell executes. Other quoted ~ values (e.g.
# additionalDirectories) are read by Claude Code's own loader, not a shell.
if grep -qE '"~/\.claude/hooks/' settings.example.json 2>/dev/null; then
  red 'settings.example.json has a quoted "~/.claude/hooks/ path — use $HOME, which does expand'
else
  pass 'no quoted ~ in settings.example.json hook commands'
fi

# Every hook the template wires must exist in THIS checkout. A missing one gives
# every fresh install a failing hook on every turn; that shipped once.
hooks_ok=1
for p in $(grep -oE '(\$HOME|~)/\.claude/hooks/[a-zA-Z0-9._-]+' settings.example.json | sort -u); do
  rel="hooks/${p##*/hooks/}"
  [ -f "$ROOT/$rel" ] || { echo "missing hook: $rel"; hooks_ok=0; }
done
[ "$hooks_ok" = 1 ] && pass "hook paths exist" || red "hook paths exist"

# Stock macOS ships bash 3.2 and the documented install command is
# `bash setup.sh`, so one bash-4-only construct hard-blocks every
# un-provisioned Mac. Guards the class, not one member: associative arrays,
# the line-reading builtins, and case-changing expansions.
if ! grep -qE 'declare -A|mapfile|readarray|\$\{[a-zA-Z_]+(\^\^|,,)\}' setup.sh \
   && /bin/bash -n setup.sh 2>/dev/null; then
  pass "setup.sh bash-3.2 clean"
else
  red "setup.sh bash-3.2 clean — a bash-4-only construct or a syntax error (stock Mac bash is 3.2)"
fi

# Blocking at warning severity. This was warn-only for months, so it ran on
# every push, found real things, and could not fail the build. Nobody read it.
# Style/info notes stay out: SC2015, SC2016 and SC2013 are deliberate here.
if command -v shellcheck >/dev/null 2>&1; then
  if [ "$(job_rc shellcheck)" -eq 0 ]; then
    pass "shellcheck"
  else
    red "shellcheck findings (see /tmp/verify-shellcheck.log)"
  fi
else
  warn "shellcheck not installed — skipped (CI has it; brew install shellcheck, or apt install shellcheck)"
fi

# ── duplicate work ──────────────────────────────────────────────────────────
# hooks/dupe-check.sh over everything this tree has changed since HEAD, tracked
# and untracked alike: the gate skills/build/stages/5-build.md runs during a
# build, turned on the repo that ships it.
#
# TWO PASSES, TWO FATES, and the row reads them apart. Copied blocks need jscpd;
# repeated names need git alone. So exit 3 never means "jscpd is missing" — the
# script prints "jscpd: did not run" and finishes the name pass, which is a real
# result and passes as one, with the label saying which half ran. Exit 3 is the
# invocation failing (a ref that is no commit, no repository), and that is red.
#
# ZERO FILES IS A REAL ANSWER HERE, not the empty result rule 2 hunts. A fresh
# checkout has changed nothing since HEAD, so CI's count is 0 every time and the
# row prints that count rather than claiming a scan it never did.
#
# The count is computed here from the same two git commands dupe-check.sh's
# collect_since uses. It is a second reading of one fact, kept because a row
# that cannot say how much it examined is the shape rule 2 exists to stop.
if [ -z "$DUPE_HEAD" ]; then
  red "dupe-check self-scan — git rev-parse HEAD failed, so nothing was scanned"
else
  dupe_n="$( { git diff --name-only --diff-filter=ACMRT "$DUPE_HEAD" --; \
               git ls-files --others --exclude-standard; } 2>/dev/null | grep -c . )"
  dupe_rc="$(job_rc dupe)"
  if [ "$dupe_rc" -eq 0 ]; then
    if grep -q 'jscpd: did not run' /tmp/verify-dupe.log 2>/dev/null; then
      pass "dupe-check self-scan ($dupe_n files changed since HEAD, repeated names only — jscpd absent)"
    else
      pass "dupe-check self-scan ($dupe_n files changed since HEAD, no copied block or repeated name)"
    fi
  elif [ "$dupe_rc" -eq 1 ]; then
    sed 's/^/    /' /tmp/verify-dupe.log 2>/dev/null
    red "dupe-check self-scan — a copied block or a repeated name in the uncommitted work (see above; the gate is hooks/dupe-check.sh)"
  else
    sed -n '1,10p' /tmp/verify-dupe.log 2>/dev/null | sed 's/^/    /'
    red "dupe-check self-scan COULD NOT RUN (exit $dupe_rc) — not a clean result (see /tmp/verify-dupe.log)"
  fi
fi

# ── vale ────────────────────────────────────────────────────────────────────
# The second prose check, beside the hand-kept regexes in hooks/slop-block.sh.
# The hook only ever sees a file an agent just edited; this reaches every
# tracked .md on every run. Rules live in styles/NoYolo/, .vale.ini says why.
#
# RUN INLINE, NOT AS A JOB. Measured 2026-08-22: 0.14s over 34 files, against
# the seconds each backgrounded row costs. Nothing to overlap.
#
# THE EXIT STATUS CANNOT REPORT FINDINGS, so this row does not ask it to.
# Measured 2026-08-22, all three on vale 3.18.0: a file with five warnings
# exits 0, a clean file exits 0, and a file that does not exist exits 0 with no
# output at all. Only a genuine breakdown (a config it cannot read) reaches 2.
# So findings are read off the OUTPUT, the status is read only for "could not
# run", and the file count is what separates a clean sweep from a sweep of
# nothing — which is rule 2, and here it is load-bearing rather than ceremonial.
#
# The list is built with -z into an array, never $(git ls-files '*.md'): a path
# containing a space would split into two nonexistent paths, and vale would
# then exit 0 in silence on both, reporting this row green for a scan that
# examined neither.
md_files=()
while IFS= read -r -d '' mdf; do md_files+=("$mdf"); done < <(git ls-files -z -- '*.md')

if command -v vale >/dev/null 2>&1; then
  if [ "${#md_files[@]}" -eq 0 ]; then
    red "vale prose lint — no tracked .md files found, which is an empty result and not a clean one"
  else
    vale_out="$(vale --config "$ROOT/.vale.ini" --no-wrap --output line "${md_files[@]}" 2>&1)"
    vale_rc=$?
    if [ "$vale_rc" -ge 2 ]; then
      printf '%s\n' "$vale_out" | sed 's/^/    /'
      red "vale prose lint — vale could not run, so nothing was checked (see above)"
    elif [ -n "$vale_out" ]; then
      printf '%s\n' "$vale_out" | sed 's/^/    /'
      red "vale prose lint — findings in tracked .md (see above; rules in styles/NoYolo, standard in docs/PROSE.md)"
    else
      pass "vale prose lint (${#md_files[@]} tracked .md files, no findings)"
    fi
  fi
else
  warn "vale prose lint not installed — skipped (brew install vale)"
fi

# ── external names ──────────────────────────────────────────────────────────
# On 2026-08-21 this repo published seven install references and six were wrong:
# four GitHub repos under an owner who owns none of them, one npm package under
# a name never published, and one that has never existed anywhere, with a build
# stage written to run it. Every other row was green throughout, because nothing
# had ever asked whether a name resolves.
#
# Exit 3 means COULD NOT REACH the registry, and that is a failure too: an unrun
# check and a clean check look identical. EXTERNAL_CHECK_OFFLINE downgrades it,
# opt-in so it cannot become the silent default in CI.
case "$(job_rc external)" in
  0) pass "external references resolve" ;;
  1) red "external references — a tracked install command names something that does not exist or points elsewhere (see /tmp/verify-external.log)" ;;
  *)
    if [ -n "${EXTERNAL_CHECK_OFFLINE:-}" ]; then
      warn "external references — could not reach the registry, downgraded by EXTERNAL_CHECK_OFFLINE"
    else
      red "external references COULD NOT RUN — not a clean result; set EXTERNAL_CHECK_OFFLINE=1 if you are deliberately offline (see /tmp/verify-external.log)"
    fi ;;
esac

# ── leak scanning ───────────────────────────────────────────────────────────
# The rule files' only compensating control is the scanner, which lints
# whichever file it loads on every run and refuses to scan a gutted one. These
# two rows are where that refusal surfaces.
"$ROOT/hooks/secret-scan.sh" --check >/tmp/verify-secretlint.log 2>&1 \
  && pass "secret pattern file healthy" \
  || red "secret pattern file healthy — missing, gutted or invalid (see /tmp/verify-secretlint.log)"

"$ROOT/hooks/secret-scan.sh" --infra --check >/tmp/verify-infralint.log 2>&1 \
  && pass "infra pattern file healthy" \
  || red "infra pattern file healthy — missing, gutted or invalid (see /tmp/verify-infralint.log)"

# One line through one rule set. Returns the scanner's own status verbatim:
# 0 caught, 1 not caught, anything else the scan COULD NOT RUN.
scan_line() {
  if [ -n "$1" ]; then printf '%s\n' "$2" | "$ROOT/hooks/secret-scan.sh" "$1" >/dev/null 2>&1
  else printf '%s\n' "$2" | "$ROOT/hooks/secret-scan.sh" >/dev/null 2>&1; fi
}

# A line counts as caught if EITHER rule set sees it: the fixture holds both
# infra values and credential values, and testing one set alone would declare
# the other's planted lines missed.
scan_either() {  # $1 line -> 0 caught, 1 missed, 2 the scanner broke
  scan_line --infra "$1"; case "$?" in 0) return 0 ;; 1) ;; *) return 2 ;; esac
  scan_line '' "$1";      case "$?" in 0) return 0 ;; 1) return 1 ;; *) return 2 ;; esac
}

PROBE_LEAK="hooks/tests/infra-scan-probe.txt"
PROBE_CLEAN="hooks/tests/infra-scan-clean.txt"
PROBE_SUMS="hooks/tests/infra-scan-probe.sha256"

sha_of() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  else sha256sum "$1" | awk '{print $1}'; fi
}

# POSITIVE AND NEGATIVE CONTROL. The content scan below passes when it finds
# nothing, and so does a scan that has gone blind: delete a metacharacter, or
# run it on a platform whose regex engine reads it differently, and it reports
# "no findings" forever. That happened — a word-boundary escape matched NOTHING
# under git grep on macOS, so the scan was green on the machine doing the
# committing. Nothing here could tell "clean" from "blind" until these ran.
#
# The planted values live in a fixture rather than inline, because inline values
# are blocked by the very hook this tests. Being excluded from the scans makes
# that fixture the one place a real leak could hide, so it is sha256-pinned.
probe_ready=1
for f in "$PROBE_LEAK" "$PROBE_CLEAN" "$PROBE_SUMS"; do
  [ -f "$f" ] || { echo "missing scan-probe fixture: $f"; probe_ready=0; }
done

if [ "$probe_ready" = 0 ]; then
  red "infra scan positive control — fixtures missing, so the control is unfalsifiable"
else
  pinned_ok=1
  for f in "$PROBE_LEAK" "$PROBE_CLEAN"; do
    want=$(awk -v want="$f" '$2==want {print $1}' "$PROBE_SUMS")
    got=$(sha_of "$f")
    if [ -z "$want" ]; then echo "no pinned hash for $f in $PROBE_SUMS"; pinned_ok=0
    elif [ "$want" != "$got" ]; then
      echo "scan-probe fixture CHANGED: $f"
      echo "  pinned $want"
      echo "  actual $got"
      echo "  These files are excluded from the leak scan, so their contents are pinned."
      echo "  If the edit is deliberate, update $PROBE_SUMS."
      pinned_ok=0
    fi
  done

  if [ "$pinned_ok" = 0 ]; then
    red "infra scan probe fixtures changed — pinned hash mismatch (see above)"
  else
    missed=""; cried=""; broke=0; n_leak=0; n_clean=0
    while IFS= read -r line; do
      case "$line" in ''|'#'*) continue ;; esac
      line=${line//@@/}            # strip the escape marker; see the fixture header
      n_leak=$((n_leak + 1))
      scan_either "$line"
      case "$?" in 0) ;; 1) missed="${missed}
    MISSED: $line" ;; *) broke=1 ;; esac
    done < "$PROBE_LEAK"

    while IFS= read -r line; do
      case "$line" in ''|'#'*) continue ;; esac
      line=${line//@@/}
      n_clean=$((n_clean + 1))
      scan_either "$line"
      case "$?" in 0) cried="${cried}
    FALSE POSITIVE: $line" ;; 1) ;; *) broke=1 ;; esac
    done < "$PROBE_CLEAN"

    if [ "$broke" = 1 ]; then
      red "infra scan positive control — the scanner could not run; the control is unfalsifiable, not clean"
    elif [ "$n_leak" -eq 0 ] || [ "$n_clean" -eq 0 ]; then
      red "infra scan positive control — fixtures held no usable lines ($n_leak leak, $n_clean clean)"
    elif [ -n "$missed" ]; then
      printf 'infra scan is BLIND to values it must catch (on %s):%s\n' "$(uname -s)" "$missed"
      red "infra scan positive control — the pattern matches nothing it should"
    elif [ -n "$cried" ]; then
      printf 'infra scan flags values it must not (on %s):%s\n' "$(uname -s)" "$cried"
      red "infra scan negative control — the pattern cries wolf"
    else
      pass "infra scan positive control ($n_leak planted caught, $n_clean clean ignored)"
    fi
  fi
fi

# THE TRACKED CONTENT ITSELF. The file list and the two scans were launched at
# the top of this file; this row reads their statuses.
#
# Each half's status is captured explicitly. This row used to be
# `if git grep ...; then FAIL; else PASS; fi`, which routed exit 1 (searched,
# found nothing) and exit >=2 (the scan ERRORED) into the same PASS branch: the
# scan breaking looked exactly like the repo being clean.
if [ "${#scan_files[@]}" -eq 0 ]; then
  red "tracked-content scan — git ls-files returned NO files; the result is empty, not clean"
else
  infra_rc="$(job_rc scan-infra)"
  cred_rc="$(job_rc scan-cred)"
  cat /tmp/verify-scan-cred.log >>/tmp/verify-scan.log 2>/dev/null
  if [ "$infra_rc" -ge 2 ] || [ "$cred_rc" -ge 2 ]; then
    red "tracked-content scan COULD NOT RUN (infra $infra_rc, credential $cred_rc) — see /tmp/verify-scan.log"
  elif [ "$infra_rc" -eq 0 ]; then
    red "tracked-content scan — a private/infra value is in a tracked file (see /tmp/verify-scan.log)"
  elif [ "$cred_rc" -eq 0 ]; then
    red "tracked-content scan — a credential is in a tracked file (see /tmp/verify-scan.log)"
  else
    pass "tracked-content scan (${#scan_files[@]} files)"
  fi
fi

# THE COMMIT-BLOCKING PATH gets the same control, invoked the way the hook
# invokes it. This is not a second engine against one fixture; it is a second
# CALLER of one engine, and a caller can still be wired up wrong.
if [ -f hooks/pre-commit ] && [ -f "$PROBE_LEAK" ]; then
  pc_missed=""; pc_broke=0; pc_n=0
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    line=${line//@@/}
    pc_n=$((pc_n + 1))
    scan_either "$line"
    case "$?" in 0) ;; 1) pc_missed="${pc_missed}
    MISSED: $line" ;; *) pc_broke=1 ;; esac
  done < "$PROBE_LEAK"
  if [ "$pc_broke" = 1 ]; then
    red "pre-commit scan positive control — the scanner could not run; the commit-blocking scan is unfalsifiable"
  elif [ "$pc_n" -eq 0 ]; then
    red "pre-commit scan positive control — no usable probe lines"
  elif [ -n "$pc_missed" ]; then
    printf 'the commit-blocking scan is BLIND (on %s):%s\n' "$(uname -s)" "$pc_missed"
    red "pre-commit scan positive control — the commit-blocking pattern misses values it must catch"
  else
    pass "pre-commit scan positive control ($pc_n planted caught, credential + infra)"
  fi
fi

# THE INSTALLED HOOK IS THE TRACKED HOOK. setup.sh COPIES hooks/pre-commit into
# .git/hooks, so the two drift the moment the tracked one is edited and nothing
# re-runs setup.sh. On the machine that first needed this row the copy was
# frozen for weeks: every later edit changed nothing at commit time, and a
# planted token committed cleanly while the pattern rows stayed green, because
# they test the tracked PATTERN and never the installed FILE.
# Local only: a CI checkout has no installed hook and never commits.
#
# THE PATH IS ASKED FOR, NOT SPELLED. This tested `.git/hooks/pre-commit`
# literally until 2026-08-24, and inside a git WORKTREE `.git` is a file holding
# a gitdir pointer, so `-f` failed and the `-d .git` fallback failed too: the row
# printed NEITHER outcome and vanished from the table. A row that guards the
# commit path and can disappear without a word is worse than one that fails,
# because the table still reads as complete. `git rev-parse --git-path` returns
# the shared hooks directory from a worktree and the ordinary one elsewhere.
#
# EVERY BRANCH EMITS A ROW, including the one where git itself could not answer.
installed_hook="$(git rev-parse --git-path hooks/pre-commit 2>/dev/null)"
if [ -z "$installed_hook" ]; then
  warn "installed pre-commit matches tracked source — not checked: git could not resolve its hooks directory here (not a repository?)"
elif [ -f "$installed_hook" ]; then
  if cmp -s "$installed_hook" hooks/pre-commit; then
    pass "installed pre-commit matches tracked source"
  else
    # Opens with the same words as the PASS, deliberately: a row whose two
    # outcomes read differently cannot be asserted by name, and the self-test
    # asserts every row by name.
    red "installed pre-commit matches tracked source — it does NOT; your commits are not running the tracked scan; fix: bash setup.sh"
  fi
else
  warn "installed pre-commit matches tracked source — none installed at $installed_hook; commits are unscanned locally, run setup.sh"
fi

# THE PRE-PUSH HOOK, on the same terms as the pre-commit one above: setup.sh
# copies it, so the two drift the moment the tracked one is edited. It runs
# verify.sh and parses the workflow's own shell, which is the check that was
# missing when a broken line continuation in ci.yml passed every local gate and
# died on both runners.
installed_push="$(git rev-parse --git-path hooks/pre-push 2>/dev/null)"
if [ -z "$installed_push" ]; then
  warn "installed pre-push matches tracked source — not checked: git could not resolve its hooks directory here"
elif [ -f "$installed_push" ]; then
  if cmp -s "$installed_push" hooks/pre-push; then
    pass "installed pre-push matches tracked source"
  else
    red "installed pre-push matches tracked source — it does NOT; your pushes are not running the tracked check; fix: bash setup.sh"
  fi
else
  warn "installed pre-push matches tracked source — none installed at $installed_push; pushes are unchecked locally, run setup.sh"
fi

# ── references and counts ───────────────────────────────────────────────────
# No tracked file may name a doc, skill, hook or script that is not on disk.
#
# THIS CHECK EXISTED AS PROSE FOR MONTHS, as step 4 of SHIP.md, and ran only
# when a human ran a release. SHIP.md said so itself: it is how SHIP.md came to
# cite five deleted files with nothing noticing.
#
# TWO SOURCE CLASSES, TWO EXTRACTION RULES, because the file types cite paths
# differently. Prose backticks a path; shell puts it in quotes, in a pathspec,
# or bare after a variable. Requiring backticks everywhere would read .sh files
# and find nothing in them, which is worse than not reading them at all: the
# row's label would then claim a reach it does not have.
#
# Reading shell is not hypothetical. A deleted skills/health was still named in
# this file's own exclusion list, in the hook's mirror of it, and in the
# scanner's caller list. All three are shell, and three green CI runs went past.
scan_refs() {
  case "$1" in
    *.md)
      grep -v 'gone-on-purpose' "$1" \
        | grep -oE '`(docs|rules|skills|hooks|agents)/[A-Za-z0-9._/-]+\.(md|sh|js|py|mjs|json|txt|yml|yaml)`' \
        | tr -d '`' ;;
    *)
      # Two boundaries the prose branch gets free from its backticks. LEADING:
      # the class excludes [A-Za-z0-9._-] but ALLOWS `/`, because the commonest
      # real reference in shell is "$ROOT/hooks/x.sh" and a boundary rejecting <!-- gone-on-purpose: an illustration of the shape, not a reference -->
      # `/` would miss every one. Rejecting `-` and `.` is what matters:
      # without it "ingest-docs/SKILL.md" yields `docs/SKILL.md`, and <!-- gone-on-purpose: the false positive being described, not a reference -->
      # "~/.agents/skills/x" yields `agents/skills/x`. TRAILING: the extension
      # must END the token, or `...probe.sha256` matches as `...probe.sh` and a
      # file that exists is reported as one that does not. Both were produced by
      # the first version of this branch.
      grep -v 'gone-on-purpose' "$1" \
        | grep -oE '(^|[^A-Za-z0-9._-])(docs|rules|skills|hooks|agents)/[A-Za-z0-9._/-]+\.(md|sh|js|py|mjs|json|txt|yml|yaml)([^A-Za-z0-9]|$)' \
        | sed -E 's|^[^A-Za-z]+||; s|[^A-Za-z0-9]$||' ;;
  esac
}

dangling=""; n_src=0; n_refs=0
while IFS= read -r src; do
  [ -z "$src" ] && continue
  n_src=$((n_src + 1))
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    n_refs=$((n_refs + 1))
    p="${p%.}"; p="${p%,}"; p="${p%:}"
    [ -e "$p" ] || [ -e "$(dirname "$src")/$p" ] || dangling="${dangling}
    DANGLING: $p  (in $src)"
  done < <(scan_refs "$src" | sort -u)
done < <(git ls-files -- '*.md' '*.sh' '*.js')

# Zero sources or zero references is the extractor breaking, not the corpus
# being clean. The floor is 1 rather than today's count, because a floor that
# tracked the corpus would need updating by hand on every edit.
if [ "$n_src" -eq 0 ]; then
  red "dangling references — git ls-files listed NO tracked sources; the sweep examined nothing"
elif [ "$n_refs" -eq 0 ]; then
  red "dangling references — no path was extracted from $n_src tracked sources; the extractor is broken"
elif [ -n "$dangling" ]; then
  printf 'tracked files cite paths that are not on disk:%s\n' "$dangling"
  red "dangling references — a tracked file names a doc/skill/hook/script that does not exist (see above)"
else
  pass "dangling references ($n_refs cited in $n_src tracked .md/.sh/.js, all resolve)"
fi

# README's skills table lists exactly the skills that exist, and the sentence
# above it spells the same number. Both sides are extracted at run time, so
# nothing here records what the answer should be and there is no third copy to
# drift. NAMES are compared, not just the count: swap one row and the number is
# still right while two rows are wrong. Counted from tracked SKILL.md rather
# than `ls -d skills/*/`, which also counts the gitignored npx symlinks that
# exist here and not in a CI clone.
readme_skills="$(grep -oE '^\| `/[a-z0-9-]+`' README.md 2>/dev/null | sed 's/.*`\/\(.*\)`/\1/' | sort -u)"
real_skills="$(git ls-files 'skills/*/SKILL.md' | awk -F/ '{print $2}' | sort -u)"
n_skills="$(printf '%s\n' "$real_skills" | grep -c .)"

if [ -z "$real_skills" ]; then
  red "README skills inventory — git ls-files found NO tracked skills/*/SKILL.md; an empty result, not a matching one"
elif [ -z "$readme_skills" ]; then
  red "README skills inventory — no skill rows extracted from README.md; the table moved or the extractor is broken"
elif [ "$readme_skills" != "$real_skills" ]; then
  echo "README.md's skills table and the tracked skills disagree:"
  diff <(printf '%s\n' "$readme_skills") <(printf '%s\n' "$real_skills") \
    | sed -e 's/^</    ONLY IN README: /' -e 's/^>/    ONLY ON DISK: /' | grep -E 'ONLY'
  red "README skills inventory — the table names a skill that does not exist, or omits one that does (see above)"
else
  words="zero one two three four five six seven eight nine ten eleven twelve"
  want="$(printf '%s' "$words" | awk -v n="$n_skills" '{print $(n+1)}')"
  if [ -z "$want" ]; then
    warn "README skills inventory — $n_skills skills match the table, but the count is past this row's number-word list"
  elif grep -qE "There are ($want|$n_skills)\b" README.md; then
    pass "README skills inventory ($n_skills skills, table and count agree)"
  else
    echo "README.md says something other than \"There are $want\" ($n_skills tracked skills):"
    grep -nE 'There are [a-z0-9]+' README.md | sed 's/^/    /'
    red "README skills inventory — the table is right and the sentence above it names a different number"
  fi
fi

# The OTHER number README publishes. Its skills table has been checked since
# 2026-08-21; the outside-pieces sentence had nothing watching it, and went
# stale twice: the front page said five while INSTALL.md listed thirteen, and
# the repository description on GitHub said thirty-one skills against six for
# weeks. A count is cheap to check and expensive to leave, because it is the
# first thing a stranger reads and the last thing anyone edits.
#
# THE TABLE IS THE LIST; both sentences only quote its size. So the row
# extracts three values at run time and holds them against each other: no
# expected number is written here, and there is no third copy to drift.
#
# BOUNDED TO ONE TABLE. INSTALL.md holds a second table whose rows also open
# with a backticked name (the vetting scores), so counting `^| ` across the
# file reads 16 where the answer is 13. The count starts at the pieces header
# and stops at the first line that is not a table row.
pieces_rows="$(awk '
  /^\| Piece \| Gives \|/ {inside = 1; next}
  inside && /^\|---/       {next}
  inside && !/^\|/         {exit}
  inside && /^\| /         {n++}
  END {print n + 0}
' INSTALL.md 2>/dev/null)"
readme_word="$(grep -oE '^[A-Za-z]+ outside pieces' README.md 2>/dev/null | head -1 | awk '{print tolower($1)}')"
install_word="$(grep -oE '^[A-Za-z]+ borrowed pieces' INSTALL.md 2>/dev/null | head -1 | awk '{print tolower($1)}')"

# Rule 1 and rule 2 together: an extractor that found nothing is a FAIL, and
# the label prints all three values so a reader can see what was compared
# rather than trusting that anything was.
if [ -z "$pieces_rows" ] || [ "$pieces_rows" -eq 0 ] 2>/dev/null; then
  red "README outside-pieces count — no rows extracted from INSTALL.md's pieces table; the extractor is broken, not the count agreed"
elif [ -z "$readme_word" ] || [ -z "$install_word" ]; then
  red "README outside-pieces count — the sentence is missing from README.md ('${readme_word:-none}') or INSTALL.md ('${install_word:-none}'); one of them was reworded and this row can no longer read it"
else
  pieces_want="$(printf '%s' "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty" \
    | awk -v n="$pieces_rows" '{print $(n+1)}')"
  if [ -z "$pieces_want" ]; then
    red "README outside-pieces count — $pieces_rows rows is past this row's number-word list; extend the list rather than leaving the count unwatched"
  elif [ "$readme_word" != "$pieces_want" ] || [ "$install_word" != "$pieces_want" ]; then
    echo "the two sentences and the table disagree:"
    echo "    README.md says   $readme_word outside pieces"
    echo "    INSTALL.md says  $install_word borrowed pieces"
    echo "    the table holds  $pieces_rows rows ($pieces_want)"
    grep -nE '^[A-Za-z]+ outside pieces' README.md | sed 's/^/    README.md:/'
    grep -nE '^[A-Za-z]+ borrowed pieces' INSTALL.md | sed 's/^/    INSTALL.md:/'
    red "README outside-pieces count — a sentence names a different number from the table it summarises (see above)"
  else
    pass "README outside-pieces count ($pieces_rows in the table, both sentences say $pieces_want)"
  fi
fi

printf '\n%-6s  %s\n' RESULT CHECK
for r in "${rows[@]}"; do printf '%-6s  %s\n' "${r%%|*}" "${r#*|}"; done
exit "$fail"
