---
name: better
description: Turn the user's rough ask into a sharper prompt, show it, then run it on their go. Use when the user types /better followed by an ask, or says make my prompt better, improve this ask, how should I ask this, rewrite my prompt, or prompt this better.
---

# better

The user is not a programmer, and their asks often arrive as a fix they have already picked
("make the button blue"). A fix caps the result at their idea. This skill rewrites the ask so
Claude gets the goal, the decisions, and the finish line, then runs the better version.

Source: the Claude Code team's own habits, as recapped in
https://www.youtube.com/watch?v=_NzakzRXzLI.

## The five checks

Apply each one only where it fits the ask. Most asks need two or three, and a check that adds
nothing makes the prompt longer without making it better.

**Goal before fix.** Lead with the outcome the user wants, and keep their idea as one option
rather than the instruction. Claude can then offer something better while the user's idea stays
on the table. Example: "Change the button to blue" becomes "More people should notice the
sign-up button. One idea is making it blue; suggest others and recommend one."

**Plan on a page when there are several decisions.** When the ask leaves more than about three
real choices open (layout, audience, scope, tools), the rewrite asks Claude to put its questions
and mock-ups of the options on one published artifact the user can comment on, before building.
Reacting to a picture is easier than describing a preference. One quick question stays in chat,
because a page costs more tokens than it saves there.

**Say what to lean toward.** When the ask has a trade-off that the user's CLAUDE.md does not
already settle, name the tie-breaker the user would pick, such as "simplest thing that works over
the most scalable" or "clear over clever" for writing. Skip it when CLAUDE.md already covers it,
because repeating a rule adds nothing.

**Check access first.** If the job needs something Claude cannot reach (a login, a file, a
service, a connector), name it in the rewrite so it gets sorted before the work starts rather than
discovered halfway.

**Let Claude design the setup.** When the ask is about speeding up or repeating work, use this
prompt, adapted to the ask:

> My goal is to speed up how fast Claude runs. Can you analyze my chat history and existing
> skills to identify places where we can use sub agents or dynamic workflows? Once you identify
> them, create an artifact showing the before and after changes and how it will work.

Every rewrite ends with how both sides will know the work is finished, in terms that can be
checked: a page that loads, a test that passes, a file that exists. Without it, Claude decides
for itself when to stop.

## Missing information

When the answer to something would change the rewrite, ask with AskUserQuestion: at most two
questions, each with a recommended option first. For anything smaller, pick the likely answer and
state it as an assumption in the rewrite, where the user can correct it.

If the ask is already clear, say so in one line, ask "Run it?" and run it as written on a yes. A
rewrite for its own sake wastes the user's time.

## What the user sees

Lead with the better prompt in a code block, so it can be copied. Under it, one line per change
saying what changed and why, at most three lines. Then ask "Run it?" and wait. On a yes, run the
better prompt as if the user had typed it.

## Done

Done is a rewritten prompt that leads with the goal, carries only the checks that fit, ends with a
checkable finish line, and has run after the user said go.
