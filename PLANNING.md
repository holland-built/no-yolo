# Planning Discipline

Plans live in `<project-root>/brainstorms/` — never here. This file defines what a good plan contains.

## When to Plan

- Multi-file changes (2+ files)
- New features or behavior changes
- Architecture decisions
- Anything you'd otherwise guess at

Trigger: user says "plan X" or task is non-trivial → auto-spawn Opus planner agent before any coding.

## Good Plan Structure

Every plan produced by Opus must contain:

| Section | What it says |
|---|---|
| **Root cause / goal** | `X breaks because Y = Z (file:line)` — grounded in evidence, never in user's words |
| **Success predicate** | Falsifiable, measurable: a number or boolean. Never "should work." |
| **Target file list** | Each file with "already exists — do NOT recreate" note |
| **Blast radius** | Explicit "do NOT touch" list — files/functions that must stay unchanged |
| **Regression pre-mortem** | Which existing tests/behaviors this could plausibly break, named before coding |
| **Ordered steps** | Smallest-reversible-first, each independently verifiable, ~300-word cap per agent |

## Self-Check Pass (Opus, second turn)

After drafting a plan, ask: "What is assumed rather than grounded in file:line? What's the strongest reason this plan is wrong or incomplete? What did it miss?" Fold answers in or note why dismissed.

## Reject a Plan If

- Cause not grounded in evidence (cites user's words instead of file:line)
- No measurable success predicate
- Blast radius unbounded
- Any claim cites an API/file not verified to exist

## Plan File Naming

`brainstorms/<slug>-plan-<YYYY-MM-DD>.md`

Diagnosis checkpoint (phase 0): `brainstorms/<slug>-diagnosis-<YYYY-MM-DD>.md`
Grill-me checkpoint: `brainstorms/<slug>-<YYYY-MM-DD>.md`
