---
name: handoff
description: Use when the owner types /handoff, says "hand this off", "save where we are", "I'm about to run out", "pick this up later", "write a handoff", or "I'm hitting the limit". Writes the session to a file a fresh session can resume from, and prints one command to start that session.
user-invocable: true
model: opus
effort: high
allowed-tools: [Bash, Read, Write, Grep, Glob]
---

# handoff

A handoff carries one thing above all others: **what the owner is trying to achieve, in
their own words.** Everything else is support.

A handoff that captured every technical detail and lost the goal sent a session confidently
in the wrong direction for a full day. That is the failure this command exists to prevent,
so the goal is written first and read first.

## 1. Find the goal

**Read `~/.claude/handoffs/.last-precompact` first, if it is there.** `hooks/precompact-handoff.sh`
writes it when the window compacted before anyone wrote a handoff, and it names the
pre-compaction transcript, which is where the owner's own words still are: this session's
visible history may be a summary of them. Quote from that transcript, not from the summary.
Delete the marker once this handoff is written, so the next one is not sent to a stale
transcript. No marker means nothing compacted unwritten, which is the ordinary case.

Scroll back to the owner's own words. Quote the sentence where they said what they wanted,
verbatim, including the messy phrasing. A tidied paraphrase drifts; the raw quote does not.

Several goals in one session: quote the one that outranks the others and say why. Goals that
changed mid-session: quote the current one and note what it replaced.

## 2. Pick where it lives

Default `~/.claude/handoffs/<date>-<slug>.md`.

Work that would delete or move the default location writes to `~/Desktop/` instead, and says
so in the file. A handoff inside the folder being deleted dies with it.

## 3. Write it, in this order

The ordering is the design. Anything below section 2 can be skimmed; the first two cannot.

```markdown
# <one line: what this session was for>

## The goal, in the owner's own words

> "<verbatim quote>"

| Part | What it means here |
|---|---|
| Outcome | <what exists when this is finished> |
| Approach | <how the owner wants it done, including anything they ruled out> |
| Done looks like | <the checkable condition> |

**This section outranks everything below it.**

## First action on resume

<One action. A command to run, or a file to read. Under two minutes.>

State the goal and this first action back in one line, then wait for a yes.

## Where we got to

| Piece | State |
|---|---|

## Decided in conversation, written nowhere else

<Each decision, with the reason. These are the ones no file records.>

## Tried and rejected

<What was attempted and why it failed, so the next session skips it.>

## Open, needs a decision

<Numbered. Each one names who decides and what turns on it.>
```

## 4. Rescue what exists nowhere else

Facts that live only in this conversation and belong to another repo: name them, name the
repo, and say they need writing from a session opened there.

Writing them from here counts as doing that project's work in this project's session, and
that has produced work in the wrong repo before.

## 5. Have Codex read it before the owner leaves

The one gate this command lacked until 2026-08-25. A handoff is judged by a session that does
not exist yet, and by then the person who could have said "you left out X" is gone. Nobody
grades their own work, and a handoff is exactly the artefact where the author cannot see the
gap: what got omitted is what the author still had in their head.

`rules/codex.md` holds the invocation. Ask for what is MISSING, not for a rewrite:

```bash
bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/codex.sh" "Read this handoff. A fresh session with no memory of the conversation must resume from it alone. No preamble. Output ONLY lines of the form: FINDING <n> | blocking|major|minor | <what a resuming session would not know> | <the line to add>. Maximum 6. If nothing is missing, output: NO FINDINGS. Hunt for: a goal that reads as a paraphrase rather than the owner's own words, a first action needing knowledge the file does not carry, a decision recorded without its reason, and any file or command named but not explained. $(cat <path>)"
```

Fold in confirmed findings. Record a one-line reason beside any rejected one, in the file.

Codex absent, timed out, or silent is reported as "Codex: did not run" with the reason, and
the handoff stands. `rules/codex.md` says why that rule belongs to the second opinion alone:
a second opinion that was unavailable leaves the first opinion intact.

## 6. Print one command

One copy-paste block, nothing around it:

```bash
claude "Read <path>. State the goal section and the First action back to me in one line, then on my yes, continue that work."
```

## Done

This command has finished when the file exists, its goal section quotes the owner verbatim,
its first action is doable in under two minutes, Codex has read it and every finding is either
folded in or refused with a reason in the file, and the start command is printed as a single
block.
