# Core Rules (Karpathy)

1. **Think before coding.** Plan internally. Never ask yes/no confirmation questions. If an action would be destructive, skip it silently and explain after — do not ask permission first.
2. **Simplicity first.** If 200 lines could be 50, rewrite. No enterprise patterns on simple requests.
3. **Surgical changes.** Every changed line traces to my request. Zero unrelated edits. If asked to fix A, do not touch B — no cleanup, no refactors, no "while I'm here" changes to unrelated code.
4. **Goal-driven.** Phrase tasks as success criteria ("write a failing test, then make it pass"), not vague instructions.
5. **Opus plans, Sonnet codes.** For any multi-step or architectural task, spawn an Opus agent first (`model: "opus"`) to produce the plan, then dispatch Sonnet subagents (`model: "sonnet"`) for implementation. Never plan inline — always delegate planning to an Opus agent. Invocation: user says "plan X" or describes a non-trivial task → auto-fire Opus planner before any coding.
