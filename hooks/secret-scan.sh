#!/usr/bin/env bash
# The leak scanner: one executable, two rule files, one regex engine.
#
# Rewritten from a blank page 2026-08-22 (machinery rebuild). The contract is
# hooks/tests/secret-scan.test.sh — 23 cases plus the anchor list that pins the
# real rule coverage — and the callers below, which key off the exit codes.
#
# CALLERS. hooks/pre-commit (steps 2 and 3) and verify.sh (checks 8/8a/8b).
# Neither holds a copy of any rule: they execute this file, so there is no
# second copy anywhere to drift. Nothing here is ever handed to a different
# regex engine either — git grep and grep -E disagree about the word-boundary
# escape, and a rule set read by two engines is how a scan goes blind while
# reporting clean.
#
# RULE SETS. Default: secret-patterns.txt, credential formats, floor 25 (meant
# to grow with each vendor). --infra: infra-patterns.txt, private-LAN and
# internal-hostname shapes, floor 6 (a closed set — losing a rule is a
# regression; adding one means raising the floor deliberately). The floor is
# per file so neither set can be gutted inside the other's slack. Both files
# live NEXT TO this script and are resolved relative to it, so every caller
# gets the copy it means.
#
# USAGE.  secret-scan.sh [--infra] [--check | --files <path>... | (stdin)]
# EXIT.   0 = matched. 1 = scanned everything, matched nothing. >=2 = the scan
#         COULD NOT RUN, and every caller must fail its own check on it —
#         an unrun scan and a clean scan must never look alike.
set -uo pipefail

refuse() { printf 'secret-scan: %s\n' "$1" >&2; exit 2; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || refuse "cannot resolve own directory"

RULE_FILE="$HERE/secret-patterns.txt"
FLOOR=25
if [ "${1:-}" = "--infra" ]; then
  shift
  RULE_FILE="$HERE/infra-patterns.txt"
  FLOOR=6
fi

[ -f "$RULE_FILE" ] || refuse "rule file missing: $RULE_FILE"
[ -r "$RULE_FILE" ] || refuse "rule file unreadable: $RULE_FILE"

rules="$(grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$RULE_FILE")"
[ -n "$rules" ] || refuse "rule file holds zero rules (only comments and blank lines)"

# The lints run on EVERY invocation, because this file is the rule files' only
# compensating control: both are excluded from the enforcement scans (a file of
# leak regexes matches its own rules on every line), so nothing else ever looks
# inside them.
#
# Lint 1 — a rule with no regex metacharacter is a pasted VALUE, not a shape.
# Line numbers only: this output reaches CI logs on a public repo, and the
# offending line may BE the secret.
plain="$(grep -nvE '^[[:space:]]*#|^[[:space:]]*$' "$RULE_FILE" | grep -vE '[][(){}.*+?^$|\\]' | cut -d: -f1 | tr '\n' ' ')"
[ -z "$plain" ] || refuse "bare literal (no regex metacharacter) at line(s): ${plain}-- a literal here is a leak, not a rule"

# Lint 2 — the word-boundary escape is engine-dependent (silently dead under
# git grep on macOS, over-eager under GNU grep). Banned outright.
if printf '%s\n' "$rules" | grep -qF '\b'; then
  refuse "word-boundary escape found in the rules — use explicit character classes"
fi

# Floor — a gutted rule set must refuse to scan, never scan with less.
count="$(printf '%s\n' "$rules" | grep -c .)"
[ "$count" -ge "$FLOOR" ] || refuse "only $count rules loaded from ${RULE_FILE##*/} (minimum $FLOOR) — refusing to scan gutted"

JOINED="$(printf '%s\n' "$rules" | paste -sd'|' -)"

# Compile check. A valid pattern over empty input exits exactly 1; POSIX says
# errors are "greater than 1" without fixing which, so the test is `!= 1`,
# never `== 2`.
grep -qE -e "$JOINED" </dev/null 2>/dev/null
[ "$?" -eq 1 ] || refuse "pattern did not compile, or grep is misbehaving"

# Lint 3 — a real value pasted into one of this file's own COMMENTS would hide
# forever (nothing else scans these files), so the comments are held against
# the rules they sit beside. Not circular: comments are not rules.
hidden="$(grep -nE '^[[:space:]]*#' "$RULE_FILE" | grep -E -e "$JOINED" | cut -d: -f1 | tr '\n' ' ')"
[ -z "$hidden" ] || refuse "value matching ${RULE_FILE##*/}'s own rules in a COMMENT at line(s): ${hidden}-- never paste a real value here"

# -I skips binary files (it is NOT case-insensitivity), matching what both
# blocking callers always did.
case "${1:-}" in
  --check) exit 0 ;;
  --files)
    shift
    [ "$#" -ge 1 ] || refuse "--files needs at least one path"
    exec grep -HnEI -e "$JOINED" -- "$@" ;;
  '') exec grep -EI -e "$JOINED" ;;
  *) refuse "unknown mode: $1 (stdin, --files, or --check; --infra goes FIRST)" ;;
esac
