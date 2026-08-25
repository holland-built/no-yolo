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
# refs/brands/ is 74 third-party brand specifications vendored verbatim under MIT. They are
# not this repo's prose and must not be rewritten to satisfy this repo's style, so vale never
# sees them. The secret and infra scans above still cover every one of those files: skipping
# a style check on borrowed text is a judgement call, skipping a leak scan is not.
# archive/ is excluded alongside it, for the same reason and one more: its contents are
# retired. Rewriting a dead skill's prose to satisfy a live style rule changes an artefact
# nobody runs, and it would make the archived copy differ from what was actually removed,
# which is the one property an archive has to keep.
while IFS= read -r -d '' mdf; do md_files+=("$mdf"); done < <(git ls-files -z -- '*.md' ':!refs/brands/**' ':!archive/**')

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

# ── retired pieces ──────────────────────────────────────────────────────────
# The gap the row above cannot see. external-check asks whether a name resolves;
# a retired project's name resolves perfectly well, because retiring it here does
# nothing to the repository it came from. On 2026-08-25 StyleSeed was archived and
# six tracked files went on installing, counting and pointing at it, through a
# green build and a published release.
#
# Matched against an install VERB, not against every mention. The uninstall line
# in README's own Uninstall section names the same tools on purpose, and someone
# who installed a piece before it was retired still needs to be told how to remove
# it. Matched on the WHOLE identity, never a basename: archive/skills and
# mattpocock/skills share one, and retiring the first must not condemn the second.
# The same three exclusions hooks/external-check.sh makes, for the same reasons:
# archive/ is history that discusses retired tools by name, refs/ is third-party
# text quoting other projects' install lines, and hooks/tests/ holds fixtures
# whose whole job is to carry a planted install command. The external-check
# suite plants an install line for the retired piece on purpose, and this row
# flagged that fixture on its first run.
#
# Built ONCE, outside the loop, and with no process substitution anywhere in this
# row. The first draft read the file list through `< <( ... )` with these comment
# lines inside the parentheses. It parsed clean under `bash -n`, died at run time
# with "bad substitution: no closing )", left the hits variable empty, and the row
# reported PASS against a tree carrying the very thing it looks for. It took two
# selftest cases to see it. verify-selftest.sh line 164 records the same trap from
# a case statement inside $( ), which is how this repo already knew that a clean
# `bash -n` says nothing about a substitution running.
retired_sources="$(git ls-files -- '*.md' '*.sh' '*.yml' \
  | grep -v '^archive/' | grep -v '^refs/' | grep -v '^hooks/tests/')"

retired_hits=""; n_retired=0
while read -r kind ident _rest; do
  case "$kind" in ''|\#*) continue ;; esac
  [ -z "$ident" ] && continue
  n_retired=$((n_retired + 1))
  # Install verbs only. Each is a form this repo actually writes in a tracked
  # file. "skills@latest add" and "skills@latest remove" differ by the word that
  # decides whether the line acquires the piece or cleans it up.
  hits="$(printf '%s\n' "$retired_sources" \
    | xargs grep -inE "(skills@latest[[:space:]]+add|npm[[:space:]]+(install|i)[[:space:]]|brew[[:space:]]+install|uv[[:space:]]+tool[[:space:]]+install|cargo[[:space:]]+install).*$ident" 2>/dev/null)"
  if [ -n "$hits" ]; then
    retired_hits="${retired_hits}
    INSTALLS A RETIRED PIECE: ${hits}"
  fi
  # The pieces table publishes what this setup uses now. A retired row there is
  # counted by the outside-pieces row and read as current by anyone installing.
  if awk -v want="$ident" '
        /^\| Piece \| Gives \|/ {inside = 1; next}
        inside && /^\|---/       {next}
        inside && !/^\|/         {exit}
        inside && tolower($0) ~ tolower(want) {found = 1}
        END {exit !found}
      ' INSTALL.md 2>/dev/null; then
    retired_hits="${retired_hits}
    STILL IN THE PIECES TABLE: $ident  (INSTALL.md)"
  fi
done < hooks/retired.txt

# Zero entries is the file being unreadable or emptied, not a clean result.
if [ ! -r hooks/retired.txt ]; then
  red "retired pieces — hooks/retired.txt is missing or unreadable; the sweep examined nothing"
elif [ "$n_retired" -eq 0 ]; then
  red "retired pieces — no identity parsed from hooks/retired.txt; the sweep examined nothing"
elif [ -n "$retired_hits" ]; then
  printf 'a retired piece is still being installed or listed as current:%s\n' "$retired_hits"
  red "retired pieces — a tracked file installs or lists something this repo retired (see above)"
else
  pass "retired pieces ($n_retired retired, none installed or listed as current)"
fi

# ── pieces on this machine ──────────────────────────────────────────────────
# The gap BOTH rows above leave. external-check asks whether a name resolves at
# its registry; the retired row asks whether a dead name is still written into a
# tracked file. Neither has ever looked at the disk, so a piece the pieces table
# promises can be absent, and a piece this repo retired can still be sitting in
# ~/.agents/skills, and every row stays green through a published release.
#
# Both happened. On 2026-08-25 StyleSeed was retired and the machine was declared
# clean by running `ls ~/.agents/skills/styleseed`, which reported no such file.
# It proved nothing: StyleSeed installed its skills under their own names, and
# ss-resolve and ss-score were still there, still describing themselves as
# compiling and scoring against rules that by then existed only under archive/.
# SHIP.md step 3 is a person doing this check by hand at release time, and nobody
# released between the retirement and the day it was noticed by accident.
#
# TWO HALVES, AND ONLY ONE OF THEM NEEDS THIS MACHINE. Whether a manifest row is
# well formed, and whether one identity is in both manifests, are answerable
# anywhere. Only the disk probes are local. The first draft of this row wrapped
# BOTH halves in the hosted-runner escape, so a malformed manifest line reached
# CI as a WARN nobody reads. They are separated below, and the validation half
# runs everywhere, always.
#
# VERIFY_NO_LOCAL_TOOLS, and not GITHUB_ACTIONS. The escape is set by the
# workflow that knows its runner has none of these pieces, rather than inferred
# from an ambient variable: GITHUB_ACTIONS describes an execution context, not a
# bare machine, and a self-hosted runner or a pre-push that inherited it would
# silently skip the only check that needs a real disk. Unset, the probes run and
# can fail, which is the direction this file errs in everywhere else.
installed_manifest="hooks/installed.txt"
probe_roots="${INSTALLED_PROBE_ROOTS:-$ROOT/skills:$HOME/.agents/skills:${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.agents/skills}"

# THE SKILL.md AND NOT THE DIRECTORY. An interrupted `npx skills add` leaves the
# directory behind with nothing in it, and a bare -d test calls that installed.
skill_present() {  # $1 skill name -> 0 when found under a declared root
  local name="$1" root
  local IFS=:
  for root in $probe_roots; do
    [ -n "$root" ] || continue
    [ -r "$root/$name/SKILL.md" ] && return 0
  done
  return 1
}

# ROOTS ARE DECLARED, NEVER SEARCHED FOR. A recursive hunt for a name finds
# archive/styleseed/.agents/skills/ss-resolve, which is a tracked snapshot that
# is SUPPOSED to be on disk, and would report every retired piece as installed
# for ever.
artefact_present() {  # $1 -> 0 when present as a skill or as a binary
  skill_present "$1" && return 0
  command -v "$1" >/dev/null 2>&1 && return 0
  return 1
}

pieces_bad=""
n_installed=0          # rows of hooks/installed.txt that parsed
n_retired_art=0        # artefacts named across hooks/retired.txt
installed_probes=0     # disk probes actually performed

# A name that can be typed into either manifest. Anything outside this set is a
# quoting accident or a pasted table cell, and reading it as a filename is how a
# probe silently looks for something nobody named.
valid_name() { case "$1" in ''|*[!A-Za-z0-9._@/-]*) return 1 ;; *) return 0 ;; esac; }

if [ ! -r "$installed_manifest" ]; then
  red "pieces on this machine — $installed_manifest is missing or unreadable; nothing was probed"
else
  # ── validation, which runs everywhere ────────────────────────────────────
  # EXACTLY THREE FIELDS. `read` into four variables does not enforce four: a
  # short row leaves $origin empty and a long one silently buries its tail in
  # $extra. Either is a malformed policy line, and a malformed policy line that
  # reads as "could not run" is how a manifest quietly stops covering something.
  installed_rows=""
  while read -r kind value origin extra; do
    case "$kind" in ''|\#*) continue ;; esac
    if [ -z "$value" ] || [ -z "$origin" ] || [ -n "$extra" ]; then
      pieces_bad="${pieces_bad}
    MALFORMED ROW (needs exactly three fields): $kind $value $origin $extra"
      continue
    fi
    case "$kind" in
      skill|cmd|ondemand) : ;;
      *) pieces_bad="${pieces_bad}
    UNKNOWN KIND '$kind' (expected skill, cmd or ondemand): $kind $value $origin"
         continue ;;
    esac
    if ! valid_name "$value"; then
      pieces_bad="${pieces_bad}
    UNUSABLE NAME in $installed_manifest: '$value'"
      continue
    fi
    n_installed=$((n_installed + 1))
    installed_rows="${installed_rows}${kind} ${value} ${origin}
"
  done < "$installed_manifest"

  # THE COUNTER THIS ROW USED TO GUARD ITSELF WITH WAS SHARED. An emptied
  # hooks/installed.txt reported "PASS (3 probed)", because the three artefacts
  # named in hooks/retired.txt kept the count above zero while the manifest that
  # lists what must be PRESENT covered nothing at all. The counts are separate
  # now, and this one is asserted on its own.
  if [ "$n_installed" -eq 0 ]; then
    pieces_bad="${pieces_bad}
    NOTHING TO CHECK: no usable row parsed from $installed_manifest"
  fi

  # EXACTLY FOUR FIELDS IN hooks/retired.txt, for the same reason and with one
  # extra: `read -r kind ident archive artefacts` absorbs a fifth word into
  # $artefacts, so `ss-resolve, ss-score` written with a space becomes the single
  # artefact "ss-resolve," and the one that matters is never looked for. The list
  # is comma separated with no spaces, and that is enforced rather than tidied.
  retired_arts=""
  while read -r kind ident archive artefacts extra; do
    case "$kind" in ''|\#*) continue ;; esac
    if [ -z "$ident" ] || [ -z "$archive" ] || [ -n "$extra" ]; then
      pieces_bad="${pieces_bad}
    MALFORMED RETIRED ROW (needs exactly four fields, artefacts comma-separated with no spaces): $kind $ident $archive $artefacts $extra"
      continue
    fi
    if [ -z "$artefacts" ]; then
      pieces_bad="${pieces_bad}
    RETIRED ROW WITHOUT ARTEFACTS: $ident — add a fourth field naming what it installed, or - for nothing (hooks/retired.txt)"
      continue
    fi
    [ "$artefacts" = "-" ] && continue
    # SPLIT WITH GLOBBING OFF. Unquoted expansion under IFS=, is still subject to
    # pathname expansion, so an artefact list containing * would be replaced by
    # whatever happens to be in the working directory.
    old_ifs="$IFS"; IFS=,; set -f
    for art in $artefacts; do
      if ! valid_name "$art"; then
        pieces_bad="${pieces_bad}
    UNUSABLE ARTEFACT NAME for $ident: '$art' (empty entry, stray comma, or a space in the list)"
        continue
      fi
      n_retired_art=$((n_retired_art + 1))
      retired_arts="${retired_arts}${art} ${ident} ${archive}
"
    done
    set +f; IFS="$old_ifs"
  done < hooks/retired.txt

  # NOTHING IS CURRENT AND RETIRED AT ONCE. bitjaru/styleseed was in both files
  # from its retirement until the same day, satisfying externals.txt's definition
  # of a live dependency while retired.txt called it dead.
  while read -r rkind rident _rest; do
    case "$rkind" in ''|\#*) continue ;; esac
    [ -n "$rident" ] || continue
    if grep -vE '^\s*(#|$)' hooks/externals.txt \
      | awk -v n="$rident" 'BEGIN{n=tolower(n)} tolower($2)==n {found=1} END{exit !found}'; then
      pieces_bad="${pieces_bad}
    IN BOTH MANIFESTS: $rident is retired and still declared current in hooks/externals.txt"
    fi
  done < hooks/retired.txt

  # THE MANIFEST MUST COVER WHAT THE FRONT DOOR PROMISES. Without this the row
  # trusts hooks/installed.txt to be complete, and deleting any single line from
  # it leaves the whole suite green while a piece goes unwatched — the same
  # shape of hole as the one this row was written to close. INSTALL.md's pieces
  # table is the published list, so it is the thing reconciled against.
  #
  # Matched on the row's NAME or on its ORIGIN, because the table and the
  # manifest do not always spell a piece the same way and neither spelling is
  # wrong: the table lists `@yawlabs/ctxlint`, which installs a binary called
  # ctxlint, and `NVIDIA/SkillSpector`, which installs skillspector.
  table_pieces="$(awk -F'|' '
      /^\| Piece \| Gives \|/ {inside = 1; next}
      inside && /^\|---/       {next}
      inside && !/^\|/         {exit}
      inside                   {gsub(/[` ]/, "", $2); if ($2 != "") print $2}
    ' INSTALL.md 2>/dev/null)"
  n_table=0
  while read -r piece; do
    [ -n "$piece" ] || continue
    n_table=$((n_table + 1))
    if ! printf '%s' "$installed_rows" \
      | awk -v p="$piece" 'BEGIN{p=tolower(p)} tolower($2)==p || tolower($3)==p {found=1} END{exit !found}'; then
      pieces_bad="${pieces_bad}
    PROMISED BUT UNWATCHED: INSTALL.md's pieces table lists $piece and $installed_manifest has no row for it"
    fi
  done <<EOF
$table_pieces
EOF
  if [ "$n_table" -eq 0 ]; then
    pieces_bad="${pieces_bad}
    NOTHING TO RECONCILE: no piece parsed out of INSTALL.md's pieces table"
  fi

  # ── the disk probes, which are the local half ────────────────────────────
  if [ -n "${VERIFY_NO_LOCAL_TOOLS:-}" ] && [ -z "${INSTALLED_PROBE_ROOTS:-}" ]; then
    probes_note="not probed: VERIFY_NO_LOCAL_TOOLS is set for a runner that has none of these installed"
  else
    probes_note=""
    while read -r kind value _origin; do
      [ -n "$kind" ] || continue
      installed_probes=$((installed_probes + 1))
      case "$kind" in
        skill)
          skill_present "$value" || pieces_bad="${pieces_bad}
    MISSING SKILL: $value — no SKILL.md under any of $probe_roots" ;;
        # An on-demand tool is fetched at call time and is never on disk, so only
        # its runner can be asserted. SHIP.md step 3 carries the same carve-out.
        cmd|ondemand)
          command -v "$value" >/dev/null 2>&1 || pieces_bad="${pieces_bad}
    MISSING COMMAND: $value — not on PATH" ;;
      esac
    done <<EOF
$installed_rows
EOF

    # THE OTHER DIRECTION, and the one that was red on 2026-08-25.
    while read -r art ident archive; do
      [ -n "$art" ] || continue
      installed_probes=$((installed_probes + 1))
      if artefact_present "$art"; then
        pieces_bad="${pieces_bad}
    RETIRED PIECE STILL INSTALLED: $art (from $ident, archived at $archive) — delete it"
      fi
    done <<EOF
$retired_arts
EOF
  fi

  if [ -n "$pieces_bad" ]; then
    printf 'the repo and this machine disagree:%s\n' "$pieces_bad"
    red "pieces on this machine — something listed is absent, something retired is still here, or a manifest is malformed (see above)"
  elif [ -n "$probes_note" ]; then
    warn "pieces on this machine — $n_installed listed and $n_retired_art retired artefacts validated, $probes_note"
  else
    pass "pieces on this machine ($installed_probes probed: $n_installed listed, all present; $n_retired_art retired, none left behind)"
  fi
fi

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

# WHERE THE INSTALLED HOOKS LIVE. `--git-path hooks/x` is the obvious call and
# it is wrong inside a worktree: hooks belong to the COMMON directory, and from a
# linked worktree that call answers `.git/hooks/x`, a path relative to a `.git`
# that is a file there. Both hook rows then reported "none installed" while the
# hooks sat installed and working. Measured 2026-08-25; git 2.54.0 also fails
# `--path-format=absolute --git-path hooks` outright for the same reason.
# --git-common-dir is the call that answers correctly in both places, and it
# returns a relative `.git` from the main checkout, so it is resolved here.
hook_path() {  # $1 hook name -> absolute path, or empty when git cannot answer
  local common
  common="$(git rev-parse --git-common-dir 2>/dev/null)" || return 0
  [ -n "$common" ] || return 0
  case "$common" in /*) : ;; *) common="$ROOT/$common" ;; esac
  printf '%s/hooks/%s' "$common" "$1"
}

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
installed_hook="$(hook_path pre-commit)"
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
installed_push="$(hook_path pre-push)"
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

# ── always-loaded word budget ───────────────────────────────────────────────
#
# docs/WRITING.md has explained since it was written that every always-loaded line costs the
# model context on every turn. It never named a number, and none of the checks above measured
# one, so the chain grew from nobody's decision. This row is the number.
#
# THE LIMIT IS A RATCHET, NOT A TARGET. 2,200 is today's measured total plus a little room.
# It stops the chain growing; it does not claim the chain is the right size. A smaller figure
# would be a better goal and reaching it means rewriting CLAUDE.md and rules/codex.md, which
# is separate work and is not pretended to be done here.
#
# IT IS A LOCAL CHOICE AND NOT A BENCHMARK. A figure of 300 to 350 words per instruction file
# was quoted at the owner twice during this work as Anthropic's own testing. It came from a
# video attributing it to Anthropic and was never found on an Anthropic page. Repeating it as
# a measured fact was wrong, and it is not the basis for this number.
WORD_LIMIT=2200
chain=(CLAUDE.md rules/codex.md rules/mockups.md output-styles/plain.md)
chain_missing=""
chain_total=0
# Each count is validated as digits before it is added. An unreadable file makes `wc` fail and
# yields an empty string, which would either add zero and quietly shrink the measured total,
# or abort the arithmetic depending on the shell options in force. A budget check that reports
# a smaller number than the truth is worse than no budget check.
for f in "${chain[@]}"; do
  if [ -f "$ROOT/$f" ] && [ -r "$ROOT/$f" ]; then
    n="$(wc -w < "$ROOT/$f" 2>/dev/null | tr -d '[:space:]')"
    case "$n" in
      ''|*[!0-9]*) chain_missing="$chain_missing $f(unreadable)" ;;
      *)           chain_total=$(( chain_total + n )) ;;
    esac
  else
    chain_missing="$chain_missing $f"
  fi
done
if [ -n "$chain_missing" ]; then
  red "always-loaded word budget — these files are named in the chain but missing:$chain_missing"
elif [ "$chain_total" -gt "$WORD_LIMIT" ]; then
  echo "the always-loaded chain is over budget:"
  for f in "${chain[@]}"; do
    [ -f "$ROOT/$f" ] && printf '    %6s  %s\n' "$(wc -w < "$ROOT/$f" | tr -d '[:space:]')" "$f"
  done
  printf '    %6s  total, against a limit of %s\n' "$chain_total" "$WORD_LIMIT"
  red "always-loaded word budget — $chain_total words against a $WORD_LIMIT limit (see above; the rule is docs/WRITING.md)"
else
  pass "always-loaded word budget ($chain_total words of $WORD_LIMIT across ${#chain[@]} files)"
fi

printf '\n%-6s  %s\n' RESULT CHECK
for r in "${rows[@]}"; do printf '%-6s  %s\n' "${r%%|*}" "${r#*|}"; done
exit "$fail"
