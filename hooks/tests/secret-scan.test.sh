#!/usr/bin/env bash
# Contract for hooks/secret-scan.sh, the leak scanner both blocking consumers
# execute.  Run: bash hooks/tests/secret-scan.test.sh
#
# Rewritten from a blank page 2026-08-22 (machinery rebuild), AFTER the scanner
# and judged against it.
#
# TWO HALVES, AND BOTH ARE NECESSARY.
#
#   SANDBOX cases run a COPY of the scanner in a mktemp directory with their own
#   rule files written next to the copy. The scanner resolves its rules relative
#   to itself, so every failure mode — file missing, gutted, uncompilable, a
#   pasted value where a rule belongs — is exercised without touching the real
#   ones. The rules there are synthetic (zzrule...), so no credential-shaped
#   string ever appears in this file's source and committing this test cannot
#   trip the very hook it tests.
#
#   REAL-INSTALL cases run the shipped scanner against the shipped rules. They
#   are the only ones that prove what actually protects this repo loads, lints
#   and compiles, and that the rule sets have not quietly shrunk.
#
# THE ANCHOR LIST IS THE POINT OF THE WHOLE FILE. A minimum-count floor counts
# LINES, so duplicating one rule twenty-five times satisfies it while every real
# vendor format silently vanishes. The anchors pin the COVERAGE itself: each is a
# fragment of a rule that must still be present. Fixed-string matched, never run
# as a regex.
#
# BASH-3.2 CLEAN (stock macOS): no associative arrays, no line-reading builtins,
# no case-changing expansions.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REAL_SCANNER="$REPO/hooks/secret-scan.sh"
REAL_CRED_RULES="$REPO/hooks/secret-patterns.txt"
REAL_INFRA_RULES="$REPO/hooks/infra-patterns.txt"

fail=0
results=()
check() {  # $1 description, $2 expected, $3 actual
  if [ "$2" = "$3" ]; then
    results+=("PASS|$1")
  else
    results+=("FAIL|$1 (expected [$2], got [$3])")
    fail=1
  fi
}

BOX="$(mktemp -d)"
# The unreadable-file case leaves mode 000 behind if it dies mid-way, which would
# make the sandbox undeletable.
trap 'chmod -R u+rwX "$BOX" 2>/dev/null; rm -rf "$BOX"' EXIT

cp "$REAL_SCANNER" "$BOX/secret-scan.sh"
chmod 755 "$BOX/secret-scan.sh"
SCANNER="$BOX/secret-scan.sh"
CRED_RULES="$BOX/secret-patterns.txt"
INFRA_RULES="$BOX/infra-patterns.txt"

# N synthetic, valid, distinct rules. Each carries regex metacharacters so it
# clears the bare-literal lint, and none is credential-shaped.
write_cred_rules() {
  i=1
  : > "$CRED_RULES"
  while [ "$i" -le "$1" ]; do printf 'zzrule%d[0-9]{4}\n' "$i" >> "$CRED_RULES"; i=$((i + 1)); done
}
write_infra_rules() {
  i=1
  : > "$INFRA_RULES"
  while [ "$i" -le "$1" ]; do printf 'zzinfra%d[0-9]{4}\n' "$i" >> "$INFRA_RULES"; i=$((i + 1)); done
}
rc_of() { "$@" >/dev/null 2>&1; echo $?; }

# Both sets start valid, so a case that sabotages one is not also tripping the
# other's floor by accident.
write_cred_rules 25
write_infra_rules 6

# ── refusing to scan: exit 2 is "could not run", never "clean" ───────────────
# Every one of these must be 2. A scanner that returned 1 (no match) here would
# report a gutted rule set as a clean bill of health, which is the failure this
# whole repo is built around.
rm -f "$CRED_RULES"
check "rule file missing" "2" "$(rc_of "$SCANNER" --check)"

: > "$CRED_RULES"
check "rule file empty" "2" "$(rc_of "$SCANNER" --check)"

printf '# just a comment\n#\n\n' > "$CRED_RULES"
check "rule file holds only comments" "2" "$(rc_of "$SCANNER" --check)"

write_cred_rules 24
check "24 credential rules, one under the floor" "2" "$(rc_of "$SCANNER" --check)"

write_cred_rules 25
printf 'zzbroken(\n' >> "$CRED_RULES"
check "a rule that does not compile" "2" "$(rc_of "$SCANNER" --check)"

# A non-comment line with no metacharacter is a pasted VALUE, not a shape.
write_cred_rules 25
printf 'zzliteralnometachar\n' >> "$CRED_RULES"
check "a bare literal where a rule belongs" "2" "$(rc_of "$SCANNER" --check)"

# The word-boundary escape is engine-dependent: dead under git grep on macOS,
# over-eager under GNU grep. It made this scan blind once and is banned outright.
write_cred_rules 25
printf '%s\n' 'zzboundary[0-9]{3}\b' >> "$CRED_RULES"
check "a word-boundary escape in a rule" "2" "$(rc_of "$SCANNER" --check)"

# A real value parked in a COMMENT would hide forever, because these files are
# excluded from every enforcement scan. zzrule19999 is credential-shaped to this
# synthetic rule set and to nothing else on earth.
write_cred_rules 25
printf '# zzrule19999\n' >> "$CRED_RULES"
check "a value matching the file's own rules, in a comment" "2" "$(rc_of "$SCANNER" --check)"

write_cred_rules 25
check "an unknown mode is refused, never silently passed through" "2" "$(rc_of "$SCANNER" --bogus)"

# Skipped as root, where mode 000 is still readable.
if [ "$(id -u)" -eq 0 ]; then
  results+=("PASS|an unreadable rule file (skipped: running as root)")
else
  chmod 000 "$CRED_RULES"
  rc="$(rc_of "$SCANNER" --check)"
  chmod 644 "$CRED_RULES"
  check "an unreadable rule file" "2" "$rc"
fi

# ── scanning: 0 matched, 1 searched and found nothing ───────────────────────
write_cred_rules 25
check "stdin, a match" "0" "$(rc_of sh -c "printf 'zzrule19999\n' | '$SCANNER'")"
check "stdin, the matching line is passed through" "zzrule19999" \
  "$(printf 'zzrule19999\n' | "$SCANNER")"

# Exit 1 is the NORMAL, healthy result and every caller keys off it. Treating it
# as failure would abort on every clean commit.
check "stdin, no match, is exactly 1" "1" \
  "$(rc_of sh -c "printf 'nothing of interest\n' | '$SCANNER'")"

printf 'zzrule19999\n' > "$BOX/hit.txt"
check "--files, a match" "0" "$(rc_of "$SCANNER" --files "$BOX/hit.txt")"
check "--files output carries file:line:" "$BOX/hit.txt:1:zzrule19999" \
  "$("$SCANNER" --files "$BOX/hit.txt")"

printf 'clean one\n' > "$BOX/clean1.txt"
printf 'clean two\n' > "$BOX/clean2.txt"
check "--files over two clean files" "1" "$(rc_of "$SCANNER" --files "$BOX/clean1.txt" "$BOX/clean2.txt")"

printf 'zzrule19999\n' > "$BOX/has space.txt"
check "--files with a path containing a space" "0" "$(rc_of "$SCANNER" --files "$BOX/has space.txt")"

check "--files with no path at all is refused" "2" "$(rc_of "$SCANNER" --files)"

# ── --infra selects the OTHER rule set, with its own floor ──────────────────
write_infra_rules 5
check "--infra, 5 rules, one under its floor of 6" "2" "$(rc_of "$SCANNER" --infra --check)"

write_infra_rules 6
printf 'zzliteralnometachar\n' >> "$INFRA_RULES"
check "--infra applies the bare-literal lint too" "2" "$(rc_of "$SCANNER" --infra --check)"

write_infra_rules 6
printf '%s\n' 'zzboundary[0-9]{3}\b' >> "$INFRA_RULES"
check "--infra applies the word-boundary ban too" "2" "$(rc_of "$SCANNER" --infra --check)"

write_infra_rules 6
check "--infra stdin, a match" "0" "$(rc_of sh -c "printf 'zzinfra19999\n' | '$SCANNER' --infra")"
check "--infra stdin, no match, is exactly 1" "1" \
  "$(rc_of sh -c "printf 'nothing of interest\n' | '$SCANNER' --infra")"

# The two sets must not bleed into each other, or the per-file floors mean
# nothing and one set could be gutted inside the other's slack.
write_cred_rules 25
write_infra_rules 6
check "--infra ignores the credential rule set" "1" \
  "$(rc_of sh -c "printf 'zzrule19999\n' | '$SCANNER' --infra")"
check "the default mode ignores the infra rule set" "1" \
  "$(rc_of sh -c "printf 'zzinfra19999\n' | '$SCANNER'")"

# ── the REAL install ────────────────────────────────────────────────────────
check "the shipped credential rules load, lint and compile" "0" "$(rc_of "$REAL_SCANNER" --check)"
check "the shipped infra rules load, lint and compile" "0" "$(rc_of "$REAL_SCANNER" --infra --check)"

# Coverage, pinned by anchor. Losing any one of these means a whole vendor format
# stopped being caught while the rule count stayed respectable.
missing=""
while IFS= read -r anchor; do
  [ -z "$anchor" ] && continue
  grep -qF -- "$anchor" "$REAL_CRED_RULES" || missing="$missing [$anchor]"
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
check "every pinned credential format is still present" "" "$missing"

# The git-host token prefix may be written per-vendor or as one character class.
if grep -qF -- 'gh[opsru]' "$REAL_CRED_RULES" || grep -qF -- 'ghp' "$REAL_CRED_RULES"; then rc=0; else rc=1; fi
check "the git-host token prefix rule is still present" "0" "$rc"

missing=""
while IFS= read -r anchor; do
  [ -z "$anchor" ] && continue
  grep -qF -- "$anchor" "$REAL_INFRA_RULES" || missing="$missing [$anchor]"
done <<'ANCHORS'
192\.168\.
10\.
172\.
100\.
internal
corp
lan
home
local
ANCHORS
check "every pinned infra shape is still present" "" "$missing"

# The counts are asserted so that ADDING a rule is a deliberate act: a new vendor
# format should update this number and say so, not slip in unremarked.
check "the shipped credential rule count" "26" \
  "$(grep -cvE '^[[:space:]]*#|^[[:space:]]*$' "$REAL_CRED_RULES")"
check "the shipped infra rule count" "6" \
  "$(grep -cvE '^[[:space:]]*#|^[[:space:]]*$' "$REAL_INFRA_RULES")"

printf '\n%-6s  %s\n' RESULT CASE
for r in "${results[@]}"; do printf '%-6s  %s\n' "${r%%|*}" "${r#*|}"; done

if [ "$fail" -eq 0 ]; then
  printf '\nAll asserts passed.\n'
  exit 0
else
  printf '\nSome asserts failed.\n'
  exit 1
fi
