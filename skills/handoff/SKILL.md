---
name: handoff
description: Use when the owner types /handoff, says "hand this off", "save where we are", "I'm about to run out", "pick this up later", "write a handoff", or "I'm hitting the limit". Writes the session to a file a fresh session can resume from, and prints one command to start that session.
user-invocable: true
model: opus
effort: high
allowed-tools: [Bash, Read, Write, Grep, Glob]
---

# handoff

A handoff carries one thing above all others: **what the owner is trying to achieve, in
their own words.** Everything else is support.

A handoff that captured every technical detail and lost the goal sent a session confidently
in the wrong direction for a full day. That is the failure this command exists to prevent,
so the goal is written first and read first.

## 1. Find the goal

Scroll back to the owner's own words. Quote the sentence where they said what they wanted,
verbatim, including the messy phrasing. A tidied paraphrase drifts; the raw quote does not.

Several goals in one session: quote the one that outranks the others and say why. Goals that
changed mid-session: quote the current one and note what it replaced.

## 2. Pick where it lives

Default `~/.claude/handoffs/<date>-<slug>.md`.

Work that would delete or move the default location writes to `~/Desktop/` instead, and says
so in the file. A handoff inside the folder being deleted dies with it.

## 3. Write it, in this order

The ordering is the design. Anything below section 2 can be skimmed; the first two cannot.

```markdown
# <one line: what this session was for>

## The goal, in the owner's own words

> "<verbatim quote>"

| Part | What it means here |
|---|---|
| Outcome | <what exists when this is finished> |
| Approach | <how the owner wants it done, including anything they ruled out> |
| Done looks like | <the checkable condition> |

**This section outranks everything below it.**

## First action on resume

<One action. A command to run, or a file to read. Under two minutes.>

State the goal and this first action back in one line, then wait for a yes.

## Where we got to

| Piece | State |
|---|---|

## Decided in conversation, written nowhere else

<Each decision, with the reason. These are the ones no file records.>

## Tried and rejected

<What was attempted and why it failed, so the next session skips it.>

## Open, needs a decision

<Numbered. Each one names who decides and what turns on it.>

## What can run at once

| Group | Steps | Waits on |
|---|---|---|
| A | <steps that start immediately> | nothing |
| B | <steps that need A's result> | A |
```

## 4. Run the Wait Test on what remains

Map the remaining work as a graph: each step a node, each hand-off between steps an edge.

Then run the Wait Test on every step: **does this step actually need the result of the one
before it?** A step that merely follows in the order someone happened to write it is not
blocked, it is queued.

Flag every step waiting on something it does not need. Those go in the same group and start
together.

Two exceptions, both learned by watching them bite:

- **Same file, same time.** Two steps that need nothing from each other still collide when
  they edit one file. They are sequential for that reason alone, and the group table says so.
- **Same tree, same time.** A step that mutates the working tree and a step that reads it are
  not parallel. On 2026-08-22 a check suite and the script that sabotages it ran together and
  produced a red row that described neither.

This step has finished when every remaining step either names what it waits on, or sits in a
group that starts immediately.

## 5. Rescue what exists nowhere else

Facts that live only in this conversation and belong to another repo: name them, name the
repo, and say they need writing from a session opened there.

Writing them from here counts as doing that project's work in this project's session, and
that has produced work in the wrong repo before.

## 6. Print one command

One copy-paste block, nothing around it:

```bash
claude "Read <path>. State the goal section and the First action back to me in one line, then on my yes, continue that work."
```

## Done

This command has finished when the file exists, its goal section quotes the owner verbatim,
its first action is doable in under two minutes, every remaining step names what it waits on
or starts immediately, and the start command is printed as a single block.
