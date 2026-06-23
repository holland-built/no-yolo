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

### Section 1 — Your skills

```bash
taglines="$HOME/.claude/skills/my-skills/TAGLINES.md"
when="$HOME/.claude/skills/my-skills/WHEN_TO_USE.md"
why="$HOME/.claude/skills/my-skills/WHY_TO_USE.md"
if [ "$ARGUMENTS" = "fast" ]; then
  printf '| Skill | What it does |\n'
  printf '| --- | --- |\n'
else
  printf '| Skill | What it does | When to use | Why vs manual |\n'
  printf '| --- | --- | --- | --- |\n'
fi
for d in ~/.claude/skills/*/; do
  [ -L "${d%/}" ] && continue
  name=$(basename "$d")
  [ "$(ls -A "$d" 2>/dev/null)" ] || continue
  story=$(grep "^$name|" "$taglines" 2>/dev/null | cut -d'|' -f2-)
  [ -z "$story" ] && story="⚠️ missing"
  if [ "$ARGUMENTS" = "fast" ]; then
    printf '| %s | %s |\n' "$name" "$story"
  else
    when_val=$(grep "^$name|" "$when" 2>/dev/null | cut -d'|' -f2-)
    why_val=$(grep "^$name|" "$why" 2>/dev/null | cut -d'|' -f2-)
    [ -z "$when_val" ] && when_val="—"
    [ -z "$why_val" ] && why_val="—"
    printf '| %s | %s | %s | %s |\n' "$name" "$story" "$when_val" "$why_val"
  fi
done
```

Print the bash output verbatim — complete GFM table. Do NOT rephrase or reformat.

### Section 2 — Installed / plugin skills

```bash
taglines="$HOME/.claude/skills/my-skills/TAGLINES.md"
when="$HOME/.claude/skills/my-skills/WHEN_TO_USE.md"
why="$HOME/.claude/skills/my-skills/WHY_TO_USE.md"
found=0
for d in ~/.claude/skills/*/; do [ -L "${d%/}" ] && found=1 && break; done
[ $found -eq 0 ] && exit 0
if [ "$ARGUMENTS" = "fast" ]; then
  printf '| Skill | What it does |\n'
  printf '| --- | --- |\n'
else
  printf '| Skill | What it does | When to use | Why vs manual |\n'
  printf '| --- | --- | --- | --- |\n'
fi
for d in ~/.claude/skills/*/; do
  [ -L "${d%/}" ] || continue
  name=$(basename "$d")
  story=$(grep "^$name|" "$taglines" 2>/dev/null | cut -d'|' -f2-)
  [ -z "$story" ] && story="⚠️ missing"
  if [ "$ARGUMENTS" = "fast" ]; then
    printf '| %s | %s |\n' "$name" "$story"
  else
    when_val=$(grep "^$name|" "$when" 2>/dev/null | cut -d'|' -f2-)
    why_val=$(grep "^$name|" "$why" 2>/dev/null | cut -d'|' -f2-)
    [ -z "$when_val" ] && when_val="—"
    [ -z "$why_val" ] && why_val="—"
    printf '| %s | %s | %s | %s |\n' "$name" "$story" "$when_val" "$why_val"
  fi
done
```

Print verbatim. If no plugin skills found, omit section.

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
