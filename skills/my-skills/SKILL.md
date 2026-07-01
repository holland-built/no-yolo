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
- **Default** (empty) — 2-col: Skill + What it does. Fits screen.
- **deep** — 4-col (adds When + Why) + Relationships + Bolt-ons.

"What it does" always uses TAGLINES.md (short one-liners). WHEN_TO_USE.md and WHY_TO_USE.md for deep mode only.

`$ARGUMENTS` = `deep` → 4-col all 4 sections. Empty (or anything else) → 2-col sections 1+2.

## How to run

### Output — pre-rendered table

```bash
if [ "$ARGUMENTS" = "deep" ]; then
  cat "$HOME/.claude/skills/my-skills/RENDERED.md"
else
  cat "$HOME/.claude/skills/my-skills/RENDERED_FAST.md"
fi
```

Print verbatim — complete GFM with section headers and tables. Do NOT rephrase or reformat.

> Both RENDERED.md and RENDERED_FAST.md are rebuilt automatically by /ship. To rebuild manually: run the regen script in ship/SKILL.md Step 3c.6.

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
