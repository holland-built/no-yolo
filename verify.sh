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
if ! grep -q 'declare -A' setup.sh && /bin/bash -n setup.sh 2>/dev/null; then
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
  record WARN "shellcheck not installed — skipped (CI has it; install locally: brew install shellcheck)"
fi

# 8. tracked-content scan — CI backstop for the local pre-commit hook
#    (pre-commit only guards staged diffs on machines that ran setup.sh; a
#    --no-verify commit or a pre-setup commit would otherwise publish a leak).
#    Patterns mirror INFRA_PATTERNS in hooks/pre-commit — if one changes, mirror
#    the other. Excludes are ONLY files that legitimately document the patterns.
INFRA_SCAN='192\.168\.[0-9]{1,3}\.[0-9]{1,3}|(^|[^0-9])10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}|100\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\.[0-9]{1,3}\.[0-9]{1,3}|[a-z0-9-]+\.(internal|corp|lan|home)\b|[a-z0-9-]+\.[a-z0-9-]+\.local\b'
SCAN_EXCLUDE=(':!hooks/pre-commit' ':!verify.sh' ':!skills/review/SKILL.md' ':!.no-yolo-deny.example.txt')
# git grep exits 0 when it FINDS matches — inverted vs the other checks on purpose
if git grep -nIE "$INFRA_SCAN" -- . "${SCAN_EXCLUDE[@]}" >/tmp/verify-scan.log 2>&1; then
  record FAIL "tracked-content scan — private/infra value in a tracked file (see /tmp/verify-scan.log)"
else
  record PASS "tracked-content scan"
fi

printf '\n%-6s  %s\n' RESULT CHECK
for r in "${results[@]}"; do printf '%-6s  %s\n' "${r%%|*}" "${r#*|}"; done
exit "$fail"
