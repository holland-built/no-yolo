---
name: xcheck
description: Use this skill when the user types /xcheck, says 'bounce this off codex', 'cross-check this plan', or 'second model opinion'. Sends a plan/diagnosis/decision to OpenAI Codex for critique, Claude adjudicates each finding, patches the artifact, max 2 rounds. Also invoked internally by /plan, /debate, /build, /diagnose --debate, /design-audit.
user-invocable: true
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
codex exec --skip-git-repo-check --sandbox read-only -m gpt-5.6-sol "Read the file .xcheck/<slug>-r<N>.md — a plan/diagnosis authored by another AI. Critique it. Do NOT rewrite it. Return ONLY numbered findings, one per line, exactly this format:
FINDING <n> | blocking|major|minor | <one-sentence issue> | <one-sentence suggested change>
Blocking = plan fails or causes damage as written. Major = meaningful gap or wrong assumption. Minor = style/nice-to-have. Max 8 findings. No preamble." < /dev/null
```

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

- `codex exec` without `< /dev/null` blocks forever on "Reading additional input from stdin..." when run non-interactively — always close stdin.
- Without `--skip-git-repo-check`, codex hangs on a prompt outside a git repo.
- A critique round takes 1–3 minutes — set Bash timeout ≥ 300000 and never run it backgrounded-and-forgotten inside a host skill gate.
- Model is pinned with `-m` (critique quality matters more than cost here). If that model errors as unknown/deprecated, drop the `-m` flag — falls back to `~/.codex/config.toml`'s default — and tell the user to update the pin.
