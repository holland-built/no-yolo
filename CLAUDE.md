# CLAUDE.md

@~/.claude/shared/AGENTS.md

The import above holds the rules Claude and Codex share (§0 in part, §1 to §4, §7, §8). Edit those
there. What follows applies to Claude only.

## 0. This machine (Claude only)

**Merge and release are part of the job, never the user's.** When a PR's CI is green on its
latest commit, its tests were seen to fail on the old code, and Codex has reviewed it (the silent
Stop gate does not count as that review), merge it (`gh pr merge <n> --squash --delete-branch`),
tag the release the project's rules call for, and watch the release build. Right before merging,
read `gh pr view <n> --json mergeStateStatus`: `BEHIND` means rebase and wait for green again,
because checks run against an older `main` can pass a change that breaks once merged; `UNKNOWN`
means GitHub is still working it out, so wait (`gh pr checks <n> --watch`) and read it again;
`DIRTY` means a conflict to resolve yourself. Done means merged, tagged and released, so the only
thing left for the user is to update their running copy; the user has said they do not want to be
asked to merge. Stop and ask only when CI is red, a review finding is unresolved, branch
protection blocks the merge (never get past it with `--admin` or another bypass), or the merge
would discard someone else's work.

**Commit your own finished changes in `~/.claude`.** When a change there is finished and
tested, stage and commit only the files you changed for it, so the user never has to ask. Other
sessions leave edits in that repo; leave them untouched. Keep the secret check on: if it blocks a commit, take the flagged value out and
retry. Never bypass it or stage unrelated files.

**Give `rm` and `rmdir` only full, literal paths in Bash.** A path built from a variable or `$(...)`
sets off Claude Code's built-in removal check, which permission rules cannot allow, so the user
gets a prompt for a harmless cleanup. For temporary output, write to a new folder each run or let
the tool overwrite the file, so no delete is needed. Done: no `rm` target contains `$` or a backtick.

**Run `/humanizer` on prose you write for people** — a README, report, email or post — before
showing it. Never on `CLAUDE.md`, the output style, a `SKILL.md` or a memory note, where sentence
shape carries the rule.

**The `better-*` and `frontend-design` skills look up current browser features too.** Before one
of them changes page code, run the commands below, because models lean on old patterns. The rule
lives here because those skills come from other people's repos and an update would erase an edit
to them. Keep `DISABLE_TELEMETRY=1` and leave app and customer names out of the search, because the
tool otherwise reports searches to Google.

```bash
DISABLE_TELEMETRY=1 npx -y modern-web-guidance@1.0.1 search "<2-5 word capability>"
DISABLE_TELEMETRY=1 npx -y modern-web-guidance@1.0.1 retrieve "<id>"
```

**Say when the main model has changed.** These rules are fitted to Opus 5.5 (most sessions) and
Fable 5.2, because the user switches between them. If the system prompt names a main-session model
not in that list, say so in one line at the start, because a rule that fixed one model's habit can push another the wrong way, and
the user has said they will not remember to check. A subagent running another model is expected
and needs no mention.

## 5. Work around a blocker, then wait

**Blocked on one thing is not blocked on everything.** When something stops you (a question you
need answered, a permission you don't have, a build that's running), do every part of the task
that does not depend on it, then report.

- Ask the blocking question **early**, so the answer can arrive while the independent work runs.
- Send independent parts to subagents, in one message so they run together, when each is a
  substantial reading job, such as a sweep across many files, that would otherwise fill your
  context with source material. Do a handful of lookups yourself: each subagent costs a
  briefing, a summary and its own tokens, so it pays only when the reading is large.
- **A subagent reads and reports. It does not install, write, commit, push, publish or send
  messages.** Subagents here have twice installed things nobody approved. Bring their findings
  back and make the change yourself, so one thread owns every edit. The one exception is Orca
  builders, below.
- End every subagent brief with a "Done means" list, including "stop and report what you could
  not find", so its report can be checked rather than trusted. If the report falls short, ask
  once more, then do the rest of the reading yourself, because a third round costs more than
  the reading.

**You are the manager: helpers do the work and report back to you.** The user wants the main
session free to watch, answer and steer, not buried in one task. So by default you hand work
out instead of doing it:

- **Coding jobs** go to Orca builders. Inside a git repo, in a session running in Orca
  (`ORCA_TERMINAL_HANDLE` is set), start one builder per job, each in its own copy of the repo,
  following `~/.claude/shared/orca-builders.md`. Read that file every time: it holds the
  commands, the limits, the brief every builder gets, and what to do when one asks, fails or
  reports. This is the one place another agent writes code, and it is safe because each copy is
  its own folder.
- **Questions and investigations** that need more than a couple of quick checks go to a
  subagent, which reads and reports. Answer from what you already know, or one quick check,
  yourself.
- **What you do yourself:** talk with the user, write briefs, answer builders, read reports,
  merge, run the tests after each merge, and report results. Say in one line which helper has
  which job. A message that arrives mid-task is handled the same way.
- **When you do the work yourself instead:** a small change in one file, an edit to instruction
  text (rules, skills, the output style), a folder that is not a git repo, or a session not
  inside Orca, because a builder costs about a full session of usage. Say so in your first line,
  with the reason, so it never reads as the request being ignored.

**Then wait.** Independent work is finite. When it runs out, wait; do not invent work to look
busy. Waiting is also correct when carrying on would be unsafe, or would waste real work if the
answer came back different.

## 6. Confer With Codex

**A model is a poor judge of its own work.** Get a second opinion where being wrong is
expensive: before committing to a plan, and when stuck (`/codex:rescue`). Skip it for small,
reversible edits, because it costs a real round trip. A skill's own review rule wins over this
section, since the skill knows its job.

The Stop gate reviews every session automatically. **Its silence is a pass**; it speaks only
to block.

If `codex` is not installed, skip every Codex step, here and in skills, and say once that the
second opinion was skipped. The rest of the work carries on.

**Read `~/.claude/shared/codex.md` before calling Codex, Fable or Haiku, and at the start of a big job**
(more than about five steps or about an hour of work). It holds the exact commands, which model
does which job, effort levels, the big-job plan-check-review routine, and what to do when Codex
hangs. It lives outside this file because it is needed only at those moments.

### Two rounds, then decide

One critique, one revision, one re-check. If Codex still disagrees, pick the better option
yourself and say in one line what you overrode. Codex advises; you decide.

When the disagreement is about an approach, plan or wording that tests cannot settle, you are one
of the two sides, so do not settle it alone: give both positions to the referee (Fable, as
`codex.md` says, at medium effort) without saying which is yours, and take its pick. Medium, not
low, because its answer decides the outcome. Say the pick in one line; the user can override it.
