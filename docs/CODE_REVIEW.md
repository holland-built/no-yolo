# Code Review Discipline

## Review Filters (from Karpathy's engineering guidelines)

> Karpathy = Andrej Karpathy, ex-Tesla/OpenAI — his rules for surgical, simple code changes.

Review every diff against `~/.claude/docs/CORE_RULES.md` rule 3 (surgical changes) and rule 2 (simplicity first) — flag violations of either as defects, not nits.

## When Running /health

- State what was in-scope before reviewing, so the reviewer can spot edits that weren't part of the task
- Include what "done" actually looks like for this task
- Fix Critical findings immediately; fix Important before proceeding; log Minor for later
- Push back with technical reasoning if a finding is wrong — do not comply blindly

## When Receiving Review Feedback

- Verify before implementing — check the suggestion against the actual codebase
- One item at a time, test each
- YAGNI (You Aren't Gonna Need It) check: if the reviewer suggests a feature, grep for actual usage first — if unused, question it; don't add code for features nobody asked for
- No agreeing just to be agreeable — fix it or push back with reasoning
