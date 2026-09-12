---
name: build
description: Build a new thing for Sholland - settle what it should do, let him pick the approach, get Codex to attack the plan before code exists, build it, and show it working. Use when he says build, make, add, or wants a feature or script written.
---

# build

Build the thing. You know how to do that — this file only carries the parts you would
otherwise get wrong here.

## What this is for

Sholland works alone and is not a programmer. He finds out what he wants by looking at
something, not by writing a spec. So the job is to get him something to react to quickly,
while stopping the two failures that cost him real time: building the wrong thing carefully,
and a change nobody looked at.

## The constraints

**He picks the approach, not you.** When the shape is undecided, give him two or three real
options in plain words — what each does, what it costs later, when it is the wrong choice.
Say which you would pick. Then stop and wait. This is the one place where moving on your own
wastes his day.

**Ask before you assume.** Anything you would otherwise guess at, ask — numbered, with your
recommended answer on each, so he can say "all of those" in four words. Find facts yourself;
never ask him for something you could read off the disk. Stop asking when a round turns up
nothing you would have guessed wrong.

**When the thing is throwaway, build it first.** If you could rebuild it in one sitting,
nothing depends on it yet, and being wrong costs time rather than data — skip the options and
show him a rough version. What he says about it is the real brief. Say "fast lane" out loud
when you take it.

**Codex sees the approach before the code exists**, unless you took the fast lane:

```bash
codex exec --skip-git-repo-check --sandbox read-only \
  -c model=gpt-5.6-sol -c model_reasoning_effort=medium \
  "<the chosen approach in full>. What would make this the wrong approach? Concrete failure cases, not style." < /dev/null
```

`< /dev/null` is required. Empty output means it failed, not that it agreed. Use a stronger
model only when undoing the decision later would mean rewriting rather than editing.

**Codex reviews the final diff** — after your last change, not before. If it finds something
and you change the code, it reviews the new diff too.

```bash
git diff <base> > /tmp/build-review.diff
codex exec --skip-git-repo-check --sandbox read-only \
  -c model=gpt-5.6-sol -c model_reasoning_effort=medium \
  "Review the diff at /tmp/build-review.diff. Only defects that would crash it or make it do the wrong thing. Ignore style. None is a valid answer." < /dev/null
```

**Run it and paste what happened** — the real command and its real output. A passing test is
not the thing working. If it draws a page, open the page.

## Where the plan lives

Write `PLAN.md` in the project folder once you know what you are building: the goal in one
line, what he decided, and how you will both know it is finished. Update it at the end with
what actually happened, including anything you changed your mind about.

**`PLAN.md` describes the job in hand, not the history of the project.** When a job finishes,
replace the body with the next one and leave a single dated line under a `## Done` heading
saying what shipped. If that list passes about twenty lines, cut the oldest half — anything
worth keeping longer belongs in the vault or a commit message, both of which are searchable
and neither of which is read start-to-finish by the next session.

The test: a file someone can read in under a minute. A `PLAN.md` nobody finishes reading
stopped being a plan.

## Done

Done is his acceptance criteria met and shown working — the thing he asked for, doing what he
asked, with the output on screen. Write those criteria into `PLAN.md` at the start, in his
words, so "done" is not your opinion.

Two things are true of every finished build, whichever lane you took: he chose what got
built, and Codex saw the final diff. If either is false, say so rather than calling it done.
