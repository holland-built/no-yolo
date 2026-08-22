# Outside pieces this setup uses

Five borrowed tools. Each one is optional: the file that reaches for it carries a fallback, so
a machine with none of these installed still works.

Every name below was queried against the registry on 2026-08-21 and `hooks/externals.txt`
pins the project each one must resolve to. `hooks/external-check.sh` re-checks that on every
run of `verify.sh`, so a name that drifts or was never real fails the build rather than
reaching a reader.

The `agnix` row said "448 rules" until 2026-08-22. The installed CLI is `agnix 0.49.0` and it
has no command that lists or counts its rules (`explain` takes one rule ID; there is no
`list`), so the figure could not be confirmed or refuted from the tool itself. An unverifiable
number in a table of verified names is the thing this file exists to stop, so it is gone. What
IS measured is that the binary runs: `agnix ~/.claude/CLAUDE.md` reported "No issues found" on
2026-08-22.

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
rm -rf "$HOME/.claude/.claude/skills" "$HOME/.claude/skills-lock.json"
```

**This command used to be `rm -rf "$HOME/.claude/.claude"`, removing the whole directory.**
That was right on the day it was written, when StyleSeed had just created that directory and
nothing else lived in it. It is not right later: Claude Code writes its own
`.claude/settings.local.json` there when `~/.claude` is opened as a project, and the broad
form takes that with it. Checked on 2026-08-22, after the cleanup had already been run once:
`.claude/skills/` was gone and `.claude/settings.local.json` was the only thing left, so the
original command would now have deleted a live settings file and nothing else. Only the
`skills` directory is StyleSeed's, so only that is named.

The skills themselves live in `~/.claude/.agents/skills/` and are untouched by this. Only the
symlinks that turn them into commands go.

One detail worth knowing before you decide. `styleseed` is a router: its `SKILL.md` dispatches
to the `ss-*` skills, so deleting those from `.agents/skills/` would break it, and the command
above deliberately does not.

This passage also claimed that `hooks/safety-net.sh` refuses the `rm` above when the path is
written `~/.claude/.claude`, and told you to spell `$HOME` out to get past it. That was wrong
in both halves, and measured wrong on 2026-08-21:

```
rm -rf ~/.claude/.claude          exit 0   (allowed)
rm -rf "$HOME/.claude/.claude"    exit 0   (allowed)
rm -rf ~/.claude                  exit 2   (refused)
```

The guard matches the configuration directory EXACTLY, as `hooks/safety-net.sh` line 108
shows, so a nested path under it is not the case it fires on. Either spelling of the cleanup
command runs. The `$HOME` form is kept above because it is unambiguous, not because the tilde
form is blocked.

| Piece | Gives | Reached from | Without it |
|---|---|---|---|
| `conorbronsdon/avoid-ai-writing` | Audits and rewrites AI writing patterns. Three modes: rewrite, detect, edit in place | `docs/PROSE.md` | That file's own list stands alone, and `hooks/slop-block.sh` still runs |
| `bitjaru/styleseed` | Design judgement, as a render, score and revise loop | `docs/SCREENS.md` | That file's axes table stands alone |
| `agnix` | Validates `CLAUDE.md`, `SKILL.md`, hooks and MCP config | `skills/checkup` | Checkup reports the check as unrun |
| `@yawlabs/ctxlint` | Lints agent context files against the actual codebase, so a reference to nothing is caught | `skills/checkup` | Same |
| `NVIDIA/SkillSpector` | Security-scans a skill for prompt injection, exfiltration and supply-chain risk before install | `skills/checkup` | Read the skill yourself first |

## Two pieces that used to be listed here

**`cxpak` never existed.** It was published in this file on 2026-08-21 with a description and a
consumer in `skills/build/stages/5-build.md`, and no package of that name has ever been on npm.
The reuse search that named it uses grep, which is what it always did.

**`claude-code-safety-net` was redundant.** `hooks/safety-net.sh` ships in this repo, needs no
install, and is covered by 109 assertions across two files: 47 in `hooks/tests/safety-net.test.sh`
for the delete, git and disk rules, and 62 in `hooks/tests/safety-net-exec.test.sh` for the
code-execution and data-egress rules. Both run on every push, because `verify.sh` row 1b globs
`hooks/tests/*.test.sh`. This line said "47 tests" until 2026-08-22, which was the count before
the second file existed. The number is written out here rather than derived, so it will go stale
again; what stops it going stale silently is that both files print their own totals when run.

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
