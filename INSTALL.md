# Outside pieces this setup uses

Five borrowed tools. Each one is optional: the file that reaches for it carries a fallback, so
a machine with none of these installed still works.

Every name below was queried against the registry on 2026-08-21 and `hooks/externals.txt`
pins the project each one must resolve to. `hooks/external-check.sh` re-checks that on every
run of `verify.sh`, so a name that drifts or was never real fails the build rather than
reaching a reader.

Two are skills, installed by the `skills` CLI. Two are npm command-line tools:

```bash
npx skills@latest add conorbronsdon/avoid-ai-writing && \
npx skills@latest add bitjaru/styleseed && \
npm install -g agnix @yawlabs/ctxlint
```

`skillspector` is a Python tool rather than a skill. Its `make` targets assume an active
virtual environment, so the one-line route is `uv`, which manages that itself:

```bash
uv tool install git+https://github.com/NVIDIA/skillspector.git
```

Without `uv`: clone it, make a virtual environment, activate it, then `make install`. A plain
`make install` outside one puts nothing on your path, which looks like a successful install
until the first time you try to run it.

Confirm each landed before relying on it. A tool that is absent gets reported as "did not
run", never as a clean result.

## StyleSeed leaves two things behind. Clean them up.

The `skills` CLI resolves its output directory against the working directory, so running the
StyleSeed line from `~/.claude` writes a nested `~/.claude/.claude/skills` holding 22 `ss-*`
symlinks plus `styleseed`. That path is a real project-skills directory, so all 22 load as
commands in every session. It also drops a `skills-lock.json` at the repo root.

Measured on 2026-08-21: 22 doors and a lockfile, from one install.

```bash
rm -rf "$HOME/.claude/.claude" "$HOME/.claude/skills-lock.json"
```

The skills themselves live in `~/.claude/.agents/skills/` and are untouched by this. Only the
symlinks that turn them into commands go.

Two details worth knowing before you decide. `styleseed` is a router: its `SKILL.md` dispatches
to the `ss-*` skills, so deleting those from `.agents/skills/` would break it, and the command
above deliberately does not. And `hooks/safety-net.sh` refuses that `rm` when the path is
written as `~/.claude/.claude`, because it cannot tell a nested directory from the
configuration directory itself. Run it with `$HOME` spelled out, as above.

| Piece | Gives | Reached from | Without it |
|---|---|---|---|
| `conorbronsdon/avoid-ai-writing` | Audits and rewrites AI writing patterns. Three modes: rewrite, detect, edit in place | `docs/PROSE.md` | That file's own list stands alone, and `hooks/slop-block.sh` still runs |
| `bitjaru/styleseed` | Design judgement, as a render, score and revise loop | `docs/SCREENS.md` | That file's axes table stands alone |
| `agnix` | 448 rules validating `CLAUDE.md`, `SKILL.md`, hooks and MCP config | `skills/checkup` | Checkup reports the check as unrun |
| `@yawlabs/ctxlint` | Lints agent context files against the actual codebase, so a reference to nothing is caught | `skills/checkup` | Same |
| `NVIDIA/SkillSpector` | Security-scans a skill for prompt injection, exfiltration and supply-chain risk before install | `skills/checkup` | Read the skill yourself first |

## Two pieces that used to be listed here

**`cxpak` never existed.** It was published in this file on 2026-08-21 with a description and a
consumer in `skills/build/stages/5-build.md`, and no package of that name has ever been on npm.
The reuse search that named it uses grep, which is what it always did.

**`claude-code-safety-net` was redundant.** `hooks/safety-net.sh` ships in this repo, needs no
install, and holds 47 tests. The two projects sharing that name on GitHub do different jobs:
one is an undo system for edits, not a guard on destructive commands.

## Versions

Ask the registry before pinning any of these, per `CLAUDE.md` rule 5. Versions written into
this file go stale; the registry does not. `hooks/externals.txt` records the project, not the
version, for that reason.

## The two local hooks

`hooks/safety-net.sh` and `hooks/slop-block.sh` ship with this setup and need no install. They
are wired in `settings.json` and depend on `jq` being on the path.

Watch each one refuse before trusting it. A guard nobody has seen fail is a belief:

```bash
echo '{"tool_input":{"command":"git push --force origin main"}}' | ~/.claude/hooks/safety-net.sh; echo "expect 2, got $?"
printf 'The plan is simple, build it.\n' > /tmp/t.md
echo '{"tool_input":{"file_path":"/tmp/t.md"}}' | ~/.claude/hooks/slop-block.sh; echo "expect 0, got $?"
```

Both were watched refusing and watched allowing on 2026-08-21.

## Codex

The second-model check needs the `codex` CLI on the path. Every command that uses it proceeds
without it, reporting the check as unrun. See `rules/codex.md`.
