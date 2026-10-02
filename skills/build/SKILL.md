---
name: build
description: Build a new thing for the user - settle what it should do, have Codex and an Opus helper argue the approach and Jev pick it (the user can override), get Codex to attack the plan before code exists, build it, and show it working. Use when the user says build, make, add, or wants a feature or script written.
---

# build

Build the thing. You know how to do that — this file only carries the parts you would
otherwise get wrong here.

## What this is for

The user works alone and is not a programmer. The user finds out what is wanted by looking at
something, not by writing a spec. So the job is to get something in front of the user quickly,
while stopping the two failures that cost real time: building the wrong thing carefully, and a
change nobody looked at.

## The constraints

**Two models argue the approach, Jev picks, and the user can override.** When the shape is
undecided and two approaches really differ, do not choose alone and do not hand the user a menu
of technical options that only a programmer could judge. The user can say what matters, so settle three or four
criteria first, as plain sentences such as "Works without a network". The user approves them
and marks which are must-haves, because Jev answers exactly the criteria it is given, and a pick
that wins two small criteria can still fail the one that matters. Then brief Codex and an Opus helper
separately on the same job and criteria. Each returns its own best approach in plain words, plus
exactly two short claims on how that approach does against each criterion. Keep the count equal,
because Jev leans toward whichever side writes more. The side that holds a claim writes it, so
your own slant stays out.

The Opus helper is the Agent tool with `subagent_type: "Plan"` and `model: "opus"`, which cannot
edit files. Codex is the `codex exec` form below.

If both land on the same approach, take it, skip Jev, and say what it is before any code is
written. Otherwise run `/jev-judge` on their claims and show the user the table it prints. When it
gives advice, say the pick and the reason in the reply before any code is written, record it in
`PLAN.md` as Jev's pick, and carry on; the user can interrupt with "the other one" at any point
and you switch. When it says ask the user, or cannot run at all (no TypeSafe key, no network),
show both approaches in plain words and wait.
However the approach was chosen, run `check_approach.py` from the `jev-judge` skill on it, with
its claims and the must-haves. An ESCALATE line sends it to the user instead. If the check cannot
run, apply the same test by hand. Anything that deletes data, publishes, or spends money goes to
the user whatever Jev says, because Jev's confidence measures how concentrated its picks are, not
how often they are right, and a quiet result from the check never clears an approach. Jev never judges whether code works; tests do that.
Skip the two-model step on the fast lane, and when only one approach is sensible. The check on
the chosen approach still runs on a single approach, because it is the safety floor.

**Ask before you assume.** Anything you would otherwise guess at, ask — numbered, with your
recommended answer on each, so the user can say "all of those" in four words. Find facts
yourself; never ask for something you could read off the disk. Stop asking when a round turns
up nothing you would have guessed wrong.

**When the thing is throwaway, build it first.** If you could rebuild it in one sitting,
nothing depends on it yet, and being wrong costs time rather than data — skip the options and
show a rough version. What the user says about it is the real brief. Say "fast lane" out loud
when you take it.

**Codex sees the approach before the code exists**, unless you took the fast lane. This runs on
the chosen approach even after the two-model step above, because there the two sides propose and
never attack each other:

```bash
codex exec --skip-git-repo-check --sandbox read-only \
  -c model=gpt-6-sol -c model_reasoning_effort=medium \
  "<the chosen approach in full>. What would make this the wrong approach? Concrete failure cases, not style." < /dev/null
```

`< /dev/null` is required. Empty output means it failed, not that it agreed. Use a stronger
model only when undoing the decision later would mean rewriting rather than editing.

**Codex reviews the final diff** — after your last change, not before. If it finds something
and you change the code, it reviews the new diff too.

New files are invisible to `git diff` until marked, so mark them first, and check the diff file
is not empty before sending it. If `codex` is missing or fails, say "Codex review: couldn't
tell" and why, and finish without it — never report a review that did not happen.

```bash
git add -N .
git diff <base> > /tmp/build-review.diff
codex exec --skip-git-repo-check --sandbox read-only \
  -c model=gpt-6-sol -c model_reasoning_effort=medium \
  "Review the diff at /tmp/build-review.diff. Only defects that would crash it or make it do the wrong thing. Ignore style. None is a valid answer." < /dev/null
```

**Write the least code that does the job, and touch only what the job needs.** The user
maintains it later without you, and cannot tell speculative code from needed code. Prefer, in
order: a pattern the project already uses, the standard library or platform, a dependency
already installed, then the smallest clear new code. Skip features, settings and wrappers
nobody asked for. Never cut input checks, data safety, security or accessibility to get there —
those fail silently. Leave nearby code, comments and formatting alone; mention unrelated dead
code rather than deleting it, and remove only what your own change left unused. This is here
because evals run without `~/.claude/CLAUDE.md`, so the skill has to carry it.

**Run it and paste what happened** — the real command and its real output. A passing test is
not the thing working. If it draws a page, open the page.

**Every check ends as passed, failed, or couldn't tell.** Report "couldn't tell" as that, never
as a pass — a guessed pass is how a broken thing gets called done. Never weaken a check,
loosen a test, or change what it expects so that it passes; fix the code or report the failure.

**Stop after three attempts at the same failure.** Say what you tried and what each attempt
showed, then hand it to the user. Past that point retries rarely add evidence and burn the
user's time.

## Where the plan lives

Write `PLAN.md` in the project folder once you know what you are building: the goal in one
line, what the user decided, and how you will both know it is finished. Update it at the end
with what actually happened, including anything you changed your mind about.

**`PLAN.md` describes the job in hand, not the history of the project.** When a job finishes,
replace the body with the next one and leave a single dated line under a `## Done` heading
saying what shipped. If that list passes about twenty lines, cut the oldest half — anything
worth keeping longer belongs in the vault or a commit message, both of which are searchable
and neither of which is read start-to-finish by the next session.

The test: a file someone can read in under a minute. A `PLAN.md` nobody finishes reading
stopped being a plan.

## Done

Done is the user's acceptance criteria met and shown working — the thing asked for, doing what
was asked, with the output on screen. Write those criteria into `PLAN.md` at the start, in the
user's words, so "done" is not your opinion.

Two things are true of every finished build, whichever lane you took: the user chose what got
built, or was shown Jev's pick before the build began, and Codex saw the final diff. If either is false, say
so rather than calling it done.
