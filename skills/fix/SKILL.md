---
name: fix
description: "Use when the user says fix, broken, failing, erroring, crashed or slow, or pastes an error or a failing command, even when the fix looks like one line, because a guessed fix without a reproduction is what this stops. Reproduces, shows the cause, fixes, shows it working. A page that looks or behaves wrong without an error goes to /improve."
---

# fix

Fix the thing. This file carries only the constraints, because the failure mode here is not
ignorance — it is confidence.

## The constraints

**Get a repeatable reproduction before you change any code.** A command that goes red on
this bug and green when it is gone. Reading code to build that reproduction is fine; reading
code *instead* of building it is the mistake. Paste the command and its real failing output.

If you cannot build one, say so and say what you tried. A change made without a reproduction
is a guess, and it must never be reported as a fix.

**Show the cause, do not argue it.** Use experiments that tell competing explanations apart,
and say what you expected versus what happened. You have it when you can name in one sentence
why the reproduction was red, and you have demonstrated that.

**When the investigation stops producing new evidence, get a second read** rather than trying
harder. Write the symptom, the reproduction, and what is ruled out and how to
`/tmp/fix-second-read.md` with the Write tool first. Free text goes in a file, never inside the
quoted prompt, because a backtick or `$(...)` in an error message would run in the shell, and
`codex-exec.py` gives Codex no stdin to pass it through.

```bash
python3 -I ~/.claude/shared/codex-exec.py --skip-git-repo-check --sandbox read-only \
  -c model=gpt-6.1-sol -c model_reasoning_effort=medium \
  "Read /tmp/fix-second-read.md. What would you check next?" < /dev/null
```

`< /dev/null` is required. Empty output means it failed, not that it agreed. If you are Codex, that
command would ask your own model again, so hand the evidence to the user for Claude's read instead.

**Correct the cause, and stop there.** The change is limited to what fixing the demonstrated
cause requires — not the smallest possible patch, and not a tidy-up of the code around it. A
fix buried inside a cleanup cannot be reviewed.

Inside that limit, write the least code that corrects it. Prefer what the project already
uses, then the standard library, then a dependency already installed. Never cut input checks,
data safety, security or accessibility to make the fix smaller — those fail silently. When the
bug sits in shared code, search its callers before changing it. Leave nearby code, comments and
formatting alone; mention unrelated dead code rather than deleting it. This is here because
evals run without `~/.claude/CLAUDE.md`, so the skill has to carry it.

When the fix changes page code, look up the current browser feature first, because models lean
on old patterns and a native feature can be the smaller fix:

```bash
DISABLE_TELEMETRY=1 npx -y modern-web-guidance@1.0.1 search "<2-5 word capability>"
DISABLE_TELEMETRY=1 npx -y modern-web-guidance@1.0.1 retrieve "<id>"
```

Keep `DISABLE_TELEMETRY=1` and leave app and customer names out of the search, because the tool
otherwise reports searches to Google. The reply does not mention this unless a guide changed what
the user will see.

**Never make the reproduction pass by changing the reproduction.** Loosening a test or its
expected output hides the bug instead of fixing it. If the check itself was wrong, say so and
show why before touching it.

**Stop after three attempts at the same cause.** Say what each attempt showed and hand it to
the user, or get the second read above. More attempts past that rarely add evidence.

**Codex reviews the final diff**, because the fix you just wrote is the one you are worst
placed to judge. Mark new files so the diff shows them, and check it is not empty. Write the
symptom and the reproduction (the command and its failing output) to `/tmp/fix-review-brief.md`
with the Write tool, and leave your diagnosis out, because a reviewer handed the conclusion tends
to agree with it. Over about 400 lines, split the diff by file and send one call per part,
because a reviewer cannot hold a big diff in one read and misses things:

```bash
git add -N .
git diff <base> > /tmp/fix-review.diff
python3 -I ~/.claude/shared/codex-exec.py --skip-git-repo-check --sandbox read-only \
  -c model=gpt-6.1-sol -c model_reasoning_effort=medium \
  "Read the symptom and reproduction at /tmp/fix-review-brief.md, then review the diff at /tmp/fix-review.diff. Find what is wrong with it: does it make that failure go away without hiding it, and does it break anything a caller relies on? Flag code the fix does not need. Also look at the tests in the repo, not only those in the diff, and name any obvious case of this bug (another input that fails the same way, a caller that relies on the changed behaviour) that no test covers. Where the brief says nothing, judge by what a reasonable person using it would expect; silence is not permission. Ignore style. Label each blocker, should or nit. None is a valid answer. End with a Set aside list: one line per behaviour you chose not to judge as out of scope." < /dev/null
```

Read the Set aside list too, so nothing is dropped silently.

Check each finding against the code yourself. Judge it by what it costs if left: anything that
loses data, exposes a secret or leaves the bug in place gets fixed; the rest is declined in one
line, because a fix that grows during review stops being reviewable. An uncovered case Codex
names is a blocker unless declined in one line with a reason, because you wrote both the fix and
its test, so a case you missed is missing from both. Two rounds at most; a
blocker still open after that means not fixed. If `codex` is missing or fails, or you are Codex,
say "Codex review: couldn't tell" and why — never report a review that did not happen.

**Show it working.** The reproduction going green, pasted. Then the real thing running — the
script, the page, the command the user actually runs — pasted too. If you could not run it,
or ran it and could not tell whether it worked, it is not fixed yet: say "unverified" or
"couldn't tell" and why, and never call it fixed, even with a caveat attached.

## Done

- The reproduction went red before and green after, and both are on screen
- You can name the cause in one sentence, and you showed it
- The change covers the cause and nothing else
- The real thing ran, not only its test
- Codex reviewed the final diff with no blocker left open, or you said why it could not

If one of those is false, say which, and why. That is a better answer than a fix you cannot
stand behind.

## Excuses to catch

Each of these has sounded reasonable mid-session and led to a fix that was not one. When you
hear yourself think the left column, do the right one.

| The excuse | What to do instead |
|---|---|
| The cause is obvious, so the reproduction can wait | Build it anyway. Guessed causes have twice sent fixes after a problem that wasn't there |
| It's one line, so it doesn't need the Codex review | One line can still break a caller; the review runs on every final diff |
| The test was wrong, so I'll adjust it | Show why the check was wrong first, or it only hides the bug |
| It should work now | Not run means unverified. Run the real thing and paste it |
