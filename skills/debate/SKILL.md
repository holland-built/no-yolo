---
name: debate
description: 6-persona product-team debate on any software decision — architecture, UI/UX, or feature priority. Senior Dev + Junior Dev + Sales Engineer + DevOps + Sales Leader + Eng Leader, then contradiction map, synthesis, and peer review.
user-invocable: true
---

# debate

Your product team argues your decision. You get the contradictions, the synthesis, and a self-graded briefing.

## Use cases

- Pick between competing architectures or UI designs
- Decide what to build next (feature prioritization)
- Test wording / copy / UX flow options
- Stress-test a technical or product decision before committing

## How to run

### Step 1 — Parse the argument

If no argument: ask "What decision, design, or feature do you want the team to debate?"

The argument can be:
- An architecture call: "microservices vs monolith for this service"
- A UI/UX choice: "which of these 3 dashboard layouts is better"
- A prioritization call: "build SSO or the reporting API next"
- A document, mockup, or plan (if user pastes it in)

### Step 2 — Six perspectives

Run all 6 in parallel as subagents (model: opus). Never inline — parallel is mandatory to prevent personas biasing each other. Each persona answers their 3 questions, then delivers their unique angle.

**THE SENIOR DEV** — guards the technical standard AND the design bar
- Does this hold up under load, edge cases, and the next 2 years of changes?
- Is this the simplest correct design, or are we adding accidental complexity?
- Does this meet our polish bar — consistent, modern, zero AI slop — or are we shipping something that looks generated?
- *Only they would say:* "This compiles and it's still not good enough — here's the standard it has to clear before it ships."

**THE JUNIOR DEV** — the new-user lens, simplicity enforcer
- Could someone who's never seen this codebase understand it in a week?
- What's the part of this I'd be scared to touch, and why?
- Is there a smaller, more obvious way to do this that we're overlooking?
- *Only they would say:* "I don't get why we need this — and if I don't, neither will the next new hire or the new user."

**THE SALES ENGINEER** — translates user needs into the platform story
- What actual customer problem does this solve, in their words not ours?
- How do I demo this to a prospect without it breaking or needing an asterisk?
- Does this fit how customers already use the platform, or does it force a new mental model?
- *Only they would say:* "Customers aren't asking for this — here's the request behind the request they're actually making."

**THE DEVOPS ENGINEER** — deployment, reliability, who runs this at 3am
- How does this get deployed, observed, and rolled back when it breaks?
- What's the failure mode, and who gets paged when it happens?
- What new operational cost (infra, on-call, maintenance) are we signing up for forever?
- *Only they would say:* "It works on your machine; tell me how it dies in production and who fixes it at 3am."

**THE SALES LEADER** — revenue, ROI, customer promises
- What's the revenue or retention impact, and how soon do we see it?
- What have we already promised customers that this does or doesn't deliver?
- Is this the highest-ROI thing the team could be doing right now?
- *Only they would say:* "I can sell this — or I can't — and here's the deal it wins or loses us this quarter."

**THE ENGINEERING LEADER** — team feasibility, debt, roadmap
- Can the team actually build and maintain this with who and what we have?
- What technical debt does this create or pay down, and is the trade worth it?
- What does saying yes to this cost us elsewhere on the roadmap?
- *Only they would say:* "Capacity is the real constraint — here's what we'd have to drop or delay to make room for this."

For each perspective output:
- Core position (2 sentences)
- Strongest supporting argument
- The one thing only they would say

### Step 3 — Contradiction map

1. Where do 2+ perspectives directly contradict? List each conflict with the specific claims that clash.
2. Which perspective has the strongest evidence? Which the weakest? Why?
3. What one question, if answered, would resolve the biggest contradiction?
4. What does EVERY perspective agree on? (Likely true — even opponents confirm it.)
5. What did NONE of the perspectives address? (The blind spot — often the most valuable finding.)

### Step 4 — Research briefing

1. **One-paragraph summary** — brief a CEO in 60 seconds, nuance not headline
2. **5 key findings** — ranked by reliability; note which perspectives support/challenge each
3. **Hidden connection** — one non-obvious link that only shows up across all 6 perspectives
4. **Actionable insight** — what should someone in the user's role actually DO differently? Specific.
5. **Frontier question** — the one question that, if answered, would change everything

### Step 5 — Peer review

1. **Confidence scores** — rate each of the 5 key findings 1–10 for reliability, explain each
2. **Weakest link** — least confident claim; what info would verify it?
3. **Bias check** — which perspective dominated the synthesis? Was one voice overrepresented?
4. **Missing perspective** — is there a 7th angle that would change the conclusions?
5. **Overall grade** — if a Stanford professor reviewed this, what grade and what would they fix?

### Step 6 — Final Decision

Do not run a new analysis. Collapse the synthesis from Steps 3–5 into one verdict and one reason. Output exactly one line, nothing after it:

> **Decision: [YES / NO / CONDITIONAL]** — [the single reason that outweighs everything else]

Rules:
- Pick ONE: YES, NO, or CONDITIONAL. Never "it depends."
- Give exactly one sentence — the single reason that outweighs all others, drawn from the strongest finding in Step 4 and its Step 5 confidence score.
- If CONDITIONAL, the reason must name the one condition that flips it to YES.
- No hedging, no caveats, no second sentence.

### Step 7 — ELI5 Summary

After the decision line, add a plain-English summary using exactly this structure:

**What this is:**
2–3 sentences. Explain the decision topic and conclusion like the reader has never heard of it. What problem was being debated? What did the team decide?

**What actually happens if you follow this:**
3–5 bullets. Concrete actions. Real verbs. "You write X", "You switch to Y when Z", "You avoid W because V."

**Watch out for:**
Only include if the decision has an irreversible, costly, or team-visible consequence. One line per risk. Skip this section entirely if nothing qualifies — no "nothing to worry about."
