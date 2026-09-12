---
name: fix-it-dont-report-it
description: "Never hand Sholland a status line saying something is stale or broken - fix it, then report"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3a56ea80-f326-4950-bbf7-3e70c7fc681a
  modified: 2026-09-12T12:22:26.664Z
---

If a report would contain "stale", "broken", "needs a fix", "not done yet" or "never been
run", do not write that line. Go and fix the thing, then write the report describing the
fixed state.

**Why:** on 2026-09-12 he said it outright — "if you're going to print something that says
stale or broken or needs a fix or hasn't done this, just don't do it. Just fix it and then
reprint this." Several status tables in a row had carried the same self-inflicted items
(`RULES.md` out of date, docs describing yesterday's setup) instead of me simply fixing them.
Reporting my own unfinished work back to him makes him the one tracking it.

**How to apply:** confer with Codex on the result rather than shipping the fix unchecked — he
asked for that in the same breath. This does not override a genuine blocker: something that
needs *his* decision still gets raised, once, as a question. It applies to work that is mine
to do. Related: [[act-on-recommendations]] which moved into `CLAUDE.md` §0.
