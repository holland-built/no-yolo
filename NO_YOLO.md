# no-yolo — Skill Authoring Rules

This directory (`~/.claude`) is the source repo for `github.com/holland-built/no-yolo`.
When working here, you are authoring public skills — write for a stranger, not yourself.

## Skill authoring standards

- **eli5 output** — every skill's output must be readable by someone who has never used Claude Code. No jargon without explanation. If it needs a glossary, rewrite it.
- **No AI slop** — all mockup-generating skills enforce the slop fingerprint (see `UI_MOCKUPS.md`). Never ship a card-grid or accordion-only design.
- **Token economy** — skill files are scannable, not essays. Steps over paragraphs. Tables over lists of sentences.
- **New skill checklist** — every new skill needs:
  - `skills/<name>/SKILL.md` (the skill itself)
  - Entry in `skills/my-skills/STORIES.md`
  - Row in `README.md` skill table
  - Trigger line in `CLAUDE.md` (if user-invocable)

## What is safe to publish

| Safe to push | Never push |
|---|---|
| `skills/` | `memory/` |
| Root `*.md` files (CLAUDE.md, CORE_RULES.md, etc.) | `brainstorms/` |
| `hooks/` (scripts only — no credential files) | `plans/` / `proposals/` |
| `setup.sh` | `settings.json` / `settings.local.json` |
| `settings.example.json` | `plugins/` (third-party, own repos) |

## Publishing workflow

Run `/publish-skills` from any Claude Code session. It:
1. Shows changed skill files
2. Guards against personal dir leaks
3. Commits + pushes to `github.com/holland-built/no-yolo`
