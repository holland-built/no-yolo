---
name: fix-it-dont-report-it
description: "Never hand the user a status line saying something is stale or broken - fix it, then report"
metadata:
  type: feedback
---

If a report would contain "stale", "broken", "needs a fix", "not done yet" or "never been
run", do not write that line. Go and fix the thing, then write the report describing the
fixed state.

**Why:** the user asked for exactly this: "if you're going to print something that says stale
or broken or needs a fix or hasn't done this, just don't do it. Just fix it and then reprint
this." Reporting your own unfinished work back makes the user the one tracking it.

**How to apply:** confer with Codex on the result rather than shipping the fix unchecked. This
does not override a genuine blocker: something that needs the user's decision still gets
raised, once, as a question. It applies to work that is yours to do.
