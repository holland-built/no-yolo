# Hooks Internals

Developer reference for the 4 caveman hook JS modules in `~/.claude/hooks/`.

## caveman-config.js

- **Hook event:** none — shared library, `require()`d by the other 3 hooks
- Shared config resolver and symlink-safe I/O. Reads active mode from env var → config file → default `'full'`. Provides atomic flag writes (temp file + rename, `O_NOFOLLOW`, `0600` perms) and validated flag reads (whitelist check + 64-byte cap).
- **Key exports:** `getDefaultMode`, `getConfigPath`, `VALID_MODES`, `safeWriteFlag`, `readFlag`, `appendFlag`, `readHistory`
- **Security:** `O_NOFOLLOW` + uid-match (Unix) / home-prefix (Windows) guard blocks symlink-clobber on `.caveman-active`

## caveman-activate.js

- **Hook event:** `SessionStart`
- Writes `.caveman-active` flag, emits full caveman ruleset as hidden context. Reads `skills/caveman/SKILL.md` at runtime (plugin install); falls back to hardcoded rules if absent (standalone install). Filters intensity table to active level only. Nudges user if statusline not yet configured.
- **Key exports:** none — standalone hook entry point

## caveman-mode-tracker.js

- **Hook event:** `UserPromptSubmit`
- Parses each prompt for `/caveman` slash commands and NL activation phrases. Updates `.caveman-active` flag. Re-emits caveman reinforcement as `additionalContext` every turn so mode survives context compression.
- `/caveman-stats` intercepted here: delegates to `caveman-stats.js` via `execFileSync`, returns `decision: "block"` with stats output so the model never sees the prompt.
- **Key exports:** none — standalone hook entry point

## caveman-stats.js

- **Hook event:** none — standalone script, invoked by `caveman-mode-tracker.js` on `/caveman-stats`
- Parses active session JSONL for output + cache-read tokens. Estimates savings using benchmark compression ratio (65% for `full` mode). Appends snapshot to `.caveman-history.jsonl`, updates `.caveman-statusline-suffix`. Supports `--all` / `--since Nd` for lifetime aggregation, `--share` for tweetable summary.
- **Key exports:** `formatStats`, `formatShare`, `formatHistory`, `aggregateHistory`, `parseSession`, `deriveSavings` (exported for unit tests)
