# Stage 1: Interview

Adapted from `mattpocock/skills` → `grilling`.

## Read first, then say what you see

Read the relevant code yourself and form your own view before asking anything. Then open
with it:

> Here is what I see in the code: X. My working theory is Y. Now the gaps.

A view that differs from the owner's description is the first thing to raise. Reconciling it
early saves the whole interview.

## One question at a time

Use `AskUserQuestion` with three or four clickable options. Put your recommendation in the
middle, so its position carries no weight of its own.

A question the codebase can answer gets explored instead of asked. The owner's time is the
scarce input here.

## Every branch, until it closes

A **branch** is a case the work would handle differently. The interview finishes when every
branch has an answer, not at a question count. Some decisions close in two questions and
some in nine.

Signs a branch is still open:

- Two answers so far are compatible with different implementations.
- A word in the request could mean two things and nobody has picked one.
- An edge case exists that neither of you has named out loud.

## Write each answer down as it lands

To `brainstorms/<slug>-<date>.md`, under Decisions, Open, and the question log.

## Decisions that outlive the session

The brainstorm file is a session artifact. Two things escape it into the repo, the moment the
decision locks rather than at the end:

**A decision record** earns a file when all three hold:

1. Reversing it is hard or expensive: schema shape, storage engine, auth model, a public API
   contract, a dependency that would have to be ripped out.
2. A reasonable person could have chosen differently, and real alternatives existed.
3. The code alone will not say why, so a future reader asks and finds nothing.

All three: write `docs/adr/NNNN-<slug>.md` with the forces, the decision in present tense,
each alternative and why it lost, and what this makes easy and hard.

Fewer than three: the brainstorm file is enough. A record for every choice is as useless as
none.

When the `domain-modeling` skill is installed, its `ADR-FORMAT.md` sets the file's numbering
and shape; absent it, the sentence above is the shape.

**Glossary.** Every project noun this interview names or sharpens goes into the repo's
glossary, one line each. Read the existing entries first: when the repo already has a word
for the thing, use the repo's word.

When the `domain-modeling` skill is installed, its `CONTEXT-FORMAT.md` sets where the
glossary lives and how an entry reads; absent it, one line per noun is the format.

Both are real files in the diff. Say so, so stage 5 does not rewrite them.

## Done

This stage has finished when every branch on the list is marked one of three ways: answered,
deferred by the owner with the default that will be used in the meantime, or dropped by the
owner as out of scope. Show the list with its marks. An unmarked branch keeps the stage open.
