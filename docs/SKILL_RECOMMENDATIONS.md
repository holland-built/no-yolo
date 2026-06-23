# Skill Library — Improvement Recommendations

Sourced from personal knowledge base. These are **additive, not corrective** — the KB *validates* the current skill library (run `/my-skills` for the live count); in fact most existing skills (plan, tdd, diagnose, code-review, graphify, trim pack) were designed FROM this research. Nothing below is applied; pick what's worth doing.

Each row cites its KB source. Audited 2026-06-18.

---

## A. New skills / tools to consider installing

| Idea | What it adds | Cost | KB source |
|---|---|---|---|
| **plan-codex** | Cross-model adversarial review — Codex + Claude iterate ≤5 rounds. Round 2+ catches "false fixes" (claimed-but-unwired changes, still-blocking awaits). Pre-build gate, complements post-build review. | OpenAI $20/mo + Codex | vid-plan-codex-review, pattern-adversarial-review |
| **Nvidia MCP security scanner** | Pre-install audit of third-party skills/MCP servers (scans for exec, curl-pipe, cookie-paste vectors). Run before installing any external skill. | ~$5/repo | vid-new-vibe-coding-repos |
| **Handy** | Local Whisper voice-to-text (free, offline). Pairs with `improve`: dictate thoughts → improve → GitHub issues → overnight agent loop. | free | vid-new-vibe-coding-repos |
| **claude-context / LSP** | Symbol-precise navigation for big repos. LSP shipped in v2.0.7, off by default — enable for multi-language repos. Third option alongside graphify (structural) and vector index (semantic). | free | pattern-claude-code-harness, tool-claude-context |

---

## B. Optimizations to existing setup

| Optimization | Effect | KB source |
|---|---|---|
| **Path-scope skills** (bind to globs) | Skills load only where relevant instead of every session. KB cites 30–40k tokens/session burned on skill bloat before the first question. Biggest single context win. | pattern-claude-code-harness |
| **Sub-agent scout pattern** | At session start, spin 3 read-only Explore scouts (e.g. DB / UI / scope-the-change). Main agent reads 3 summaries instead of 3 full crawls. KB calls this "the single biggest difference" in daily sessions. | pattern-claude-code-harness, vid-fix-claude-code-harness |
| **Static-then-LLM two-pass review** | Run `fallow` (deterministic, free, instant) BEFORE `trim` (LLM). Strips structural noise so the LLM pass spends tokens on judgment, not obvious dead code. code-health already sequences this — apply the principle elsewhere. | pattern-static-then-llm-review |
| **Catalog README for skills dir** | A discovery doc: what each skill kills, when to use it, cost/benefit. KB's highest-adoption pattern ("the catalog is the artifact"). The new RELATIONSHIPS.md is a start. | pattern-skills-over-frameworks |

---

## C. Best-practice hygiene

| Practice | What | Cadence | KB source |
|---|---|---|---|
| **CLAUDE.md bloat test** | For each line: delete it; if Claude doesn't regress, it was dead weight. KB reports ~80% of bloated files get cut. Old rules written for weaker models now constrain newer ones. | quarterly | vid-fix-claude-code-harness |
| **brainstorms/ checkpointing** | Commit each decision to a dated md file during long sessions (context window fills, early answers forgotten). plan + forge already do this — extend to all long sessions. | per session | vid-plan-skill |
| **Generator ≠ evaluator** | Never let one model grade its own work — it says "great" regardless. Inject a neutral critic (different vendor, sub-agent, or feedback loop). | always | pattern-adversarial-review |

---

## Architectural frame (the 7-point harness)

KB's unifying model, ordered by leverage: **1.** CLAUDE.md (layered) → **2.** Hooks (self-improving) → **3.** Skills (path-scoped) → **4.** Plugins (full-stack installs) → **5.** LSP (symbol nav) → **6.** MCP (external tools, sequence last) → **7.** Sub-agents (context isolation). "Harness > model" — at scale the configuration beats waiting for the next Opus. *(pattern-claude-code-harness)*
