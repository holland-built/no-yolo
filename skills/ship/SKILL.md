---
name: ship
description: Use this skill when the user types /ship, says 'ship this', 'ship it', 'push this', or 'commit and push'. Alias for /release — the one context-aware publish command that reads the repo-root SHIP.md and pushes to the right environment.
user-invocable: true
argument-hint: "[env: dev|staging|prod] [optional commit message] [--auto]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
---

# ship → alias for release

`/ship` is kept for muscle memory. The real logic lives in the `release` skill.

**When invoked:** immediately invoke the `release` skill (via the Skill tool) with the same arguments. Do nothing else here — `release` handles repo detection, the `SHIP.md` playbook, environment selection, gates, commit, and push.

See `~/.claude/skills/release/SKILL.md` and each repo's `SHIP.md`.
