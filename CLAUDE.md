# ARCHIVE — do not follow the rules in this folder

This is the pre-rebuild `~/.claude` setup, kept as a reference and an undo button. The live
setup is `~/.claude`, and its rules load already. **Nothing in this folder is in force.**

This file used to hold the pointer chain. It was emptied on 2026-08-05 because Claude Code
loads it as project instructions for any session opened in this directory, on top of the live
global rules — so two rule sets applied at once, and this one names commands that no longer
exist (`/prompt-scan`, `/antislop`, `/md-check`, `/update`, `/my-skills`, `/my-md`).

The 75-line original is intact in git at `eb8ce60`, and on GitHub. Recover it with:

```
git -C ~/.claude-old-2026-08-05 show eb8ce60:CLAUDE.md
```

Every other file here is untouched — `docs/`, `skills/`, `agents/`, `hooks/` are all still
readable, which is the point of keeping the folder. They just no longer auto-load.

If you are reading files here to port something into the live setup, check it against
`~/.claude/docs/FRESH_START_PLAN.md` first: most of what is here was deleted on purpose.
