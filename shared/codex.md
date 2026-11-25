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
codex exec --ephemeral --skip-git-repo-check --sandbox read-only \
  -c model=gpt-6.1-sol -c model_reasoning_effort=medium "<the prompt>" < /dev/null
```

`< /dev/null` is required, or it waits forever for input, and `--skip-git-repo-check` is required
outside a git repo; leaving out either is what makes it hang. `--ephemeral` keeps the call out of
the Codex app's session list, which filled with thousands of one-off reviews without it. **Empty output means it failed**:
report that, not a pass. `codex debug models` lists the Codex models that exist now
(`~/.codex/models_cache.json` has been wrong before).

When a prompt carries long material (a document, log or transcript), put the material first and
the instructions and question last. Anthropic reports up to 30% better answers in its tests with
the question at the end. When the answer must rest on the material, ask for the exact supporting
quotes first, so each claim can be checked against the source.

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

**A big job keeps its step list in `checklist.json`,** beside `PLAN.md`: one entry per step with
`step`, `check` (the command or observation that proves it) and `passes`, which starts `false`.
Change `passes` to `true` only after that step's check has run and passed, and change nothing else
in the entry. A fresh session trusts this file, and Anthropic reports from its own experiments,
without a benchmark, that models are less likely to wrongly rewrite JSON than Markdown. `PLAN.md`
keeps the goal and decisions, so the steps live in one place.

**A big job that gathers information runs in two stages.** Start with short, broad searches and
list the options before comparing the best few, because detailed reading too early can miss a
better choice. One helper finds material up to a set limit, such as the top 50, and writes what
it kept and what it learned to a short file. A fresh helper starts from that file and improves only those items. Without the limit and the file, a long
run keeps collecting or repeats work, and what it learned never reaches the next helper. Done means
the second stage's result covers every kept item, each with its evidence.

## When it hangs

`/codex:status`, then `/codex:cancel`, then carry on. Two hangs on one task: stop conferring for
that task.

`shared/codex-watchdog.py` runs every 5 minutes (launchd `local.codex-watchdog`). It posts a Mac
notification when a Codex job passes 20 minutes or OpenAI answers "429 Too Many Requests", and
stops a read-only `codex exec` at 30 minutes, which reaches the caller as empty output. Its log is
`~/.claude/state/codex-watchdog.log`.

The Stop gate reviews only replies that changed files, through a local patch in the plugin's
`stop-review-gate-hook.mjs` (`lastTurnChangedFiles`). A plugin update replaces that file, so after
one, check the function is still there and copy it back if not.
