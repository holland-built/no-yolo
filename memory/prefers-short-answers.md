---
name: prefers-short-answers
description: The user wants short, lead-with-the-answer replies
metadata:
  type: feedback
---

Write the answer you would give AFTER the user says "wait, what?" — write that one first. That
reaction is a reliable signal the first answer was too long.

Tables are welcome. Do not remove them. The problem is what goes in the cells: file paths,
byte counts, and technical names. Plain words in the cells work fine.

**Why:** Across many sessions the user asked for shorter answers, plainer words, and fewer of
them. Dense tables of file paths were the specific thing that could not be read.

**How to apply:** Default to 1-3 sentences. The rules for this live in
`~/.claude/output-styles/plain.md`.
