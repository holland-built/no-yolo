# Stage 6: Prove

The metric is the gate. Screenshots and prose are supporting evidence.

## What runs together

The measurement and the words-on-the-page check read the built app and change nothing, so
they run in one call. The critical path joins them only when it is read-only against the
state the measurement reads; a money path that creates an order while the measurement counts
rows makes both answers depend on timing, and in that case the measurement runs first and the
critical path after. "Lock it" runs after all of them have returned, because it stashes the
fix to watch the test go red, and a measurement taken while the fix is stashed describes the
wrong tree.

## Measure it the way you measured it broken

| Kind | Proof |
|---|---|
| Screen | Re-run the stage 0 measurement against the running app. Re-run the stress test; the fix survives it. Capture a screenshot beside it |
| Logic or data | Re-run the stage 0 reproduction and show the observed output now matching expected: the value, the status code, the row count |

"Tests pass" is not this. The same measurement, run again, is.

## Lock it

Turn the success condition into a committed automated test: a browser assertion for a layout
invariant, a unit or integration test for a logic condition.

Confirm it goes red on the pre-fix code where that is feasible: stash the fix, run it, watch
it fail, restore. A regression test never seen failing is a belief, not a guard.

## Exercise the critical path

Run the project's money path end to end and confirm it still works. A change passes its own
test and breaks the path the product exists for.

## Words on the page

A measurement proves the layout holds and a screenshot proves it renders. Neither proves the
text is right.

For a UI change on a routed app, open the routes this run touched, derive what each page
actually says, and compare against the reviewed baseline. Only the routes in this run's diff,
never the whole site. A checker that could not run is a flag, not a pass.

## Where the reasoning goes

The cause, the option rejected, and the before-and-after numbers go in the commit message.
`git blame` finds them there. A separate changelog file duplicating the same words reached
704 lines in a month and was read by nobody.

## Summary

Plain words first, per the `eli5` skill: what changed, what it means, what is next.

Then one technical table, one row per stage that actually ran:

| Stage | What happened | Files | Tests |
|---|---|---|---|

## Memory

Ask once: **"Anything from this run worth saving to memory? Reply with the fact, or skip."**
A fact goes into `memory/facts/` per `docs/MEMORY.md`. `skip` ends it silently.

## Done

This command has finished when the success condition holds against reality, the regression
test is committed and green, the critical path has been exercised, the full suite is green,
and the owner has the plain-words summary.
