# Calling Codex and Fable

Read by Claude when `~/.claude/CLAUDE.md` §6 sends it here: before calling Codex or Fable, and at
the start of a big job. Skills point here instead of copying these commands, so a model change
means editing one file.

## The roles and how to call each

| Role | Who | How |
|---|---|---|
| Reviewer: routine second opinions, final diff review | `gpt-6.1-sol` | the command below |
| Structure, speed, computer use, spreadsheets; big-job planner | `gpt-6-astra` | the command below with `-c model=gpt-6-astra` |
| Thinking a problem through, design; big-job planner; referee | Fable | Agent tool, `subagent_type: "Plan"`, `model: "fable"`, effort as the job says (this rule authorises it) |
| Cheap read-and-report work (search, check, list) | Haiku | Agent tool, `model: "haiku"`; a stronger model checks its result; never work that writes, never unclear or cut-off work, because a cheaper model guesses at a gap instead of asking |

Treat models as colleagues matched to roles, not a ranking.

```bash
codex exec --skip-git-repo-check --sandbox read-only \
  -c model=gpt-6.1-sol -c model_reasoning_effort=medium "<the prompt>" < /dev/null
```

`< /dev/null` is required, or it waits forever for input, and `--skip-git-repo-check` is required
outside a git repo; leaving out either is what makes it hang. **Empty output means it failed**:
report that, not a pass. `codex debug models` lists the Codex models that exist now
(`~/.codex/models_cache.json` has been wrong before).

When the shape of a thing is undecided, run the same brief past two models. Where they differ is
what you had not decided.

## Effort

`medium` is the default, never `max`. Reach for a sharper prompt before more effort; the Codex
plugin's own advice is to tighten the prompt and the checks first. Go to `high` once, and only
when a tightened prompt has also stalled (the same call failing twice, or two fixes in a row
leaving the tests red) on a hard bug or a design that would be costly to undo, because routine
work gains nothing and a thin spec at high effort over-builds. A denied permission, an empty
search or a missing network is a blocker to clear, not a reason for more effort.

`/codex:review` takes `--model` but silently discards `--effort` (it runs at whatever
`config.toml` says). `codex exec` and `/codex:rescue` carry both. The Stop gate carries neither.

## Big jobs: plan, check, review

On a job of more than about five steps or an hour, a mistake found at the end costs the most, so
three models look at it at different points:

| When | Who | Effort | Job |
|---|---|---|---|
| Before any work | Fable and Astra, briefed separately | medium | Each returns its own plan; where they differ is what is still undecided |
| After each major step | Fable or Astra, taking turns | low | One narrow question, below |
| After the last change | the reviewer | medium | Review the final diff |

The step check works at low effort only because the question is narrow: give the plan and what
this step changed, and ask "Is anything off-plan or broken? Answer yes or no, then one line." A
broad "review everything" at low effort comes back as a confident pass that means little. Check a
yes against the code before acting on it; empty output is a failed check. A step check never
replaces the final review.

## When it hangs

`/codex:status`, then `/codex:cancel`, then carry on. Two hangs on one task: stop conferring for
that task.
