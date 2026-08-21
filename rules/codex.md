# Calling Codex

The single source for how the second-model check runs. Every command that uses Codex reads
this file.

## The invocation

One wrapper holds it, so a change reaches every caller at once:

```bash
bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/codex.sh" "<prompt>" [output-file]
```

Inside it: `codex exec --sandbox workspace-write --skip-git-repo-check "<prompt>" < /dev/null`.
Three parts earn their place, each learned by watching it fail on 2026-08-21:

| Part | Without it |
|---|---|
| `< /dev/null` | Waits on standard input forever. Silent for 40 minutes, looking like a slow model |
| `--skip-git-repo-check` | Refuses to run outside a trusted directory |
| `--sandbox workspace-write` | Either no network, so it cannot check a claim about the outside world, or no boundary at all |

The prompt is an argument. Piping the file and passing the prompt as well is a usage error.

## What it is actually running

Not stated anywhere until 2026-08-21, which is how it went unnoticed that every review this
setup had ever run used the lowest reasoning setting the model offers. A file calling itself
the single source for how the check runs has to carry the settings that decide what comes back.

| Setting | Value | Set in |
|---|---|---|
| Model | `gpt-5.6-sol` | `~/.codex/config.toml` |
| Reasoning effort | `high` | `~/.codex/config.toml` |
| Sandbox | `workspace-write` | The `--sandbox` flag in `hooks/codex.sh`, which overrides the config |
| Network | on | `[sandbox_workspace_write] network_access` in `~/.codex/config.toml` |

**Codex can now write inside the working tree, and this file said it could not.** That was
true while the sandbox was `read-only`. It stopped being true the moment the sandbox widened,
and the reason to widen it was network: a read-only sandbox has none, so Codex reviewed seven
invented package names without being able to look one of them up. Read what it returns; do not
assume the tree is untouched.

`danger-full-access` was the alternative and was declined. It reaches the whole disk, including
`~/.ssh` and `~/.aws`, and `codex exec` runs with `approval: never`, so nothing would sit
between a generated command and the filesystem. `hooks/safety-net.sh` does not cover this:
it is a Claude Code hook on Claude's own commands and never sees Codex's.

## The prompt shape

Ask for findings, never a rewrite. One per line, so they can be counted and answered:

```
FINDING <n> | blocking|major|minor | <what is wrong> | <the fix>
```

Cap at eight. Ask for no preamble. Name what to hunt for, because a generic "review this"
returns generic findings: collisions between rules, instructions the model follows anyway,
anything readable two ways.

## Adjudication

Read the cited line yourself before accepting a finding. Confirmed findings fold in.
Rejected ones get a one-line reason recorded beside them.

Codex advises and Claude decides, with one exception: nobody grades their own work, so a
Codex-authored artifact is judged by Claude alone, and Codex's verdict on its own work
carries no weight.

## When it did not run

A missing binary, a timeout, or empty output is reported as "Codex: did not run, <reason>".
That is a flag on the check, not a defect in the work, and the work proceeds.

**This applies to the Codex second opinion and to nothing else.** A second opinion that was
unavailable leaves the first opinion intact. Every other gate keeps its own policy: a secret
scan that could not run holds the release closed, because an unrun scan and a clean scan look
identical and the cost of guessing wrong is a published credential.

## Where it fires

| Stage | What Codex gets |
|---|---|
| Plan | The written plan, before any code exists |
| Mockups | The screenshot of the variant set, plus authorship of the slot `rules/mockups.md` assigns it |
| Tests | The spec and public interface only, never the implementation |
| Review | The diff |
