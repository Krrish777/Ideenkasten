---
type: enriched-note
topic: "State Persistence & Multi-Session Continuity"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - state-management
  - context-management
---

# State Persistence & Multi-Session Continuity

> [!tip] Quick Recap
> Treat the agent like an engineer whose short-term memory is wiped every session. Before it clocks out, it must write down what matters so the next shift picks up fast. Manage that state with ACID discipline, and know your model: context anxiety makes context *reset* (not just compaction) essential for some models.

## Core Idea

Core approach: **treat the agent like an engineer whose short-term memory gets wiped at every session.** Before it "clocks out," it must write down critical information so the next "shift" agent can pick up quickly.

This matters because of a behavior Anthropic observed in long-running agents: when agents sense their context is running low, they exhibit a "rushed finish" — rushing to finish current work, skipping verification steps, or choosing a simple solution over the optimal one. Anthropic calls this **context anxiety.**

![[Pasted image 20260618174251.png]]

## How It Works — Managing State with ACID Principles

This analogy comes from database transaction management. It feels like overcomplication, but it's a very practical framework:

- **Atomicity** — Each logical operation (e.g., "add new endpoint and update tests") gets one git commit. If it fails midway, `git stash` to roll back. All or nothing.
- **Consistency** — Define "consistent state" verification predicates (all tests pass, lint zero errors). The agent runs verification after each operation; inconsistent intermediate states should not be committed.
- **Isolation** — When multiple agents work concurrently, design state files to avoid race conditions. Simple approach: each agent uses its own progress file, or use git branches.
- **Durability** — Critical project knowledge lives in git-tracked files. What's in your head doesn't count — only what's written down counts.

## Practical Tools

**Tool 1: Progress file (`PROGRESS.md`).** The most basic state file — current state, completed, in-progress, known issues, next steps:

```text
# Project Progress

## Current State
- Latest commit: abc1234 (feat: add user preferences endpoint)
- Test status: 42/43 passing (test_pagination_edge_case failing)
- Lint: passing

## Completed
- [x] User model and database migration
- [x] Basic CRUD endpoints

## In Progress
- [ ] Pagination feature (90% - edge case test failing)

## Known Issues
- test_pagination_edge_case returns 500 on empty result sets

## Next Steps
1. Fix pagination edge case bug
2. Add "include deleted users" query parameter
```

**Tool 2: Decision log (`DECISIONS.md`).** Record important design decisions and reasons — what, why, when:

```text
## 2024-01-15: Use Redis for user preferences caching
- Reason: High read frequency, small data size
- Rejected: PostgreSQL materialized view (high change frequency)
- Constraint: Cache TTL 5 minutes, active invalidation on write
```

**Tool 3: Git commits as checkpoints.** Commit after each atomic unit of work — free, automatically versioned state snapshots.

**Tool 4: `init.sh` / harness initialization flow.** Specify the "clock-in" and "clock-out" routines in `AGENTS.md`:

```text
## At session start (clock in)
1. Read PROGRESS.md for current state
2. Read DECISIONS.md for important decisions
3. Run make check to confirm repo is in consistent state
4. Continue from PROGRESS.md "Next Steps"

## Before session end (clock out)
1. Update PROGRESS.md
2. Run make check to confirm consistent state
3. Commit all completed work
```

> [!note] Source enrichment (Anthropic, verified 2026-06-19)
> Anthropic frames this as a **two-agent system**: an **Initializer Agent** sets up the environment on the very first session (creating `init.sh`, a `claude-progress.txt` progress file, and an initial git commit), and a **Coding Agent** handles every session after. The coding agent's fixed startup sequence: run `pwd` to confirm the working directory, read the git log and `claude-progress.txt`, pick the highest-priority unfinished feature, start the dev server via `init.sh`, run a quick end-to-end check, then implement. The guiding metaphor is "engineers working in shifts, where each new engineer arrives with no memory of what happened on the previous shift."

## Key Details — Compaction vs Context Reset

- **Compaction** — summarizing early conversation within the same session. Maintains continuity (the agent sees "what"), but "why" is often lost in summaries. More critically, compaction doesn't eliminate context anxiety — the agent knows context was once large and still tends to rush.
- **Context reset** — completely clearing context, opening a new session, rebuilding from persisted artifacts. Clean mental state with no "running out of time" anxiety, but depends entirely on the completeness of handoff artifacts.

Anthropic's actual data: for **Sonnet 4.5**, context anxiety is severe enough that compaction alone isn't sufficient — context reset becomes a critical harness component. For **Opus 4.5**, this behavior is greatly diminished, and compaction can manage context without resets. The takeaway: **harness design needs specific understanding of the target model, not a one-size-fits-all template.**

A blog-system task (12 feature points, ~5 sessions) made the value concrete:

| Metric | No state files | With state files |
|--------|----------------|------------------|
| Session 2 rebuild cost | ~15 min | ~3 min |
| Feature completion | 7/12 (58%) | 12/12 (100%) |
| Hidden defect rate | 43% | 8% |
| Rebuild time | baseline | ~78% lower |

> [!info] ★ Insight
> Context anxiety is the rare case where the *fix is psychological, not informational*. A reset session has the same artifacts a compacted one does — but no memory of having been "almost out of room," so it doesn't rush. That's why model choice changes the harness: the better the model handles its own context, the less of this scaffolding you need.

## Connections

- [[Harness-Engineering-Initialization-Phase]] — initialization produces the first clean handoff artifact
- [[Harness-Engineering-Feature-List-Primitive]] — the structured alternative to free-form progress notes
- [[Harness-Engineering-Session-Hygiene]] — keeping handoff state clean over many sessions
- [[Harness-Engineering-Five-Subsystems]] — the State subsystem

## References

- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Harness design for long-running apps — Anthropic](https://www.anthropic.com/engineering/harness-design-long-running-apps)
