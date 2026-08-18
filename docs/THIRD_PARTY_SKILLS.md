# Third-party skills, and the lines we add to them

Borrowed skills are installed by `npx skills` and symlinked into `skills/`. Both the targets
and the symlinks are gitignored: the code belongs to whoever wrote it, and this repo publishes
the pointer, never the copy. `docs/BORROWED.md` is the tracked record of what was borrowed.

**There are two installer roots, not one.** Most borrowed skills land in
`~/.claude/.agents/skills/`; `improve`, `interface-design`, `computer-use`, `orca-cli` and
`resolving-merge-conflicts` land in `~/.agents/skills/`. Nothing here chooses between them —
the installer does. So **never hardcode a root**: address a borrowed skill as
`skills/<name>/SKILL.md` and let the symlink resolve it. Both `setup.sh` and `verify.sh` got
this wrong first and would have skipped `interface-design` without saying anything.

This file covers the exception: the handful of lines this setup adds to files it does not own.

## The rule, stated exactly

> **Third-party bodies are never edited. Frontmatter that controls routing may be overlaid,
> re-applied by `setup.sh`, and watched by `verify.sh`.**

The distinction is the whole policy. A skill's *content* is the author's work and stays
verbatim — that is why `skills/design/vendor/taste-skill/` is vendored untouched and read as
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
| `apple-design` | same | same | `setup.sh` (skipped when absent — nothing here installs it) | `verify.sh` 5d |
| `emil-design-eng` | same | same | `setup.sh` | `verify.sh` 5d |
| `interface-design` | same | same | `setup.sh` | `verify.sh` 5d |
| `animation-vocabulary`, `ponytail-help`, `ponytail-gain`, `ponytail-debt` | `model: haiku` | Cheap skills pinned to a cheap model | **nothing** — see below | nothing |

## Why every overlay needs both halves

`npx skills add` and `npx skills update` rewrite the file from upstream and say nothing about
it. An overlay with no re-apply step survives until the next install; an overlay with no check
fails silently, and the symptom is subtle — `/improve` quietly stops existing, or a demoted
design skill quietly comes back as a rival door. Neither shows up as an error.

So an overlay is only finished when it has three things: the line, a `setup.sh` block that
re-applies it idempotently, and a `verify.sh` row that WARNs when it is gone.

The four `model: haiku` pins have none of the last two, which is why `README.md` tells you they
vanish on reinstall and that nothing breaks when they do. That is an accepted gap, recorded
rather than hidden — if it ever stops being acceptable, it needs the same two halves as the
rest.

## Ordering matters in `setup.sh`

A patch must be applied **after** the install that owns the directory. Four of the six demoted
skills come from `emilkowalski/skills`, so their block sits after that install line — placing it
next to the earlier `improve` patch would have it overwritten seconds later by the installer
running below it. `apple-design` is installed by hand and by nothing in this repo, so the loop
skips it when the path is absent rather than reporting a failure.

## Adding a new overlay

1. Add the line to `~/.claude/skills/<name>/SKILL.md` — through the symlink, never through an
   installer root. See the two-roots note at the top.
2. Add an idempotent re-apply block to `setup.sh`, after the install that owns the directory.
3. Add a `verify.sh` row that WARNs when the line is missing, skipping cleanly when the path
   does not exist — CI and a fresh clone have no borrowed skills at all. Make PASS conditional
   on having actually checked something, so "checked nothing" cannot render as "all clear".
4. Add a row to the table above.
5. If it changes what can be invoked, update `docs/DESIGN_SURFACES.md` in the same commit.
