#!/usr/bin/env bash
# external-check.sh — every external tool a tracked file tells you to install must be declared
# in hooks/externals.txt, and must still resolve to the project that file pins it to.
#
# Two halves, on purpose:
#
#   SCOPE   (offline, always runnable) every reference extracted from a tracked install command
#           appears in the manifest. This is the half that catches an invented name, and it
#           needs no network, so it can never be skipped.
#   RESOLVE (network) each manifest entry still exists, and each npm entry's published
#           repository.url still points at the owner the manifest pins.
#
# Exit codes, which the caller must keep distinct:
#   0  every reference is declared and resolves
#   1  a reference is undeclared, absent, or points somewhere else
#   3  the check COULD NOT RUN (no network, no npm, no curl). Never report this as clean.
#
# Modes: --extract prints what it found and exits. --scope runs the offline half only, and
# --resolve the network half only. The halves answer different questions and each has to be
# testable without the other: scope asks "is this declared", resolve asks "is it what we said".
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "external-check: cannot cd to $ROOT" >&2; exit 3; }
# Overridable so the tests can point it at a fixture. The provenance comparison is the part
# that decides whether a real-but-wrong package passes, so it has to be exercisable against a
# manifest that deliberately expects the wrong owner.
MANIFEST="${EXTERNAL_CHECK_MANIFEST:-hooks/externals.txt}"

MODE="${1:-full}"
TARGET="${2:-}"

# ── Extraction ───────────────────────────────────────────────────────────────
# Tracked files only, because only a tracked file can mislead someone else. Two directories
# are excluded and both are deliberate: archive/ is history that discusses removed tools by
# name, and hooks/tests/ holds fixtures whose whole job is to contain planted strings.
#
# Extraction reads the RUNNABLE forms, not prose. A tool named in a sentence is a claim; a
# tool named in `npm install -g` is a command someone will run. Operands are tokenised and
# read to the first shell separator, so a multi-package install yields every package and not
# just the first, and a scoped name like @yawlabs/ctxlint survives intact.
extract() {
  # A single named file, for the tests. Extraction is the half most likely to go subtly wrong,
  # so it has to be exercisable against fixtures rather than only against the live repo.
  if [ -n "${1:-}" ]; then
    printf '%s\n' "$1"
  else
    # refs/brands/ excluded for the same reason as archive/: it is third-party text this repo
    # only stores. Its brand specifications quote install commands from the sites they
    # describe, and this repo never runs one of them. Declaring another project's examples in
    # externals.txt would assert they were checked, which would be a lie.
    git ls-files -- . ':!archive' ':!hooks/tests' ':!refs/brands/**'
  fi | while IFS= read -r f; do
    [ -f "$f" ] || continue
    python3 - "$f" <<'PY'
import re, sys

path = sys.argv[1]
try:
    text = open(path, encoding="utf-8", errors="replace").read()
except OSError:
    sys.exit(0)

STOP = {"&&", "||", ";", "|", "\\", "&", ">", ">>"}

# A package specifier and nothing else: optional @scope/, a name, an optional @version.
# Prose words reach the operand loop too (a trailing "·" separator, a stray word after a
# closing backtick), and this is what tells them apart from a name someone will install.
SPEC = re.compile(r"^@?[a-z0-9][a-z0-9._-]*(/[a-z0-9._-]+)?(@[A-Za-z0-9._^~>=<-]+)?$")

def operands(tokens):
    """Package names following an install verb, up to the first shell separator."""
    out = []
    for t in tokens:
        if t in STOP or t.startswith("#"):
            break
        if t.startswith("-"):          # a flag, not a package
            continue
        t = t.strip("`'\"()")
        if not SPEC.match(t):          # not a package name, so the command ended here
            break
        out.append(unpin(t))
    return out

def unpin(spec):
    """`jscpd@latest` -> `jscpd`, `@playwright/mcp@latest` -> `@playwright/mcp`.

    SPEC has always MATCHED a trailing @version, and nothing ever removed it, so the identity
    carried the tag into the comparison and could never equal a manifest row. It went unseen
    because no tracked file pinned a version until 2026-08-26, when INSTALL.md documented
    `npx -y @playwright/mcp@latest` and the scope check demanded a row for a name nobody can
    sensibly declare: pinning the tag in the manifest would make the row rot the moment the
    command changed, and would compare a tag against a package name.

    Split on the LAST @, never the first: a scoped package opens with one and it is part of
    the name.
    """
    at = spec.rfind("@")
    return spec[:at] if at > 0 else spec

# In a shell script, a config file or a .gitignore, a leading # is a comment and whatever it
# mentions is not run. In markdown it is a heading, and real commands live in fenced blocks
# below it, so markdown keeps every line. Without this split, a tool named in a .gitignore
# comment reads as an install command: one such line survived the first run only because it
# ended in a bracket, which is luck rather than a rule.
COMMENTED = not path.endswith((".md", ".mdx"))

# A GitHub repository named in a clone or a VCS install URL is a reference exactly as much as
# an npx one is. INSTALL.md installs SkillSpector with a git URL, and until this was added the
# extractor walked straight past it: the manifest row stayed satisfied by nothing, so the URL
# could rot or be mistyped and the guard would still report clean.
GITURL = re.compile(
    r"(?:git\+)?(?:https://|git@)github\.com[:/]([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+?)(?:\.git)?(?:[/'\"\s)]|$)"
)

# Shell line continuations. `npm install -g \` with its packages on the following lines is an
# ordinary way to write a long command, and splitting on raw lines would extract nothing at all
# from it. Join first, then tokenise.
joined, buf = [], ""
for raw in text.splitlines():
    stripped = raw.rstrip()
    if stripped.endswith("\\"):
        buf += stripped[:-1] + " "
        continue
    joined.append(buf + stripped)
    buf = ""
if buf:
    joined.append(buf)

for raw in joined:
    line = raw.strip().lstrip("$ ").strip()
    if COMMENTED and line.startswith("#"):
        continue
    # A markdown table row or prose sentence can quote a command; strip the decoration
    # but keep the command itself.
    line = line.replace("`", " ")

    # Only count a repository URL when something is actually fetching it. A URL in prose is a
    # link; a URL after git clone, pip install or uv tool install is a dependency.
    if re.search(r"\b(git\s+clone|pip\s+install|pipx\s+install|uv\s+tool\s+install|uvx)\b", line):
        for owner, repo in GITURL.findall(line):
            print("gh", owner + "/" + repo)

    tok = line.split()
    for i, t in enumerate(tok):
        if t not in ("npm", "npx"):
            continue
        rest = tok[i + 1:]
        if not rest:
            continue
        if t == "npm" and rest[0] in ("install", "i", "uninstall", "remove", "rm"):
            for p in operands(rest[1:]):
                if p and not p.startswith("<"):
                    print("npm", p)
        elif t == "npx":
            # An npx INVOCATION always carries an explicit yes-flag or a pinned version in this
            # repo, and prose about npx never does. Without that discriminator the word "npx" in
            # a sentence swallows the next word as a package: "newer npx installs land here"
            # yielded a package called "installs", and three more like it, on the first run.
            flagged = any(a in ("-y", "--yes") for a in rest)
            args = [a.strip("`'\"") for a in rest if a not in ("-y", "--yes")]
            if not args:
                continue
            head = args[0]
            if not (flagged or "@" in head):
                continue
            if not SPEC.match(head):
                continue
            if head.split("@")[0] == "skills":
                if len(args) >= 3 and args[1] == "add":
                    ref = args[2].strip("`'\"")
                    if "/" in ref and SPEC.match(ref):
                        print("gh", ref)
            else:
                # `head.split("@")[0]` is empty for a SCOPED package, so the whole specifier
                # used to be printed instead, tag and all: @playwright/mcp@latest never
                # matched the row declaring @playwright/mcp. unpin splits on the LAST @, which
                # is right for both shapes.
                print("npm", unpin(head))
PY
  done | sort -u
}

# ── The manifest ─────────────────────────────────────────────────────────────
if [ ! -f "$MANIFEST" ]; then
  echo "external-check: $MANIFEST is missing, so nothing can be declared" >&2
  exit 1
fi

# Case-insensitive, because GitHub is: the same repository is reachable as NVIDIA/SkillSpector
# and NVIDIA/skillspector, and this repo's own INSTALL.md uses both spellings, one from the
# project's README and one from its uv install line. Two spellings of one repository must not
# read as one declared and one invented.
declared() {
  grep -vE '^\s*(#|$)' "$MANIFEST" \
    | awk -v k="$1" -v n="$2" 'BEGIN{k=tolower(k);n=tolower(n)} tolower($1)==k && tolower($2)==n {found=1} END{exit found?0:1}'
}
provenance() { grep -vE '^\s*(#|$)' "$MANIFEST" | awk -v n="$1" '$1=="npm" && $2==n {print $3}'; }

REFS="$(extract "$TARGET")"

if [ "$MODE" = "--extract" ]; then
  printf '%s\n' "$REFS"
  exit 0
fi

# ── Half one: SCOPE. Offline, and therefore never skipped. ───────────────────
undeclared=""
if [ "$MODE" = "--resolve" ]; then
  REFS=""
fi
while IFS=' ' read -r kind name; do
  [ -z "${name:-}" ] && continue
  declared "$kind" "$name" || undeclared="${undeclared}
  $kind $name"
done <<EOF
$REFS
EOF

if [ -n "$undeclared" ]; then
  printf 'external-check: a tracked install command names something %s does not declare:%s\n' "$MANIFEST" "$undeclared" >&2
  printf 'Query it first (npm view <pkg> version), then add a row with what you saw.\n' >&2
  exit 1
fi

[ "$MODE" = "--scope" ] && { echo "external-check: scope OK ($(printf '%s\n' "$REFS" | grep -c .) references, all declared)"; exit 0; }

# ── Half two: RESOLVE. Needs network. ────────────────────────────────────────
# A SUCCESS-ONLY cache, keyed by the manifest's own hash and valid for an hour. Only a clean
# resolve is ever cached, so a failure is always re-checked and can never be papered over, and
# editing the manifest changes the key, so a new row is always resolved for real.
#
# It is here because verify-selftest.sh runs verify.sh nineteen times in a row, which meant
# nineteen full trips to two registries and a self-test that took longer than the patience of
# anyone running it. Set EXTERNAL_CHECK_NO_CACHE=1 to force a live check.
#
# The key covers this script as well as the manifest, so tightening a rule here invalidates
# every cached pass rather than inheriting one made under the older, weaker rule. CI never
# reads the cache at all: a build is the one place the answer must be live.
cache_key() {
  if command -v shasum >/dev/null 2>&1; then cat "$MANIFEST" "${BASH_SOURCE[0]}" | shasum -a 256 | awk '{print $1}'
  else cat "$MANIFEST" "${BASH_SOURCE[0]}" | sha256sum | awk '{print $1}'; fi
}
CACHE="${TMPDIR:-/tmp}/external-check-$(cache_key 2>/dev/null || echo none).ok"
if [ -z "${EXTERNAL_CHECK_NO_CACHE:-}" ] && [ -z "${CI:-}" ] && [ -f "$CACHE" ]; then
  # -mmin is GNU and BSD alike for "modified fewer than N minutes ago".
  if [ -n "$(find "$CACHE" -mmin -60 2>/dev/null)" ]; then
    echo "external-check: $(grep -cvE '^\s*(#|$)' "$MANIFEST") declared tools resolve (cached within the hour)"
    exit 0
  fi
fi

command -v curl >/dev/null 2>&1 || { echo "external-check: curl absent, cannot resolve" >&2; exit 3; }
command -v npm  >/dev/null 2>&1 || { echo "external-check: npm absent, cannot resolve" >&2; exit 3; }

# npm writes to its cache even for a read. Under a restricted sandbox that throws EPERM, which
# is an operational failure and must not read as "package missing". An isolated cache removes
# the whole class.
NPM_TMP="$(mktemp -d)"
trap 'rm -rf "$NPM_TMP"' EXIT

missing=""
broke=""

resolve_npm() {
  local pkg="$1" want="$2" out rc url
  out="$(npm view "$pkg" repository.url --cache "$NPM_TMP" --registry https://registry.npmjs.org/ 2>&1)"
  rc=$?
  # The EXIT CODE decides, not the text. Reading the output alone meant a failed command that
  # happened to print the expected repository string counted as a success.
  if [ "$rc" -ne 0 ]; then
    case "$out" in
      *"code E404"*) missing="${missing}
  npm $pkg  does not exist on the public registry" ;;
      # Everything else is operational: EPERM, ENOTFOUND, a 5xx, an auth prompt. Those must
      # NEVER be counted as missing, or a flaky network would delete a real dependency.
      *) broke="${broke}
  npm $pkg  could not be checked: $(printf '%s' "$out" | head -1)" ;;
    esac
    return
  fi
  url="$(printf '%s' "$out" | head -1 | tr -d "'\" ")"
  if [ -z "$url" ]; then
    broke="${broke}
  npm $pkg  could not be checked: the registry returned no repository field"; return
  fi
  # Compare the OWNER/REPO PATH ON GITHUB, not a substring of the URL. A substring match is
  # satisfied by any URL that merely contains the expected text, so
  # https://attacker.example/agent-sh/agnix-payload passed as agent-sh/agnix.
  local host_path
  host_path="$(printf '%s' "$url" | sed -E 's#^git\+##; s#^(https|ssh|git)://##; s#^git@#-#; s#^-github\.com:#github.com/#; s#\.git$##; s#/+$##')"
  case "$host_path" in
    github.com/*) : ;;
    *) missing="${missing}
  npm $pkg  resolves, but its repository host is not github.com: '$url'"; return ;;
  esac
  local got="${host_path#github.com/}"
  # Case-insensitive: GitHub treats owner and repo case-insensitively in URLs, and package
  # metadata is written by hand.
  if [ "$(printf '%s' "$got" | tr 'A-Z' 'a-z')" != "$(printf '%s' "$want" | tr 'A-Z' 'a-z')" ]; then
    missing="${missing}
  npm $pkg  resolves, but its repository is '$got', not '$want'"
  fi
}

resolve_gh() {
  local repo="$1" code
  # No array for the auth header. Stock macOS ships bash 3.2, where "${arr[@]}" on an EMPTY
  # array is an unbound-variable error under set -u, and the first version of this function
  # hit it on every unauthenticated call.
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$repo" 2>/dev/null)"
  else
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "https://api.github.com/repos/$repo" 2>/dev/null)"
  fi
  case "$code" in
    200) : ;;
    404) missing="${missing}
  gh  $repo  does not exist" ;;
    # 403 and 429 are rate limiting, which on a shared CI runner is routine. Counting either
    # as "missing" would turn a busy hour into a red build and teach everyone to ignore it.
    *) broke="${broke}
  gh  $repo  could not be checked: HTTP ${code:-none}" ;;
  esac
}

while read -r kind name want; do
  case "$kind" in
    npm) resolve_npm "$name" "$want" ;;
    gh)  resolve_gh  "$name" ;;
  esac
done < <(grep -vE '^\s*(#|$)' "$MANIFEST")

if [ -n "$missing" ]; then
  printf 'external-check: declared tools that do not resolve:%s\n' "$missing" >&2
  exit 1
fi
if [ -n "$broke" ]; then
  printf 'external-check: COULD NOT RUN, this is not a clean result:%s\n' "$broke" >&2
  exit 3
fi

: > "$CACHE" 2>/dev/null || true
echo "external-check: $(grep -cvE '^\s*(#|$)' "$MANIFEST") declared tools resolve, provenance matches"
exit 0
