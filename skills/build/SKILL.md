---
name: build
description: Use when the user types /build, or says "build me", "let's build", "make me a" about something real. Runs the whole job: goal, spec, mockup, a second model's challenge, build, test, fix, until the finish line is crossed.
user-invocable: true
disable-model-invocation: true
argument-hint: "<what to build>"
---

# build

The order below is the whole skill. Each row names the thing that already does the
work — this file exists so nobody has to remember the order or be told twice.

## Phase 0 — write the finish line

Before anything else, write one sentence: **what will be true when this is done, and
the command that will show it.** Put it at the top of the spec. Phase 8 checks it.

No finish line, no build. "Make it better" is not a finish line.

## The order

| # | Phase | What runs | Note |
|---|---|---|---|
| 1 | Goal | `/grill-with-docs` | Let it interview you. Vague opening prompts are fine — it does the work |
| 2 | Spec | `/to-spec` | Synthesises phase 1. Do not re-interview |
| 3 | Mockup | `/prototype` + `frontend-design` | **Web only.** `rules/web.md` fires automatically. Screenshot it in Chrome and read the screenshot before showing it |
| 4 | Ask | Stop. Show the spec and the mockup, ask go / change / stop | The only mandatory human gate |
| 5 | Challenge | `/codex:adversarial-review` | A second model tries to break the plan. See below |
| 6 | Tickets | `/to-tickets` | One ticket = one context window of work |
| 7 | Build | `/implement` per ticket | Drives `/tdd`. Fresh context per ticket |
| 8 | Prove | `/codex:review`, then `/code-review` | Then quote the phase-0 finish line and the command that proved it |

**Keep phases 1–3 in one unbroken context window.** No `/compact`, no `/clear` until
after phase 6 — they build on the same thinking. Every `/implement` starts fresh.

## On the second model

Two points only: phase 5 on the plan, phase 8 on the diff. Not per ticket.

It is there to disagree. If it returns findings, read the file and line it cites before
accepting anything — a finding you cannot see in the code is not a finding. Accepted
findings fold in without asking. **A finding I reject and it insists on comes to you.**
If Codex did not run, say "Codex: did not run" and continue. A missing second opinion
is a flag, not a defect.

## Sizing

A one-line change does not get eight phases. Small and obvious: do it, then phase 8.
The pipeline is for work where being wrong is expensive.
