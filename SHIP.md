# SHIP.md — release playbook for ~/.claude (no-yolo skill library)

Repo: `github.com/holland-built/no-yolo`. Run `/release` from anywhere under `~/.claude`.

## Environments
| Env | Branch | Default | Notes |
|-----|--------|---------|-------|
| main | main | * | the only branch; publishes to no-yolo |

## Steps
1. **Antislop scan (warn only):** scan changed `.md` files against `docs/ANTISLOP.md` writing tells; print `| File | Tell | Excerpt |`, never block.
2. **Size check (warn only):** `wc -l ~/.claude/*.md ~/.claude/docs/*.md ~/.claude/skills/*/SKILL.md`; table any file >200 lines.
3. **Drift check (warn only):** run `/md-check --drift`; print DRIFT/WRONG verdicts. Actually invoke it — do not substitute an ad-hoc grep.
3.5. **Orphan check (warn only):** run `/md-check --orphans`; print DANGLING/UNREFERENCED verdicts. This is the standing "nothing on GitHub that isn't real, nothing real that's invisible" guarantee — the repo is meant to be a full working backup/template, so a dangling reference (describes something that no longer exists) or an unreferenced skill (exists but undiscoverable) both defeat that purpose. Actually invoke it every run — this is not optional busywork, it's the check that would have caught the impeccable mess before it shipped.
4. **GLOBAL_DESCRIPTIONS coverage (warn only):** every root/docs `.md` must have a line in `skills/my-md/GLOBAL_DESCRIPTIONS.md`; print MISSING.
5. **Changelog:** prepend today's dated section to `docs/DAILY_CHANGELOG.md` — one plain-English bullet per changed skill/doc (skip `.gitignore` and the changelog itself).
6. **README format check (HARD BLOCK):** every `## ` heading in `docs/README_FORMAT.md` must exist in `README.md`; missing → STOP. Run `bash verify.sh` from the repo root; the `README format headings` row must read PASS. This is the identical script CI runs.
7. **README count patch:** update "N custom commands" / "plus N borrowed from plugins" from the live skill dir counts.
8. **Regenerate menus:** rebuild `skills/my-skills/RENDERED.md` and `RENDERED_FAST.md` from `CATEGORIES.md` + `TAGLINES*.md` + `WHEN_TO_USE.md` + `WHY_TO_USE.md` (run: `python3 skills/my-skills/regen.py` — then verify with `git diff --exit-code`). A skill in `CATEGORIES.md` with no `TAGLINES_SHORT.md` line renders "⚠️ missing". Content check, not just format: every tagline in `RENDERED.md` must match the current `TAGLINES.md` line verbatim — a mismatch means someone edited one and forgot the other; sync from TAGLINES.md (source of truth).
9. **Config template check (HARD BLOCK):** `settings.example.json` must parse (`python3 -c "import json;json.load(open('settings.example.json'))"`); its hook command strings must use `$HOME/` not a quoted `~/` (a quoted `~` never expands — hard-fail on any match of `grep -c '"~/.claude/hooks' settings.example.json`, want `0`); and every hook path referenced must exist on disk (`grep -oE '(\$HOME\|~)/.claude/hooks/[a-zA-Z0-9._-]+' settings.example.json | sed "s#^\$HOME#$HOME#; s#^~#$HOME#" | sort -u`, test each). A missing hook script or a quoted-`~` path means fresh installs get a failing hook every turn — both shipped once (`log-learnings-stop.sh`, quoted-`~` paths); never again. Run `bash verify.sh` from the repo root; the `settings.example.json parses` and `hook paths exist` rows must read PASS. This is the identical script CI runs.

Stage scope: `git add skills/ docs/ hooks/ README.md .gitignore setup.sh settings.example.json SHIP.md CLAUDE.md memory/bin/` (explicit paths — do NOT rely on a `*.md` shell glob; it expands in the CWD, not the repo root. `memory/bin/` only — the rest of `memory/` is a Guard.).

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
- learnings.md   (personal; gitignored — never publish)

## Release
Dated GitHub release, publish step (optional — only when the user asks to publish, not on a plain push):
- `TAG="v$(date +%Y-%m-%d)"`; if it exists, delete + recreate.
- Notes = today's `DAILY_CHANGELOG.md` bullets; summary line counts new skills (`added /x`) + total changes.
- `gh release create "$TAG" --repo holland-built/no-yolo --title "$TAG" --notes "$NOTES"`
- Update repo description with current custom-skill count.
- If `gh` missing/unauthed: print `⚠️ release skipped — run gh auth login` and continue.
