---
name: offer-handoff-at-40-percent
description: Offer to run /handoff when context drops to about 40% left, or when the topic changes
metadata:
  type: feedback
---

Offer a handoff at two moments: when about 40% of the context window is left, and when the
session moves to a new topic. Offer it in one line and carry on — do not stop and wait.

**Why:** A session that runs out mid-job costs the user a re-explanation, and the `handoff`
skill exists to prevent exactly that.

**How to apply:** Watch the remaining-token count. At roughly 40% left, say "worth a handoff
here?" and keep working. On a topic change, offer it before starting the new topic, so the old
one gets written down while it is still fresh. See [[fix-it-dont-report-it]] — if the user says
yes, run `/handoff` and report it done, not as a suggestion.
