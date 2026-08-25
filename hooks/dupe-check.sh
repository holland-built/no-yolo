#!/usr/bin/env bash
# dupe-check.sh — the Duplicate scan gate in skills/build/stages/5-build.md, made runnable.
#
# Two passes, because they catch different things and one of them survives a missing tool:
#
#   COPIED BLOCKS  jscpd over the touched files. Catches a block pasted and edited, which no
#                  name search finds. Needs jscpd on PATH.
#   REPEATED NAMES a new top-level symbol whose name is already defined somewhere else in the
#                  tree. Catches the sibling that already does the job, which jscpd walks past
#                  when the second implementation was written from scratch. Needs git alone.
#
# Usage, one mode per run:
#   dupe-check.sh <file> [file...]        both passes over whole files
#   dupe-check.sh --since <ref>           both passes over what changed since <ref>
#   dupe-check.sh --symbols <name> [...]  the name pass over names the plan proposes
#
# Exit codes, which callers keep distinct:
#   0  every pass that ran found nothing
#   1  a finding: a copied block, a repeated name, or both
#   3  COULD NOT RUN. Never report this as clean.
#
# FAIL CLOSED. A bad ref, a file that is not there, a git command that errors: all 3. An empty
# but successfully computed change set is 0, because nothing changed is a real clean result.
#
# WHY THE jscpd EXIT CODE IS NOT TRUSTED. Measured on jscpd 5.0.16, 2026-08-22: `--exit-code 1`
# returns 1 for a clone found AND 1 for a config file that does not exist. Reading the status
# alone would report a broken invocation as a finding, and a run over files in no format it
# analyses prints nothing at all. The `Found <n> clones.` line the console reporter emits is
# what decides here; its absence with a nonzero status is a tool failure, not a clean bill.
#
# WHY THE NAME PASS IS ANCHORED AT COLUMN ZERO. A `const` inside a function body is a local,
# and reporting locals is how a gate gets switched off. Anchoring costs the nested definitions
# and buys a signal worth reading.
#
# BASH-3.2 CLEAN (stock macOS): no associative arrays, no line-reading builtins, no
# case-changing expansions. Paths move through NUL-delimited git output throughout, so a space
# or a newline in a filename cannot split one path into two.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die() { printf 'dupe-check: %s\n' "$1" >&2; exit 3; }

BOX="$(mktemp -d)" || { echo "dupe-check: cannot create a working directory" >&2; exit 3; }
trap 'rm -rf "$BOX"' EXIT

# Operands go to a file rather than an array. Under `set -u`, bash 3.2 treats "${A[@]}" and
# even "${#A[@]}" on an EMPTY array as an unbound variable and aborts, which is a crash on
# every no-argument run.
ARGFILE="$BOX/args"
: > "$ARGFILE"
n_args=0

MODE=""
REF=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --since)
      [ "$MODE" = "" ] || die "--since and --symbols are separate modes; pick one"
      MODE=since; shift
      [ "$#" -gt 0 ] || die "--since needs a ref"
      REF="$1"; shift ;;
    --symbols)
      [ "$MODE" = "" ] || die "--since and --symbols are separate modes; pick one"
      MODE=symbols; shift ;;
    -h|--help)
      grep '^#' "${BASH_SOURCE[0]}" | head -18 | cut -c 3-; exit 0 ;;
    -*) die "unknown option $1" ;;
    *) printf '%s\n' "$1" >> "$ARGFILE"; n_args=$((n_args + 1)); shift ;;
  esac
done
[ "$MODE" = "" ] && MODE=files

# ── The tree ─────────────────────────────────────────────────────────────────
# Resolved from the CURRENT DIRECTORY, never from this script's own location: the hook is
# installed once and runs against whichever project the build is in.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$ROOT" ] || die "not inside a git repository, so neither pass has a tree to search"
cd "$ROOT" || die "cannot enter $ROOT"

# ── The file list ────────────────────────────────────────────────────────────
FILES="$BOX/files"          # NUL-delimited, repo-relative
: > "$FILES"

collect_since() {
  local base
  git rev-parse --verify --quiet "$REF^{commit}" >/dev/null \
    || die "'$REF' is not a commit in this repository"
  base="$(git merge-base "$REF" HEAD 2>/dev/null)" \
    || die "no merge base between '$REF' and HEAD"
  [ -n "$base" ] || die "no merge base between '$REF' and HEAD"
  # Against the WORKING TREE, not against HEAD. A three-dot diff to HEAD reports nothing for
  # work that is staged or still unsaved, which is exactly the work a build gate is asked
  # about.
  # refs/brands/ is excluded from both halves. It holds 74 third-party brand specifications
  # vendored verbatim, and they repeat each other by design: every one carries a `primary:`,
  # a `canvas:`, a `typography:`. That is the format, not a copied block, and reporting it
  # would bury a real duplicate under 74 false ones.
  git diff -z --name-only --diff-filter=ACMRT "$base" -- . ':!refs/brands/**' > "$BOX/tracked" \
    || die "git diff against $base failed"
  git ls-files -z --others --exclude-standard -- . ':!refs/brands/**' > "$BOX/untracked" \
    || die "git ls-files failed"
  cat "$BOX/tracked" "$BOX/untracked" > "$FILES"
  BASE="$base"
}

BASE=""
case "$MODE" in
  since) collect_since ;;
  files)
    [ "$n_args" -gt 0 ] || die "name at least one file, or pass --since <ref>"
    while IFS= read -r f; do
      [ -f "$f" ] || die "$f is not a readable file"
      printf '%s\0' "$f" >> "$FILES"
    done < "$ARGFILE" ;;
  symbols)
    [ "$n_args" -gt 0 ] || die "--symbols needs at least one name" ;;
esac

n_files=0
if [ "$MODE" != symbols ]; then
  n_files="$(tr '\0' '\n' < "$FILES" | grep -c . || true)"
fi

findings=0
jscpd_ran=0
names_ran=0

# ── Pass one: copied blocks ──────────────────────────────────────────────────
# The project's own .jscpd.json wins when it has one; the shipped default is the fallback, so
# a project that has never heard of jscpd still gets a configured run rather than jscpd's
# defaults. Keys are camelCase: snake_case keys parse without complaint and are then ignored,
# measured on 5.0.16.
if [ "$MODE" != symbols ]; then
  if ! command -v jscpd >/dev/null 2>&1; then
    printf 'jscpd: did not run, not installed\n'
  elif [ "$n_files" -eq 0 ]; then
    jscpd_ran=1
  else
    CONFIG="$ROOT/.jscpd.json"
    [ -f "$CONFIG" ] || CONFIG="$SELF_DIR/../.jscpd.json"
    if [ ! -f "$CONFIG" ]; then
      printf 'jscpd: did not run, no .jscpd.json in %s or beside the hook\n' "$ROOT"
    else
      # xargs -0 keeps every path intact and splits the run when the list is long.
      xargs -0 jscpd --config "$CONFIG" --no-colors --reporters console --exit-code 1 \
        < "$FILES" > "$BOX/jscpd.out" 2>&1
      jscpd_rc=$?
      clones="$(grep -oE 'Found [0-9]+ clones' "$BOX/jscpd.out" | tail -1 | tr -dc '0-9')"
      # A FRAGMENT MATCHING ITSELF IS NOT A COPY. jscpd reports one when a file
      # holds a long run of similar tokens: measured 2026-08-23 on SHIP.md's
      # `git add` path list, which came back as a clone of lines 236:1-241:3
      # against 236:2-241:4, the same lines one column over. Nobody can act on
      # that, and a gate that cries wolf gets waived by habit and then waived
      # on the day it was right. Both halves must name the same file AND their
      # line ranges must overlap; two separate blocks inside one file still
      # report.
      #
      # The range is read out of the brackets rather than by splitting the line
      # on punctuation. The first version split on [][: and put "1 - 241" in one
      # field, so it read the END line as 3: it filtered one clone shape and
      # missed the identical one beside it, which is worse than not filtering.
      self_overlap="$(awk '
        function fname(s,   i) { i = index(s, "["); s = substr(s, 1, i - 1)
          sub(/^ *- */, "", s); sub(/^ +/, "", s); sub(/ +$/, "", s)
          sub(/:[a-z]+$/, "", s); return s }
        function lo(s,   i, j, r) { i = index(s, "["); j = index(s, "]")
          r = substr(s, i + 1, j - i - 1); split(r, q, " - "); split(q[1], t, ":")
          return t[1] + 0 }
        function hi(s,   i, j, r) { i = index(s, "["); j = index(s, "]")
          r = substr(s, i + 1, j - i - 1); split(r, q, " - "); split(q[2], t, ":")
          return t[1] + 0 }
        /^ - .*\[.*\]/ {
          f1 = fname($0); a = lo($0); b = hi($0)
          if ((getline nxt) > 0 && nxt ~ /\[.*\]/) {
            f2 = fname(nxt); c = lo(nxt); d = hi(nxt)
            if (f1 == f2 && c <= b && d >= a) n++
          }
        }
        END {print n + 0}
      ' "$BOX/jscpd.out" 2>/dev/null)"
      [ -n "$self_overlap" ] || self_overlap=0
      if [ -n "$clones" ]; then
        jscpd_ran=1
        if [ "$clones" -gt "$self_overlap" ]; then
          grep -vE '^(💡|🎩|💖|time:|Using config)' "$BOX/jscpd.out"
          findings=1
        elif [ "$self_overlap" -gt 0 ]; then
          printf 'jscpd: %s clone(s), all of them a fragment overlapping itself; ignored\n' "$self_overlap"
        fi
      elif [ "$jscpd_rc" -eq 0 ]; then
        # Nothing in a format jscpd analyses. A real answer, and a clean one.
        jscpd_ran=1
      else
        printf 'jscpd: did not run, it exited %s without reporting a count\n' "$jscpd_rc"
        sed -n '1,5p' "$BOX/jscpd.out" >&2
      fi
    fi
  fi
fi

# ── Pass two: repeated names ─────────────────────────────────────────────────
# Names that mean something different in every file that holds one. Reporting these is noise
# and nothing else.
COMMON=" main init setup run test tests new default index constructor handler get set add
 remove update parse format render build config options data value result item next done
 check contains "

# Reads lines on stdin, prints one candidate name per line.
extract_symbols() {
  sed -E 's/^\+//' > "$BOX/lines"
  grep -oE '^(export[[:space:]]+)?(default[[:space:]]+)?(async[[:space:]]+)?(function|class|def|func|const|let|var|type|interface)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
    "$BOX/lines" 2>/dev/null | awk '{print $NF}'
  # Shell's own form, which carries no keyword: `name() {` and `name () {`.
  grep -oE '^[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)[[:space:]]*\{' "$BOX/lines" 2>/dev/null \
    | sed -E 's/[[:space:]]*\(\).*//'
}

# Every place in the tree that DEFINES this name, as file:line.
definitions_of() {
  local name="$1" pat
  pat="(^|[^A-Za-z0-9_])(function|class|def|func|const|let|var|type|interface)[[:space:]]+${name}([^A-Za-z0-9_]|\$)"
  pat="${pat}|^[[:space:]]*${name}[[:space:]]*\(\)[[:space:]]*\{"
  git grep -n -I -E --untracked -- "$pat" 2>/dev/null \
    | grep -vE '(^|/)(node_modules|dist|build|vendor|\.mockups|\.xcheck)/' \
    | cut -d: -f1,2
}

report_name() {  # $1 name, $2 the file it came from ("" for --symbols)
  local name="$1" origin="$2" hits hit
  case "$COMMON" in *" $name "*) return 0 ;; esac
  hits="$(definitions_of "$name")"
  [ -n "$hits" ] || return 0
  printf '%s\n' "$hits" | while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    [ "${hit%%:*}" = "$origin" ] && continue
    printf 'DUPLICATE SYMBOL: %s already at %s\n' "$name" "$hit"
  done
}

SEEN="$BOX/seen"
: > "$SEEN"
NAMEHITS="$BOX/namehits"
: > "$NAMEHITS"

if [ "$MODE" = symbols ]; then
  names_ran=1
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    grep -qxF -- "$name" "$SEEN" && continue
    printf '%s\n' "$name" >> "$SEEN"
    report_name "$name" "" >> "$NAMEHITS"
  done < "$ARGFILE"
else
  names_ran=1
  while IFS= read -r -d '' f; do
    [ -f "$f" ] || continue
    # The ADDED lines only, so a file that merely moved does not re-report its own symbols.
    # An UNTRACKED file has no diff at all — git diff prints nothing for it — so the whole
    # file is what is new. Reading the diff for those meant a brand-new file, the commonest
    # way a duplicate name arrives, was scanned for nothing and passed.
    if [ -n "$BASE" ] && git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
      git diff "$BASE" -- "$f" 2>/dev/null | grep '^+' | grep -v '^+++'
    else
      cat "$f"
    fi > "$BOX/added"
    extract_symbols < "$BOX/added" | sort -u > "$BOX/names"
    while IFS= read -r name; do
      [ -z "$name" ] && continue
      grep -qxF -- "$name:$f" "$SEEN" && continue
      printf '%s\n' "$name:$f" >> "$SEEN"
      report_name "$name" "$f" >> "$NAMEHITS"
    done < "$BOX/names"
  done < "$FILES"
fi

if [ -s "$NAMEHITS" ]; then
  sort -u "$NAMEHITS"
  findings=1
fi

if [ "$jscpd_ran" -eq 0 ] && [ "$names_ran" -eq 0 ]; then
  printf 'dupe-check: COULD NOT RUN, this is not a clean result\n' >&2
  exit 3
fi
[ "$findings" -eq 1 ] && exit 1
exit 0
