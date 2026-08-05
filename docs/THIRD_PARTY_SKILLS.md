# Third-Party Skills — where to get them, never a copy in this repo

Other people's work never gets uploaded here — no vendored file, no pinned copy committed to
git. Each row below is a **pointer**: what it is, whose repo it's from, and the command that
fetches it onto your own machine. `skills/*/vendor/` is gitignored — the files exist locally
after you (or `/update vendor <name>`) run the install command, but never on GitHub.

| Name | Upstream repo | Install command | Local path (gitignored) | Used by |
|---|---|---|---|---|
| taste-skill | `Leonxlnx/taste-skill` | `/update vendor taste-skill` (first run installs, later runs re-fetch latest) | `skills/design/vendor/taste-skill/` | `/design` Step 1 only (fresh-gen dials + routing) |
| ponytail (+5 sub-skills) | `DietrichGebert/ponytail` | `npx skills@latest add DietrichGebert/ponytail` (hashes pinned in `skills-lock.json`) | `.agents/skills/ponytail*` | `/health`, `/ponytail*` |
| improve | `shadcn/improve` | `npx skills@latest add shadcn/improve` | `skills/improve` | `/health`, `/improve` |
| emil-design-eng (+6) | `emilkowalski/skills` | `npx skills@latest add emilkowalski/skills` (hashes pinned in `skills-lock.json`) | `.agents/skills/{emil-design-eng,apple-design,animation-vocabulary,find-animation-opportunities,improve-animations,review-animations,pick-ui-library}` | `/design`, `/design-audit`, `/debate --ui` |
| archify | `tt-a1i/archify` | `npx skills@latest add tt-a1i/archify` (hash pinned in `skills-lock.json`) | `.agents/skills/archify` | diagrams — replaced the tracked draw.io skill 2026-07-17 |
| resolving-merge-conflicts | `mattpocock/skills` | `curl` the single `SKILL.md` from `skills/engineering/resolving-merge-conflicts/` (14 lines, no scripts, MIT) | `.agents/skills/resolving-merge-conflicts` | merge/rebase conflicts — the one gap with no in-house coverage |
| impeccable **(CLI, on demand)** | `pbakaus/impeccable` | `npx -y impeccable detect` — run on demand, nothing is installed | **none** (never lands on disk) | `/antislop`, `/design-audit`, `/design` validator |
| impeccable **(skill — HAND-EDITED FORK, do NOT reinstall blind)** | `bergside/awesome-design-md-skills` (`skills/impeccable/SKILL.md`) | `npx skills@latest add bergside/awesome-design-md-skills` — **⚠️ re-running this WIPES the local edits below** | `~/.agents/skills/impeccable` | design-system authoring for net-new sites |
| computer-use | Orca app (com.stablyai.orca) | managed by Orca app, not npx | `~/.agents/skills/computer-use` | Orca desktop control |
| orca-cli | Orca app (com.stablyai.orca) | managed by Orca app, not npx | `~/.agents/skills/orca-cli` | Orca CLI wiring |
| interface-design | `Dammyjay93/interface-design` | `npx skills@latest add Dammyjay93/interface-design` | `~/.agents/skills/interface-design` | product UI craft (`/interface-design:design-review`, `/interface-design:design-deslop`) — **no attribution in local files, add on next touch** |
| i-have-adhd **(ADOPTED RULES — not an installed skill)** | `ayghri/i-have-adhd` (MIT) | **nothing to install.** Four named rules only — *Say where we are*, *Real time estimates*, *One next action*, *Five items, ranked* — were adapted by hand on 2026-08-02 in commit `9727bba`. Upstream pinned at `d05af1e`. Drift check: `gh api repos/ayghri/i-have-adhd/commits/HEAD --jq .sha` — first 7 chars ≠ `d05af1e` means upstream moved; re-read those four rules there and decide by hand whether to re-adapt. | **none** (no file from that repo is on disk, now or ever) | `/eli5` — the "Every turn" table in `skills/eli5/SKILL.md`, and the same four rules in `hooks/eli5-activate.js`. The rest of that skill was deliberately NOT adopted. |

> **Two different things are called "impeccable" — they share nothing but the word.** The CLI row is
> Paul Bakaus's npm package (v3.5.0), fetched per run by `npx -y impeccable detect` (59 grep-level
> source checks, no model call, no API key, no local copy); it replaced a 376MB
> `plugins/marketplaces/` clone that was never plugin-installed and never invoked, deleted
> 2026-08-01. The skill row is **not Orca's** — this doc said so for months and it was wrong. Orca
> does not list it. `.agents/.skill-lock.json` records `/skills/impeccable` as
> `source: bergside/awesome-design-md-skills`, `sourceType: github`, installed 2026-05-07, hash
> `3f15d48`. Its `SKILL.md` carries `author: typeui.sh` and `TYPEUI_SH_MANAGED_START/END` markers —
> older bergside-repo branding, not present in the current impeccable npm package, and not evidence
> of Orca. Neither one updates or uninstalls the other.

> **The local `impeccable` skill is a fork, frozen since 2026-06-23.** It carries a custom
> `description`, an added `user-invocable: true`, and 7 added `triggers` that upstream does not have.
> `npx skills@latest add bergside/awesome-design-md-skills` overwrites all of it silently. Diff before
> you reinstall; the patches are listed in the Local patches table below.

> **Manual-only skills in this pack:** `review-animations` and `pick-ui-library` both set
> `disable-model-invocation: true`, so the Skill tool REFUSES to run them (verified by test:
> "Skill review-animations cannot be used with Skill tool due to disable-model-invocation").
> Pipelines that need their knowledge must READ their `SKILL.md` as reference instead of
> invoking them. `/design-audit` previously tried to invoke `review-animations` and that call
> silently failed until 2026-07-26.

> **Removed 2026-07-31 — `orchestration` (Orca).** Its SKILL.md documented `run --spec` and
> `run-stop`; the Orca CLI retired both, so following the skill failed at step one (verified live).
> Nothing in this repo invoked it. Only the symlink `skills/orchestration` was deleted — Orca's own
> `~/.agents/skills/orchestration` is untouched, so `ln -s ../../.agents/skills/orchestration
> skills/orchestration` restores it if Orca ever re-syncs the file to the current CLI.

> **History:** this was previously installed from `holland-built/trim`, a personal fork that renamed ponytail→trim. The fork drifted 96 commits behind upstream and was abandoned on 2026-07-26 in favour of tracking `DietrichGebert/ponytail` directly. Do not re-fork to rename — alias locally instead.

taste-skill is **vendored** (a copy fetched locally, never on GitHub).
ponytail / improve / emil-design-eng are **npx-installed** as symlinks (not vendored) — all three
have their fetched content hashes recorded in `skills-lock.json` for drift detection, including
`shadcn/improve` (this doc previously claimed it had no lockfile entry; it does).
The impeccable CLI is a third kind — **on-demand npx**: no vendored copy, no install, no lockfile
entry, nothing on disk to go stale. `/update` Step 4.6 checks it as kind (c): it may report which
version npm publishes, and may never report it "up to date" — there is no local copy to compare.

`i-have-adhd` is a **fourth kind — adopted rules (d)**, and it is the one row where the
"never a copy in this repo" rule at the top does not apply: no *file* of theirs is here, but four
of their ideas were rewritten into our own words inside `skills/eli5/SKILL.md` and
`hooks/eli5-activate.js`, and that text IS in git. MIT permits it; the attribution comment in
`eli5/SKILL.md` and this row are the licence obligation. **`/update` Step 4.6 must not route this
row to kind (c)** just because its Local path is `none` — there is no npm package, so
`npm view` returns nothing and the row would read `CANNOT CHECK` forever. Check it like this:
```bash
HEAD=$(gh api repos/ayghri/i-have-adhd/commits/HEAD --jq .sha 2>/dev/null | cut -c1-7)
if [ -z "$HEAD" ]; then echo "i-have-adhd: CANNOT CHECK — gh unavailable"
elif [ "$HEAD" = "d05af1e" ]; then echo "i-have-adhd: up to date (adopted rules, pinned d05af1e)"
else echo "i-have-adhd: ⚠️ upstream moved d05af1e → $HEAD — re-read the four rules by hand"; fi
```
The verdict is advisory: upstream moving does NOT mean our four rules are wrong, only that a human
should look. There is nothing to re-install and no `/update vendor` path — if a re-adaptation is
made, edit the two files by hand and bump the pinned sha in the row above.

If a local path doesn't exist yet (fresh clone, or never installed), the skills that use it
fall back to their built-in FALLBACKS block — nothing breaks, you get the baked-in minimum
instead of the real upstream rules until you run the install command.

## Codex-only skills — installed in `~/.agents/skills/`, invisible to Claude Code

This doc never mentioned these 14. Claude Code reads only `~/.claude/skills/`, so nothing here
routes to them, nothing here can invoke them, and no `/health` or `/skill-audit` pass has ever
looked at them. **Codex does load them.** They are third-party content on this machine and belong
in this doc for the same reason every row above does. Refresh command for all of them:
`npx skills@latest update -g`.

| Name(s) | Upstream | Status |
|---|---|---|
| dispatching-parallel-agents, executing-plans, finishing-a-development-branch, receiving-code-review, requesting-code-review, subagent-driven-development, using-git-worktrees, verification-before-completion, writing-plans, writing-skills | `obra/superpowers` | **242 commits behind** upstream `44c9b2d` — measured, not estimated. The biggest drift in this doc. |
| skill-creator | `anthropics/skills` | current |
| microsoft-foundry | `microsoft/azure-skills` | local `1.1.5`, upstream `1.2.1` — behind |
| web-design-guidelines | `vercel-labs/agent-skills` | `1.0.0`, current |
| full-output-enforcement | `Leonxlnx/taste-skill` (`skills/output-skill/`) | current — same repo the vendored taste-skill row uses, different subpath |

## Refreshing — the one command that was never written down

`npx skills@latest update` refreshes **all 109 locked skills in one command**. That is documented
nowhere else in this repo, which is exactly why the drift above went unnoticed for months: every
row here names a per-skill `add` command, so the whole library was only ever updated one skill at a
time, by hand, when someone remembered. Use `-g` for the global `~/.agents/skills/` set. Read the
Local patches table below first — `update` reverts patches the same way `add` does.

`computer-use` and `orca-cli` are the genuine exceptions: both really are Orca-app-managed
(verified — both stamped 2026-07-26 03:54 in a single sync batch, matching `stablyai/orca` HEAD).
They have **no on-demand refresh command**; they change when the Orca app syncs them and not before.

## A third skills root — `~/.codex/skills/`, 12 lazyweb skills, 11 of them broken

This doc has only ever covered `~/.claude/.agents/skills/` and `~/.agents/skills/`. There is a
**third** location: `~/.codex/skills/`. Claude Code reads only `~/.claude/skills/`, so it cannot
see any of it. Codex loads it. Nothing in `~/.claude` references it — `grep -ril -e lazyweb -e
'.codex/skills'` over `~/.claude` (excluding `projects/`) returns **zero hits**, so no skill, doc
or hook here routes to them, and no `/health`, `/update` or `/skill-audit` pass has ever seen them.

The 12: `lazyweb`, plus `lazyweb-{ab-test-research, deep-design-research, design-best-practices,
design-brainstorm, design-improve, lite-design-research, optimize-paywall, optimize-sign-up,
paywall-cta, quick-search, update}`.

**Size: effectively zero.** All 12 entries are symlinks into `~/.lazyweb/repos/lazyweb-skill/`
(a 1.4M git clone outside `~/.claude`). `du -sh ~/.codex/skills/` reports 508K, but that is
entirely `.system/` — Codex's own bundled skills (`imagegen`, `openai-docs`, `plugin-creator`,
`review-agent`, `skill-creator`, `skill-installer`), not third-party content. Following the
symlinks adds only 12K.

**Origin: determined, not guessed.** `git -C ~/.lazyweb/repos/lazyweb-skill remote -v` →
`https://github.com/aboul3ata/lazyweb-skill`. MIT ("Copyright (c) 2026 Lazyweb"), `VERSION`
`0.12.4`, HEAD `18cfc64` (2026-06-24), branch tracking `origin/main`. Installed 2026-06-25 by
`curl -fsSL https://www.lazyweb.com/install.sh | bash`. There is **no `.skill-lock.json` anywhere
under `~/.codex/`** — `npx skills` does not manage these, and `npx skills@latest update -g` will
never touch them.

> **11 of the 12 are dead symlinks — verified, not suspected.** The clone's `skills/` directory is
> empty. `git status --porcelain` there shows **16 deleted-but-uncommitted files** (` D
> skills/lazyweb-*/…`), wiped from the working tree on 2026-06-29 and never committed; `git
> ls-tree HEAD skills/` still lists all 11 directories. Only `lazyweb/SKILL.md` resolves (it points
> at the repo-root `SKILL.md`), and that file is a pure router whose every route reads a
> `skills/lazyweb-*/SKILL.md` that is no longer on disk. **Codex loads one working skill that
> routes to eleven missing ones.** Restore from the pinned commit with
> `git -C ~/.lazyweb/repos/lazyweb-skill checkout -- skills/` — or delete the whole thing.

**What it needs to run:** a hosted service, not just files. `~/.codex/config.toml` defines
`[mcp_servers.lazyweb]` = `npx -y mcp-remote https://www.lazyweb.com/mcp --header "Authorization:
Bearer $TOKEN"`, with the token read from `~/.lazyweb/lazyweb_mcp_token` (present, 37 bytes).
Upstream states the tokens are free and no-billing, so **no paid account** — but network access and
a live lazyweb.com are mandatory. Without MCP the skill's own instructions fall back to plain web
research, which it calls "degraded". Its autorouter, which writes a marked block into host agents'
global instruction files, is **not installed** here: no `~/.lazyweb/router.manifest.json`, no
`~/.lazyweb/config`, and no lazyweb marker in any `~/.claude` MD file.

**Refresh: `~/.lazyweb/bin/lazyweb-update --host all`** — verified to exist on disk (symlink to
the clone's `bin/lazyweb-update`) and documented in the upstream README. Opt-in silent updates via
`touch ~/.lazyweb/auto_update`. This is the only refresh path; the `npx skills@latest update`
command in the section above does nothing for these.

## Local patches applied on top of upstream (a reinstall silently reverts these)

| Skill | Patch | Why | Re-apply after reinstall |
|---|---|---|---|
| resolving-merge-conflicts | rewrote `description:` to carry trigger phrases, and added `user-invocable: true` | Upstream's description is one clause with no trigger words, so the router never fired it and typing the name did nothing. This repo's rule is that a skill's triggers live in its own `description` — see `docs/SKILL_TRIGGERS.md`. | Re-apply both lines after any re-fetch; the file is 14 lines, so it is a 30-second edit |
| improve | added `user-invocable: true` to its frontmatter, **and rewrote `description:`** | Upstream ships without `user-invocable`, so typing `/improve` never fired. `/health`'s H3 was unaffected: invoking a skill via the Skill tool ignores that field. The rewritten description carries the trigger phrases and the routing note to `/ponytail-audit` and `/health`, per `docs/SKILL_TRIGGERS.md`. **Corrected 2026-08-03:** this row said `/trim-audit` for months — a leftover from the abandoned `holland-built/trim` fork (History note above); no such command exists. The live description in `~/.agents/skills/improve/SKILL.md` now says `/ponytail-audit`. | `setup.sh` re-applies `user-invocable` automatically after install — **it does not re-apply the description**; re-add that by hand to `~/.agents/skills/improve/SKILL.md` |
| impeccable | custom `description`, added `user-invocable: true`, 7 added `triggers` | Upstream's frontmatter has no triggers and is not user-invocable, so the skill never routed. Fork frozen 2026-06-23. | Nothing re-applies these. `npx skills@latest add bergside/awesome-design-md-skills` wipes all three — diff the frontmatter against the pre-install copy and paste them back |

Check this table after any `npx skills@latest add ...`. The patches live outside git on
gitignored symlinks, so nothing warns you when an install wipes them.

To add a new row: pick an install command (usually `curl`/`gh` pulling specific files, wired
into `/update vendor <name>` — see `skills/update/SKILL.md` Step 11), add the gitignore line
for its local path, add a row here. Never commit the fetched content itself.
