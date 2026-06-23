# Skills & Plugins

## Installed sources

- **Core rules** — `~/.claude/docs/CORE_RULES.md` (loaded every session via CLAUDE.md)
- **Caveman** — terse-output mode (`/caveman lite|full|ultra`)
- Custom skills under `~/.claude/skills/` — run `/my-skills` to list them

## Per-Project vs Global

Industry guidance (from engineers like Andrej Karpathy and Boris Cherny) recommends installing skills **per-project** rather than globally. Global skills bloat every session's prompt by ~30–40k tokens (tokens are the chunks Claude reads — more tokens = slower, more expensive sessions). Per-project installs cost nothing when not in use.

**Simplicity self-check before installing:** install only what the task asks for. No skill packs "just in case," no configurability you didn't request, no abstraction for a single use. Ask "would a senior engineer say this is overcomplicated?" — if yes, don't install it.

## Daily-Driver Skills

| Skill | When |
|---|---|
| `caveman:caveman` | Cut tokens ~75% on long sessions |
| `plan` | Pre-build planning interview — extracts decisions before any code |
| `diagnose` | 6-phase bug diagnosis — minimize/hypothesize/instrument/fix |
| `tdd` | Vertical-slice TDD — one test → impl → green → repeat; forbids all-tests-first |
| `build` | Full pipeline (thin wrapper): calls `/plan-feature` then `/build-feature`. Use for end-to-end runs. |
| `plan-feature` | Evidence → plan → Opus plan → approval gate. The no-code gate — stops before any code. |
| `build-feature` | Reads approved plan → mockup gate → TDD → build → regression → prove. |
| `code-health` | Three-phase health: Fallow (dead-code/dupes/security) → Trim (YAGNI review) → Improve (plan) |
| `code-review` | 3-pass diff review: correctness → over-engineering → engineering filters (scope check + simplicity check) |
| `ui-ux` | Design intelligence — 161 palettes, 99 UX guidelines, font pairings, chart types |
| `ui-wild` | Radical redesign: 10 Opus designers compete, a judge agent that rejects generic AI output, mockup approval gate |

## Symlinks vs Real Skill Dirs

`~/.claude/skills/` mixes real dirs (your skills) with symlinks to plugin packs (trim, improve). Both work identically. Run `/my-skills` to see the current list.
