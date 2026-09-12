---
name: fix
description: Something is broken, throwing, failing, or slow - reproduce it, show the cause, correct it, and show it working. Use when Sholland says fix, broken, failing, erroring, crashed, or slow.
---

# fix

Fix the thing. This file carries only the constraints, because the failure mode here is not
ignorance — it is confidence.

## The constraints

**Get a repeatable reproduction before you change any code.** A command that goes red on
this bug and green when it is gone. Reading code to build that reproduction is fine; reading
code *instead* of building it is the mistake. Paste the command and its real failing output.

If you cannot build one, say so and say what you tried. A change made without a reproduction
is a guess, and it must never be reported as a fix.

**Show the cause, do not argue it.** Use experiments that tell competing explanations apart,
and say what you expected versus what happened. You have it when you can name in one sentence
why the reproduction was red, and you have demonstrated that.

**When the investigation stops producing new evidence, get a second read** rather than trying
harder:

```bash
codex exec --skip-git-repo-check --sandbox read-only \
  -c model=gpt-5.6-sol -c model_reasoning_effort=medium \
  "<the symptom, the reproduction, what is ruled out and how it was ruled out>. What would you check next?" < /dev/null
```

`< /dev/null` is required. Empty output means it failed, not that it agreed.

**Correct the cause, and stop there.** The change is limited to what fixing the demonstrated
cause requires — not the smallest possible patch, and not a tidy-up of the code around it. A
fix buried inside a cleanup cannot be reviewed.

**Show it working.** The reproduction going green, pasted. Then the real thing running — the
script, the page, the command he actually uses — pasted too.

## Done

- The reproduction went red before and green after, and both are on screen
- You can name the cause in one sentence, and you showed it
- The change covers the cause and nothing else
- The real thing ran, not only its test

If one of those is false, say which, and why. That is a better answer than a fix you cannot
stand behind.
