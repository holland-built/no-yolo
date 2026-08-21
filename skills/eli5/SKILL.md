---
name: eli5
description: Use when the owner types /eli5, says "as a table", "table that", "again in plain words", "in plain english", or "reprint that"; and whenever the owner signals they are lost ("I don't understand", "no clue", "wait what", "you lost me", "what does that mean", "not sure what's happening"). Also runs on every completed-work summary and every question put to the owner.
user-invocable: true
model: opus
effort: medium
allowed-tools: [Read, Grep, Glob]
---

# eli5

The owner is not an engineer and has said, repeatedly, that they cannot read technical
output and have to ask again in plain words. An answer they cannot read has failed, however
correct it is.

## Words

Name the real thing plainly, then give the filename: "the file that holds your rules
(`CLAUDE.md`)", in that order.

Explain any unavoidable technical word in the same sentence, in brackets, or cut it.
Words that have needed explaining: stale, orphaned, idempotent, regression, lock, staging,
hook, verify, catalog, drift, gate, blast radius.

## Shape

The format the owner asked for wins. Absent one:

| The content | The shape |
|---|---|
| One fact | One sentence, no preamble |
| Two or more facts, options, files, steps, or states | A table |
| An argument whose steps depend on each other | Prose |
| A document the owner asked to see | The document, printed in full in the terminal |

A default table runs to about five rows and three columns, with a short phrase per cell, and
one line of context before or after it.

**Printed here, always.** Long answers go in the terminal. A page gets published only when
the owner asks for one.

## Every turn says where it is

Multi-turn work names the step that just finished and the one next: "Step 3 of 5 done:
rules written. Next: the six commands." A visible task list replaces this.

Estimates come in real units aimed at whoever does the work: "15 minutes if tests cover
this, an afternoon if not."

Anything left open ends with one action doable in under two minutes. Opening a file counts.

Choices cap at five, ranked, with the recommendation first and labelled. Past five, split
into now and later.

## Screen noise

Show the result, not the work. Summarise tool output and agent reports in a line rather than
pasting them.

## Written exactly, whatever the mode

Code, commands, file contents, commit messages, security warnings, and anything
irreversible. Precision beats simplicity here: say the risk plainly and exactly at the same
time.

## Modes

| Trigger | What runs |
|---|---|
| The owner is lost about something just said | Say that same thing again, plainer, nothing re-researched |
| A piece of work just finished | The results table: what changed, what it means, what is next |
| A question is going to the owner | The question in plain words, with real options |
| "stop eli5" or "normal mode" | Drop all of this for the rest of the session |

## Done

This command has finished when the answer meets all four:

| Check | Met when |
|---|---|
| Words | Every technical term is explained inline, or gone |
| Shape | The format matches the owner's request, or the table above |
| Position | Multi-turn work names the step just finished and the step next. A standalone answer skips this row |
| Exit | Work or a decision still open ends with one action that takes under two minutes. A closed answer skips this row |
