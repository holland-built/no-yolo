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
| impeccable **(Orca skill)** | Orca app (com.stablyai.orca) | managed by Orca app, not npx | `~/.agents/skills/impeccable` | design-system authoring for net-new sites |
| computer-use | Orca app (com.stablyai.orca) | managed by Orca app, not npx | `~/.agents/skills/computer-use` | Orca desktop control |
| orca-cli | Orca app (com.stablyai.orca) | managed by Orca app, not npx | `~/.agents/skills/orca-cli` | Orca CLI wiring |
| interface-design | `Dammyjay93/interface-design` | `npx skills@latest add Dammyjay93/interface-design` | `~/.agents/skills/interface-design` | product UI craft (`/interface-design:design-review`, `/interface-design:design-deslop`) — **no attribution in local files, add on next touch** |
| i-have-adhd **(ADOPTED RULES — not an installed skill)** | `ayghri/i-have-adhd` (MIT) | **nothing to install.** Four named rules only — *Say where we are*, *Real time estimates*, *One next action*, *Five items, ranked* — were adapted by hand on 2026-08-02 in commit `9727bba`. Upstream pinned at `d05af1e`. Drift check: `gh api repos/ayghri/i-have-adhd/commits/HEAD --jq .sha` — first 7 chars ≠ `d05af1e` means upstream moved; re-read those four rules there and decide by hand whether to re-adapt. | **none** (no file from that repo is on disk, now or ever) | `/eli5` — the "Every turn" table in `skills/eli5/SKILL.md`, and the same four rules in `hooks/eli5-activate.js`. The rest of that skill was deliberately NOT adopted. |

> **Two different things are called "impeccable" — they share nothing but the word.** The CLI row is
> Paul Bakaus's npm package, fetched per run by `npx -y impeccable detect` (59 grep-level source
> checks, no model call, no API key, no local copy); it replaced a 376MB `plugins/marketplaces/`
> clone that was never plugin-installed and never invoked, deleted 2026-08-01. The Orca row is an
> 8KB SKILL.md the Orca app syncs to `~/.agents/skills/impeccable`; it is still installed, still
> used, and is NOT going anywhere. Neither one updates or uninstalls the other.

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
ponytail / improve / emil-design-eng are **npx-installed** as symlinks (not vendored) — two of the
three have their fetched content hashes recorded in `skills-lock.json` for drift detection;
`shadcn/improve` has no lockfile entry (see Maintenance notes in the plan for why).
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

## Local patches applied on top of upstream (a reinstall silently reverts these)

| Skill | Patch | Why | Re-apply after reinstall |
|---|---|---|---|
| resolving-merge-conflicts | rewrote `description:` to carry trigger phrases, and added `user-invocable: true` | Upstream's description is one clause with no trigger words, so the router never fired it and typing the name did nothing. This repo's rule is that a skill's triggers live in its own `description` — see `docs/SKILL_TRIGGERS.md`. | Re-apply both lines after any re-fetch; the file is 14 lines, so it is a 30-second edit |
| improve | added `user-invocable: true` to its frontmatter | Upstream ships without it, so typing `/improve` never fired. `/health`'s H3 was unaffected: invoking a skill via the Skill tool ignores that field. | `setup.sh` now re-applies it automatically after install; manual fallback: re-add the line to `~/.agents/skills/improve/SKILL.md` |

Check this table after any `npx skills@latest add ...`. The patches live outside git on
gitignored symlinks, so nothing warns you when an install wipes them.

To add a new row: pick an install command (usually `curl`/`gh` pulling specific files, wired
into `/update vendor <name>` — see `skills/update/SKILL.md` Step 11), add the gitignore line
for its local path, add a row here. Never commit the fetched content itself.
