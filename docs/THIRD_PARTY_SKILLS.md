# Third-Party Skills — where to get them, never a copy in this repo

Other people's work never gets uploaded here — no vendored file, no pinned copy committed to
git. Each row below is a **pointer**: what it is, whose repo it's from, and the exact command
that fetches it onto your own machine. `skills/*/vendor/` is gitignored — the files exist
locally after you (or `/update vendor <name>`) run the install command, but never on GitHub.

| Name | Upstream repo | Install command | Local path (gitignored) | Used by |
|---|---|---|---|---|
| taste-skill | `Leonxlnx/taste-skill` | `/update vendor taste-skill` (first run installs, later runs re-fetch latest) | `skills/design/vendor/taste-skill/` | `/design` Step 1 only (fresh-gen dials + routing) |
| trim (+5 sub-skills) | `holland-built/trim` | `npx skills@latest add holland-built/trim` (hashes pinned in `skills-lock.json`) | `skills/trim*` | `/review`, `/trim*` |
| improve | `shadcn/improve` | `npx skills@latest add shadcn/improve` | `skills/improve` | `/review`, `/improve` |
| emil-design-eng (+2) | `emilkowalski/skills` | `npx skills@latest add emilkowalski/skills` (hashes pinned in `skills-lock.json`) | `skills/emil-design-eng`, `skills/animation-vocabulary`, `skills/review-animations` | `/design`, `/design-audit` |
| archify | `tt-a1i/archify` | `npx skills@latest add tt-a1i/archify` (hash pinned in `skills-lock.json`) | `.agents/skills/archify` | diagrams — replaced the tracked draw.io skill 2026-07-17 |

taste-skill is **vendored** (a copy fetched locally, never on GitHub, per the preamble above).
trim / improve / emil-design-eng are **npx-installed** as symlinks (not vendored) — two of the
three have their fetched content hashes recorded in `skills-lock.json` for drift detection;
`shadcn/improve` has no lockfile entry (see Maintenance notes in the plan for why).

If the local path doesn't exist yet (fresh clone, or never installed), the skills that use it
fall back to their own built-in FALLBACKS block — nothing breaks, you just get the baked-in
minimum instead of the real upstream rules until you run the install command.

## Local patches applied on top of upstream (a reinstall silently reverts these)

| Skill | Patch | Why | Re-apply after reinstall |
|---|---|---|---|
| improve | added `user-invocable: true` to its frontmatter | Upstream ships without it, so typing `/improve` never fired. `/review`'s H3 was unaffected: invoking a skill via the Skill tool ignores that field. | `setup.sh` now re-applies it automatically after install; manual fallback: re-add the line to `~/.agents/skills/improve/SKILL.md` |

Check this table after any `npx skills@latest add ...`. These patches live outside git (the
paths are gitignored symlinks), so nothing warns you when an install wipes them.

To add a new row: pick an install command (usually `curl`/`gh` pulling specific files, wired
into `/update vendor <name>` — see `skills/update/SKILL.md` Step 11), add the gitignore line
for its local path, add a row here. Never commit the fetched content itself.
