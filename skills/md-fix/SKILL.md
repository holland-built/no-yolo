---
name: md-fix
description: Use this skill when the user types /md-fix, says 'fix my md files', 'dedupe my docs', 'organize my markdown', or 'clean up my docs'. Runs the md-check audit, then proposes and — after one approve-all gate — APPLIES the fixes: dedupe duplicate rules, merge overlapping files, trim oversize files, fix description drift. The active counterpart to read-only /md-check.
user-invocable: true
argument-hint: "[--auto to skip the approval gate]"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# md-fix

`/md-check` REPORTS problems. `/md-fix` FIXES them. Flow: audit → propose fix table → one approve-all gate → apply → verify.

Runs against `~/.claude/*.md` + `~/.claude/docs/*.md` (same scope as md-check).

## Step 1 — Audit

Invoke `/md-check` (on-demand mode) and `/md-check --drift`. Collect every finding:
- **OVERSIZE** — files >200 lines
- **Merge candidates** — file pairs with >40% term overlap or a shared section header
- **Duplicate rules** — near-identical bullets in 2+ files
- **Drift** — CLAUDE.md skill descriptions that no longer match their SKILL.md source

If the audit is fully clean → print `✓ Nothing to fix — all MD files healthy.` and STOP.

## Step 2 — Build the fix plan

One row per finding. Each fix is concrete and names exactly what changes:

| # | Target | Problem | Fix | Kind |
|---|--------|---------|-----|------|

Fix `Kind` vocab:
- **DEDUPE** — delete the duplicate line(s); keep the canonical copy (name which file:line stays)
- **MERGE** — fold the smaller file's unique content into the larger, delete the smaller (only when overlap >40%)
- **TRIM** — an OVERSIZE file: propose what moves out and where (a new doc, or an existing one). Append-only logs (DAILY_CHANGELOG.md, learnings.md §6) are exempt — do NOT trim them.
- **DRIFT-FIX** — rewrite the CLAUDE.md description line to match its SKILL.md `description` frontmatter

## Step 3 — Approve-all gate

Skip this step entirely if `$ARGUMENTS` contains `--auto`.

Print the fix table, then one line: `Reply "go" to apply all, or list the # to skip.` Wait for the reply. This is a mutation gate (many files edited at once), not a clarifying question — the single gate is the only pause.

## Step 4 — Apply

Apply each approved fix with Edit/Write.

**Personal-file guard (HARD — never edit these):** `memory/` `brainstorms/` `plans/` `proposals/` `projects/` `sessions/` `settings.json` `settings.local.json`. If a fix would touch one, skip it and note why.

Never delete a file you did not just read in this run.

## Step 5 — Verify + report

Re-run the Step 1 audit. Report before/after:

| Metric | Before | After |
|--------|--------|-------|
| Files >200 lines | | |
| Duplicate rules | | |
| Drifted descriptions | | |

Then a table of what changed (file, action). End with `✅ Fixed N findings across M files` or the `--auto` equivalent.

> Changes to `CLAUDE.md` or other loaded MDs need a session restart to take effect (no hot-reload). Note this if any were edited.
