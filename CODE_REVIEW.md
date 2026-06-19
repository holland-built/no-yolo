# Code Review Discipline

## Karpathy Filters (apply when reviewing or receiving review)

### Surgical Check (Rule 3)
Flag any changed lines that don't trace directly to the stated request. Scope creep in a diff is a bug — not a bonus. Every line changed must have a reason rooted in the task.

### Simplicity Filter (Rule 2)
When flagging complexity, apply this test: "Would a senior engineer say this is overcomplicated?" If yes, flag it. Don't soften it — overcomplicated code is a defect.

## When Running /code-review

- State what was in-scope before reviewing — reviewer needs the blast radius to judge scope creep
- Include the success predicate — what "done" looks like for this task
- Fix Critical findings immediately; fix Important before proceeding; log Minor for later
- Push back with technical reasoning if a finding is wrong — do not comply blindly

## When Receiving Review Feedback

- Verify before implementing — check the suggestion against the actual codebase
- One item at a time, test each
- YAGNI check: if reviewer suggests a feature, grep for actual usage first — if unused, question it
- No performative agreement — just fix it or push back with reasoning
