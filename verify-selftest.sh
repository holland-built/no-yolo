#!/usr/bin/env bash
# Proves verify.sh actually goes RED when it should.
#
# Rewritten from a blank page 2026-08-22 (machinery rebuild), and deliberately
# AFTER verify.sh, never alongside it. Rewriting a checker and its own referee
# together lets the two drift into agreeing on the same defect and calling it
# green; a cross-model review of this rebuild named that as the blocking risk.
# The order used was: freeze the old self-test, rewrite verify.sh, make the OLD
# self-test pass against the NEW verify.sh (24 of 24 on 2026-08-22), and only
# then rewrite this file against the verify.sh those 24 cases had just judged.
#
# WHY IT EXISTS. Three rows of this suite were once found silently passing while
# doing nothing at all, and the file reported 14 PASS while 8 rows could not go
# red under any circumstance. A row nobody has watched fail is decoration.
#
# HOW EACH CASE WORKS. Break the thing a row guards, assert verify.sh prints
# FAIL for that row BY NAME, put it back. A row that stays green under sabotage
# is reported BROKEN, and this script exits non-zero.
#
# SAFE BY CONSTRUCTION. Every mutation is backed up first and restored twice
# over: immediately after its assertion, and again by an EXIT trap, so a crash
# or a Ctrl-C still puts the tree back. The backup carries the file's MODE as
# well, because `cp` onto an existing file keeps the DESTINATION's mode, so a
# case that runs chmod would otherwise survive its own restore.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || { echo "cannot cd to $ROOT"; exit 1; }

STASH="$(mktemp -d)"
touched=()

# Keyed by full path with slashes flattened, never by basename: two files here
# are called pre-commit (hooks/pre-commit and .git/hooks/pre-commit) and a
# basename key aliased them onto one backup, so restoring either wrote the
# other's contents over it.
slot() { printf '%s' "$1" | tr '/' '_'; }

mode_of() {
  if stat -f '%Lp' "$1" >/dev/null 2>&1; then stat -f '%Lp' "$1"   # BSD, macOS
  else stat -c '%a' "$1"; fi                                       # GNU, Linux
}

save() {
  cp "$1" "$STASH/$(slot "$1").bak"
  mode_of "$1" > "$STASH/$(slot "$1").mode" 2>/dev/null || true
  touched+=("$1")
}
save_new() { touched+=("$1"); }   # a file the case CREATES: restore means delete

put_back() {
  [ -f "$STASH/$(slot "$1").bak" ] || return 0
  cp "$STASH/$(slot "$1").bak" "$1"
  [ -f "$STASH/$(slot "$1").mode" ] && chmod "$(cat "$STASH/$(slot "$1").mode")" "$1" 2>/dev/null
  return 0
}

restore_all() {
  for f in "${touched[@]:-}"; do
    [ -z "$f" ] && continue
    if [ -f "$STASH/$(slot "$f").bak" ]; then put_back "$f"; else rm -f "$f"; fi
  done
  rm -rf "$STASH"
}
trap restore_all EXIT

results=()
broken=0

# Assert verify.sh emits a FAIL line containing $1. Rows are matched by NAME,
# which is why verify.sh's FAIL labels must open with the same words as their
# PASS labels; a row whose two outcomes read differently cannot be asserted.
expect_red() {
  local label="$1" desc="$2" out
  out="$(bash verify.sh 2>&1)"
  if printf '%s' "$out" | grep -q "^FAIL.*$label"; then
    results+=("PASS|$desc")
  else
    results+=("BROKEN|$desc — stayed green under sabotage")
    broken=1
  fi
}

# The inverse: the row must stay GREEN. Used only where a green result is itself
# the claim worth proving, such as an escape hatch that has to keep working.
expect_green() {
  local label="$1" desc="$2" out
  out="$(bash verify.sh 2>&1)"
  if printf '%s' "$out" | grep -q "^FAIL.*$label"; then
    results+=("BROKEN|$desc — went red when it should not have")
    broken=1
  else
    results+=("PASS|$desc")
  fi
}

# One planted value, lifted from the pinned fixture rather than written here. A
# literal credential or private address inside THIS file would be found by the
# very scan these cases sabotage, since this file is tracked and not excluded
# from it. Adding it to the exclusion list is the alternative and is worse: an
# excluded file is exactly where a real value could hide, which is why the ones
# that ARE excluded are sha256-pinned. $1 is the 1-based line to take.
planted() {
  grep -v '^#' hooks/tests/infra-scan-probe.txt | grep . | sed -n "$1p" | tr -d '@'
}

# Sabotage paths are assembled at run time rather than written as literals,
# because a literal nonexistent path in this tracked file is itself a dangling
# reference, and the dangling-reference row would then flag the file that tests
# it. The old version needed a gone-on-purpose marker on each such line; built
# this way, it needs none.
GHOST_MD="docs/zz-$(printf 'selftest')-absent.md"
GHOST_SH="hooks/zz-$(printf 'selftest')-absent.sh"
# The two suite files a case below creates, named the same way and for the same
# reason: written as literals they are dangling references in a tracked file,
# and the row that hunts those would flag the file that proves it works.
TMP_JS="hooks/tests/zz$(printf 'selftest').test.js"
TMP_SH="hooks/tests/zz$(printf 'selftest').test.sh"

# ── 0. baseline ─────────────────────────────────────────────────────────────
# Everything must be green BEFORE anything is broken, or a red below proves
# nothing about the sabotage that supposedly caused it.
if bash verify.sh >/dev/null 2>&1; then
  results+=("PASS|baseline: verify.sh green before any sabotage")
else
  results+=("BROKEN|baseline: verify.sh is ALREADY red — fix that before reading anything below")
  broken=1
fi

# ── the two test-suite rows ─────────────────────────────────────────────────
cat > "$TMP_JS" <<'JS'
const { test } = require('node:test');
test('deliberate failure injected by verify-selftest.sh', () => {
  throw new Error('selftest sabotage');
});
JS
save_new "$TMP_JS"
expect_red "hook unit tests" "a failing *.test.js turns the unit-test row red"
rm -f "$TMP_JS"

cat > "$TMP_SH" <<'SH'
#!/usr/bin/env bash
exit 1
SH
save_new "$TMP_SH"
expect_red "hook shell tests" "a failing *.test.sh turns the shell-test row red"
rm -f "$TMP_SH"

# ── syntax and config ───────────────────────────────────────────────────────
save hooks/statusline.sh
printf '\nif true; then\n' >> hooks/statusline.sh        # opened, never closed
expect_red "shell syntax" "a script that does not parse turns the syntax row red"
put_back hooks/statusline.sh

save hooks/statusline.sh
printf '\nzz_selftest_unused=1\n' >> hooks/statusline.sh
expect_red "shellcheck" "a shellcheck warning turns the lint row red"
put_back hooks/statusline.sh

save settings.example.json
printf '{ this is not json' > settings.example.json
expect_red "settings.example.json parses" "malformed JSON turns the template row red"
put_back settings.example.json

# A quoted ~ pointing at a hook that EXISTS, so this trips the quoting row only
# and not the missing-path row beside it.
save settings.example.json
python3 - <<'PY'
import json, glob, os
p = "settings.example.json"
d = json.load(open(p))
real = os.path.basename(sorted(glob.glob("hooks/*.sh"))[0])
d.setdefault("hooks", {}).setdefault("SessionStart", []).append(
    {"hooks": [{"type": "command", "command": 'bash "~/.claude/hooks/%s"' % real}]}
)
json.dump(d, open(p, "w"), indent=2)
PY
expect_red 'has a quoted' "a quoted ~ in a hook command turns its row red"
put_back settings.example.json

save settings.example.json
GHOST_HOOK="${GHOST_SH#hooks/}" python3 - <<'PY'
import json, os
p = "settings.example.json"
d = json.load(open(p))
cmd = 'bash "$HOME/.claude/hooks/%s"' % os.environ["GHOST_HOOK"]
d.setdefault("hooks", {}).setdefault("SessionStart", []).append(
    {"hooks": [{"type": "command", "command": cmd}]}
)
json.dump(d, open(p, "w"), indent=2)
PY
expect_red "hook paths exist" "a wired hook that is not on disk turns its row red"
put_back settings.example.json

save setup.sh
printf '\ndeclare -A zz_selftest_map\n' >> setup.sh
expect_red "setup.sh bash-3.2 clean" "a bash-4-only construct turns the portability row red"
put_back setup.sh

# ── external names ──────────────────────────────────────────────────────────
# docs/TESTING.md is tracked and carries no scan exclusion, so it is the safe
# host for both of these. The shape is the one that shipped for real: an install
# command naming a package that cannot exist.
save docs/TESTING.md
printf '\n```bash\nnpm install -g zz-selftest-package-that-cannot-exist\n```\n' >> docs/TESTING.md
expect_red "external references" "an install command naming an undeclared package turns the row red"
put_back docs/TESTING.md

# The manifest going missing must fail CLOSED. A guard whose rule file is gone,
# reporting "nothing undeclared", is the decoration this whole file hunts.
save hooks/externals.txt
rm hooks/externals.txt
expect_red "external references" "a missing externals manifest fails closed instead of passing clean"
put_back hooks/externals.txt

# ── leak scanning ───────────────────────────────────────────────────────────
# Each rule file gone must refuse the scan, not scan with nothing loaded.
save hooks/secret-patterns.txt
rm hooks/secret-patterns.txt
expect_red "secret pattern file" "a missing credential rule file fails the scan closed"
put_back hooks/secret-patterns.txt

save hooks/infra-patterns.txt
rm hooks/infra-patterns.txt
expect_red "infra pattern file" "a missing infra rule file fails the scan closed"
put_back hooks/infra-patterns.txt

# A planted credential in a file that is ALREADY TRACKED, so the git index is
# never touched: ls-files lists it either way and the scanner reads the working
# tree. Staging a new file instead would leave it in the index if this run were
# interrupted, and the trap restores contents, not the index.
save docs/TESTING.md
printf '\nzz-selftest: %s\n' "$(planted 1)" >> docs/TESTING.md
expect_red "tracked-content scan" "a credential in a tracked file turns the content row red"
put_back docs/TESTING.md

# The NEGATIVE control. The clean fixture is the one that must produce no match,
# so planting a real infra value in it makes the scan cry wolf. Its pinned hash
# is updated in the same breath, because the hash row fails FIRST and would
# otherwise short-circuit the control this case exists to exercise.
save hooks/tests/infra-scan-clean.txt
save hooks/tests/infra-scan-probe.sha256
planted 2 >> hooks/tests/infra-scan-clean.txt
python3 - <<'PY'
import hashlib, pathlib
f = "hooks/tests/infra-scan-clean.txt"
h = hashlib.sha256(pathlib.Path(f).read_bytes()).hexdigest()
p = pathlib.Path("hooks/tests/infra-scan-probe.sha256")
p.write_text("\n".join(
    f"{h}  {f}" if line.strip().endswith(f) else line
    for line in p.read_text().split("\n")
))
PY
expect_red "infra scan negative control" "a clean-fixture value that now matches turns the cry-wolf row red"
put_back hooks/tests/infra-scan-clean.txt
put_back hooks/tests/infra-scan-probe.sha256

# The fixtures are excluded from the leak scan, so they are the one place a real
# value could hide. Here the fixture changes and the pin does NOT, which is the
# case the pin exists for.
save hooks/tests/infra-scan-probe.txt
printf '\n# zz-selftest edit; contents irrelevant, the pin compares hashes\n' >> hooks/tests/infra-scan-probe.txt
expect_red "infra scan probe fixtures changed" "an edited fixture is caught by its pinned hash"
put_back hooks/tests/infra-scan-probe.txt

# Taking the executable bit off the scanner makes every invocation fail to run,
# which must read as "unfalsifiable", never as "clean".
save hooks/secret-scan.sh
chmod -x hooks/secret-scan.sh
expect_red "pre-commit scan positive control" "a scanner that cannot run turns the commit-blocking control red"
put_back hooks/secret-scan.sh
[ -x hooks/secret-scan.sh ] || { echo "BROKEN: hooks/secret-scan.sh left non-executable"; broken=1; }

# ── the installed hook ──────────────────────────────────────────────────────
# setup.sh COPIES hooks/pre-commit into .git/hooks, so the two drift the moment
# the tracked one is edited and nothing re-runs setup.sh. On the machine that
# first needed this row the copy was frozen for weeks and a planted token
# committed cleanly. A CI checkout has no such file, so the case reports SKIP
# rather than silently proving nothing.
if [ -f .git/hooks/pre-commit ]; then
  save .git/hooks/pre-commit
  printf '\n# zz-selftest drift\n' >> .git/hooks/pre-commit
  expect_red "installed pre-commit matches tracked source" "an installed hook that has drifted turns its row red"
  put_back .git/hooks/pre-commit
  [ -x .git/hooks/pre-commit ] || { echo "BROKEN: .git/hooks/pre-commit left non-executable"; broken=1; }
else
  results+=("SKIP|installed-hook drift not exercised: no .git/hooks/pre-commit here (run setup.sh)")
fi

# ── references and counts ───────────────────────────────────────────────────
save docs/TESTING.md
printf '\nSee `%s` for details.\n' "$GHOST_MD" >> docs/TESTING.md
expect_red "dangling references" "a tracked .md citing a file that is not on disk turns the row red"
put_back docs/TESTING.md

# The .sh half of that row, which the .md-only version could not see. This is
# the exact shape that hid a deleted skill inside three shell files for weeks.
save hooks/statusline.sh
printf '\n# see %s for the details\n' "$GHOST_SH" >> hooks/statusline.sh
expect_red "dangling references" "a tracked .sh naming a script that is not on disk turns the row red"
put_back hooks/statusline.sh

# The escape hatch must still work, or SHIP.md's history sections could never
# pass and the marker would be quietly dead. The SAME dangling reference, on a
# line that carries the marker, has to stay GREEN. This is the one case here
# whose green result is the claim being proved.
save docs/TESTING.md
printf '\nOnce at `%s`, deleted since. <!-- gone-on-purpose -->\n' "$GHOST_MD" >> docs/TESTING.md
expect_green "dangling references" "the gone-on-purpose marker still exempts its own line"
put_back docs/TESTING.md

# Three ways the README inventory can be wrong, and only the first is a count.
save README.md
python3 - <<'PY'
import pathlib
p = pathlib.Path("README.md")
p.write_text(p.read_text().replace("| `/eli5` |", "| `/zz-selftest-absent` |\n| `/eli5` |", 1))
PY
expect_red "README skills inventory" "a table row for a skill that does not exist turns the row red"
put_back README.md

# The case a COUNT cannot catch, and the reason the row compares NAMES: one real
# skill renamed leaves the number unchanged while two rows are wrong.
save README.md
python3 - <<'PY'
import pathlib
p = pathlib.Path("README.md")
p.write_text(p.read_text().replace("| `/handoff` |", "| `/zz-selftest-renamed` |", 1))
PY
expect_red "README skills inventory" "a swapped skill name that leaves the count correct turns the row red"
put_back README.md

save README.md
python3 - <<'PY'
import pathlib
p = pathlib.Path("README.md")
p.write_text(p.read_text().replace("There are six.", "There are nine.", 1))
PY
expect_red "README skills inventory" "a spelled count disagreeing with the table turns the row red"
put_back README.md

# ── everything back ─────────────────────────────────────────────────────────
if bash verify.sh >/dev/null 2>&1; then
  results+=("PASS|the tree is green again with every sabotage undone")
else
  results+=("BROKEN|the tree did NOT come back green — inspect $STASH before it is removed")
  broken=1
fi

printf '\n%-7s  %s\n' RESULT 'SELF-TEST (does the row go red when it should?)'
for r in "${results[@]}"; do printf '%-7s  %s\n' "${r%%|*}" "${r#*|}"; done
echo
if [ "$broken" = 0 ]; then
  echo "Every row proved it can fail."
else
  echo "One or more rows CANNOT fail. They are decoration: fix them or delete them."
fi
exit "$broken"
