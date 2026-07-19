---
type: enriched-note
topic: "Scope Control & WIP=1"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - scope-control
---

# Scope Control & WIP=1

> [!tip] Quick Recap
> Attention is a finite resource — split it across k tasks and each gets C/k. Below a threshold, none finish. Agents over-broad prompts start many things and finish none ("overreach"). Enforce WIP=1, demand completion evidence per task, and block new work until the verified completion rate hits 1.0.

## Core Idea

When prompts are too broad, agents tend to "start multiple things at once" rather than "finish one thing first."

This isn't a metaphor — it's math. Assume the agent's context capacity is **C** and it activates **k** tasks simultaneously. Each task gets an average of **C/k** reasoning resources. When C/k drops below the minimum threshold needed to complete a single task, none of them get finished.

Claude Code's real behavior is telling. Ask it to "add user registration" and it might:

1. Create a User model
2. Write the registration route
3. Notice it needs email verification, so add a mail service
4. See that passwords need hashing, so bring in bcrypt
5. Notice error handling is inconsistent, so refactor the global error middleware
6. See the test file structure is messy, so reorganize the directory

Six steps later, every one is half-done. No end-to-end verification, complex coupling between half-baked code, and the next session is completely lost.

![[Pasted image 20260618191838.png]]

## Core Concepts

- **Overreach** — the agent activates more tasks in a session than optimal. Quantifiable: doing 5 features with 0 passing end-to-end is overreach.
- **Under-finish** — the ratio of tasks that pass end-to-end verification, out of all activated, falls below threshold. Code written but tests not passing is under-finish.
- **WIP Limit** — from Kanban: limit how many tasks are in-flight at once. For agents, **WIP=1 is the safest default** — finish one before starting the next.
- **Completion Evidence** — the verifiable condition a task must satisfy to move from "in progress" to "done." Without it, agents substitute "the code looks fine" for "the behavior passes tests."
- **Scope Surface** — a DAG where each node is a work unit and edges are dependencies. States are limited to four: `not_started`, `active`, `blocked`, `passing`.
- **Completion Pressure** — the constraining force the harness exerts through WIP limits and completion-evidence requirements, forcing the agent to finish the current task before starting a new one.

## How to Do It Right

**1. Enforce WIP=1.** The most direct and effective method. In `CLAUDE.md` / `AGENTS.md`:

```text
## Work Rules
- Work on one feature at a time
- Only start the next feature after the current one passes end-to-end verification
- Don't "also refactor" feature B while implementing feature A
```

**2. Define explicit completion evidence for every task.** Done is not "code is written" — it's "behavior verification passes." Every feature-list entry needs a verification command:

```text
F01: User Registration
  Verification: curl -X POST /api/register -d '{"email":"test@example.com","password":"123456"}' | jq .status == 201
  State: passing
```

**3. Externalize the scope surface.** Use a machine-readable file (JSON or Markdown) recording all task states. Any new session reads it and immediately knows: which task is active, what counts as done, what verifications have passed.

**4. Monitor Verified Completion Rate.** Track **VCR = verified tasks / activated tasks.** Block new task activations when VCR < 1.0.

## Key Details — The REST API Case

A REST API project with 8 features, two strategies:

| | Unconstrained | WIP=1 |
|---|---|---|
| Session 1 activity | 5 features at once | registration only |
| Code produced | ~800 lines / 12 files | ~200 lines / 4 files |
| Session 1 E2E pass | 20% (only registration) | 100% |
| Final completion | 3/8 (37.5%) | 7/8 (87.5%, 8th externally blocked) |

Result: **less total code (800 vs 1200 lines) but more effective code.** Completion rate 87.5% vs 37.5%.

> [!info] ★ Insight
> The counterintuitive result is that constraining the agent *increases* throughput. Unconstrained, it produces more lines and fewer working features — because every half-finished task taxes the shared C/k budget and couples to the others. WIP=1 turns a pile of fragile, interdependent drafts into a stream of verified, independent commits.

## Connections

- [[Harness-Engineering-Feature-List-Primitive]] — the file that externalizes the scope surface
- [[Harness-Engineering-Preventing-Premature-Victory]] — completion evidence is what gates the state transition
- [[Harness-Engineering-State-Persistence]] — context anxiety amplifies overreach near context limits
- [[Harness-Engineering-Five-Subsystems]] — the Scope subsystem

## References

- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Harness Engineering — OpenAI](https://openai.com/index/harness-engineering/)
