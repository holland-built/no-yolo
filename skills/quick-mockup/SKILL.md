---
name: quick-mockup
description: Use this skill when the user types /quick-mockup, says 'quick mockup', 'sketch this', 'throwaway mockup', or 'just show me the layout'. Up to 5 style-matched functional layout candidates on one combined page with an AI ★ pick — reads the project's CSS tokens so variants match the real style, uses native HTML so dropdowns/selects work; much lighter than /design (no slop-judge, no 10-variant pipeline, no brand tokens beyond reading the project's own). Hard rule: always serve over http:// and auto-open in the real browser — never describe the layout in prose or ASCII art, never use AskUserQuestion preview fields for visual choices. Routes from the global "never show ASCII mockups" rule: when the ask is small/quick, reach for this skill before /design.
user-invocable: true
model: sonnet
argument-hint: "[what to lay out] [--variants N, default 5]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
---

# quick-mockup

Target: $ARGUMENTS

Disposable layout mockup. Build fast, open in browser, throw away once the layout decision is locked.

**NOT /design** — no brand-seed, no taste generators, no slop-judge, no 10-variant pipeline. Style
matching here is limited to reading the project's own existing CSS tokens (colors, font, radius) —
never invents a brand. Polished multi-variant visual design with new brand tokens → redirect to `/design`.

---

## Hard rules (never violate)

1. **Always serve over http://** — never `file://`. Browsers block some APIs on bare file paths.
2. **Always auto-open the real browser** after building or updating. Never describe the layout in
   prose, never render a text or ASCII preview, never use AskUserQuestion preview fields for visual
   choices. Build first, show second.
3. **Generic labels, style-matched chrome** — content labels stay generic ("Card 1", "Section A",
   "Label"), never real copy. But colors, font, and corner radius match the PROJECT's own CSS
   tokens where found (Step 1.5) — this is style-match, not content-match. No invented brand tokens.
4. **Self-contained HTML, real interaction** — single file, inline `<style>`, no build step, no
   framework, no external CDN links, no JS component libraries. Use native HTML controls (`<select>`,
   `<input>`, `<details>/<summary>`, `<button>`) so the mockup is lightly functional out of the box.
5. **Responsive by default** — the file must respond to window resize in real-time (CSS flexbox/
   grid, not fixed-px widths for content areas). The user drags their own browser window.

---

## Step 0 — Detect project mockup convention

```bash
ls scripts/mockup.sh 2>/dev/null && echo "CONVENTION:script" || true
ls MOCKUPS.md 2>/dev/null && echo "CONVENTION:docs" || true
```

- `CONVENTION:script` → read `scripts/mockup.sh` and use whatever serve/open pattern it defines.
- `CONVENTION:docs` → read `MOCKUPS.md` for the project's mockup directory and serving approach.
- Neither → use the fallback in Step 2.

---

## Step 1 — Determine variant count

Parse `$ARGUMENTS`:
- Default: **5 variants**.
- `--variants N` flag: clamp N to **2–5**.
- If the ask names a specific number of distinct candidates (e.g. "sidebar vs. top-nav vs.
  fullscreen" = 3), that count wins, still clamped to 2–5.
- Cap is **5**. If the user wants more, or wants brand-new (not project-derived) visual styles,
  redirect to `/design`.

---

## Step 1.5 — Read the project's style tokens (cheap, bounded)

Look ONLY at these entrypoints, and ONLY at the project root / conventional locations — never
`node_modules`, `dist`, `build`, or `.next`:

```bash
for f in globals.css app.css index.css styles.css; do
  find . -maxdepth 4 -name "$f" \
    -not -path "*/node_modules/*" -not -path "*/dist/*" \
    -not -path "*/build/*" -not -path "*/.next/*" 2>/dev/null
done
find . -maxdepth 2 -name "tailwind.config.*" \
  -not -path "*/node_modules/*" 2>/dev/null
```

From whatever is found, extract (grep/read, don't overthink it):
- `:root { ... }` custom properties → color tokens, `--radius`/border-radius, `--font-*`.
- `tailwind.config.{js,ts}` → `theme.colors`, `theme.borderRadius`, `theme.fontFamily`.

Apply per-token, with fallback for anything NOT found:
- **Color** found → use it for accents/borders; not found → neutral gray (`#e5e7eb` / `#d1d5db`).
- **Radius** found → use it (square corners if the project's radius is 0/near-0); not found → `4px`.
- **Font** found AND it's a websafe/system/Google Fonts name (resolvable without a local
  `@font-face` file) → use it, **always with a `system-ui, sans-serif` fallback in the stack**.
  Found but needs a local font file → skip it, use `system-ui`, and note the degrade in that
  variant's one-line header comment. Not found → `system-ui`.
- **Nothing found at all** (fresh/no-CSS project) → clean neutral + square-ish + `system-ui`,
  still fully functional. This is a normal outcome, not a failure.

Labels stay generic regardless of what's found — this step matches STYLE, never real content.

---

## Step 2 — Pick output path and port

```bash
SLUG=$(python3 -c "
import re, sys
args = '''$ARGUMENTS'''
slug = re.sub(r'[^a-z0-9]+', '-', args.lower().strip())[:40].strip('-')
print(slug or 'layout')
")
OUTDIR=".mockups/quick"
mkdir -p "$OUTDIR"
PORT=8743
```

Single variant → `$OUTDIR/$SLUG.html`
Multiple variants → `$OUTDIR/$SLUG-1.html`, `$OUTDIR/$SLUG-2.html`, ... plus one combined page
`$OUTDIR/$SLUG-all.html`.

---

## Step 3 — Build the variant files + the combined page (pass 1, unranked)

For each variant, use this template as the baseline, substituting the tokens found (or the
fallbacks) from Step 1.5:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Quick Mockup — $SLUG v<N></title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: <PROJECT_FONT, or system-ui>, sans-serif; font-size: 14px; color: #111; background: #f9fafb; min-height: 100vh; }

  /* Content box utility — colors/radius from Step 1.5 tokens, fallback gray/4px */
  .ph { background: <TOKEN_BG, or #e5e7eb>; border: 1px solid <TOKEN_BORDER, or #d1d5db>; border-radius: <TOKEN_RADIUS, or 4px>; display: flex; align-items: center; justify-content: center; color: #6b7280; font-size: 12px; }
</style>
</head>
<body>
  <!-- Layout goes here. Use .ph boxes for content areas, real <select>/<input>/<details>/<button>
       for anything interactive. Generic labels ("Card 1", "Nav", "Sidebar") — never real copy. -->
</body>
</html>
```

Adapt the layout to `$ARGUMENTS`. Use `flex` or `grid` for all layout — no hardcoded pixel widths
on content areas. Prefer real native controls over `.ph` boxes wherever the layout implies
interaction (a filter → `<select>`, a search box → `<input>`, a collapsible → `<details>`).
No JS frameworks, no component libraries; a small inline `<script>` is fine only if truly needed.

**Combined page** `$OUTDIR/$SLUG-all.html`: one file that stacks all variants top-to-bottom (or in
a simple grid), each in its own `<section>` with a header `v1`..`v5` and a one-line style note
(font/color/radius used, and any font degrade from Step 1.5). Mirror `/design`'s `all.html`
pattern conceptually (labeled sections, sticky jump nav is fine, no separate tabs) — but skip its
light/dark pairing and validator machinery. Leave the pick UNRANKED at this point — no ★ yet.

---

## Step 4 — Start server (if not already running on PORT)

```bash
# Kill any stale process on PORT first
lsof -ti tcp:$PORT | xargs kill -9 2>/dev/null || true

# Serve from project root so relative paths resolve; run in background
python3 -m http.server $PORT --directory . &>/dev/null &
sleep 0.4
```

If `python3` is unavailable:
```bash
npx --yes serve -p $PORT . &>/dev/null &
sleep 0.8
```

---

## Step 5 — Screenshot + AI pick (pass 2)

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --window-size=1400,900 \
  --screenshot=".mockups/quick/$SLUG-all.png" \
  "file://$PWD/.mockups/quick/$SLUG-all.html"
```

If that Chrome binary is absent, skip the screenshot and just `open` the combined page in Step 6 —
never block on the screenshot.

If the screenshot succeeded: inspect it, then edit `$OUTDIR/$SLUG-all.html` to add, in every
variant's section header, a compact one-line rationale (what layout/style choice it represents),
and mark exactly ONE winner with a `★` plus a short "why picked" sentence. This is a quick eyeball
pick — no slop-judge, no adversarial judge agent, no scoring rubric.

---

## Step 6 — Open in browser

```bash
open "http://localhost:$PORT/.mockups/quick/$SLUG-all.html"
```

(Individual variant files also exist on disk/served if the user wants to open one directly —
no need to open each in its own tab.)

---

## Step 7 — Reply

After opening, output **exactly this** (adapt paths/port/count):

```
Combined: .mockups/quick/<slug>-all.html
URL:      http://localhost:8743/.mockups/quick/<slug>-all.html
Pick:     v<N> ★ — <one-line why>

Open it yourself and resize/interact — screenshots here are just a preview, not the deliverable.

To wire the pick into the real app: /build <describe it> or /design (mockup-match).

This file is disposable: delete it once the layout decision is locked and the real component is built to match.
```

Do **not** paste an ASCII or text layout after this. The browser tab is the deliverable.

---

## Updating an existing mockup

If the user says "update the mockup" / "change the layout" / "move X to Y":
1. Edit the existing variant file(s) in-place, and the corresponding section in `-all.html`.
2. Re-open the combined page URL in the browser (browser reloads automatically if already open —
   no new tab needed unless the user asks).
3. Skip Steps 0–4 (server is already running). Re-run Step 5's screenshot+pick only if the change
   could shift which variant is best; otherwise leave the existing ★ as-is.

---

## When to redirect

- **User wants REAL DATA in the mockup (real rows, real values, a "working" prototype) → this is NOT quick-mockup.** Quick-mockup uses generic labels and style-matched placeholder content only, never real copy or real data. Route by intent: exploring a look/direction → `/design`; building the actual component to keep → `/build`. Never pour real data into a quick-mockup sketch.
- User wants a brand-new visual identity (not derived from the project's own CSS), dark/light theme
  pairs, a slop-judge pass, or more than 5 options → redirect to `/design`.
- User wants a polished production component built to spec → redirect to `/build`.
- User wants to audit an existing UI → redirect to `/design-audit`.
