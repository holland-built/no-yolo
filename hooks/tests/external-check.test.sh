#!/bin/bash
# Tests for hooks/external-check.sh, the guard that stops an invented package name shipping.
# Run: bash hooks/tests/external-check.test.sh
#
# Extraction is the half most likely to go quietly wrong, in both directions. Miss a real
# install command and the guard protects nothing; invent one from a sentence and the guard
# cries wolf and gets switched off. Every NEGATIVE case below is a line that really did
# produce a phantom package on the first run of this script.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO/hooks/external-check.sh"

fail=0
pass=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Write body to a fixture with the given name, extract from it, compare to expected.
# expected is a newline-separated sorted list, or "" for nothing at all.
extracts() {
  local name="$1" body="$2" want="$3" desc="$4" actual
  printf '%s\n' "$body" > "$TMP/$name"
  actual="$(bash "$HOOK" --extract "$TMP/$name" 2>/dev/null | grep . | sort)"
  if [ "$actual" != "$want" ]; then
    echo "FAIL: $desc"
    echo "  wanted: [${want//$'\n'/ | }]"
    echo "  got:    [${actual//$'\n'/ | }]"
    fail=1
  else
    pass=$((pass + 1))
  fi
}

# --- POSITIVE: a real install command must be seen -----------------------------
extracts a.md 'npm install -g agnix' \
  'npm agnix' "a single global install"

extracts b.md 'npm install -g agnix @yawlabs/ctxlint impeccable' \
  'npm @yawlabs/ctxlint
npm agnix
npm impeccable' "every package on a multi-package line, not just the first"

extracts c.md 'npm uninstall -g agnix' \
  'npm agnix' "an uninstall names a dependency too"

extracts d.md 'npx skills@latest add bitjaru/styleseed' \
  'gh bitjaru/styleseed' "a skills-CLI repo reference"

extracts e.md 'npx --yes agnix /some/path' \
  'npm agnix' "an npx invocation with the yes-flag"

extracts f.md 'npx -y impeccable detect' \
  'npm impeccable' "an npx invocation with the short yes-flag"

extracts g.md 'Remove one tool at a time: `npm uninstall -g agnix @yawlabs/ctxlint` · `/plugin remove <x>`' \
  'npm @yawlabs/ctxlint
npm agnix' "a command quoted inside a prose sentence, stopping at the separator"

extracts h.md '```bash
npm install -g agnix
```' "npm agnix" "a command inside a fenced block"

# --- Repository URLs, when something is fetching them --------------------------
extracts r1.md 'git clone https://github.com/NVIDIA/SkillSpector.git && cd SkillSpector' \
  'gh NVIDIA/SkillSpector' "a git clone URL"

extracts r2.md 'uv tool install git+https://github.com/NVIDIA/skillspector.git' \
  'gh NVIDIA/skillspector' "a git+https URL behind uv tool install"

extracts r3.md 'pip install git+https://github.com/owner/thing.git' \
  'gh owner/thing' "a git URL behind pip install"

extracts r4.md 'See https://github.com/owner/thing for the background.' \
  '' "a repository URL in prose is a link, not a dependency"

extracts r5.md '[the docs](https://github.com/owner/thing) explain it' \
  '' "a markdown link is not a dependency"

# --- Line continuations --------------------------------------------------------
# A long install split across lines is ordinary, and splitting on raw lines found nothing.
extracts s1.md 'npm install -g \
  agnix \
  impeccable' 'npm agnix
npm impeccable' "packages on continuation lines"

# --- NEGATIVE: prose must NOT become a package ---------------------------------
# Each of these produced a phantom package before the discriminators were added.
extracts i.md 'newer npx installs land here' \
  '' "the word npx in a sentence does not swallow the next word"

extracts j.md 'One exemption: on-demand npx tools.' \
  '' "npx followed by a plain noun"

extracts k.md 'A tool that is fetched and run by `npx` at call time' \
  '' "npx quoted mid-sentence"

extracts l.md 'check the runner instead: `command -v npx` must succeed' \
  '' "npx as the object of command -v"

extracts m.md 'just say "Remember that I use pnpm, not npm", or "Forget about X"' \
  '' "npm named in a sentence with no install verb"

extracts n.md 'Query the version read-only: `npm view <pkg> version`' \
  '' "npm view is a read, not an install"

extracts o.md 'npm install -g <your-package-here>' \
  '' "a placeholder in angle brackets is not a package"

# --- Comments: a name in a comment is not a command ----------------------------
printf '# emilkowalski/skills (npx skills@latest add emilkowalski/skills)\nskills/emil\n' > "$TMP/p.gitignore"
actual="$(bash "$HOOK" --extract "$TMP/p.gitignore" 2>/dev/null | grep . | sort)"
if [ -n "$actual" ]; then
  echo "FAIL: a reference inside a .gitignore comment must not be extracted, got [$actual]"
  fail=1
else
  pass=$((pass + 1))
fi

# The same text in markdown IS kept, because # is a heading there and fenced commands are real.
extracts q.md '# heading
npm install -g agnix' 'npm agnix' "a markdown heading does not suppress the file"

# --- The live repo must be clean ----------------------------------------------
# The offline half needs no network, so it runs everywhere and can never be skipped.
if bash "$HOOK" --scope >/dev/null 2>&1; then
  pass=$((pass + 1))
else
  echo "FAIL: --scope on the live repo: an install command names something hooks/externals.txt omits"
  bash "$HOOK" --scope
  fail=1
fi

# --- An undeclared package must fail the scope half ---------------------------
# Proves the guard can go red, which is the whole point of it existing.
UNDECLARED="$TMP/undeclared.md"
printf 'npm install -g zz-selftest-not-a-real-package\n' > "$UNDECLARED"
bash "$HOOK" --scope "$UNDECLARED" >/dev/null 2>&1
rc=$?
if [ "$rc" != 1 ]; then
  echo "FAIL: an undeclared package should exit 1, got $rc"
  fail=1
else
  pass=$((pass + 1))
fi

# --- Provenance: a package that exists is not the same as the right package ----
# Skipped without network, and the skip is announced rather than counted as a pass.
if curl -s -o /dev/null --max-time 10 https://registry.npmjs.org/agnix 2>/dev/null; then
  # agnix is real and resolves to agent-sh/agnix. A manifest expecting a DIFFERENT owner must
  # go red, or the check is only asking "does this name exist" and a squatted name passes.
  printf 'npm  agnix  someone-else/agnix\n' > "$TMP/wrong.txt"
  EXTERNAL_CHECK_MANIFEST="$TMP/wrong.txt" EXTERNAL_CHECK_NO_CACHE=1 bash "$HOOK" --resolve >/dev/null 2>&1
  rc=$?
  if [ "$rc" != 1 ]; then
    echo "FAIL: a package resolving to the wrong repository should exit 1, got $rc"
    fail=1
  else
    pass=$((pass + 1))
  fi

  # And the right owner must still pass, or the row above proves only that everything is red.
  printf 'npm  agnix  agent-sh/agnix\n' > "$TMP/right.txt"
  EXTERNAL_CHECK_MANIFEST="$TMP/right.txt" EXTERNAL_CHECK_NO_CACHE=1 bash "$HOOK" --resolve >/dev/null 2>&1
  rc=$?
  if [ "$rc" != 0 ]; then
    echo "FAIL: a package resolving to its pinned repository should exit 0, got $rc"
    fail=1
  else
    pass=$((pass + 1))
  fi

  # A package that does not exist must be reported as missing, not as an operational error.
  printf 'npm  zz-package-that-cannot-exist-9x7  someone/thing\n' > "$TMP/gone.txt"
  EXTERNAL_CHECK_MANIFEST="$TMP/gone.txt" EXTERNAL_CHECK_NO_CACHE=1 bash "$HOOK" --resolve >/dev/null 2>&1
  rc=$?
  if [ "$rc" != 1 ]; then
    echo "FAIL: a nonexistent package should exit 1, got $rc"
    fail=1
  else
    pass=$((pass + 1))
  fi
else
  echo "SKIP: no network, so the three provenance asserts did not run (this is not a pass)"
fi

if [ "$fail" -eq 0 ]; then
  echo "All $pass asserts passed."
  exit 0
else
  echo "Some asserts failed."
  exit 1
fi
