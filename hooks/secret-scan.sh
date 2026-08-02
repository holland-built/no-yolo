#!/usr/bin/env bash
# hooks/secret-scan.sh — THE credential scanner. Single pattern source, single engine.
# Callers (nobody holds a copy of the rules):
#   hooks/pre-commit step 2  -> "$(git rev-parse --show-toplevel)/hooks/secret-scan.sh"
#   verify.sh checks 8/8a/8b -> "$ROOT/hooks/secret-scan.sh"   (the CHECKOUT's copy; CI has no $HOME/.claude)
#   skills/health/SKILL.md   -> "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/secret-scan.sh"  (/health runs in OTHER repos)
# The pattern file lives NEXT TO THIS SCRIPT and is resolved relative to it, so each
# caller automatically gets the copy it means.
# Modes: (none) = filter stdin; --files <f>... = scan files, file:line output; --check = load+lint+compile only.
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
PATTERN_FILE="$SELF_DIR/secret-patterns.txt"

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
[ "$n" -ge 25 ] || die "only $n rules loaded (minimum 25) — refusing to scan with a gutted pattern set"

PATTERN="$(printf '%s\n' "$rules" | paste -sd'|' -)"

# Compile test. A VALID pattern over empty input exits 1 — that is the ONLY success here.
# POSIX says errors are "greater than 1", not exactly 2, so do not special-case 2.
# Treating 1 as failure would abort on every valid pattern set.
grep -qE -e "$PATTERN" </dev/null 2>/dev/null
rc=$?
[ "$rc" -eq 1 ] || die "compile test returned $rc (want 1) — pattern did not compile, or grep is not behaving"

# LINT 3 — the comments in this file are scanned by NOTHING ELSE (the file is excluded from
# the enforcement scans because it self-matches), so a real key pasted into a comment would
# hide here forever. Not circular: comments are not rules. Line numbers only.
cbad="$(grep -nE '^[[:space:]]*#' "$PATTERN_FILE" | grep -E -e "$PATTERN" | cut -d: -f1 | tr '\n' ' ')"
[ -z "$cbad" ] || die "credential-shaped value in a COMMENT at line(s): ${cbad}-- never paste a real key here"

case "${1:-}" in
  --check) exit 0 ;;
  --files) shift
           [ "$#" -ge 1 ] || die "--files needs at least one path"
           exec grep -HnEI -e "$PATTERN" -- "$@" ;;
  '')      exec grep -EI -e "$PATTERN" ;;
  *)       die "unknown mode: $1 (stdin, --files, or --check)" ;;
esac
