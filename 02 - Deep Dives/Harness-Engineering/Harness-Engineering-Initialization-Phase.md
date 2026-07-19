---
type: enriched-note
topic: "The Initialization Phase"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - initialization
---

# The Initialization Phase

> [!tip] Quick Recap
> Initialization and implementation are two fundamentally different kinds of work with opposite goals. Mix them and the agent shortchanges infrastructure for visible code. Make the first session do *only* setup — runnable env, one passing test, a startup checklist, a task breakdown, a committed checkpoint. Anthropic measured a 31% higher completion rate from doing this.

## Core Idea

The better approach: before letting the agent start working, use a separate phase to get the base environment ready, run verification commands through, and understand the project structure. Initialization work should not be crammed together with feature implementation — they are two fundamentally different kinds of tasks.

The implementation phase aims to maximize the quantity and quality of *verified features.* The initialization phase aims to maximize the *reliability and efficiency of all subsequent implementation.*

When you mix the two, the agent faces a multi-objective optimization problem: build infrastructure *and* write feature code simultaneously. Without explicit priority setting, the agent gravitates toward writing code (directly visible output) while sacrificing infrastructure (its value only shows up in later sessions). The result: infrastructure isn't solid, and the feature code's reliability suffers too.

![[Pasted image 20260618190525.png]]

Anthropic's long-running application research explicitly recommends separating initialization from implementation. Their data: projects using a dedicated initialization phase showed **31% higher feature completion rates** in multi-session scenarios compared to mixed approaches. And the time invested in initialization is fully recovered within the next 3–4 sessions.

## How It Works — Doing Initialization Right

The first session does *only* initialization — no business feature code at all. Initialization produces:

**1. Runnable environment.** The project starts, dependencies install, no environment issues.

**2. Verifiable test framework.** At least one example test passes, proving the test framework itself is properly configured.

**3. Startup readiness checklist document:**

```text
# Startup Readiness Checklist

## Start Commands
- Install dependencies: `make setup`
- Start dev server: `make dev`
- Run tests: `make test`
- Full verification: `make check`

## Current State
- All dependencies installed and locked
- Test framework configured (Vitest + React Testing Library)
- Example test passing (1/1)
- Lint rules configured (ESLint + Prettier)

## Project Structure
- src/ — Source code
- src/components/ — React components
- src/api/ — API client
- tests/ — Test files
```

**4. Task breakdown.** An ordered task list, each with clear acceptance criteria:

```text
## Task 1: User Authentication Basics
- Implement JWT auth middleware
- Add login/register endpoints
- Acceptance: pytest tests/test_auth.py all passing
```

**5. Git commit as checkpoint.** Commit a clean checkpoint after initialization. All subsequent work starts from here.

## Key Details

**Start from a template, not an empty directory.** Use a project template (create-react-app, fastapi-template, etc.) to preset standard directory structure, dependency configuration, and test framework. Starting from a template far outperforms starting from scratch, where the agent must infer everything from nothing.

**Initialization completion criteria** are not "how much code was written," but whether the startup readiness checklist's four conditions are met: **can start, can test, can see progress, can pick up next steps.**

```text
## Initialization Acceptance Checklist
- [ ] `make setup` succeeds from scratch
- [ ] `make test` has at least one passing test
- [ ] A new agent session can answer "how to run" and "how to test" from repo contents alone
- [ ] Task breakdown file exists with at least 3 tasks
- [ ] Everything committed to git
```

**A React project comparison:** the mixed approach (scaffolding + first feature in session 1) left no command docs, no progress file, no task breakdown — session 2 spent ~20 minutes inferring structure. The dedicated-init approach finished session 2 rebuild in under 3 minutes and started straight from the task list. Across the full cycle, the mixed approach's total rebuild time was ~60% higher.

> [!info] ★ Insight
> The core metric for initialization quality is **"time from start to first passing test"** and **"success rate of subsequent sessions."** Both measure the same thing: did the first session make every later session cheaper? Infrastructure has no visible output, which is precisely why it loses to feature code unless you wall it off into its own phase.

## Connections

- [[Harness-Engineering-State-Persistence]] — initialization produces the first clean handoff state
- [[Harness-Engineering-Feature-List-Primitive]] — the task breakdown is the seed of the feature list
- [[Harness-Engineering-Session-Hygiene]] — "always ready to hand off" is maintained, not just established
- [[Harness-Engineering-Five-Subsystems]] — the Environment subsystem

## References

- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Harness design for long-running apps — Anthropic](https://www.anthropic.com/engineering/harness-design-long-running-apps)
