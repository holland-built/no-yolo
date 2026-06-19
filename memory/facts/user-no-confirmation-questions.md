---
id: user-no-confirmation-questions
tier: user
type: feedback
name: No confirmation questions — act, don't ask
description: Do not stop for clarifying/confirmation questions; make the reasonable call and continue until done and tested. User redirects if wrong.
status: active
captured: 2026-05-17
updated: 2026-05-30
confidence: 1.0
provenance:
  - session: d24a3716-732b-464e-9097-4a833b1dc295
    date: 2026-05-17
  - session: b26af252-ef9d-42af-87aa-9528421e9b16
    date: 2026-05-17
supersedes: []
superseded-by: null
---

Do NOT stop to ask clarifying or yes/no confirmation questions. Make the reasonable call and keep executing until the work is done and verified. The user will redirect if a call was wrong.

**Why:** User explicitly asked for a "continue until done and tested" mode (2026-05-17) and finds "Should I proceed? / Does this look good?" prompts disruptive. Wants momentum, not consensus-seeking.

**How to apply:**
- Skip AskUserQuestion for direction choices when a reasonable default exists — pick it, execute, verify, move on.
- Continue to the next edit on the same theme without a "want me to continue?" check.
- Verify own work (tests/preview/screenshots) before claiming complete.
- Recap at natural breakpoints, not for permission.

**Boundary:** Does NOT override destructive-action confirmation. Still gate once on: irreversible ops (force-push, rm -rf, dropping tables), outward-facing actions (PRs, comments, Slack), or genuinely ambiguous intent where a wrong default wastes significant effort.
