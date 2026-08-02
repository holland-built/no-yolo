#!/usr/bin/env bash
# verify.sh — one-command verification for the no-yolo repo.
# Runs locally (repo at ~/.claude) AND in CI (repo at $GITHUB_WORKSPACE).
# Repo root is derived from this script's own location — never hardcoded.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT" || { echo "cannot cd to $ROOT"; exit 1; }

fail=0
results=()
record() { results+=("$1|$2"); [ "$1" = FAIL ] && fail=1; return 0; }

# 1. hook unit tests (glob form REQUIRED on this node build)
if node --test 'hooks/tests/*.test.js' >/tmp/verify-tests.log 2>&1; then
  record PASS "hook unit tests"
else
  record FAIL "hook unit tests (see /tmp/verify-tests.log)"
fi

# 1b. hook shell tests — check 1's glob is *.test.js only, so *.test.sh ran nowhere.
ok=1
shopt -s nullglob
sh_tests=(hooks/tests/*.test.sh)
for t in "${sh_tests[@]}"; do
  bash "$t" >>/tmp/verify-sh-tests.log 2>&1 || { echo "FAILED: $t"; ok=0; }
done
shopt -u nullglob
if [ "${#sh_tests[@]}" -eq 0 ]; then
  record PASS "hook shell tests (none present)"
elif [ "$ok" = 1 ]; then
  record PASS "hook shell tests (${#sh_tests[@]})"
else
  record FAIL "hook shell tests (see /tmp/verify-sh-tests.log)"
fi

# 2. bash -n over every tracked .sh
ok=1
while IFS= read -r f; do [ -z "$f" ] && continue; bash -n "$f" || ok=0; done < <(git ls-files '*.sh')
[ "$ok" = 1 ] && record PASS "shell syntax (bash -n)" || record FAIL "shell syntax (bash -n)"

# 3. settings.example.json parses
if python3 -c "import json;json.load(open('settings.example.json'))" 2>/dev/null; then
  record PASS "settings.example.json parses"
else
  record FAIL "settings.example.json parses"
fi

# 4. reject quoted "~/.claude/hooks/ (tilde never expands inside double quotes,
#    and hook commands are the only strings in this file that get shell-executed;
#    other quoted "~/... values, e.g. additionalDirectories, are read directly by
#    Claude Code's own config loader, not a shell, so they are out of scope here)
if grep -nE '"~/\.claude/hooks/' settings.example.json >/dev/null 2>&1; then
  record FAIL 'settings.example.json has a quoted "~/.claude/hooks/ path — use $HOME (see plan 007)'
else
  record PASS 'no quoted ~ in settings.example.json hook commands'
fi

# 5. every hook path referenced in settings.example.json exists in the CHECKOUT
ok=1
for p in $(grep -oE '(\$HOME|~)/\.claude/hooks/[a-zA-Z0-9._-]+' settings.example.json | sort -u); do
  rel="hooks/${p##*/hooks/}"
  [ -f "$ROOT/$rel" ] || { echo "missing hook: $rel"; ok=0; }
done
[ "$ok" = 1 ] && record PASS "hook paths exist" || record FAIL "hook paths exist"

# 5b. catalog lock current — the menu (STORIES/TAGLINES/.../SKILL_TRIGGERS) still matches the
#     SKILL.md descriptions it was last verified against. Mechanical: pure sha256, no LLM.
if python3 skills/my-skills/catalog_lock.py --check >/tmp/verify-catalog.log 2>&1; then
  record PASS "catalog lock current"
else
  record FAIL "catalog lock stale — run catalog_lock.py --check (see /tmp/verify-catalog.log)"
fi

# 5bb. rendered menus match their sources. The catalog lock hashes the SOURCES, so
#      editing a source and re-locking WITHOUT running regen left this green while
#      RENDERED.md was stale. --check renders in memory and compares; it writes nothing.
if python3 skills/my-skills/regen.py --check >/tmp/verify-regen.log 2>&1; then
  record PASS "rendered menus current"
else
  record FAIL "rendered menus stale — run skills/my-skills/regen.py (see /tmp/verify-regen.log)"
fi

# 5c. local third-party patches still applied (see docs/THIRD_PARTY_SKILLS.md).
#     These live outside git on gitignored symlinks, so `npx skills add` reverts them
#     with no warning. Skip silently where the path doesn't exist (CI, fresh clone) —
#     this guards a local install, not the repo.
IMPROVE_SKILL="$HOME/.agents/skills/improve/SKILL.md"
if [ -f "$IMPROVE_SKILL" ]; then
  if grep -q '^user-invocable: true' "$IMPROVE_SKILL"; then
    record PASS "third-party patches applied"
  else
    record WARN "improve lost its user-invocable patch — /improve is dead; see docs/THIRD_PARTY_SKILLS.md"
  fi
fi

# 6. README format: every '## ' heading in docs/README_FORMAT.md exists in README.md
ok=1
while IFS= read -r h; do grep -qF "$h" README.md || { echo "README missing: $h"; ok=0; }; done < <(grep '^## ' docs/README_FORMAT.md)
[ "$ok" = 1 ] && record PASS "README format headings" || record FAIL "README format headings"

# 6b. README inventory current — the skills table inside README.md's
#     "## Skills inventory" section must be byte-identical to
#     skills/my-skills/RENDERED_FAST.md, so the README copy can't drift from
#     the generated source.
readme_table=$(awk '/^## Skills inventory/{f=1;next} /^## /{f=0} f && /^\|/' README.md)
rendered_table=$(grep '^|' skills/my-skills/RENDERED_FAST.md)
if [ "$readme_table" = "$rendered_table" ]; then
  record PASS "README inventory current"
else
  record FAIL "README inventory current — README Skills inventory table drifted from skills/my-skills/RENDERED_FAST.md"
fi

# 6c. setup.sh bash-3.2 clean — stock macOS ships bash 3.2 and the documented
#     install command is `bash setup.sh`; a bash-4-only construct hard-blocks
#     every un-provisioned Mac (shipped once: declare -A in the preflight).
#     Guards the whole class: declare -A, mapfile/readarray, ${var^^}/${var,,}.
if ! grep -qE 'declare -A|mapfile|readarray|\$\{[a-zA-Z_]+(\^\^|,,)\}' setup.sh && /bin/bash -n setup.sh 2>/dev/null; then
  record PASS "setup.sh bash-3.2 clean"
else
  record FAIL "setup.sh bash-3.2 clean — bash-4-only construct or syntax error (stock Mac bash is 3.2)"
fi

# 7. shellcheck — BLOCKING at warning severity and above.
#    Was warn-only for months: `record WARN` never sets fail=1, so it ran on every
#    CI push (ubuntu-latest ships shellcheck), found real things, and could not fail
#    the build. Nobody read it. A check that cannot go red is decoration.
#    -S warning: errors+warnings block; style/info notes (SC2015 A&&B||C, SC2016
#    single-quoted regexes, SC2013 for-over-grep) are deliberate here and don't.
if command -v shellcheck >/dev/null 2>&1; then
  if git ls-files '*.sh' | xargs shellcheck -S warning >/tmp/verify-shellcheck.log 2>&1; then
    record PASS "shellcheck"
  else
    record FAIL "shellcheck findings (see /tmp/verify-shellcheck.log)"
  fi
else
  record WARN "shellcheck not installed — skipped (CI has it; install locally: brew install shellcheck, or sudo apt install shellcheck)"
fi

# 8. tracked-content scan — CI backstop for the local pre-commit hook
#    (pre-commit only guards staged diffs on machines that ran setup.sh; a
#    --no-verify commit or a pre-setup commit would otherwise publish a leak).
#    The INFRA rules below are the one remaining mirrored pair: they mirror
#    INFRA_PATTERNS in hooks/pre-commit, so if one changes, mirror the other.
#    The CREDENTIAL rules are NOT mirrored anywhere any more — they live in
#    hooks/secret-patterns.txt and are reachable only by executing
#    hooks/secret-scan.sh, which pre-commit, this file and /health all call. No
#    caller holds a copy, so there is no second copy left to drift.
#    Excludes are ONLY files that legitimately document the patterns.
# NO \b IN THIS PATTERN. git grep on macOS does not honour \b — it silently
# matches nothing, so the hostname rules were DEAD on the very machine that does
# the committing: a leaked <host>.home or <host>.internal sailed through the
# scan and only a Linux run would ever have caught it. Meanwhile GNU grep on
# Linux honoured \b and matched a plain pathlib home() call, reporting private
# data in a file that had none. Failing open on one platform and crying wolf on the other, from
# one metacharacter. Explicit character classes behave the same everywhere.
INFRA_SCAN='192\.168\.[0-9]{1,3}\.[0-9]{1,3}|(^|[^0-9])10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}|100\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\.[0-9]{1,3}\.[0-9]{1,3}|(^|[^A-Za-z0-9._-])[a-z0-9-]+\.(internal|corp|lan|home)($|[^A-Za-z0-9-])|(^|[^A-Za-z0-9._-])[a-z0-9-]+\.[a-z0-9-]+\.local($|[^A-Za-z0-9-])'
# hooks/secret-patterns.txt is excluded for the same reason as the probe fixtures, but it
# is NOT pinned by sha256: a file of regexes matches its own rules (the ghp_ rule looks
# exactly like a ghp_ token), and unlike the fixtures it is MEANT to change every time a
# vendor prefix is added. Its compensating control is inside the scanner instead —
# secret-scan.sh lints the file on every single run: bare literals with no metacharacter
# (i.e. a pasted value, not a rule), \b, a rule count under 25, a pattern that will not
# compile, and any credential-shaped string in a COMMENT all make it refuse to scan.
SCAN_EXCLUDE=(':!hooks/pre-commit' ':!verify.sh' ':!skills/health/SKILL.md' ':!.no-yolo-deny.example.txt' ':!hooks/tests/infra-scan-probe.txt' ':!hooks/tests/infra-scan-clean.txt' ':!hooks/secret-patterns.txt')

# The pattern file is the single source for every credential rule in this repo. If it is
# missing, gutted, or holds an uncompilable rule, the scanner refuses to scan at all — this
# row is where that surfaces, and it fails CLOSED.
if "$ROOT/hooks/secret-scan.sh" --check >/tmp/verify-secretscan.log 2>&1; then
  record PASS "secret pattern file healthy"
else
  record FAIL "secret pattern file healthy — pattern file missing/gutted/invalid (see /tmp/verify-secretscan.log)"
fi

# 8a. POSITIVE CONTROL — prove the pattern can still MATCH, before trusting a
#     clean result from it.
#
#     Check 8 below passes when it finds nothing. So does a pattern that has been
#     broken: delete a metacharacter, or run it on a platform whose regex engine
#     reads it differently, and the scan reports "no findings" forever. That is
#     exactly what happened once already — the \b in the hostname rules matched
#     NOTHING under git grep on macOS, so the scan went green on the very machine
#     doing the committing. It was found by hand, not by this file, because nothing
#     here could tell "clean" from "blind".
#
#     The planted values live in hooks/tests/infra-scan-probe.txt rather than
#     inline, because inline values get blocked by the very hook this tests (they
#     did — hooks/pre-checkin refused the first version of this commit, correctly).
#     Those fixture files are excluded from the scans by name and PINNED by sha256,
#     so the one place a real leak could hide is a file that cannot change without
#     failing the build. See their headers.
PROBE_LEAK="hooks/tests/infra-scan-probe.txt"
PROBE_CLEAN="hooks/tests/infra-scan-clean.txt"
PROBE_SUMS="hooks/tests/infra-scan-probe.sha256"

probe_ready=1
for f in "$PROBE_LEAK" "$PROBE_CLEAN" "$PROBE_SUMS"; do
  [ -f "$f" ] || { echo "missing scan-probe fixture: $f"; probe_ready=0; }
done

# shasum on macOS, sha256sum on Linux — neither is present on both.
sha256_of() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  else sha256sum "$1" | awk '{print $1}'; fi
}

if [ "$probe_ready" = 0 ]; then
  record FAIL "infra scan positive control — fixtures missing, so the scan is unfalsifiable"
else
  # The fixtures are excluded from the scan, so they are pinned. A changed fixture
  # is either a deliberate edit (update the hash) or an attempt to hide a value
  # inside the one file the scan does not read.
  sums_ok=1
  for f in "$PROBE_LEAK" "$PROBE_CLEAN"; do
    want=$(awk -v f="$f" '$2==f {print $1}' "$PROBE_SUMS")
    got=$(sha256_of "$f")
    if [ -z "$want" ]; then echo "no pinned hash for $f in $PROBE_SUMS"; sums_ok=0
    elif [ "$want" != "$got" ]; then
      echo "scan-probe fixture CHANGED: $f"
      echo "  pinned $want"
      echo "  actual $got"
      echo "  These files are excluded from the leak scan, so their contents are pinned."
      echo "  If the edit is deliberate, update $PROBE_SUMS."
      sums_ok=0
    fi
  done
  if [ "$sums_ok" = 0 ]; then
    record FAIL "infra scan probe fixtures changed — pinned hash mismatch (see above)"
  else
    # BOTH rule sets get exercised per line, because neither one alone can catch the
    # fixture: the infra values (RFC1918/CGNAT addresses, .internal/.lan hostnames)
    # exist only in $INFRA_SCAN, and the credential values only in the pattern file
    # behind secret-scan.sh. Testing one would silently declare the other's planted
    # lines "missed", so a line counts as caught if EITHER engine sees it.
    scan_probe=$(mktemp -d)
    scan_missed=""
    scan_broke=0
    scan_i=0
    while IFS= read -r probe_line; do
      case "$probe_line" in ''|'#'*) continue ;; esac
      # Strip the `@@` escape marker — see the fixture header for why it exists.
      probe_line=${probe_line//@@/}
      scan_i=$((scan_i + 1))
      printf '%s\n' "$probe_line" > "$scan_probe/leak-$scan_i.txt"
      # git -C so the pathspec is INSIDE the directory git grep runs in: a path
      # outside the repo is rejected, and `--no-index -- -` does not read stdin at
      # all (it always exits 1, reporting every planted value as missed). A control
      # that cannot tell "the scan is blind" from "my probe is broken" is not a
      # control — the first version of this was exactly that.
      scan_hit=0
      if git -C "$scan_probe" grep --no-index -qIE "$INFRA_SCAN" -- "leak-$scan_i.txt" 2>/dev/null; then
        scan_hit=1
      else
        # 0 = matched, 1 = no match, ANYTHING ELSE = the scan could not run. A broken
        # scanner exits non-zero on every line, which reads identically to "the rules
        # are blind" — so it gets its own flag and its own FAIL, never counted as a miss.
        printf '%s\n' "$probe_line" | "$ROOT/hooks/secret-scan.sh" >/dev/null 2>&1
        scan_rc=$?
        case "$scan_rc" in
          0) scan_hit=1 ;;
          1) ;;
          *) scan_broke=1 ;;
        esac
      fi
      if [ "$scan_hit" -eq 0 ] && [ "$scan_broke" -eq 0 ]; then
        scan_missed="${scan_missed}
    MISSED: $probe_line"
      fi
    done < "$PROBE_LEAK"

    scan_false=""
    scan_j=0
    while IFS= read -r probe_line; do
      case "$probe_line" in ''|'#'*) continue ;; esac
      probe_line=${probe_line//@@/}
      scan_j=$((scan_j + 1))
      printf '%s\n' "$probe_line" > "$scan_probe/clean-$scan_j.txt"
      # A clean line is a false positive if EITHER engine fires on it — the negative
      # control has to cover both rule sets too, or half the crying-wolf goes unseen.
      scan_hit=0
      if git -C "$scan_probe" grep --no-index -qIE "$INFRA_SCAN" -- "clean-$scan_j.txt" 2>/dev/null; then
        scan_hit=1
      else
        printf '%s\n' "$probe_line" | "$ROOT/hooks/secret-scan.sh" >/dev/null 2>&1
        scan_rc=$?
        case "$scan_rc" in
          0) scan_hit=1 ;;
          1) ;;
          *) scan_broke=1 ;;
        esac
      fi
      if [ "$scan_hit" -eq 1 ]; then
        scan_false="${scan_false}
    FALSE POSITIVE: $probe_line"
      fi
    done < "$PROBE_CLEAN"
    rm -rf "$scan_probe"

    if [ "$scan_broke" -eq 1 ]; then
      record FAIL "infra scan positive control — hooks/secret-scan.sh could not run (exit >1); the control is unfalsifiable, not clean"
    elif [ "$scan_i" -eq 0 ] || [ "$scan_j" -eq 0 ]; then
      record FAIL "infra scan positive control — fixtures held no usable lines ($scan_i leak, $scan_j clean)"
    elif [ -n "$scan_missed" ]; then
      printf 'infra scan is BLIND to values it must catch (on %s):%s\n' "$(uname -s)" "$scan_missed"
      record FAIL "infra scan positive control — the pattern matches nothing it should"
    elif [ -n "$scan_false" ]; then
      printf 'infra scan flags values it must not (on %s):%s\n' "$(uname -s)" "$scan_false"
      record FAIL "infra scan negative control — the pattern cries wolf"
    else
      record PASS "infra scan positive control ($scan_i planted caught, $scan_j clean ignored)"
    fi
  fi
fi

# git grep exits 0 when it FINDS matches — inverted vs the other checks on purpose, and
# that inversion is exactly how this row used to FAIL OPEN. It was
# `if git grep ...; then FAIL; else PASS; fi`, which routes exit 1 (searched everything,
# found nothing) and exit >=2 (git grep ERRORED — bad pathspec, unreadable tree, a regex
# it would not compile) into the same PASS branch. The scan breaking looked identical to
# the repo being clean. Both halves now capture their status explicitly and PASS is only
# reachable from a real, completed, empty result.
git grep -nIE "$INFRA_SCAN" -- . "${SCAN_EXCLUDE[@]}" >/tmp/verify-scan.log 2>&1
infra_rc=$?

# Credential half: ONE invocation of the same executable pre-commit runs, over the same
# file set. The list is built with a NUL-safe read loop and not xargs — xargs exits 123
# when the child exited 1..125, so "no credentials found" (grep 1) and "the scanner blew
# up" (grep 2) both arrive as 123, which is the fail-open bug above in a different suit.
cred_files=()
while IFS= read -r -d '' f; do cred_files+=("$f"); done < <(git ls-files -z -- . "${SCAN_EXCLUDE[@]}")
cred_rc=1
if [ "${#cred_files[@]}" -eq 0 ]; then
  # bash 3.2 (stock macOS) errors on "${arr[@]}" for an empty array under set -u, so this
  # is guarded — but an empty list is also an anomaly in its own right. A scan of zero
  # files finds zero credentials and that is not a clean bill of health.
  cred_rc=99
else
  "$ROOT/hooks/secret-scan.sh" --files "${cred_files[@]}" >>/tmp/verify-scan.log 2>&1
  cred_rc=$?
fi

if [ "$cred_rc" -eq 99 ]; then
  record FAIL "tracked-content scan — git ls-files returned NO files to scan; the result is empty, not clean"
elif [ "$infra_rc" -ge 2 ] || [ "$cred_rc" -ge 2 ]; then
  record FAIL "tracked-content scan COULD NOT RUN (git grep exit $infra_rc, secret-scan.sh exit $cred_rc) — see /tmp/verify-scan.log"
elif [ "$infra_rc" -eq 0 ]; then
  record FAIL "tracked-content scan — private/infra value in a tracked file (see /tmp/verify-scan.log)"
elif [ "$cred_rc" -eq 0 ]; then
  record FAIL "tracked-content scan — credential in a tracked file (see /tmp/verify-scan.log)"
else
  record PASS "tracked-content scan"
fi

# 8b. The pre-commit hook's own pattern gets the same control.
#     verify.sh's comment says "Patterns mirror INFRA_PATTERNS in hooks/pre-commit
#     — if one changes, mirror the other", and they HAVE diverged: this file's \b
#     was replaced with explicit character classes and pre-commit's was not. That
#     divergence is fine ONLY as long as pre-commit's pattern still works in the
#     engine pre-commit actually uses (grep -EI — BSD grep on macOS, GNU on Linux,
#     which do honour \b where git grep does not). Asserted, not assumed, on
#     whichever platform this runs.
if [ -f hooks/pre-commit ] && [ -f "$PROBE_LEAK" ]; then
  # pre-commit applies BOTH rule sets to the same added lines, so both get controlled —
  # but only the infra half is still text inside pre-commit to parse out. The credential
  # half used to be read the same way (`sed -n 's/^PATTERNS="\(.*\)"$/\1/p'`), and that
  # parse died the instant PATTERNS moved. It has moved: pre-commit step 2 no longer holds
  # a copy of the credential rules, it EXECUTES hooks/secret-scan.sh — the same executable
  # this check calls below. There is nothing to parse and nothing left to go stale.
  # The infra sed parse stays, because those rules are still inline in pre-commit and a
  # rename must still fail loudly rather than quietly control nothing.
  pc_infra=$(sed -n 's/^INFRA_PATTERNS="\(.*\)"$/\1/p' hooks/pre-commit)
  if [ -z "$pc_infra" ]; then
    record FAIL "pre-commit INFRA_PATTERNS not found — the commit-blocking infra scan may have been renamed"
  else
    pc_missed=""
    pc_broke=0
    pc_n=0
    while IFS= read -r probe_line; do
      case "$probe_line" in ''|'#'*) continue ;; esac
      probe_line=${probe_line//@@/}
      pc_n=$((pc_n + 1))
      pc_hit=0
      # The exact invocation pre-commit's step 3 uses on its added lines.
      if printf '%s\n' "$probe_line" | grep -qEI "$pc_infra" 2>/dev/null; then
        pc_hit=1
      else
        # The exact invocation pre-commit's step 2 uses. Same three-way handling as 8a:
        # a scanner that cannot run is a FAIL of its own, never a silent missed line.
        printf '%s\n' "$probe_line" | "$ROOT/hooks/secret-scan.sh" >/dev/null 2>&1
        pc_rc=$?
        case "$pc_rc" in
          0) pc_hit=1 ;;
          1) ;;
          *) pc_broke=1 ;;
        esac
      fi
      if [ "$pc_hit" -eq 0 ] && [ "$pc_broke" -eq 0 ]; then
        pc_missed="${pc_missed}
    MISSED: $probe_line"
      fi
    done < "$PROBE_LEAK"
    if [ "$pc_broke" -eq 1 ]; then
      record FAIL "pre-commit scan positive control — hooks/secret-scan.sh could not run (exit >1); the commit-blocking scan is unfalsifiable"
    elif [ "$pc_n" -eq 0 ]; then
      record FAIL "pre-commit scan positive control — no usable probe lines"
    elif [ -n "$pc_missed" ]; then
      printf 'pre-commit scan is BLIND (on %s, secret-scan.sh + grep -EI):%s\n' "$(uname -s)" "$pc_missed"
      record FAIL "pre-commit scan positive control — the commit-blocking pattern misses values it must catch"
    else
      record PASS "pre-commit scan positive control ($pc_n planted caught via secret-scan.sh + grep -EI)"
    fi
  fi
fi

# 8c. the INSTALLED hook is the TRACKED hook. setup.sh COPIES hooks/pre-commit into
#     .git/hooks/pre-commit, so the two drift the moment the tracked one is edited
#     and nothing re-runs setup.sh. On the machine that wrote this check the copy
#     was frozen at Jul 30: every later edit to the tracked source — including the
#     credential rules added the same hour — changed nothing at commit time, and a
#     planted ghp_ token committed cleanly. Checks 8a/8b both passed throughout,
#     because both test the tracked PATTERN and neither tests the installed FILE.
#     Local-only: a CI checkout has no .git/hooks/pre-commit and never commits.
if [ -f .git/hooks/pre-commit ]; then
  if cmp -s .git/hooks/pre-commit hooks/pre-commit; then
    record PASS "installed pre-commit matches tracked source"
  else
    record FAIL "installed .git/hooks/pre-commit is STALE — your commits are not running the tracked scan; fix: cp hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit"
  fi
elif [ -d .git ]; then
  record WARN "no .git/hooks/pre-commit installed — commits are unscanned locally; run setup.sh"
fi

# 9. skill coherence — every SKILL.md branches only on terms it also defines,
#    and refers only to mechanisms it also names.
#    Catches the de-dup failure mode structure checks are blind to: a pass cut
#    the lines defining `Found` out of skills/antislop/SKILL.md and left the
#    filter "rows where Found = yes" consuming it; 14/14 stayed green. The same
#    pass cut "the approval gate" out from under skills/release/SKILL.md —
#    prose, no token, which is what [phrase] mode now covers.
#    WARN-ONLY ON PURPOSE (matches the note in hooks/check-coherence.py): this
#    is a brand-new heuristic, and a false positive must not block a release.
#    It always records PASS — the exit code is deliberately ignored. Promote to
#    FAIL once it has run clean across a few releases.
if coh=$(python3 hooks/check-coherence.py 2>&1); then
  record PASS "skill coherence"
else
  record PASS "skill coherence (WARN: $(printf '%s' "$coh" | grep -cE '\[(token|phrase)\] ') finding(s) — run python3 hooks/check-coherence.py)"
fi

printf '\n%-6s  %s\n' RESULT CHECK
for r in "${results[@]}"; do printf '%-6s  %s\n' "${r%%|*}" "${r#*|}"; done
exit "$fail"
