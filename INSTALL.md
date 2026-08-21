# Outside pieces this setup uses

Seven borrowed tools. Each one is optional: the file that reaches for it carries a fallback,
so a machine with none of these installed still works.

Run this once to install all seven:

```bash
npx skills@latest add hesreallyhim/avoid-ai-writing && \
npx skills@latest add hesreallyhim/styleseed && \
npm install -g agnix ctxlint cxpak && \
npx skills@latest add hesreallyhim/claude-code-safety-net && \
npx skills@latest add hesreallyhim/skillspector
```

Confirm each landed before relying on it. A tool that is absent gets reported as "did not
run", never as a clean result.

| Piece | Gives | Reached from | Without it |
|---|---|---|---|
| `avoid-ai-writing` | 49 families of machine-sounding prose, rewritten | `docs/PROSE.md` | That file's own list stands alone |
| `styleseed` | 74 design rules the agent applies itself | `docs/SCREENS.md` | That file's axes table stands alone |
| `agnix` | Validates rule files, hooks, and config | `skills/checkup` | Checkup reports the check as unrun |
| `ctxlint` | Finds stale references and dead commands in rule files | `skills/checkup` | Same |
| `cxpak` | A dependency graph, so existing code gets reused | `stages/5-build.md` | Grep-based reuse search |
| `safety-net` | Stops destructive git and filesystem commands | `hooks/safety-net.sh`, wired in `settings.json`. Local, no install | Off only if the hook is unwired |
| `skillspector` | Security-scans a borrowed skill before install | `skills/checkup` | Read the skill yourself first |

## Versions

Ask the registry before pinning any of these, per `CLAUDE.md` rule 5. Versions written into
this file go stale; the registry does not.

## The two local hooks

`hooks/safety-net.sh` and `hooks/slop-block.sh` ship with this setup and need no install.
They are wired in `settings.json` and depend on `jq` being on the path.

Watch each one refuse before trusting it. A guard nobody has seen fail is a belief:

```bash
echo '{"tool_input":{"command":"git push --force origin main"}}' | ~/.claude/hooks/safety-net.sh; echo "expect 2, got $?"
printf 'The plan is simple — build it.\n' > /tmp/t.md
echo '{"tool_input":{"file_path":"/tmp/t.md"}}' | ~/.claude/hooks/slop-block.sh; echo "expect 2, got $?"
```

Both were watched refusing and watched allowing on 2026-08-21.

## Codex

The second-model check needs the `codex` CLI on the path. Every command that uses it
proceeds without it, reporting the check as unrun. See `rules/codex.md`.
