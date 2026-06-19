# Skills & Plugins

## Installed sources

- **Core rules** — `~/.claude/CORE_RULES.md` (loaded every session via CLAUDE.md)
- **Caveman** — terse-output mode (`/caveman lite|full|ultra`)
- Custom skills under `~/.claude/skills/` — run `/my-skills` to list them

## Per-Project vs Global

Karpathy + Boris Cherny recommend installing skills **per-project** rather than globally. Global skills bloat every session's prompt by ~30–40k tokens. Per-project installs cost nothing when not in use.

**Simplicity self-check before installing (Karpathy Rule 2):** install only what the task asks for. No skill packs "just in case," no configurability you didn't request, no abstraction for a single use. Ask "would a senior engineer say this is overcomplicated?" — if yes, don't install it.

## Daily-Driver Skills

| Skill | When |
|---|---|
| `caveman:caveman` | Cut tokens ~75% on long sessions |
| `grill-me` | Pre-build planning interview — extracts decisions before any code |
| `diagnose` | 6-phase bug diagnosis — minimize/hypothesize/instrument/fix |
| `tdd` | Vertical-slice TDD — one test → impl → green → repeat; forbids all-tests-first |
| `forge` | Full pipeline: grill-me → Opus plan → approval → TDD → Sonnet build → prove |
| `code-health` | Three-phase health: Fallow (dead-code/dupes/security) → Ponytail (YAGNI review) → Improve (plan) |
| `code-review` | 3-pass diff review: correctness → over-engineering → Karpathy filters |
| `ui-ux` | Design intelligence — 161 palettes, 99 UX guidelines, font pairings, chart types |
| `ui-wild` | Radical redesign: 10 Opus designers compete, anti-slop judge, mockup approval gate |

## Symlinks vs Real Skill Dirs

`~/.claude/skills/` mixes real dirs (your skills) with symlinks to plugin packs (ponytail, improve). Both work identically. Run `/my-skills` to see the current list.
