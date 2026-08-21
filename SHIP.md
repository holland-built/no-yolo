# SHIP.md: release playbook for ~/.claude (no-yolo skill library)

Repo: `github.com/holland-built/no-yolo`. Run `/release` from anywhere under `~/.claude`.

Rewritten 2026-08-05. The previous version was written against the catalogue system that the
fresh-start rebuild deleted: eight of its ten steps called `/md-check`, `/update`,
`skills/my-skills/`, `skills/my-md/` or `docs/HOOKS.md`, none of which exist. Two of those <!-- gone-on-purpose -->
were hard blocks, so every release would have stopped forever. **A step belongs here only if
the thing it runs is on disk right now**. Check before adding one.

## Environments
| Env | Branch | Default | Notes |
|-----|--------|---------|-------|
| main | `main` | * | the only branch; publishes to no-yolo |

`main` became the rebuilt setup on 2026-08-05. The two histories were unrelated (the rebuild
started from an empty room), so this was a force-push, not a merge. The pre-rebuild setup is
kept in two places, per the plan's promise that nothing is destroyed:

| Where | What |
|---|---|
| tag `pre-rebuild-2026-08-05` | `main` exactly as it stood before the swap |
| branch `migrate-wshobson-agents` | the same, plus three commits of in-flight work |

**This repo's remote pointed at its own working directory** until 2026-08-05, so every push from
it silently went nowhere and the rebuilt setup sat unpublished while looking pushed. A
self-referencing remote still resolves `origin/*`, still reports "up to date", and still exits 0.
Nothing about it looks wrong. If a branch claims to be in sync but GitHub disagrees, check
`git remote -v` before anything else.

## Steps

1. **Antislop scan (warn only):** scan changed `.md` files against `docs/ANTISLOP.md` writing
   tells; print `| File | Tell | Excerpt |`, never block.

2. **Size check (warn only):** `wc -l ~/.claude/*.md ~/.claude/docs/*.md
   ~/.claude/skills/*/SKILL.md`; table any file >200 lines.

3. **Stale-external sweep (repo mirrors the machine: HARD BLOCK):** every external tool
   referenced in tracked files (a `skills/<name>` .gitignore entry, a setup.sh install or
   suggestion line, a README Add-ons row) must exist on THIS machine right now. Check with
   `ls ~/.agents/skills/<name>`, `ls ~/.claude/.agents/skills/<name>` (newer npx installs land
   here), or `ls skills/<name>`. A reference to something not installed is old shit. Delete the
   reference, don't ship it. Standing rule from a past incident: a tool was uninstalled locally
   but its 16 references shipped for weeks.

   **One exemption: on-demand npx tools.** A tool that is fetched and run by `npx` at call
   time (e.g. `npx -y impeccable detect`) is never on disk by design, so `ls` can only ever
   fail it. For those, check the runner instead: `command -v npx` must succeed, else BLOCK.
   Nothing else relaxes. Anything with a real local path has to be there, right now.

4. **Dangling-reference sweep (HARD BLOCK):** no tracked file may name a doc, skill, agent or
   script that is not on disk. This is the check the old playbook needed and did not have. It is
   how SHIP.md itself came to reference five deleted files without anything noticing.

   Three details in the command below are each there because the naive version fails:

   - **Only backtick-quoted paths count.** This repo cites every real file in backticks. Matching
     bare text instead produces a flood of substring hits, the tail of "ingest-docs/SKILL.md"
     looks like a docs path, and the tail of "~/.agents/skills/x" looks like an agents path.
   - **Driven off `git ls-files`, not a directory walk.** Only tracked files can break a release
     for someone else, and walking directories drags in gitignored third-party folders whose
     contents are never edited here.
   - **The marker is filtered per line, before extraction.** `grep -o` prints only the matched
     path and throws its line away, so filtering afterwards can never see the marker.
   ```bash
   git ls-files -- '*.md' | while read -r src; do
     grep -v 'gone-on-purpose' "$src" \
       | grep -oE '`(docs|skills|hooks|agents|commands)/[A-Za-z0-9._/-]+\.(md|sh|js|py|mjs|json)`' \
       | tr -d '`' | while read -r p; do
           [ -e "$p" ] || [ -e "$(dirname "$src")/$p" ] || echo "DANGLING: $p  (in $src)"
         done
   done | sort -u
   ```
   Any output → STOP and either restore the file or delete the reference.

   **Naming something you deliberately deleted.** Prose that discusses a removed file on purpose
   (this playbook's own header does) would otherwise trip this forever. Put
   `<!-- gone-on-purpose -->` on that line. Use it only for history and rationale, never to
   silence a reference something still follows.

   Gitignored-by-design paths are the one real gap here: `skills/design/vendor/` is absent on a
   fresh clone, so this check passes locally and would fail for a stranger. Anything citing it
   must also name the tracked fallback, the way `docs/ANTISLOP.md` names `TASTE_CORE.md`.

5. **Third-party and setup freshness (warn only: never auto-pull):** run `/checkup` and print
   its drift rows. `/checkup` absorbed the old `/update` and `/md-check`; it reports how far
   behind each vendored directory and cloned marketplace is, and lists borrowed skills nothing
   reads any more. Warn only: `taste-skill` drives what `/design` builds, so a stranger's commit
   must never land silently mid-release.

6. **README format check (HARD BLOCK):** every `## ` heading in `docs/README_FORMAT.md` must
   exist in `README.md`; missing → STOP. Run `bash verify.sh` from the repo root; the
   `README format headings` row must read PASS. This is the identical script CI runs.

7. **README count patch:** update "N custom commands" and "plus N borrowed from other people's
   repos" from the live skill directory counts. Own skills are real directories, borrowed ones
   are symlinks:
   ```bash
   own=0; bor=0
   for d in skills/*/; do [ -L "${d%/}" ] && bor=$((bor+1)) || own=$((own+1)); done
   echo "own=$own borrowed=$bor"
   ```

8. **Config template check (HARD BLOCK):** `settings.example.json` must parse
   (`python3 -c "import json;json.load(open('settings.example.json'))"`); its hook command
   strings must use `$HOME/` not a quoted `~/` (a quoted `~` never expands, hard-fail on any
   match of `grep -c '"~/.claude/hooks' settings.example.json`, want `0`); and every hook path
   referenced must exist on disk. Run `bash verify.sh`; the `settings.example.json parses` and
   `hook paths exist` rows must read PASS. A missing hook script or a quoted-`~` path means
   fresh installs get a failing hook every turn. Both shipped once
   (`log-learnings-stop.sh`, quoted-`~` paths); never again.

9. **Prune stale mockups (every release, all repos):**
   ```bash
   bash ~/.claude/skills/design/scripts/mockup-dir.sh --prune
   ```
   Deletes `.mockups/` folders untouched for 30+ days, and removes `.mockups/` entirely once
   empty. Refuses to touch anything under 7 days old whatever number you pass. Mockups are
   disposable and gitignored, so nothing else prunes them and they accumulate silently: 21MB in
   one repo, 8.5MB in another before anyone looked. Report one line; never block on it.

## Stage scope

```
git add skills/ docs/ hooks/ .github/ agents/ commands/ README.md INSTALL.md LICENSE \
  .gitignore .no-yolo-deny.example.txt setup.sh settings.example.json SHIP.md CLAUDE.md \
  memory/bin/ memory/CLAUDE.generated.md memory/SCHEMA.md verify.sh verify-selftest.sh
```

Explicit paths: do NOT rely on a `*.md` shell glob, which expands in the CWD rather than the
repo root. Each of these was omitted once and something silently never shipped:

- `.github/` holds `workflows/ci.yml`, the workflow that runs verify.sh: omitted once, so a
  CI-config fix could never ship.
- `verify.sh` and `verify-selftest.sh` are tracked and CI runs them: omitted once, so a fix to
  the verifier itself silently never shipped.
- Under `memory/`, exactly three tracked things must ship: `bin/*.py`, `CLAUDE.generated.md`
  (imported by CLAUDE.md), and `SCHEMA.md`. `memory/facts/` stays private via .gitignore, which
  is what the `memory/` Guard protects. `CLAUDE.generated.md` was missing once, so a
  `/memory-compile` could never reach GitHub.
- `LICENSE` is the MIT terms the README's licence badge reads: omit it and the badge renders
  "unknown" against a file git never received.
- `.no-yolo-deny.example.txt` is the tracked template for the gitignored `.no-yolo-deny.txt`.
- `agents/` (subagent roster) and `commands/` (utility commands) are tracked and must ship.

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
  understands them. There is no changelog file to read from, the rebuild deleted
  `docs/DAILY_CHANGELOG.md`, which was the single most-edited file in the repo and the reason <!-- gone-on-purpose -->
  every change had become five changes.
- `gh release create "$TAG" --repo holland-built/no-yolo --title "$TAG" --notes "$NOTES"`
- Update the repo description with the current custom-skill count.
- If `gh` is missing or unauthed: print `⚠️ release skipped — run gh auth login` and continue.
