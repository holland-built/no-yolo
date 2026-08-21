# Third-party skills, and the lines we add to them

Borrowed skills are installed by `npx skills` and symlinked into `skills/`. Both the targets
and the symlinks are gitignored: the code belongs to whoever wrote it, and this repo publishes
the pointer, never the copy. `docs/BORROWED.md` is the tracked record of what was borrowed.

**There are two installer roots, not one.** Nothing here chooses between them. The
installer does. So **never hardcode a root**: address a borrowed skill as
`skills/<name>/SKILL.md` and let the symlink resolve it. Both `setup.sh` and `verify.sh` got
this wrong first and would have skipped `interface-design` without saying anything.

Measured 2026-08-18 by resolving all 19 symlinks with `os.path.realpath`, 0 broken:

| Root | Holds |
|---|---|
| `~/.agents/skills/` | `improve`, `interface-design`, `orca-cli`, plus `impeccable`, which nothing symlinks to |
| `~/.claude/.agents/skills/` | the rest, including `resolving-merge-conflicts` |

`computer-use` was in the first root until 2026-08-20, when it was removed.

This paragraph previously placed `resolving-merge-conflicts` in `~/.agents/skills/`. It is in
`~/.claude/.agents/skills/`. A doc that names a hardcoded root, and names it wrongly, is the
exact trap the paragraph above warns about, hence the measured table rather than a list.

**There is only one lock file**, always `~/.agents/.skill-lock.json` (or under
`$XDG_STATE_HOME`), never one per root, read from the installer's own `getSkillLockPath()`
in `skills@1.5.22`. Which root a skill lives in says nothing about whether it is locked.

This file covers the exception: the handful of lines this setup adds to files it does not own.

## The rule, stated exactly

> **Third-party bodies are never edited. Frontmatter that controls routing may be overlaid,
> re-applied by `setup.sh`, and watched by `verify.sh`.**

The distinction is the whole policy. A skill's *content* is the author's work and stays
verbatim. That is why `skills/design/vendor/taste-skill/` is vendored untouched and read as
reference. A skill's *frontmatter* decides whether it appears in this machine's skill list,
which is a decision about this setup, not about the skill. Changing it is configuration.

"Never edited" as an absolute was already untrue before it was written down here: `setup.sh`
has patched `improve` since the day it was installed. Recording the real boundary is more
honest than a rule the repo breaks in its own installer.

## What is overlaid today

| Skill | Line added | Why | Re-applied by | Watched by |
|---|---|---|---|---|
| `improve` | `user-invocable: true` | Upstream ships without it, which makes `/improve` do nothing at all | `setup.sh` | `verify.sh` 5c |
| `animation-vocabulary` | `disable-model-invocation: true` | Reference material for `/design`, not a competing door (`docs/DESIGN_SURFACES.md`) | `setup.sh` | `verify.sh` 5d |
| `find-animation-opportunities` | same | same | `setup.sh` | `verify.sh` 5d |
| `improve-animations` | same | same | `setup.sh` | `verify.sh` 5d |
| `review-animations` | same | Upstream already ships it demoted; the check covers it so a future upstream change is caught | n/a | `verify.sh` 5d |
| `apple-design` | same | same | `setup.sh` (skipped when absent, since nothing here installs it) | `verify.sh` 5d |
| `emil-design-eng` | same | same | `setup.sh` | `verify.sh` 5d |
| `interface-design` | same | same | `setup.sh` | `verify.sh` 5d |
| `styleseed` and 22 `ss-*` | **all 23 symlinks deleted** | The chosen coherence authority, but `docs/DESIGN_SURFACES.md` allows three doors and this would have added 23. Only `engine/*.md` is kept, vendored at `.agents/styleseed-engine/`, read by `/design` | `setup.sh` | `verify.sh` 5e |
| `animation-vocabulary`, `ponytail-debt` | `model: haiku` | Cheap skills pinned to a cheap model | **nothing**, see below | nothing |
| `ponytail-gain`, `ponytail-help` | **deleted after install** | Neither is invoked by anything and neither does work: one prints a scoreboard, the other a help card. They cannot be uninstalled on their own, because one `npx skills add DietrichGebert/ponytail` installs all six, so `setup.sh` deletes these two straight after that line | `setup.sh` | nothing yet |

## Why every overlay needs both halves

`npx skills add` and `npx skills update` rewrite the file from upstream and say nothing about
it. An overlay with no re-apply step survives until the next install; an overlay with no check
fails silently, and the symptom is subtle: `/improve` quietly stops existing, or a demoted
design skill quietly comes back as a rival door. Neither shows up as an error.

So an overlay is only finished when it has three things: the line, a `setup.sh` block that
re-applies it idempotently, and a `verify.sh` row that WARNs when it is gone.

The four `model: haiku` pins have none of the last two, which is why `README.md` tells you they
vanish on reinstall and that nothing breaks when they do. That is an accepted gap, recorded
rather than hidden. If it ever stops being acceptable, it needs the same two halves as the
rest.

## Ordering matters in `setup.sh`

A patch must be applied **after** the install that owns the directory. Four of the six demoted
skills come from `emilkowalski/skills`, so their block sits after that install line. Placing it
next to the earlier `improve` patch would have it overwritten seconds later by the installer
running below it. `apple-design` is installed by hand and by nothing in this repo, so the loop
skips it when the path is absent rather than reporting a failure.

## Why 12 of the 13 borrowed skills are deliberately not in the lock file

Decided 2026-08-18, recounted 2026-08-20. The lock holds three entries, and only one of them,
`interface-design`, has a live symlink under `skills/`. `orca-cli` is locked but archived, so
the entry outlives the link. `impeccable` is locked with nothing symlinked to it at all, and it
is a *different project* from the enabled `impeccable` plugin: `bergside/awesome-design-md-skills`
against `pbakaus/impeccable`. Same name, different upstream.

`computer-use` was the fourth entry until 2026-08-20. Removing the skill did **not** remove the
entry: `npx skills remove` deleted the symlink and the folder and left the lock untouched, which
is exactly the state that makes `npx skills update` reinstall a thing you thought was gone. The
entry was deleted by hand afterwards. **Treat `npx skills remove` as one of three steps, never
the whole job**, and check the lock after every removal.

**What being unlocked costs.** `npx skills update` builds its work list from
`Object.keys(lock.skills)` and nothing else (its `updateGlobalSkills`). An unlocked skill is
not updated and is not mentioned, and the run reports success having touched none of them. So 12
borrowed skills sit frozen, silently. `/checkup` prints both numbers and names, so the
silence is at least visible here.

Note that the `Source:` column in `npx skills list` is read from each skill's own frontmatter
(`metadata.author`), not from the lock. A skill can therefore show a GitHub source and still be
unlocked, which is how the earlier count was overstated.

**Why re-locking is worse today.** `npx skills add`/`update` rewrite a skill from upstream and
say nothing, which wipes the frontmatter overlays in the table above. **Eight** of the unlocked
skills carry one: `animation-vocabulary`, `find-animation-opportunities`, `improve-animations`,
`review-animations`, `apple-design`, `emil-design-eng` (demotions), `improve`
(`user-invocable`), and the `model: haiku` pin on `ponytail-debt`. Losing a demotion turns
reference material back into a competing design door, the thing
`skills/checkup/scripts/design_doors.py` exists to catch. The remaining haiku pins have neither
a `setup.sh` re-apply nor a `verify.sh` row, so they would go without a trace.

Trading a silent non-update for a silent demotion-reversal is a bad trade, so nothing was
re-installed. Hand-writing lock entries was also rejected: their hashes would be invented, and
a fabricated record of an install that never happened is what rule 1 in `docs/CORE_RULES.md`
bans.

**The prerequisite for revisiting this**: every overlay has both halves, a `setup.sh` block
and a `verify.sh` row. Four do not. Give the haiku pins those two halves first, then re-locking
becomes a safe, boring operation.

## Adding a new overlay

1. Add the line to `~/.claude/skills/<name>/SKILL.md`, through the symlink, never through an
   installer root. See the two-roots note at the top.
2. Add an idempotent re-apply block to `setup.sh`, after the install that owns the directory.
3. Add a `verify.sh` row that WARNs when the line is missing, skipping cleanly when the path
   does not exist. CI and a fresh clone have no borrowed skills at all. Make PASS conditional
   on having actually checked something, so "checked nothing" cannot render as "all clear".
4. Add a row to the table above.
5. If it changes what can be invoked, update `docs/DESIGN_SURFACES.md` in the same commit.
