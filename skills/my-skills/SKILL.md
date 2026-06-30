---
name: my-skills
description: Use this skill when the user types /my-skills, says 'my skills', 'list my skills', or 'skills I created'. Lists authored skills (not plugin packs) in a table plus a relationship map of skill dependencies.
user-invocable: true
argument-hint: "[fast | deep]"
model: haiku
allowed-tools:
  - Bash
---

# my-skills

Mode: $ARGUMENTS

Three modes:
- **Default** (empty) — 4-col: Skill + What + When + Why.
- **fast** — 2-col: Skill + tagline only. Fits screen.
- **deep** — 4-col + Relationships + Bolt-ons.

"What it does" always uses TAGLINES.md (short one-liners). WHEN_TO_USE.md and WHY_TO_USE.md for default/deep modes.

`$ARGUMENTS` = `fast` → 2-col sections 1+2. `$ARGUMENTS` = `deep` → 4-col all 4 sections. Empty → 4-col sections 1+2.

## How to run

### Output — pre-rendered table

```bash
cat "$HOME/.claude/skills/my-skills/RENDERED.md"
```

Print verbatim — complete GFM with section headers and tables. Do NOT rephrase or reformat.

> RENDERED.md is rebuilt automatically by /ship. To rebuild manually: run the regen script in ship/SKILL.md Step 3c.6.

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
