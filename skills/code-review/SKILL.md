---
name: code-review
description: Three-pass diff review — correctness/bugs, over-engineering (ponytail-review), Karpathy surgical+simplicity filters. Applies CODE_REVIEW.md on every run. Pass --fix to apply findings, --comment to post as inline PR comments. Effort: low/medium = fewer high-confidence findings; high/max = broader coverage.
user-invocable: true
argument-hint: "[--fix] [--comment] [--effort low|medium|high|max]"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Grep
  - Glob
  - Agent
---

Arguments: $ARGUMENTS

## Phase 0 — Load Review Discipline

Read `~/.claude/CODE_REVIEW.md` before doing anything else. These are the active filters for this review.

## Phase 1 — Get the Diff

```bash
git diff $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null || echo "HEAD~1") HEAD
```

If no branch divergence found, diff against `HEAD~1`. Save the diff — all three passes use it.

## Phase 2 — Three Passes (run in parallel)

### Pass A — Correctness & Reuse

Review the diff for:
- Correctness bugs — logic errors, off-by-ones, null/undefined, wrong conditionals
- Reuse — existing function/component already does this?
- Security — auth, input validation, secrets in diff

### Pass B — Over-Engineering

Invoke `ponytail-review` skill via the Skill tool, passing the diff as context.
Captures: what to delete, reinvented stdlib, unneeded deps, speculative abstractions.

### Pass C — Karpathy Filters (from CODE_REVIEW.md)

- **Surgical** — every changed line traces to the stated request; flag any that don't
- **Simplicity** — would a senior engineer say this is overcomplicated?

## Phase 3 — Merge & Output

Combine all findings from A + B + C into one table, deduplicated:

```
path:line: <emoji> <severity>: <problem>. <fix>.
```

Severity + emoji:
- 🔴 Critical — breaks correctness or security; fix immediately
- 🟠 Important — fix before proceeding
- 🟡 Minor — log for later
- 🔵 Scope — line not traced to request (surgical violation)
- ⚪ Simplicity — senior engineer would simplify this
- 🟣 Complexity — over-engineered, delete or shrink (ponytail)

No praise. No summary prose. Findings only. Sort by severity (Critical first).

## Phase 4 — If `--fix` passed

Apply all Critical + Important findings to the working tree. Show a table:

| File | Line | Finding | Applied |
|---|---|---|---|

## Phase 5 — If `--comment` passed

Post each finding as an inline PR comment:
```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments ...
```

Detect owner/repo from `git remote get-url origin`. Detect PR number via `gh pr view --json number`.
