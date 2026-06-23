# Skills & Plugins

## Installed sources

- **Core rules** — `~/.claude/docs/CORE_RULES.md` (loaded every session via CLAUDE.md)
- **Caveman** — terse-output mode (`/caveman lite|full|ultra`)
- Custom skills under `~/.claude/skills/` — run `/my-skills` to list them

## Skill Taxonomy (Anthropic's 4 buckets)

Every skill fits exactly ONE bucket — straddling two confuses the agent:

| Type | Does | Example |
|------|------|---------|
| **Utility** | One small reusable thing, every time | draft-in-my-voice, simplify-writing |
| **Verification** | Checks output; objective Pass/Fail or /10 | code-review, brand-voice-check |
| **Data Enrichment** | Pulls external data in | funnel-digest, competitor-analysis |
| **Orchestration** | Chains other skills into a playbook | generate-report, weekly-standup |

Orchestration calling sub-skills is NOT straddling. Build orchestration from sub-utility skills — update a utility, all orchestration skills that call it inherit the fix.

**Verification = highest ROI.** "If you give Claude a way to verify it will 2–3x the quality of the output." — Claude Code creator. Spend time here first.

## Skill Folder Structure

Skills are folders, not just markdown files:

```
my-skill/
  SKILL.md        ← instructions; description = trigger condition (see below)
  scripts/        ← deterministic logic (same input → same output)
  assets/         ← templates, examples, reference files
  config.json     ← values prompted once on first run, stored after
```

Push deterministic work into scripts — more scripts = more repeatable output + fewer tokens burned.

Setup usability pattern:
- `config.json` — prompt for values on first run, store them; don't re-enter on every call
- `AskUserQuestion` tool — structured multiple-choice instead of free-form input
- `arguments` frontmatter field — declares expected inputs at invocation time

## Description Field = Trigger Condition

The `description` field in SKILL.md is **not a summary** — it is a trigger condition: tells Claude WHEN to fire and WHO it serves. Claude Code scans descriptions on session start to route requests automatically.

- Good: *"Use this skill when the user asks to build web components, pages, or applications."*
- Bad: *"A skill that builds web UI components."*

A good trigger names: (1) who it serves, (2) exact phrases a user would type.

## Gotchas Discipline

Gotchas = highest-signal content in any skill file. Rules:
- Only add gotchas you have **actually seen** Claude get wrong — never pre-load them
- Skills start small and grow as Claude hits real edge cases
- "Wait, watch, then add to it."

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
