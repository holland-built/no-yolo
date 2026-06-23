---
name: ui
description: Use this skill when the user types /ui or /ux, says 'design something', 'design this', 'show me options', 'mockup this', or 'design options'. UI entry point — routes to ui-ux, quick-design, ui-wild, or impeccable.
user-invocable: true
argument-hint: "[optional: what you're designing or which mode]"
allowed-tools: []
---

## Route

If `$ARGUMENTS` names intent clearly, skip the menu and invoke the matching skill directly.

- mentions "knowledge", "palettes", "fonts", "rules", "guidelines", "plan", "before code" → invoke `ui-ux`
- mentions "mockup", "variants", "3 options", "quick", "tokens" → invoke `quick-design`
- mentions "wild", "radical", "fresh", "bold", "redesign", "shake up" → invoke `ui-wild`
- mentions "cream", "orange", "editorial", "impeccable", "brand", "magazine" → invoke `impeccable`

Otherwise print the menu and wait:

---

> What do you need?
>
> **1. Design knowledge** — color palettes, font pairings, UX rules, layout guidelines. Planning a UI before touching code. → `/ui-ux`
>
> **2. Quick mockups** — 3 variants (safe / modern / bold) using your project's real design tokens. Pick one, then build. → `/quick-design`
>
> **3. Radical redesign** — 10 AI designers compete, a slop judge kills the generic ones, you pick the winner. Current UI thrown out entirely. → `/ui-wild`
>
> **4. Editorial theme** — warm cream and burnt orange brand applied surgically. One fixed look, magazine feel. → `/impeccable`

Type a number or describe what you need.

---

On selection (number or re-stated intent), invoke the matching skill via the Skill tool, passing `$ARGUMENTS` as the argument.
