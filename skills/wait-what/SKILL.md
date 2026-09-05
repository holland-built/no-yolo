---
name: wait-what
description: Use when the user types /wait-what, or says "you lost me", "in plain English", "explain that again", "I don't follow". Says the last answer again in the plainest English, in four lines, and names the one thing to do next.
user-invocable: true
disable-model-invocation: true
argument-hint: "[the part that lost me]"
---

# wait-what

The last answer did not land. Say it again. Do not defend it.

## What to say again

If `$ARGUMENTS` names a part, explain that part. If it is blank, explain the whole
last answer.

## The four lines

Write exactly four lines. One sentence each. Nothing before them, nothing after.

| Line | What it holds |
|---|---|
| 1 | The thing itself, in words a person outside this field would use |
| 2 | Why it matters to you, right now, in this project |
| 3 | What it does *not* mean — the wrong reading I probably caused |
| 4 | The one thing to do next, or the one question I need answered |

## The rules for the words

- Under 15 words a sentence. Not 20. This is the short version.
- No name of any tool, file, flag or plugin. If a name is unavoidable, say what it
  does instead. "The thing that checks my replies", not the filename.
- No numbers unless the number is the point.
- Active voice. Say who does the thing.
- Never say "as I mentioned" or "to clarify". Just say it.

## What not to do

Do not apologise. Do not summarise the earlier answer first. Do not add a fifth
line. Do not run a command — this rewrites words that already exist.

If four lines cannot hold it, the answer was two answers. Say line 1 to 4 for the
first one, then ask which half the user wants next.
