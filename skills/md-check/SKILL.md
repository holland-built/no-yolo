---
name: md-check
description: MD hygiene audit — line-count, topic-overlap, and duplicate-rule detection across ~/.claude/ markdown files. On-demand full audit or pre-creation gate before writing a new MD. Activate on "/md-check", "check md files", "md hygiene", "check for duplicate docs".
user-invocable: true
argument-hint: "[--pre <proposed-filename>] (omit for full audit)"
allowed-tools:
  - Bash
  - Read
  - Grep
---

Mode: $ARGUMENTS

If `$ARGUMENTS` starts with `--pre` → run Pre-creation mode. Otherwise → run On-demand audit.

---

## On-demand Audit Mode (`/md-check`)

### Step 1 — Inventory
```bash
find "$HOME/.claude" -maxdepth 1 -name "*.md" | sort | xargs wc -l 2>/dev/null
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
`MERGE-INTO-EXISTING: ~/.claude/UI_MOCKUPS.md — "antislop" maps to existing "Slop fingerprint" section (header match)`

---

## Notes
- Exclude `brainstorms/` and `plugins/` from all scans — they are ephemeral/external
- All paths absolute in output
- Restart session required to apply changes to CLAUDE.md or other loaded MDs (no hot-reload)
