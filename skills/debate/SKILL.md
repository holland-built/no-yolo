---
name: brief
description: 5-expert perspective research brief on any topic — UI choices, wording decisions, or research questions. Practitioner + Academic + Skeptic + Economist + Historian, then contradiction map, synthesis, and peer review.
user-invocable: true
---

# debate

Five experts argue your topic. You get the contradictions, the synthesis, and a self-graded briefing.

## Use cases

- Pick between competing UI designs or layouts
- Test wording / copy options
- Research a topic before committing to a direction
- Stress-test a decision or plan

## How to run

### Step 1 — Parse the argument

If no argument: ask "What topic, decision, or question do you want to debate?"

The argument can be:
- A topic: "microservices vs monolith"
- A decision: "which of these 3 UI mockups is better"
- A question: "should we rewrite this in TypeScript"
- A document or plan (if user pastes it in)

### Step 2 — Five perspectives

Run all 5 in parallel as subagents (model: "opus") or inline if context is tight. Each expert answers:

**THE PRACTITIONER** — works with this daily
- What do they know that academics miss?
- What practical realities are usually ignored?

**THE ACADEMIC** — has studied this for years
- What does the peer-reviewed evidence actually say?
- Where does evidence contradict popular belief?

**THE SKEPTIC** — thinks the mainstream view is wrong
- What is the strongest counterargument?
- What evidence do proponents conveniently ignore?

**THE ECONOMIST** — follows the money
- Who profits from the current narrative?
- What financial incentives shape the research?

**THE HISTORIAN** — has seen similar patterns before
- What historical parallels exist?
- What can we learn from how those played out?

For each perspective output:
- Core position (2 sentences)
- Strongest supporting evidence
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
3. **Hidden connection** — one non-obvious link that only shows up across all 5 perspectives
4. **Actionable insight** — what should someone in the user's role actually DO differently? Specific.
5. **Frontier question** — the one question that, if answered, would change everything

### Step 5 — Peer review

1. **Confidence scores** — rate each of the 5 key findings 1–10 for reliability, explain each
2. **Weakest link** — least confident claim; what info would verify it?
3. **Bias check** — which perspective dominated the synthesis? Was one voice overrepresented?
4. **Missing perspective** — is there a 6th angle that would change the conclusions?
5. **Overall grade** — if a Stanford professor reviewed this, what grade and what would they fix?
