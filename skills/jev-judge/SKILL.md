---
name: jev-judge
description: Get a tiebreaker when Claude and Codex (or an Opus helper) disagree about which approach, plan or wording is better. Scores each side's claims against criteria with TypeSafe's Jev model and says which side wins, or says ask the user. Use when Codex disagrees with you, when the user says tiebreaker, who is right, or judge this. Not for deciding whether code works; tests do that.
---

# jev-judge

Two models argue for different answers and the user is left to referee. Jev reads both sets of
claims and picks per criterion, so the user sees a short table instead of two essays.

## The constraints

**The verdict is advice. The user decides.** Jev's confidence measures how concentrated its
picks are, not how often it is right. So the script only reports a winner when both question
orders agree and confidence is at least the cutoff in `jev_judge.py`; anything else it hands back
as "ask the user". Never present a winner as settled.

**Never use it to judge whether code works.** Run the tests. Jev reads claims, not behaviour, so
it would confidently pick the side that argues better.

**The user approves the criteria before you run it.** Draft them, show them, wait. Jev answers
exactly the question it is given, and a badly chosen criterion gives a confident wrong answer.
Each one should be a plain sentence a stranger could check, such as "Works without a network".

**Each side's claims come from that side.** Get Codex's claims from Codex, with `codex exec` as
in `/build`, and your own from you. Show the user both lists word for word. If you write the other
side's claims, your slant goes in unseen.

**File each claim under the criterion it speaks to.** Jev sees only the claims filed under the
criterion it is judging, so a claim that speaks to two criteria is filed under both. A criterion
that neither side has claims for goes to the user and Jev is never asked. In testing, Jev picked a
side with full confidence on a criterion the claims did not mention, so the script checks for
evidence itself.

**Never print or copy the key.** The script reads `TYPESAFE_API_KEY`, or the file
`~/.config/typesafe/key`. When a call fails the script prints "Jev: couldn't tell" and the reason;
pass that on as it is. A failed call is not a tie.

## How to run it

Write the input to a scratch file, then run the script:

```bash
# judge the claims in the file and print the table
python3 ~/.claude/skills/jev-judge/jev_judge.py claims.json
```

```json
{"criteria": ["Works without a network", "Keeps the file format unchanged"],
 "a": {"name": "Claude", "claims": {"Works without a network": ["Stores data in one local file."]}},
 "b": {"name": "Codex",  "claims": {"Works without a network": ["Needs a server for sync."],
                                    "Keeps the file format unchanged": ["Reads the old format."]}}}
```

Claims are filed under the exact criterion text. A claim filed under text that is not in `criteria`
stops the run, so a typo cannot hide evidence.

The output lists every question Jev saw, one line per criterion, then either `ADVICE: <name>` or
`VERDICT: ask the user`. Show the user that output as printed.

## Done

The user has seen the criteria, both sides' claims, and the printed table, and has made the
decision. If the script says "ask the user", you asked.
