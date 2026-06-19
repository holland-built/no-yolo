---
description: Start coding session with all my rules — pass goal as argument
---

# Session Opener

**Goal:** $ARGUMENTS

## Rules to follow this session

1. **Read first** — `~/.claude/CLAUDE.md` and the 5 sub-MDs (`PLANNING.md`, `TESTING.md`, `SUBAGENTS.md`, `CONTEXT.md`, `SKILLS.md`).

2. **Plan mode** — enter Plan mode for any multi-file or non-trivial change. Shift+Tab×2 equivalent.

3. **Grill me** — ask clarifying questions until zero ambiguity. List your assumptions before writing code. (Karpathy Rule 1 + Matt Pocock grill-with-docs.)

4. **TDD when applicable** — bug fixes and new features start with a failing test. (Karpathy Rule 4.)

5. **Surgical changes only** — every changed line traces to the goal above. Zero unrelated edits. (Karpathy Rule 3.)

6. **Simplicity first** — if 200 lines could be 50, rewrite. No enterprise patterns on simple requests. (Karpathy Rule 2.)

7. **UI/GUI changes need mockups first** — see `~/.claude/UI_MOCKUPS.md`. Run `/quick-design [description]` for 3 variants before writing production code.

8. **Verify before claiming done** — actually run the checks, show the output. Evidence before assertions.

9. **End of session** — run `/log` to capture session notes.

## Stack reminders (fill in for your project)

- Frontend dev: `<your dev command>`
- Backend dev: `<your backend command>`
- Lint: `<your lint command>`
- Test: `<your test command>`

## Output style this session

- Bullets or tables, not prose
- One-paste commands when giving instructions
- Caveman mode if active (check `.caveman-active`)

---

## Append your own rules below this line

(Add new rules as you learn what you want from me. Edit this file freely.)

<!-- USER APPENDS START -->

<!-- USER APPENDS END -->
