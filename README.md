# no-yolo

Personal Claude Code setup saved as files you can copy. Includes the rules Claude reads each session, custom commands ("skills"), helper agents, automation scripts, and a memory system. Fork it and you have a working setup immediately.

---

## Prerequisites

- [Claude Code](https://claude.ai/code): `claude --version`
- GitHub CLI signed in: `gh auth status`
- Node.js: `node --version`
- git

---

## Install

```bash
# Fresh machine — replace ~/.claude directly
mv ~/.claude ~/.claude.bak 2>/dev/null || true
gh repo clone holland-built/no-yolo ~/.claude

# Then run setup (pick one mode)
bash ~/.claude/setup.sh           # full — tools, plugin skills, env var guide
bash ~/.claude/setup.sh --md-only # rules only — strips skill triggers from CLAUDE.md
```

After setup, open Claude Code and run `/my-skills` to confirm everything loaded.

**Inside Claude Code (optional plugins):**
```
/plugin marketplace add impeccable            # magazine design theme
/plugin marketplace add JuliusBrussee/caveman # terse mode
```

---

## Directory layout

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Pointer-only rules file — loads memory and topic files |
| `CORE_RULES.md` | The 5 core working rules |
| `PLANNING.md` | Planning rules |
| `TESTING.md` | Testing rules |
| `SUBAGENTS.md` | When and how to use helper agents |
| `UI_MOCKUPS.md` | Screen design rules + slop fingerprint |
| `ANTISLOP.md` | AI writing + GUI slop tells (25 patterns) |
| `SKILLS.md` | Skill usage rules |
| `CODE_REVIEW.md` | Code review rules |
| `NO_YOLO.md` | How to author a new skill |
| `memory/` | Preferences: `facts/` = source, `CLAUDE.generated.md` = compiled |
| `skills/` | Custom commands — run `/my-skills` for the full list |
| `hooks/` | Automation: caveman mode, session reflect, status line |
| `settings.example.json` | Starter settings — copy to `settings.json` and edit |
| `brainstorms/` | Plan files written by `/plan-feature` and `/forge` |

---

## Skills

Run `/my-skills` inside Claude Code for the live, up-to-date inventory with descriptions and relationships.

Key commands: `/plan-feature` → `/build-feature` (feature pipeline), `/debug-debate` (bug diagnosis), `/code-review`, `/ui-wild`, `/last-30`, `/antislop`, `/prompt-scan`, `/better_prompt`, `/md-check`, `/whats-next`.

---

## Updating

```
/update                # check if behind — shows what's new
/update full           # pull everything + re-run setup
/update rules          # pull rules only (no tool installs)
/update rollback       # undo last update
/update restore <name> # bring back a removed skill
```

Changes take effect when you reopen Claude Code.

---

## Memory

**Easy:** say "remember that I prefer X" — Claude saves it automatically.

**Committed (syncs via git):**
1. Edit or create a file in `memory/facts/`
2. Run `/memory-compile` inside Claude Code
3. `git add memory/ && git commit -m "remember: X" && git push`

Never hand-edit `memory/CLAUDE.generated.md` — it's overwritten on compile.

---

## Caveman mode

Shorter replies, fewer tokens. Toggle inside Claude Code:
```
/caveman full    # terse fragments, articles dropped
/caveman lite    # slightly shorter
/caveman ultra   # bare minimum
stop caveman     # back to normal
```

---

## Status bar

```
~  no-yolo  main  ●  42% ctx  2.1h/5h  [CAVEMAN:full]
```

`●` = uncommitted changes · `ctx` = context fill (run `/compact` above 60%) · `2.1h/5h` = daily usage · `[CAVEMAN:full]` = terse mode active. Driven by `hooks/statusline.sh`.

---

## Adding a skill

See `NO_YOLO.md` for the full checklist. Short version:
1. `mkdir ~/.claude/skills/<name>` + write `SKILL.md`
2. Add trigger block to `CLAUDE.md`
3. Add row to `skills/my-skills/STORIES.md` + `TAGLINES.md`
4. Update `README.md` skills list

---

## What's excluded

| Excluded | Reason |
|---|---|
| `settings.json` | Machine-specific (Node path, MCP servers, API keys) — use `settings.example.json` |
| `plugins/` | Third-party marketplaces; each lives in its own repo |
| Plugin symlinks (`ponytail*/`, `improve`, etc.) | Install via commands in `setup.sh` |
