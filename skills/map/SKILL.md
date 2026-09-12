---
name: map
description: Chart a piece of work too big for one session as a map of decisions in MAP.md, then settle them one at a time until the way forward is clear. Use when Sholland has a large or foggy idea and it is not yet clear what building it even involves.
---

# map

Something big has arrived and the way to it is not visible yet. Find the way. Do not charge
at the destination.

## The constraints

**This is planning, not building.** Every item on the map is a question whose answer is a
decision, not a slice of work to execute. When you feel the pull to just build it, that is
the signal the map is finished and it is time to hand off to `/build`.

**The map is one file: `MAP.md` in the project folder.** No issue tracker — Sholland works
alone and does not keep one. The map is an index: it names the destination, lists the
decisions already settled in one line each, and holds the open questions. Detail lives with
the question it belongs to, written once.

**Name the destination first.** One or two lines saying what reaching the end looks like — a
spec to hand to `/build`, a decision to lock before anything starts, a change to make in
place. Every session re-reads it before picking up a question. It shapes everything else, so
getting it wrong is expensive and getting it vague is worse.

**One question at a time, and only ones that are answerable now.** A question that depends on
another open question waits. Settling one usually reveals two more — that is the map working,
not the map failing.

**Settle a question by grilling it, not by deciding it for him.** Use `/grill` on the open
question: numbered, with your recommendation on each. Write the answer into `MAP.md` as one
line, and move the detail under the question it settled.

**Record what is out of scope, and never revisit it.** Also record the fog — the parts you
can see are in scope but cannot ask about yet. Fog becomes questions as the map advances;
out-of-scope stays closed.

## What MAP.md holds

```markdown
# Map: <name of the effort>

## Destination
<what the end looks like, one or two lines>

## Settled
- <question>: <the answer, one line>

## Open
- <question, and why it cannot be answered until the ones above it are>

## Fog
<in scope, visible, not yet askable>

## Out of scope
<ruled out, with the reason, permanently>
```

**Settled is an index, not a transcript.** One line per decision — the question and the
answer, nothing else. The reasoning lives in the session that produced it, not here. If
Settled passes about thirty lines, the map is finished or it was scoped too wide; say which,
rather than letting the file grow past what one session will read.

## Done

Done is nothing left to decide before someone goes and does the thing — the Open list empty
and the Fog cleared or moved out of scope. Say so, and hand the map to `/build`.

A session that cannot get there says where it stopped and what it was waiting on. `MAP.md`
is the handoff; the next session should need nothing else.
