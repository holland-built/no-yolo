#!/bin/bash
# Tests for hooks/secret-scan.sh — the single credential scanner.
# Plain bash asserts, same style as node-shim.test.sh. Picked up automatically by
# verify.sh check 1b (hooks/tests/*.test.sh). Run: bash hooks/tests/secret-scan.test.sh
#
# BASH-3.2 CLEAN on purpose (stock macOS bash): no mapfile, no readarray, no
# declare -A, no ${var^^}.
#
# Every case runs against a COPY of the scanner in a mktemp sandbox, with its own
# secret-patterns.txt written NEXT TO THE COPY. The scanner resolves its pattern file
# relative to itself, so the sandbox exercises every failure mode — missing file,
# gutted file, broken regex, leaked literal — without touching the real one.
#
# The synthetic rules (zzruleN...) exist so that no credential-shaped string ever
# appears in this file's source: committing this test must not trip the very hook it
# tests. Cases 15 and 16 cover the REAL install, where the real rules live.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REAL_SCAN="$REPO/hooks/secret-scan.sh"
REAL_RULES="$REPO/hooks/secret-patterns.txt"
REAL_INFRA="$REPO/hooks/infra-patterns.txt"

fail=0
results=()
assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    results+=("PASS|$desc")
  else
    results+=("FAIL|$desc (expected [$expected], got [$actual])")
    fail=1
  fi
}

SANDBOX="$(mktemp -d)"
trap 'chmod 644 "$SANDBOX/secret-patterns.txt" 2>/dev/null; rm -rf "$SANDBOX"' EXIT
cp "$REAL_SCAN" "$SANDBOX/secret-scan.sh"
chmod 755 "$SANDBOX/secret-scan.sh"
SCAN="$SANDBOX/secret-scan.sh"
RULES="$SANDBOX/secret-patterns.txt"
INFRA_RULES="$SANDBOX/infra-patterns.txt"

# N synthetic, valid, distinct rules — each carries regex metacharacters, so they clear
# the "bare literal" lint, and none of them is credential-shaped.
mkrules() {
  local want="$1" i=1
  : > "$RULES"
  while [ "$i" -le "$want" ]; do
    printf 'zzrule%d[0-9]{4}\n' "$i" >> "$RULES"
    i=$((i + 1))
  done
}

# The same for the --infra rule set, which the scanner reads from a SECOND file next to
# itself. Synthetic again: no real LAN address or internal hostname appears in this
# source, so committing this test cannot trip the very infra scan it tests.
mkinfrarules() {
  local want="$1" i=1
  : > "$INFRA_RULES"
  while [ "$i" -le "$want" ]; do
    printf 'zzinfra%d[0-9]{4}\n' "$i" >> "$INFRA_RULES"
    i=$((i + 1))
  done
}

# --- Case 1: no pattern file at all -> cannot scan ---
rm -f "$RULES"
"$SCAN" --check >/dev/null 2>&1
rc=$?
assert_eq "1. pattern file missing" "2" "$rc"

# --- Case 2: empty pattern file -> zero rules ---
: > "$RULES"
"$SCAN" --check >/dev/null 2>&1
rc=$?
assert_eq "2. empty pattern file" "2" "$rc"

# --- Case 3: comments only, still zero rules ---
printf '# just a comment\n#\n\n' > "$RULES"
"$SCAN" --check >/dev/null 2>&1
rc=$?
assert_eq "3. comment-only pattern file" "2" "$rc"

# --- Case 4: 24 rules, one under the floor -> refuse to scan gutted ---
mkrules 24
"$SCAN" --check >/dev/null 2>&1
rc=$?
assert_eq "4. 24 rules (below minimum 25)" "2" "$rc"

# --- Case 5: count is fine but one rule does not compile ---
mkrules 25
printf 'zzbroken(\n' >> "$RULES"
"$SCAN" --check >/dev/null 2>&1
rc=$?
assert_eq "5. invalid regex in rule set" "2" "$rc"

# --- Case 6: a rule with no metacharacter is a pasted value, not a rule ---
mkrules 25
printf 'zzliteralnometachar\n' >> "$RULES"
"$SCAN" --check >/dev/null 2>&1
rc=$?
assert_eq "6. bare literal rule (LINT 1)" "2" "$rc"

# --- Case 7: a credential-shaped value parked in a COMMENT (LINT 3) ---
#     Synthetic: rule 1 is zzrule1[0-9]{4}, so zzrule19999 is "credential-shaped"
#     to this rule set and to nothing else on earth.
mkrules 25
printf '# zzrule19999\n' >> "$RULES"
"$SCAN" --check >/dev/null 2>&1
rc=$?
assert_eq "7. value in a comment (LINT 3)" "2" "$rc"

# --- Case 8: stdin match -> 0, and the matching line is passed through ---
mkrules 25
out="$(printf 'zzrule19999\n' | "$SCAN")"
rc=$?
assert_eq "8. stdin match exit code" "0" "$rc"
assert_eq "8. stdin match passes the line through" "zzrule19999" "$out"

# --- Case 9: stdin, no match -> EXACTLY 1. A valid pattern finding nothing is
#     the normal, healthy result — not a failure. Callers key off this.
printf 'nothing of interest here\n' | "$SCAN" >/dev/null
rc=$?
assert_eq "9. stdin no-match is exit 1, not failure" "1" "$rc"

# --- Case 10: --files match -> 0, output carries the file:line: prefix ---
printf 'zzrule19999\n' > "$SANDBOX/hit.txt"
out="$("$SCAN" --files "$SANDBOX/hit.txt")"
rc=$?
assert_eq "10. --files match exit code" "0" "$rc"
assert_eq "10. --files match file:line: prefix" "$SANDBOX/hit.txt:1:zzrule19999" "$out"

# --- Case 11: --files over two clean files -> exactly 1 ---
printf 'clean one\n' > "$SANDBOX/clean1.txt"
printf 'clean two\n' > "$SANDBOX/clean2.txt"
"$SCAN" --files "$SANDBOX/clean1.txt" "$SANDBOX/clean2.txt" >/dev/null
rc=$?
assert_eq "11. --files no match over two files" "1" "$rc"

# --- Case 12: a path with a space survives the hand-off to grep ---
printf 'zzrule19999\n' > "$SANDBOX/has space.txt"
"$SCAN" --files "$SANDBOX/has space.txt" >/dev/null
rc=$?
assert_eq "12. --files path containing a space" "0" "$rc"

# --- Case 13: pattern file present but unreadable -> fail closed, not silently clean.
#     Skipped as root, where mode 000 is still readable.
if [ "$(id -u)" -eq 0 ]; then
  results+=("PASS|13. unreadable pattern file (skipped: running as root)")
else
  chmod 000 "$RULES"
  "$SCAN" --check >/dev/null 2>&1
  rc=$?
  chmod 644 "$RULES"
  assert_eq "13. unreadable pattern file" "2" "$rc"
fi

# --- Case 14: unknown mode -> 2, never a silent pass-through ---
"$SCAN" --bogus >/dev/null 2>&1
rc=$?
assert_eq "14. unknown mode --bogus" "2" "$rc"

# --- Case 15: REAL INSTALL. Everything above ran on a sandbox copy; this is the only
#     case that proves the shipped scanner + shipped rules load, lint and compile.
"$REAL_SCAN" --check >/dev/null 2>&1
rc=$?
assert_eq "15. real hooks/secret-scan.sh --check" "0" "$rc"

# --- Case 16: REQUIRED RULES. The minimum-25 floor counts lines, so duplicating one
#     rule 25 times would satisfy it while every real vendor format quietly vanished.
#     These anchors pin the coverage itself. Fixed-string match: the anchors are
#     fragments of the rules, not regexes to run.
missing=""
while IFS= read -r anchor; do
  [ -z "$anchor" ] && continue
  grep -qF -- "$anchor" "$REAL_RULES" || missing="$missing [$anchor]"
done <<'ANCHORS'
AKIA
sk-ant-
github_pat_
xox
AIza
sk_live_
glpat-
npm_
PRIVATE KEY
postgres://
mysql://
mongodb
redis://
earer
eyJ
SG\.
rk_live_
aws_secret_access_key
password
passwd
apikey
ANCHORS
assert_eq "16. required rules present" "" "$missing"

# The token-prefix rule may be written per-vendor or as one character class.
if grep -qF -- 'gh[opsru]' "$REAL_RULES" || grep -qF -- 'ghp' "$REAL_RULES"; then
  rc=0
else
  rc=1
fi
assert_eq "16. git host token prefix rule present" "0" "$rc"

n_real="$(grep -cvE '^[[:space:]]*#|^[[:space:]]*$' "$REAL_RULES")"
assert_eq "16. real rule count" "26" "$n_real"

# --- Cases 17-23: --infra, the SECOND rule set. Same executable, same lints, same exit
#     codes — a different file and a different floor (6, its real rule count; the infra
#     set is closed, so losing one rule is a regression, not routine growth).
#     Every lint below is proved to apply to whichever file is loaded, not just the
#     credential one: that is the whole reason the two sets could be consolidated.

# --- Case 17: 5 infra rules, one under the floor -> refuse to scan gutted ---
mkinfrarules 5
"$SCAN" --infra --check >/dev/null 2>&1
rc=$?
assert_eq "17. --infra 5 rules (below minimum 6)" "2" "$rc"

# --- Case 18: a rule with no metacharacter is a pasted value, not a rule ---
mkinfrarules 6
printf 'zzliteralnometachar\n' >> "$INFRA_RULES"
"$SCAN" --infra --check >/dev/null 2>&1
rc=$?
assert_eq "18. --infra bare literal rule (LINT 1)" "2" "$rc"

# --- Case 19: the word-boundary escape is banned here too. It is the exact
#     metacharacter that made this scan blind under git grep on macOS, which is why
#     the character-class form is the one that survived into the rule file. ---
mkinfrarules 6
printf '%s\n' 'zzwordboundary[0-9]{3}\b' >> "$INFRA_RULES"
"$SCAN" --infra --check >/dev/null 2>&1
rc=$?
assert_eq "19. --infra word-boundary escape (LINT 2)" "2" "$rc"

# --- Case 20: stdin match -> 0, and the matching line is passed through ---
mkinfrarules 6
out="$(printf 'zzinfra19999\n' | "$SCAN" --infra)"
rc=$?
assert_eq "20. --infra stdin match exit code" "0" "$rc"
assert_eq "20. --infra stdin match passes the line through" "zzinfra19999" "$out"

# --- Case 21: stdin, no match -> EXACTLY 1, the healthy result pre-commit keys off ---
printf 'nothing of interest here\n' | "$SCAN" --infra >/dev/null
rc=$?
assert_eq "21. --infra stdin no-match is exit 1, not failure" "1" "$rc"

# --- Case 22: the two rule sets do not bleed into each other. A credential-shaped
#     value must NOT be caught by --infra, or the per-file floors mean nothing. ---
mkrules 25
mkinfrarules 6
printf 'zzrule19999\n' | "$SCAN" --infra >/dev/null
rc=$?
assert_eq "22. --infra ignores the credential rule set" "1" "$rc"

# --- Case 23: REAL INSTALL. The only case that proves the shipped infra rules load,
#     lint and compile — and that the shipped set has not quietly shrunk. ---
"$REAL_SCAN" --infra --check >/dev/null 2>&1
rc=$?
assert_eq "23. real hooks/infra-patterns.txt --infra --check" "0" "$rc"

n_infra="$(grep -cvE '^[[:space:]]*#|^[[:space:]]*$' "$REAL_INFRA")"
assert_eq "23. real infra rule count" "6" "$n_infra"

printf '\n%-6s  %s\n' RESULT CASE
for r in "${results[@]}"; do printf '%-6s  %s\n' "${r%%|*}" "${r#*|}"; done

if [ "$fail" -eq 0 ]; then
  printf '\nAll asserts passed.\n'
  exit 0
else
  printf '\nSome asserts failed.\n'
  exit 1
fi
