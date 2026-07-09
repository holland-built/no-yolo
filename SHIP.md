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
6. **README format check (HARD BLOCK):** every `## ` heading in `docs/README_FORMAT.md` must exist in `README.md`; missing → STOP.
7. **README count patch:** update "N custom commands" / "plus N borrowed from plugins" from the live skill dir counts.
8. **Regenerate menus:** rebuild `skills/my-skills/RENDERED.md` and `RENDERED_FAST.md` from `CATEGORIES.md` + `TAGLINES*.md` + `WHEN_TO_USE.md` + `WHY_TO_USE.md` (see the regen scripts kept in this repo's ship history). A skill in `CATEGORIES.md` with no `TAGLINES_SHORT.md` line renders "⚠️ missing". Content check, not just format: every tagline in `RENDERED.md` must match the current `TAGLINES.md` line verbatim — a mismatch means someone edited one and forgot the other; sync from TAGLINES.md (source of truth).
9. **Config template check (HARD BLOCK):** `settings.example.json` must parse (`python3 -c "import json;json.load(open('settings.example.json'))"`), and every `~/.claude/hooks/*` path referenced in its hook commands must exist on disk (`grep -oE '~/.claude/hooks/[a-zA-Z0-9._-]+' settings.example.json | sort -u`, test each with the `~` expanded). A missing hook script means fresh installs get a failing hook every turn — this shipped once (`log-learnings-stop.sh`); never again.

Stage scope: `git add skills/ docs/ README.md .gitignore` (explicit paths — do NOT rely on a `*.md` shell glob; it expands in the CWD, not the repo root).

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
