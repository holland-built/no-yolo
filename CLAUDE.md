# CLAUDE.md

@~/.claude/shared/AGENTS.md

The import above holds the rules Claude and Codex share (§0 in part, §1 to §4, §7, §8). Edit those
there. What follows applies to Claude only.

## 0. This machine (Claude only)

**Merge and release are part of the job.** When a PR's CI is green, its tests have been
seen to fail on the old code, and Codex has reviewed it, merge it
(`gh pr merge <n> --squash --delete-branch`), tag the release the project's rules call
for, and watch the release build. Green means green on the PR's latest commit with the branch
up to date: check `gh pr view <n> --json mergeStateStatus` right before merging, and if it is
`BEHIND`, rebase and wait for green again, because checks run against an older `main` can pass a
change that breaks once merged. Never merge with `--admin` or another bypass; a merge that branch
protection blocks is a reason to stop and ask. Do not hand the merge back to the user. "Done" means
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

**Say when the main model has changed.** These rules were last fitted to Fable 5.2. If the system
prompt names a different model for the main session, say so in one line at the start and offer
`/model-update`, because a rule that fixed one model's habit can push another the wrong way, and
the user has said they will not remember to check. A subagent running another model is expected
and needs no mention. `/model-update` updates the model name here when it runs.

## 5. Never Idle

**Blocked on one thing is not blocked on everything.**

When something stops you - a question you need answered, a permission you don't have, a
build that's running - do not stop and wait.

- Do every part of the task that does not depend on the blocked thing. Then report.
- Send independent parts to subagents, in one message so they run together, when each is a
  substantial reading job, such as a sweep across many files, that would otherwise fill your
  context with source material. Do a handful of lookups yourself: each subagent costs a
  briefing, a summary and its own tokens, so it pays only when the reading is large.
- **A subagent reads and reports. It does not install, write, commit, push, publish or send
  messages.** Subagents here have twice installed things nobody approved. Bring their findings
  back and make the change yourself, so one thread owns every edit.
- End every subagent brief with a "Done means" list, including "stop and report what you could
  not find", so its report can be checked rather than trusted. If the report falls short, ask
  once more, then do the rest of the reading yourself, because a third round costs more than
  the reading.
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
  -c model=gpt-6.1-sol -c model_reasoning_effort=medium "<the prompt>" < /dev/null
```

`< /dev/null` is required, or it waits forever for input. Here, **empty output means it
failed** - report that, not a pass.

### Model and effort

**`medium` is the ceiling.** Role picks the model, not input size:

`gpt-6.1-sol` for routine second opinions and the automatic review. Escalate explicitly for
consequential architecture, ambiguous debugging, or escalated review.

### Which model for which job

Treat models as colleagues and match them to roles. This is not a ranking, and a task is not
a leaderboard. Source: `vid-fable-vs-astra-app-build` in the vault, one practitioner's
current practice, n=1.

| Job | Reach for | Second choice |
|---|---|---|
| Thinking a problem through, design | Fable | `gpt-6-astra` for structure |
| Structure, speed, computer use, spreadsheets | `gpt-6-astra` | Fable for the design half |
| Cheap bulk work under supervision | Haiku in a subagent | Always inspected by a stronger model |
| Second opinion on a plan or a diff | `gpt-6.1-sol` at medium | Astra only when undoing it means rewriting, except its big-job roles below |

Use Haiku through the Agent tool's `model: "haiku"` override, which follows the current version,
for read-and-report work — searching, checking, listing — never for work that writes. Unclear
or cut-off work never goes to Haiku: recover the missing context in the main session first,
because a cheaper model guesses at the gap instead of asking.

When the shape of a thing is undecided, run the same brief past two models. The divergence is
the deliverable: it shows you what you had not decided.

### Big jobs: plan, check, review

A big job is one with more than about five steps or about an hour of work. On those, a mistake
found at the end costs the most, so three models look at it at different points:

| When | Who | Effort | Job |
|---|---|---|---|
| Before any work | Fable and Astra, briefed separately | medium | Each returns its own plan; where they differ is what is still undecided |
| After each major step | Fable or Astra, taking turns | low | One narrow question, below |
| After the last change | `gpt-6.1-sol` | medium | Review the final diff, as in "Two rounds, then decide" |

Fable is the Agent tool with `subagent_type: "Plan"`, `model: "fable"` and the effort from the
table, which this rule authorises. Astra is the `codex exec` command above with
`-c model=gpt-6-astra` and the effort from the table.

The step check works at low effort only because the question is narrow: give the plan, what this
step changed, and ask "Is anything off-plan or broken? Answer yes or no, then one line." A broad
"review everything" at low effort comes back as a confident pass that means little. A yes is checked
against the code before acting on it, and empty output is a failed check, not a pass. A step check
never replaces the final review.

Check `codex debug models` for which Codex models exist now - **not**
`~/.codex/models_cache.json`, which is written per-client-version and has already been wrong
once.

Reach for a sharper prompt before more effort. The plugin's own guidance: *"Do not raise
reasoning or complexity first. Tighten the prompt and verification rules before escalating."*
Raise effort only once a tightened prompt has also stalled: the same call failing twice, or two
fixes in a row leaving the tests red. Go up one level and stay within the ceiling above. A
denied permission, an empty search or a missing network is a blocker to clear, not a reason for
more effort.

`/codex:review` takes `--model` but silently discards `--effort` - its transport has no effort
field, so it runs at whatever `config.toml` says. `codex exec` and `/codex:rescue` carry both.
The Stop gate carries neither and inherits `config.toml`.

### Two rounds, then decide

One critique, one revision, one re-check. If Codex still disagrees, pick the better option
yourself and say in one line what you overrode. Codex advises; you decide.

When the disagreement is about an approach, plan or wording that tests cannot settle, you are one
of the two sides, so do not settle it alone: give both positions to Fable (Agent tool,
`subagent_type: "Plan"`, `model: "fable"`, `effort: "medium"`) without saying which is yours, and
take its pick. It runs at medium, not low, because its answer decides the outcome. Say the pick in one line;
the user can override it.

When it hangs: `/codex:status`, then `/codex:cancel`, then carry on. Two hangs on one task,
stop conferring for that task.

Two known causes of a hang, both avoidable: leaving out `--skip-git-repo-check` outside a git
repo, and leaving out `< /dev/null`, without which it sits waiting for input that never comes.
