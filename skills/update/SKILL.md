---
name: update
description: Use this skill when the user types /update, says 'check for updates', 'am I out of date', 'what's new', 'update my setup', or 'rollback'. Two-way reconciliation between your local ~/.claude and its published copy on GitHub — checks not just what GitHub has that you don't (behind), but what you have that GitHub doesn't yet (ahead, or plain uncommitted work — points to /release to publish). Also covers plugin version status and vendored third-party skill drift (docs/THIRD_PARTY_SKILLS.md). `/update vendor <name>` and `/update marketplace <name>` actually apply third-party updates (re-vendor / git pull) — the only steps that touch third-party content, always behind a confirm.
user-invocable: true
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

### Step 2 — reconcile both directions (not just "am I behind")

`github.com/holland-built/no-yolo` is your published copy — the place you or anyone else
copies this setup from. Reconciliation means checking BOTH directions, not just whether
GitHub has something you don't:

```bash
cd ~/.claude
BEHIND=$(git rev-list HEAD..origin/main --count)
AHEAD=$(git rev-list origin/main..HEAD --count)
DIRTY=$(git status --porcelain)
```

- **BEHIND > 0** — GitHub has commits your machine doesn't. Covered by Steps 3-4 below.
- **AHEAD > 0** — your machine has commits GitHub doesn't (built locally, never published).
  List them: `git log origin/main..HEAD --oneline` (same plain-English prefix translation as
  Step 3). Tell user: "You have N local commit(s) not on GitHub yet. Run `/release` to publish
  them." Never push from here — `/update`'s job is to report, `/release` is the sole publish
  command.
- **DIRTY non-empty** — files changed or created on disk that aren't even committed yet (the
  most common gap: a whole work session sitting in `git status` that neither BEHIND nor AHEAD
  can see, since it's not a commit at all). List the files from `$DIRTY` grouped as Modified /
  New. Tell user: "You also have M uncommitted change(s) — not yet part of any commit."

If BEHIND = 0 AND AHEAD = 0 AND DIRTY is empty: output "Your machine and GitHub are
identical — everything reconciled." Skip Steps 3-4 (nothing remote to translate) but still run
Steps 4.5-4.7 below — those check different things (plugins, vendored content, marketplaces)
and must never be skipped just because the core repo is in sync.

If BEHIND > 0: continue to Step 3.

### Step 3 — translate commits into plain English

```bash
git log HEAD..origin/main --oneline
```

For each commit line, translate the prefix into plain language:
- `feat:` or `feat(` → "New:"
- `fix:` or `fix(` → "Fixed:"
- `docs:` or `docs(` → "Docs updated:"
- `chore:` or `refactor:` → "Cleanup (no action needed):"
- `remove` or `nuke` or `delete` in message → ⚠️ "Removed:"

Show as a numbered list, newest first. No git hashes. No jargon.

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
  + /graphify skill (new)
  + /brief skill (new)
  ~ PLANNING.md updated (rules changed)

⚠️  What would be removed:
  - /debate skill (renamed to /brief — use /update restore debate to get it back)

ℹ️  You are 3 updates behind.
```

If nothing is removed: skip the ⚠️ section entirely.

### Step 4.5 — plugin status

Read installed plugins (read-only — never auto-update):

```bash
python3 - "$HOME/.claude/plugins/installed_plugins.json" <<'PYEOF'
import json, sys, os
p = sys.argv[1]
if not os.path.exists(p):
    print("No plugins installed."); raise SystemExit
try:
    plugins = json.load(open(p)).get("plugins", {})
except Exception:
    print("installed_plugins.json unreadable."); raise SystemExit
if not plugins:
    print("No plugins installed."); raise SystemExit
for name, entries in plugins.items():
    e = entries[0] if entries else {}
    print(f"{name}\t{e.get('version','?')}\t{e.get('scope','?')}")
PYEOF
```

Show as a table: **Plugin | Installed version | Scope**. Flag any row whose version is `unknown` or `?` as ⚠️ "may be stale — reinstall to pin a version".

Then output verbatim:
> To check for plugin updates, run `/plugin list` inside Claude Code, then `/plugin update <name>` for any that are outdated. Plugins can't be updated from outside the session.

### Step 4.6 — vendored third-party skill drift (read-only)

Read `docs/THIRD_PARTY_SKILLS.md`. For each row, check upstream HEAD against the pinned commit:

```bash
gh api repos/<upstream-repo>/commits/main --jq '.sha' 2>/dev/null
```

Show as a table: **Name | Pinned | Upstream HEAD | Status**. Status is `up to date` if SHAs match, else `⚠️ STALE — N commits behind` (get N via `gh api repos/<repo>/compare/<pinned>...main --jq '.ahead_by'`). If `gh` missing/unauthed or the table has no rows: skip this step silently.

Never auto-update inside this check — output:
> Vendored skill "<name>" is behind upstream. Run `/update vendor <name>` to re-vendor it.

### Step 4.7 — orphaned marketplaces (read-only)

Some marketplaces are git-cloned directly into `plugins/marketplaces/<name>/` but have **no
matching entry** in `installed_plugins.json` (no `<plugin>@<name>` key) — Step 4.5 silently
skips these, so a skill can drift with zero warning (e.g. `impeccable`, cloned straight from
`pbakaus/impeccable` with nothing installed through the normal plugin flow).

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

Show as a table: **Marketplace | Status**. `up to date` if `LOCAL = REMOTE`, else
`⚠️ STALE — behind upstream`. If none are orphaned or `git`/network fails: skip silently.

Never auto-update inside this check — output:
> "<name>" isn't tracked by the plugin system. Run `/update marketplace <name>` to pull it to latest.

### Step 5 — offer options (when run with no argument)

After showing the summary, output:

```
What do you want to do?
  /update preview            — see the full detailed changelog
  /update full               — apply everything (pulls + installs tools + offers third-party updates)
  /update rules               — apply rules only (no tool installs)
  /update rollback            — go back to what you had before
  /update vendor <name>       — re-vendor a stale third-party skill
  /update marketplace <name>  — git pull a stale orphaned marketplace
```
(The last two only appear if Steps 4.6/4.7 found something STALE.)

Then stop. Do not auto-pull.

### Step 6 — if argument is `preview`

Show the full git diff of changed markdown files in plain English. For each changed .md file:
- State what file changed and what section was affected
- Quote the before and after for changed lines (use simple "was: / now:" format)
- Highlight any lines that were deleted (user may want to keep them)

Do NOT show raw git diff output. Translate everything.

### Shared: sync-and-run

Used by Steps 7 and 8. Substitute `<SETUP_CMD>` with the caller's command.

**Dirty-check stash guard:**
```bash
cd ~/.claude && DIRTY=$(git status --porcelain)
```
If DIRTY non-empty: tell user "You have local changes I'm setting aside safely before updating." Run `git stash push -m "pre-update stash $(date +%Y-%m-%d)"`. After pull completes run `git stash pop`. If stash pop has conflicts: "Some of your local changes conflicted with the update. Your originals are in git stash — run `git stash pop` in your terminal to review."

**AHEAD/IS_FORK/SYNC_REF detection:**
```bash
cd ~/.claude
AHEAD=$(git rev-list origin/main..HEAD --count 2>/dev/null || echo 0)
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
IS_FORK=false; SYNC_REF=origin/main
if ! echo "$ORIGIN_URL" | grep -q "holland-built/no-yolo"; then
  IS_FORK=true
  EXISTING=$(git remote get-url upstream 2>/dev/null || echo "")
  [ -z "$EXISTING" ] && git remote add upstream https://github.com/holland-built/no-yolo.git \
    || git remote set-url upstream https://github.com/holland-built/no-yolo.git
  git fetch upstream main; SYNC_REF=upstream/main
fi
```

**If AHEAD = 0:** `git merge --ff-only "$SYNC_REF" && <SETUP_CMD>`

**If AHEAD > 0:** Tell user "You have [N] local commit(s). Rebasing on top of latest."
```bash
CONFLICTS=""
git rebase "$SYNC_REF"; REBASE_EXIT=$?
[ $REBASE_EXIT -ne 0 ] && CONFLICTS=$(git diff --name-only --diff-filter=U 2>/dev/null) && git rebase --abort
```
If rebase failed: tell user commits are untouched, list CONFLICTS, print `git fetch [upstream|origin] main && git rebase [SYNC_REF]` + `git rebase --continue`. STOP.
If rebase succeeded: run `<SETUP_CMD>`. If IS_FORK: tell user "force-push needed: `git push --force origin main`"

### Step 7 — if argument is `full`

Confirm: "Pulling all updates and re-running setup. This takes about 30 seconds. Continue? (y/n)"

Run the **Shared: sync-and-run** block above using `bash ~/.claude/setup.sh` as `<SETUP_CMD>`.

After success: show plain-English summary of what changed. Then run Steps 4.6 and 4.7's checks — for any row/marketplace reported STALE, ask once: "Also update third-party content — <names> — to latest? (y/n)". If yes, run Step 11 (`vendor <name>`) and/or Step 12 (`marketplace <name>`) for each. Tell user: "Reopen Claude Code to pick up the changes."

### Step 8 — if argument is `rules`

Run the **Shared: sync-and-run** block above using `bash ~/.claude/setup.sh --md-only` as `<SETUP_CMD>`.

Tell user: "Rules updated. Tool installs skipped. Reopen Claude Code to pick up changes."

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
  3. Last week — added graphify token-saving docs

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

Show the user what commits touched that skill and let them pick which version to restore.

After restoring: remind user to add the trigger back to CLAUDE.md if they want `/skill-name` to work.

### Step 11 — if argument is `vendor <name>`

Look up `<name>` in `docs/THIRD_PARTY_SKILLS.md`. If no row matches: "No vendored third-party skill named '<name>' — see `/update` to see what's tracked." Stop.

Confirm: "Re-vendoring '<name>' from <upstream-repo>. This overwrites the local copy under <vendor-path>. Continue? (y/n)"

```bash
VENDOR_PATH="<vendor-path from the row>"
REPO="<upstream-repo from the row>"
NEW_SHA=$(gh api "repos/$REPO/commits/main" --jq '.sha')
for f in "$VENDOR_PATH"/*.md; do
  base=$(basename "$f" .md)
  [ "$base" = "SOURCE" ] && continue
  curl -s "https://raw.githubusercontent.com/$REPO/main/skills/$base/SKILL.md" -o "$f"
done
cd ~/.claude && git diff --stat -- "$VENDOR_PATH"
```

(Convention: local `<vendor-path>/<x>.md` always maps to upstream `skills/<x>/SKILL.md` — this is how every vendored file here was pulled.)

Update `<vendor-path>/SOURCE.md`'s "Pinned commit" and "Vendored" date to `$NEW_SHA` / today. Update the matching row's "Pinned commit" in `docs/THIRD_PARTY_SKILLS.md` too — both must always agree.

Show the `git diff --stat` output (files changed, lines added/removed) as the change summary. Tell user: "Re-vendored '<name>' to <NEW_SHA short>. Review the diff before your next `/design` or `/impeccable` run — these files directly drive what they build/fix." Do not commit — leave it staged for the user's own review/commit.

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
