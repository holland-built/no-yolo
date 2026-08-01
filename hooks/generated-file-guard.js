#!/usr/bin/env node
// generated-file-guard — PreToolUse guard for Edit/Write/MultiEdit.
//
// Blocks HAND edits to files a generator owns. Editing them by hand is silently
// wasted work: the next generator run overwrites the file and the change is gone
// with no error, no diff, no warning. The guard converts that silent loss into a
// loud message naming the source to edit and the command that regenerates.
//
// The generators themselves are unaffected: regen.py and memory_compile.py write
// via Python (`Path.write_text`), not via the Edit/Write tool, so no PreToolUse
// hook ever sees them.
//
// Fail open: any unexpected error -> exit 0. A guard that crashes a session is
// worse than the thing it guards.
//
// Escape hatch: CLAUDE_ALLOW_GENERATED_EDIT=1 passes silently.

const fs = require('fs');

// ---------------------------------------------------------------------------
// The ONLY thing to edit when a new generated file appears. `path` is matched as
// a path SUFFIX so it works for absolute or relative tool input.
// ---------------------------------------------------------------------------
const GUARDED = [
  {
    path: 'memory/CLAUDE.generated.md',
    why: 'compiled from the fact files under memory/facts/',
    fix: 'edit the source fact in memory/facts/<fact>.md, then run /memory-compile',
  },
  {
    path: 'skills/my-skills/RENDERED.md',
    why: 'rendered from each skill\'s SKILL.md frontmatter by regen.py',
    fix: 'edit the source SKILL.md, then run: python3 skills/my-skills/regen.py',
  },
  {
    path: 'skills/my-skills/RENDERED_FAST.md',
    why: 'rendered from each skill\'s SKILL.md frontmatter by regen.py',
    fix: 'edit the source SKILL.md, then run: python3 skills/my-skills/regen.py',
  },
  {
    path: 'docs/FLAGS.md',
    why: 'assembled from the skill catalog by regen.py (third target in regen.py main())',
    fix: 'edit the source SKILL.md flags section, then run: python3 skills/my-skills/regen.py',
  },
];

function main() {
  if (process.env.CLAUDE_ALLOW_GENERATED_EDIT === '1') return 0;

  let payload = {};
  try {
    const raw = fs.readFileSync(0, 'utf8');
    if (raw.trim()) payload = JSON.parse(raw);
  } catch {
    return 0; // no readable payload -> nothing to judge -> allow
  }

  const input = payload.tool_input || payload.toolInput;
  if (!input || typeof input !== 'object') return 0;

  const target = input.file_path || input.path || input.notebook_path;
  if (!target || typeof target !== 'string') return 0;

  // Normalize separators + strip a trailing slash so suffix matching is stable.
  const norm = target.replace(/\\/g, '/').replace(/\/+$/, '');

  const hit = GUARDED.find((g) => norm === g.path || norm.endsWith('/' + g.path));
  if (!hit) return 0;

  process.stderr.write(
    `GENERATED FILE — ${hit.path} is not editable by hand.\n` +
      `  target : ${target}\n` +
      `  why    : it is ${hit.why}. A hand edit here is silently discarded the next\n` +
      `           time the generator runs — no error, no diff, just lost work.\n` +
      `  fix    : ${hit.fix}\n` +
      `Do not retry this edit. If you genuinely need to write the generated file directly ` +
      `(a generator fix, a one-off repair), re-run with CLAUDE_ALLOW_GENERATED_EDIT=1 set.`
  );
  return 2;
}

let code = 0;
try {
  code = main();
} catch {
  code = 0; // fail open, always
}
process.exit(code);
