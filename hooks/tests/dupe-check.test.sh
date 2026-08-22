#!/usr/bin/env bash
# Contract for hooks/dupe-check.sh, the Duplicate scan gate stage 5 runs.
# Run: bash hooks/tests/dupe-check.test.sh
#
# EVERY CASE RUNS IN ITS OWN THROWAWAY GIT REPOSITORY. Both passes read the tree from the
# current directory, so a fixture that shared this repo would search this repo, and its
# results would change every time anyone committed anything here.
#
# THE POINT OF THE FILE IS THE THREE-WAY EXIT CODE. 0 and 1 are both real answers; 3 says the
# gate could not run and the build must flag rather than pass. The cases that matter most are
# the ones where a broken run could look like a clean one: a ref that does not exist, a file
# that is not there, a directory outside any repository, and jscpd missing from PATH.
#
# jscpd IS OPTIONAL. Its cases are skipped, loudly, when the binary is absent, because a
# suite that silently drops half its coverage on a machine without a tool is how coverage
# disappears. The name pass has no such dependency and is tested unconditionally.
#
# BASH-3.2 CLEAN (stock macOS): no associative arrays, no line-reading builtins, no
# case-changing expansions.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO/hooks/dupe-check.sh"

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
skip() { results+=("SKIP|$1"); }

BOX="$(mktemp -d)"
trap 'rm -rf "$BOX"' EXIT

# A fresh repository with one committed file that defines fooBar, so every case starts from
# the same known tree. Prints its path.
new_repo() {
  local d
  d="$(mktemp -d "$BOX/repo.XXXXXX")"
  (
    cd "$d" || exit 1
    git init -q .
    git config user.email dupe@test.invalid
    git config user.name dupe-test
    printf 'function fooBar(x) {\n  return x + 1;\n}\n' > existing.js
    git add -A
    git commit -qm baseline
  ) >/dev/null 2>&1
  printf '%s\n' "$d"
}

# An 8-line block long enough to clear the shipped minTokens of 50.
write_block() {  # $1 path, $2 the function name
  cat > "$1" <<EOF
function $2(input) {
  const result = [];
  for (let i = 0; i < input.length; i++) {
    if (input[i] % 2 === 0) { result.push(input[i] * 3); }
    else { result.push(input[i] + 7); }
  }
  return result.filter(Boolean).map((x) => x + 1);
}
EOF
}

# Output lands in $OUT and the status in $RC, both set in THIS shell. Capturing the run with
# $(...) instead would put the hook in a subshell, where every status it set was discarded and
# every exit-code assert silently compared 0 against 0.
OUT="$BOX/out"
RC=0
run_in() {  # $1 dir, rest: hook arguments
  local d="$1"; shift
  ( cd "$d" && bash "$HOOK" "$@" ) > "$OUT" 2>&1
  RC=$?
}

HAVE_JSCPD=0
command -v jscpd >/dev/null 2>&1 && HAVE_JSCPD=1

# ── (a) a copied block ───────────────────────────────────────────────────────
D="$(new_repo)"
write_block "$D/copy-a.js" alpha
sed 's/alpha/beta/' "$D/copy-a.js" > "$D/copy-b.js"
if [ "$HAVE_JSCPD" -eq 1 ]; then
  run_in "$D" --since HEAD
  check "a copied 8-line block exits 1" "1" "$RC"
  check "a copied 8-line block is reported as a clone" "1" \
    "$(grep -c 'Clone found' "$OUT")"
else
  skip "a copied 8-line block (jscpd absent)"
  skip "a copied 8-line block is reported as a clone (jscpd absent)"
fi

# ── (b) a repeated name ──────────────────────────────────────────────────────
# The duplicate arrives in a file git has never seen, which is the ordinary case mid-build.
# An untracked file has no diff, so a hook reading only the diff would report nothing here.
D="$(new_repo)"
printf 'function fooBar(y) {\n  return y * 2;\n}\n' > "$D/new.js"
run_in "$D" --since HEAD
check "a new function whose name already exists exits 1" "1" "$RC"
check "it names the symbol and where it already lives" "DUPLICATE SYMBOL: fooBar already at existing.js:1" \
  "$(grep '^DUPLICATE SYMBOL' "$OUT")"

# The same finding must survive the change being committed, or the gate would go quiet on
# exactly the work that is about to ship.
( cd "$D" && git add -A && git commit -qm added ) >/dev/null 2>&1
run_in "$D" --since HEAD~1
check "the finding survives the change being committed" "1" "$RC"

# Whole-file mode, no ref at all.
D="$(new_repo)"
printf 'function fooBar(y) {\n  return y * 2;\n}\n' > "$D/new.js"
run_in "$D" new.js
check "named files with no ref scan the whole file" "1" "$RC"
check "named-file mode names the same location" "DUPLICATE SYMBOL: fooBar already at existing.js:1" \
  "$(grep '^DUPLICATE SYMBOL' "$OUT")"

# --symbols, the form the plan-approval reuse search uses. It has no file of its own, so it
# reports every definition in the tree.
D="$(new_repo)"
run_in "$D" --symbols fooBar
check "--symbols finds an existing definition" "1" "$RC"
check "--symbols names it" "DUPLICATE SYMBOL: fooBar already at existing.js:1" \
  "$(grep '^DUPLICATE SYMBOL' "$OUT")"
run_in "$D" --symbols nothingDefinesThis
check "--symbols on a name nobody defines is clean" "0" "$RC"

# A name that means something different in every file holding one is noise, not a finding.
D="$(new_repo)"
printf 'function main() {\n  return 0;\n}\n' > "$D/existing.js"
( cd "$D" && git add -A && git commit -qm m ) >/dev/null 2>&1
printf 'function main() {\n  return 1;\n}\n' > "$D/new.js"
run_in "$D" --since HEAD
check "a name like main is not reported" "0" "$RC"

# ── (c) a clean pair ─────────────────────────────────────────────────────────
D="$(new_repo)"
write_block "$D/clean-a.js" gammaOne
printf 'function deltaTwo(n) {\n  return n - 1;\n}\n' > "$D/clean-b.js"
run_in "$D" --since HEAD
check "two unrelated new files exit 0" "0" "$RC"
check "and report no duplicate symbol" "0" "$(grep -c '^DUPLICATE SYMBOL' "$OUT")"

# ── (d) jscpd off PATH ───────────────────────────────────────────────────────
# The name pass has to keep running, and the message has to say the other one did not. A gate
# that went quiet about its missing half would report a half-run as a full one.
D="$(new_repo)"
write_block "$D/copy-a.js" alpha
sed 's/alpha/beta/' "$D/copy-a.js" > "$D/copy-b.js"
printf 'function fooBar(y) {\n  return y * 2;\n}\n' > "$D/new.js"
( cd "$D" && PATH=/usr/bin:/bin bash "$HOOK" --since HEAD ) > "$OUT" 2>&1
rc=$?
check "jscpd absent still reports the name finding" "1" "$rc"
check "jscpd absent says so" "jscpd: did not run, not installed" \
  "$(grep '^jscpd:' "$OUT")"
check "jscpd absent still runs the name pass" "DUPLICATE SYMBOL: fooBar already at existing.js:1" \
  "$(grep '^DUPLICATE SYMBOL' "$OUT")"

# ── could not run: every one of these is 3, never 0 and never 1 ──────────────
D="$(new_repo)"
run_in "$D" --since no-such-ref-anywhere
check "a ref that does not exist" "3" "$RC"
run_in "$D" not-a-file.js
check "a file that is not there" "3" "$RC"
run_in "$D"
check "no file and no ref" "3" "$RC"
run_in "$D" --symbols
check "--symbols with no name" "3" "$RC"
run_in "$D" --since
check "--since with no ref" "3" "$RC"
run_in "$D" --since HEAD --symbols
check "two modes at once" "3" "$RC"
run_in "$D" --nonsense
check "an unknown option" "3" "$RC"

OUTSIDE="$(mktemp -d)"
run_in "$OUTSIDE" --since HEAD
rm -rf "$OUTSIDE"
check "a directory outside any repository" "3" "$RC"

# ── the shipped config ───────────────────────────────────────────────────────
# jscpd 5 parses a config with unknown keys without complaint and then ignores them, so a
# snake_case key would leave the gate running on jscpd's defaults while looking configured.
if [ -f "$REPO/.jscpd.json" ]; then rc=0; else rc=1; fi
check "the shipped .jscpd.json exists" "0" "$rc"
if grep -qE '"minTokens"' "$REPO/.jscpd.json" && grep -qE '"minLines"' "$REPO/.jscpd.json"; then rc=0; else rc=1; fi
check "its keys are camelCase, which is the casing jscpd reads" "0" "$rc"
python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$REPO/.jscpd.json" >/dev/null 2>&1
check "it is valid JSON" "0" "$?"

printf '\n%-6s  %s\n' RESULT CASE
for r in "${results[@]}"; do printf '%-6s  %s\n' "${r%%|*}" "${r#*|}"; done

if [ "$fail" -eq 0 ]; then
  printf '\nAll asserts passed.\n'
  exit 0
else
  printf '\nSome asserts failed.\n'
  exit 1
fi
