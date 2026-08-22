#!/bin/bash
# Tests for hooks/pre-commit — the commit blocker itself, not the scanner it calls.
# Plain bash asserts, same style as secret-scan.test.sh. Picked up automatically by
# verify.sh check 1b (hooks/tests/*.test.sh). Run: bash hooks/tests/pre-commit.test.sh
#
# BASH-3.2 CLEAN on purpose (stock macOS bash): no mapfile, no readarray, no
# declare -A, no ${var^^}.
#
# WHY THIS EXISTS: hooks/secret-scan.sh has its own suite, so the RULES are proved.
# What was never proved is that pre-commit runs those rules against the staged set and
# refuses. It was left out because it judges a real staged index — but an index does not
# have to be this repo's. Every case below runs inside a throwaway git repo in a mktemp
# sandbox, with a COPY of the tracked hook installed at .git/hooks/pre-commit. Nothing
# here reads, stages, or commits anything in ~/.claude.
#
# NO CREDENTIAL OR INFRA VALUE IS WRITTEN IN THIS FILE. The planted values are read at
# runtime from hooks/tests/infra-scan-probe.txt — the same sha256-pinned positive-control
# fixture verify.sh check 8a uses — and sorted into a credential set and an infra set by
# asking the scanner itself which rule set catches each line. That keeps this source
# committable through the very hook it tests, and it cannot drift if the fixture is
# reordered.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO/hooks/pre-commit"
SCAN="$REPO/hooks/secret-scan.sh"
PROBE="$REPO/hooks/tests/infra-scan-probe.txt"

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
# The exit code alone cannot tell WHICH rule refused, and a hook that refuses for the
# wrong reason is a hook that will pass this suite while blind to the case it claims.
assert_has() {
  local desc="$1" needle="$2" haystack="$3"
  case "$haystack" in
    *"$needle"*) results+=("PASS|$desc") ;;
    *) results+=("FAIL|$desc (output did not contain [$needle])"); fail=1 ;;
  esac
}

SANDBOX="$(mktemp -d)"
trap 'chmod -R u+rwx "$SANDBOX" 2>/dev/null; rm -rf "$SANDBOX"' EXIT

# --- Throwaway repo ---------------------------------------------------------------
R="$SANDBOX/repo"
mkdir -p "$R/hooks"
git init -q "$R" >/dev/null 2>&1
git -C "$R" config user.email "probe@example.invalid"
git -C "$R" config user.name "pre-commit suite"
git -C "$R" config commit.gpgsign false
# A global core.hooksPath would send git looking somewhere else entirely, and the
# suite would then pass by never running the hook at all.
git -C "$R" config core.hooksPath .git/hooks

cp "$SCAN" "$R/hooks/secret-scan.sh"; chmod 755 "$R/hooks/secret-scan.sh"
cp "$REPO/hooks/secret-patterns.txt" "$R/hooks/secret-patterns.txt"
cp "$REPO/hooks/infra-patterns.txt" "$R/hooks/infra-patterns.txt"
printf 'seed file for the throwaway repo\n' > "$R/README.md"
git -C "$R" add -A >/dev/null 2>&1
git -C "$R" commit -q -m "seed" >/dev/null 2>&1

# Installed only AFTER the seed commit: the hook refuses a diff that adds the rule
# files (they match their own rules), so seeding first is what makes the repo usable.
cp "$HOOK" "$R/.git/hooks/pre-commit"; chmod 755 "$R/.git/hooks/pre-commit"

# --- Planted values, sorted by the scanner ----------------------------------------
CRED_LINES="$SANDBOX/cred-lines.txt"
INFRA_LINES="$SANDBOX/infra-lines.txt"
CLEAN_LINES="$SANDBOX/clean-lines.txt"
: > "$CRED_LINES"; : > "$INFRA_LINES"
printf 'ordinary documentation prose for the positive control.\nnothing sensitive on this line either.\n' > "$CLEAN_LINES"

while IFS= read -r line; do
  case "$line" in \#*|'') continue ;; esac
  line=${line//@@/}   # strip the escape marker — see the fixture header for why it exists
  if printf '%s\n' "$line" | "$SCAN" >/dev/null 2>&1; then
    printf '%s\n' "$line" >> "$CRED_LINES"
  elif printf '%s\n' "$line" | "$SCAN" --infra >/dev/null 2>&1; then
    printf '%s\n' "$line" >> "$INFRA_LINES"
  fi
done < "$PROBE"

# If the fixture ever stopped matching, every case below would stage a clean file and
# report that the hook allowed it — a green suite proving nothing. Fail here instead.
n_cred=$(grep -c . "$CRED_LINES")
n_infra=$(grep -c . "$INFRA_LINES")
[ "$n_cred" -gt 0 ] && rc=0 || rc=1
assert_eq "0. probe fixture yields credential lines" "0" "$rc"
[ "$n_infra" -gt 0 ] && rc=0 || rc=1
assert_eq "0. probe fixture yields infra lines" "0" "$rc"

stage() {  # $1 path inside the repo, $2 file to copy in
  mkdir -p "$R/$(dirname "$1")"
  cp "$2" "$R/$1"
  git -C "$R" add -- "$1" >/dev/null 2>&1
}
unstage_all() {
  git -C "$R" reset -q >/dev/null 2>&1
  git -C "$R" clean -qfd >/dev/null 2>&1
}
run_hook() { ( cd "$R" && ./.git/hooks/pre-commit 2>&1 ); }

# --- Case 1: a staged infra value -> REFUSE, naming the infra rule -----------------
stage "docs/leak.md" "$INFRA_LINES"  # gone-on-purpose: a fixture name staged into a scratch index, never a file in this repo
out="$(run_hook)"; rc=$?
assert_eq "1. staged infra value: exit code" "1" "$rc"
assert_has "1. staged infra value: names the infra rule" "private network / internal infra value in diff" "$out"
unstage_all

# --- Case 2: a staged credential value -> REFUSE, naming the credential rule -------
stage "docs/creds.md" "$CRED_LINES"  # gone-on-purpose: a fixture name staged into a scratch index, never a file in this repo
out="$(run_hook)"; rc=$?
assert_eq "2. staged credential value: exit code" "1" "$rc"
assert_has "2. staged credential value: names the credential rule" "personal data pattern found in diff" "$out"
unstage_all

# --- Case 3: a blocked personal PATH -> REFUSE even though the content is clean.
#     This is the hook's own rule, not the scanner's: no line in the file matches
#     anything, so only the path list can be what refused. ---------------------------
stage "memory/facts/note.md" "$CLEAN_LINES"
out="$(run_hook)"; rc=$?
assert_eq "3. blocked personal path: exit code" "1" "$rc"
assert_has "3. blocked personal path: names the path" "personal path being added/modified: memory/facts/" "$out"
unstage_all

# --- Case 3b: the memory INDEX, which is gitignored and so never reaches an ordinary
#     `git add`. .gitignore is not a guard: `git add -f` ignores it, and a file already
#     tracked from before it was ignored is staged with no flag at all. The index names
#     every fact the owner asked to be remembered, so it gets a path rule of its own. ---
stage "memory/MEMORY.md" "$CLEAN_LINES"
out="$(run_hook)"; rc=$?
assert_eq "3b. blocked memory index: exit code" "1" "$rc"
assert_has "3b. blocked memory index: names the path" "personal path being added/modified: memory/MEMORY.md" "$out"
unstage_all

# --- Case 3c: the tracked TEMPLATE beside it must still be allowed, or the rule above
#     has quietly blocked the one memory file that is meant to ship. --------------------
stage "memory/MEMORY.example.md" "$CLEAN_LINES"
out="$(run_hook)"; rc=$?
assert_eq "3c. memory template still allowed: exit code" "0" "$rc"
unstage_all

# --- Case 4: a clean file -> ALLOW. A guard that refuses everything is as broken as
#     one that refuses nothing; without this case the three above prove nothing. ------
stage "docs/clean.md" "$CLEAN_LINES"  # gone-on-purpose: a fixture name staged into a scratch index, never a file in this repo
out="$(run_hook)"; rc=$?
assert_eq "4. clean file: exit code" "0" "$rc"
assert_has "4. clean file: reports clean" "no-yolo pre-commit: clean" "$out"
unstage_all

# --- Cases 5 & 6: the same two directions through a REAL `git commit`, so the suite
#     proves the hook is wired in as a git hook and not merely that a script exits.
#     Commit count is the evidence: a refusal that still writes a commit is not a
#     refusal. --------------------------------------------------------------------
before=$(git -C "$R" rev-list --count HEAD)
stage "docs/creds2.md" "$CRED_LINES"  # gone-on-purpose: a fixture name staged into a scratch index, never a file in this repo
git -C "$R" commit -q -m "should be refused" >/dev/null 2>&1
rc=$?
[ "$rc" -ne 0 ] && rc=1 || rc=0
assert_eq "5. git commit with a credential value is refused" "1" "$rc"
assert_eq "5. git commit refused: no commit written" "$before" "$(git -C "$R" rev-list --count HEAD)"
unstage_all

stage "docs/clean2.md" "$CLEAN_LINES"  # gone-on-purpose: a fixture name staged into a scratch index, never a file in this repo
git -C "$R" commit -q -m "should be allowed" >/dev/null 2>&1
rc=$?
assert_eq "6. git commit with a clean file is allowed" "0" "$rc"
assert_eq "6. git commit allowed: commit written" "$((before + 1))" "$(git -C "$R" rev-list --count HEAD)"
unstage_all

# --- Case 7: the scanner cannot run -> FAIL CLOSED. The staged file is clean, so a
#     hook that judged by scan output alone would allow this commit blind. ----------
chmod -x "$R/hooks/secret-scan.sh"
stage "docs/clean3.md" "$CLEAN_LINES"  # gone-on-purpose: a fixture name staged into a scratch index, never a file in this repo
out="$(run_hook)"; rc=$?
chmod 755 "$R/hooks/secret-scan.sh"
assert_eq "7. scanner not executable: fails closed" "1" "$rc"
assert_has "7. scanner not executable: says why" "secret-scan.sh missing or not executable" "$out"
unstage_all

printf '\n%-6s  %s\n' RESULT CASE
for r in "${results[@]}"; do printf '%-6s  %s\n' "${r%%|*}" "${r#*|}"; done

if [ "$fail" -eq 0 ]; then
  printf '\nAll asserts passed.\n'
  exit 0
else
  printf '\nSome asserts failed.\n'
  exit 1
fi
