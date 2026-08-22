#!/usr/bin/env bash
# hooks/secret-scan.sh — THE leak scanner. Two rule files, one reader, one engine.
# Callers (nobody holds a copy of the rules):
#   hooks/pre-commit step 2  -> "$(git rev-parse --show-toplevel)/hooks/secret-scan.sh"
#   hooks/pre-commit step 3  -> the same path, with --infra
#   verify.sh checks 8/8a/8b -> "$ROOT/hooks/secret-scan.sh" [--infra]   (the CHECKOUT's copy; CI has no $HOME/.claude)
# A third caller, skills/health/SKILL.md, was listed here until 2026-08-21. The rebuild
# deleted that skill and the line outlived it. There is no /health any more, so nothing
# runs this scanner against OTHER repos: both remaining callers scan THIS one.
# Rule sets:
#   (default) secret-patterns.txt — credential formats.
#   --infra   infra-patterns.txt  — private LAN / internal-infra values. Kept a separate
#             set because RFC1918 addresses are legitimate content in most other repos,
#             so anything scanning beyond this repo would want the credential set alone.
# The two sets stay separate files because the two blocking consumers apply them to
# DIFFERENT inputs (pre-commit's step 2 excludes the pattern-documenting files, step 3
# does not), and because a single joined pattern would let one set's rules vanish inside
# the other's minimum-count floor.
# Both files live NEXT TO THIS SCRIPT and are resolved relative to it, so each caller
# automatically gets the copy it means.
# Modes: (none) = filter stdin; --files <f>... = scan files, file:line output; --check = load+lint+compile only.
# --infra is a rule-set selector, not a mode — it composes with all three.
# There is deliberately NO mode that prints the joined pattern: exporting it would let a
# caller feed it to a different regex engine (git grep), recreating the \b portability bug
# this executable exists to end.
# -I means "skip binary files" (NOT case-insensitive) — same semantics the two blocking
# consumers already had.
# Exit codes: 0 match, 1 no match, 2 the scan could NOT run.
# FAIL CLOSED: every caller must treat anything other than 0 or 1 as a failure of its own check.
set -uo pipefail

die() { printf 'secret-scan: %s\n' "$1" >&2; exit 2; }

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || die "cannot resolve own directory"

# Rule-set selection. The floor is PER FILE and set from that file's real rule count, so
# neither set can be gutted inside the other's slack — refusing to scan with a gutted
# pattern set is the whole point of the floor.
#   credentials: 26 rules today, floor 25 (this file is MEANT to grow with each vendor).
#   infra:        6 rules today, floor  6 (a closed set — three RFC1918 ranges, the CGNAT
#                 range, two hostname-TLD rules; losing even one is a regression, and
#                 adding one means raising this number deliberately).
PATTERN_NAME="secret-patterns.txt"
MIN_RULES=25
if [ "${1:-}" = "--infra" ]; then
  shift
  PATTERN_NAME="infra-patterns.txt"
  MIN_RULES=6
fi
PATTERN_FILE="$SELF_DIR/$PATTERN_NAME"

[ -f "$PATTERN_FILE" ] || die "pattern file missing: $PATTERN_FILE"
[ -r "$PATTERN_FILE" ] || die "pattern file unreadable: $PATTERN_FILE"

rules="$(grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$PATTERN_FILE")"
[ -n "$rules" ] || die "pattern file holds zero rules (comments/blank lines only)"

# LINT 1 — a rule with no regex metacharacter is a bare literal: a LEAKED VALUE, not a rule.
# Line numbers ONLY: this runs in CI on a public repo and the offending line may BE the secret.
bad="$(grep -nvE '^[[:space:]]*#|^[[:space:]]*$' "$PATTERN_FILE" | grep -vE '[][(){}.*+?^$|\\]' | cut -d: -f1 | tr '\n' ' ')"
[ -z "$bad" ] || die "bare literal (no regex metacharacter) at line(s): ${bad}-- a literal here is a leak, not a rule"

# LINT 2 — \b is engine-dependent (dead under git grep on macOS). Banned.
n_wb="$(printf '%s\n' "$rules" | grep -cF '\b')"
[ "$n_wb" -eq 0 ] || die "\\b found in $n_wb rule line(s) — use explicit character classes"

n="$(printf '%s\n' "$rules" | grep -c .)"
[ "$n" -ge "$MIN_RULES" ] || die "only $n rules loaded from $PATTERN_NAME (minimum $MIN_RULES) — refusing to scan with a gutted pattern set"

PATTERN="$(printf '%s\n' "$rules" | paste -sd'|' -)"

# Compile test. A VALID pattern over empty input exits 1 — that is the ONLY success here.
# POSIX says errors are "greater than 1", not exactly 2, so do not special-case 2.
# Treating 1 as failure would abort on every valid pattern set.
grep -qE -e "$PATTERN" </dev/null 2>/dev/null
rc=$?
[ "$rc" -eq 1 ] || die "compile test returned $rc (want 1) — pattern did not compile, or grep is not behaving"

# LINT 3 — the comments in a rule file are scanned by NOTHING ELSE (both files are excluded
# from the enforcement scans because they self-match), so a real key or a real LAN address
# pasted into a comment would hide there forever. Not circular: comments are not rules.
# Line numbers only.
cbad="$(grep -nE '^[[:space:]]*#' "$PATTERN_FILE" | grep -E -e "$PATTERN" | cut -d: -f1 | tr '\n' ' ')"
[ -z "$cbad" ] || die "value matching $PATTERN_NAME's own rules in a COMMENT at line(s): ${cbad}-- never paste a real value here"

case "${1:-}" in
  --check) exit 0 ;;
  --files) shift
           [ "$#" -ge 1 ] || die "--files needs at least one path"
           exec grep -HnEI -e "$PATTERN" -- "$@" ;;
  '')      exec grep -EI -e "$PATTERN" ;;
  *)       die "unknown mode: $1 (stdin, --files, or --check; --infra goes FIRST)" ;;
esac
