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

All sections rendered as 2-column markdown tables: **Skill/Tool** | **The whole story**.
Stories are pre-baked in STORIES.md — emit them exactly as stored, no rephrasing or synthesis.

Check the argument the user passed. If it is `deep`, run all 4 sections. Otherwise run only Sections 1 and 2.

## How to run

### Section 1 — Your skills

```bash
stories="$HOME/.claude/skills/my-skills/STORIES.md"
for d in ~/.claude/skills/*/; do
  [ -L "${d%/}" ] && continue
  name=$(basename "$d")
  [ "$(ls -A "$d" 2>/dev/null)" ] || continue
  story=$(grep "^$name|" "$stories" 2>/dev/null | cut -d'|' -f2-)
  [ -z "$story" ] && story="⚠️ missing story — add to STORIES.md"
  printf '%s\t%s\n' "$name" "$story"
done
```

Emit as `| Skill | The whole story |` markdown table. Use stored text exactly — do NOT rephrase.

### Section 2 — Installed / plugin skills

```bash
stories="$HOME/.claude/skills/my-skills/STORIES.md"
for d in ~/.claude/skills/*/; do
  [ -L "${d%/}" ] || continue
  name=$(basename "$d")
  story=$(grep "^$name|" "$stories" 2>/dev/null | cut -d'|' -f2-)
  [ -z "$story" ] && story="⚠️ missing story — add to STORIES.md"
  printf '%s\t%s\n' "$name" "$story"
done
```

Emit as `| Skill | The whole story |` markdown table. If no plugin skills, omit section. Use stored text exactly — do NOT rephrase.

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
