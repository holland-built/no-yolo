---
name: plan
description: Use this skill when the user types /plan, says 'plan this', 'help me think through', 'plan before we build', or 'interview me about'. Pre-build planning interview — extracts design decisions, edge cases, constraints one question at a time before any code.
user-invocable: true
argument-hint: "[describe the feature, system, or decision to plan]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
---

Planning topic: $ARGUMENTS

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one by one. For each question, provide your recommended answer. Ask questions **one at a time**.

If a question can be answered by exploring the codebase, explore it instead of asking.

---

## Checkpointing rule

After every answer, append it to `brainstorms/<topic-slug>-<YYYY-MM-DD>.md` (create the file and `brainstorms/` dir if needed). Format:

```markdown
# <topic> — <date>

## Decisions
- <decision>: <answer>

## Open flags
- <thing user couldn't answer / needs to look up>

## Q&A log
**Q:** <question>
**A:** <answer>

---
```

This guards against the model misremembering early answers as the context window fills.

---

## When to stop

Ask exactly as many questions as needed — no fixed count. 2 may be enough for a simple task; 15 may be needed for a complex system. Stop when the decision tree has no open branches.

When you believe every significant branch is resolved, **seek explicit agreement before proceeding.**

Output this structure exactly — no prose outside it:

```
**What we're building:**
[2–3 plain English sentences. What problem does this solve? What does it actually touch on the computer? No jargon.]

**What actually happens:**
- [concrete step — real verb, real file/system]
- [concrete step]
- [concrete step]

**Watch out for:**
[Only if something is irreversible, visible to others, or can't be undone. One line each. Skip section if nothing qualifies.]

**Decisions locked:**
- [decision]: [answer]
- [decision]: [answer]

**Open flags:**
- [thing to look up before /build runs]

Are we aligned? (yes / keep going / fix X)
```

- User says **yes** → write final summary to brainstorm file + gate
- User says **keep going** or corrects something → continue grilling, re-surface summary when ready
- Never self-declare complete — always wait for explicit "yes"

**Gate:** Agreement confirmed. Before dispatching, run the locked summary through the `better-prompt` skill (Skill tool, `skill: "better-prompt"`) to sharpen it and get its recommended skill route. Dispatch that recommended skill with the sharpened prompt — `/build` for a feature/system, `/design` for a UI-only ask, or whichever skill better-prompt names. Do NOT write any code from this output alone.

---

**Rule:** The fix for misalignment is friction applied to *you*, not the model. Friction here = questions you answer before a line of code is written. Front-loading this jumps first-iteration success from ~70% to ~90%.

---

## Independent Pre-Read Rule

Before the first question, **do not parrot the user's problem statement back.** Instead:
1. Read relevant code/files/graphify output independently.
2. Form your own diagnosis — what does the evidence say the actual problem is?
3. State your independent read *before* asking Q1: "Here's what I see in the code: [X]. My working theory is [Y]. Now let me probe the gaps..."
4. If your read differs from the user's description, name the conflict explicitly and ask about it first.

User problem descriptions are starting hypotheses, not specifications. The interview sharpens the real diagnosis — it doesn't rubber-stamp the initial complaint.
