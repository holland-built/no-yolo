#!/usr/bin/env bash
# Regenerates skills/design/ASTRYX_CATALOG.md from the REAL @astryxdesign/core package.
# One command: ./skills/design/regen-astryx-catalog.sh   (run from ~/.claude or anywhere)
# Never hand-edit the generated section below the marker in ASTRYX_CATALOG.md — rerun this
# script instead. Pull-from-source-at-build-time, same principle as CORE_RULES rule 9.
set -euo pipefail
OUT="$(cd "$(dirname "$0")" && pwd)/ASTRYX_CATALOG.md"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
npm init -y >/dev/null 2>&1
npm install --no-audit --no-fund @astryxdesign/core >/dev/null 2>&1
VER="$(node -p "JSON.parse(require('fs').readFileSync('node_modules/@astryxdesign/core/package.json','utf8')).version")"
node node_modules/@astryxdesign/core/docs.mjs --list --brief > brief.txt

# Transform brief.txt into '- **Name** — brief' bullets, grouped by the categories docs.mjs
# emits (Layout/Display/Form/Action/Navigation/Overlay/Other, etc). Do NOT hand-invent groups.
cat > transform.cjs <<'NODE'
const fs = require('fs');
const lines = fs.readFileSync('brief.txt', 'utf8').split('\n');
const sections = [];
let current = null;
for (const raw of lines) {
  if (raw.trim() === '') continue;
  if (!raw.startsWith(' ')) {
    const name = raw.trim().replace(/:$/, '');
    current = { name, items: [] };
    sections.push(current);
    continue;
  }
  const m = raw.match(/^\s{2}([A-Za-z]+)(.*)$/);
  if (m && current) {
    const name = m[1];
    let rest = m[2];
    let desc;
    if (rest.startsWith('(')) {
      // signature may contain nested parens (e.g. Table's idKey type) — track depth
      // to find the TRUE end of the signature instead of the first ')'.
      let depth = 0, i = 0;
      for (; i < rest.length; i++) {
        if (rest[i] === '(') depth++;
        else if (rest[i] === ')') { depth--; if (depth === 0) { i++; break; } }
      }
      desc = rest.slice(i).trim();
    } else {
      desc = rest.trim();
    }
    current.items.push({ name, desc });
  }
}
let out = '';
let count = 0;
for (const s of sections) {
  if (!s.items.length) continue;
  out += `\n### ${s.name}\n`;
  for (const it of s.items) {
    out += `- **${it.name}** — ${it.desc}\n`;
    count++;
  }
}
fs.writeFileSync('generated.md', out);
console.error(`transform: ${count} bullets`);
NODE
node transform.cjs

{
  cat <<PREAMBLE
# Astryx component catalog — the Meta UX menu /design and /build reach for

> Meta's open-source React design system (\`github.com/facebook/astryx\`, MIT). Real, installable
> package: \`@astryxdesign/core@${VER}\`. This file exists so the fresh-gen mockup agents and the
> build agents KNOW these components are available and reach for them proactively — not only
> when the user names one.
>
> **This file is GENERATED — never hand-edit the component list below.** Regen with
> \`./skills/design/regen-astryx-catalog.sh\` (pull-from-source-at-build-time, same principle as
> CORE_RULES rule 9). On any new Astryx release, rerun the script and commit the diff — the
> version stamp below makes staleness visible.
>
> **Never import a name that isn't in this file.** Before any import, confirm the exact export +
> props via \`node node_modules/@astryxdesign/core/docs.mjs <Name>\` (or
> \`npx astryx component <Name>\`). If a component isn't here, hand-build — never guess a name.
>
> **Only reach for these in a React + npm/bundler project.** Not React, or React-via-CDN with no
> \`package.json\` (e.g. a babel-standalone page): do NOT use Astryx — mock the behavior / hand-build.

## When to reach for Astryx (proactive rule)
A design "calls for a rich interaction" when it includes any of: a preview-on-hover (**HoverCard**),
live/typeahead search (**Typeahead** / **PowerSearch**), a chat/messaging surface (**Chat**), a
command palette (**CommandPalette**), stacked toasts (**Toast**), a media carousel or fullscreen
viewer (**Carousel** / **Lightbox**), a token/multi-select input (**Tokenizer** / **MultiSelector**),
or app scaffolding/nav (**AppShell** / **SideNav** / **TopNav**). For those, **prefer the finished
Astryx component over hand-building** — it's accessible, animated, and battle-tested. Theme it to
the project's tokens so it looks like the project, not like Facebook. There is no real Astryx
component for an infinite/virtualized feed, emoji reactions, a rich mention/emoji composer, or a
story-bar — **hand-build those explicitly**, don't go hunting for a component that doesn't exist.
For plain/static pieces, hand-build as normal.

PREAMBLE
  echo "## Components (generated from @astryxdesign/core@${VER} — do not hand-edit below this line)"
  cat generated.md
} > "$OUT"
echo "wrote $OUT (@astryxdesign/core@${VER})"
