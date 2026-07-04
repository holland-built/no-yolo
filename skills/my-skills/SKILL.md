---
name: my-skills
description: Use this skill when the user types /my-skills, says 'my skills', 'list my skills', or 'skills I created'. Lists authored skills (not plugin packs) in a table plus a relationship map of skill dependencies.
user-invocable: true
argument-hint: "[deep]"
model: haiku
allowed-tools:
  - Bash
---

# my-skills

Mode: $ARGUMENTS

Two modes:
- **Default** (empty) — paired-column, no section headers: Skill + What it does + Skill + What it does. 2-5 word summaries, 2 skills per row. Whole menu fits on one screen.
- **deep** — 4-col (adds When + Why) + Relationships + Bolt-ons, grouped by category with section headers.

Default mode's "What it does" uses TAGLINES_SHORT.md (2-5 word summaries). Deep mode uses TAGLINES.md (full one-liners) + WHEN_TO_USE.md + WHY_TO_USE.md.

`$ARGUMENTS` = `deep` → 4-col all 4 sections. Empty (or anything else) → paired 4-col, no headers.

## How to run

### Output — pre-rendered table

```bash
if [ "$ARGUMENTS" = "deep" ]; then
  cat "$HOME/.claude/skills/my-skills/RENDERED.md"
else
  cat "$HOME/.claude/skills/my-skills/RENDERED_FAST.md"
fi
```

Print verbatim — complete GFM with tables. Do NOT rephrase or reformat.

> Both RENDERED.md and RENDERED_FAST.md are rebuilt automatically by /release. To rebuild manually, re-run the RENDERED regen (see `~/.claude/SHIP.md` → ## Steps → "Regenerate menus").

### Section 3 — Relationships (what each skill leans on) — deep mode only

```bash
stories="$HOME/.claude/skills/my-skills/STORIES.md"
grep "^rel:" "$stories" | sed 's/^rel://' | while IFS='|' read -r name story; do
  printf '%s\t%s\n' "$name" "$story"
done
```

Emit as `| Skill | The whole story |` markdown table. Use stored text exactly — do NOT rephrase.

### Section 4 — Bolt-on dependencies (outside tools the skills need) — deep mode only

```bash
stories="$HOME/.claude/skills/my-skills/STORIES.md"
grep "^bolt:" "$stories" | sed 's/^bolt://' | while IFS='|' read -r name story; do
  printf '%s\t%s\n' "$name" "$story"
done
```

Emit as `| Tool | The whole story |` markdown table. Use stored text exactly — do NOT rephrase.
