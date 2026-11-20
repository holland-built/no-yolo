---
name: grill-lite
description: "Use when the user says grill me, grill-lite, interview me, ask me your questions first, stress-test this plan, or wants to think a plan, purchase or idea through before acting. Asks numbered rounds of questions, then saves the decisions in a short note."
---

<!-- Based on mattpocock/skills (MIT): skills/productivity/grilling and skills/engineering/grill-with-docs, read 2026-11-20. Changed: questions use the Action First "Waiting on you" shape; only questions the user can judge; DECISIONS.md replaces the glossary and ADRs. -->

The user wants to be interviewed until you both understand the plan the same way, before anything
is built or decided. The user is not a programmer, so the value of this is getting what they want
pinned down, not having them weigh technical options they cannot judge.

## Who answers what

Facts are your job. Anything you can find in the files, the tools or the web, look up yourself
(a subagent can do it while you ask the rest), because asking the user for something you could
find wastes their attention.

Decisions the user can judge are theirs: what it should do, who it is for, what it should look and
feel like, what matters most, what is out of scope. Technical choices are yours; state them as
assumptions in the summary so the user can still object.

## How to ask

Ask in rounds. Each round holds every question you can ask now without guessing at an answer you
have not heard yet; a question that depends on another open question waits for a later round.
Use the "Waiting on you" shape from the output style: numbered options, your recommended option
first and marked, so the user can accept everything by replying with 1s. Explain any term the
user may not know in the question itself.

The user can end it at any time ("enough", "let's build"), and that ends it; do not argue for more
rounds. Otherwise it ends when nothing is left that you would otherwise have to guess.

Before acting, show a short summary of what was decided and the assumptions you made, and wait for
the user to confirm it, because acting on a misread plan is the failure this exists to stop.

## The decisions note

Once confirmed, append to `DECISIONS.md` in the project folder (create it if missing; in a folder
that is not a project, ask where). Record only decisions someone would later wonder about: hard to
undo, surprising, or picked over a real alternative. One entry each, dated, one line for the
decision and one for why, so a later session does not undo a choice without knowing its reason.

## Done

The user confirmed the summary, and `DECISIONS.md` holds the decisions worth keeping. If `/build`
follows, its questions are already answered by that summary; do not ask them again.
