# When a session runs long

Read when context is filling, or when a session has been going for hours.

## The signal

Context fills fastest on file reads and tool output, not on conversation. A session that has
read a dozen large files is closer to the edge than one that has talked for an hour.

Watch for the shape rather than the number: repeating a search you already ran, re-reading a
file you already have, or losing track of which decision was settled. Those are the symptoms
of a window under pressure.

## Spend it well

| Instead of | Do |
|---|---|
| Reading a whole file to answer one question | Grep for the symbol, read the region |
| Dumping tool output into the reply | State the conclusion and the command |
| Reading every sibling doc | Read the one whose condition fired |
| Keeping a long search in this context | Dispatch it and take the conclusion back |

A subagent's value here is that its reading stays in its own window. You get the answer, not
the files.

## Stop at a boundary

A stage boundary is the cheapest place to stop: the work in front of you is finished, the
work behind it has not started, and the state is describable in a paragraph.

When a session is long and a boundary arrives, name the stage that just finished and the one
next, and offer the handoff. A handoff written at a boundary survives; one written mid-stage
carries a half-finished thought nobody can resume.

## What a handoff carries

The `/handoff` command writes it. The ordering matters more than the content:

1. **The goal, in the owner's own words**, quoted. First thing written, first thing read.
2. What was decided, and what is still open.
3. What was tried and did not work, so the next session skips it.
4. The single first action to take on resume.

The goal goes first because it is the part that gets lost. A handoff that carries every
technical detail and loses the goal sends the next session confidently in the wrong
direction for a day.

## Resuming

State the goal and the first action back in one line, then wait. A resumed session that
starts working before confirming it read the right file has guessed.
