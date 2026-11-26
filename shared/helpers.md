# Helpers: parallel coding jobs

Read by Claude when `~/.claude/CLAUDE.md` §5 hands coding jobs out. A helper is a Claude
subagent started with the Agent tool and `isolation: "worktree"`, so it works in its own copy of
the repo on its own branch. The main chat starts helpers, answers them, calls Codex, merges their
work and reports to the user. Orca does not coordinate any of this: the user decided on
2026-11-26 that the main chat runs the show between Claude and Codex, so never start Orca workers
(`orca orchestration ...`) or install Orca's skills, even inside the Orca app.

## Before starting

- **Commit this chat's finished changes** (this rule authorises that commit), because each copy
  is cut from a commit and uncommitted edits are missing from every helper's copy.
- **Name the private files each helper needs.** A new copy is a clean checkout, so gitignored
  files (`.env`, `secrets.yaml`, local config) are missing, and a helper without them fails its
  checks or invents values to get past them. List the ones its checks need (`git status
  --ignored --short` shows them) in the brief, with their full path in the main folder, and tell
  the helper to copy them in before it starts. A secret the job must not touch goes in the brief
  as off-limits instead.
- **Up to 6 helpers at once.** Many at once have overloaded the Mac before. Before starting a
  fifth, check `uptime` (load under about twice the core count) and `memory_pressure` (not
  critical), and queue the rest if it is struggling.
- **Get Codex's check list first** for each job, with the call in `skills/build/SKILL.md`
  ("Codex writes the checks before the code exists"). Helpers never call Codex themselves, so the
  main chat makes every Codex call and they all wait in the `shared/codex.md` queue.

## Writing each brief

Write the brief in the Agent call's prompt. Every brief contains:

1. **This opening, word for word:** "You are a helper for one job, working in your own copy of
   the repo. This brief overrides your CLAUDE.md: do not merge, push, tag, release or deploy
   (uploading to the test target named below is the one exception), do not start subagents or Orca workers, do not run Codex, do not install anything, and do not
   edit skill or setup files (anything under `~/.claude/skills`, `~/.agents/skills`,
   `~/.claude/shared`, `CLAUDE.md` or the output style). Commit on your own branch. Print no
   Done or Waiting on you banner; the main chat talks to the user." Helpers load the same
   `CLAUDE.md`, whose §0 says to merge and release, so without this line a helper may ship its
   own work.
2. **The files, and the part of each file** (function, section, element) the job may change.
   On a single-file page, also where its new CSS and JS go: beside that panel's existing code,
   not at the end of the style or script block, because two helpers adding at the same end
   always conflict.
3. **Its own test target** (a test file name on a shared server, a port, an output folder, a
   test database), because separate copies separate the code, not what the code touches: two
   helpers deploying to one test URL overwrite each other. The helper may upload to that target
   and nowhere else; this is the one exception to `CLAUDE.md` §5's rule that subagents never
   publish.
4. **The picked mockup**, when the job changes how a page looks: its file path and the part this
   helper must match, with "screenshot your result at the mockup's size beside the mockup and
   include both in the report; any difference is a bug" (`AGENTS.md` §7).
5. **The checks that prove it done:** the test files for the part it changes, any older tests on
   the same page, and Codex's check list, with: "Turn each check a new automated test can prove
   into a test, one at a time, each seen to fail before the code and pass after; where an
   existing test already proves a check, name it instead; show the rest working. Report which
   test or proof covers each check." A list from another model catches what the helper would
   miss in both its code and its tests. Then: "Do not run the full test suite; the main chat runs
   it once after merging," because helpers running the whole suite and the main chat running it
   again made every job pay twice (8 to 13 minutes a run on Wayfinder, 2026-11-25).
6. **How to ask:** "When you need anything from the user (a choice, a missing fact, a go-ahead),
   or a permission is refused, stop and report. Put QUESTION: (or BLOCKED: and the refused
   command) in one line, with the options if there are clear ones, just above your helper status
   line. The main chat asks the user and sends you the answer."
7. **The report it ends with:** what it changed, its branch name, its last commit hash, the
   test output, which test or proof covers each check, and what it could not do, then the helper
   status line from the Action First style.
8. **"Done means"**, written by you as the brief's last lines, so the helper is judged against
   criteria set before the work, including "stop and report what you could not find".

Jobs that change the same or neighbouring lines go into one helper's brief as steps in order,
not into two helpers. Jobs that touch parts of a file well apart can go to separate helpers,
because git merges separate parts on its own.

## Starting

Start every helper for the batch in one message: Agent tool, `subagent_type:
"general-purpose"`, `isolation: "worktree"`, `run_in_background: true`. Say in one line which
helper has which job, then take a job yourself or end the turn; a notification arrives when each
helper finishes, so do not poll. Write each helper's name or agent ID (what SendMessage needs), job, branch, copy path and test target into
the chat's handoff notes, because a new chat cannot otherwise find unfinished helpers; it finds
their copies with `git worktree list`.

The user cannot watch a helper the way they watched an Orca tab, so give a one-line update in the
main chat when a helper reports, asks, or fails.

## When a helper reports

- **A question:** answer it with SendMessage to that helper when the brief or the user's words
  settle it. Otherwise put it in the "Waiting on you" block (Action First rule 13) at the top of
  your reply, with every waiting question in that one block, and pass the answer back with
  SendMessage. Ask in that text block, not with the AskUserQuestion dialog, because the dialog
  freezes this chat until the user answers, and on 2026-11-17 three finished helpers sat
  unshipped for over an hour behind one question.
- **Finished work:** first commit or finish your own current step, so the merge lands on a clean
  tree. Read the diff, merge the helper's branch into yours, and run the tests. Codex's review of
  that diff gets the brief's check list, names any check or obvious case no test covers, and ends
  with its Set aside list; an uncovered one goes back to the same helper with SendMessage unless
  you decline it in one line with a reason. When several helpers have reported, merge them all
  and run the tests once; if that fails, test branch by branch to find the bad one. A clean merge
  can still break behaviour, so the tests run every time. A merge conflict you resolve yourself.
- **A refused permission (BLOCKED:):** it cannot be relayed, so put it in the "Waiting on you"
  block naming the command and what approving it would allow, or do that step yourself in the
  main chat when it is yours to do.
- **A failed coding job:** send the fix to the same helper with SendMessage, so its copy and
  context are kept. After three failed rounds, stop and tell the user. A reading report that
  falls short follows `CLAUDE.md` §5 instead: ask once more, then do the rest yourself.

**Ship each branch as soon as it is merged and tested; do not hold it for the others.** Give it
its own pull request under `CLAUDE.md` §0 and run the project's deploy step right away, because
the user wants to try each change while other helpers still work. Then tell the user what to
test, in plain everyday words with no code names or file names:

```text
------------------------- Live: test this -------------------------
<what changed, as the user would say it>
Try: <one thing to do, and where, on phone or computer>
```

Helpers never merge their work or deploy it live (their own test target aside): several of them share live files such as
`index.html`, and one owner keeps them from overwriting each other.

## Done

Each helper's copy goes away once its work is merged and tested, because the user wants finished
helpers gone, not piling up as folders: remove it with `git worktree remove <its path>` and
delete its branch with `git branch -d <its branch>`, both run from the main project folder,
never from inside the copy (a removal from inside its own copy on 2026-11-25 left the chat's
folder missing and blocked every tool until the user recreated it). Keep a copy only when its
work was not merged, and name it to the user.

Tell the user about every helper once it is settled, one line each:

```text
<helper>: done and live. Nothing for you.
<helper>: failed <n> times (<why, in plain words>). See the question above.
```

A failed helper's "retry, or drop it" goes in the "Waiting on you" block as a numbered question.
Then close the turn with the Done or Not done yet banner (Action First rule 12).

Done is every branch merged, tested and shipped live as it came in, each helper's test target
removed, and every merged helper's copy and branch gone.
