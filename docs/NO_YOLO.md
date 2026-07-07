# no-yolo — Skill Authoring Rules

This directory (`~/.claude`) is the source repo for `github.com/holland-built/no-yolo`.
When working here, you are authoring public skills — write for a stranger, not yourself.

## Skill authoring standards

- **eli5 output** — every skill's output must be readable by someone who has never used Claude Code. No jargon without explanation. If it needs a glossary, rewrite it.
- **No AI slop** — all mockup-generating skills enforce the slop fingerprint (see `UI_MOCKUPS.md`). Never ship a card-grid or accordion-only design.
- **Token economy** — skill files are scannable, not essays. Steps over paragraphs. Tables over lists of sentences.
- **Description = trigger condition** — the `description` field in SKILL.md frontmatter must tell Claude WHEN to fire and WHO it serves, not summarize what the skill is. Pattern: "Use this skill when the user asks to [exact phrases]."
- **Gotchas grow organically** — only add gotchas that actually happened in testing; never pre-load them. Skills start small and improve as real failures accumulate.
- **New skill checklist** — every new skill needs:
  - `skills/<name>/SKILL.md` with `user-invocable: true` in frontmatter (required for blue slash command in UI; description = trigger condition)
  - One-line entry in `skills/my-skills/TAGLINES.md`, `WHEN_TO_USE.md`, and `WHY_TO_USE.md`
  - Entry in `skills/my-skills/STORIES.md`
  - Trigger block in `docs/SKILL_TRIGGERS.md` (if user-invocable)
  - Row in `README.md` skill table — format: `` | `/name` | what it does | modes & flags | `` (backtick + slash prefix required)

## What is safe to publish

| Safe to push | Never push |
|---|---|
| `skills/` | `memory/` |
| Root `*.md` files (CLAUDE.md, CORE_RULES.md, etc.) | `brainstorms/` |
| `hooks/` (scripts only — no credential files) | `plans/` / `proposals/` |
| `setup.sh` | `settings.json` / `settings.local.json` |
| `settings.example.json` | `plugins/` (third-party, own repos) |

## Publishing workflow

Run `/release` from any Claude Code session. It:
1. Shows changed skill files
2. Guards against personal dir leaks
3. Commits + pushes to `github.com/holland-built/no-yolo`
