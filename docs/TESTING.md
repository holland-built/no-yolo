# Testing Discipline

## TDD (Test-Driven Development — write the test before the code) Default

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

## A Check Must Prove It Can Fail

A verifier that cannot go red is decoration, and worse than none — it reads as evidence while checking nothing. Three shipped this way in `~/.claude` before anyone noticed: `md-check --drift` grepped a file whose format had moved (always "no drift"), `skill-audit` echoed its report path instead of writing it, and `hooks/tests/*.test.sh` was executed by nothing.

So: **never trust a green you haven't seen go red.** For every check, feed it one input that must pass and one that must fail, and confirm it says so. `verify-selftest.sh` does this for `verify.sh` — it sabotages each check in turn, asserts the FAIL appears, and restores. Run it whenever you add or edit a check.

The same trap catches a *false red*: scope a grep wrong and it reports a problem that isn't there. Both directions come from never testing the check against a known answer.

## Stack-Specific Commands

Project test/lint commands live in the project's `ARCHITECTURE.md` or `CLAUDE.md` — not here. Detect them at session start from `package.json` scripts, `README`, or project skill.

## UI Verification (Mandatory for any frontend change)

**Before coding any GUI/UI change:** see `~/.claude/docs/UI_MOCKUPS.md` for how many mockups to make before production code.

After writing production code: start the dev server, open the page in a browser, and confirm it works as expected before claiming done.

**Never claim "done" on a UI change without browser-level verification.**

Use skill: `/build` (phase 6 — prove).

## When to skip TDD

Trivial typo fixes, single-line renames, comment edits. Everything else: TDD.
