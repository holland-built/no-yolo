<!-- GENERATED FROM ~/.claude/memory/facts/ — DO NOT EDIT. Run /memory-compile. -->
<!-- compiled 2026-06-18 -->
# Learned Preferences (compiled from curated memory)

Compiled from the fact store. Each line links its source fact.

## Working Preferences
- **Auto-commit on push commands** — When the user says 'push to <branch>', auto-commit all local changes first (add, generate message, commit, push) without asking. ([user-auto-commit-on-push](memory/facts/user-auto-commit-on-push.md))
- **No confirmation questions — act, don't ask** — Do not stop for clarifying/confirmation questions; make the reasonable call and continue until done and tested. User redirects if wrong. ([user-no-confirmation-questions](memory/facts/user-no-confirmation-questions.md))
- **Bulleted/table output, never prose** — Default output is a bulleted list or markdown table; no long prose paragraphs. Code/commands in fenced blocks. ([user-output-format-bullets](memory/facts/user-output-format-bullets.md))
- **Single-paste prompts always** — When the user needs to run something, give ONE consolidated copy-paste block, never a numbered list of separate prompts/commands. ([user-single-paste-prompts](memory/facts/user-single-paste-prompts.md))
- **Always subagent-driven plan execution** — After writing any plan, immediately dispatch subagent-driven development; never ask 'inline or subagent', never offer inline. ([user-subagent-execution](memory/facts/user-subagent-execution.md))

## Patterns
- **Read target + imports before dispatching a file-modifying agent** — Before dispatching any agent that edits an existing file, the coordinator reads that file and its direct imports and writes an explicit 'already exists — do NOT recreate' section; cap agent output ~300 words. ([pattern-agent-read-before-dispatch](memory/facts/pattern-agent-read-before-dispatch.md))

## Reference
- **KB-mined Claude Code best practices** — High-signal Claude Code rules mined from the Obsidian KB (Karpathy/Cherny/Kochel) not yet in the global MD chain — apply when relevant. ([user-kb-best-practices](memory/facts/user-kb-best-practices.md))

