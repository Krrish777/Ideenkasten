---
type: enriched-note
topic: "Architectural Boundaries & Agent-Oriented Error Messages"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - architecture
---

# Architectural Boundaries & Agent-Oriented Error Messages

> [!tip] Quick Recap
> Agents copy whatever patterns already exist in the repo — good or bad — so architectural constraints must exist on day one and be mechanically enforced. Enforce invariants, don't micromanage implementation. And write error messages *for the agent*: not just "what went wrong" but "how to fix it," which turns a rule into a self-correction loop.

## Core Idea

The prerequisite for end-to-end testing is that the system has clear boundaries. If the architecture is a tangled mess, end-to-end testing will only prove "the whole mess runs" without telling you where design intent was violated.

OpenAI's experience: **for agent-generated codebases, architectural constraints must be established as early prerequisites on day one — not something to think about once the team has grown.** The reason is straightforward: agents copy existing patterns in the repository, even when those patterns are inconsistent or suboptimal. Without architectural constraints, agents introduce more drift with every session.

## How It Works — Layered Domain Architecture

OpenAI adopted a **Layered Domain Architecture**, where each business domain is divided into fixed layers:

```text
Types -> Config -> Repo -> Service -> Runtime -> UI
```

Dependencies flow strictly forward, and cross-domain concerns enter through explicit `Providers` interfaces. Any other dependency is forbidden and mechanically enforced via custom linting.

> [!note] Source enrichment (OpenAI, verified 2026-06-19)
> Cross-cutting concerns (auth, connectors, telemetry, feature flags) all enter through a **single explicit `Providers` interface** — anything else is disallowed and enforced mechanically. The broader pattern: AGENTS.md should never stand alone. Pair it with **pre-commit hooks, linters, and type checkers** that catch violations before a human sees them, and run **recurring automations (e.g. daily)** that scan for guidance gaps and suggest what to add to AGENTS.md. A rule the model cannot mechanically trip over beats a rule it has to remember.

Key principle: **enforce invariants; don't micromanage implementation.** For example, require that "data is parsed at the boundary," but don't prescribe which library to use. And error messages must include fix instructions — not just "violation," but how to change it.

## Turning Rules into Executable Checks

Every architectural constraint should have a corresponding test or lint rule:

```bash
# Check whether the renderer process directly calls Node.js APIs
grep -r "require('fs')" src/renderer/ && exit 1 || echo "OK: no direct fs access in renderer"
```

## Agent-Oriented Error Messages

OpenAI emphasizes in its Codex engineering practices: **error messages written for agents must include fix instructions.** Instead of writing `"Direct filesystem access in renderer"`, write:

> "Direct filesystem access in renderer. All file operations must go through the preload bridge. Move this call to `preload/file-ops.ts` and invoke it via `window.api`."

This turns architectural rules into an auto-correction loop. Error messages don't just tell you "what went wrong" — they tell you "how to fix it," enabling the agent to correct itself autonomously.

Failure messages should contain three elements — what went wrong, why, and how to fix it:

```text
ERROR: Found direct import of 'fs' in src/renderer/App.tsx:12
WHY: Renderer process has no access to Node.js APIs for security
FIX: Move file operations to src/preload/file-ops.ts and call via window.api.readFile()
```

## Key Details — The Review-Feedback Promotion Process

Every time you discover a new category of agent error during code review, **turn it into an automated check.** A month later your harness will be far stronger than it was at the start of the month.

This is the mechanism that compounds: human taste, captured once in review, becomes a mechanical check enforced forever — so the same mistake never costs human attention twice.

> [!info] ★ Insight
> "Enforce invariants, don't micromanage" is the architectural analogue of "give a map, not a manual." Both fight the same enemy: instructions that try to dictate every step. A boundary the agent *cannot* cross (mechanically enforced) is worth more than ten paragraphs telling it not to — because the agent reads code patterns far more reliably than prose rules.

## Connections

- [[Harness-Engineering-Beyond-Unit-Tests-E2E]] — boundaries are the prerequisite that makes E2E meaningful
- [[Harness-Engineering-Preventing-Premature-Victory]] — actionable error feedback feeds termination validation
- [[Harness-Engineering-Session-Hygiene]] — drift is what un-enforced boundaries accumulate into
- [[Harness-Engineering-Instructions-Drawing-A-Map]] — "enforce invariants" mirrors "give a map"

## References

- [Harness Engineering — OpenAI](https://openai.com/index/harness-engineering/)
- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
