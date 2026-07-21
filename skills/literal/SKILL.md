---
name: literal
description: Use this skill when the user types /literal, says 'stop challenging', 'just do it', 'do exactly what I say', or 'literal mode'. Toggles a sticky mode that suppresses AI's challenge-by-default posture — AI obeys your words to the letter, proposes nothing, shows no mockups, until you turn it off. Off = challenging resumes.
user-invocable: true
model: haiku
argument-hint: "[on|off] (omit to toggle on)"
allowed-tools:
  - Bash
  - Read
---

# literal

By default this AI pushes back — it proposes its own version of things, shows mockups, suggests better paths, before doing what you asked. Good for direction. Annoying when you're deep in rapid changes and just want it done. `/literal` turns that pushing-back off for a whole stretch: the AI does exactly what your words say, nothing more, nothing extra, until you turn it back off.

Mode: $ARGUMENTS

## How it's wired

The on/off state is owned by the hook `literal-mode-tracker.js`, not by this skill — this skill does not write the flag itself. Mirrors how the `caveman` skill leaves its own state to its hook (contrast with `lockstep`, which touches its flag file directly). Saying `/literal` runs this skill so the toggle registers in conversation, but the actual state lives with the hook.

## Turning on

`/literal` (no args) or `/literal on` = on. Confirm to the user: "Literal mode on — no more proposals or mockups until you turn it off." A badge appears in your status bar while it's active, so you always know it's on.

## Turning off

`/literal off`, or saying "stop literal" / "normal mode" in conversation = off. Confirm: "Literal mode off — challenging resumes."

## One-off safewords (not sticky)

Saying "just do it", "do exactly what I say", or "no AI" in a single message suppresses pushback for that ONE message only — it does not turn on sticky mode and does not need `/literal` at all. Use `/literal` itself only when you want the suppression to hold across many messages.
