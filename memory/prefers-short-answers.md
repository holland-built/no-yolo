---
name: prefers-short-answers
description: Sholland wants short, lead-with-the-answer replies
metadata:
  type: feedback
---

Write the answer you would give AFTER they say "wait, what?" — write that one first. They
have confirmed that reaction is a reliable signal the first answer was too long.

They like tables. Do not remove them. The problem is what goes in the cells: file paths,
byte counts, and technical names. Plain words in the cells work fine.

**Why:** The best-evidenced correction in their history. Across many sessions they have
asked for shorter answers, plainer words, and fewer of them, and on 2026-09-09 said replies
were still too hard to follow. The cause was found that day: the Plain output style at
`~/.claude/output-styles/plain.md` said "Table-first is the default", which contradicted
this. Dense tables of file paths were the specific thing they could not read.

**How to apply:** Default to 1-3 sentences. The style file was rewritten on 2026-09-09 to
encode this; old version kept at `~/.claude/output-styles/plain.md.bak-20260909`. Related:
[[checks-setup-before-answering]], [[act-on-recommendations]].
