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

taste-skill is **vendored** (a copy fetched locally, never on GitHub, per the preamble above).
trim / improve / emil-design-eng are **npx-installed** as symlinks (not vendored) — two of the
three have their fetched content hashes recorded in `skills-lock.json` for drift detection;
`shadcn/improve` has no lockfile entry (see Maintenance notes in the plan for why).

If the local path doesn't exist yet (fresh clone, or never installed), the skills that use it
fall back to their own built-in FALLBACKS block — nothing breaks, you just get the baked-in
minimum instead of the real upstream rules until you run the install command.

To add a new row: pick an install command (usually `curl`/`gh` pulling specific files, wired
into `/update vendor <name>` — see `skills/update/SKILL.md` Step 11), add the gitignore line
for its local path, add a row here. Never commit the fetched content itself.
