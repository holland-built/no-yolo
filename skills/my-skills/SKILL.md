---
name: my-skills
description: List the skills you authored (not installed plugin packs) in a table with what each does, plus a relationship map of what each skill calls. Global — any Claude Code session can run it. Activate on "/my-skills", "my skills", "list my skills", "skills I created".
user-invocable: true
argument-hint: "[deep]"
allowed-tools:
  - Bash
---

# my-skills

Two modes:
- **Default** (`/my-skills`) — Sections 1 + 2 only: your skills and plugin skills. Fast daily reference.
- **Deep** (`/my-skills deep`) — All 4 sections: adds Relationships and Bolt-ons.

All sections rendered as 4-column markdown tables: **Skill** | **What it does** | **When to use** | **Why vs manual**.
Data is pre-baked in STORIES.md, WHEN_TO_USE.md, WHY_TO_USE.md — emit exactly as stored, no rephrasing.

Check the argument the user passed. If it is `deep`, run all 4 sections. Otherwise run only Sections 1 and 2.

## How to run

### Section 1 — Your skills

```bash
stories="$HOME/.claude/skills/my-skills/STORIES.md"
when="$HOME/.claude/skills/my-skills/WHEN_TO_USE.md"
why="$HOME/.claude/skills/my-skills/WHY_TO_USE.md"
wrap() { printf '%s' "$1" | fold -s -w 72 | awk '{printf "%s%s", sep, $0; sep="<br>"}'; }
for d in ~/.claude/skills/*/; do
  [ -L "${d%/}" ] && continue
  name=$(basename "$d")
  [ "$(ls -A "$d" 2>/dev/null)" ] || continue
  story=$(grep "^$name|" "$stories" 2>/dev/null | cut -d'|' -f2-)
  when_val=$(grep "^$name|" "$when" 2>/dev/null | cut -d'|' -f2-)
  why_val=$(grep "^$name|" "$why" 2>/dev/null | cut -d'|' -f2-)
  [ -z "$story" ] && story="⚠️ missing"
  [ -z "$when_val" ] && when_val="—"
  [ -z "$why_val" ] && why_val="—"
  printf '%s\t%s\t%s\t%s\n' "$name" "$(wrap "$story")" "$(wrap "$when_val")" "$(wrap "$why_val")"
done
```

Emit as `| Skill | What it does | When to use | Why vs manual |` markdown table. Use stored text exactly — do NOT rephrase.

### Section 2 — Installed / plugin skills

```bash
stories="$HOME/.claude/skills/my-skills/STORIES.md"
when="$HOME/.claude/skills/my-skills/WHEN_TO_USE.md"
why="$HOME/.claude/skills/my-skills/WHY_TO_USE.md"
wrap() { printf '%s' "$1" | fold -s -w 72 | awk '{printf "%s%s", sep, $0; sep="<br>"}'; }
for d in ~/.claude/skills/*/; do
  [ -L "${d%/}" ] || continue
  name=$(basename "$d")
  story=$(grep "^$name|" "$stories" 2>/dev/null | cut -d'|' -f2-)
  when_val=$(grep "^$name|" "$when" 2>/dev/null | cut -d'|' -f2-)
  why_val=$(grep "^$name|" "$why" 2>/dev/null | cut -d'|' -f2-)
  [ -z "$story" ] && story="⚠️ missing"
  [ -z "$when_val" ] && when_val="—"
  [ -z "$why_val" ] && why_val="—"
  printf '%s\t%s\t%s\t%s\n' "$name" "$(wrap "$story")" "$(wrap "$when_val")" "$(wrap "$why_val")"
done
```

Emit as `| Skill | What it does | When to use | Why vs manual |` markdown table. If no plugin skills, omit section. Use stored text exactly — do NOT rephrase.

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
