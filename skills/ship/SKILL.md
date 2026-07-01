---
name: ship
description: Use this skill when the user types /ship, says 'ship this', 'push this', 'commit and push', or 'ship my work'. Quality-gated publish for any project: antislop + content leak guard → changelog → commit + push to current branch. In ~/.claude project: also runs md-check, drift-check, README validation, RENDERED.md regen, and GitHub release to no-yolo.
user-invocable: true
argument-hint: "[optional commit message]"
allowed-tools:
  - Bash
  - Read
---

# ship

Quality-gate, changelog, commit + push. Behavior adapts to which project you're in.

## Step 0 — Detect project context

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
IS_CLAUDE_REPO=false
[ "$REPO_ROOT" = "$HOME/.claude" ] && IS_CLAUDE_REPO=true
echo "Repo: $REPO_ROOT | .claude mode: $IS_CLAUDE_REPO"
```

```bash
git -C "$REPO_ROOT" status --short
```

If clean: print "Nothing to ship. Working tree clean." and STOP.

---

## Step 0 — What changed

```bash
git -C ~/.claude status --short
```

If clean: print "Nothing to ship. Working tree clean." and STOP.

---

## Phase 1 — Quality gates (WARN ONLY — never block)

### 1a. Antislop scan (ALL projects)
Read `~/.claude/docs/ANTISLOP.md` — extract all bullets under `## Writing Tells (25)`.
Scan all changed `.md` files (`git diff HEAD --name-only | grep '\.md$'`) for tell matches.
If violations found: print `| File | Tell | Excerpt |` table. Do NOT stop.

### 1b. ~/.claude project only — additional gates
Skip 1b entirely if `IS_CLAUDE_REPO=false`.

**Size check:**
```bash
wc -l ~/.claude/*.md ~/.claude/docs/*.md ~/.claude/skills/*/SKILL.md 2>/dev/null | sort -rn | head -20
```
Table any file >200 lines. Do NOT stop.

**eli5 check:** Read `~/.claude/README.md`. Flag unexplained jargon in any `##` section's first sentence. Do NOT stop.

**Drift check:** Invoke `md-check --drift`. Print DRIFT/WRONG verdicts as warning. Do NOT stop.

**GLOBAL_DESCRIPTIONS check:**
```bash
descs="$HOME/.claude/skills/my-md/GLOBAL_DESCRIPTIONS.md"
{ find "$HOME/.claude" -maxdepth 1 -name "*.md"; find "$HOME/.claude/docs" -maxdepth 1 -name "*.md" 2>/dev/null; } | sort | while IFS= read -r f; do
  name=$(basename "$f")
  grep -q "^$name|" "$descs" 2>/dev/null || echo "MISSING: $name"
done
```
Print warning for any MISSING. Do NOT stop.

---

## Phase 2 — Changelog

Run:
```bash
git -C "$REPO_ROOT" diff HEAD --stat
git -C "$REPO_ROOT" diff HEAD --name-only
```

Determine changelog path:
- `IS_CLAUDE_REPO=true` → `~/.claude/docs/DAILY_CHANGELOG.md`
- Any other project → `$REPO_ROOT/frontend/DAILY_CHANGELOG.md` if exists, else `$REPO_ROOT/DAILY_CHANGELOG.md` (create if missing)

Append to that file:

```
## YYYY-MM-DD

- [plain English bullet per changed skill or doc]
```

Rules:
- Use today's date. If a heading for today already exists, append bullets under it — do NOT add a second heading.
- One bullet per skill or doc changed. Plain English: "added /ship skill", "trimmed ui-ux duplicates", "updated README install steps". No git syntax.
- Do not list `.gitignore` or `DAILY_CHANGELOG.md` itself as bullets.

---

## Phase 3 — Commit + push

### 3a. Personal-file guard (HARD BLOCK — all projects)
If any changed path matches these → STOP, do not commit:
`memory/facts/` `brainstorms/` `plans/` `proposals/` `projects/` `sessions/` `settings.json` `settings.local.json` `history.jsonl` `*.log` `cache/` `paste-cache/`

Output: `BLOCKED — personal files in diff: [list them]. Fix before shipping.`

### 3b. Content scan (HARD BLOCK — all projects)
```bash
git -C "$REPO_ROOT" diff HEAD | grep -E "^\+" | grep -vE "^\+\+\+" | grep -E \
  "/Users/[a-zA-Z0-9_-]+|provenance:|session: [a-f0-9-]{36}|password\s*[:=]|secret\s*[:=]|api[_-]?key\s*[:=]|AKIA[0-9A-Z]{16}"
```
If any line matches → STOP: `BLOCKED — personal data in diff: [matched lines]. Fix before shipping.`

### 3c. ~/.claude project only — README + RENDERED regen
Skip 3c entirely if `IS_CLAUDE_REPO=false`.

**README format check (HARD BLOCK):**
Read `~/.claude/docs/README_FORMAT.md`. Extract every `## ` heading as required.
Read `~/.claude/README.md`. Any missing/renamed heading → STOP: `BLOCKED — README missing required section: [heading].`

**README skill count patch:**
```bash
CUSTOM=$(for d in ~/.claude/skills/*/; do [ -L "${d%/}" ] || echo x; done | wc -l | tr -d ' ')
BORROWED=$(for d in ~/.claude/skills/*/; do [ -L "${d%/}" ] && echo x; done | wc -l | tr -d ' ')
sed -i '' "s/[0-9][0-9]* custom commands/$CUSTOM custom commands/" ~/.claude/README.md
sed -i '' "s/plus [0-9]* borrowed from plugins/plus $BORROWED borrowed from plugins/" ~/.claude/README.md
```

**Regenerate my-skills RENDERED.md:**
```bash
taglines="$HOME/.claude/skills/my-skills/TAGLINES.md"
when="$HOME/.claude/skills/my-skills/WHEN_TO_USE.md"
why="$HOME/.claude/skills/my-skills/WHY_TO_USE.md"
cats="$HOME/.claude/skills/my-skills/CATEGORIES.md"
packs="$HOME/.claude/skills/my-skills/PLUGIN_PACKS.md"
out="$HOME/.claude/skills/my-skills/RENDERED.md"
tmp_rendered=$(mktemp)
{ in_section=0
  while IFS= read -r line; do
    case "$line" in
      "## "*) [ $in_section -eq 1 ] && printf '\n'; printf '%s\n\n' "$line"; printf '| Skill | What it does | When to use | Why vs manual |\n| --- | --- | --- | --- |\n'; in_section=1 ;;
      "") ;;
      *) name="$line"
         story=$(grep "^$name|" "$taglines" 2>/dev/null | cut -d'|' -f2-); [ -z "$story" ] && story="⚠️ missing"
         when_val=$(grep "^$name|" "$when" 2>/dev/null | cut -d'|' -f2-); [ -z "$when_val" ] && when_val="—"
         why_val=$(grep "^$name|" "$why" 2>/dev/null | cut -d'|' -f2-); [ -z "$why_val" ] && why_val="—"
         printf '| %s | %s | %s | %s |\n' "$name" "$story" "$when_val" "$why_val" ;;
    esac
  done < "$cats"
  printf '\n## Plugins\n\n'
  printf '| Pack | What it does | Entry point | Why vs manual |\n| --- | --- | --- | --- |\n'
  while IFS='|' read -r name tagline entry why_val; do printf '| %s | %s | %s | %s |\n' "$name" "$tagline" "$entry" "$why_val"; done < "$packs"
} > "$tmp_rendered"
diff -q "$tmp_rendered" "$out" >/dev/null 2>&1 || { echo "⚠️ RENDERED.md regen differs from committed version — source files (TAGLINES/WHEN_TO_USE/WHY_TO_USE) had drifted:"; diff "$out" "$tmp_rendered"; }
mv "$tmp_rendered" "$out"
```

**Regenerate my-skills RENDERED_FAST.md (paired-column, no headers, default mode):**
```bash
taglines_short="$HOME/.claude/skills/my-skills/TAGLINES_SHORT.md"
out_fast="$HOME/.claude/skills/my-skills/RENDERED_FAST.md"
order_file=$(mktemp)
tmp_fast=$(mktemp)
grep -v "^## \|^$" "$cats" > "$order_file"
{
  printf '| Skill | What it does | Skill | What it does |\n| --- | --- | --- | --- |\n'
  paste -d'\t' - - < "$order_file" | while IFS=$'\t' read -r a b; do
    sa=$(grep "^$a|" "$taglines_short" 2>/dev/null | cut -d'|' -f2-); [ -z "$sa" ] && sa="⚠️ missing"
    if [ -n "$b" ]; then
      sb=$(grep "^$b|" "$taglines_short" 2>/dev/null | cut -d'|' -f2-); [ -z "$sb" ] && sb="⚠️ missing"
      printf '| %s | %s | %s | %s |\n' "$a" "$sa" "$b" "$sb"
    else
      printf '| %s | %s | | |\n' "$a" "$sa"
    fi
  done
} > "$tmp_fast"
diff -q "$tmp_fast" "$out_fast" >/dev/null 2>&1 || { echo "⚠️ RENDERED_FAST.md regen differs from committed version — source files had drifted:"; diff "$out_fast" "$tmp_fast"; }
mv "$tmp_fast" "$out_fast"
rm -f "$order_file"
```
> Every new skill added to `CATEGORIES.md` needs a matching line in `TAGLINES_SHORT.md` (2-5 words) or it renders "⚠️ missing" here.
> Both regen blocks diff against the current file before overwriting and print a warning if source files had drifted — warn-only, still commits either way.

### 3d. Stage
If `IS_CLAUDE_REPO=true`:
```bash
git -C ~/.claude add skills/ *.md docs/ hooks/ setup.sh .gitignore 2>/dev/null
```
Any other project: stage all modified tracked files:
```bash
git -C "$REPO_ROOT" add -u
```

### 3e. Commit
Use `$ARGUMENTS` as commit message if provided. Otherwise auto-generate from changed files.
Always append footer:
```
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

### 3f. Push
If `IS_CLAUDE_REPO=true`:
```bash
git -C ~/.claude push origin main
```
Any other project — push to current tracking branch:
```bash
BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)
git -C "$REPO_ROOT" push origin "$BRANCH"
```

---

## Step 4 — GitHub release (~/.claude project only)

Skip entirely if `IS_CLAUDE_REPO=false`.

## Step 4 — GitHub release

Create a dated release using the changelog entry as notes.

```bash
DATE=$(date +%Y-%m-%d)
TAG="v$DATE"

# If tag already exists (re-running ship same day) — delete and recreate
if git -C ~/.claude tag | grep -q "^$TAG$"; then
  gh release delete "$TAG" --repo holland-built/no-yolo --yes 2>/dev/null || true
  git -C ~/.claude tag -d "$TAG" 2>/dev/null || true
  git -C ~/.claude push origin ":refs/tags/$TAG" 2>/dev/null || true
fi

# Extract today's changelog bullets
BULLETS=$(awk "/^## $DATE/{found=1; next} found && /^## /{exit} found && /^- /{print}" "$HOME/.claude/docs/DAILY_CHANGELOG.md")
BULLET_COUNT=$(echo "$BULLETS" | grep -c "^-" 2>/dev/null || echo 0)
NEW_SKILLS=$(echo "$BULLETS" | grep -oE "added /[a-z-]+" | wc -l | tr -d ' ')

# Build one-sentence summary header
if [ "$NEW_SKILLS" -gt 0 ]; then
  SUMMARY="Added $NEW_SKILLS skill(s), $BULLET_COUNT change(s) total."
else
  SUMMARY="$BULLET_COUNT change(s)."
fi

NOTES="$SUMMARY

$BULLETS"

# Tag and release
git -C ~/.claude tag "$TAG"
git -C ~/.claude push origin "$TAG"
gh release create "$TAG" \
  --repo holland-built/no-yolo \
  --title "$TAG" \
  --notes "$NOTES"

# Update GitHub repo description with current skill count
CUSTOM=$(for d in ~/.claude/skills/*/; do [ -L "${d%/}" ] || echo x; done | wc -l | tr -d ' ')
gh repo edit holland-built/no-yolo \
  --description "Personal Claude Code setup: $CUSTOM skills, memory system, quality gates. Fork to get a working setup instantly." 2>/dev/null || true
```

If `gh` is not installed or not authenticated: print `⚠️ GitHub release skipped — run gh auth login` and continue.

---

## Step 5 — Confirm

Print:
```
Shipped to github.com/holland-built/no-yolo

Committed: [list of files]
Release: [tag] — github.com/holland-built/no-yolo/releases/tag/[tag]
Changelog: [the dated entry just written]
```
