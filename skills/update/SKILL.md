---
name: update
description: Use this skill when the user types /update, says 'check for updates', 'am I out of date', 'what's new', 'update my setup', or 'rollback'. Two-way reconciliation between your local ~/.claude and its published copy on GitHub — checks not just what GitHub has that you don't (behind), but what you have that GitHub doesn't yet (ahead, or plain uncommitted work — points to /release to publish). Also covers plugin version status and vendored third-party skill drift (docs/THIRD_PARTY_SKILLS.md). `/update vendor <name>` and `/update marketplace <name>` actually apply third-party updates (re-vendor / git pull) — the only steps that touch third-party content, always behind a confirm.
user-invocable: true
model: sonnet
argument-hint: "[preview|full|rules|rollback|restore <name>|vendor <name>|marketplace <name>]"
---

# update

Check if your Claude Code setup is out of date, preview what would change, and update safely.

## Modes

| Command | What it does |
|---|---|
| `/update` | Check if you're behind — shows how many versions, what's new, what's removed |
| `/update preview` | Detailed plain-English changelog without changing anything |
| `/update full` | Pull all changes + re-run full setup |
| `/update rules` | Pull changes + rules only (no tool installs) |
| `/update rollback` | Undo the last update, go back to what you had |
| `/update restore <skill-name>` | Bring back a skill that was removed in an update |
| `/update vendor <name>` | Re-vendor a stale third-party skill (e.g. taste-skill) from upstream, re-pin the commit |
| `/update marketplace <name>` | `git pull` a stale orphaned marketplace (e.g. impeccable) to latest |

## How to run

### Step 1 — fetch remote state (no changes made yet)
Run silently:
```bash
cd ~/.claude
git fetch origin main 2>/dev/null
```

### Step 2 — reconcile both directions
`github.com/holland-built/no-yolo` is your published copy. Check BOTH directions, not just "am I behind":
```bash
cd ~/.claude
BEHIND=$(git rev-list HEAD..origin/main --count)
AHEAD=$(git rev-list origin/main..HEAD --count)
DIRTY=$(git status --porcelain)
```
- **BEHIND > 0** — GitHub has commits you don't → Steps 3-4.
- **AHEAD > 0** — local commits GitHub doesn't have. List them (`git log origin/main..HEAD --oneline`, same prefix translation as Step 3). Tell user: "You have N local commit(s) not on GitHub yet. Run `/release` to publish them." Never push from here — `/release` is the sole publish command.
- **DIRTY non-empty** — uncommitted files that neither BEHIND nor AHEAD can see (the most common gap: a whole work session sitting in `git status`). List the files from `$DIRTY` grouped Modified / New. Tell user: "You also have M uncommitted change(s) — not yet part of any commit."

If BEHIND = 0 AND AHEAD = 0 AND DIRTY empty: output "Your machine and GitHub are identical — everything reconciled." Skip Steps 3-4 but still run Steps 4.5-4.7 — they check different things (plugins, vendored content, marketplaces) and must never be skipped just because the core repo is in sync.

If BEHIND > 0: continue to Step 3.

### Step 3 — translate commits into plain English
```bash
git log HEAD..origin/main --oneline
```
Prefix translation: `feat:`/`feat(` → "New:", `fix:`/`fix(` → "Fixed:", `docs:`/`docs(` → "Docs updated:", `chore:`/`refactor:` → "Cleanup (no action needed):", `remove`/`nuke`/`delete` in message → ⚠️ "Removed:". Show as a numbered list, newest first. No git hashes. No jargon.

### Step 4 — detect what's new and what's removed
```bash
# New skills added remotely
git diff HEAD origin/main --name-status | grep "^A.*skills/.*/SKILL\.md"

# Skills removed remotely  
git diff HEAD origin/main --name-status | grep "^D.*skills/.*/SKILL\.md"

# Rule files changed
git diff HEAD origin/main --name-status | grep -E "^M.*(CLAUDE|CORE_RULES|PLANNING|TESTING|SUBAGENTS|CODE_REVIEW)\.md"
```
Format output:
```
📦 What you'd get:
  + /quick-mockup skill (new)
  + /brief skill (new)
  ~ PLANNING.md updated (rules changed)

⚠️  What would be removed:
  - /debate skill (renamed to /brief — use /update restore debate to get it back)

ℹ️  You are 3 updates behind.
```
Nothing removed → skip the ⚠️ section entirely.

### Step 4.5 — plugin status (read-only — never auto-update)
```bash
python3 "$HOME/.claude/hooks/list-plugins.py"
```
(Shared lister — same script setup.sh Step 5 uses. Prints TSV `name<TAB>version<TAB>scope`, or "No plugins installed.")

Table: **Plugin | Installed version | Scope**. Flag version `unknown` or `?` as ⚠️ "may be stale — reinstall to pin a version". Then output verbatim:
> To check for plugin updates, run `/plugin list` inside Claude Code, then `/plugin update <name>` for any that are outdated. Plugins can't be updated from outside the session.

### Step 4.6 — vendored third-party skill drift (read-only)
Read `docs/THIRD_PARTY_SKILLS.md` for names + local paths (none of this content is in git — see that file). For each row:
```bash
if [ ! -f "<local-path>/SOURCE.md" ]; then
  echo "<name>: NOT INSTALLED"
else
  PINNED=$(grep "Pinned commit" "<local-path>/SOURCE.md" | grep -oE '[0-9a-f]{40}')
  HEAD=$(gh api repos/<upstream-repo>/commits/main --jq '.sha' 2>/dev/null)
fi
```
Table: **Name | Status** — `not installed — run /update vendor <name> to install` if `SOURCE.md` is missing, `up to date` if `PINNED = HEAD`, else `⚠️ STALE — N commits behind` (N via `gh api repos/<repo>/compare/<pinned>...main --jq '.ahead_by'`). If `gh` missing/unauthed or the table has no rows: skip this step silently.

Never auto-update inside this check — output:
> Vendored skill "<name>" is behind upstream. Run `/update vendor <name>` to re-vendor it.

### Step 4.7 — orphaned marketplaces (read-only)
Marketplaces git-cloned into `plugins/marketplaces/<name>/` with **no** `<plugin>@<name>` key in `installed_plugins.json` are invisible to Step 4.5, so a skill can drift with zero warning (e.g. `impeccable`, cloned straight from `pbakaus/impeccable`).
```bash
python3 - "$HOME/.claude/plugins/known_marketplaces.json" "$HOME/.claude/plugins/installed_plugins.json" <<'PYEOF'
import json, sys, os
mkt_p, inst_p = sys.argv[1], sys.argv[2]
mkts = json.load(open(mkt_p)) if os.path.exists(mkt_p) else {}
installed = json.load(open(inst_p)).get("plugins", {}) if os.path.exists(inst_p) else {}
covered = {k.split("@", 1)[1] for k in installed if "@" in k}
for name, info in mkts.items():
    if name in covered:
        continue
    loc = info.get("installLocation", "")
    if loc and os.path.isdir(os.path.join(loc, ".git")):
        print(f"{name}\t{loc}")
PYEOF
```
For each orphaned marketplace printed, run in its directory:
```bash
LOCAL=$(git rev-parse HEAD); REMOTE=$(git ls-remote origin HEAD | cut -f1)
```
Table: **Marketplace | Status** — `up to date` if `LOCAL = REMOTE`, else `⚠️ STALE — behind upstream`. If none are orphaned or `git`/network fails: skip silently.

Never auto-update inside this check — output:
> "<name>" isn't tracked by the plugin system. Run `/update marketplace <name>` to pull it to latest.

### Step 5 — offer options (when run with no argument)
After the summary, output:
```
What do you want to do?
  /update preview            — see the full detailed changelog
  /update full               — apply everything (pulls + installs tools + offers third-party updates)
  /update rules               — apply rules only (no tool installs)
  /update rollback            — go back to what you had before
  /update vendor <name>       — re-vendor a stale third-party skill
  /update marketplace <name>  — git pull a stale orphaned marketplace
```
(The last two only appear if Steps 4.6/4.7 found something STALE.) Then stop. Do not auto-pull.

### Step 6 — if argument is `preview`
For each changed .md file: state what file and section changed, quote before/after for changed lines ("was: / now:" format), highlight deleted lines (user may want to keep them). Do NOT show raw git diff output — translate everything.

### Shared: sync-and-run
Used by Steps 7 and 8. Substitute `<SETUP_CMD>` with the caller's command.

**Dirty-check stash guard:**
```bash
cd ~/.claude && DIRTY=$(git status --porcelain)
```
If DIRTY non-empty: tell user "You have local changes I'm setting aside safely before updating." Run `git stash push -m "pre-update stash $(date +%Y-%m-%d)"`. After pull completes run `git stash pop`. If pop conflicts: "Some of your local changes conflicted with the update. Your originals are in git stash — run `git stash pop` in your terminal to review."

**AHEAD detection:**
```bash
cd ~/.claude
AHEAD=$(git rev-list origin/main..HEAD --count 2>/dev/null || echo 0)
```
**If AHEAD = 0:** `git merge --ff-only origin/main && <SETUP_CMD>`

**If AHEAD > 0:** Tell user "You have [N] local commit(s). Rebasing on top of latest."
```bash
CONFLICTS=""
git rebase origin/main; REBASE_EXIT=$?
[ $REBASE_EXIT -ne 0 ] && CONFLICTS=$(git diff --name-only --diff-filter=U 2>/dev/null) && git rebase --abort
```
If rebase failed: tell user commits are untouched, list CONFLICTS, print `git fetch origin main && git rebase origin/main` + `git rebase --continue`. STOP. If rebase succeeded: run `<SETUP_CMD>`.

### Step 7 — if argument is `full`
Confirm: "Pulling all updates and re-running setup. This takes about 30 seconds. Continue? (y/n)"

Run **Shared: sync-and-run** with `bash ~/.claude/setup.sh` as `<SETUP_CMD>`.

After success: plain-English summary of what changed. Then re-run Steps 4.6 and 4.7's checks — for any row/marketplace STALE, ask once: "Also update third-party content — <names> — to latest? (y/n)". If yes, run Step 11 (`vendor <name>`) and/or Step 12 (`marketplace <name>`) for each. Tell user: "Reopen Claude Code to pick up the changes."

### Step 8 — if argument is `rules`
Run **Shared: sync-and-run** with `bash ~/.claude/setup.sh --md-only` as `<SETUP_CMD>`. Tell user: "Rules updated. Tool installs skipped. Reopen Claude Code to pick up changes."

### Step 9 — if argument is `rollback`
**First: same dirty-check guard as Step 7.** If DIRTY non-empty: "You have unsaved local changes. Rolling back would delete them. Type `cancel` to stop." Wait for response.

**Create a restore point before touching anything:**
```bash
git tag claude-restore-$(date +%Y%m%d-%H%M%S)
```
Tell user: "Saved a restore point — if anything goes wrong you can always get back to right now."

Show last 5 states as a numbered list with plain-English dates:
```
Your recent setup history:
  1. Today (current) — added /brief skill, updated PLANNING.md
  2. 3 days ago — fixed README typos
  3. Last week — added token-saving docs

Which one do you want to go back to? (type the number)
```
After user picks, use `git revert` (keeps history, safe) NOT `git reset --hard` (permanent, destructive):
```bash
git revert --no-commit <hash-range>
git commit -m "rollback: reverted to <chosen-date>"
```
Tell user: "Rolled back. Nothing permanently deleted — your history is preserved. Reopen Claude Code to pick up the changes."

### Step 10 — if argument is `restore <skill-name>`
```bash
git show origin/main:skills/<skill-name>/SKILL.md > ~/.claude/skills/<skill-name>/SKILL.md
```
If the skill doesn't exist on origin/main either, search recent history:
```bash
git log --all --oneline -- skills/<skill-name>/SKILL.md
```
Show which commits touched that skill and let the user pick which version to restore. After restoring: remind user to add the trigger back to CLAUDE.md if they want `/skill-name` to work.

### Step 11 — if argument is `vendor <name>`
Look up `<name>` in `docs/THIRD_PARTY_SKILLS.md`. If no row matches: "No vendored third-party skill named '<name>' — see `/update` to see what's tracked." Stop.

`<vendor-path>` is gitignored — never touches git, never committed; the command works identically for a first install or a refresh.

If `<vendor-path>/SOURCE.md` doesn't exist yet: "Installing '<name>' from <upstream-repo> to <vendor-path> (local only, never published). Continue? (y/n)"
If it exists: "Re-fetching '<name>' from <upstream-repo>. This overwrites the local copy under <vendor-path>. Continue? (y/n)"
```bash
VENDOR_PATH="<vendor-path from the row>"
REPO="<upstream-repo from the row>"
mkdir -p "$VENDOR_PATH"
NEW_SHA=$(gh api "repos/$REPO/commits/main" --jq '.sha')
for base in <file basenames from the row's "Used by"/known file list, e.g. taste-skill redesign-skill image-to-code-skill>; do
  curl -s "https://raw.githubusercontent.com/$REPO/main/skills/$base/SKILL.md" -o "$VENDOR_PATH/$base.md"
done
```
(Convention: local `<vendor-path>/<x>.md` always maps to upstream `skills/<x>/SKILL.md`.)

Write or update `<vendor-path>/SOURCE.md` with: Upstream, License, Pinned commit (`$NEW_SHA`), Vendored date (today), Files, Used by — same shape as the existing `taste-skill/SOURCE.md`.

Show a `diff`-style summary of what changed (or "installed N files" if first install). Tell user: "'<name>' ready at <vendor-path> (commit <NEW_SHA short>, local only). Review before your next `/design` run — these files directly drive what it builds."

### Step 12 — if argument is `marketplace <name>`
Look up `<name>` in `known_marketplaces.json`'s `installLocation`. If missing or not a git repo: "'<name>' isn't a git-cloned marketplace — nothing to pull." Stop.

Confirm: "Pulling '<name>' to latest from its upstream repo. Continue? (y/n)"
```bash
cd "<installLocation>"
BEFORE=$(git rev-parse --short HEAD)
git pull origin main 2>&1
AFTER=$(git rev-parse --short HEAD)
```
Tell user: "'<name>' updated from $BEFORE to $AFTER." If `BEFORE = AFTER`: "'<name>' was already up to date." If pull fails (conflicts/dirty tree in that clone): show the git error verbatim and stop — do not force anything.
