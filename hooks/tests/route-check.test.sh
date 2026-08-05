#!/bin/bash
# Tests for skills/route-map/scripts/route-check.mjs — the ENUMERATION, MAP-PARSE and CLI
# thirds of the route driver.
#
# NO BROWSER, NO DEV SERVER, NO NETWORK. Every case below is decided before the driver
# reaches the point where it would spawn `npm run dev`: enumeration walks the tree first,
# the map is parsed next, and the CLI shape is checked before either. That ordering is the
# only reason this suite can live inside verify.sh at all — the browser half is proved on a
# real app, not here.
#
# Plain bash asserts, same style as secret-scan.test.sh. Picked up automatically by
# verify.sh check 1b (hooks/tests/*.test.sh). Run: bash hooks/tests/route-check.test.sh
#
# BASH-3.2 CLEAN on purpose (stock macOS bash): no mapfile, no readarray, no declare -A,
# no ${var^^}.
#
# Every fixture is a throwaway app tree under ONE mktemp sandbox, removed by the EXIT trap.
# Every value here is synthetic — no real hostname, address, phone number or key appears in
# this source, so committing this test cannot trip the repo's own scanners.
#
# WHAT MAKES A GREEN RUN MEAN SOMETHING: cases 2-6 and 9-10 are positive controls for a
# driver whose whole contract is "fail loudly, never skip". A walker that quietly ignored an
# unknown file would still pass cases 1, 7 and 8 forever.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DRIVER="$REPO/skills/route-map/scripts/route-check.mjs"

if ! command -v node >/dev/null 2>&1; then
  echo "FAIL: node is not on PATH — route-check.mjs cannot be exercised"
  exit 1
fi
if [ ! -f "$DRIVER" ]; then
  echo "FAIL: driver not found at $DRIVER"
  exit 1
fi

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
# Substring asserts go through `case`, not grep: the needles carry [brackets], (parens) and
# % signs, and a quoted case pattern matches them literally with no escaping dance.
assert_has() {
  local desc="$1" needle="$2" hay="$3"
  case "$hay" in
    *"$needle"*) results+=("PASS|$desc") ;;
    *) results+=("FAIL|$desc (output does not contain [$needle])"); fail=1 ;;
  esac
}
assert_lacks() {
  local desc="$1" needle="$2" hay="$3"
  case "$hay" in
    *"$needle"*) results+=("FAIL|$desc (output unexpectedly contains [$needle])"); fail=1 ;;
    *) results+=("PASS|$desc") ;;
  esac
}

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
mkdir -p "$SANDBOX/maps"

# A route file's CONTENTS never matter to this driver — it reads names, not code.
mkpage() {
  mkdir -p "$(dirname "$1")"
  printf 'export default function P() { return null }\n' > "$1"
}

OUTPUT=""
RC=0
run() {                                   # run <driver args...> -> sets OUTPUT and RC
  OUTPUT="$(node "$DRIVER" "$@" 2>&1)"
  RC=$?
}

# =============================================================================
# 1. HAPPY PATH — five routes across every segment shape the walker supports.
#    Nested dirs, a (group), a _private folder, an @slot holding a page directly,
#    and a [id] dynamic dir. All five must survive; the private folder must not.
# =============================================================================
H="$SANDBOX/happy"
mkpage "$H/app/page.tsx"
mkpage "$H/app/(marketing)/about/page.tsx"
mkpage "$H/app/blog/[id]/page.tsx"
mkpage "$H/app/docs/guide/page.tsx"
mkpage "$H/app/dashboard/@side/page.tsx"
mkpage "$H/app/_private/Widget.tsx"
run "$H" --enumerate
assert_eq   "1. happy 5-route tree exits 0" "0" "$RC"
n_pat="$(printf '%s\n' "$OUTPUT" | grep -c '"pattern":' | tr -d ' ')"
assert_eq   "1. happy tree enumerates exactly 5 routes" "5" "$n_pat"
assert_has  "1. root route" '"pattern": "/"' "$OUTPUT"
assert_has  "1. (group) is transparent in the URL" '"pattern": "/about"' "$OUTPUT"
assert_has  "1. [id] dynamic segment kept verbatim" '"pattern": "/blog/[id]"' "$OUTPUT"
assert_has  "1. nested dirs" '"pattern": "/docs/guide"' "$OUTPUT"
assert_has  "1. @slot page folds to the parent URL" '"pattern": "/dashboard"' "$OUTPUT"
assert_has  "1. @slot page is reported as kind slot" '"kind": "slot"' "$OUTPUT"
assert_lacks "1. _private folder is not walked" "_private" "$OUTPUT"

# =============================================================================
# 2. A segment the walker cannot map to a URL dies naming itself.
# =============================================================================
mkpage "$SANDBOX/pct/app/page.tsx"
mkpage "$SANDBOX/pct/app/%bad/page.tsx"
run "$SANDBOX/pct" --enumerate
assert_eq  "2. %bad segment exits 2" "2" "$RC"
assert_has "2. %bad segment is named" "unsupported segment '%bad'" "$OUTPUT"

# =============================================================================
# 3. middleware can rewrite any route, so its mere presence is fatal.
# =============================================================================
mkpage "$SANDBOX/mw/app/page.tsx"
printf 'export function middleware() {}\n' > "$SANDBOX/mw/middleware.ts"
run "$SANDBOX/mw" --enumerate
assert_eq  "3. middleware.ts exits 2" "2" "$RC"
assert_has "3. middleware.ts is named" "unsupported construct: middleware.ts" "$OUTPUT"

# =============================================================================
# 4. Two router roots means two answers to "what is this URL" — never guess.
# =============================================================================
mkpage "$SANDBOX/dual/app/page.tsx"
mkpage "$SANDBOX/dual/src/app/page.tsx"
run "$SANDBOX/dual" --enumerate
assert_eq  "4. dual roots exit 2" "2" "$RC"
assert_has "4. both roots are named" "found: app, src/app" "$OUTPUT"

# =============================================================================
# 5. THE FAIL-OPEN FIX. default.tsx renders only on a soft navigation into an
#    unmatched parallel slot — a thing this tool cannot drive. It used to pass as
#    "not route-producing"; now it dies and says why.
# =============================================================================
mkpage "$SANDBOX/def/app/page.tsx"
mkpage "$SANDBOX/def/app/default.tsx"
run "$SANDBOX/def" --enumerate
assert_eq  "5. default.tsx exits 2 (fail-open fix)" "2" "$RC"
assert_has "5. default.tsx is named" "unsupported route file 'app/default.tsx'" "$OUTPUT"
assert_has "5. soft navigation is the stated reason" "soft navigation" "$OUTPUT"

# =============================================================================
# 6. A colocated component is indistinguishable from a route file the walker got
#    wrong, so it dies rather than being guessed at.
# =============================================================================
mkpage "$SANDBOX/colo/app/page.tsx"
mkpage "$SANDBOX/colo/app/Button.tsx"
run "$SANDBOX/colo" --enumerate
assert_eq  "6. colocated Button.tsx exits 2" "2" "$RC"
assert_has "6. the offending file is named" "unrecognised file 'app/Button.tsx'" "$OUTPUT"
assert_has "6. colocation is called out by name" "colocated components are unsupported" "$OUTPUT"

# =============================================================================
# 7. NEGATIVE CONTROL for case 6. The allow-list must not be so tight that an
#    ordinary app tree dies: special stems and asset extensions are fine.
# =============================================================================
A="$SANDBOX/allow"
mkpage "$A/app/page.tsx"
mkpage "$A/app/layout.tsx"
mkpage "$A/app/loading.tsx"
mkpage "$A/app/error.tsx"
mkpage "$A/app/not-found.tsx"
mkpage "$A/app/template.tsx"
mkdir -p "$A/app" && printf 'body { margin: 0 }\n' > "$A/app/globals.css"
run "$A" --enumerate
assert_eq   "7. layout/loading/error/not-found/template/css tree exits 0" "0" "$RC"
n_pat="$(printf '%s\n' "$OUTPUT" | grep -c '"pattern":' | tr -d ' ')"
assert_eq   "7. none of them produce a route" "1" "$n_pat"

# =============================================================================
# 8. Metadata files are neither routes nor errors — they land in `meta`.
# =============================================================================
M="$SANDBOX/meta"
mkpage "$M/app/page.tsx"
printf 'export default function robots() {}\n'  > "$M/app/robots.ts"
printf 'export default function sitemap() {}\n' > "$M/app/sitemap.ts"
printf 'not a real icon\n'                      > "$M/app/favicon.ico"
run "$M" --enumerate
assert_eq  "8. robots+sitemap+favicon tree exits 0" "0" "$RC"
assert_has "8. robots.ts lands in meta" '"app/robots.ts"' "$OUTPUT"
assert_has "8. sitemap.ts lands in meta" '"app/sitemap.ts"' "$OUTPUT"
assert_has "8. favicon.ico lands in meta" '"app/favicon.ico"' "$OUTPUT"
n_pat="$(printf '%s\n' "$OUTPUT" | grep -c '"pattern":' | tr -d ' ')"
assert_eq  "8. metadata files produce no routes" "1" "$n_pat"

# =============================================================================
# 9. MAP PARSE. These run in FULL-RUN mode (three positionals), not --enumerate,
#    because the map is only read on the full path. Every one of them dies during
#    the parse — before the port check, before `npm run dev`, before playwright.
#    That is asserted implicitly: a case that got past the parse would hang or
#    spawn a server, and the exit code would not be 2.
# =============================================================================
APPOK="$SANDBOX/mapapp"
mkpage "$APPOK/app/page.tsx"
OUTDIR="$SANDBOX/out"

runmap() {                                # runmap <map-name>
  run "$APPOK" "$SANDBOX/maps/$1.md" "$OUTDIR"
}

cat > "$SANDBOX/maps/dup.md" <<'MAP'
/ | none | "hello"
/ | none | "hello again"
MAP
runmap dup
assert_eq  "9a. duplicate row key exits 2" "2" "$RC"
assert_has "9a. duplicate row names the route and the first line" "duplicate row for route '/' (first seen at line 1)" "$OUTPUT"

cat > "$SANDBOX/maps/unkdir.md" <<'MAP'
!bogus something
/ | none | "hello"
MAP
runmap unkdir
assert_eq  "9b. unknown directive exits 2" "2" "$RC"
assert_has "9b. unknown directive is named" "unknown directive '!bogus'" "$OUTPUT"

cat > "$SANDBOX/maps/twocell.md" <<'MAP'
/ | none
MAP
runmap twocell
assert_eq  "9c. 2-cell row exits 2" "2" "$RC"
assert_has "9c. 2-cell row prints the required shape" "expected 'route | auth | expected [| note]'" "$OUTPUT"

cat > "$SANDBOX/maps/badlinks.md" <<'MAP'
!links sideways
/ | none | "hello"
MAP
runmap badlinks
assert_eq  "9d. bad !links value exits 2" "2" "$RC"
assert_has "9d. bad !links value lists the legal ones" "use '!links off' or '!links external'" "$OUTPUT"

# A pin this short would match almost any number on the page, so it dies at parse
# rather than passing a check it could never fail. 5551 is four digits of nothing.
cat > "$SANDBOX/maps/shortpin.md" <<'MAP'
!contact 5551
/ | none | "hello"
MAP
runmap shortpin
assert_eq  "9e. !contact pin under 7 digits exits 2" "2" "$RC"
assert_has "9e. short pin says how many digits it got" "pins only 4 digit(s)" "$OUTPUT"

# =============================================================================
# 10. CLI CONTRACT. A malformed invocation is exit 2 — never a silent default,
#     never a partial run.
# =============================================================================
run
assert_eq  "10a. no arguments exits 2" "2" "$RC"
assert_has "10a. no arguments prints usage" "usage: route-check.mjs" "$OUTPUT"

run "$APPOK" --bogus
assert_eq  "10b. unknown flag exits 2" "2" "$RC"
assert_has "10b. unknown flag is named" "unknown flag '--bogus'" "$OUTPUT"

run "$APPOK" "$SANDBOX/maps/dup.md" --enumerate
assert_eq  "10c. --enumerate with a map positional exits 2" "2" "$RC"
assert_has "10c. --enumerate states its arity" "--enumerate takes exactly one positional" "$OUTPUT"

run "$SANDBOX/does-not-exist" --enumerate
assert_eq  "10d. missing app root exits 2" "2" "$RC"
assert_has "10d. missing app root is named" "app root does not exist:" "$OUTPUT"

run "$APPOK" --update
assert_eq  "10e. bare --update exits 2" "2" "$RC"
assert_has "10e. bare --update demands a value" "'--update' needs a value" "$OUTPUT"

# A typo in --update must not silently rewrite nothing (or, worse, everything).
cat > "$SANDBOX/maps/tiny.md" <<'MAP'
/ | none | "hello"
MAP
run "$APPOK" "$SANDBOX/maps/tiny.md" "$OUTDIR" --update=/nope
assert_eq  "10f. --update naming an unknown route exits 2" "2" "$RC"
assert_has "10f. the bad route is named back" "--update=/nope: no such route in the enumeration" "$OUTPUT"
assert_has "10f. the known routes are listed" "known routes: /" "$OUTPUT"

printf '\n%-6s  %s\n' RESULT CASE
for r in "${results[@]}"; do printf '%-6s  %s\n' "${r%%|*}" "${r#*|}"; done

if [ "$fail" -eq 0 ]; then
  printf '\nAll asserts passed.\n'
  exit 0
else
  printf '\nSome asserts failed.\n'
  exit 1
fi
