# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" -> "Write tests for invalid inputs, then make them pass"
- "Fix the bug" -> "Write a test that reproduces it, then make it pass"
- "Refactor X" -> "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] -> verify: [check]
2. [Step] -> verify: [check]
3. [Step] -> verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Never Idle

**Blocked on one thing is not blocked on everything.**

When something stops you - a question you need answered, a permission you don't have, a
build that's running - do not stop and wait.

- Do every part of the task that does not depend on the blocked thing. Then report.
- Run independent work at the same time, not one after another.
- Ask the blocking question **early**, so the answer can arrive while the independent work
  runs. Do not save it for the end.

**Then stop.** Independent work is finite. When it runs out, wait - do not invent work to
look busy. Waiting is also correct when carrying on would be unsafe, or would waste real
work if the answer came back different.

## 6. Confer With Codex

**A model is a poor judge of its own work.** Get a second opinion where being wrong is
expensive: before committing to a plan, and when stuck (`/codex:rescue`). Skip it for small,
reversible edits - it costs a real round trip.

The Stop gate reviews every session automatically. **Its silence is a pass** - it speaks only
to block.

For everything else, call Codex directly:

```bash
codex exec --skip-git-repo-check --sandbox read-only \
  -c model=gpt-5.6-sol -c model_reasoning_effort=medium "<the prompt>" < /dev/null
```

`< /dev/null` is required, or it waits forever for input. Here, **empty output means it
failed** - report that, not a pass.

### Model and effort

**`medium` is the ceiling.** Size picks the model, not subject matter:

| Input | Model |
| --- | --- |
| Under 272k tokens | `gpt-5.6-sol` - its own default is `low`, so set `medium` |
| Over 272k | `gpt-6-astra` |

Reach for a sharper prompt before more effort. The plugin's own guidance: *"Do not raise
reasoning or complexity first. Tighten the prompt and verification rules before escalating."*

`/codex:review` takes `--model` but silently discards `--effort` - its transport has no effort
field, so it runs at whatever `config.toml` says. `codex exec` and `/codex:rescue` carry both.
The Stop gate carries neither and inherits `config.toml`.

### Two rounds, then decide

One critique, one revision, one re-check. If Codex still disagrees, pick the better option
yourself and say in one line what you overrode. Codex advises; you decide.

When it hangs: `/codex:status`, then `/codex:cancel`, then carry on. Two hangs on one task,
stop conferring for that task.

Two known causes of a hang, both avoidable:

```bash
codex exec --skip-git-repo-check ... < /dev/null
```

`--skip-git-repo-check` is required outside a git repo. Closing stdin with `< /dev/null` is
required always, or it sits waiting for input that never comes.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

---

## Agent skills

### Issue tracker

Issues live as GitHub issues in this repo, driven by the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical labels, each named after its role. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
