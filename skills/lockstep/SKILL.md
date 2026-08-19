---
name: lockstep
description: Use this skill when the user types /lockstep, says "lock step", "hold off on code", or "don't code yet". Hard, hook-enforced gate that blocks Edit/Write/NotebookEdit until the user explicitly releases it, not just a prompt reminder.
user-invocable: true
model: haiku
effort: low
argument-hint: "[on|off] (omit to toggle on)"
allowed-tools:
  - Bash
  - Read
---

# lockstep

A written "don't code yet" instruction can get ignored mid-conversation. This makes it mechanical: while active, a `PreToolUse` hook (`~/.claude/hooks/lockstep-guard.js`) denies every `Edit`/`Write`/`NotebookEdit` call outright. It is not a suggestion the model can talk itself past.

Mode: $ARGUMENTS

## Turning on (`/lockstep`, `/lockstep on`, or a trigger phrase)

```bash
touch "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.lockstep-active"
```

Confirm to the user: "Lockstep on. No file edits until you say go." Then continue the conversation normally: discuss, plan, research, run read-only commands. If a mutating tool call is attempted while this is active, the hook blocks it and feeds back a reminder to summarize and wait instead of retrying.

## Turning off (`/lockstep off`)

```bash
rm -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.lockstep-active"
```

Confirm: "Lockstep off, edits unblocked."

Also release it (run the same `rm`) when the user gives a clear go-ahead in conversation ("go", "agreed", "ship it", "do it", even without typing `/lockstep off` explicitly. Don't require the exact command if the intent is unambiguous.

## Destructive Bash is inside the hold

While lockstep is active, the hold covers destructive `Bash` too: an edit you can undo is blocked, so a delete you can't must be. Destructive means it removes or overwrites something that can't be re-derived: `rm -rf`, `git reset --hard`, `git push --force` (and `--force-with-lease`), `git clean -fd`, `git checkout .`, `git branch -D`, `DROP TABLE` / `TRUNCATE`, `dd`, `>` onto a tracked file. Reads, builds, tests, `git status`, `git log` are untouched, so run them freely.

The hook denies these outright. It matches `Bash` too. Don't route around it with a different command that has the same effect. When you hit the block, say what you would have run, then give three lines and wait:

1. **Blast radius:** every file / branch / table it destroys, from a real dry run (`git clean -n`, `git diff --stat`, `ls`), never estimated from memory.
2. **Rollback:** one line, or `none — irreversible`.
3. **Asked for by:** the user's instruction, quoted.

A "yes" to that block releases **that one command**. The lockstep flag stays on until released normally.

## Notes

- The flag file is global (`$CLAUDE_CONFIG_DIR/.lockstep-active`, falling back to `~/.claude`), not per-project. It applies to every session using that config dir until released.
- The hook blocks `Edit`/`Write`/`NotebookEdit` and destructive `Bash`, judged per command segment so `npm test && rm -rf dist` is caught on the second half. Ordinary Bash passes, because a hold you can't work inside gets switched off and stays off.
- **`/lockstep off` is itself an `rm -f` of the flag file**, so the guard exempts that one command. Without the exemption the mode would deny its own release and you would be stuck in it.
- Quoted strings still count: `sh -c "rm -rf /"` deletes just as hard as the bare command, so the guard does not strip quotes. `echo "rm -rf x"` gets caught as a false positive, accepted, because quote-stripping is how this class of guard grows a bypass.
- With the flag present the hook fails **closed** on a malformed payload, unlike every other guard here, which fails open. A stop order that goes quiet when the payload shape changes is not a stop order.
