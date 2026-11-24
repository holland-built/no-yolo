---
name: better
description: "Use when the user types /better followed by any ask (the login page is broken, make the whole site better, add a dark mode toggle, rewrite the interface), or says make my prompt better, write me a prompt, a prompt to paste into another chat, how should I ask this, or rewrite my prompt. Sharpens the ask, hands it to build, fix or improve when one fits, adds every other skill and saved lesson that fits, and runs it. When the user wants a prompt for another chat, it writes the prompt and does not run it."
---

# better

The user is not a programmer, and their asks often arrive as a fix they have already picked
("make the button blue"). A fix caps the result at their idea. This skill rewrites the ask so
Claude gets the goal, the decisions, and the finish line, then runs the better version.

/better is the one command the user remembers. They have built many skills and taught Claude
lessons from videos and past sessions, but they will not remember which slash command does what.
So the rewrite does the remembering: the user says "/better make the whole site better" and the
rewrite names every skill and lesson that job should use.

Source: the Claude Code team's own habits, as recapped in
https://www.youtube.com/watch?v=_NzakzRXzLI.

## Where the ask goes

Decide this before rewriting, because it changes what the rewrite is for.

**A prompt for somewhere else is written and not run.** When what the user wants back is a prompt
(the ask starts with "prompt", says "write me a prompt", "a prompt to paste" or "make this prompt
better", or names another chat, session, project or tool as the place it will run), the prompt is
the whole job. Running it here would change files in the wrong project. When it is unclear whether
they want it run, write it and do not run it, because an unwanted run changes files and an unrun
prompt costs the user one word to start. "Prompt" as a part of a screen ("the prompt box is
broken") is an ordinary ask.

**Making, mending or improving something here goes to one workflow skill.** `build`, `fix` and
`improve` carry checks a rewrite cannot: a failing check before a fix, a second model on the plan
and the diff, tests at phone and desktop size. Naming one in the rewrite does not load it, so load
it with the Skill tool before any other work and pass the rewrite as its ask.

| The ask is about | Load |
|---|---|
| an error message, a crash, a failing command, something slow, or anything broken that is not a page | `fix` |
| an existing page or screen that looks, feels or behaves wrong, even when the user says "broken" | `improve` |
| something that does not exist yet | `build` |

"The login page is broken" with no error named goes to `improve`, which applies the `fix` rule to
broken behavior itself. This table repeats the three skills' descriptions; when they differ, the
descriptions in the live skill list win, because those are the ones kept up to date. An ask that
holds two of these is split and run in order, each under its own skill.

**Everything else is rewritten and run.** A deck, a document, a diagram, research or a question has
its own skill or none, and the checks below pick it.

## The ten checks

The first check applies to every ask. Apply the others only where they fit. Most asks need two or
three, and a check that adds nothing makes the prompt longer without making it better.

When the ask is handed to `build`, `fix` or `improve`, leave out the plan page, the score and round
limit, and questions to the user, because that skill has its own review rounds and its own way of
asking, and two sets of rounds spend the usage limit twice. The rewrite then carries what the skill
cannot work out alone: the goal, the user's idea as one option, the other skills and saved lessons
that fit, and the finish line.

**Use every skill and lesson that fits.** Read the skill list Claude Code shows this session (names
and descriptions), and pick every skill whose description fits the job, not only the first one.
Then read the project's saved memory notes and pull in the corrections that apply as must-haves,
because a fresh run otherwise repeats old mistakes. Name each skill in the rewrite with the part of
the job it does, such as "`/site-design` makes the 3 mockups, `/impeccable` critiques the pick".
Pick from the live list, never from memory, because a list from memory left `impeccable`, the
user's main design skill, out of a full app redesign. [ask-to-skill.md](ask-to-skill.md) maps
common asks to the skills that fit, as a starting point only. A skill that does not change the work
stays out, because each one costs time.

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
`site-design` for a new or unsettled look, `impeccable` for design direction, critique, audit and
polish of any redesign or build, `improve` for an existing page that feels wrong, and `better-ui`
when only surfaces and icons need polish. Name the part of the screen and the states
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
test already says whether it worked. If Codex is unavailable, say the work was not scored. When
the job compares mockups, scoring starts on the one the user picks, because a score on the options
would steer a choice that belongs to the user, and the `site-design` review gives none.

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

When the answer to something would change the rewrite, ask in the output style's Waiting on you block: at most two
questions, each with a recommended option first. For anything smaller, pick the likely answer and
state it as an assumption in the rewrite, where the user can correct it.

If the ask is already clear, say so in one line and run it as written. A rewrite for its own sake
wastes the user's time.

## What the user sees

Lead with the better prompt in a code block, so it can be copied. Under it, one line naming the
skills it uses, so the user learns them without memorising them, then one line per other change
saying what changed and why, at most three lines.

When it runs here, carry straight on without asking: load the workflow skill if one was picked, and
each other named skill as the work reaches it.

When it is a prompt for somewhere else, stop after the code block and those lines. The other chat
has seen none of this conversation, so the prompt says what it needs in full: the goal, the folder
and files by full path, what is already decided, what to leave alone, and the finish line. Write a
saved lesson out in its own words rather than by name, and name a skill only when the other chat is
Claude Code on this machine, because nothing else has them. Read the other project first when it is
on this disk, so the prompt names real files, and change nothing there. The last line says where to
paste it, and that replying `run` runs it here instead.

## Done

Done is a rewritten prompt that leads with the goal, names every installed skill and saved lesson
that fits, carries only the checks that fit, and ends with a checkable finish line. Either it has
run, under `build`, `fix` or `improve` when one fits, or it was asked for as a prompt and is on
screen, not run.
