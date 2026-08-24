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

# ── refuse to run beside anything it could destroy ──────────────────────────
# This script backs a file up, breaks it, and puts it back from that backup some
# seconds later. Anything edited inside that window is overwritten by the backup,
# silently and with no git object to recover from.
#
# That is not hypothetical. On 2026-08-23 a run of this script overlapped an
# editing session in the same checkout and reverted eight tracked files to the
# contents they had when the run started, including a rename. The work survived
# only because it was still legible in a transcript.
#
# So: a clean tree, and one run at a time. On a clean tree `git status` after a
# crash names exactly what was planted and nothing else, which is what makes the
# leftovers recoverable at all.
#
# Fail CLOSED. If git cannot answer, the audit this relies on does not exist, so
# there is no safe way to proceed.
if ! command -v git >/dev/null 2>&1; then
  echo "verify-selftest: git not found, and this script needs it to prove the tree came back. Refusing."
  exit 1
fi
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "verify-selftest: $ROOT is not a git work tree, so sabotage would be unrecoverable. Refusing."
  exit 1
fi
if ! dirty="$(git status --porcelain 2>/dev/null)"; then
  echo "verify-selftest: 'git status' failed, so the tree state is unknown. Refusing."
  exit 1
fi
if [ -n "$dirty" ] && [ "${SELFTEST_ALLOW_DIRTY:-0}" != 1 ]; then
  echo "verify-selftest: the working tree is dirty. This script rewrites tracked files from"
  echo "backups taken at its own start, so anything below would be reverted to its current"
  echo "contents and any edit made while it runs would be lost outright:"
  printf '%s\n' "$dirty" | sed 's/^/    /'
  echo
  echo "Commit or stash first. To override knowingly: SELFTEST_ALLOW_DIRTY=1 bash verify-selftest.sh"
  exit 1
fi

# One at a time. Two overlapping runs back up each other's sabotage and restore
# it as though it were the real file. mkdir is the atomic test-and-set here.
LOCK="$ROOT/.selftest.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  echo "verify-selftest: $LOCK exists, so another run is in progress or one died."
  echo "If nothing is running, remove it: rmdir $LOCK"
  exit 1
fi

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
}

# Prove the restore worked, rather than assuming it. Checked against the backups
# and not against `git status`, for two reasons: `.git/hooks/pre-commit` is
# sabotaged too and lives outside the work tree where git cannot see it, and a
# file created by a case is untracked, so `git checkout` would never remove it.
# Only paths this script recorded are judged, so an unrelated edit elsewhere is
# never mistaken for leftover sabotage.
audit_restore() {
  local f leftover=0
  for f in "${touched[@]:-}"; do
    [ -z "$f" ] && continue
    if [ -f "$STASH/$(slot "$f").bak" ]; then
      if ! cmp -s "$STASH/$(slot "$f").bak" "$f"; then
        echo "SABOTAGE LEFT BEHIND: $f does not match its backup"
        leftover=1
      elif [ -f "$STASH/$(slot "$f").mode" ] && [ "$(mode_of "$f")" != "$(cat "$STASH/$(slot "$f").mode")" ]; then
        echo "SABOTAGE LEFT BEHIND: $f has the wrong mode"
        leftover=1
      fi
    elif [ -e "$f" ]; then
      echo "SABOTAGE LEFT BEHIND: $f was planted by a case and still exists"
      leftover=1
    fi
  done
  return "$leftover"
}

# ONE finalizer. A second `trap ... EXIT` would silently replace this one and
# take the restore with it, so everything that must happen on the way out
# happens here, in order: put the tree back, then check that it went back, then
# release the lock. The exit status can only get worse, never better: a failed
# restore turns a green run red, and never masks a failure the run already had.
finish() {
  local rc=$?
  restore_all
  if ! audit_restore; then
    echo
    echo "verify-selftest: the tree did NOT come back clean. The backups are kept at $STASH."
    echo "Restore the files named above from there, or with 'git checkout --' for tracked ones."
    rmdir "$LOCK" 2>/dev/null
    exit 1
  fi
  rm -rf "$STASH"
  rmdir "$LOCK" 2>/dev/null
  exit "$rc"
}
trap finish EXIT

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

# ── duplicate work ──────────────────────────────────────────────────────────
# Two new files under hooks/, untracked and so read whole by the gate, carrying
# one identical block. The repeated FUNCTION NAME is what makes the row fire
# with git alone, so this case proves the row on a machine with no jscpd too;
# where jscpd is installed the copied block is reported beside it. Paths are
# assembled at run time for the same reason as the ghosts above.
DUPE_A="hooks/zz-$(printf 'selftest')-dupe-a.sh"
DUPE_B="hooks/zz-$(printf 'selftest')-dupe-b.sh"
for dupe_f in "$DUPE_A" "$DUPE_B"; do
  cat > "$dupe_f" <<'SH'
#!/usr/bin/env bash
zz_selftest_dupe_fn() {
  local running=0 step=0
  for step in 1 2 3 4 5 6 7 8; do
    running=$((running + step * 3))
    printf 'step %s of %s, running total %s\n' "$step" 8 "$running"
  done
  return 0
}
SH
  save_new "$dupe_f"
done
expect_red "dupe-check self-scan" "a block copied into two new files turns the duplicate row red"
rm -f "$DUPE_A" "$DUPE_B"

# A tell only VALE catches, never the regexes in hooks/slop-block.sh: the hook
# carries the long dash and the vocabulary count, and this is docs/PROSE.md's
# "Say the fact, not the adjective". Picking a tell both checks know would leave
# the row red either way and prove nothing about vale. Written as a plain
# sentence rather than a table row, because styles/NoYolo/Adjective.yml is
# scoped ~table so that PROSE.md's own specimen table stays clean.
save docs/TESTING.md
printf '\nThis test runner is production-ready.\n' >> docs/TESTING.md
expect_red "vale prose lint" "an unmeasured adjective in a tracked .md turns the prose row red"
put_back docs/TESTING.md

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
# The path is asked for rather than spelled, for the reason verify.sh's row now
# gives: inside a worktree `.git` is a file, so the literal path missed a hook
# that was installed and this case reported SKIP while the row itself printed
# nothing at all. Two silences that looked like one expected absence.
INSTALLED_HOOK="$(git rev-parse --git-path hooks/pre-commit 2>/dev/null)"
if [ -n "$INSTALLED_HOOK" ] && [ -f "$INSTALLED_HOOK" ]; then
  save "$INSTALLED_HOOK"
  printf '\n# zz-selftest drift\n' >> "$INSTALLED_HOOK"
  expect_red "installed pre-commit matches tracked source" "an installed hook that has drifted turns its row red"
  put_back "$INSTALLED_HOOK"
  [ -x "$INSTALLED_HOOK" ] || { echo "BROKEN: $INSTALLED_HOOK left non-executable"; broken=1; }
else
  results+=("SKIP|installed-hook drift not exercised: no hook installed at ${INSTALLED_HOOK:-an unresolvable path} (run setup.sh)")
fi

# THE ROW MUST EXIST WHATEVER IT SAYS. The case above proves the row can go red
# where a hook is installed; it cannot prove the row was printed at all, and the
# defect being fixed here was exactly that: no FAIL, no PASS, no WARN, just a
# table one row shorter than it looked. Asserted by name against an untouched
# tree, so it holds on a machine with no hook and inside a worktree alike.
# The output is captured before it is searched, never piped into grep. This file
# runs under `set -o pipefail` and `grep -q` exits the moment it matches, so
# verify.sh takes SIGPIPE and the PIPELINE reports 141: the assertion failed on
# its first run for finding what it was looking for. expect_red above captures
# for the same reason.
row_probe="$(bash verify.sh 2>&1)"
if printf '%s' "$row_probe" | grep -q 'installed pre-commit matches tracked source'; then
  results+=("PASS|the installed-hook row is printed even when it has nothing to compare")
else
  results+=("BROKEN|the installed-hook row printed NOTHING — it vanished from the table instead of reporting")
  broken=1
fi

# The pre-push hook, drift and presence, mirroring the two cases above it. A
# CI checkout has no .git/hooks/pre-push and never pushes, so the drift half
# reports SKIP there rather than proving nothing quietly.
INSTALLED_PUSH="$(git rev-parse --git-path hooks/pre-push 2>/dev/null)"
if [ -n "$INSTALLED_PUSH" ] && [ -f "$INSTALLED_PUSH" ]; then
  save "$INSTALLED_PUSH"
  printf '\n# zz-selftest drift\n' >> "$INSTALLED_PUSH"
  expect_red "installed pre-push matches tracked source" "an installed pre-push that has drifted turns its row red"
  put_back "$INSTALLED_PUSH"
  [ -x "$INSTALLED_PUSH" ] || { echo "BROKEN: $INSTALLED_PUSH left non-executable"; broken=1; }
else
  results+=("SKIP|pre-push drift not exercised: no hook installed at ${INSTALLED_PUSH:-an unresolvable path} (run setup.sh)")
fi

push_probe="$(bash verify.sh 2>&1)"
if printf '%s' "$push_probe" | grep -q 'installed pre-push matches tracked source'; then
  results+=("PASS|the pre-push row is printed even when it has nothing to compare")
else
  results+=("BROKEN|the pre-push row printed NOTHING — it vanished from the table instead of reporting")
  broken=1
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

# The outside-pieces count, which nothing watched until 2026-08-23. Two shapes,
# because the two sides go stale independently: the front page keeps yesterday's
# number, or a piece joins the table and neither sentence is touched. Both had
# already happened, the second of them for a day.
save README.md
python3 - <<'PYEOF'
import pathlib, re
p = pathlib.Path("README.md")
p.write_text(re.sub(r"^\w+ outside pieces", "Nineteen outside pieces", p.read_text(), count=1, flags=re.M))
PYEOF
expect_red "README outside-pieces count" "a front page naming a different number of outside pieces turns the row red"
put_back README.md

save INSTALL.md
python3 - <<'PYEOF'
import pathlib
p = pathlib.Path("INSTALL.md")
lines = p.read_text().split("\n")
for i, line in enumerate(lines):
    if line.startswith("| Piece | Gives |"):
        lines.insert(i + 2, "| `zz-selftest-piece` | nothing | nowhere | nothing changes |")
        break
p.write_text("\n".join(lines))
PYEOF
expect_red "README outside-pieces count" "a piece added to the table while both sentences keep the old number turns the row red"
put_back INSTALL.md

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
