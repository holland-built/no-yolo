# Third-Party Skills — where to get them, never a copy in this repo

Other people's work never gets uploaded here — no vendored file, no pinned copy committed to
git. Each row below is a **pointer**: what it is, whose repo it's from, and the exact command
that fetches it onto your own machine. `skills/*/vendor/` is gitignored — the files exist
locally after you (or `/update vendor <name>`) run the install command, but never on GitHub.

| Name | Upstream repo | Install command | Local path (gitignored) | Used by |
|---|---|---|---|---|
| taste-skill | `Leonxlnx/taste-skill` | `/update vendor taste-skill` (first run installs, later runs re-fetch latest) | `skills/design/vendor/taste-skill/` | `/design` Step 1 only (fresh-gen dials + routing) |

If the local path doesn't exist yet (fresh clone, or never installed), the skills that use it
fall back to their own built-in FALLBACKS block — nothing breaks, you just get the baked-in
minimum instead of the real upstream rules until you run the install command.

To add a new row: pick an install command (usually `curl`/`gh` pulling specific files, wired
into `/update vendor <name>` — see `skills/update/SKILL.md` Step 11), add the gitignore line
for its local path, add a row here. Never commit the fetched content itself.
