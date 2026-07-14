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
cd "$ROOT"

TMP="$(mktemp -d)"
declare -a TOUCHED=()
restore() {
  for f in "${TOUCHED[@]:-}"; do
    [ -z "$f" ] && continue
    if [ -f "$TMP/$(basename "$f").bak" ]; then
      cp "$TMP/$(basename "$f").bak" "$f"
    else
      rm -f "$f"
    fi
  done
  rm -rf "$TMP"
}
trap restore EXIT

backup() { cp "$1" "$TMP/$(basename "$1").bak"; TOUCHED+=("$1"); }
track_new() { TOUCHED+=("$1"); }

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
cp "$TMP/settings.example.json.bak" settings.example.json

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
cp "$TMP/settings.example.json.bak" settings.example.json

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
cp "$TMP/settings.example.json.bak" settings.example.json

# 6. README format headings
backup docs/README_FORMAT.md
echo '## zz-selftest-heading-that-is-not-in-readme' >> docs/README_FORMAT.md
assert_red "README format headings" "check 6 catches a README missing a required heading"
cp "$TMP/README_FORMAT.md.bak" docs/README_FORMAT.md

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
