---
name: my-md
description: Use this skill when the user types /my-md, says 'list md files', 'show markdown files', 'what hooks do I have', 'list my hooks', or 'what runs automatically'. Lists everything in the setup that is not a skill — markdown files in ~/.claude/ and the current project, plus every hook script and what it does, flagging any hook with no write-up.
user-invocable: true
argument-hint: ""
model: haiku
effort: low
allowed-tools:
  - Bash
---

# my-md

Everything in the setup that is NOT a skill. Three sections, all rendered as
2-column markdown tables. No deep mode — these are flat lists, nothing to go deeper on.

Skills live in `/my-skills`. This covers the other two halves: the markdown files
that hold the rules, and the hook scripts that run on their own.

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

## Section 3 — Hooks (things that run on their own)

Hooks are scripts the harness runs automatically at set moments — session start,
every prompt, before a file is written. Nobody invokes them; they just fire.
Their write-ups live in `docs/HOOKS.md`, and this section is also the drift check:
a script with no write-up shows up flagged instead of staying invisible.

```bash
doc="$HOME/.claude/docs/HOOKS.md"
for f in "$HOME"/.claude/hooks/*.js "$HOME"/.claude/hooks/*.sh "$HOME"/.claude/hooks/*.py; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  case "$name" in node-shim.sh) continue ;; esac
  desc=$(grep -m1 -F "**$name**" "$doc" 2>/dev/null | sed 's/.*\*\* — //; s/^- //')
  [ -z "$desc" ] && desc="⚠️ no write-up — add a line to docs/HOOKS.md"
  printf '%s\t%s\n' "$name" "$desc"
done
```

Emit as `| Hook | What it does |` markdown table. Header: `## Hooks — runs on its own`.
Use stored text exactly — do NOT rephrase, and do NOT invent a description for a
flagged hook. Shorten a long write-up to its first sentence; that is the only edit allowed.

After the table, if any row is flagged, print one line:
`> N hook(s) have no write-up — run /health to get them documented.`
