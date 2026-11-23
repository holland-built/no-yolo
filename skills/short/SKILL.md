---
name: short
description: "Use when the user types /short, or says shorter, too long, tl;dr, bullets only, five words, put it in a table, action first, just tell me what to do, or complains a reply was long, rambling or hard to follow. Redoes the last reply as five-word bullets, or a table when it is too big."
---

# short

The user reads replies in short bursts. When one comes out too long, this command pulls it back to
the house style without the user having to say what was wrong with it.

Read `~/.claude/output-styles/action-first.md` again, because the rules drift out of attention in a
long session and that file is the standard. Then rewrite your last reply to it. Keep every fact,
command, path and warning the user needs to act, because a shorter reply that drops the one thing
they needed is worse than a long one. Cut everything else.

Write the content as bullets of five words or fewer, because the user can take in a line that size
at a glance. When it needs more than five bullets, use a table with cells of five words or fewer,
because rows are easier to scan than a long list. Commands, paths, links and error text stay exact
and do not count toward the five words, because a shortened command breaks. A warning may run longer
when five words would hide the danger. Required blocks from the style file, such as the end banner,
keep their own shape.

Send only the rewritten reply, with no note about what was cut, since that note is the same padding
the user asked to lose. Keep replies in this shape for the rest of the session.

## Done

The first line is something the user can do, every bullet or table cell is five words or fewer
apart from the exact text and warnings above, and nothing the user needed to act has gone.
