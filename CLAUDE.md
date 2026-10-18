# CLAUDE.md

@~/.claude/shared/AGENTS.md

The import above holds the rules Claude and Codex share (§0 in part, §1 to §4, §7, §8). Edit those
there. What follows applies to Claude only.

## 0. This machine (Claude only)

**Merge and release are part of the job.** When a PR's CI is green, its tests have been
seen to fail on the old code, and Codex has reviewed it, merge it
(`gh pr merge <n> --squash --delete-branch`), tag the release the project's rules call
for, and watch the release build. Do not hand the merge back to the user. "Done" means
merged, tagged and released, so the only thing left for the user is to update their
running copy. Stop and ask only if CI is red, a review finding is unresolved, or the
merge would discard someone else's work.

**Commit your own finished changes in `~/.claude`.** When a change there is finished and
tested, stage and commit only the files you changed for it, so the user never has to ask. Other
sessions leave edits in that repo; leave them untouched, and let the guarded `no-yolo` sync push
what is shareable. Keep the secret check on: if it blocks a commit, take the flagged value out and
retry. Never bypass it or stage unrelated files.

**Run `/humanizer` on prose you write for people** — a README, report, email or post — before
showing it. Never on `CLAUDE.md`, the output style, a `SKILL.md` or a memory note, where sentence
shape carries the rule.

## 5. Never Idle

**Blocked on one thing is not blocked on everything.**

When something stops you - a question you need answered, a permission you don't have, a
build that's running - do not stop and wait.

- Do every part of the task that does not depend on the blocked thing. Then report.
- Run independent work at the same time, not one after another.
- When the independent parts do not need each other's results, send them to subagents in
  one message so they run together. Reading, searching and checking are the good cases.
- **A subagent reads and reports. It does not install, write, or commit.** Subagents here
  have twice installed things nobody approved. Bring their findings back and make the
  change yourself, so one thread owns every edit.
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

If `codex` is not installed, skip every Codex step, here and in skills, and say once that the
second opinion was skipped. The rest of the work carries on.

For everything else, call Codex directly:

```bash
codex exec --skip-git-repo-check --sandbox read-only \
  -c model=gpt-6-sol -c model_reasoning_effort=medium "<the prompt>" < /dev/null
```

`< /dev/null` is required, or it waits forever for input. Here, **empty output means it
failed** - report that, not a pass.

### Model and effort

**`medium` is the ceiling.** Role picks the model, not input size:

`gpt-6-sol` for routine second opinions and the automatic review. Escalate explicitly for
consequential architecture, ambiguous debugging, or escalated review.

### Which model for which job

Treat models as colleagues and match them to roles. This is not a ranking, and a task is not
a leaderboard. Source: `vid-fable-vs-astra-app-build` in the vault, one practitioner's
current practice, n=1.

| Job | Reach for | Second choice |
|---|---|---|
| Thinking a problem through, design | Fable 5.1 | `gpt-6-astra` for structure |
| Structure, speed, computer use, spreadsheets | `gpt-6-astra` | Fable for the design half |
| Cheap bulk work under supervision | Haiku 4.5 in a subagent | Always inspected by a stronger model |
| Second opinion on a plan or a diff | `gpt-6-sol` at medium | Astra only when undoing it means rewriting |

Haiku 4.5 is `claude-haiku-4-5-20251001`. Use it through the Agent tool's `model` override
for read-and-report work — searching, checking, listing — never for work that writes.

When the shape of a thing is undecided, run the same brief past two models. The divergence is
the deliverable: it shows you what you had not decided.

Most models default to a 272k window (`max_context_window` 872k, raisable), so input size
rarely separates them. Check `codex debug models` for what is actually available - **not**
`~/.codex/models_cache.json`, which is written per-client-version and has already been wrong
once.

Reach for a sharper prompt before more effort. The plugin's own guidance: *"Do not raise
reasoning or complexity first. Tighten the prompt and verification rules before escalating."*

`/codex:review` takes `--model` but silently discards `--effort` - its transport has no effort
field, so it runs at whatever `config.toml` says. `codex exec` and `/codex:rescue` carry both.
The Stop gate carries neither and inherits `config.toml`.

### Two rounds, then decide

One critique, one revision, one re-check. If Codex still disagrees, pick the better option
yourself and say in one line what you overrode. Codex advises; you decide.

When the disagreement is about an approach, plan or wording that tests cannot settle, run
`/jev-judge` instead of picking alone, because you are one of the two sides. Its pick is advice,
and the user can override it.

When it hangs: `/codex:status`, then `/codex:cancel`, then carry on. Two hangs on one task,
stop conferring for that task.

Two known causes of a hang, both avoidable:

```bash
codex exec --skip-git-repo-check ... < /dev/null
```

`--skip-git-repo-check` is required outside a git repo. Closing stdin with `< /dev/null` is
required always, or it sits waiting for input that never comes.
