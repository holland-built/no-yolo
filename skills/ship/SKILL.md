---
name: ship
description: Quality-gated publish to github.com/holland-built/no-yolo. Runs md-check + antislop + eli5 + drift-check warnings, validates README structure (hard block), writes a dated changelog entry, then guards against personal-data leaks and pushes. Activate on "/ship", "push skills", "publish to no-yolo", "ship my work".
user-invocable: true
argument-hint: "[optional commit message]"
allowed-tools:
  - Bash
  - Read
---

# ship

Quality-gate, changelog, then publish `~/.claude` to `github.com/holland-built/no-yolo`.

---

## Step 0 — What changed

```bash
git -C ~/.claude status --short
```

If clean: print "Nothing to ship. Working tree clean." and STOP.

---

## Phase 1 — Quality gates (WARN ONLY — never block)

### 1a. Size check
```bash
wc -l ~/.claude/*.md ~/.claude/docs/*.md ~/.claude/skills/*/SKILL.md 2>/dev/null | sort -rn | head -20
```
Table any file with >200 lines: `| File | Lines |`. Print warning. Do NOT stop.

### 1b. Antislop scan
Read `~/.claude/docs/ANTISLOP.md` — extract all bullets under `## Writing Tells (25)`.
Scan `~/.claude/README.md` and `~/.claude/CLAUDE.md` for tell matches.
If violations found: print `| File | Tell | Excerpt |` table. Do NOT stop.

### 1c. eli5 check
Read `~/.claude/README.md`. For each `##` section heading: does the first sentence use unexplained jargon or acronyms?
Flag any in a one-line table: `| Section | Jargon |`. Do NOT stop.

### 1d. Drift check
Invoke `md-check --drift` via the Skill tool. For any DRIFT or WRONG verdicts: print the full drift table as a warning. Do NOT stop.

### 1e. GLOBAL_DESCRIPTIONS coverage check
```bash
descs="$HOME/.claude/skills/my-md/GLOBAL_DESCRIPTIONS.md"
{ find "$HOME/.claude" -maxdepth 1 -name "*.md"; find "$HOME/.claude/docs" -maxdepth 1 -name "*.md" 2>/dev/null; } | sort | while IFS= read -r f; do
  name=$(basename "$f")
  grep -q "^$name|" "$descs" 2>/dev/null || echo "MISSING: $name"
done
```
If any `MISSING:` lines → print warning table `| File | Status |` with each missing file. Do NOT stop.

---

## Phase 2 — Changelog

Run:
```bash
git -C ~/.claude diff HEAD --stat
git -C ~/.claude diff HEAD --name-only
```

Append to `~/.claude/docs/DAILY_CHANGELOG.md` (create file if missing):

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

### 3a. Personal-file guard (HARD BLOCK)
If any changed path matches these → STOP, do not commit:
`memory/facts/` `brainstorms/` `plans/` `proposals/` `projects/` `sessions/` `settings.json` `settings.local.json` `history.jsonl` `*.log` `cache/` `paste-cache/`

Output: `BLOCKED — personal files in diff: [list them]. Fix before shipping.`

### 3b. Content scan (HARD BLOCK)
```bash
git -C ~/.claude diff HEAD | grep -E "^\+" | grep -vE "^\+\+\+" | grep -E \
  "/Users/[a-zA-Z0-9_-]+|provenance:|session: [a-f0-9-]{36}|password\s*[:=]|secret\s*[:=]|api[_-]?key\s*[:=]|AKIA[0-9A-Z]{16}"
```
If any line matches → STOP: `BLOCKED — personal data in diff: [matched lines]. Fix before shipping.`

### 3c. README format check (HARD BLOCK)
Read `~/.claude/docs/README_FORMAT.md`. Extract every line that starts with `## ` as a required section heading.
Read `~/.claude/README.md`. For each required heading, check it appears verbatim in README.md.
If any required heading is missing or renamed → STOP: `BLOCKED — README missing required section: [heading]. Fix README or update README_FORMAT.md before shipping.`

### 3d. Stage
```bash
git -C ~/.claude add skills/ *.md docs/ hooks/ setup.sh .gitignore 2>/dev/null
```

### 3e. Commit
Use `$ARGUMENTS` as commit message if provided. Otherwise auto-generate:
- Format: `[verb] [skill names]: [one-line description]`
- Examples: `add /ship, /antislop, /prompt-scan: quality-gated publish + slop detection`

Always append footer:
```
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

### 3f. Push
```bash
git -C ~/.claude push origin main
```

---

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

# Extract today's section from DAILY_CHANGELOG.md as release notes
NOTES=$(awk "/^## $DATE/{found=1; next} found && /^## /{exit} found{print}" "$HOME/.claude/docs/DAILY_CHANGELOG.md")

# Tag and release
git -C ~/.claude tag "$TAG"
git -C ~/.claude push origin "$TAG"
gh release create "$TAG" \
  --repo holland-built/no-yolo \
  --title "$TAG" \
  --notes "$NOTES"
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
