---
name: update
description: Use this skill when the user types /update, says 'check for updates', 'am I out of date', 'what's new in my setup', 'update my setup', or 'rollback'. Two-way reconciliation between your local ~/.claude and its published copy on GitHub — checks not just what GitHub has that you don't (behind), but what you have that GitHub doesn't yet (ahead, or plain uncommitted work — points to /release to publish). Also covers plugin version status and vendored third-party skill drift (docs/THIRD_PARTY_SKILLS.md). `/update vendor <name>` and `/update marketplace <name>` actually apply third-party updates (re-vendor / git pull) — the only steps that touch third-party content, always behind a confirm.
user-invocable: true
model: sonnet
effort: low
argument-hint: "[preview|full|rules|rollback|restore <name>|vendor <name>|marketplace <name>]"
---

# update

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
| `/update marketplace <name>` | `git pull` a stale orphaned marketplace (cloned under `plugins/marketplaces/`, but not plugin-installed) to latest |

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

If BEHIND = 0 AND AHEAD = 0 AND DIRTY empty: output "Your machine and GitHub are identical — everything reconciled." Skip Steps 3-4 but still run Steps 4.5-4.7 — they check different things (plugins, vendored content, marketplaces).

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

**Listing the installed version is not a check.** This step printed versions for months and compared them to nothing, so a plugin could fall arbitrarily far behind and still read as a clean row. The published version is already on disk — each marketplace clone carries a `.claude-plugin/marketplace.json` — so compare them:
```bash
python3 - "$HOME/.claude/plugins/installed_plugins.json" "$HOME/.claude/plugins/known_marketplaces.json" <<'PYEOF'
import json, sys, os
inst = json.load(open(sys.argv[1])).get("plugins", {})
mkts = json.load(open(sys.argv[2])) if os.path.exists(sys.argv[2]) else {}
for key, entries in inst.items():
    if "@" not in key:
        continue
    plugin, mkt = key.split("@", 1)
    for e in entries:                                   # value is a LIST of install records
        local = e.get("version") or "unknown"
        loc = (mkts.get(mkt) or {}).get("installLocation") or os.path.join(
            os.path.expanduser("~/.claude/plugins/marketplaces"), mkt)
        man = os.path.join(loc, ".claude-plugin", "marketplace.json")
        pub = None
        if os.path.exists(man):
            for p in json.load(open(man)).get("plugins", []):   # top-level "plugins" array
                if p.get("name") == plugin:
                    pub = p.get("version")                       # per-plugin, NOT metadata.version
        print("\t".join([plugin, mkt, local, pub or "?", e.get("scope", "?")]))
PYEOF
```
Field shapes are verified, not guessed: `installed_plugins.json` maps `<plugin>@<marketplace>` to a **list** of records each carrying `version` and `scope`; `marketplace.json` carries a top-level `plugins` array whose entries have `name` and `version`. A marketplace-level `metadata.version` also exists on some manifests (`openai-codex` has one, `design-plugins` does not) — **never read that as the plugin's version**; it tracks the marketplace, and on a multi-plugin marketplace it is a different number entirely.

Table: **Plugin | Installed version | Published version | Status | Scope** (this block's output supersedes the lister's three columns — run the lister first only to catch "No plugins installed."). An installed version of `unknown` or `?` still gets the old flag, ⚠️ "may be stale — reinstall to pin a version", *and* forces the Status column to `⚠️ CANNOT TELL`. Status is `current` when the two versions are equal, `⚠️ BEHIND — marketplace publishes <pub>` when they differ, and `⚠️ CANNOT TELL` when either side is `?`/`unknown` (no manifest, no matching plugin name, or an unpinned install). **Never report `current` for a row you could not compare** — an uncomparable row reads as clean only because nothing was checked, which is the exact failure this block was added to end. A local version *ahead* of the marketplace is also `⚠️ CANNOT TELL`, not `current`: it usually means the marketplace clone itself is stale, so run Step 4.7's pull first and re-check.

This is read-only. Never run `/plugin update` and never edit either JSON file. Then output verbatim:
> To check for plugin updates, run `/plugin list` inside Claude Code, then `/plugin update <name>` for any that are outdated. Plugins can't be updated from outside the session.

(Baseline, measured 2026-08-03: `codex@openai-codex` 1.0.6 and `design-and-refine@design-plugins` 1.1.0 were both current against their marketplaces. A row that goes `⚠️ BEHIND` is therefore real drift, not a first-run artefact.)

### Step 4.6 — third-party skill drift (read-only)
Read `docs/THIRD_PARTY_SKILLS.md` for names, install commands, and local paths (none of this content is in git — see that file). **Read two sections of it, not one:** the main pointer table at the top drives kinds (a)–(d), and the "Codex-only skills — installed in `~/.agents/skills/`, invisible to Claude Code" section drives kind (e). Reading only the top table is how 14 skills stayed unchecked for months.

**There are FIVE install kinds and they need different checks.** Getting this wrong is not theoretical: this step used to test `SOURCE.md` for every row, so the four npx-installed skills — which never have one — reported `NOT INSTALLED` forever and their real drift was invisible. `archify` sat two weeks and 13 files behind while this check stayed quiet.

**Routing rule — read the section FIRST, then the Name cell, then the Install command, then Local path.** Every row in the "Codex-only skills" section is kind (e) and nothing else; the four kinds below apply only to rows in the main pointer table. Within that table, a Name cell marked **ADOPTED RULES** is kind (d) and nothing else, no matter what the other columns say. Only if the Name cell carries no such marker do the other columns decide: `SOURCE.md`-bearing vendored rows are (a), `npx skills@latest add` rows are (b), and a Local path of `none` **plus a real npm package in a bare `npx -y <pkg> <cmd>` install command** is (c). Local path `none` on its own never means (c) — kind (d) is also `none` and has no package, so `npm view` returns nothing and the row would read `CANNOT CHECK` forever. `docs/THIRD_PARTY_SKILLS.md` warns about exactly that mis-route; obey the marker.

**(a) Vendored** (install command is `/update vendor <name>`) — has a `SOURCE.md`:
```bash
if [ ! -f "<local-path>/SOURCE.md" ]; then
  echo "<name>: NOT INSTALLED"
else
  PINNED=$(grep "Pinned commit" "<local-path>/SOURCE.md" | grep -oE '[0-9a-f]{40}')
  HEAD=$(gh api repos/<upstream-repo>/commits/main --jq '.sha' 2>/dev/null)
fi
```
Status: `not installed — run /update vendor <name> to install` if `SOURCE.md` is missing, `up to date` if `PINNED = HEAD`, else `⚠️ STALE — N commits behind` (N via `gh api repos/<repo>/compare/<pinned>...main --jq '.ahead_by'`).

**(b) npx-installed** (install command is `npx skills@latest add <repo>`) — no `SOURCE.md` ever, so never test for one. Compare the installed `SKILL.md` against upstream's:
```bash
LOCAL="<local-path>/SKILL.md"                       # e.g. .agents/skills/archify/SKILL.md
TMP=$(mktemp)
# Repo layouts differ three ways: ponytail/emilkowalski nest under skills/, archify does not,
# and interface-design hides under .claude/skills/. Try all three, in this order.
curl -fsS "https://raw.githubusercontent.com/<repo>/main/skills/<name>/SKILL.md" -o "$TMP" 2>/dev/null \
  || curl -fsS "https://raw.githubusercontent.com/<repo>/main/<name>/SKILL.md" -o "$TMP" 2>/dev/null \
  || curl -fsS "https://raw.githubusercontent.com/<repo>/main/.claude/skills/<name>/SKILL.md" -o "$TMP" 2>/dev/null
if [ ! -f "$LOCAL" ]; then echo "<name>: NOT INSTALLED"
elif [ ! -s "$TMP" ]; then echo "<name>: CANNOT CHECK — no upstream SKILL.md at any of the three paths"
elif diff -q "$TMP" "$LOCAL" >/dev/null 2>&1; then echo "<name>: up to date"
else echo "<name>: STALE"; fi
rm -f "$TMP"
```
**Compare files, never shell variables.** `UP=$(curl …)` then piping it to `diff` strips the trailing newline and makes *every* skill report STALE — a freshly installed one included. That false positive was hit while writing this step; curl straight to a temp file instead.

**Two paths were not enough.** `interface-design` lives at `.claude/skills/interface-design/SKILL.md` in `Dammyjay93/interface-design` — measured: the `skills/` and bare paths both return 404, the `.claude/skills/` one returns 200. With only two fallbacks that row printed `CANNOT CHECK` on every run since it was installed, which is the kind (b) version of the failure kind (c) already records. If a fourth layout ever appears, the row's own `skillPath` in `~/.agents/.skill-lock.json` is the authoritative answer — read it rather than guessing a fourth curl.

**Locally patched skills need the body compared, not the whole file.** Any row in `docs/THIRD_PARTY_SKILLS.md`'s "Local patches applied on top of upstream" table is *supposed* to differ from upstream, so a whole-file diff reports it STALE forever and a real upstream change hides in the noise. Every patch recorded there so far is frontmatter-only, so for those rows diff the body — everything after the closing `---` — and report `patched (frontmatter)` when only the frontmatter differs:
```bash
body() { awk 'BEGIN{n=0} /^---$/{n++; if(n<=2) next} n>=2' "$1"; }
if diff -q <(body "$TMP") <(body "$LOCAL") >/dev/null 2>&1; then echo "<name>: up to date (patched frontmatter)"
else echo "<name>: STALE — body differs from upstream"; fi
```
If a future patch touches the body, this rule stops holding — say so in the report rather than quietly widening it.
Status: `up to date`, `⚠️ STALE — reinstall to pick up upstream changes`, `NOT INSTALLED`, or `⚠️ CANNOT CHECK`. **A row that cannot be checked is never reported as up to date** — that is how the last one hid.

**(c) On-demand npx** (Local path column is `none`, install command is a bare `npx -y <pkg> <cmd>` — e.g. `impeccable`) — the package is fetched and run at call time and **leaves nothing on disk**. There is no `SOURCE.md` and no local file, so *both* checks above are inapplicable: do not test for `SOURCE.md`, do not diff, do not `ls` the path. The only fact obtainable is what the registry currently publishes, and that is information, not a verdict:
```bash
if ! command -v npx >/dev/null 2>&1; then echo "<name>: CANNOT CHECK — npx not on PATH"
else
  PUB=$(npm view <pkg> version 2>/dev/null)
  if [ -n "$PUB" ]; then echo "<name>: on-demand — npm publishes $PUB (nothing local to compare)"
  else echo "<name>: CANNOT CHECK — registry unreachable (offline?)"; fi
fi
```
This kind has exactly two allowed statuses: `on-demand — npm publishes vX.Y.Z (nothing local to compare)` and `⚠️ CANNOT CHECK`. **Never print `up to date`** — there is no local copy for that to be true *of*; every `npx` run already takes latest. Never print `STALE` (nothing can be stale) and never `NOT INSTALLED` (not-installed is the correct, permanent state for this kind — reporting it as a fault is precisely the failure recorded above, where four rows sat red for months and a real two-week drift hid inside the noise). Offline, or `npx` missing → `CANNOT CHECK`, never a clean result.

**(d) Adopted rules** (Name cell marked **ADOPTED RULES**, Local path `none`, install command says nothing to install and carries a pinned upstream sha — e.g. `i-have-adhd`) — no file of theirs is on disk, now or ever; some of their *ideas* were rewritten by hand into our own files. There is nothing to install, no package, and no `SOURCE.md`, so (a)/(b)/(c) are all inapplicable: do not `ls` the path, do not diff, do not `npm view`. The only obtainable fact is whether upstream has moved past the pinned sha recorded in the row:
```bash
PINNED="<pinned sha from the row, e.g. d05af1e>"
REPO="<upstream repo from the row, e.g. ayghri/i-have-adhd>"
UP=$(gh api "repos/$REPO/commits/HEAD" --jq .sha 2>/dev/null | cut -c1-7)
if [ -z "$UP" ]; then echo "<name>: ⚠️ CANNOT CHECK — gh unavailable / unauthenticated / rate-limited / offline"
elif [ "$UP" = "$PINNED" ]; then echo "<name>: pinned at $PINNED — upstream unchanged"
else echo "<name>: ⚠️ UPSTREAM MOVED — pinned $PINNED, upstream now $UP; re-read the adopted rules and decide by hand whether to re-adapt"; fi
```
This kind has exactly three allowed statuses: `pinned at <sha> — upstream unchanged`, `⚠️ UPSTREAM MOVED — pinned <old>, upstream now <new>; re-read the adopted rules and decide by hand whether to re-adapt`, and `⚠️ CANNOT CHECK — gh unavailable / unauthenticated / rate-limited / offline`. **Never print `up to date`** — nothing local exists for that to be true *of*. Never `STALE` — nothing is on disk to go stale. Never `NOT INSTALLED` — not-installed is the correct, permanent state for this kind, and reporting it as a fault is the same failure recorded above for kind (c), where rows sat red for months and a real two-week drift hid in the noise.

**(e) Codex-only skills** (every row in `docs/THIRD_PARTY_SKILLS.md`'s "Codex-only skills" section — 14 of them, under `~/.agents/skills/`) — installed by `npx skills@latest add … -g`, symlinked into every agent *except* Claude Code, so **Claude Code never loads them and no `/health`, `/skill-audit` or router pass has ever seen them.** Codex does load them, and they are third-party content on this machine, so they drift like anything else: measured 2026-08-03, the ten `obra/superpowers` skills were **242 commits behind** upstream `44c9b2d` and `microsoft-foundry` was local `1.1.5` against upstream `1.2.1` — both silent for months. **Severity is lower than kinds (a)–(d), not zero:** a stale row here degrades Codex sessions only, so rank these below every other kind in the report and never let one block an otherwise-clean pass. Membership test, if a row's kind is ever in doubt: `npx skills@latest list -g --json` prints an `agents` array per skill, and kind (e) is exactly the skills whose array omits `Claude Code`.

**The `skills` CLI has no read-only check.** Verified against `npx skills@latest --help`: the subcommands are `add`, `use`, `remove`, `list`/`ls`, `find`, `update`, `experimental_install`, `init`, `experimental_sync` — `update` writes, and nothing reports drift without writing. `list -g --json` enumerates what is installed but never contacts upstream. **Do not invent a `check` flag.** The only read-only check available is comparing each locked entry in `~/.agents/.skill-lock.json` against upstream yourself, which is what the block below does — the lock file records each skill's `source` repo *and* its exact `skillPath`, so no path guessing is needed:
**Feed it the names from the doc, never the whole lock file.** `.skill-lock.json` holds ~109 entries, most of them project-scoped installs long gone from `~/.agents/skills/`; looping the file wholesale prints ~85 rows of `NOT INSTALLED` (verified by running it) and buries the eight real STALE rows in exactly the noise kinds (c) and (d) were rewritten to stop. It also re-reports kind (b) rows — `impeccable`, `interface-design`, `archify` and the ponytail/emil packs all live under `~/.agents/skills/` too, and `impeccable` is a deliberate hand-edited fork that must stay in kind (b) where the patch rules apply. So set `NAMES` from the "Codex-only skills" section's Name(s) column and nothing else; the lock file only supplies `source` and `skillPath` for those names.
Keep the name list **inside the Python heredoc**, not in a shell variable: an unquoted `$NAMES` does not word-split under zsh (the default shell here), so the whole list arrives as one argument and every row reports `NOT INSTALLED` — hit while writing this step.
```bash
ROWS=$(mktemp)
python3 - "$HOME/.agents/.skill-lock.json" <<'PYEOF' > "$ROWS"
import json, sys
# Names come from the doc section, never from a disk listing. Keep this comment OUTSIDE the
# string — anything inside it becomes a bogus skill name via .split().
NAMES = """
dispatching-parallel-agents executing-plans finishing-a-development-branch receiving-code-review
requesting-code-review subagent-driven-development using-git-worktrees verification-before-completion
writing-plans writing-skills skill-creator microsoft-foundry web-design-guidelines
full-output-enforcement
""".split()
locked = json.load(open(sys.argv[1])).get("skills", {})
for name in NAMES:
    e = locked.get(name)
    if not e:
        print("\t".join([name, "", ""])); continue      # in the doc, absent from the lock
    print("\t".join([name, e.get("source", ""), e.get("skillPath", "")]))
PYEOF
while IFS=$'\t' read -r NAME REPO PATHY; do
  LOCAL="$HOME/.agents/skills/$NAME/SKILL.md"
  [ -f "$LOCAL" ] || { echo "$NAME: NOT INSTALLED (in the doc, missing on disk)"; continue; }
  [ -n "$REPO" ] && [ -n "$PATHY" ] || { echo "$NAME: ⚠️ CANNOT CHECK — no lock entry to resolve upstream from"; continue; }
  TMP=$(mktemp)
  curl -fsS "https://raw.githubusercontent.com/$REPO/HEAD/$PATHY" -o "$TMP" 2>/dev/null
  if [ ! -s "$TMP" ]; then echo "$NAME: ⚠️ CANNOT CHECK — upstream unreachable or path moved"
  elif diff -q "$TMP" "$LOCAL" >/dev/null 2>&1; then echo "$NAME: up to date"
  else echo "$NAME: ⚠️ STALE — differs from upstream $REPO"; fi
  rm -f "$TMP"
done < "$ROWS"
rm -f "$ROWS"
```
**Compare files, never shell variables** — same trailing-newline trap as kind (b), same fix. `skillFolderHash` in the lock file is *not* usable for this: it is a hash of the folder as installed, and there is no published upstream hash to compare it to, so diffing the fetched `SKILL.md` is the check. Only `SKILL.md` is compared, so a change confined to a sibling reference file inside the skill folder will not be caught — say that in the report rather than implying a full-folder verdict.

This kind has exactly four allowed statuses: `up to date`, `⚠️ STALE — differs from upstream <repo>`, `NOT INSTALLED (in the doc, missing on disk)`, and `⚠️ CANNOT CHECK` (upstream unreachable, path moved, or no lock entry). **A row that cannot be checked is never reported as up to date.** Never print a commit count unless you actually fetched one (`gh api repos/<repo>/compare/<sha>...HEAD --jq .ahead_by`) — the 242 figure above is a recorded measurement, not a number to reprint as if freshly computed. `computer-use` and `orca-cli` also sit under `~/.agents/skills/` but are **not** kind (e) — they are Orca-app-managed rows in the main pointer table with no refresh command at all, so `npx skills@latest update -g` will never move them. Keep them out of `NAMES`; if they surface anywhere, report `managed by Orca — no refresh command`, never `STALE`.

Codex-only rows share ONE fix line for the whole group — never one per row, or a STALE superpowers batch prints ten identical commands:
> N Codex-only skill(s) are behind upstream — <names>. They affect Codex sessions only; Claude Code does not load them. Run `npx skills@latest update -g` to refresh the whole global set. Check `docs/THIRD_PARTY_SKILLS.md`'s "Local patches" table first — `update` reverts patches exactly the way `add` does.

Table: **Name | Kind | Status**. If `gh`/`curl` are unavailable or the table has no rows, say the check was skipped — do not print an all-clear you did not earn.

Never auto-update inside this check — output the fix that matches the kind:
> Vendored skill "<name>" is behind upstream. Run `/update vendor <name>` to re-vendor it.
> npx-installed skill "<name>" is behind upstream. Run its own install command from `docs/THIRD_PARTY_SKILLS.md` (`npx skills@latest add <repo>`) — the `skills` CLI re-pins `skills-lock.json` itself. Then check `docs/THIRD_PARTY_SKILLS.md`'s "Local patches" table: a reinstall silently reverts every patch listed there.

On-demand rows get **no fix line at all** — there is nothing to update. If a published version needs holding still, pin it in the calling skill's command (`npx -y <pkg>@<version>`), not here.

Adopted-rules rows get **no command either — the fix is a person, not a script.** An upstream move is never auto-appliable: these are hand-adapted prose rules that now live in two of our own files, so the only correct response is a human re-reading the upstream rules and deciding whether ours still hold. For `i-have-adhd` those rules live in `skills/eli5/SKILL.md` (the "Every turn" table) and `hooks/eli5-activate.js`. Output:
> Upstream of adopted-rules row "<name>" moved past the pinned sha. Nothing to install. Re-read the upstream rules yourself, decide by hand whether to re-adapt `skills/eli5/SKILL.md` and `hooks/eli5-activate.js`, and if you do, bump the pinned sha in that row of `docs/THIRD_PARTY_SKILLS.md`.

### Step 4.7 — orphaned marketplaces (read-only)
Marketplaces git-cloned into `plugins/marketplaces/<name>/` with **no** `<plugin>@<name>` key in `installed_plugins.json` are invisible to Step 4.5, so a skill can drift with zero warning. (History: `pbakaus/impeccable` sat here as a 376MB clone that was never plugin-installed and never invoked. It was deleted 2026-08-01 and replaced by on-demand `npx -y impeccable detect` — kind (c) in Step 4.6. Do not re-clone it.)
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
  npx skills@latest update -g — refresh the Codex-only skills (not a /update mode; run it yourself)
```
(The last three only appear if Steps 4.6/4.7 found something STALE — the `npx` line only when kind (e) rows are STALE. It is deliberately not a `/update` subcommand: the `skills` CLI re-pins its own lockfile, and wrapping it would hide that `update -g` reverts every local patch.)

Then stop. Do not auto-pull.

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

After success: plain-English summary of what changed. Then re-run Steps 4.6 and 4.7's checks — for any row/marketplace STALE, ask once: "Also update third-party content — <names> — to latest? (y/n)". If yes, run Step 11 (`vendor <name>`) and/or Step 12 (`marketplace <name>`) for each. **Kinds (d) and (e) are excluded from this offer** even when they report `⚠️ UPSTREAM MOVED` / `⚠️ STALE` — for (d) there is no command that could update them, re-adapting is a human edit to our own files; for (e) the fix is `npx skills@latest update -g`, which Step 11 correctly refuses and which reverts local patches, so print its fix line and let the user run it. Tell user: "Reopen Claude Code to pick up the changes."

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

**REFUSE unless the row's Install command is `/update vendor <name>`** — that is the only vendored kind. Everything else (npx-installed, on-demand npx, adopted rules, `curl`-a-single-file, Orca-managed) must be turned away here. The recipe below fetches `skills/<x>/SKILL.md` into `<vendor-path>/<x>.md` — for an npx skill, whose local path is a whole package directory of code, schemas and examples, that writes a stray markdown file and leaves the real install untouched while reporting success. Say instead: "'<name>' isn't vendored — run `<its own install command>` from `docs/THIRD_PARTY_SKILLS.md`." For an npx-installed row add "the `skills` CLI re-pins `skills-lock.json` itself"; for an on-demand row add "there is nothing to install — it is fetched per run"; for an adopted-rules row add "there is nothing to install — the rules were re-written by hand into our own files." Stop.

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
