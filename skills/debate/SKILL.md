---
name: debate
description: Use this skill when the user types /debate, says 'debate this', 'stress test this decision', 'get the team on this', or 'should we build this'. Seven-persona product-team debate — Senior Dev + Junior Dev + Sales Engineer + DevOps + Sales Leader + Eng Leader + Product Designer — Chairman oversight, contradiction map, synthesis, peer review. Flag `--ui` swaps in a 5-persona UI/UX panel grounded in the project's design docs.
user-invocable: true
argument-hint: "<topic or decision> [--ui]"
---

# debate

Your product team argues your decision. You get the contradictions, the synthesis, and a self-graded briefing.

## Flags

- `--ui` — swap the default 7 business/eng personas for the **UI/UX panel** (5 design-focused debaters, see Appendix A). Use for visual/interaction/layout/color/a11y decisions. Before running, read the project's design docs if present (`DESIGN.md`, `COLOR_CONTRACT.md`, `UIUX_CHECKLIST.md`, `MOCKUPS.md`, `tailwind.config.*`, token/CSS files) and feed them to every persona so they argue grounded in the project's own rules, not generic taste. Everything else (Chairman → Steps 3–8) runs unchanged.

No flag = default 7-persona product-team panel (Step 2 below).

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

### Step 2 — Seven perspectives

Run all 7 in parallel as subagents (model: opus). Never inline — parallel is mandatory to prevent personas biasing each other. Each persona answers their 3 questions, then delivers their unique angle.

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

**THE PRODUCT DESIGNER** — the human under pressure, UX/interaction lens
- What does the user see and do in the first 3 seconds of this surface, and does it match what they came to do?
- Where does cognitive load spike — how many states, choices, and interruptions stand between intent and done?
- Does the information hierarchy match the task's real priority, or does the layout advertise what was easiest to build?
- *Only they would say:* "Nobody in this room has watched a real user fail at this — here's the moment they give up, and no metric or refactor fixes what the screen itself is doing wrong."

For each perspective output:
- Core position (2 sentences)
- Strongest supporting argument
- The one thing only they would say

### Step 3 — Chairman's review

After all 7 personas return, run ONE more subagent (model: opus): **THE CHAIRMAN** — oversight, not an 8th opinion. The Chairman gets every persona's full output and steers the debate before synthesis. The Chairman never introduces new arguments — only rules on the ones presented.

The Chairman outputs exactly:
1. **Evidence rulings** — for each persona: ADMITTED (argument backed by evidence: code read, data cited, causal logic) or DISCOUNTED (assertion, vibes, lens-flattering claim). One line of reason each.
2. **Forced answers** — the 2 sharpest unanswered cross-examinations (e.g. "SE claims X; EngLeader's capacity point directly contradicts it — which survives?") with the Chairman's ruling on each.
3. **Steering order** — 3 bullets max: what the synthesis (Steps 4–6) MUST address, and any persona whose voice must be down-weighted for dominating without evidence.

Steps 4–6 are bound by the Chairman's rulings: DISCOUNTED arguments cannot appear as key findings.

### Step 4 — Contradiction map

1. Where do 2+ perspectives directly contradict? List each conflict with the specific claims that clash.
2. Which perspective has the strongest evidence? Which the weakest? Why?
3. What one question, if answered, would resolve the biggest contradiction?
4. What does EVERY perspective agree on? (Likely true — even opponents confirm it.)
5. What did NONE of the perspectives address? (The blind spot — often the most valuable finding.)

### Step 5 — Research briefing

1. **One-paragraph summary** — brief a CEO in 60 seconds, nuance not headline
2. **5 key findings** — ranked by reliability; note which perspectives support/challenge each. ADMITTED arguments only — the Chairman's DISCOUNTED rulings are binding.
3. **Hidden connection** — one non-obvious link that only shows up across all 7 perspectives
4. **Actionable insight** — what should someone in the user's role actually DO differently? Specific.
5. **Frontier question** — the one question that, if answered, would change everything

### Step 6 — Peer review

1. **Confidence scores** — rate each of the 5 key findings 1–10 for reliability, explain each
2. **Weakest link** — least confident claim; what info would verify it?
3. **Bias check** — which perspective dominated the synthesis? Was one voice overrepresented? Did the Chairman's rulings hold, or did a discounted argument leak back in?
4. **Missing perspective** — is there an 8th angle that would change the conclusions?
5. **Overall grade** — if a Stanford professor reviewed this, what grade and what would they fix?

### Step 6.5 — Cross-model check (xcheck)

Run the `xcheck` skill (Skill tool, `skill: "xcheck"`) on the Step 5 research briefing. Codex is an outside reviewer, not an 8th persona — Chairman rules still bind. ACCEPTED findings amend the briefing before Step 7; REJECTED findings go to the dissent block after the decision line. If Codex is unavailable, xcheck no-ops and Step 7 runs on the briefing as-is.

### Step 7 — Final Decision

Do not run a new analysis. Collapse the synthesis from Steps 4–6 into one verdict and one reason. Output exactly one line, nothing after it:

> **Decision: [YES / NO / CONDITIONAL]** — [the single reason that outweighs everything else]

Rules:
- Pick ONE: YES, NO, or CONDITIONAL. Never "it depends."
- Give exactly one sentence — the single reason that outweighs all others, drawn from the strongest finding in Step 5 and its Step 6 confidence score.
- If CONDITIONAL, the reason must name the one condition that flips it to YES.
- No hedging, no caveats, no second sentence.

### Step 8 — ELI5 Summary

After the decision line, add a plain-English summary using exactly this structure:

**What this is:**
2–3 sentences. Explain the decision topic and conclusion like the reader has never heard of it. What problem was being debated? What did the team decide?

**What actually happens if you follow this:**
3–5 bullets. Concrete actions. Real verbs. "You write X", "You switch to Y when Z", "You avoid W because V."

**Watch out for:**
Only include if the decision has an irreversible, costly, or team-visible consequence. One line per risk. Skip this section entirely if nothing qualifies — no "nothing to worry about."

---

## Appendix A — UI/UX panel (`--ui` flag)

Replaces Step 2's seven personas with these **five**. Run all 5 in parallel as subagents (model: opus), same rules — never inline. Each answers their 3 questions, then delivers the one thing only they would say. Then Chairman (Step 3) and Steps 4–8 run identically.

**Grounding (required before dispatch):** read any project design docs found (`DESIGN.md`, `COLOR_CONTRACT.md`, `UIUX_CHECKLIST.md`, `MOCKUPS.md`, `learnings.md`, `tailwind.config.*`, token/theme CSS). Pass the extracted rules (palette contract, named rules, density/type scale, banned aesthetics, both-theme requirement) into every persona's brief. If no design docs exist, personas argue from WCAG + the stated product context and say so.

**THE RESTRAINT AUDITOR** — palette / color-contract cop
- Does every color here earn its place, or is a hue encoding identity/decoration that should be neutral?
- Is the accent still rare — CTA / active-nav / selection / focus only — or is it leaking into chrome and data?
- Is anything a raw palette class or hex instead of a token, and does it hold in BOTH themes?
- *Only they would say:* "You added a color to mean identity. That's the exact move that got the last redesign called unprofessional — neutralize it."

**THE OPERATOR** — the real user under real conditions
- In the first 3–4 seconds on this surface, where does the eye go, and does it match what the user came to do?
- How many clicks/keystrokes from intent to done, and does anything break flow (modal, scroll, reflow, focus jump)?
- Is this glanceable and keyboard-first for someone working fast under pressure, or does it assume an unhurried mouse user?
- *Only they would say:* "I'm mid-conversation with 4 seconds of attention — tell me where my eye lands and how many clicks this costs, because that's the whole job."

**THE SPATIAL DESIGNER** — layout, information architecture, density, hierarchy
- Does the visual hierarchy match the task's real priority, or does it mirror the data model / what was easiest to build?
- Is grouping, alignment, and density doing the work (tier bands, baseline alignment, tabular-nums) or fighting the user?
- What's the affordance for every non-obvious control — is state (collapse/drag/active) legible without a click?
- *Only they would say:* "This layout advertises what was easiest to build, not the user's mental model of the thing on screen."

**THE ACCESSIBILITY ENFORCER** — AA contrast, keyboard, focus, both themes
- Does every text/UI pair clear WCAG AA in BOTH light and dark — including muted-foreground and disabled states?
- Can this be fully operated by keyboard: visible focus rings, aria-current, icon-only buttons labeled, focus not trapped/lost?
- Are state changes announced (live regions, toasts) and not conveyed by color alone?
- *Only they would say:* "It passes in light and I can prove it fails AA in dark at the exact ratio — here."

**THE DIAGNOSTICIAN** — symptom vs disease, blast radius (Independent-Diagnosis lens)
- The user's words describe a symptom — what's the actual underlying cause, and how far upstream is it?
- What's the minimum surgical change, and what's the blast radius / regression risk / duplicate-component trap?
- Is there a prior fix in `learnings.md` this would re-break, or a named rule this would violate?
- *Only they would say:* "You asked to fix what you see; the real defect is several components upstream — patching here just moves the bruise."
