# SHIP.md: release playbook for ~/.claude (no-yolo skill library)

Repo: `github.com/holland-built/no-yolo`. Run `/release` from anywhere under `~/.claude`.

**A step belongs here only if the thing it runs is on disk right now.** Check before adding
one, and check again after any rebuild. This playbook twice came to name deleted files, both
times leaving hard blocks that could never pass; `docs/DECISIONS.md` records both.

## Environments
| Env | Branch | Default | Notes |
|-----|--------|---------|-------|
| main | `main` | * | the only branch; publishes to no-yolo |

If a branch claims to be in sync but GitHub disagrees, check `git remote -v` before anything
else. This repo's remote pointed at its own working directory until 2026-08-05, and every push
silently went nowhere while reporting success.

## Steps

Steps 1 to 8 read the tree and write nothing, and none needs another's result. Run them as
one batch: `bash verify.sh` once (steps 4, 6 and 8 are three rows of that one run), with
`/checkup` and the step 1, 2, 3 and 7 commands beside it, then read all the output together.
The numbering is for reading, not for ordering. What stays serial is everything after: the
secrets gate, then staging, then the commit, then the push, then reading the target.

### 1. Writing check

**Warn only.** Print `| File | Tell | Excerpt |`; never block.

```bash
{ git diff --name-only origin/HEAD -- '*.md'; git ls-files --others --exclude-standard -- '*.md'; } \
  | sort -u | while read -r f; do
  printf '{"tool_input":{"file_path":"%s/%s"}}' "$PWD" "$f" | bash hooks/slop-block.sh
done
```

The hook takes a tool-call payload on standard input, not a filename, because that is how
Claude Code invokes it, which is what the `printf` wrapper is for. The change set is
`origin/HEAD` plus untracked `.md` rather than `--cached`, because staging happens after this
step and a `--cached` list here would be empty.

**Expected:** nothing. The hook already fires on every Write and Edit, so a finding means a
file reached git without passing through one.

**Risk if skipped:** the hook decides only what a program can decide, so read the judgement
rules in `docs/PROSE.md` against the same files yourself.

### 2. Size check

**Warn only.** With `CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"`, run
`wc -l "$CFG"/*.md "$CFG"/docs/*.md "$CFG"/rules/*.md "$CFG"/skills/*/SKILL.md`; table any
file >200 lines.

**Risk if skipped:** a file grows past the point where attention thins across it, one commit
at a time, and no single commit looks wrong.

### 3. Stale-external sweep

**Mostly automatic since 2026-08-25.** `verify.sh`'s "pieces on this machine" row runs this
check on every push, from `hooks/pre-push`, against `hooks/installed.txt` and the artefact
lists in `hooks/retired.txt`. It reports WARN on a hosted runner, which has none of these
tools, and answers properly here. What follows is now a confirmation of a row you have already
seen, plus the two judgements a manifest cannot make: whether a newly added piece was ever
written into `hooks/installed.txt`, and whether a reference belongs in the repo at all.

This step stayed a human one for a day too long. It is a hard block written for exactly the
StyleSeed case, and it never fired, because nobody released between the retirement and the day
the leftovers were found by accident.

**HARD BLOCK.** The repo mirrors the machine: every external tool referenced in tracked files
(a row in `INSTALL.md`, a `skills/<name>` .gitignore entry, a README prerequisite) must exist
on THIS machine right now.

Check with `ls ~/.agents/skills/<name>`,
`ls "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/.agents/skills/<name>` (newer npx installs land
here), `ls skills/<name>`, or `command -v <tool>` for anything installed globally.

**Expected:** every reference resolves. A reference to something not installed is old shit.
Delete the reference, don't ship it.

Two carve-outs, and nothing else relaxes:

- **`INSTALL.md` may name a tool this machine does not have,** because its whole subject is
  what to install. What it must not do is claim one is present.
- **On-demand npx tools** are fetched and run at call time (e.g. `npx -y impeccable detect`),
  so they are never on disk by design and `ls` can only ever fail them. Check the runner
  instead: `command -v npx` must succeed, else BLOCK.

**Risk if skipped:** a tool was once uninstalled locally and its 16 references shipped for
weeks.

### 4. Dangling-reference sweep

**HARD BLOCK.** Run `bash verify.sh` and read the `dangling references` row.

**Expected:** PASS. No tracked `.md`, `.sh` or `.js` may name a doc, skill, agent or script
that is not on disk. Any failure names the citing file and the missing path: restore the file
or delete the reference.

The row is the only live copy of this check. It runs on every push and in CI on both
platforms, and `verify-selftest.sh` sabotages it to prove it can still go red. `SHIP.md`
carried a second copy until 2026-08-25, under a sentence claiming it was the same code; it was
not, and `docs/DECISIONS.md` holds it as evidence along with the three details that make the
live row work.

**Writing prose about a file you deliberately deleted.** That would trip this row forever, so
put `<!-- gone-on-purpose -->` on the same line as the reference. Per line, not per file. Use
it for history and rationale only, never to silence a reference something still follows.

**Naming a vendored file.** The vendored skill directories are gitignored per-name, so a
backticked path inside one passes here and fails in CI. Name such a file in plain words rather
than backticks, and say it is vendored.

**Risk if skipped:** this is the step whose absence let the playbook ship five references to
deleted files.

### 5. Outside-tool freshness

**Warn only, and never auto-pull.** Run `/checkup` and print its drift rows. It reports how
far behind this clone is against GitHub, and which of the borrowed pieces in `INSTALL.md` are
absent.

**Expected:** drift rows are information, not a gate. Never install anything mid-release: an
outside tool that arrives in the middle of a publish has not been watched working. The count
lives in `INSTALL.md` alone, so this step cannot name a number that has drifted.

Whether those tools are the tools they claim to be is not a judgement call and is not here:
`hooks/external-check.sh` resolves every one against the registry on every run of `verify.sh`,
and a name that does not resolve to the project `hooks/externals.txt` pins is a hard failure,
not a drift row.

### 6. README inventory rows

**HARD BLOCK.** Run `bash verify.sh` and read two rows.

| Row | What it holds together |
|---|---|
| `README skills inventory` | The skill NAMES in README's table against tracked `skills/*/SKILL.md`, both directions, plus the spelled number in the sentence above the table |
| `README outside-pieces count` | Both sentences that publish the outside-pieces number, against the rows in INSTALL.md's pieces table |

**Expected:** PASS on both. A failure prints the diff of which side has what.

**Risk if skipped:** the front page publishes two numbers, and both went stale before anything
watched them. `docs/DECISIONS.md` records why a hand-run count could not do this job.

### 7. README prose sweep

**Warn only.** Step 6 keeps two numbers honest and nothing reads the other 270 lines. Step 4
catches a path that stopped resolving. Neither can catch a sentence whose every path resolves
and whose description is wrong.

Print every README line naming a skill or rule this release changes, and read those lines
against what the change actually did:

```bash
git diff --name-only origin/HEAD -- skills/ rules/ \
  | awk -F/ '{print $1 "/" $2}' | sort -u \
  | while IFS= read -r p; do
      n="$(basename "${p%.md}")"
      hits="$(grep -nF -- "$n" README.md || true)"
      if [ -n "$hits" ]; then printf '%s\n' "$hits" | sed "s|^|$n  |"
      elif [ -e "$p" ]; then echo "$n  NO README MENTION (it exists; the page never introduces it)"
      else echo "$n  removed, and the page never named it: nothing to re-read"; fi
    done
```

Read the line, never the count: some skill names are ordinary English words, so `design` and
`release` match prose that is not about them. Four further details in that command are each
there because the obvious version fails, and `docs/DECISIONS.md` explains all four before
anyone edits it.

Warn only, on purpose. Whether a sentence still reads true is a judgement, and a block on a
judgement gets satisfied by editing the sentence until the gate stops complaining.

**The acknowledgement, and this part is required.** A judgement cannot be gated, but it can be
required to happen. When this release touches `hooks/`, `verify.sh`, `skills/build/stages/` or
`INSTALL.md`, print the README lines that describe them and write into the release report
either "still true" or the edit made.

```bash
base="$(git describe --tags --abbrev=0 2>/dev/null || echo origin/HEAD)"
git diff --name-only "$base"..HEAD -- hooks/ verify.sh skills/build/stages/ INSTALL.md \
  | grep -q . && grep -nE 'hook|verify|gate|stage|piece|tool' README.md
```

**Expected:** a line in the release report, in words, for every one of those four paths the
release touched. An empty acknowledgement is a failed step even though nothing blocks.

**Risk if skipped:** a release once changed 36 files across all four of those paths while
README moved by three lines, every one of them a number.

### 8. Config template check

**HARD BLOCK.** Run `bash verify.sh`; the `settings.example.json parses` and `hook paths exist`
rows must read PASS. Three things must hold:

- It parses: `python3 -c "import json;json.load(open('settings.example.json'))"`.
- Its hook command strings use `$HOME/` and not a quoted `~/`, because a quoted `~` never
  expands. Hard-fail on any match of `grep -c '"~/.claude/hooks' settings.example.json`, want
  `0`.
- Every hook path referenced exists on disk.

**Risk if skipped:** a missing hook script or a quoted-`~` path means fresh installs get a
failing hook every turn. Both shipped once (`log-learnings-stop.sh`, quoted-`~` paths); never
again.

## Stage scope

Explicit paths. Do NOT rely on a `*.md` shell glob, which expands in the CWD rather than the
repo root.

<!-- jscpd:ignore-start -->
```
git add skills/ docs/ rules/ hooks/ .github/ archive/ styles/ output-styles/ refs/ \
  README.md INSTALL.md LICENSE \
  .gitignore .no-yolo-deny.example.txt .vale.ini .jscpd.json \
  setup.sh settings.example.json SHIP.md CLAUDE.md \
  memory/MEMORY.example.md verify.sh verify-selftest.sh
```
<!-- jscpd:ignore-end -->

| Path | What it is |
|---|---|
| `skills/`, `docs/`, `rules/` | The instructions. `rules/` holds what two or more skills share, so one number cannot drift from the other |
| `hooks/` | The scripts that run by themselves, and their tests |
| `.github/` | `workflows/ci.yml`, the workflow that runs `verify.sh` |
| `verify.sh`, `verify-selftest.sh` | The verifier and the file that proves each of its rows can still go red. CI runs both |
| `archive/` | Skills kept for their text rather than for loading, plus `archive/styleseed/`, a hash-verified snapshot of 23 skills that were never in git |
| `styles/`, `.vale.ini` | The prose linter's rules and its config. `verify.sh` passes `--config "$ROOT/.vale.ini"` by name |
| `.jscpd.json` | The duplicate scanner's config. `hooks/dupe-check.sh` falls back to the copy beside it |
| `output-styles/` | How answers are written to the owner. `settings.json` names it, so a clone without it has a dangling `outputStyle` |
| `refs/` | Vendored reference data rather than code: 74 brand specifications under MIT. Top level, not under a skill, on purpose |
| `memory/MEMORY.example.md` | The only tracked thing under `memory/`. The real index and the facts are gitignored, because both name things about the owner |
| `LICENSE` | The MIT terms the README's licence badge reads |
| `.no-yolo-deny.example.txt` | The tracked template for the gitignored `.no-yolo-deny.txt` |

Every path in that list was omitted once, and something silently never shipped each time;
`docs/DECISIONS.md` records what each omission cost, and why two paths that used to be there
are not.

After staging, confirm nothing tracked was left behind: `git status --porcelain | grep -v '^[AMD]'`
should list only Guard paths and gitignored files. Anything else means the scope above is
missing a path.

## Guards
- memory/
- brainstorms/
- plans/
- proposals/
- projects/
- sessions/
- settings.json
- settings.local.json
- history.jsonl
- *.log
- cache/
- paste-cache/
- learnings.md   (personal; gitignored: never publish)

## Release

Dated GitHub release. Optional, only when the user asks to publish, not on a plain push.

- `TAG="v$(date +%Y-%m-%d)"`; if it exists, delete and recreate.
- Notes = the commit subjects since the previous tag
  (`git log --oneline "$(git describe --tags --abbrev=0 HEAD^)"..HEAD`), rewritten so a stranger
  understands them. There is no changelog file to read from, and no plan to add one;
  `docs/DECISIONS.md` records what the last one cost.
- `gh release create "$TAG" --repo holland-built/no-yolo --title "$TAG" --notes "$NOTES"`
- Update the repo description with the current custom-skill count.
- If `gh` is missing or unauthed: print `⚠️ release skipped: run gh auth login` and continue.
