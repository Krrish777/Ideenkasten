---
type: enriched-note
topic: "The Giant Instruction-File Trap"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - instructions
  - context-management
---

# The Giant Instruction-File Trap

> [!tip] Quick Recap
> Every time the agent errs, you add a rule. The file only grows. Eventually it eats the context budget, buries critical rules in the "lost middle," mixes red lines with suggestions, and accumulates contradictions. The fix: split into a short entry file plus on-demand topic docs, and manage instructions like code dependencies.

## Core Idea

This is the "giant instruction file" trap. Everything seems useful, so you cram it all in, and finding one specific rule means rifling through the entire file. You wrote 600 lines, but only a third is relevant to the task at hand.

The most common vicious cycle: the agent makes a mistake → you say "add a rule to prevent this" → you add it to `AGENTS.md` → it works, temporarily. Then the agent makes a different mistake, so you add another rule. Repeat until the file bloats out of control. "Add a rule" every time feels reasonable, but the cumulative effect is disastrous.

## How It Works — What Goes Wrong

- **Context budget gets eaten alive.** Every line in the entry file is loaded every session, relevant or not.
- **Lost in the middle.** LLMs use information at the extremes of a long text significantly better than the center. A rule at line 300 is effectively invisible.
- **Priority conflicts.** The file mixes non-negotiable hard constraints ("never use `eval()`"), important design guidelines ("prefer functional style"), and one-off historical lessons ("fixed a WebSocket memory leak last week"). All three look identical in the file. The agent has no reliable signal to tell a red line from a suggestion.
- **Maintenance decay.** Outdated instructions rarely get deleted — the consequences of deletion feel uncertain, while adding feels cost-free. The file only grows, never shrinks; signal-to-noise steadily declines.
- **Contradiction accumulation.** Instructions added at different times start to contradict each other — one says "use TypeScript strict mode," another says "some legacy files may use `any`." The agent picks one at random each time.

The lever is the **Instruction Signal-to-Noise Ratio (SNR)** — and the cure is **reveal on demand.**

![[Pasted image 20260618173345.png]]

## How to Split

Core principle: keep frequently-needed information at hand, tuck away occasionally-needed information, and don't carry what you'll never use.

The entry file `AGENTS.md` stays at 50–200 lines, containing only the essentials:

```text
# AGENTS.md

## Project Overview
Python 3.11 FastAPI backend, PostgreSQL 15 database.

## Quick Start
- Install: `make setup`
- Test: `make test`
- Full verification: `make check`

## Hard Constraints
- All APIs must use OAuth 2.0 authentication
- All database queries must use SQLAlchemy 2.0 syntax
- All PRs must pass pytest + mypy --strict + ruff check

## Topic Docs
- API Design Patterns (`docs/api-patterns.md`) — Required reading when adding endpoints
- Database Rules (`docs/database-rules.md`) — Required when modifying database operations
- Testing Standards (`docs/testing-standards.md`) — Reference when writing tests
```

Each topic document is 50–150 lines, organized by subject in `docs/` or next to the corresponding module. The agent only reads them when needed. Think of it like packing cubes for luggage — underwear in one cube, toiletries in another. Finding what you need doesn't require emptying the entire bag.

Every instruction should document its **source** ("why was this rule added?"), **applicability condition** ("when is this rule needed?"), and **expiry condition** ("under what circumstances can this rule be removed?"). Audit regularly; delete outdated, redundant, or contradictory entries. Manage your instructions the way you manage code dependencies.

If an instruction absolutely must be in the entry file, put it at the **top or bottom, never the middle** — but moving it into a topic doc for on-demand loading is better.

## Key Details — The 600-Line Case

A SaaS team's `AGENTS.md` ballooned from 50 lines to 600, mixing tech-stack versions, coding standards, historical bug-fix notes, API guides, deployment procedures, and personal preferences. Performance declined: simple bug fixes wasted context on irrelevant deployment instructions; the security rule "all database queries must use parameterized queries" was buried at line 300 and frequently ignored; three contradictory style rules caused random choices.

The split refactoring:
1. Trimmed `AGENTS.md` to 80 lines: overview, run commands, 15 global hard constraints.
2. Created topic docs: `docs/api-patterns.md` (120 lines), `docs/database-rules.md` (60 lines), `docs/testing-standards.md` (80 lines).
3. Added topic-doc links in the entry file.
4. Historical notes were converted to test cases or deleted outright.

After: success rate on the same task set rose **from 45% to 72%.** Security-constraint compliance rose **from 60% to 95%**, because the rule moved from the middle of the file to the top of the entry file — no longer "lost in the middle."

> [!warning] The deletion asymmetry
> Adding a rule feels free; deleting one feels risky ("maybe something depends on it?"). That asymmetry is exactly why the file only grows. Treat the source/applicability/expiry metadata as the antidote — a rule with a written expiry condition is one you can safely remove.

## Connections

- [[Harness-Engineering-Instructions-Drawing-A-Map]] — the disciplined alternative to the bloated file
- [[Harness-Engineering-Five-Subsystems]] — the Instruction subsystem
- [[Harness-Engineering-Session-Hygiene]] — periodic simplification applies to instructions too

## References

- [Harness Engineering — OpenAI](https://openai.com/index/harness-engineering/)
- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
