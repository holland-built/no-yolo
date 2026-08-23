# Calling Codex

The single source for how the second-model check runs. Every command that uses Codex reads
this file.

## The invocation

One wrapper holds it, so a change reaches every caller at once:

```bash
bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/codex.sh" "<prompt>" [output-file]
```

Inside it: `codex exec --sandbox read-only --skip-git-repo-check "<prompt>" < /dev/null`.
Three parts earn their place, each learned by watching it fail on 2026-08-21:

| Part | Without it |
|---|---|
| `< /dev/null` | Waits on standard input forever. Silent for 40 minutes, looking like a slow model |
| `--skip-git-repo-check` | Refuses to run outside a trusted directory |
| `--sandbox read-only` | Codex could write to the tree. It advises; it never edits |

The prompt is an argument. Piping the file and passing the prompt as well is a usage error.

## What it is actually running

Not stated anywhere until 2026-08-21, which is how it went unnoticed that every review this
setup had ever run used the lowest reasoning setting the model offers. A file calling itself
the single source for how the check runs has to carry the settings that decide what comes back.

| Setting | Value | Set in |
|---|---|---|
| Model | `gpt-5.6-sol` | `~/.codex/config.toml` |
| Reasoning effort | `high` | `~/.codex/config.toml` |
| Sandbox | `read-only` | The `--sandbox` flag in `hooks/codex.sh`, which overrides the config |
| Network | none, which `read-only` implies | Not configurable in this mode |

## Why it is read-only, having briefly not been

The sandbox was widened to `workspace-write` on 2026-08-21 to give Codex a network, because a
read-only sandbox has none and it had just reviewed seven invented package names without being
able to look up one of them. Measured, not assumed: under `read-only`, `curl` returns 000 and
`npm view` returns ENOTFOUND. The `network_access` setting belongs to `workspace-write` alone,
so the two cannot be separated.

Within the hour, during two reviews whose prompts asked for findings and nothing else, Codex
wrote a new step into `SHIP.md` and rewrote a section of `docs/DECISIONS.md`. Both edits turned
out to be substantially correct, and neither was requested. An advisor that edits is not an
advisor, and a review you have to diff afterwards costs more than it returns.

**Verification moved instead of the sandbox.** `hooks/external-check.sh` resolves every
external name against the registry on every run of `verify.sh`, so the job that needed a
network now belongs to this repo and runs on every push, rather than to a model that runs only
when a skill invokes it. Codex is back to what it is good at, which is judgement about a plan
or a diff, and that needs no network at all.

`danger-full-access` was considered and declined at the same time. It reaches the whole disk,
including `~/.ssh` and `~/.aws`, and `codex exec` runs with `approval: never`, so nothing would
sit between a generated command and the filesystem. `hooks/safety-net.sh` is no help there: it
is a Claude Code hook on Claude's own commands and never sees Codex's.

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

A missing binary, a timeout, or empty output is reported as "Codex: did not run", followed by the reason.
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
