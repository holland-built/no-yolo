# Archive manifest

Archived 2026-08-20, under `docs/REBUILD_PLAN.md`.

Archived means out of the loaded path but recoverable by name. It does not mean
deleted, and it does not mean "git remembers". Nothing here is loaded at session
start: Claude Code discovers skills only at `~/.claude/skills/*/SKILL.md`, and this
folder is a sibling of that one. Evidence it is genuinely inert:
`~/.agents/skills/impeccable/SKILL.md` exists, is not symlinked into `skills/`, and
does not appear in a session's skill list except through its own plugin.

**Notes about archived commands live here and only here.** No stub `SKILL.md` is left
behind at the old name. A stub would still be discovered and would still cost context
in every session, which is the exact thing archiving is meant to stop.

## Archived, own code (in `archive/skills/`)

| Name | What it did | Restore |
|---|---|---|
| `last-30` | Trending signal from GitHub, HN, Reddit, YouTube, X, last 30 days | `git mv archive/skills/last-30 skills/last-30` |
| `better-prompt` | Rewrote a rough prompt against learned conventions | `git mv archive/skills/better-prompt skills/better-prompt` |
| `watch` | Downloaded a video, transcribed it, answered from frames + transcript | `git mv archive/skills/watch skills/watch` |
| `ingest-docs` | Converted PDF/Word/PowerPoint in `docs/raw/` into clean context files | `git mv archive/skills/ingest-docs skills/ingest-docs` |
| `dep-audit` | npm-only supply-chain pass: leaked keys, advisories, licences | `git mv archive/skills/dep-audit skills/dep-audit` |

## Archived, third-party (link removed, payload untouched)

These were symlinks into git-ignored third-party folders. The link is gone; the code
it pointed at is still on disk, exactly where it was. Restoring is one `ln -s`.

| Name | Payload still at | Restore |
|---|---|---|
| `archify` | `~/.claude/.agents/skills/archify` | `ln -s ../.agents/skills/archify ~/.claude/skills/archify` |
| `resolving-merge-conflicts` | `~/.claude/.agents/skills/resolving-merge-conflicts` | `ln -s ../.agents/skills/resolving-merge-conflicts ~/.claude/skills/resolving-merge-conflicts` |
| `orca-cli` | `~/.agents/skills/orca-cli` | `ln -s ../../.agents/skills/orca-cli ~/.claude/skills/orca-cli` |

`archify` also had an install line in `setup.sh` (`npx skills@latest add tt-a1i/archify`).
That line was removed in the same commit. Leaving it would have put the symlink back on
the next setup run. If you restore `archify`, restore that line too.

`resolving-merge-conflicts` and `orca-cli` were never in `setup.sh`. Their payloads were
installed by hand, so a fresh machine will not have them to link to. Sources are recorded
in `docs/THIRD_PARTY_SKILLS.md`.

## Not archived, and why

The plan listed these for archiving. They are load-bearing, so they stayed. This is a
finding, not a deferral: the plan assumed they were retired commands.

| Name | Why it stayed |
|---|---|
| `design` | 31 inbound files. `build` calls `skills/design/scripts/mockup-dir.sh` and reads `PREFAB_SOURCING.md`; `release`, `SHIP.md` and two hook tests also depend on it. |
| `checkup` | Two hook tests exercise its scripts (`design_doors.py`, `borrowed_check.py`). |
| `route-map` | `build` runs `skills/route-map/scripts/route-check.mjs`, and `hooks/tests/route-check.test.sh` tests it. |
| `improve` | `verify.sh` asserts a local patch on it; `setup.sh` installs it; `health` and the design docs reference it. |

Moving any of these means moving the code its dependants call, in the same commit.
That was not in scope for this pass.
