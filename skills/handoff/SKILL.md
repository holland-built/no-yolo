---
name: handoff
description: Write the current session down so a fresh one can carry on without the user re-explaining anything. Use when a session is getting long, running out of context, ending unfinished, or when the user says hand off, write this up, or pick this up tomorrow.
---

# handoff

Write a file the next session reads instead of asking the user to repeat everything.

## What it is for

Context runs out mid-job and the next session starts blind. The user then re-explains what was
already explained, usually badly, because the session was the one holding the detail. The
handoff is what stops that — it is written for an agent to act on, not for a human to admire.

## The constraints

**Write what cannot be re-derived, and skip what can.** The next session can read the code,
run `git log`, and list a directory. It cannot know what was tried and abandoned, which of two
readings of the request won, what broke and why, or what the user said was wanted when
correcting you. That is the whole value.

**Point at evidence, do not summarise it.** Real paths, real commands, real commit hashes, the
exact file and line. A handoff that paraphrases its sources sends the next session hunting.

**Say what is decided and what is still open, separately.** The most expensive failure here is
a reopened decision — the next session re-litigates something already settled, and the user
pays for the same conversation twice. Anything the user decided goes under a heading that says
so.

**Say what already bit you.** Every wrong turn this session took, in one line each, phrased so
the next session avoids it rather than repeating it. This is the section that earns the file.

**Label anything you did not check yourself.** The next session builds on this file, so a
guess stated as fact compounds.

**Never carry a secret across.** Not the value, not a redacted version, not "the one in X".
Name the file that holds it and stop. Anything typed into a prompt once lives in the session
log, and a handoff is exactly the kind of file that would copy it somewhere new.

## Where it goes

`HANDOFF.md` in the project folder, or `~/AI/research/handoff-<topic>-<YYYY-MM-DD>.md` when
there is no project. Include at the top: the date, what was being attempted, and where it
stopped.

## Then print the paste block

The user starts the next session by pasting, so end by printing exactly this in the chat, with
nothing after it:

```
────────── COPY FROM HERE ──────────

Read <absolute path to the handoff file> in full before doing anything.

<one sentence: what this is and what you are picking up>

<one sentence: the single most important thing not to repeat>

────────── COPY TO HERE ──────────
```

Keep it to those three lines. The file carries the detail; the paste block only has to get the
next session to open it. Use the absolute path — a relative one breaks the moment the next
session starts somewhere else.

## Done

Done is a file that a session with no memory of this one could act on without asking the user
a single question. Read it back and check exactly that. If a question remains, either answer it
in the file or write it under the open heading — do not leave it implied.
