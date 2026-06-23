---
name: my-md
description: List all markdown files in two sections — global Claude config (~/.claude/) and current project. Shows filename + what it does. Activate on "/my-md", "list md files", "show markdown files".
user-invocable: true
argument-hint: ""
model: haiku
allowed-tools:
  - Bash
---

# my-md

Two sections, both rendered as 2-column markdown tables: **File** | **The whole story**.
No deep mode — it's a flat file list, nothing to go deeper on.

## Section 1 — Global (~/.claude/)

```bash
descs="$HOME/.claude/skills/my-md/GLOBAL_DESCRIPTIONS.md"
for f in ~/.claude/*.md ~/.claude/docs/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  desc=$(grep "^$name|" "$descs" 2>/dev/null | cut -d'|' -f2-)
  [ -z "$desc" ] && desc="⚠️ missing description — add to GLOBAL_DESCRIPTIONS.md"
  printf '%s\t%s\n' "$name" "$desc"
done
```

Emit as `| File | The whole story |` markdown table. Header: `## Global — ~/.claude/`. Use stored text exactly — do NOT rephrase.

## Section 2 — Current project

```bash
if [ "$PWD" = "$HOME" ]; then
  echo "NOT_A_PROJECT"
else
  find . -maxdepth 6 -name "*.md" \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    -not -path "*/dist/*" \
    -not -path "*/.next/*" \
    -not -path "*/build/*" \
    -not -path "*/.cache/*" \
    2>/dev/null \
    | sort | while IFS= read -r f; do
    title=$(grep -m1 "^#" "$f" 2>/dev/null | sed 's/^#* *//')
    [ -z "$title" ] && title="(no heading)"
    excerpt=$(awk '/^#{1,6} /{found=1; next} found && /^[^[:space:]#>|`\-\*]/{gsub(/[_*`]/, ""); print substr($0,1,100); exit}' "$f" 2>/dev/null)
    if [ -n "$excerpt" ]; then
      story="$title — $excerpt"
    else
      story="$title"
    fi
    printf '%s\t%s\n' "${f#./}" "$story"
  done
fi
```

Emit as `| File | The whole story |` markdown table. Header: `## Project — <pwd>`.

- If output is `NOT_A_PROJECT`: print `> Run /my-md from a project directory, not your home folder.`
- If no files found: print `> No markdown files in current project. /build and /plan create them when you run a feature build.`
