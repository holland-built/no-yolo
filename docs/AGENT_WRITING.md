# Writing for Agents

> Rules for the text Claude reads: skill files, `CLAUDE.md`, the docs in this folder,
> subagent briefs. `ANTISLOP.md` is the twin of this file and covers prose a human reads.
> Where the two touch (fake precision, hype adjectives, code slop), that file is canonical and
> this one stays quiet; agent-facing text is still text, so its writing tells still apply.
> Every rule below says what goes wrong when it is broken, so a borderline line can be judged
> instead of pattern-matched.

## Prompt the positive

A prohibition drags the banned behaviour into context, where it becomes more available rather
than less. "Never write a comment that restates the line below it" makes comments the subject
of the paragraph. Write the behaviour you want in its place: comment the why.

Some rules genuinely only exist as prohibitions: a hard stop with no positive twin. Keep the
ban, and name the replacement behaviour in the same sentence, so the reader leaves the line
holding something to do.

## Leading words

One word can carry a whole pretrained concept. "Relentless" arrives with a behaviour already
attached; "be thorough, don't stop early, check every case" spends three clauses reaching the
same place and lands softer. Prefer words the model already has strong priors for over coined
terms and invented labels. A coined word has no prior, so it needs a definition, and the
definition is the cost you just paid.

When a line turns out to be a list of adjectives restating each other, refactor it into the
single word that carries them.

## Hunt no-ops

For every line, ask one question: does this beat what the model would do with no instruction
at all? If the answer is no, delete the sentence rather than trimming words inside it. A
shortened no-op is still a no-op, and it now reads as if someone considered it and kept it.

This repo ran that experiment on itself. 35 core rules were unloaded and left off; 8 earned
their way back. `CORE_RULES.md` records which ones and why each survived.

## Sediment

Every line costs context on each load, and the lines nobody re-reads accumulate: a note about
a bug that got fixed, a warning about a tool that's gone, an exception for a case that stopped
existing. Nothing evicts them, because nothing checks them.

Checking is the job. When you edit one of these files, re-read what is already in it and cut
what no longer describes the current system. A file nobody prunes turns into archaeology, and
then the reader has to date every line before trusting any of it.

## Progressive disclosure is a branching question

Ask whether every path through the doc needs this, or only some. What every path needs goes
inline. What only some paths reach goes behind a pointer, with the condition that leads there
stated before the destination.

`CLAUDE.md`'s condition-first list is this rule applied, and its own closing note records the
evidence: bare `topic → file` arrows read as a menu and got opened all at once, while the
conditional form got opened almost never.

## Completion criteria need clarity and demand

Two separate failures live here. The first is a vague bound, which causes stopping early.
Later steps are visible and pull attention toward being done, so anything short of an
unambiguous finish line gets read as finished.

The second is a criterion that is perfectly clear and costs nothing. "Produce a list of
affected files" is satisfied by a short list. "Account for every changed file, including the
ones you decided not to touch" cannot be satisfied without walking the diff, and walking the
diff was the actual goal. Write the criterion that fails unless the work happens.

## Co-location

A concept's definition, its rules, and its exceptions belong under one heading. Splitting them
across files to avoid repeating yourself is a lookup you have handed to the reader, and the
reader may not perform it. An exception filed somewhere else is an exception that does not
fire.

Cross-file pointers are for whole topics. When one idea is being split in half, keep the halves
together and move the pointer up a level.

## The environment is a source of truth

`package.json` names the scripts. `--help` prints the flags. The directory layout shows where
things live. A doc that restates one of those facts is a cache of it, and the cache goes stale
quietly, with no signal that it has.

A cache earns its context cost when the lookup is expensive. Cache the convention nobody wrote
down: why this repo puts a thing where it does, which of two plausible commands is the
sanctioned one, what the layout implies that it doesn't state. For the fact that is one command
away, name the command and let the reader run it, so the doc holds a pointer instead of a
snapshot.
