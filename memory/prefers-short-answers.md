---
name: prefers-short-answers
description: Sholland wants short, lead-with-the-answer replies; asks me to cut length repeatedly
metadata:
  type: feedback
---

Write the answer you would give AFTER he says "wait, what?" — write that one first.
He confirmed this: "if I say, wait, what? It's usually perfect."

He likes tables. Do not remove them. The problem is what goes in the cells: file paths,
byte counts, and technical names. Plain words in the cells work fine.

**Why:** The best-evidenced correction in their history. Across sessions: "can I have the
short version", "dumb this down", "no other words cant read all that", "my god thats a lot
of words... Tell me in the least amount of words possible", and on 2026-09-09: "I can never
understand it. It needs to be way simpler." The cause was found that day: the Plain output
style at `~/.claude/output-styles/plain.md` said "Table-first is the default", which
contradicted this. Dense tables of file paths were the specific thing they could not read.

**How to apply:** Default to 1-3 sentences. The style file was rewritten on 2026-09-09 to
encode this; old version kept at `~/.claude/output-styles/plain.md.bak-20260909`. Related:
[[checks-setup-before-answering]], [[act-on-recommendations]].
