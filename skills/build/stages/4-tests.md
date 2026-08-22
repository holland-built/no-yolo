# Stage 4: Tests

The loop, what makes a test worthless, and how to agree the seam all live in
`docs/TESTING.md`. Read that file. This one covers only what is specific to a build run.

## What this stage produces

The agreed seam, and one failing test that proves the seam works as a test surface.

The red-green loop itself belongs to stage 5, where the code is written. Writing every test
here first would produce a wall of red that reports nothing until the end, and would put
implementation in a stage that has none.

**Agree the seam before the test.** Name where you will test (the public function, the HTTP
boundary, the database adapter) and what you will fake. Get a yes on that. Tests are the
hardest part of a diff to relocate later, so their level is the owner's call, and their
answer wins. When the `codebase-design` skill is installed, put the question in its
seam-and-adapter vocabulary; absent it, name the place and the fake in plain words.

When stage 3 runs, draft the seam question while the mockups are being judged, and put it to
the owner in the same turn as the variant gate when the seam does not turn on which variant
wins (a function or HTTP boundary usually does not; a browser assertion on a layout does).
Two gates asked one after the other cost the owner two waits for one decision's worth of
input. The first failing test is written after the answer, beside the sourcing table.

Then write one test for the first behaviour in the plan, run it, and read the failure. It
goes red because the behaviour is absent, not because of an import error, a typo, or a stale
fixture. `docs/TESTING.md` carries the full rules on what makes a test worthless.

## Where new tests go

Beside the module, in their own file. Golden-master and snapshot suites are regression
guards and stay untouched: a suite edited to make a build pass has stopped guarding anything.

## Codex's edge cases

The background job launched at plan approval is read here. It received the spec and the
public interface, never the implementation, so its tests carry different assumptions from the
author's.

```bash
cat .xcheck/<slug>-tests.out
```

Read each returned test. Drop any that misread the spec. Adapt the rest to the project's
conventions and run them.

| Result | Meaning |
|---|---|
| Fails | A real finding. Fix it in stage 5 |
| Passes, covers a genuine gap | Keep it in the suite |
| Passes, duplicates an existing test | Drop it |

Empty file, or `codex` absent: record "Codex tests: did not run" and continue. A missing
second opinion is not a defect.

Delete the temporary files when the stage ends.

## Done

This stage has finished when the owner has agreed the seam, one test for the first planned
behaviour was watched failing for the intended reason, and Codex's returned tests have each
been kept, adapted, or dropped with a reason.

Stage 5 carries the remaining behaviours through the red-green loop, one slice at a time.
