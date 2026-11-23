---
name: better
description: "Use when the user types /better followed by an ask, or says make my prompt better, improve this ask, how should I ask this, rewrite my prompt, or prompt this better. Sharpens the ask, shows it, and runs it on their go."
---

# better

The user is not a programmer, and their asks often arrive as a fix they have already picked
("make the button blue"). A fix caps the result at their idea. This skill rewrites the ask so
Claude gets the goal, the decisions, and the finish line, then runs the better version.

Source: the Claude Code team's own habits, as recapped in
https://www.youtube.com/watch?v=_NzakzRXzLI.

## The nine checks

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

**Ask for the expert version.** When quality matters more than speed (a report, an audit, an
analysis, anything a professional would be paid for), the rewrite asks for a deeper version, not a
bigger one. Claude first states what a top professional would do that the ask leaves out, the
rawest material they would start from, the methods and tools they would use, and what besides
Claude's own say-so would show the result is right. Then it does the work that way. Telling Claude
to "act like an expert" only changes how it sounds; naming the expert's methods changes the work.
Skip it for quick fixes, where it only adds length. Source: Felix Rieseberg,
https://felixrieseberg.com/how-to-be-more-ambitious-a-tutorial-for-humans-with-models/.

**Aim visual asks.** When the ask is about how a page or screen looks, name the skill that fits:
`site-design` for a new or unsettled look, `improve` for an existing page that feels wrong, and
`better-ui` when only surfaces and icons need polish. Name the part of the screen and the states
to check (hover, selected, loading, empty, phone width). If the user gave a screenshot or link,
say what to take from it (density, spacing, type) and what to leave (its layout, its brand). Settle
the layout before adding decorative animation, because motion hides a weak layout. If the user
cannot say what feels off, have Claude describe the three to five parts of that section in plain
words so the user can point at one. Never ask the user for a reference, because that hands them a
chore.

**Set a score and a round limit.** When the result is judged on quality (a page, design, report,
deck or piece of writing), add both to the rewrite yourself, because the user has said they cannot
tell how long a job should run. In each round, Codex scores the work out of 10 and names the
weakest part, then Claude fixes that part. Codex scores because whoever built the work is a poor
judge of it. The work stops at 8 or when the rounds run out, and the user gets the final score, so
a page that fell short never reads as finished. Allow 1 round for a small fix, up to 3 for a normal
page or document, and up to 5 only when the user says "go all out", because rounds spend their
usage limit. Skip this for asks with a plain right answer, such as a bug fix or a lookup, where a
test already says whether it worked. If Codex is unavailable, say the work was not scored.

**Tighten the contract.** Add only the lines the ask needs. When it mixes unrelated jobs, split them
and run them in order, because each job then gets its own finish line. When the form of the answer
matters, state it, such as "cause, evidence, smallest safe fix". For a diagnosis, review or
research, require evidence for each claim, with guesses labeled and unknowns named. Replace "think
harder" or "be very smart" with a check the result must pass, because a check changes the work.
Source: the prompting guide in the Codex plugin (`gpt-5-4-prompting`).

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

If the ask is already clear, say so in one line and run it as written. A rewrite for its own sake
wastes the user's time.

## What the user sees

Lead with the better prompt in a code block, so it can be copied. Under it, one line per change
saying what changed and why, at most three lines. Then run the better prompt as if the user had
typed it, without asking.

## Done

Done is a rewritten prompt that leads with the goal, carries only the checks that fit, ends with a
checkable finish line, and has run.
