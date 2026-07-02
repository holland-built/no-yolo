---
name: quick-mockup
description: Use this skill when the user types /quick-mockup, says 'quick mockup', 'sketch this', 'throwaway mockup', or 'just show me the layout'. Fast disposable placeholder-only HTML for layout/spatial decisions — the lightweight counterpart to /design. ONE self-contained HTML file, neutral gray boxes, system-ui font, generic labels ("Card 1", "Section A"). No real copy, no brand tokens, no slop-judge, no 10-variant pipeline. Hard rule: always serve over http:// and auto-open in the real browser — never describe the layout in prose or ASCII art, never use AskUserQuestion preview fields for visual choices. Routes from the global "never show ASCII mockups" rule: when the ask is small/quick, reach for this skill before /design.
user-invocable: true
argument-hint: "[what to lay out] [--variants N]"
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

**NOT /design.** This skill produces zero brand tokens, zero slop-judge passes, zero 10-variant
pipelines. If the user wants polished multi-variant visual design, redirect them to `/design`.

---

## Hard rules (never violate)

1. **Always serve over http://** — never `file://`. Browsers block some APIs on bare file paths.
2. **Always auto-open the real browser** after building or updating. Never describe the layout in
   prose, never render a text or ASCII preview, never use AskUserQuestion preview fields for visual
   choices. Build first, show second.
3. **Placeholder-only content** — generic labels ("Card 1", "Section A", "Label"), neutral gray
   boxes (`#e5e7eb` fill, `#d1d5db` border), `system-ui` font. No real copy, no brand colors or
   tokens unless the user explicitly asks to match the real theme.
4. **Self-contained HTML** — single file, inline `<style>`, no build step, no framework, no
   external CDN links.
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
- Default: **1 variant**.
- `--variants N` flag where N ≤ 3: build N separate files.
- If the ask describes 2–3 **genuinely distinct layout candidates** (e.g. "sidebar vs. top-nav
  vs. fullscreen") with no flag: build one file per candidate (cap at 3).
- Never exceed 3 variants. If the user asks for more, explain that 3+ variants is `/design`'s job.

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
Multiple variants → `$OUTDIR/$SLUG-1.html`, `$OUTDIR/$SLUG-2.html`, etc.

---

## Step 3 — Build the HTML file(s)

Write the file. Use this template as the baseline:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Quick Mockup — $SLUG</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: system-ui, sans-serif; font-size: 14px; color: #111; background: #f9fafb; min-height: 100vh; }

  /* Placeholder box utility */
  .ph { background: #e5e7eb; border: 1px solid #d1d5db; border-radius: 4px; display: flex; align-items: center; justify-content: center; color: #6b7280; font-size: 12px; }
</style>
</head>
<body>
  <!-- Layout goes here. Use .ph boxes for every content area. Real labels ("Card 1", "Nav", "Sidebar"). -->
</body>
</html>
```

Adapt the layout to `$ARGUMENTS`. Use `flex` or `grid` for all layout — no hardcoded pixel widths
on content areas. Every distinct content region is a `.ph` box with a short label.

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

## Step 5 — Open in browser

Single variant:
```bash
open "http://localhost:$PORT/.mockups/quick/$SLUG.html"
```

Multiple variants — open all:
```bash
for f in .mockups/quick/$SLUG-*.html; do
  open "http://localhost:$PORT/$f"
done
```

---

## Step 6 — Reply

After opening, output **exactly this** (adapt paths/port):

```
File:  .mockups/quick/<slug>.html
URL:   http://localhost:8743/.mockups/quick/<slug>.html

Open it yourself and resize/interact — screenshots here are just a preview, not the deliverable.

This file is disposable: delete it once the layout decision is locked and the real component is built to match.
```

If multiple variants, list all file/URL pairs.

Do **not** paste an ASCII or text layout after this. The browser tab is the deliverable.

---

## Updating an existing mockup

If the user says "update the mockup" / "change the layout" / "move X to Y":
1. Edit the existing file in-place.
2. Re-open the URL in the browser (browser reloads automatically if already open — no new tab needed unless the user asks).
3. Skip Steps 0–4 (server is already running).

---

## When to redirect

- User wants brand tokens, dark/light variants, slop-judge, or 10 options → redirect to `/design`.
- User wants a polished production component built to spec → redirect to `/build`.
- User wants to audit an existing UI → redirect to `/design-audit`.
