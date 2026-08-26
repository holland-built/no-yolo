# Archive manifest

Archived 2026-08-20, under `docs/REBUILD_PLAN.md`. <!-- gone-on-purpose -->

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
| `better-prompt` | Rewrote a rough prompt against learned conventions | `git mv archive/skills/better-prompt skills/better-prompt` |
| `ingest-docs` | Converted PDF/Word/PowerPoint in `docs/raw/` into clean context files | `git mv archive/skills/ingest-docs skills/ingest-docs` |
| `dep-audit` | npm-only supply-chain pass: leaked keys, advisories, licences | `git mv archive/skills/dep-audit skills/dep-audit` |

**Restored since:** `watch` was moved back to `skills/watch` on 2026-08-25, and `last-30` on
2026-08-26, and both are live again. Their rows are gone from the table above rather than
struck through, because a restore command sitting beside a skill that is already restored is a
trap for whoever reads it next.

`last-30` came back because the owner went looking for it and could not find it. Its Firecrawl
mode does not work: the skill declares `mcp__firecrawl__firecrawl_search`, and no Firecrawl
server is registered, so those tools do not exist in a session. The self-hosted box answers on
its configured address, so what is missing is the registration and not the service. The skill
falls back to plain web search and its preflight says so out loud, which is why restoring it
was still worth doing.

## Archived, third-party and never in git (`archive/styleseed/`)

StyleSeed, archived 2026-08-25. 27 entries, 104 files, 1.2 MB, copied with their
source-relative paths preserved and hash-verified entry by entry before anything was removed.
27 of 27 matched.

**This one could not have been recovered by git.** Every path was in `.gitignore`, so a plain
delete would have been permanent, exactly as it was for the 74 brand specifications lost on
2026-08-21. The copy is the only reason the removal is reversible.

| What | Where it is now |
|---|---|
| `skills/styleseed` and 22 `ss-*` | `archive/styleseed/skills/` |
| `.agents/skills/styleseed`, `ss-resolve`, `ss-score` | `archive/styleseed/.agents/skills/` |
| `.agents/styleseed-engine`, 28 files, 372 KB | `archive/styleseed/.agents/styleseed-engine/` |

Restore all of it:

```bash
cp -R archive/styleseed/skills/. ~/.claude/skills/
cp -R archive/styleseed/.agents/. ~/.claude/.agents/
```

Two of the 23 were symlinks into `.agents/skills/`. They are archived as real files, so a
restore produces directories where links used to be. That works, and `npx skills update` will
relink them if it is ever run again.

**Why it went.** Codex was asked to rule on keep-versus-delete against evidence rather than
taste, and found three things. It satisfied neither of the owner's stated requirements: not in
the repo, and nothing watching it for upstream changes. Its router refuses to act until a
project contains `.styleseed/project.json`, a file the owner cannot write. And it could not be
reduced to a smaller core, because that router depends on the separate engine payload above.
`skills/design` replaces it, reading 74 real brand specifications from `refs/brands/`.

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
in `docs/THIRD_PARTY_SKILLS.md`. <!-- gone-on-purpose -->

## Not archived, and why

The plan listed these for archiving. They are load-bearing, so they stayed. This is a
finding, not a deferral: the plan assumed they were retired commands.

| Name | Why it stayed |
|---|---|
| `design` | 31 inbound files. `build` calls `skills/design/scripts/mockup-dir.sh` and reads `PREFAB_SOURCING.md`; `release`, `SHIP.md` and two hook tests also depend on it. | <!-- gone-on-purpose -->
| `checkup` | Two hook tests exercise its scripts (`design_doors.py`, `borrowed_check.py`). |
| `route-map` | `build` runs `skills/route-map/scripts/route-check.mjs`, and `hooks/tests/route-check.test.sh` tests it. | <!-- gone-on-purpose -->
| `improve` | `verify.sh` asserts a local patch on it; `setup.sh` installs it; `health` and the design docs reference it. |

Moving any of these means moving the code its dependants call, in the same commit.
That was not in scope for this pass.
