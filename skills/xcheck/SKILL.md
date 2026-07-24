---
name: xcheck
description: Use this skill when the user types /xcheck, says 'bounce this off codex', 'cross-check this plan', or 'second model opinion'. Sends a plan/diagnosis/decision to OpenAI Codex for critique, Claude adjudicates each finding, patches the artifact, max 2 rounds. Also invoked internally by /plan, /debate, /build, /diagnose --debate, /design-audit.
user-invocable: true
effort: high
argument-hint: "[artifact to cross-check — plan text, file path, or 'last plan']"
allowed-tools:
  - Bash
  - Read
  - Write
---

# xcheck — cross-model critique loop

Claude authors. Codex critiques. Claude adjudicates. Never the other way around.

## Preflight (silent)

```bash
command -v codex >/dev/null && echo CODEX_OK || echo CODEX_MISSING
```

If `CODEX_MISSING` (or any codex call errors): print exactly one line — `xcheck skipped — Codex unavailable (install: /plugin install codex@openai-codex)` — return the artifact **unchanged**, and let the calling skill continue. Never block a host skill on Codex.

## Protocol

**Ownership rule (hard):** Codex returns findings only — it never rewrites the artifact. Claude applies accepted findings itself, preserving the artifact's structure and voice.

### Round (max 2 — hard cap)

1. Write current artifact to `.xcheck/<slug>-r<N>.md` (create dir; slug = kebab of topic).
2. Send to Codex, read-only:

```bash
bash ~/.claude/skills/xcheck/scripts/codex-run.sh -m gpt-5.6-sol -t 300 "Read the file .xcheck/<slug>-r<N>.md — a plan/diagnosis authored by another AI. Critique it. Do NOT rewrite it. Return ONLY numbered findings, one per line, exactly this format:
FINDING <n> | blocking|major|minor | <one-sentence issue> | <one-sentence suggested change>
Blocking = plan fails or causes damage as written. Major = meaningful gap or wrong assumption. Minor = style/nice-to-have. Max 8 findings. No preamble."
```

> `codex-run.sh` is the shared process-level runner (stdin close, git-repo skip, timeout, pinned-model fallback with a stderr warning). Any skill calling `codex exec` directly should use it instead — output parsing stays with the caller.

Parse only lines matching `^FINDING` from the output (codex echoes the prompt and prints hook/token noise around them).

3. **Adjudicate** — for each finding, Claude rules ACCEPT or REJECT with a one-line reason. Grounding beats opinion: reject anything the codebase/evidence contradicts. Minor findings may be batch-rejected in one line.
4. **Patch** — apply accepted findings to the artifact yourself (surgical edits, keep structure).

### Convergence gate

- Stop after a round that produces **zero newly-ACCEPTED blocking or major findings** (minors never extend the loop — models nitpick forever).
- Hard cap 2 rounds. Never a third.

## Output

Return the patched artifact plus:

```
**xcheck:** <N> round(s) · <a> accepted / <r> rejected
**Dissent (rejected, for the record):**
- <finding> — rejected: <reason>
```

Skip the dissent block if nothing was rejected. Delete `.xcheck/` files after the host skill completes.

## Gotchas

- The stdin-hang, git-repo-prompt, timeout, and model-fallback gotchas are all handled inside `scripts/codex-run.sh` — never call `codex exec` directly from this skill.
- A critique round takes 1–3 minutes — set Bash timeout ≥ 310000 (above the runner's own 300s) and never run it backgrounded-and-forgotten inside a host skill gate.
- If the runner warns the pinned model was rejected, tell the user to update the pin in this file.
