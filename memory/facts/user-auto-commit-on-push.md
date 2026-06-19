---
id: user-auto-commit-on-push
tier: user
type: feedback
name: Auto-commit on push commands
description: When the user says 'push to <branch>', auto-commit all local changes first (add, generate message, commit, push) without asking.
status: active
captured: 2026-05-18
updated: 2026-05-30
confidence: 1.0
provenance:
  - session: git-workflow-origin
    date: 2026-05-18
supersedes: []
superseded-by: null
---

When the user issues any "push to [branch]" command (staging/prod/main), automatically: `git add` -> auto-generate commit message -> `git commit` -> `git push origin [branch]`. Do not ask for confirmation.

**Why:** Streamlined workflow; prevents local/remote divergence; user prefers autonomous behavior here.

**Boundary:** Honors [[user-no-confirmation-questions]] boundary — force-push still gates once.
