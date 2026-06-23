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
2. Run it → confirm it fails (red)
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
