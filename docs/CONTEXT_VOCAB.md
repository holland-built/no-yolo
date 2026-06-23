# Context Vocabulary

Shared concept names for this setup. Name a concept here once — then reference it by name in any prompt to save ~½ the tokens needed to explain it each time.

**How to use:** When starting work on a project, paste or reference the relevant terms. Claude reads this file and treats the names as established vocabulary.

---

## ~/.claude/ system terms

| Term | Meaning |
|---|---|
| skill | A custom Claude Code command defined by a SKILL.md file in `~/.claude/skills/<name>/` |
| pending queue | `~/.claude/.pending-tasks.md` — session task list read by `/whats-next` |
| handoff block | HANDOFF section in `brainstorms/<slug>-plan-<date>.md` written by `/plan-feature` on approval |
| fact file | A memory record in `~/.claude-work/projects/-Users-sholland/memory/facts/*.md` |
| compiled preferences | `memory/CLAUDE.generated.md` — auto-built from fact files by `/memory-compile` |
| slop | AI-generated visual or prose patterns that look generic/templated — defined in `ANTISLOP.md` |
| brainstorm file | Planning artifact written to `brainstorms/` by build/plan skills |
| gateguard | Pre-edit hook that requires stating facts before modifying key files |

## Project-specific terms

Add project-specific vocabulary here when working on a project. Delete after the project is done.

<!-- Example:
| materialization cascade | The sequence of events when a topology node transitions from pending → active → verified |
| floating island header | The location-group card header pattern in TopologyTree.tsx using `relative pt-3 px-2` |
-->

---

## Usage pattern

When a prompt needs to reference a complex concept from this file:

```
[using context from CONTEXT_VOCAB.md] 
Fix the handoff block in brainstorms/my-feature-plan-2026-06-22.md — 
status should be "approved" not "pending".
```

The bracketed reference tells Claude to treat the term as already defined, cutting the explanation.
