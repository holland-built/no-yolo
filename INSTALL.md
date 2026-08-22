# Outside pieces this setup uses

Thirteen borrowed pieces: seven skills, four npm command-line tools (one of them never
installed, run on demand), one Python scanner, one prose linter from Homebrew. Each one is
optional: the file that reaches for it carries a fallback, so a machine with none of these
installed still works.

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

Seven are skills, installed by the `skills` CLI. Three are npm command-line tools:

```bash
npx skills@latest add conorbronsdon/avoid-ai-writing -g -y -a claude-code && \
npx skills@latest add bitjaru/styleseed -g -y -a claude-code && \
npx skills@latest add mattpocock/skills -g -y -a claude-code --skill writing-for-agents && \
npx skills@latest add mattpocock/skills -g -y -a claude-code --skill codebase-design && \
npx skills@latest add mattpocock/skills -g -y -a claude-code --skill domain-modeling && \
npx skills@latest add anthropics/skills -g -y -a claude-code --skill mcp-builder && \
npx skills@latest add obra/superpowers -g -y -a claude-code --skill systematic-debugging && \
npm install -g agnix @yawlabs/ctxlint jscpd
```

`vale` is the prose linter behind `verify.sh`'s "vale prose lint" row and `hooks/slop-block.sh`.
It is one static Go binary and comes from Homebrew:

```bash
brew install vale
```

On Linux, take the release tarball from `vale-cli/vale` instead. Homebrew is on the
`ubuntu-latest` image but not on its PATH, so `.github/workflows/ci.yml` installs vale that way
on both of its Linux jobs, and those two steps are the worked example to copy.

`@modelcontextprotocol/inspector` installs nothing. It is run on demand,
`npx @modelcontextprotocol/inspector`, which fetches it for that run and leaves nothing behind.

Three flags carry the weight. `-g` installs for every project rather than the working
directory, `-a claude-code` writes a real directory under `~/.claude/skills/` that Claude Code
loads, and `--skill <name>` takes one skill out of a repo that holds many. Run on 2026-08-22,
this form produced directories, not symlinks.

`--skill` is the whole reason `obra/superpowers` appears as one line rather than a plugin
install. Its other skills carry hard gates that collide with `/build`, so only
`systematic-debugging` is taken.

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

## StyleSeed installs 23 doors, and keeps them

Measured on 2026-08-22: the line above puts real directories at `~/.claude/skills/styleseed`
and `~/.claude/skills/ss-*`, 22 of the latter, and all 23 load as commands in every session.

They stay. `styleseed` is a router whose `SKILL.md` dispatches to the `ss-*` skills by name
through the Skill tool, so a router without them loaded reaches nothing. The 22 are the
mechanism, not litter.

Earlier versions of this file told you to delete them, which was right for what the earlier
install command produced. Without `-g -a claude-code`, the `skills` CLI resolved its output
directory against the working directory: run from `~/.claude`, it wrote a nested
`~/.claude/.claude/skills` full of symlinks plus a `skills-lock.json` at the repo root. The
flags in the install block fix that at the source, so there is nothing left to clean up.

If you have that nested directory from an older install, `rm -rf
"$HOME/.claude/.claude/skills" "$HOME/.claude/skills-lock.json"` clears it. Name the `skills`
directory and not its parent: Claude Code writes its own `.claude/settings.local.json` there
when `~/.claude` is opened as a project, and the broad form takes that with it.

That older passage also claimed that `hooks/safety-net.sh` refuses the `rm` above when the path is
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
| `writing-for-agents` | The two-budget vocabulary at length, plus `SKILL-MECHANICS.md` on frontmatter, invocation choice and router skills | `docs/WRITING.md` | That file is the whole standard, minus the mechanics |
| `codebase-design` | Deep-module vocabulary: where a seam goes, what a shallow interface costs | `skills/build/stages/4-tests.md`, `5-build.md` | Those stages design without the shared words |
| `domain-modeling` | Builds a project's domain model, its `CONTEXT.md` and its ADRs | `skills/build/stages/1-interview.md` | The interview asks its own questions |
| `mcp-builder` | How to write an MCP server that an LLM can actually drive, in Python or TypeScript | Any MCP server work | Read the MCP spec yourself |
| `systematic-debugging` | A gate that makes you reproduce and explain before you patch | `docs/TESTING.md` | That file's Diagnosing section stands alone |
| `agnix` | Validates `CLAUDE.md`, `SKILL.md`, hooks and MCP config | `skills/checkup` | Checkup reports the check as unrun |
| `@yawlabs/ctxlint` | Lints agent context files against the actual codebase, so a reference to nothing is caught | `skills/checkup` | Same |
| `NVIDIA/SkillSpector` | Security-scans a skill for prompt injection, exfiltration and supply-chain risk before install | `skills/checkup` | Read the skill yourself first |
| `vale` | Lints every tracked `.md` against the rules in `styles/NoYolo/`, the half of the prose standard a regex cannot hold | `verify.sh` row "vale prose lint", `hooks/slop-block.sh` | The hook stays silent on that half and the verify row records WARN |
| `jscpd` | Finds a block pasted and then edited, which no name search catches | `hooks/dupe-check.sh`, run by `verify.sh` and `skills/build/stages/5-build.md` | The repeated-name pass still runs and the output says "jscpd: did not run, not installed" |
| `@modelcontextprotocol/inspector` | Drives an MCP server's tools by hand, so a client is written against the tool surface the server really has | `skills/build/stages/0-evidence.md` | Read the server's own source for its tool list |

## Vetting

Every skill above was run through `skillspector scan --no-llm` on 2026-08-22 before it was
trusted. Four came back 0/100: `writing-for-agents`, `codebase-design`, `domain-modeling` and
`styleseed`. Three did not, and all three were then read line by line:

| Skill | Score | What the hits were |
|---|---|---|
| `mcp-builder` | 75/100 HIGH | An OAuth best-practice bullet, and a Python `self.env = env` assignment in an example server |
| `systematic-debugging` | 52/100 HIGH | A `security find-identity` line inside a debugging walkthrough |
| `avoid-ai-writing` | 100/100 CRITICAL | The scanner walked the whole repo: a `.gitignore` naming credential paths, and a cursor-rules README. Its `SKILL.md` is clean |

Every one of those is documentation about a thing, not the thing. Judged noise, and the
judgement is a human read of the cited lines rather than the scanner's verdict.

**The LLM pass did not run**, for want of a configured API key. So what is above is the
pattern-matching half alone, and a skill that hides its intent in prose the regexes do not
match would pass it. Read a skill yourself before you trust it with your machine.

## Two pieces that used to be listed here

**`cxpak` was never on npm.** It was published in this file on 2026-08-21 as an npm package with
a consumer in `skills/build/stages/5-build.md`, and npm has never carried a package of that
name. The project itself is real: `Barnett-Studios/cxpak` on GitHub, last pushed 2026-08-14,
installed with cargo or a brew tap. Nothing here installs it, and the reuse search that named
it uses grep, which is what it always did.

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
