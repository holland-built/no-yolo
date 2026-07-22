---
name: checkup
description: Use this skill when the user types /checkup, says 'checkup', 'check up my skills', 'health check my library', or 'is my setup healthy'. One wellness pass (read-only except deterministic regen artifacts) over the ~/.claude skill library — shells to verify.sh, /md-check, /update, /antislop, /skill-audit and the memory lint (never re-implements a check), auto-fixes only deterministic derived output (regen.py), then pauses with one plain-English summary before you pick findings to fix via /plan → approval → subagent build → /release.
user-invocable: true
argument-hint: "(no arguments — one full read-only pass)"
model: opus
allowed-tools:
  - Bash
  - Read
  - Grep
  - Edit
  - Write
  - Task
  - AskUserQuestion
---

## What /checkup is

A thin wrapper. A read-only pass over the skill library, one safe auto-fix, then pause. Every check shells to an existing owner; this skill re-implements nothing.

## Step 0 — Preflight hard rules (run before any check)

- HARD RULE — Repo guard: confirm inside the no-yolo repo via `git rev-parse --show-toplevel` + `git remote -v` (published ~/.claude origin). If not, no-op with ONE line "Not in the ~/.claude repo — /checkup only runs here." and stop.
- HARD RULE — Dirty worktree: run `git status --porcelain` up front, capture the pre-existing dirty set, report it in the summary. The ONLY files /checkup may write are regen artifacts (RENDERED*.md, docs/FLAGS.md) and, in the blessed case, the catalog + catalog-lock.json. Never stage/commit/bury unrelated user edits.
- HARD RULE — Missing dep / no network: any check needing a tool or network degrades gracefully — SKIP with a noted reason in the summary, never crash.
- HARD RULE — Partial-failure isolation: run each check in its own step; one check's error is captured and reported and does NOT abort the rest.
- HARD RULE — Idempotence: re-running makes no new changes; only writes are deterministic (regen) or refused-if-drift (relock).

## Step 1 — Plumbing gates

Run `bash verify.sh` (read-only); parse its PASS/FAIL rows; record FAILs as findings.

## Step 2 — Doc integrity

Run `/md-check --drift` then `/md-check --orphans` (read-only); record findings.

## Step 3 — Behind/ahead + vendored drift

Run bare read-only `/update` (its Step 1 makes no changes). NO invented flag, NO separate stale-external sweep — /update owns behind/ahead + plugin versions + vendored third-party drift. Record findings.

## Step 4 — Prose slop

Run `/antislop` on docs/ + README prose; diagnosis only; record findings.

## Step 5 — Skill-library dimensions

Run `/skill-audit`. DISCLOSE in the summary that this writes a dated report under brainstorms/ (gitignored) — an allowed private-artifact mutation, not silent.

## Step 6 — Memory lint

Run `python3 memory/bin/memory_compile.py`, read its lint output; record findings.

## Step 7 — learnings.md staleness probe (read-only)

Check whether learnings.md has a section for the current model ID; if stale, surface a finding recommending an opt-in `/prompt-scan`. HARD RULE — do NOT auto-run /prompt-scan (fetches web + rewrites learnings.md); separately-approved refresh only.

## Step 8 — Safe auto-fix (the ONLY unattended write)

Run `python3 skills/my-skills/regen.py` ONLY if a catalog change /checkup itself made requires it (pure health pass = confirmation no-op). HARD RULE — relock is blessing-only: `python3 skills/my-skills/catalog_lock.py --relock` runs ONLY to bless a catalog change /checkup itself caused; it REFUSES if there is unreviewed pre-existing catalog drift → surface that drift as a FINDING, do not relock.

## Step 9 — Pause + one plain summary (eli5 style)

Output follows the eli5 plain-short style: ONE plain sentence for a single item; a SMALL chart only when listing multiple findings; no jargon; no mandatory "why" column. Disclose the regen auto-fix that ran, the skill-audit private report, any skipped checks + reasons, the pre-existing dirty set. Then STOP.

## Step 10 — Staged gate (never a blanket OK)

User first SELECTS which findings to act on; run `/plan` on those; the resulting plan gets its OWN approval before any edit; then build via subagents (Task → Sonnet); then `/release` (keeps its own public-push gate). /checkup never pushes blind.
