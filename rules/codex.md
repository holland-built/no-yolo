# Calling Codex

The single source for how the second-model check runs. Every command that uses Codex reads
this file.

## The invocation

One wrapper holds it, so a change reaches every caller at once:

```bash
bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/codex.sh" --tier <name> "<prompt>" [output-file]
```

Inside it: `codex exec --sandbox read-only --skip-git-repo-check -m <model> -c
model_reasoning_effort=<effort> "<prompt>" < /dev/null`. Three parts earn their place, each
learned by watching it fail on 2026-08-21:

| Part | Without it |
|---|---|
| `< /dev/null` | Waits on standard input forever. Silent for 40 minutes, looking like a slow model |
| `--skip-git-repo-check` | Refuses to run outside a trusted directory |
| `--sandbox read-only` | Codex could write to the tree. It advises; it never edits |

The prompt is an argument. Piping the file and passing the prompt as well is a usage error.

## Why it is read-only

Codex advises. It never edits, and it has no network. Both follow from `read-only`, and
neither is negotiable per-call.

The model and the effort are set by `--tier`, in the wrapper's flags, which beat
`~/.codex/config.toml`. Omitting `--tier` gives sol at high. Until 2026-08-21 nothing stated
these, which is how every review ran at the lowest setting unnoticed.

Needing a network is a signal that the work belongs to this repo instead. Resolving an
external name is `hooks/external-check.sh`, which runs on every push. `docs/DECISIONS.md`
carries what happened when the sandbox was widened, and why `danger-full-access` was declined.

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

Six jobs, and they are not one job, so each names its tier. Measured against `codex-cli
0.150.1` on 2026-08-28: every model and effort below is accepted, and a wrong one returns HTTP
400 with exit status still 0, so empty output reports a failed call, never the code.

| Stage | `--tier` | Model, effort | What Codex gets |
|---|---|---|---|
| Plan | `plan` | sol, xhigh | The written plan, before any code exists. The call that catches blockers |
| Mockups | `mockup` | sol, low | The screenshot of the variant set, plus authorship of the slot `rules/mockups.md` assigns it |
| Tests | `tests` | luna, high | The spec and public interface only, never the implementation |
| Review | `review` | terra, high | The diff |
| Rival | `rival` | terra, medium | The approved plan. Adjudicated hunk by hunk |
| Handoff | `gaps` | luna, medium | The handoff file, read for what is missing |
