# Code Review Discipline

## Review Filters (from Karpathy's engineering guidelines)

> Karpathy = Andrej Karpathy, ex-Tesla/OpenAI — his rules for surgical, simple code changes.

### Surgical Check (Rule 3)
Flag any changed lines that don't trace directly to the stated request. Scope creep in a diff is a bug, not a bonus.

### Simplicity Filter (Rule 2)
Apply this test: "Would a senior engineer say this is overcomplicated?" If yes, flag it. Don't soften it — overcomplicated code is a defect.

## When Running /review

- State what was in-scope before reviewing, so the reviewer can spot edits that weren't part of the task
- Include what "done" actually looks like for this task
- Fix Critical findings immediately; fix Important before proceeding; log Minor for later
- Push back with technical reasoning if a finding is wrong — do not comply blindly

## When Receiving Review Feedback

- Verify before implementing — check the suggestion against the actual codebase
- One item at a time, test each
- YAGNI (You Aren't Gonna Need It) check: if the reviewer suggests a feature, grep for actual usage first — if unused, question it; don't add code for features nobody asked for
- No agreeing just to be agreeable — fix it or push back with reasoning
