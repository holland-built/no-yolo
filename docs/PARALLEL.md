# Running steps at once

Read before running any ordered list of steps: tool calls, bash commands, reads, or agents.

## The Wait Test

Draw the steps. For each one ask: **does this step use the result of the step before it?**

A step that does not is waiting for nothing. Run it alongside, not after. Run the test before
writing any multi-step pipeline, and again whenever a pipeline gets slow.

The rule is symmetric. A genuine dependency stays serial: a review needs the code, a fix needs
the diagnosis, a synthesis needs everything it synthesises.

## Waves

**Wave** is the word for a group of steps that run at once, and it is the only word this setup
uses for it.

Wave 1 is every step that depends on nothing. Each wave after it is every remaining step whose
dependencies all completed in **any** earlier wave, not only the one just before. A step
waiting on steps 2 and 7 joins the first wave that follows both.

A wave goes out as **parallel tool calls in one assistant turn**, which is what makes them
run at once. Several bash commands in one shell invocation still run one after another.

Cap a wave at five agents; beyond that, run it in rounds. Tool calls have no such cap.

## Shared state is a dependency the numbers do not show

Two steps with no data flowing between them still collide when they write the same thing. A
browser has one viewport, so a resize by one step changes what another captures. A performance
measurement taken while something else runs measures the something else. A file two steps both
write ends up with one of them.

Where that happens, the steps are serial, and the file says so once with the reason. Absent a
named reason, independent steps run at once.

## A wave finishes when every step in it has

Four results back out of five is a wave still running, and the next wave waits. Name the step
that did not return and what it leaves unproven.
