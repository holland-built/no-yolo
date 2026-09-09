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

**The model that wrote the code is a poor judge of it.** Get a second vendor's opinion at
the two points where being wrong is expensive.

| When | Run | Why |
| --- | --- | --- |
| Before committing to a plan or design | `codex exec` (below) | Catches unmeasured claims before they cost a build |
| After a substantial build | The Stop gate does this automatically | Fresh eyes that did not write it |
| Stuck, or a second attempt is needed | `/codex:rescue` | Delegated build work |

Do not confer for small, reversible edits. It costs a real round trip.

### Pick the model by size, not by subject

**`medium` is the ceiling. Never go above it.** Effort costs time, not money - astra prices
flat across every level - but higher is not automatically better, and the ceiling is a
deliberate choice.

| Input size | Model | Why |
| --- | --- | --- |
| Fits in 272k tokens | `gpt-5.6-sol` | Faster. Its own default is `low`, so set `medium` explicitly. |
| Larger than 272k | `gpt-6-astra` | 1.05M context. The only one that fits a big diff. |

Do not split on "documents versus code". That is a vibe. Size is a number.

```bash
codex exec --skip-git-repo-check --sandbox read-only \
  -c model=gpt-5.6-sol -c model_reasoning_effort=medium "<the prompt>" < /dev/null
```

`--skip-git-repo-check` is needed outside a git repo. `< /dev/null` is needed always, or it
waits forever for input.

**Reach for a better prompt before more effort.** The plugin's own guidance: *"Do not raise
reasoning or complexity first. Tighten the prompt and verification rules before escalating."*

### What does and does not carry effort

Verified in the plugin source, because two of these fail silently:

| Path | Model | Effort |
| --- | --- | --- |
| `codex exec -c ...` | yes | yes |
| `/codex:rescue` | yes | yes |
| The Stop gate | no - inherits `config.toml` | no - inherits `config.toml` |
| `/codex:review` | yes | **never**; the transport has no effort field |

`/codex:review --effort high` is silently ignored. Do not use it and assume it worked.

### Two rounds, then decide

**Cap the argument at two rounds.** One critique, one revision, one re-check. That is it.

If Codex still disagrees after two rounds, stop. Pick the better option yourself, do it, and
say in one line what you chose and what you overrode. A third round is two models restating
themselves.

Never hand the decision to Codex. It advises. You decide.

### Silence is not a pass

**A review that returns nothing has not passed. It has not run.**

The plugin records no outcome - its job files never store the model, the effort, or the
result. So an absent answer looks exactly like a clean one. Never report a review as passed
unless you read findings. If it timed out, ran out of tokens, or came back empty, say which.

### When Codex hangs

Codex gets stuck. Assume it will and do not let it block the work.

- Check with `/codex:status`. Kill it with `/codex:cancel`. Then carry on without it.
- Never wait on a Codex job. Do the rest of the task while it runs (rule 5).
- Two hangs on one task means stop conferring for that task. Note it and move on.

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
