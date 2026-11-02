---
name: improve
description: Make something that already exists better - a web page, web app, dashboard or screen, on phone and desktop. Picks the right design and behavior checklists itself (accessibility, layout, writing, type, color, polish, taste), tests it like a real user at phone and desktop size, has Codex and an Opus helper agree before any code, ships each fix live and retests until it passes. Use when the user says improve, make it better, polish, clean it up, this feels off, it's clunky, the colors/layout/buttons/wording are bad, or names a page and complains about how it looks or behaves. A web page that behaves wrong comes here even if the user says broken; /fix is for crashes, errors and things that are not pages. New things go to /build; for rewriting a prompt use /better.
---

# improve

The user is not a programmer, has ADHD, and finds out what they want by using the thing. They
will never remember which design checklist does what, so this skill picks them. It covers web
pages and web apps, on a phone and on a desktop browser, because the user uses both.

## What the user actually asks for

On the user's own camera web app, most requests were about
behavior: the timeline not following a scroll, taps that do nothing, zoom, wrong times, video
quality. Colors and fonts almost never came up. The complaint that came up again and again was
"you fixed one tiny thing and didn't look at everything" and "did you even test it". So test
behavior on a real screen size first, judge looks second, and sweep the whole app for the same
problem once one is found.

## Scope comes from the user's words, findings decide the checks

A named area keeps the work narrow: "make the colors better" uses `better-colors` and nothing
else. "Make it better", or a feeling ("it's clunky", "zoom sucks"), starts with a walkthrough,
and what the walkthrough finds decides which checklists run. Words alone are not enough, because
"the timeline feels off" sounds visual and is usually a behavior bug.

The checklists are skills; load the ones that apply:

| Area | Skill |
|---|---|
| Keyboard, screen readers, contrast, zoom | `better-accessibility` |
| Grouping, alignment, resizing, reading order | `better-layout` |
| Labels, errors, empty states | `better-writing` |
| Type scale, wrapping, truncation | `better-typography` |
| Palettes, tokens, contrast | `better-colors` |
| Corners, shadows, icons, motion | `better-ui` |
| Not looking generic or templated | `frontend-design` |
| All six `better-*` areas in one ranked report | `better-interface` |
| A new layout with several real options | `site-design` (variants on the real page, user picks) |

Behavior has no checklist skill; the task list below is its checklist.

## How deep to go

- **Quick**: one named thing. Codex and the Opus helper each get one look at the proposed change,
  at the same time; if they agree, make it, and if not, use the normal rounds. Rerun the tasks the
  change touches, then the full list once at the end.
- **Normal** (the default, including plain "make it better"): walkthrough, the checklists the
  findings call for, agreement on each change as below.
- **Deep**: only when the user says "every screen", "everything" or similar. Every screen,
  `better-interface` plus `frontend-design`, both reviewers per screen.

## The task list is the test

Each app gets a file of real user tasks, `IMPROVE_TASKS.md`, next to the app's code. Run any test
scripts the project already has as part of it. If the file is missing, write one: five to ten
things a person does and what they should see, such as "Drag the timeline: the time and video
follow the finger while dragging". Base each task on how the app works now and what its README
says, because an old request may describe something the user later changed or dropped.

Run every task at phone size and desktop size (1440 x 900) on the live page, and screenshot each
result. For phone size use Playwright with an iPhone device profile (`isMobile`, `hasTouch`), on WebKit,
the iPhone's engine, when it is installed, so
taps and drags are real touch events; a resized desktop window only checks layout, so a
touch task tested that way is marked couldn't tell. Say which device or emulation each result
came from. Touch emulation does not pinch by itself: a zoom task needs a real two-finger gesture (for
example two touch points sent through the Chrome DevTools protocol), or it is couldn't tell.

The task list runs before any opinion and again after every change, because screenshots alone
cannot show that scrolling, zoom or a tap works, and a change is not done because the code looks
right. Record each task as passed, failed or couldn't tell; never call a couldn't-tell a pass.
Tasks that already fail outside the area asked about are reported, not fixed, so a colors job
does not turn into a video job.

For broken behavior, use the `fix` skill's rule: a check that fails now and passes after, before
any code changes.

## Two reviewers, then agreement, then code

Claude and Codex review separately, so neither anchors the other. Codex in review mode will not
run commands or open files, and it does not have the checklist skills, so paste the code it needs
and the relevant rule lines from the loaded checklists into the prompt, and attach screenshots by
absolute path. The prompt goes after `--`, or the last image flag reads it as a file:

```bash
codex exec --skip-git-repo-check --sandbox read-only \
  -c model=gpt-6-sol -c model_reasoning_effort=medium \
  --image /abs/path/shot-phone.png --image /abs/path/shot-desktop.png -- \
  "<goal in the user's words>. <task results>. <code excerpt>. Review against these rules: <pasted rule lines>. List problems a user would hit, most serious first." < /dev/null
```

`< /dev/null` is required, and empty output means it failed, not that it agreed.

The user's rule: no code until Codex and an Opus helper (Agent tool, `subagent_type: "Plan"`,
`model: "opus"`) agree on each change. Send all items in one prompt per round and argue only the
ones they disagree on; at most three rounds on any item. If they still disagree, run `/jev-judge`
with criteria in the user's own words where possible ("easy for anyone at home", "highest quality video",
"fewer buttons", "works one-handed on an iPhone"). Jev's pick is advice: tell the user the pick in
one line and carry on unless they object. If Jev says ask the user or couldn't tell, show both
options in plain words, park that item, and carry on with the others. A retry of an agreed fix
needs no new agreement unless the approach changes.

Subagents run in parallel for testing and reviewing when their work does not overlap: different
screens, different tasks. The main thread makes every edit, so two agents never write the same
file and one thread owns what changed.

## Ship live, then test back and forth

The user's rule, given as standing approval on 2026-11-02: each agreed fix goes live as soon as it
is made, without asking first. Live means wherever the
project's own deploy steps put it (its README says how); if the project has none, ask once where
live is. Before the first edit, write undo steps the way the project already does (for example a dated
entry in an `UNDO.md` file), because live changes need a way back.

After each fix, hard-reload the page or bump the file's version tag and confirm the new code
loaded, because cached files make a retest pass or fail on the old code. Then rerun the tasks at
both sizes, send Codex the diff and the new screenshots, and loop until the tasks pass and Codex
has no blocker. If the live page cannot be reached, the change is reported as untested, never as
done. Stop after three attempts on the same item and report what each attempt showed.

When one problem is found, search the app for the same cause and fix it there too, with the same
checks. Keep it to that cause; a sweep is not a general cleanup.

## When to ask

Only before deleting data, spending money, or when the project does not say where live is. Everything else carries on, with the reason said in
one line. If the user says "don't ask again", save that as a memory note for the project and stop
asking there.

## Done

Every task that passed before still passes, every task for the area asked about passes at phone
and desktop size on the live page, and any other failures are listed as left over. The user has
seen before and after screenshots, Codex reviewed the final diff, every change was agreed by Codex
and the Opus helper or decided by Jev, and the undo steps are written. Report it as one short
table of what changed, the task results, and anything left over.
