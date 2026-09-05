---
name: word-list
description: Use when the user types /word-list, or says "build my word list", "which words lose me", "make the check use my words". Reads their own saved sessions, finds the words they never use back, and writes the table the check reads.
user-invocable: true
disable-model-invocation: true
argument-hint: "[how many words to propose, default 20]"
allowed-tools: Bash,Read,Write,Edit
---

# word-list

Build the user's own word list from their own sessions. Never from a guess.

The check reads `~/.claude/CONTEXT.md`. This command writes that file.

## Step 1 — count

Run the script. It reads every saved session, counts what you wrote and what
they wrote, and prints the words you lean on that they never use back.

    python3 "$HOME/.claude/skills/word-list/scripts/find-words.py" \
      || python3 "$CLAUDE_PLUGIN_ROOT/skills/word-list/scripts/find-words.py"

The first path is where `install.sh` puts it. The second is where it lands if
they installed the add-on instead.

Two knobs, both optional: `MIN_MINE` (how often you used it, default 4) and
`MAX_YOURS` (how often they used it, default 0).

If the script finds no sessions, say so and stop. Do not invent a list.

## Step 2 — judge

The count finds candidates. It cannot tell jargon from an ordinary word, and it
must not try. That is your job, one word at a time.

**Keep a word** when a person outside this field would have to look it up, or
would guess the wrong meaning.

**Drop a word** when it is ordinary English, or a name for one of their own
projects. A project name is theirs. They own it, so they can read it.

Take the top `$ARGUMENTS` words, or 20 if they gave no number.

## Step 3 — write the plain word

For each word you keep, write what it does, in words the reader already owns.

The right column replaces the left in a sentence. So write a phrase, not a
definition. "the check", not "a script that inspects output".

## Step 4 — merge, never overwrite

Read the existing `~/.claude/CONTEXT.md` first.

- Keep every row already there. They chose those.
- Add your new rows underneath.
- If a word is already listed, leave their wording alone.

Write the file, then show them one table: the word, how often you used it, and
the plain word you propose. They cross out what they disagree with.

## Step 5 — prove it

Run the check against a sentence holding one of the new words:

    printf '{"last_assistant_message":"<sentence>"}' | bash ~/.claude/hooks/reply-check.sh

It must block, and it must name the plain word. Show that output. If it does not
block, the row is malformed. Fix it before you say the job is done.
