---
name: humanize
description: Edit prose so it stops reading like a model wrote it - removes five structural tells while keeping meaning and voice. Use when writing or revising a document people read, such as a README, a report, an email or a post, or when Sholland says humanize, de-AI, sounds like AI, or make it sound like me.
---

# humanize

Rewrite prose so a reader stops noticing a model wrote it. The tells that give it away are
structural, not a list of banned words, so spotting them takes judgment rather than a search.

## The five tells

**Not X but Y.** "This isn't a tool, it's a workflow." A denied claim nobody made, set up to
be knocked down. Say the positive claim.

**One-line closers.** A short punchy sentence tacked onto a paragraph to land it. Cut it, or
fold its content into the sentence before.

**Forced triads.** Lists of three where the third item is filler, added for rhythm. Keep the
items that carry content, however many that is.

**Staged run-ups.** "Here's the thing:" or "The result?" before the point. Start with the
point.

**Bold as decoration.** Bold on phrases that are not warnings or terms to scan for. Remove it.

## The constraints

**Match his voice, not a style guide.** He uses dashes and short sentences, so keep both. When
a sample of his writing is at hand, it outranks anything here.

**Leave code, commands, file paths, headings and identifiers exactly as they are.** Changing
one breaks something the reader will copy.

**Never run this on an instruction file** — `CLAUDE.md`, `plain.md`, any `SKILL.md` or memory
note. In those files sentence shape is load-bearing, and a smoother sentence can quietly change
a rule. If asked to anyway, say that and stop.

**Meaning does not move.** Keep every "must", "never" and "only". Refuse any edit that would
widen or narrow scope, drop an exception, or change which rule wins. A tell left in costs less
than a changed fact.

## Done

- None of the five tells remain, judged by reading, not by a search
- Every fact, limit and exception in the original is still there
- Code, commands, paths, headings and identifiers are unchanged
- It still sounds like him
