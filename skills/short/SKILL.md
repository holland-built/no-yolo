---
name: short
description: Redo the last reply in the Action First style - next action first, numbered steps, nothing extra. Use when the user types /short, or says shorter, too long, tl;dr, action first, just tell me what to do, or complains a reply was long, rambling or hard to follow.
---

# short

The user reads replies in short bursts. When one comes out too long, this command pulls it back to
the house style without the user having to say what was wrong with it.

Read `~/.claude/output-styles/action-first.md` again, because the rules drift out of attention in a
long session and that file is the standard. Then rewrite your last reply to it. Keep every fact,
command, path and warning the user needs to act, because a shorter reply that drops the one thing
they needed is worse than a long one. Cut everything else.

Send only the rewritten reply, with no note about what was cut, since that note is the same padding
the user asked to lose. Keep replies in this shape for the rest of the session.

## Done

The first line is something the user can do, the reply fits the style file's sentence count, and
nothing the user needed to act has gone.
