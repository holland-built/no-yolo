# Hooks

Hook scripts in `~/.claude/hooks/` run automatically at harness events (session start, session end, before a tool runs). They are wired in `settings.json` under the `hooks` key — machine-specific; see `settings.example.json` for the template.

## Active hooks

- **eli5-activate.js** — plain-language output mode. On by default. SessionStart emits the full ruleset; UserPromptSubmit re-injects a one-line reminder every turn, which is what stops it drifting.
- **prompt-scan-nudge.js** — SessionStart; surfaces the model recorded in the last `/prompt-scan` so Claude can offer a re-scan if the current model differs.
- **lockstep-guard.js** — PreToolUse (Edit/Write/NotebookEdit); denies file mutation while `.lockstep-active` exists. Toggle: `/lockstep`.
- **worktree-autoarm.js** — SessionStart; arms the worktree guard when a session opens inside a linked git worktree, and prunes stale flags for deleted worktrees.
- **worktree-guard.js** — PreToolUse (Edit/Write/NotebookEdit); once a worktree is armed for a repo, denies edits to that repo's main checkout outside the active worktree.
- **statusline.sh** — displays context usage, your 5-hour usage limit, and your 7-day usage limit in the Claude Code status bar.

Present but not wired by default: `caveman-*` scripts (config, stats, activate, mode-tracker, statusline). They belong to the optional Caveman plugin — see below.

## Plain English mode (default)

`eli5-activate.js` keeps every reply in plain words: no jargon, a small chart for a list, one sentence for a single point. Code, commands and security warnings are still written out exactly, because those need to be precise.

State: `.eli5-active`. Turn off with `ELI5_MODE=off`, or say "stop eli5" to drop it for one session.

Why a hook and not a rule in a file: the same instruction lived in `memory/CLAUDE.generated.md` for months and drifted constantly, because a written preference is a suggestion. A hook fires every turn and cannot be forgotten.

## Caveman mode (optional, off by default)

The Caveman plugin cuts tokens roughly 75% by dropping filler. It is **not** installed or wired by default, and it conflicts with plain English mode: caveman keeps technical terms exact, which is the opposite goal. Pick one.

Install: `/plugin marketplace add JuliusBrussee/caveman`. Toggle: `/caveman lite|full|ultra`, off with "stop caveman". State: `.caveman-active`. Set `defaultMode: "off"` in `~/.config/caveman/config.json` to disable it without uninstalling.

## Setup

```bash
# Make hooks executable after clone (also done by setup.sh)
chmod +x ~/.claude/hooks/*.sh
```

Deeper module reference → [HOOKS_INTERNALS.md](HOOKS_INTERNALS.md).
