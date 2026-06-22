---
name: md-check
description: MD hygiene audit — line-count, topic-overlap, duplicate-rule detection, and --drift mode to catch stale CLAUDE.md skill descriptions vs SKILL.md source of truth. On-demand audit, pre-creation gate, or drift check. Activate on "/md-check", "check md files", "md hygiene", "check for duplicate docs".
user-invocable: true
argument-hint: "[--pre <proposed-filename>] [--drift] (omit for full audit)"
model: haiku
allowed-tools:
  - Bash
  - Read
  - Grep
---

Mode: $ARGUMENTS

If `$ARGUMENTS` starts with `--pre` → run Pre-creation mode.
If `$ARGUMENTS` is `--drift` → run Drift Check mode.
Otherwise → run On-demand audit.

---

## On-demand Audit Mode (`/md-check`)

### Step 1 — Inventory
```bash
{ find "$HOME/.claude" -maxdepth 1 -name "*.md"; find "$HOME/.claude/docs" -maxdepth 1 -name "*.md" 2>/dev/null; } | sort | xargs wc -l 2>/dev/null
```
Flag any file over 200 lines as `OVERSIZE`.

### Step 2 — Header Map
For each MD file, extract section headers:
```bash
grep -nE "^#{1,3} " <file>
```
Build a per-file header list.

### Step 3 — Topic Overlap Detection
For each file, extract top-20 frequent non-stopword tokens (4+ chars):
```bash
grep -oE '\b\w{4,}\b' <file> | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -rn | head -20
```
For each file pair: overlap % = |intersection of top-20 term sets| / |smaller set|.
- `>40%` overlap → flag as merge candidate
- Shared section header (exact match) → counts double, flag immediately

Exclude: `node_modules/`, `plugins/`, `brainstorms/`

### Step 4 — Duplicate Rule Detection
Normalize each bullet/numbered line: lowercase, strip markdown punctuation.
Find near-identical lines (>80% token match) appearing in 2+ files.
Report as: `"<rule text>" → found in <file1>:line + <file2>:line`

### Step 5 — Output Tables

**File inventory:**
| File | Lines | Status | Note |
|------|-------|--------|------|
| CLAUDE.md | 110 | OK | |
| README.md | 391 | OVERSIZE | trim needed |
| CODE_REVIEW.md | 25 | DUP-RULE | → CORE_RULES.md:3 |

Status vocab: `OK` / `OVERSIZE` (>200 lines) / `DUP-RULE` / `OVERLAP`

**Merge candidates:**
| File A | File B | Overlap % | Shared headers |
|--------|--------|-----------|----------------|

**Duplicate rules:**
| Rule text (truncated) | File A:line | File B:line |
|-----------------------|-------------|-------------|

No merge candidates or duplicate rules → print: `✓ No overlaps or duplicates found.`

---

## Drift Check Mode (`/md-check --drift`)

Checks that every skill description in CLAUDE.md accurately matches the source-of-truth in its SKILL.md.

### Step 1 — Extract skill blocks from CLAUDE.md
```bash
grep -E "^\- \*\*[a-z]" ~/.claude/CLAUDE.md
```
For each line matching `- **skill-name** (path/to/SKILL.md) - description text`, parse:
- skill name (between `**`)
- SKILL.md path (between `(` and `)`)
- description text (after the final ` - `)

Skip blocks that have no description (pointer-only blocks like impeccable after cleanup).

### Step 2 — Read each SKILL.md frontmatter description
For each skill with a resolvable path, read the `description:` field from SKILL.md frontmatter using the Read tool.

### Step 3 — LLM judge per skill
For each skill, compare the CLAUDE.md description against the SKILL.md `description` field.
Verdict rules:
- `OK` — CLAUDE.md description is accurate, even if shorter/more terse
- `DRIFT` — CLAUDE.md omits a key behavior, contradicts SKILL.md, or describes a removed feature
- `WRONG` — CLAUDE.md description is factually incorrect (opposite of what SKILL.md says)

One-line reason required for any non-OK verdict.

### Step 4 — Output table
```
| Skill | CLAUDE.md says | SKILL.md says | Verdict |
|-------|----------------|---------------|---------|
```
- Only include rows with DRIFT or WRONG verdicts — skip OK rows to keep output tight
- If all OK: print `✓ No drift detected.`
- Count: `X skills checked, Y drifted`

---

## Pre-creation Mode (`/md-check --pre <filename>`)

Called by other skills before writing a new MD file. Checks if the proposed topic already exists.

Input: `--pre <proposed-filename>` (e.g. `--pre ANTISLOP.md`)

Steps:
1. Run the header map (Step 2 above) across all existing `~/.claude/*.md`
2. Extract the proposed filename stem (e.g. `antislop`) and compare against existing headers and filenames (case-insensitive, fuzzy: strip hyphens/underscores)
3. Check proposed content if piped via stdin: compute term overlap against existing files

Output — exactly one verdict line:
- `PROCEED` — no significant overlap found
- `MERGE-INTO-EXISTING: <path> — <reason>` — topic already covered, add to this file instead
- `DUPLICATE-DETECTED: <path>#<section> — <reason>` — content duplicates an existing section

Then one line of reasoning, e.g.:
`MERGE-INTO-EXISTING: ~/.claude/docs/UI_MOCKUPS.md — "antislop" maps to existing "Slop fingerprint" section (header match)`

---

## Notes
- Exclude `brainstorms/` and `plugins/` from all scans — they are ephemeral/external
- All paths absolute in output
- Restart session required to apply changes to CLAUDE.md or other loaded MDs (no hot-reload)
