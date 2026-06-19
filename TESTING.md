# Testing Discipline

## TDD Default (Karpathy Rule 4 in practice)

For any bug fix or new feature:
1. Write a failing test that reproduces the bug or specifies the feature.
2. Run it, confirm it fails for the right reason.
3. Write the minimum code to pass.
4. Refactor only if tests still pass.

### Goal-Driven Restatement (Rule 4)

Restate every vague instruction as a verifiable goal before acting:

| Instruction | Goal-driven restatement |
|---|---|
| "Fix the bug" | Write a test that reproduces it, then make it pass |
| "Add validation" | Write tests for invalid inputs, then make them pass |
| "Refactor X" | Ensure tests pass before and after |

For multi-step work, append a per-step verification to each step: `[Step] → verify: [check]`.

Use skill: `/tdd`.

## Stack-Specific Commands

Project test/lint commands live in the project's `ARCHITECTURE.md` or `CLAUDE.md` — not here. Detect them at session start from `package.json` scripts, `README`, or project skill.

## UI Verification (Mandatory for any frontend change)

**Before coding any GUI/UI change:** see `~/.claude/UI_MOCKUPS.md`. 5–8 mockup variations required before production code.

After production code:
1. Ensure dev server running (use the project's documented dev command — see project `CLAUDE.md` or `ARCHITECTURE.md`).
2. Load page via `preview_start` / reload via `preview_eval`.
3. Check `preview_console_logs` for errors.
4. `preview_snapshot` to verify content/structure.
5. `preview_screenshot` only for visual changes (heavier).
6. For interactions: `preview_click` / `preview_fill` then re-snapshot.

**Never claim "done" on a UI change without browser-level verification.**

Use skill: `/forge` (phase 6 — prove).

## When to skip TDD

Trivial typo fixes, single-line renames, comment edits. Everything else: TDD.
