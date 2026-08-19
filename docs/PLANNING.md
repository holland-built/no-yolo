# Planning Discipline

Plans live in `<project-root>/brainstorms/`, never here. This file defines what a good plan contains.

## When to Plan

- Multi-file changes (2+ files)
- New features or behavior changes
- Architecture decisions
- Anything you'd otherwise guess at

Trigger: user says "plan X" or task is non-trivial → auto-spawn a Fable planner agent before any coding. See `SUBAGENTS.md` for the Fable-plans/Opus-codes split.

## Good Plan Structure

Every plan must contain (written by the Fable planner, per `SUBAGENTS.md`; this line said "Opus plan" until 2026-08-19, left over from the pre-2026-07-31 split):

| Section | What it says |
|---|---|
| **Root cause / goal** | `X breaks because Y = Z (file:line)`, grounded in evidence, never in user's words |
| **Done looks like** | Something you can actually check: a number, a test result, a screenshot. Not "it should work." |
| **Target file list** | Every file the change will touch |
| **What this change could break** | Explicit "do NOT touch" list: the files and functions that must stay untouched |
| **What this could break** | Name existing tests or behaviors that might be affected before writing a line of code |
| **Ordered steps** | Start with the smallest step that can be verified on its own, each independently verifiable |

## Self-Check Pass

After writing a plan, ask: what did I assume without checking? What's the most likely way this plan is wrong? Fix it before handing it to anyone.

## Reject a Plan If

- Cause not grounded in evidence (cites user's words instead of file:line)
- No measurable "done looks like"
- "What this change could break" is unbounded
- Any claim cites an API/file not verified to exist

## Plan File Naming

`brainstorms/<slug>-plan-<YYYY-MM-DD>.md`

Diagnosis checkpoint (phase 0): `brainstorms/<slug>-diagnosis-<YYYY-MM-DD>.md`
Grill-me checkpoint: `brainstorms/<slug>-<YYYY-MM-DD>.md`
