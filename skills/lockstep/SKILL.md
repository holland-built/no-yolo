---
name: lockstep
description: Use this skill when the user types /lockstep, says "lock step", "hold off on code", or "don't code yet". Hard, hook-enforced gate that blocks Edit/Write/NotebookEdit until the user explicitly releases it — not just a prompt reminder.
user-invocable: true
model: haiku
argument-hint: "[on|off] (omit to toggle on)"
allowed-tools:
  - Bash
  - Read
---

# lockstep

A written "don't code yet" instruction can get ignored mid-conversation. This makes it mechanical: while active, a `PreToolUse` hook (`~/.claude/hooks/lockstep-guard.js`) denies every `Edit`/`Write`/`NotebookEdit` call outright — it is not a suggestion the model can talk itself past.

Mode: $ARGUMENTS

## Turning on (`/lockstep`, `/lockstep on`, or a trigger phrase)

```bash
touch "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.lockstep-active"
```

Confirm to the user: "Lockstep on — no file edits until you say go." Then continue the conversation normally — discuss, plan, research, run read-only commands. If a mutating tool call is attempted while this is active, the hook blocks it and feeds back a reminder to summarize and wait instead of retrying.

## Turning off (`/lockstep off`)

```bash
rm -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.lockstep-active"
```

Confirm: "Lockstep off — edits unblocked."

Also release it (run the same `rm`) when the user gives a clear go-ahead in conversation — "go", "agreed", "ship it", "do it" — even without typing `/lockstep off` explicitly. Don't require the exact command if the intent is unambiguous.

## Notes

- The flag file is global (`$CLAUDE_CONFIG_DIR/.lockstep-active`, falling back to `~/.claude`), not per-project — it applies to every session using that config dir until released.
- Only covers `Edit`/`Write`/`NotebookEdit`. `Bash` commands that mutate files (e.g. `rm`, `git commit`) are not blocked by the hook — this is a scope tradeoff for simplicity, not an oversight. If mutating Bash needs the same hard gate later, that's a separate follow-up.
