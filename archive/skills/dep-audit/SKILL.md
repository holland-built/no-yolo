---
name: dep-audit
description: "Use this skill when the user types /dep-audit, says 'audit my dependencies', 'check for vulnerable packages', 'what licences am I using', or 'security scan this app'. npm-only supply-chain pass: leaked keys in both tracked files AND git history, npm advisories, licences, dependency inventory and a small Next.js config checklist, merged into one severity-ranked table. This is NOT a Trivy equivalent. It never scans OS or container packages, builds no SBOM, and reads no infrastructure-as-code."
user-invocable: true
effort: high
argument-hint: "[repo path, defaults to the current repo]"
allowed-tools: [Bash, Read, Grep, Glob]
---

Arguments: $ARGUMENTS, installs nothing; every tool below is `git` or the `npm` already present.

## Preflight

```bash
TARGET="$(echo "$ARGUMENTS" | xargs)"; TARGET="${TARGET:-.}"
ROOT="$(cd "$TARGET" 2>/dev/null && (git rev-parse --show-toplevel 2>/dev/null || pwd))" || ROOT=""
TMP="$(mktemp -d)"   # $TMP and $ROOT are reused below — one shell session, rm -rf "$TMP" at the end
[ -n "$ROOT" ] && echo "ROOT|$ROOT" || echo "ROOT|UNRESOLVED"
[ -f "$ROOT/package.json" ] && echo "NPM|yes" || echo "NPM|no"
```

**Hard gate, `NPM|no` means every npm step below is SKIPPED, not attempted.** `npm audit`/`npm ls`
walk *up* the tree, so with no `package.json` they silently report a parent's `node_modules`
(verified: run in `~/.claude` they reported six vulnerabilities belonging to the *home directory
above it*), real-looking findings about packages
the repo does not have. When `NPM|no`, still run step 1, still print the blind-spots section, and
say: `no package.json at <ROOT> — npm passes skipped (not clean, unrun)`.

## 1: Leaked keys (always runs)

**Branch first: is `$ROOT` the no-yolo repo itself?** If it holds BOTH `hooks/secret-scan.sh` and
`verify.sh`, the tracked-content scan is already `verify.sh`'s job. Delegate, never repeat it:

```bash
(cd "$ROOT" && bash verify.sh) > "$TMP/verify.out" 2>&1; echo "VERIFY_RC|$?"
grep -m1 'tracked-content scan' "$TMP/verify.out" || echo "KEYS_ROW|missing"
```

| verify.sh row | Key-scan row |
|---|---|
| `PASS tracked-content scan` | INFO `key scan clean (via verify.sh)` |
| `FAIL tracked-content scan …` | one CRITICAL row quoting the FAIL text verbatim |
| no such row, or `VERIFY_RC` non-zero and no row | CRITICAL `key scan DID NOT RUN — verify.sh produced no tracked-content row` |

Why delegate rather than re-scan: `verify.sh`'s `SCAN_EXCLUDE` names the six files that hold
credential formats on purpose and sha256-pins the two test fixtures, so excluding them hides
nothing. It tells a real leak from a fixture. A bare re-scan cannot: it returns ~20 hits on the
repo's own pattern list and fixtures, and a wall of expected findings trains the reader to ignore
the table.

**Every other repo**, scan tracked files with the shared scanner:

```bash
SCAN="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/secret-scan.sh"
if [ ! -x "$SCAN" ]; then echo "SCAN_DID_NOT_RUN|scanner not executable at $SCAN"
elif ! "$SCAN" --check 2>/dev/null; then echo "SCAN_DID_NOT_RUN|scanner self-check failed"
else
  files=(); while IFS= read -r -d '' f; do [ -f "$ROOT/$f" ] && files+=("$ROOT/$f"); done \
    < <(git -C "$ROOT" ls-files -z 2>/dev/null)
  if [ "${#files[@]}" -eq 0 ]; then echo "SCAN_DID_NOT_RUN|no tracked files (not a git repo?)"
  else "$SCAN" --files "${files[@]}"; echo "SCAN_STATUS|$?"; fi
fi
```

Resolved from the installed config dir, **never** a repo-relative path. Fail closed, as `/health` does:

| Output | Action |
|---|---|
| `SCAN_DID_NOT_RUN\|<reason>` | CRITICAL `key scan DID NOT RUN — <reason>`. Never report clean |
| lines, then `SCAN_STATUS\|0` | one CRITICAL row per printed `file:line` |
| `SCAN_STATUS\|1` | no matches, one INFO row `key scan clean (N tracked files)` |
| `SCAN_STATUS\|` anything else | CRITICAL `key scan DID NOT RUN — scanner exited <rc>` |

Never pipe the file list through `xargs` because it collapses grep's exit 1 ("no match") into 123, destroying the 0/1 contract the table above depends on.

## 1b: Leaked keys in git HISTORY (always runs)

Step 1 scans the files that exist *now*. A key that was committed and later deleted is invisible
to it and still live in every clone. This step is the only thing that sees those.

```bash
[ "$(git -C "$ROOT" rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ] \
  && echo "HIST_REPO|yes" || echo "HIST_REPO|no"
echo "HIST_SHALLOW|$(git -C "$ROOT" rev-parse --is-shallow-repository 2>/dev/null)"
GIT_PAGER=cat git -C "$ROOT" --no-pager log --all -p --no-color \
  --format='%n===COMMIT %h %ad %s' --date=short > "$TMP/history.txt" 2>/dev/null
echo "HIST_RC|$?"
echo "HIST_BYTES|$(wc -c < "$TMP/history.txt" | tr -d ' ')"
echo "HIST_COMMITS|$(git -C "$ROOT" rev-list --all --count 2>/dev/null)"
```

**Check `HIST_BYTES` before drawing any conclusion.** A dump of 0 bytes is the failure this step
exists to survive: git pages by default, and a paged `git log -p` into a pipe writes nothing and
reads exactly like a clean repo. `GIT_PAGER=cat` plus `--no-pager` plus the byte count is a belt
and two braces. Keep all three. Expect roughly 100 KB per commit of source churn; a repo with
800+ commits produces a dump in the hundreds of MB and takes a minute or two. That is normal, not
a reason to skip.

Fail closed, any row below that is not the last one produces a CRITICAL and **never** a clean verdict:

| Signal | Action |
|---|---|
| `HIST_REPO\|no` | CRITICAL `history key scan DID NOT RUN — not a git repo` |
| `HIST_SHALLOW\|true` | CRITICAL `history key scan DID NOT RUN — shallow clone, most history absent`. Re-run after `git fetch --unshallow` |
| `HIST_RC` non-zero | CRITICAL `history key scan DID NOT RUN — git log exited <rc>` |
| `HIST_BYTES\|0` with `HIST_COMMITS` > 0 | CRITICAL `history key scan DID NOT RUN — empty dump from a non-empty repo` |
| repo, not shallow, rc 0, bytes > 0 | proceed to the scan below |

Then scan the dump with the same scanner and the same fail-closed contract as step 1, `--files`,
not stdin, because only `--files` emits the line numbers the commit lookup needs:

```bash
# re-resolved here: step 1's no-yolo branch delegates to verify.sh and never sets $SCAN
SCAN="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/secret-scan.sh"
"$SCAN" --files "$TMP/history.txt"; echo "HIST_STATUS|$?"
```

This step runs in the no-yolo repo too. `verify.sh` scans tracked content only, so delegating
step 1 to it leaves history uncovered, 1b is never skipped for any repo.

| Output | Action |
|---|---|
| lines, then `HIST_STATUS\|0` | one CRITICAL row per hit, resolve each to its commit below |
| `HIST_STATUS\|1` | one INFO row `history key scan clean (N commits, M bytes scanned)` |
| `HIST_STATUS\|` anything else | CRITICAL `history key scan DID NOT RUN — scanner exited <rc>` |

Each hit is `.../history.txt:<N>:<line>`. That line number means nothing to the reader, turn it
into a commit before it goes in the table:

```bash
awk -v n=<N> 'NR<=n && /^===COMMIT /{c=$0} NR==n{print c; exit}' "$TMP/history.txt"
```

`Where` becomes that commit's short hash and date; `Fix` is **rotate the credential first**,
rewriting history second. A key that reached any remote is compromised whether or not the commit
is later removed. Never write a fix that only says "rewrite history".

Two hits are expected, not leaks, and belong in the table as INFO with the reason stated: test
fixtures (a passphrase whose own text says it is test-only), and, in the no-yolo repo, the six
pattern-documenting files step 1 delegates to `verify.sh`. Judge them by reading the matched line;
do not add an exclude list here, which would hide a real key that happened to sit in one of them.

## 2: Vulnerable packages

```bash
npm --prefix "$ROOT" audit --json > "$TMP/audit.json" 2>/dev/null; echo "AUDIT_RC|$?"
```

`AUDIT_RC` 0 or 1 is normal (1 = advisories found); anything else, or unparseable JSON → one HIGH
row saying the advisory pass did not run. Read `.metadata.vulnerabilities` for per-severity counts,
then one row per key in `.vulnerabilities`: package, `severity`, `via[0].title`, and the fixed
version from `fixAvailable` (`true`, `false`, or `{name, version}`).

## 3: Licences

```bash
# --long is REQUIRED: plain `npm ls --json` emits no `license` field at all, so the
# licence pass would walk a tree of packages and silently report zero findings.
npm --prefix "$ROOT" ls --json --long --all > "$TMP/tree.json" 2>/dev/null
```

Walk `dependencies` recursively. **Skip any node with no `version`**, uninstalled optional
platform binaries (`*-linux-x64-gnu`, `*-win32-*`) carry no licence because they carry no package,
and counting them invents ~100 phantom findings. Permissive allowlist: MIT, ISC, BSD-2-Clause,
BSD-3-Clause, Apache-2.0, 0BSD. Flag anything else LOW (copyleft (MPL/LGPL/GPL) MODERATE), and
missing/`UNKNOWN` on an *installed* package MODERATE. `license` may be a string or `{type: ...}`.

## 4: Inventory

```bash
npm --prefix "$ROOT" ls --depth=0 2>/dev/null | tail -n +2 | grep -c '^[├└]'   # direct
npm --prefix "$ROOT" ls --all --parseable 2>/dev/null | wc -l                  # total resolved
```

One INFO row: direct count and transitive count (total minus direct); `problems` entries from the tree JSON (extraneous / missing / peer conflicts) become LOW rows.

## 5: Next.js config checklist

Only when `next` is a dependency. Three checks, each an evidence-backed row:

- **Secrets in the client bundle:** `grep -rEn 'NEXT_PUBLIC_[A-Z0-9_]*(KEY|TOKEN|SECRET|PASSWORD)'` over the repo and `.env*`: CRITICAL, every `NEXT_PUBLIC_` var is inlined into shipped JS. Also run `secret-scan.sh --files` over just the `'use client'` files. Never a second pattern set.
- **Headers in `next.config.*`:** read it. No `headers()` block or no `Content-Security-Policy` → HIGH. `Access-Control-Allow-Origin: *` → HIGH. No `X-Frame-Options`/CSP `frame-ancestors` → MODERATE.
- **Exposed environment:** `git ls-files | grep -E '(^|/)\.env'` (a tracked `.env*` that is not `.env.example` is CRITICAL), and `process.env.` inside any `'use client'` file with no `NEXT_PUBLIC_` prefix → HIGH (undefined at runtime, or leaked if bundled).

## 6: Codex triage

Runs once every finding is collected and ranked, before the table prints. Typically under two
minutes; the runner's default timeout caps it at five.

Give every non-INFO row a stable ID (`R1`, `R2`, …) and write the assembled findings into the
audited repo at `"$ROOT/.xcheck/dep-findings-<date>.md"`, not to `$TMP`: the Codex sandbox is not
proven to read a `mktemp -d` path outside the repo, and `.xcheck/` is the path `/health`'s Codex
reviewer and `/build` phase 4.5 both already write to. `Write` is not in this skill's tool grant,
so the file goes down as a heredoc like every other step here:

```bash
DATE="$(date +%F)"; FINDINGS="$ROOT/.xcheck/dep-findings-$DATE.md"
mkdir -p "$ROOT/.xcheck"
cat > "$FINDINGS" <<'EOF'
| ID | Severity | Area | Finding | Where | Fix |
|---|---|---|---|---|---|
| R1 | <severity> | <area> | <the finding> | <file:line or package> | <one action> |
EOF
```

`$ROOT` is what makes that correct on a `/dep-audit ~/AI/salty` run, and the same reason forces
`cd "$ROOT"` around the runner, because codex resolves the path in its prompt against the shell's cwd, so
a bare `.xcheck/…` sends it reading whatever tree the session happens to be sitting in:

```bash
(cd "$ROOT" && bash ~/.claude/skills/xcheck/scripts/codex-run.sh -m gpt-5.6-sol -s read-only \
  "Read .xcheck/dep-findings-$DATE.md — a severity-ranked table of npm supply-chain findings (leaked keys, git history, advisories, licences, inventory, Next.js config), each non-INFO row carrying a stable ID. For every row with an ID, judge: genuinely dangerous for this repository, or noise? Weigh reachability (dev-only or optional dependency, an advisory class not exploitable here), whether a licence matters for an unpublished app, and whether a key row is a documented fixture. Return one line per ID, echoing the ID verbatim: <ID> | danger|noise | <one-sentence reason naming that row's package or file>. Judge every ID and invent none. No preamble.")
```

Then `rm -f "$FINDINGS"` once adjudication is done, whether the triage returned verdicts, failed,
or timed out, `.xcheck/` is gitignored in `~/.claude` and the audited repo may never have heard of
it, so leaving the file behind stages an audit report into someone else's next commit.

The runner returns codex's whole session: a stdin banner, the reasoning, then the final message printed TWICE (once inline, once as the tail block). Parse the LAST block only; counting matches across the raw output double-counts every verdict.

Match each returned line back to its ID. A `noise` verdict **never lowers a severity**, Claude
assigned it, Claude keeps it. The verdict is shown so the reader can discount a row with both
models' reasoning in front of them. An ID Codex skipped gets `—`.

Could not run, a non-zero exit, timeout 124, output that does not parse, or no `codex` on the
machine at all: the table still prints, plus one extra row
`| INFO | Triage | Codex triage DID NOT RUN — <reason> | — | — | — |`. That row is the whole
signal when codex is simply absent, so print it there too rather than staying quiet, an
untriaged table must never read as a triaged one.

## Output: ONE table

Merge every source into a single table, `| Severity | Area | Finding | Where | Fix | Codex |`, ranked CRITICAL → HIGH → MODERATE → LOW → INFO. Not five tables, not one per phase. `Area` is Keys / History / Advisory / Licence / Inventory / Next.js / Triage; `Where` is `file:line`, a package name, or the config key, never "the codebase"; `Fix` is one action, not a paragraph. `Codex` holds `danger` / `noise` / `—` from section 6 and is advisory only. It never changes the severity beside it.

## What this did NOT check

Print this on **every** run, pass or fail, verbatim in substance:

- No OS or container package scanning. Nothing outside `node_modules` was looked at.
- No SBOM was produced.
- No licence-policy or SPDX evaluation, licences are matched against a hardcoded allowlist, not against your policy.
- No infrastructure-as-code checks, Dockerfiles, compose files, terraform and k8s manifests are not read.

**A clean result here therefore does not mean full coverage.** It means npm-level findings only.

## Why these gaps are acceptable

Verified 2026-08-02 across the three active app repos:

- `~/AI/salty`: none.
- `~/AI/wayfinder-redesign`: `docker-compose.yml`, one `postgres:17-alpine` dev database.
- `~/AI/Caliber`: none (its only `.yml` files are Playwright page snapshots).

The gap is *narrow, not absent*. Two repos have no infrastructure to scan; the third's only
container is a stock upstream Postgres for local dev, not built here, not deployed, no
application Dockerfile and no manifests behind it. A container scanner would have one target, and
would repeat what `postgres:17-alpine`'s own release notes say.

**Reconsider a real scanner (Trivy/Grype) the moment any one of these is true:**

1. Any repo gains a `Dockerfile`, an image *you* build is an image you own the CVEs of.
2. `wayfinder-redesign`'s compose grows past a dev-only database, or its image ships anywhere.
3. Any repo gains terraform, a k8s manifest, or a pipeline that builds a container.
