#!/usr/bin/env bash
# verify-selftest.sh — proves verify.sh actually FAILS when it should.
#
# Why this exists: three checks in this repo were found silently passing while
# doing nothing (md-check --drift grepped a moved file; skill-audit echoed instead
# of writing; *.test.sh ran nowhere). A check that cannot go red is decoration.
#
# For each check: break the thing it guards, assert verify.sh reports FAIL for it,
# restore. Any check that stays green under sabotage is broken.
#
# Safe by construction: every mutation is backed up to a tempdir and restored via
# an EXIT trap, so a Ctrl-C or a crash still puts the repo back.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || { echo "cannot cd to $ROOT"; exit 1; }

TMP="$(mktemp -d)"
declare -a TOUCHED=()

# A backup is keyed by the file's full path with the slashes flattened, not by its
# basename. Two files in this repo are named pre-commit (hooks/pre-commit and the copy
# at .git/hooks/pre-commit) and a basename key aliased them onto one backup, so
# restoring one would have written the other's contents over it.
key() { printf '%s' "$1" | tr '/' '_'; }

# The mode travels with the backup. `cp` onto an existing file keeps the DESTINATION's
# mode, so a sabotage that runs chmod would survive its own restore: the scanner would
# be left non-executable by a script whose whole purpose is putting the repo back.
restore() {
  for f in "${TOUCHED[@]:-}"; do
    [ -z "$f" ] && continue
    if [ -f "$TMP/$(key "$f").bak" ]; then
      cp "$TMP/$(key "$f").bak" "$f"
      if [ -f "$TMP/$(key "$f").mode" ]; then
        chmod "$(cat "$TMP/$(key "$f").mode")" "$f" 2>/dev/null || true
      fi
    else
      rm -f "$f"
    fi
  done
  rm -rf "$TMP"
}
trap restore EXIT

mode_of() {
  if stat -f '%Lp' "$1" >/dev/null 2>&1; then stat -f '%Lp' "$1"   # BSD, macOS
  else stat -c '%a' "$1"; fi                                        # GNU, Linux
}

backup() {
  cp "$1" "$TMP/$(key "$1").bak"
  mode_of "$1" > "$TMP/$(key "$1").mode" 2>/dev/null || true
  TOUCHED+=("$1")
}
track_new() { TOUCHED+=("$1"); }

# One planted value, lifted from the pinned probe fixture rather than written here.
# A literal credential or private address inside THIS file would be found by the very
# scan these cases sabotage, because verify-selftest.sh is tracked and not excluded
# from it. Adding it to the exclusion list was the alternative and is worse: an
# excluded file is exactly where a real value could hide, which is why the fixtures
# that ARE excluded are pinned by sha256. $1 is the 1-based line to take.
probe_value() {
  grep -v '^#' hooks/tests/infra-scan-probe.txt | grep . | sed -n "$1p" | tr -d '@'
}

# Put ONE file back now, rather than waiting for the EXIT trap. Every sabotage below
# calls this the moment its assert has run, so a later assert never sees an earlier
# sabotage. It goes through the same key() and mode logic the trap uses, so the two
# cannot disagree.
restore_one() {
  cp "$TMP/$(key "$1").bak" "$1"
  [ -f "$TMP/$(key "$1").mode" ] && chmod "$(cat "$TMP/$(key "$1").mode")" "$1" 2>/dev/null
  return 0
}

results=()
selftest_fail=0
# assert that verify.sh emits FAIL for a check whose label matches $1
assert_red() {
  local label="$1" desc="$2"
  local out
  out="$(bash verify.sh 2>&1)"
  if echo "$out" | grep -q "^FAIL.*$label"; then
    results+=("PASS|$desc")
  else
    results+=("BROKEN|$desc — stayed green under sabotage")
    selftest_fail=1
  fi
}

# 0. baseline — everything must be green BEFORE we sabotage anything,
#    otherwise a red below proves nothing.
if bash verify.sh >/dev/null 2>&1; then
  results+=("PASS|baseline: verify.sh green before sabotage")
else
  results+=("BROKEN|baseline: verify.sh already red — fix that first")
  selftest_fail=1
fi

# 1. hook unit tests (*.test.js)
cat > hooks/tests/zz-selftest.test.js <<'EOF'
const { test } = require('node:test');
test('deliberate failure injected by verify-selftest.sh', () => {
  throw new Error('selftest sabotage');
});
EOF
track_new hooks/tests/zz-selftest.test.js
assert_red "hook unit tests" "check 1 catches a failing *.test.js"
rm -f hooks/tests/zz-selftest.test.js

# 1b. hook shell tests (*.test.sh)
cat > hooks/tests/zz-selftest.test.sh <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
track_new hooks/tests/zz-selftest.test.sh
assert_red "hook shell tests" "check 1b catches a failing *.test.sh"
rm -f hooks/tests/zz-selftest.test.sh

# 3. settings.example.json parses
backup settings.example.json
printf '{ this is not json' > settings.example.json
assert_red "settings.example.json parses" "check 3 catches malformed JSON"
restore_one settings.example.json

# 4. quoted ~ in hook commands.
#    Point at a hook that EXISTS, so this trips check 4 only and not check 5 too.
backup settings.example.json
python3 - <<'EOF'
import json, glob, os
p = "settings.example.json"
d = json.load(open(p))
real = os.path.basename(sorted(glob.glob("hooks/*.sh"))[0])
d.setdefault("hooks", {}).setdefault("SessionStart", []).append(
    {"hooks": [{"type": "command", "command": 'bash "~/.claude/hooks/%s"' % real}]}
)
json.dump(d, open(p, "w"), indent=2)
EOF
assert_red 'has a quoted' "check 4 catches a quoted ~ hook path"
restore_one settings.example.json

# 5. hook paths exist
backup settings.example.json
python3 - <<'EOF'
import json
p = "settings.example.json"
d = json.load(open(p))
d.setdefault("hooks", {}).setdefault("SessionStart", []).append(
    {"hooks": [{"type": "command", "command": 'bash "$HOME/.claude/hooks/zz-does-not-exist.sh"'}]}
)
json.dump(d, open(p, "w"), indent=2)
EOF
assert_red "hook paths exist" "check 5 catches a hook path that does not exist"
restore_one settings.example.json

# 7. shellcheck — blocking at warning severity
backup hooks/statusline.sh
printf '\nzz_selftest_unused_var=1\n' >> hooks/statusline.sh
assert_red "shellcheck" "check 7 catches a shellcheck warning"
restore_one hooks/statusline.sh

# 8. secret pattern file — the credential rules live in ONE file now, so deleting it
#    must fail the scan CLOSED. A scanner that reports "clean" with no rules loaded
#    is the exact decoration this self-test exists to catch.
backup hooks/secret-patterns.txt
rm hooks/secret-patterns.txt
assert_red "secret pattern file" "removing hooks/secret-patterns.txt turns the credential scan red instead of passing clean"
restore_one hooks/secret-patterns.txt

# 8. infra pattern file — the private-network rules were the LAST hand-copied pair
#    (hooks/pre-commit's INFRA_PATTERNS and verify.sh's INFRA_SCAN). They now live in
#    one file behind the same scanner, so deleting it must fail the scan CLOSED exactly
#    the way deleting the credential file does.
backup hooks/infra-patterns.txt
rm hooks/infra-patterns.txt
assert_red "infra pattern file" "removing hooks/infra-patterns.txt turns the infra scan red instead of passing clean"
restore_one hooks/infra-patterns.txt

# 2. shell syntax (bash -n) over every tracked .sh
backup hooks/statusline.sh
printf '\nif true; then\n' >> hooks/statusline.sh   # opened, never closed
assert_red "shell syntax" "check 2 catches a shell script that does not parse"
restore_one hooks/statusline.sh

# 6c. setup.sh bash-3.2 clean. Stock macOS ships bash 3.2 and the documented install
#     command is `bash setup.sh`, so a bash-4-only construct hard-blocks every
#     un-provisioned Mac. The check greps for the class; this plants one member of it.
backup setup.sh
printf '\ndeclare -A zz_selftest_map\n' >> setup.sh
assert_red "setup.sh bash-3.2 clean" "check 6c catches a bash-4-only construct"
restore_one setup.sh

# 7b. external references. A tracked file gains an install command for a package that cannot
#     exist, which is exactly the shape of the defect this row was built for: on 2026-08-21 six
#     of seven published references were wrong and one had never existed anywhere.
#     docs/TESTING.md is tracked, carries no scan exclusion, and is restored straight after.
backup docs/TESTING.md
printf '\n```bash\nnpm install -g zz-selftest-package-that-cannot-exist\n```\n' >> docs/TESTING.md
assert_red "external references" "check 7b catches an install command naming an undeclared package"
restore_one docs/TESTING.md

# 7b-manifest. Removing the manifest must fail CLOSED. A guard whose rule file is gone and
#     which then reports "nothing undeclared" is the decoration this whole self-test hunts.
backup hooks/externals.txt
rm hooks/externals.txt
assert_red "external references" "removing hooks/externals.txt turns the row red instead of passing clean"
restore_one hooks/externals.txt

# 8. tracked-content scan. The value goes into a file that is ALREADY TRACKED, so the
#    git index is never touched: `git ls-files` lists it either way and the scanner
#    reads the working tree. Staging a new file instead would leave it in the index if
#    this run were interrupted, and the EXIT trap restores file contents, not the index.
#    docs/TESTING.md is chosen because it is tracked and carries no scan exclusion.
backup docs/TESTING.md
printf '\nzz-selftest: %s\n' "$(probe_value 1)" >> docs/TESTING.md
assert_red "tracked-content scan" "check 8 catches a credential in a tracked file"
restore_one docs/TESTING.md

# 8a. infra scan NEGATIVE control. The clean fixture is the one that must produce no
#     match; planting a real infra value in it makes the scan cry wolf. Its pinned hash
#     is updated in the same breath, because the hash row fails FIRST and would
#     short-circuit the control this case exists to exercise. Both files are backed up,
#     so an interrupted run restores the fixture and its pin together.
backup hooks/tests/infra-scan-clean.txt
backup hooks/tests/infra-scan-probe.sha256
probe_value 2 >> hooks/tests/infra-scan-clean.txt
python3 - <<'EOF'
import hashlib, pathlib
f = "hooks/tests/infra-scan-clean.txt"
h = hashlib.sha256(pathlib.Path(f).read_bytes()).hexdigest()
p = pathlib.Path("hooks/tests/infra-scan-probe.sha256")
p.write_text("\n".join(
    f"{h}  {f}" if line.strip().endswith(f) else line
    for line in p.read_text().split("\n")
))
EOF
assert_red "infra scan negative control" "check 8a catches the scan crying wolf on a clean value"
restore_one hooks/tests/infra-scan-clean.txt
restore_one hooks/tests/infra-scan-probe.sha256

# 8a-pin. The fixtures are excluded from the leak scan, so their contents are pinned:
#     they are the one place a real value could hide from the scan that reads everything.
#     Here the fixture changes and the pin does NOT, which is the case the pin exists for.
backup hooks/tests/infra-scan-probe.txt
printf '\n# zz-selftest edit, contents irrelevant: the pin compares hashes\n' >> hooks/tests/infra-scan-probe.txt
assert_red "infra scan probe fixtures changed" "the pinned hash catches an edited scan fixture"
restore_one hooks/tests/infra-scan-probe.txt

# 8b. pre-commit scan positive control. Taking the executable bit off the scanner makes
#     every invocation fail to run, which must read as "unfalsifiable", never as "clean".
#     The mode is restored by restore_one and by the EXIT trap, both of which now carry
#     modes; a `cp` alone would have left the scanner non-executable.
backup hooks/secret-scan.sh
chmod -x hooks/secret-scan.sh
assert_red "pre-commit scan positive control" "check 8b catches a scanner that cannot run"
restore_one hooks/secret-scan.sh
[ -x hooks/secret-scan.sh ] || { echo "BROKEN: hooks/secret-scan.sh left non-executable"; selftest_fail=1; }

# 8c. the INSTALLED hook is the TRACKED hook. setup.sh copies hooks/pre-commit into
#     .git/hooks/pre-commit, so the two drift the moment the tracked one is edited and
#     nothing re-runs setup.sh. On the machine that wrote the original check the copy was
#     frozen for weeks and a planted token committed cleanly.
if [ -f .git/hooks/pre-commit ]; then
  backup .git/hooks/pre-commit
  printf '\n# zz-selftest drift\n' >> .git/hooks/pre-commit
  assert_red "installed pre-commit matches tracked source" "check 8c catches an installed hook that has drifted from the tracked one"
  restore_one .git/hooks/pre-commit
  [ -x .git/hooks/pre-commit ] || { echo "BROKEN: .git/hooks/pre-commit left non-executable"; selftest_fail=1; }
else
  results+=("SKIP|check 8c not exercised: no .git/hooks/pre-commit installed (run setup.sh)")
fi

# final: repo must be green again once everything is restored
restore_ok=1
bash verify.sh >/dev/null 2>&1 || restore_ok=0
[ "$restore_ok" = 1 ] && results+=("PASS|repo restored clean after sabotage") \
                      || { results+=("BROKEN|repo NOT restored — inspect $TMP"); selftest_fail=1; }

printf '\n%-7s  %s\n' RESULT 'SELF-TEST (does the check go red when it should?)'
for r in "${results[@]}"; do printf '%-7s  %s\n' "${r%%|*}" "${r#*|}"; done
echo
[ "$selftest_fail" = 0 ] && echo "All checks proved they can fail." \
                         || echo "One or more checks CANNOT fail — they are decoration. Fix or delete them."
exit "$selftest_fail"
