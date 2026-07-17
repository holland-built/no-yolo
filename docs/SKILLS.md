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

Orchestration calling sub-skills is NOT straddling. Build orchestration from utility sub-skills — update a utility once and every orchestration skill that calls it inherits the fix.

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

## Skill Authoring Rules

Authoring standards (description = trigger condition, gotchas discipline, new-skill checklist, publish rules) live in `~/.claude/docs/NO_YOLO.md` — follow those. Not covered there: Claude Code scans skill descriptions on session start to route requests automatically, so the trigger phrasing directly controls routing.

## Per-Project vs Global

Token-budget guidance (global-skill bloat, prefer per-project installs) lives in `~/.claude/docs/CONTEXT.md`.

**Simplicity self-check before installing:** install only what the task asks for. No skill packs "just in case," no configurability you didn't request, no abstraction for a single use. Ask "would a senior engineer say this is overcomplicated?" — if yes, don't install it.

## Daily-Driver Skills

| Skill | When |
|---|---|
| `caveman:caveman` | Cut tokens ~75% on long sessions |
| `plan` | Pre-build planning interview — extracts decisions before any code |
| `diagnose` | 6-phase bug diagnosis — minimize/hypothesize/instrument/fix |
| `tdd` | Vertical-slice TDD — one test → impl → green → repeat; forbids all-tests-first |
| `build` | Full feature pipeline: evidence → plan → Opus plan → approval gate → mockup gate → TDD → build → regression → prove |
| `review` | Diff review AND full codebase health pass (fallow + trim + improve) — one ranked findings list, one approve-all gate |
| `design` | Fresh design generation: 10 Opus mockups (8 paradigms + 2 wild) → slop validator → you confirm → Opus plan → Sonnet build |
| `quick-mockup` | Fast disposable placeholder-only HTML mockup for layout/spatial decisions — no brand tokens, no pipeline |
| `design-audit` | Read-only design audit: 5 parallel lenses (Taste/Swiss/UIwiki/a11y/code-health) → violations table + top-10 |

## Symlinks vs Real Skill Dirs

`~/.claude/skills/` mixes real dirs (your skills) with symlinks to plugin packs (trim, improve). Both work identically. Run `/my-skills` to see the current list.
