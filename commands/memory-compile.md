---
description: Promote high-confidence instincts, lint, and regenerate the compiled memory views
---

Run the curated-memory pipeline and report results concisely (bulleted):

1. **Promote** auto-captured high-confidence instincts into the curated fact store:
   ```bash
   python3 ~/.claude/memory/bin/memory_bridge.py --apply
   ```
   Report any `NEEDS-REVIEW (conflict)` items prominently — these are auto-promoted
   facts that contradict an existing belief and must be confirmed or dropped by the user.

2. **Compile** (lints, then regenerates `CLAUDE.generated.md` + adopted project `MEMORY.md`):
   ```bash
   python3 ~/.claude/memory/bin/memory_compile.py
   ```
   If it exits non-zero on `ERROR needs-review`, surface the conflicts and STOP — do not
   force-compile. Ask the user to resolve (supersede the old fact or drop the new one).

3. Summarize: facts active, warnings, anything needing review. Note that the new
   `CLAUDE.generated.md` loads at the next session start.

Source of truth is `~/.claude/memory/facts/*.md` — edit facts, never the generated files.
Schema: `~/.claude/memory/SCHEMA.md`.
