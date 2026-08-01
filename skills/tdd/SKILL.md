---
name: tdd
description: Use this skill when the user types /tdd, says 'write tests first', 'TDD this', 'test-driven', or 'implement with tests'. Vertical-slice TDD — one test → one implementation → one green bar → repeat. Forbids all-tests-first horizontal slicing.
user-invocable: true
argument-hint: "[describe the feature or function to implement]"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
---

Implement using vertical-slice TDD. Target: $ARGUMENTS

## The rule

**Do NOT write all tests first, then all code.** That is horizontal slicing — it verifies imagined behavior and produces a wall of red that gives no feedback until everything is done.

**Do this instead — one vertical slice at a time:**

```
1. Write ONE failing test for the smallest useful behavior
2. Run it → confirm it fails, for the reason you intended (red)
3. Write the minimum code to make it pass
4. Run it → confirm it passes (green)
5. Refactor if needed (keep green)
6. Repeat from 1 for the next behavior
```

Each slice = one test + one implementation + one green bar.

---

## Before writing any test

1. Read the target file(s) — understand what already exists
2. Identify the smallest useful behavior to test first (the "tracer bullet")
3. State it in one sentence: "Given X, when Y, then Z"
4. **Agree the seams first.** Name where you will test — the public function, the HTTP boundary, the DB adapter — and what you will fake, then stop and get the user's OK before writing a single test. Tests are the hardest thing in the diff to move later; picking the seam alone means rewriting them when the user wanted a different level. If they name a different seam, use theirs.

---

## Two ways a test can be worthless

**Tautological test — banned.** If the assertion recomputes the expected value using the same logic as the code under test, it passes no matter what the code does, including wrong. Expected values are written by hand as literals: `expect(total).toBe(17.5)`, never `expect(total).toBe(price * qty * (1 + rate))`. Same ban on asserting against the implementation's own output, a shared helper both sides call, or a snapshot you just regenerated to make it pass. If you can't state the expected value without running the code, you don't yet understand the behavior — go work that out first.

**Unvalidated red — doesn't count.** A test you wrote but never executed is not RED, it's unknown. Run it and read the failure. It must fail *because the behavior is missing* — not on an import error, typo, wrong fixture path, or bad mock setup. A green-on-first-run test is a bug in the test: it's asserting something already true, so fix the test before writing any implementation.

---

## Running tests

Use the project's documented test command (from `package.json` scripts, `Makefile`, project `CLAUDE.md`, or `ARCHITECTURE.md`). Run only the relevant test file or pattern while iterating — not the whole suite.

**Golden-master / snapshot suites:** if the project has one, treat it as a regression guard, NOT a TDD target. Do not add new vertical slices into it. Write new behavior tests in a separate test file alongside the module under test.

---

## When a test fails unexpectedly

Stop. Don't write more tests. Use `/diagnose` — build the feedback loop, then fix the root cause. A red test you don't understand is more valuable as a diagnostic tool than as a TODO.

---

## Done when

Every behavior specified in $ARGUMENTS has a passing test. No test verifies behavior that wasn't requested. The diff contains only the new test file + the implementation — nothing else.
