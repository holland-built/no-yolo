# Outside pieces this setup uses

Twelve borrowed pieces: six skills, four npm command-line tools (one of them never
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

Six are skills, installed by the `skills` CLI. Three are npm command-line tools:

```bash
npx skills@latest add conorbronsdon/avoid-ai-writing -g -y -a claude-code && \
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

## A skill that installs more than one door

Some of these repos hold a router plus the skills it dispatches to, so one install line
produces many loaded commands. That is the mechanism and not litter: a router whose siblings
are missing reaches nothing. Count the directories after installing and expect more than one.

Where an older install left a mess, it was the flags and not the count. Without
`-g -a claude-code`, the `skills` CLI resolved its output directory against the working
directory: run from `~/.claude`, it wrote a nested `~/.claude/.claude/skills` full of symlinks
plus a `skills-lock.json` at the repo root. The flags in the install block fix that at the
source, so there is nothing left to clean up.

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

## Optional connections

**Nothing here is needed to use this repo, and nothing checks for them.** They are tool servers
that a session attaches at startup, and they are listed because they were wired up on the
owner's machine and someone reading this should be able to make the same choice deliberately
rather than by copying a config they cannot see.

They are deliberately absent from the pieces table above and from `hooks/installed.txt`. That
manifest is what `verify.sh` proves is PRESENT on every push, so putting an optional thing in it
would hand everyone who clones this a red check for something they chose not to install.

| Server | What it adds | Wire it up |
|---|---|---|
| Playwright | Drives a real browser: clicking, filling forms, screenshots | `claude mcp add playwright -s user -- npx -y @playwright/mcp@latest` |
| Firecrawl | Fetches pages that block a plain request, and the search behind `/last-30` | `claude mcp add firecrawl -s user -e FIRECRAWL_API_URL=<your-instance> -- npx -y firecrawl-mcp` |

Both were registered on 2026-08-26 and both report Connected.

**A tool server attaches when a session STARTS.** Registering one mid-session does not make its
tools appear in that session, and neither does asking again. Open a new one.

**Firecrawl needs an instance to point at.** The owner self-hosts one; the hosted service takes
a `FIRECRAWL_API_KEY` instead of a URL. A self-hosted box does not need the key unless it was
configured to want one. If the first search returns 404, add `/v1` to the URL: builds differ on
whether they expect the version in the path.

**Firecrawl's own build decides what a caller may send.** The owner's instance rejects
`includeDomains`, `categories`, `sources` and `highlights`, and one rejected key fails the whole
call rather than being ignored. `skills/last-30/SKILL.md` records which parameters were measured
working, and restricts a search by writing `site:<domain>` into the query instead.

## Vetting

Every skill above was run through `skillspector scan --no-llm` on 2026-08-22 before it was
trusted. Three came back 0/100: `writing-for-agents`, `codebase-design` and `domain-modeling`.
A fourth clean result belonged to `styleseed`, which was retired on 2026-08-25 and is no longer
listed here. Three did not come back clean, and all three were then read line by line:

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

## Three pieces that used to be listed here

**`bitjaru/styleseed` was retired on 2026-08-25**, and this file went on installing it for the
rest of that day. The session that retired it left six references behind, and a later search
for an unrelated fault found them: the install line, a pieces row, two pointers sending design
work to it, and a section headed "and keeps them". A hash-verified snapshot is tracked at
`archive/styleseed/` and `docs/BORROWED.md` carries its row, so nothing is lost. Why it was
retired rather than kept is in `docs/DECISIONS.md`.

**It was cleared off the machine later the same day, and the first check said so wrongly.**
That check was `ls skills/styleseed` and `ls ~/.agents/skills/styleseed`, both reporting no
such file, and it proved nothing: StyleSeed never installed a directory under its own name. It
installed its skills under theirs, and `ss-resolve` and `ss-score` were still in
`~/.agents/skills` describing themselves as compiling and scoring against rules that by then
existed only under `archive/`. They now sit outside every load path, in
`~/.agents-retired-2026-08-25/`, kept rather than deleted because the copies on disk had
updated past the revision the archive pins. `hooks/retired.txt` records the names a retired
piece leaves behind so the next one is not cleared by looking for the wrong thing, and
`verify.sh`'s "pieces on this machine" row checks them on every push.

Design judgement now rests on the axes table in `docs/SCREENS.md`, which was always the
documented fallback for this skill's absence.

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
