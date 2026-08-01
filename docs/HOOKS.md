# Hooks

Hook scripts in `~/.claude/hooks/` run automatically at harness events (session start, session end, before a tool runs). They are wired in `settings.json` under the `hooks` key — machine-specific; see `settings.example.json` for the template.

## Active hooks

- **eli5-activate.js** — plain-language output mode. On by default. SessionStart emits the full ruleset; UserPromptSubmit re-injects a one-line reminder every turn, which is what stops it drifting.
- **prompt-scan-nudge.js** — SessionStart; surfaces the model recorded in the last `/prompt-scan` so Claude can offer a re-scan if the current model differs.
- **lockstep-guard.js** — PreToolUse (Edit/Write/NotebookEdit **and Bash**); denies file mutation, plus 12 destructive shell patterns (`rm -rf`, `git reset --hard`, force-push, `filter-repo`, `DROP TABLE`…), judged per command segment so `npm test && rm -rf dist` is caught. Ordinary Bash passes. `/lockstep off` is itself an `rm -f` of the flag, so that one command is exempt — without the exemption the mode denies its own release. Alone among these guards it fails CLOSED on a malformed payload while the flag is present. Toggle: `/lockstep`.
- **worktree-autoarm.js** — SessionStart; arms the worktree guard when a session opens inside a linked git worktree, and prunes stale flags for deleted worktrees.
- **worktree-guard.js** — PreToolUse (Edit/Write/NotebookEdit); once a worktree is armed for a repo, denies edits to that repo's main checkout outside the active worktree.
- **literal-mode-tracker.js** — UserPromptSubmit; owns the `/literal` on/off state (`.literal-active`) and re-injects the literal-mode reminder each turn while it is on. Emits nothing while off. Toggle: `/literal`.
- **config-protection.js** — PreToolUse (Edit/Write/MultiEdit); denies edits to an *existing* lint/format/type config (eslint, prettier, biome, ruff, flake8, tsconfig). Creating one for the first time is allowed — only weakening an existing check is blocked. Override: `CLAUDE_ALLOW_CONFIG_EDIT=1`. Deliberately does NOT guard `pyproject.toml`, `setup.cfg`, `.editorconfig` — dual-purpose files ordinary work edits.
- **generated-file-guard.js** — PreToolUse (Edit/Write/MultiEdit); denies hand-edits to compiled output (`memory/CLAUDE.generated.md`, `skills/my-skills/RENDERED*.md`, `docs/FLAGS.md`) and names the command that regenerates each. Override: `CLAUDE_ALLOW_GENERATED_EDIT=1`.
- **relock-guard.js** — PreToolUse (Bash); denies `catalog_lock.py --relock` while any `skills/*/SKILL.md` is untracked by git, because the lock is built from `git ls-files` and would silently omit it. `--check` is never blocked. Override: `CLAUDE_ALLOW_RELOCK=1`.
- **slop-guard.js** — Stop; **warns, never blocks.** Scans the finished reply against `hooks/slop-patterns.json` (edit that file, not the script) and names any listed phrase it finds. See the honesty note below.
- **format-typecheck.js** — Stop; formats and type-checks the JS/TS files touched that turn, batched one call per project root. Uses only a formatter the project already has installed; no formatter or no `package.json` → silent no-op. Never blocks, even on a type error.
- **mockup-autoopen.js** — PostToolUse (Write); when a `.html` file is written under `.mockups/`, regenerates `.mockups/_index.html` and opens the page. Debounced to one open per 20s so an 8-mockup `/design` run does not open 8 tabs.
- **statusline.sh** — displays context usage, your 5-hour usage limit, and your 7-day usage limit in the Claude Code status bar.

### What a clean slop-guard run does NOT prove

It proves one thing only: none of the listed phrases appeared. It cannot see parroting the ask back, invented or static filler values, padding, forced rule-of-three, empty caveats, overclaimed completion that used different words, or any GUI slop at all. Those stay with `/antislop` and the design judge. A green light here is not a verdict on the reply.

## Plain English mode (default)

`eli5-activate.js` keeps every reply in plain words: no jargon, a small chart for a list, one sentence for a single point. Code, commands and security warnings are still written out exactly, because those need to be precise.

State: `.eli5-active`. Turn off with `ELI5_MODE=off`, or say "stop eli5" to drop it for one session.

Why a hook and not a rule in a file: the same instruction lived in `memory/CLAUDE.generated.md` for months and drifted constantly, because a written preference is a suggestion. A hook fires every turn and cannot be forgotten.

## Setup

```bash
# Make hooks executable after clone (also done by setup.sh)
chmod +x ~/.claude/hooks/*.sh
```
