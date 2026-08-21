# SHIP.md: release playbook for ~/.claude (no-yolo skill library)

Repo: `github.com/holland-built/no-yolo`. Run `/release` from anywhere under `~/.claude`.

Rewritten 2026-08-05, and again on 2026-08-21. The 2026-08-05 version was written against the
catalogue system that the fresh-start rebuild deleted: eight of its ten steps called
`/md-check`, `/update`, `skills/my-skills/`, `skills/my-md/` or `docs/HOOKS.md`, none of which <!-- gone-on-purpose -->
exist. Two of those were hard blocks, so every release would have stopped forever.

It happened a second time. The 2026-08-21 rebuild cut 26 skills to 6 and replaced the rule
files, and this playbook was left naming `docs/ANTISLOP.md` and `docs/README_FORMAT.md`, <!-- gone-on-purpose -->
along with a mockup-pruning script that went with `/design`. All deleted. Three of nine steps,
two of them hard blocks. Step 4 below is the sweep that should have caught it and did not run,
because nobody released in between.

**A step belongs here only if the thing it runs is on disk right now.** Check before adding
one, and check again after any rebuild.

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

1. **Writing check (warn only):** print `| File | Tell | Excerpt |`; never block.

   The hook takes a tool-call payload on standard input, not a filename, because that is how
   Claude Code invokes it. Wrap each path the same way to run it by hand:

   ```bash
   git diff --name-only --cached -- '*.md' | while read -r f; do
     printf '{"tool_input":{"file_path":"%s/%s"}}' "$PWD" "$f" | bash hooks/slop-block.sh
   done
   ```

   The hook decides only what a program can decide, so read the judgement rules in
   `docs/PROSE.md` against the same files yourself. It already fires on every Write and Edit,
   so a clean result here is the expected one, and a finding means a file reached git without
   passing through a hook.

2. **Size check (warn only):** `wc -l ~/.claude/*.md ~/.claude/docs/*.md ~/.claude/rules/*.md
   ~/.claude/skills/*/SKILL.md`; table any file >200 lines.

3. **Stale-external sweep (repo mirrors the machine: HARD BLOCK):** every external tool
   referenced in tracked files (a row in `INSTALL.md`, a `skills/<name>` .gitignore entry, a
   README prerequisite) must exist on THIS machine right now. Check with
   `ls ~/.agents/skills/<name>`, `ls ~/.claude/.agents/skills/<name>` (newer npx installs land
   here), `ls skills/<name>`, or `command -v <tool>` for anything installed globally. A
   reference to something not installed is old shit. Delete the reference, don't ship it.
   Standing rule from a past incident: a tool was uninstalled locally but its 16 references
   shipped for weeks.

   `INSTALL.md` is the one file that may name a tool this machine does not have, because its
   whole subject is what to install. What it must not do is claim one is present.

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
       | grep -oE '`(docs|rules|skills|hooks|agents)/[A-Za-z0-9._/-]+\.(md|sh|js|py|mjs|json)`' \
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

   Gitignored-by-design paths are the one real gap here, because they exist locally and are
   absent on a fresh clone, so the check passes for you and fails for a stranger. Two live
   cases: `memory/MEMORY.md` and `memory/facts/`. Neither is matched by the pattern above, and
   that is deliberate rather than lucky, so anything that starts citing them has to name the
   tracked template beside them, the way `settings.example.json` sits beside `settings.json`.

5. **Outside-tool freshness (warn only: never auto-pull):** run `/checkup` and print its drift
   rows. It reports how far behind this clone is against GitHub, and which of the five optional
   tools in `INSTALL.md` are absent. Warn only, and never install anything mid-release: an
   outside tool that arrives in the middle of a publish has not been watched working.

   Whether those five tools are the tools they claim to be is not a judgement call and is not
   here: `hooks/external-check.sh` resolves every one against the registry on every run of
   `verify.sh`, and a name that does not resolve to the project `hooks/externals.txt` pins is a
   hard failure, not a drift row.

6. **README count patch:** update the skill count in `README.md` from the live directory.
   Every skill is now a real directory of this repo's own; the borrowed/symlinked split the
   old version of this step counted no longer exists.
   ```bash
   ls -d skills/*/ | wc -l
   ```

7. **README prose sweep (warn only):** step 6 keeps one number honest and nothing reads the
   other 270 lines. Step 4 catches a path that stopped resolving. It cannot catch a sentence
   whose every path resolves and whose description is wrong, which is the whole class that
   reached publication on 2026-08-21: seven install references whose every surrounding path
   was valid and six of whose package names were not.

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

   Four details, each because the obvious version fails:

   - **The change set is `origin/HEAD`, not `--cached`.** Staging happens in the Stage scope
     section below, which runs after this step, so a `--cached` diff here reads empty and a
     step that examined nothing looks exactly like a step that found nothing. Comparing against
     the remote covers staged, unstaged and already-committed-but-unpushed alike, which is what
     this release will actually publish.
   - **The names come off a pipe, not out of a variable.** The obvious version collects them
     into `changed` and runs `for n in $changed`, which works in bash and silently does not in
     zsh: zsh performs no word splitting on an unquoted expansion, so the loop runs once with
     every name glued into one string and greps for something that cannot match. Reproduced on
     2026-08-21: the same loop over "a b c" runs once under zsh and three times under bash.
   - **`grep -nF`, with `|| true`.** Fixed-string, and a no-match exit status is swallowed. A
     warn-only step whose last name happens to miss must not report failure.
   - **A removed skill is not a finding.** `[ -e "$p" ]` separates a skill the page never
     introduced, which is a gap, from one deleted on purpose, which is expected.

   Some names are ordinary English words, so `design` and `release` match prose that is not
   about them. Read the line, never the count. That noise is the price of a substring match,
   and a stricter pattern would miss the sentence naming a skill without backticks, which is
   the sentence this step exists to catch.

   Warn only, on purpose. Whether a sentence still reads true is a judgement, and a block on a
   judgement gets satisfied by editing the sentence until the gate stops complaining.

8. **Config template check (HARD BLOCK):** `settings.example.json` must parse
   (`python3 -c "import json;json.load(open('settings.example.json'))"`); its hook command
   strings must use `$HOME/` not a quoted `~/` (a quoted `~` never expands, hard-fail on any
   match of `grep -c '"~/.claude/hooks' settings.example.json`, want `0`); and every hook path
   referenced must exist on disk. Run `bash verify.sh`; the `settings.example.json parses` and
   `hook paths exist` rows must read PASS. A missing hook script or a quoted-`~` path means
   fresh installs get a failing hook every turn. Both shipped once
   (`log-learnings-stop.sh`, quoted-`~` paths); never again.

## Stage scope

```
git add skills/ docs/ rules/ hooks/ .github/ agents/ README.md INSTALL.md LICENSE \
  .gitignore .no-yolo-deny.example.txt setup.sh settings.example.json SHIP.md CLAUDE.md \
  memory/MEMORY.example.md verify.sh verify-selftest.sh
```

Explicit paths: do NOT rely on a `*.md` shell glob, which expands in the CWD rather than the
repo root. Each of these was omitted once and something silently never shipped:

- `.github/` holds `workflows/ci.yml`, the workflow that runs verify.sh: omitted once, so a
  CI-config fix could never ship.
- `verify.sh` and `verify-selftest.sh` are tracked and CI runs them: omitted once, so a fix to
  the verifier itself silently never shipped.
- Under `memory/`, exactly one tracked thing ships: `MEMORY.example.md`. Both the real index
  `memory/MEMORY.md` and the `memory/facts/` it lists are gitignored, because both name things
  about the owner. Until 2026-08-21 a compiled view shipped instead; the compiler is gone and
  the index that replaced it is written by hand (`docs/MEMORY.md`).
- `rules/` holds the files two or more skills share (`codex.md`, `mockups.md`). A rule that
  lives in one skill stays in that skill; a rule two files need lives here, and both point at
  it, so the number in one cannot drift from the number in the other.
- `LICENSE` is the MIT terms the README's licence badge reads: omit it and the badge renders
  "unknown" against a file git never received.
- `.no-yolo-deny.example.txt` is the tracked template for the gitignored `.no-yolo-deny.txt`.
- `agents/` (subagent roster) is tracked and must ship. This bullet also named `commands/`
  until 2026-08-21, when no such directory existed and nothing was tracked under one: the
  rebuild deleted it and the line outlived it. It was never in the `git add` list above, so
  nothing ever failed to ship, which is exactly why nobody noticed.

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
- If `gh` is missing or unauthed: print `⚠️ release skipped: run gh auth login` and continue.
