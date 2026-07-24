---
name: debate
description: Use this skill when the user types /debate, says 'debate this', 'stress test this decision', or 'get the team on this'. Seven-persona product-team debate — Senior Dev + Junior Dev + The Alternative + DevOps + The Prioritizer + Eng Leader + User Advocate — Chairman oversight, contradiction map, synthesis, peer review. Both panels ground personas in an in-memory project primer (built fresh per run from the repo's own docs, never written to disk) so they argue against your real codebase, not generically. Flag `--ui` swaps in a 6-persona UI/UX panel (7th seat joins on ranking asks) grounded in the project's design docs and installed design skills.
user-invocable: true
argument-hint: "<topic or decision> [--ui]"
---

# debate

Your product team argues your decision. You get the contradictions, the synthesis, and a self-graded briefing.

## Flags

- `--ui` — swap the default 7 business/eng personas for the **UI/UX panel** (5 design-focused debaters, see Appendix A). Use for visual/interaction/layout/color/a11y decisions. Before running, read the project's design docs if present (`DESIGN.md`, `COLOR_CONTRACT.md`, `UIUX_CHECKLIST.md`, `MOCKUPS.md`, `tailwind.config.*`, token/CSS files) plus installed knowledge — the `emil-design-eng` skill's rules (`~/.claude/skills/emil-design-eng/`), `~/.claude/docs/ANTISLOP.md` → `## GUI Slop`, `~/.claude/docs/UI_MOCKUPS.md`, and the `dataviz` skill's references when the surface includes charts/dashboards — and feed all of it to every persona so they argue against these standards, not generic taste. Everything else (Chairman → Steps 3–8) runs unchanged.

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

### Step 1.5 — Project primer (grounding, in-memory)

Personas must argue against THIS project, not generic taste. Before dispatch, the coordinator builds a project primer **in memory and passes it into every persona brief** — nothing is written to disk. No cache file, no staleness gate, no committed artifact: the regeneration cost is a rounding error next to seven Opus personas, and a persisted `.debate-primer.md` would drift, churn git, and violate this library's derive-don't-store convention (decided by `/debate` on 2026-07-24).

Build it from the human-owned digests only — do NOT read the whole codebase:
- `CLAUDE.md`, `README*`, `docs/` architecture files, `DESIGN.md` / design tokens, and top-level source-dir names for shape (not full contents).
- Plus `~/.claude/docs/CORE_RULES.md` for the project's standards.

Distill to a **single sectioned primer** (≤150 lines held in context): current architecture, stack, conventions, active constraints, project standards, and — as its own **Design section** — any tokens/design docs found. One primer serves both panels; split into a separate design primer only if a real `--ui` run visibly starves for design grounding (falsifiable trigger, not by default).

For a large repo, keep the digest reads scoped to the debate topic. If the digests are trivial or absent (tiny/new repo), ground in `CORE_RULES.md` + the stated context and say so. The same in-memory primer is injected into every persona brief in Step 2 and Appendix A.

### Step 2 — Seven perspectives

Run all 7 in parallel as subagents (model: opus). Never inline — parallel is mandatory to prevent personas biasing each other. **Each persona's brief includes the Step 1.5 project primer** so they argue against this codebase, not in the abstract. Each persona answers their 3 questions, then delivers their unique angle.

**Sharpening contract (binds every persona, both panels).** A persona is only as smart as what it's forced to cite. Put this in each brief:
- **Ground every claim in a specific fact** — a file/symbol from the primer, a named rule (`CORE_RULES.md`, the project's own standards), or a concrete failure scenario. An assertion with no anchor is DISCOUNTED by the Chairman (Step 3), so vibes cost the persona its vote.
- **Judge against THIS project's bar, not generic taste** — name the standard, benchmark, or prior decision you're measuring against; "I don't like it" is not an argument, "it violates rule X / the primer says Y" is.
- **Lead with your evidence lane (soft, not gagged)** — each seat argues primarily from its own evidence class so the panel can't homogenize: DevOps→failure/operational facts, Prioritizer→value-vs-effort and what-it-displaces, Eng Leader→team capacity/debt/ownership, User Advocate→user-outcome/JTBD, Senior Dev→standards/2-year durability, Junior Dev→newcomer-legibility. UI panel seats already carry natural lanes (color-contract, layout/hierarchy, a11y ratios, named-benchmark). You MAY flag a cross-cutting point outside your lane, but lead with yours. The Chairman (Step 3) flags any two seats citing the *same* evidence for the *same* claim — that's collapse, and the weaker of the two is down-weighted.
- **Argue past the strawman** — deliver the one thing only your role sees; engage the strongest version of the opposing case, not the weakest.

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

**THE ALTERNATIVE** — steelmans the strongest competing approach
- What's the strongest approach we are NOT taking, and what's its best case if executed well?
- What would have to be true in 6 months for the alternative to clearly beat what's proposed here?
- If we pick wrong, what's the switching cost to change course later?
- *Only they would say:* "I'm the approach you rejected — here's the strongest version of me, beat THAT, not the strawman."

**THE DEVOPS ENGINEER** — deployment, reliability, who runs this at 3am
- How does this get deployed, observed, and rolled back when it breaks?
- What's the failure mode, and who gets paged when it happens?
- What new operational cost (infra, on-call, maintenance) are we signing up for forever?
- *Only they would say:* "It works on your machine; tell me how it dies in production and who fixes it at 3am."

**THE PRIORITIZER** — value vs. effort, opportunity cost
- What's the value per unit of effort here, compared to everything else on the table right now?
- What does doing this displace — what doesn't get done because this does?
- If we could only ship half of this, which half earns its place?
- *Only they would say:* "Everything here is worth doing — that's not the question. Rank it against what you're NOT doing."

**THE ENGINEERING LEADER** — team capacity, debt, ownership (NOT opportunity cost — that's the Prioritizer's lane)
- Can the team actually build and maintain this with who and what we have?
- What technical debt does this create or pay down, and is the trade worth it?
- Who owns this after it ships — is there a named maintainer, or does it rot the first time it breaks?
- *Only they would say:* "Capacity and ownership are the real constraint — a thing no one on the team can maintain is a liability the day its author moves on."

**THE USER ADVOCATE** — the outcome / job-to-be-done lens (not pixels)
- What job did the user hire this for, and does this decision move that outcome or just our internals?
- What breaks in the user's real workflow if we ship this — and would they even notice the thing we're debating?
- Are we solving the user's problem or our own (elegance, tidiness, resume-driven design)?
- *Only they would say:* "None of your seven agree on the code, and the user doesn't care which of you wins — here's the outcome they came for, and whether any option on the table actually delivers it."

For each perspective output:
- Core position (2 sentences)
- Strongest supporting argument
- The one thing only they would say

### Step 3 — Chairman's review

After all 7 personas return, run ONE more subagent (model: opus): **THE CHAIRMAN** — oversight, not an 8th opinion. The Chairman gets every persona's full output and steers the debate before synthesis. The Chairman never introduces new arguments — only rules on the ones presented.

The Chairman outputs exactly:
1. **Evidence rulings** — for each persona: ADMITTED (argument backed by evidence: code read, data cited, causal logic) or DISCOUNTED (assertion, vibes, lens-flattering claim). One line of reason each. **Collapse check:** if two seats reached the same claim citing the same evidence (not just the same conclusion via different lanes), name the pair and down-weight the weaker — that is persona collapse, the failure this panel exists to avoid.
2. **Forced answers** — the 2 sharpest unanswered cross-examinations (e.g. "SE claims X; EngLeader's capacity point directly contradicts it — which survives?") with the Chairman's ruling on each.
3. **Steering order** — 3 bullets max: what the synthesis (Steps 4–6) MUST address, and any persona whose voice must be down-weighted for dominating without evidence.

Steps 4–6 are bound by the Chairman's rulings: DISCOUNTED arguments cannot appear as key findings.

### Step 4 — Contradiction map

1. Where do 2+ perspectives directly contradict? List each conflict with the specific claims that clash.
2. Which perspective has the strongest evidence? Which the weakest? Why?
3. What one question, if answered, would resolve the biggest contradiction?
4. What does EVERY perspective agree on? (Likely true — even opponents confirm it.)
5. What did NONE of the perspectives address? (The blind spot — often the most valuable finding.)

### Step 4.5 — Codex blind-spot check

Skip silently if `command -v codex` fails. Otherwise make ONE bounded call:

```bash
bash ~/.claude/skills/xcheck/scripts/codex-run.sh -m gpt-5.6-sol -s read-only "Here is a contradiction map from a multi-persona debate: <paste Step 4 output>. Name up to 3 important considerations ALL personas missed. One line each, no preamble."
```

Claude adjudicates each returned item under the Chairman's evidence rules (Step 3): ADMITTED items join Step 4's blind-spot list (item 5); DISCOUNTED items are dropped with a one-line reason. Codex critiques, never authors a persona position — one call max.

### Step 5 — Research briefing

1. **One-paragraph summary** — brief a CEO in 60 seconds, nuance not headline
2. **5 key findings** — ranked by reliability; note which perspectives support/challenge each. ADMITTED arguments only — the Chairman's DISCOUNTED rulings are binding.
3. **Hidden connection** — one non-obvious link that only shows up across all 7 perspectives
4. **Actionable insight** — what should someone in the user's role actually DO differently? Specific. End by naming which installed tool executes it (e.g. `/design` fresh UI, `/design-audit` find problems, impeccable plugin polish existing UI, `/design component-pull` add an element, `/build` feature, `/plan` interview) — every debate ends pointed at a tool, not just a verdict.
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

Replaces Step 2's seven personas with these **six**. Run all 6 in parallel as subagents (model: opus), same rules — never inline. Each answers their 3 questions, then delivers the one thing only they would say. Then Chairman (Step 3) and Steps 4–8 run identically.

**Also inject the Step 1.5 project primer** into every persona brief here, on top of the design grounding below — the UI panel argues against both the codebase and the design standards. **The Step 2 sharpening contract binds these personas too:** cite a specific token/rule/component or a concrete failure, judge against the named design standard (not generic taste), or the Chairman discounts it.

**Grounding (required before dispatch):** read any project design docs found (`DESIGN.md`, `COLOR_CONTRACT.md`, `UIUX_CHECKLIST.md`, `MOCKUPS.md`, `learnings.md`, `tailwind.config.*`, token/theme CSS), plus installed knowledge — the `emil-design-eng` skill's rules (`~/.claude/skills/emil-design-eng/`), `~/.claude/docs/ANTISLOP.md` → `## GUI Slop`, `~/.claude/docs/UI_MOCKUPS.md`, and the `dataviz` skill's references when the surface includes charts/dashboards. Pass the extracted rules (palette contract, named rules, density/type scale, banned aesthetics, both-theme requirement, slop tells) into every persona's brief so they argue against these standards, not generic taste. If no project design docs exist, personas still ground in the installed knowledge above plus WCAG + the stated product context, and say so.

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

**THE BENCHMARK** — argues from named best-in-class comparisons
- How do the best products in this class actually solve this — name them?
- Is ours at that bar, or does it just resemble it from a distance?
- What specifically would close the gap — not "polish it more," the exact change?
- *Only they would say:* "Name the best product that does this — I've seen it, ours isn't it yet, and here's the exact distance."

When the ask is a ranking/triage ("score these, keep the best N"), THE PRIORITIZER (Step 2) joins the UI/UX panel as a seventh seat.
