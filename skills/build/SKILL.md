---
name: build
description: "Use when the user says build, make, add, or wants a feature, page, toggle, setting or script written, including small additions that look like a few lines, because those still get the Codex review. Settles what it should do, picks a plan, has Codex attack it, builds it and shows it working."
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

**Two models argue the approach, you pick, and the user can override.** When the shape is
undecided and two approaches really differ, do not choose alone and do not hand the user a menu
of technical options that only a programmer could judge. The user can say what matters, so settle three or four
criteria first, as plain sentences such as "Works without a network". Choose them yourself and
mark which are must-haves, then show them to the user without waiting for approval, because a pick
that wins two small criteria can still fail the one that matters. Use the user's own criteria word
for word when they give any. Then brief Fable and Astra separately on the same job, in one message so they run at the same time, and
criteria. Each returns its own best approach in plain words, plus how it does against each
criterion. Neither sees the other's answer, so neither anchors on it.

Fable is the Agent tool with `subagent_type: "Plan"`, `model: "fable"` and `effort: "medium"`,
which cannot edit files. Astra is the `codex exec` form below with `-c model=gpt-6-astra`.

If both land on the same approach, take it and say what it is before any code is written.
Otherwise pick the one that wins the must-haves; when both meet them, the one that wins more of the
rest. Say the pick and the reason in one line before any code is written, record it in `PLAN.md`,
and carry on; the user can interrupt with "the other one" at any point and you switch. You are not
one of the two sides here, so the pick is yours to make, and stopping to ask would hand the user
the technical menu this rule exists to avoid.

Whoever chose it, check the chosen approach before building: does it delete or overwrite data,
publish something off this machine, or spend money, and does it meet every must-have? Any yes on
the first three, or a missed must-have, goes to the user instead, because those cannot be undone
by switching later. Tests, not argument, decide whether code works.
Skip the two-model step on the fast lane, and when only one approach is sensible on a job that is
not big; a big build always gets both plans. The check on
the chosen approach still runs on a single approach, because it is the safety floor.

**A mockup the user picked is the settled approach.** When a new page's look is unsettled, run
`site-design` before the two plans; the variant the user picks is this mockup. The user has
already chosen what it should look like and do, so skip the two plans and the Codex attack on the approach below: on the
interview-density build (2026-11-15) the two plans took ten minutes and agreed with the mockup.
Still run the check on the chosen approach, the after-step checks on a big build, and the final
review, because those catch how it is built, which the mockup does not settle.

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
python3 -I ~/.claude/shared/codex-exec.py --skip-git-repo-check --sandbox read-only \
  -c model=gpt-6.1-sol -c model_reasoning_effort=medium \
  "<the chosen approach in full>. What would make this the wrong approach? Concrete failure cases, not style." < /dev/null
```

`< /dev/null` is required. Empty output means it failed, not that it agreed. Use a stronger
model only when undoing the decision later would mean rewriting rather than editing.

**A big build gets a check after each major step.** Big means more than about five steps or
about an hour of work, where a mistake found only at the end costs the most. After each major
step, ask Fable or Astra, taking turns, at `effort: "low"` / `model_reasoning_effort=low`: give
the plan and what the step changed, and ask "Is anything off-plan or broken? Answer yes or no,
then one line." Keep the question that narrow, because a broad review at low effort returns a
confident pass that means little. Check a yes against the code before acting on it; empty output
is a failed check, not a pass. These checks never replace the final review.

**Codex reviews the final diff** — after your last change, not before. If it finds something
and you change the code, it reviews the new diff too. Tell it the intent and what is out of
scope, because a reviewer that knows the goal can flag code the goal never needed, and one that
does not will suggest more.

New files are invisible to `git diff` until marked, so mark them first, and check the diff file
is not empty before sending it. If `codex` is missing or fails, say "Codex review: couldn't
tell" and why, and finish without it — never report a review that did not happen.

```bash
git add -N .
git diff <base> > /tmp/build-review.diff
python3 -I ~/.claude/shared/codex-exec.py --skip-git-repo-check --sandbox read-only \
  -c model=gpt-6.1-sol -c model_reasoning_effort=medium \
  "Intent: <one line>. Out of scope: <one line>. Review the diff at /tmp/build-review.diff. Only defects that would crash it or make it do the wrong thing in the intended case, and code the intent does not need. Ignore style. Label each blocker, should or nit. None is a valid answer." < /dev/null
```

**Check each finding against the code before acting on it.** Review loops grow a change one
cheap-looking fix at a time, and the user maintains every added line. Judge a finding by what it
costs if left, not by its label or how rare it is: anything that loses data, exposes a secret or
breaks the intended case gets fixed; a guard for a case that does not matter, extra compatibility
or a small slowdown gets declined in one line and listed as a follow-up. Prefer the fix that
deletes or narrows code, and if review made the diff bigger, cut before the next round. Agree
because the finding is right, not to end the loop.

**Two review rounds, then decide.** A third round rarely finds what the second missed. Settle
the disputed small findings yourself and say in one line what you overrode. A blocker still open
after two rounds is not a judgment call: stop and report it as failed, never as done.

**When the work ends in a pull request**, the title says what changed for the user, and the
description opens with the problem in the user's words, then the fix in a sentence, then how it
was proved. The user reads it later to remember why the change exists, and a list of renamed
functions does not answer that.

**"Be ambitious" widens what is asked for, and simplicity still governs how it is built.** When
the user says be ambitious, go all out, or asks for the full version, finish the thing they named:
its empty and error states, full flow, keyboard use and polish are no longer speculative. Say in
one line what that adds, write it into `PLAN.md` as acceptance criteria, and build each with the
least code that does it. A new product area, such as accounts or sharing, still gets asked first.

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

**A new page gets the design pass without being asked.** The user will not remember which design
skill does what, so `/build` carries it. Before writing a page or screen, load `frontend-design`
for the visual direction, so it does not come out looking like every other generated page. Once the
page runs, run `better-interface` on it, unless `site-design` already
did, and fix every `HIGH` finding, because those are the
accessibility and layout failures nobody notices until a reader hits one. A small change to an
existing page skips all of this; that is `/improve`'s job when it looks wrong.

**Look up the current browser feature before writing page code.** Models lean on old patterns
from their training, which adds JavaScript the browser now does for free. For each dialog, form,
table, layout, animation or similar piece of a page, search first and use the guide that fits:

```bash
DISABLE_TELEMETRY=1 npx -y modern-web-guidance@1.0.1 search "<2-5 word capability>"
DISABLE_TELEMETRY=1 npx -y modern-web-guidance@1.0.1 retrieve "<id>"
```

Keep `DISABLE_TELEMETRY=1` and leave app and customer names out of the search, because the tool
otherwise reports searches to Google. Skip it for backend work and text-only edits. The user never
has to ask for this, and the reply does not mention it unless a guide changed what they will see.

**A brand-new web app starts on Astryx, without asking.** The user likes how it looks, and its
ready-made tables, forms and chat screens cost far fewer tokens than writing them. Use React 19 or
later, keep the `frontend-design` pass, and give the app its own theme so it does not look like
every other Astryx app. The version script picks the newest release at least a week old, because
Astryx is in beta and ships often.

```bash
V=$(python3 ~/.claude/tools/astryx-version.py)
npm install --save-exact --ignore-scripts @astryxdesign/core@$V @astryxdesign/theme-neutral@$V @stylexjs/stylex
npm install -D --save-exact --ignore-scripts @astryxdesign/cli@$V
npx astryx init
```

Delete the `GEMINI.md` that `init` leaves, and read a part's guide with `npx astryx component <Name>`
before using it.

An existing app stays on what it uses unless the user asks to convert it, because in a test
Astryx's theme changed the fonts, heading colors and page background of parts it was not used on.
Converting is its own job, one app at a time, with before and after screenshots of every page.

**Every check ends as passed, failed, or couldn't tell.** Report "couldn't tell" as that, never
as a pass — a guessed pass is how a broken thing gets called done. Never weaken a check,
loosen a test, or change what it expects so that it passes; fix the code or report the failure.

**Stop retrying after three attempts at the same failure.** Past that point retries rarely add
evidence and burn the user's time. Say what you tried and what each attempt showed, carry on
with any part of the build that does not depend on it, and hand back when nothing else can
move without the user.

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
built, or was told the pick and the reason before the build began, and Codex saw the final diff. If either is false, say
so rather than calling it done.

## Excuses to catch

Each of these has sounded reasonable mid-build and cost the user later. When you hear yourself
think the left column, do the right one.

| The excuse | What to do instead |
|---|---|
| It's only a few lines, so it can skip the review | Small additions still get the Codex review on the diff |
| The tests pass, so it works | Run the real thing; if it draws a page, open the page |
| A setting or fallback might be handy later | Leave it out. The user maintains every line and can't tell which were speculative |
| The user will want this, so I'll just pick | Ask with a recommended answer, unless it's the fast lane |
