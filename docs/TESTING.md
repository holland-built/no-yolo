# Testing

Read before writing code for a fix or a feature.

Adapted from `mattpocock/skills` → `tdd` and `diagnosing-bugs`.

## The loop

One behaviour at a time, all the way through, before starting the next:

```
1. Write ONE failing test for the smallest useful behaviour
2. Run it. Watch it go red for the reason you intended
3. Write the least code that turns it green
4. Run it. Confirm green
5. Tidy, staying green
6. Next behaviour
```

Finishing every test before any code verifies imagined behaviour and produces a wall of red
that reports nothing until the end. One slice at a time keeps the feedback tight.

## Red means you watched it fail

A test you wrote and never ran has an unknown colour. Run it and read the failure. It goes
red because the behaviour is absent, not because of an import error, a typo, a wrong fixture
path, or a stale mock. A test that passes the first time asserts something already true:
fix the test before writing any implementation.

## Expected values are written by hand

`expect(total).toBe(17.5)`. A literal you worked out yourself.

An assertion that recomputes the expected value with the same logic as the code under test
passes whatever the code does, wrong included. The same goes for asserting against the
implementation's own output, against a helper both sides call, or against a snapshot you
just regenerated to make it green.

When you cannot state the expected value without running the code, work the behaviour out
first.

## Scope while iterating

Run the one file or pattern you are working on. Save the full suite for the gate.

Golden-master and snapshot suites are regression guards: leave them untouched and put new
behaviour in its own file beside the module.

## When a test fails and you do not know why

Stop writing tests. A red test you cannot explain is worth more as a diagnostic than as a
TODO. Go to the loop below.

## Diagnosing

### 1. Build the fastest reliable way to observe it

Ranked by how tight the loop is:

| Rank | Loop |
|---|---|
| 1 | A failing test that runs in under 5 seconds |
| 2 | A short script that triggers it |
| 3 | One curl or API call showing the wrong behaviour |
| 4 | Dev server plus browser |
| 5 | Grep the error in existing logs |

State it before going on: `Loop: <command> -> reproduces, output: <output>`.

### 2. Shrink it

Strip everything not load-bearing: unrelated code paths, config, environment variables.
Bisect when it appeared recently (`git bisect start && git bisect bad && git bisect good
<hash>`). Narrow to one file, one function, one call.

### 3. Guess, then kill the guesses

Three to five distinct explanations. For each: what would have to be true, what evidence
already speaks to it, and the single observation that would eliminate it.

### 4. Instrument

Add observation without changing behaviour: values at branch points, assertions that should
always hold, config and state at the failure point, request and response headers for network
bugs, `typeof` and `.constructor.name` for type errors.

Run the loop. Eliminate. Repeat until one explanation survives.

### 5. Fix the cause, in the fewest lines

State the cause in one sentence before writing anything.

### 6. Lock it

Write the test that would have caught it. Run it against the broken version and watch it
fail. Run it against the fix and watch it pass. Commit it with the fix.

Stuck at any point: go back to step 1 and make the loop tighter.

## Done

A build run's completion contract lives in `skills/build/stages/6-prove.md`. Work outside a
build run borrows the same shape: measure the success condition the way it was measured
before, and commit the regression test that goes red without the fix.
