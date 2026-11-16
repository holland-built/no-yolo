# Orca builders: parallel coding jobs

Read by Claude when `~/.claude/CLAUDE.md` §5 sends two or more coding jobs to Orca. A builder
is an Orca orchestration worker (Claude or Codex) in its own child worktree, a separate copy of
the repo. The main session is the owner: it starts builders, answers them, merges their work
and reports to the user.

## Before starting

- **Check you are inside Orca.** `ORCA_TERMINAL_HANDLE` must be set. `orca status` is not
  enough: it also succeeds from a plain terminal whenever the Orca app is open, and a session
  outside Orca never hears back from its builders. Outside Orca, do the work yourself and say
  so in one line.
- **Load the `orchestration` skill** for the version-matched commands.
- **Copy the private files each builder needs.** A new worktree is a clean checkout, so
  gitignored files (`.env`, `secrets.yaml`, local config) are missing, and a builder without
  them fails its checks or invents values to get past them. The first time a repo gets
  builders, list the gitignored files its checks need (`git status --ignored --short` shows
  them) and add them to `.worktreeinclude` at the repo root, one literal path per line, with
  `#` comments allowed. Orca copies those into every new worktree. Commit that file. A secret
  the job must not touch goes in the brief as off-limits instead.
- **Commit this session's finished changes** (this rule authorises that commit), because each
  copy is cut from a commit and uncommitted edits are missing from every builder's copy.
- **Leftover builder copies clear themselves.** `~/.claude/tools/orca-sweep.py` runs every 15
  minutes from launchd and removes any child worktree whose branch is merged into the branch it
  came from, has no unsaved files, and has been idle for an hour. Its log is
  `~/.claude/state/orca-sweep.log`; name anything it keeps to the user when it matters.
- **At most 3 builders at once.** Each costs about a full session of usage, and many at once
  have overloaded the machine (Orca issue #24058). Queue the rest and start one as each
  finishes.

## Writing each brief

Write the brief to a scratchpad file, because the shell mangles quotes and backticks inside
`--spec`. Every brief contains:

1. **This opening, word for word:** "You are an Orca builder for one job. This brief overrides
   your CLAUDE.md: do not merge, push, tag or release, do not start Orca workers or subagent
   plans, do not run Codex reviews, and do not install anything. Commit on your own branch,
   then report with worker_done." Builders load the same `~/.claude/CLAUDE.md`, whose §0 says
   to merge and release, so without this line a builder may ship its own work.
2. **The files, and the part of each file** (function, section, element) the job may change.
   On a single-file page, also where its new CSS and JS go: beside that panel's existing code,
   not at the end of the style or script block, because two builders adding at the same end
   always conflict.
3. **Its own test target** (a test file name on a shared server, a port, an output folder, a
   test database), because worktrees separate the code, not what the code touches: two
   builders deploying to one test URL overwrite each other. The builder may upload to that
   target and nowhere else.
4. **The checks that prove it done.**
5. **How to ask:** "When you need anything from the user (a choice, a missing fact, a go-ahead),
   do not ask in your own tab, because the user watches the main chat, not yours. Send it to the
   coordinator with `orca orchestration ask --question "<one line: what you need>" --options
   "<a,b>"` when there are clear choices, then end your turn; Orca wakes you with the answer."
6. **The report it must send:** `worker_done` with `--outcome`, `--files-modified`, its branch
   name, its last commit hash, and the test output.

Jobs that change the same or neighbouring lines go into one builder's brief as steps in order,
not into two builders. Jobs that touch parts of a file well apart can go to separate builders,
because git merges separate parts on its own.

## Starting

For each job:

```text
orca orchestration worker-start --spec-file <brief-file> --worktree new-child --name <job> \
  --base-branch <the branch you are on> --agent <claude|codex> --setup skip
```

- `claude` unless the user names Codex.
- Leave out `--model` and `--effort` unless the user names a model; `--effort` is rejected
  without `--model`.
- `--setup skip` stops the repo's setup hooks, which can install things.
- A builder in a new worktree keeps its tab open on its own, so the user can watch it and
  talk to it.

Then write the Run id, and each builder's dispatch id, worktree, branch and test target, into
the session's handoff notes, because a new session cannot otherwise find the builders. It
resumes with `orca orchestration worker-list --run <id>` and
`orca orchestration inbox --terminal run:<id> --limit 50 --full`.

Say in one line which agent has which job, then end your turn. Orca wakes you; do not poll.

## When Orca wakes you

- **A question:** answer with `orca orchestration reply --id <message_id> --body "<answer>"`
  when the brief or the user's words settle it. Otherwise relay it to the user, then pass their
  answer back with the same `reply`. Finish your current edit first; the builder waits.
- **Anything that waits on the user** (a relayed question, a permission prompt in a builder's
  tab, a decision of your own) goes in this shape, at the top of your reply and in the `/short`
  style, because the user has said they often cannot tell whether a helper needs them or what
  it is asking:

  ```text
  Waiting on you: <helper name> needs <the one thing>.
  Reply: <the choices, or the exact words to type>
  ```

  One block per waiting item, nothing above them. A permission prompt cannot be relayed, so its
  block says which Orca tab to open and what to approve. Then also mark the waiting copy in
  Orca's sidebar, so the user sees it there too: `orca worktree set --worktree <selector>
  --unread --comment "Waiting on you: <the one thing>"`, and clear it with `--read --comment ""`
  once answered. End your turn after the blocks; Orca sends its notification when your turn
  ends.
- **A builder waiting on a permission prompt** (`worker-show` reports `agentWait`): a
  "Waiting on you" block naming its tab. Never answer it through its terminal.
- **A report:** first commit or finish your own current step, so the merge lands on a clean
  tree. Read the diff, merge that branch, and run the tests before merging the next, so a
  break points at one branch. A clean merge can still break behaviour, so the tests run every
  time. A failed outcome is a failure: send the fix with `orca orchestration send`, or tell
  the user. A merge conflict you resolve yourself.
- **An escalation, or a builder that exited or was lost:** do not rerun `worker-start`, which
  makes a new task and throws away the builder's commits. Follow the receipt's `next`, else
  load `recovery-and-cleanup.md` from the orchestration skill and retry the same task with
  `--task <task_id> --retry-of <dispatch_id>` in that builder's existing worktree. After three
  failed starts, stop and tell the user.
- **A builder's tab looks finished but no report came:** Orca has a known bug where the report
  is lost (issue #13364). Check it once with `orca orchestration worker-show`, which is not
  polling. Silence alone does not prove it failed.

Nothing goes live until every branch is merged and tested.

## Done

Each builder goes away once its work is merged and tested, because the user wants finished
helpers gone, not piling up as tabs and folders: release it with
`orca orchestration worker-release --dispatch <id>`, then remove its copy and branch with
`orca worktree rm --worktree branch:<its branch> --delete-branch`. Its work is already in your
branch, so nothing is lost. Keep a builder only when its work was not merged (it failed, or
the user is still talking to it in its tab) and name those to the user.

Then ship the merged result as one pull request: push your branch, `gh pr create --fill`, and
merge and release it under `~/.claude/CLAUDE.md` §0, then run any deploy step the project's README
names. Never push to `main` directly (a hook blocks it), and the user's done means live, not
merged on this machine.

Done is every branch merged, tests passing on the merged result, the result shipped, each builder's test target
removed, and every merged builder gone.
