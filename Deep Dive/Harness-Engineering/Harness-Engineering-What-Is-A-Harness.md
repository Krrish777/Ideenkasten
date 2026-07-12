---
type: enriched-note
topic: "What Is a Harness"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
---

# What Is a Harness

> [!tip] Quick Recap
> The strongest model still fails on real tasks without a proper environment around it. The harness is everything outside the model weights — instructions, tools, environment, state, verification. The model decides *what* code to write; the harness governs *when, where, and how* it writes it. The harness doesn't make the model smarter; it makes the model's output reliable.

## Core Idea

There's a hard truth most people learn the hard way: **the strongest model in the world will still fail on real engineering tasks if you don't build a proper environment around it.** It starts well, then something starts to go wrong. It skips a step, breaks a test, says done when it's actually not. Developers spend more time cleaning up than if they'd done it themselves.

This isn't a model problem. It's a harness problem.

Harness engineering is about building a complete working environment around the model so it produces reliable results. It's not about writing better prompts. It's about designing the system the model operates inside.

## How It Works

The harness has five subsystems, each with one job:

```text
                    THE HARNESS PATTERN
                    ====================

    You --> give task --> Agent reads harness files --> Agent executes
                                                        |
                                              harness governs every step:
                                              |
                                              +--> Instructions: what to do, in what order
                                              +--> Scope:        one feature at a time, no overreach
                                              +--> State:        progress log, feature list, git history
                                              +--> Verification: tests, lint, type-check, smoke runs
                                              +--> Lifecycle:    init at start, clean state at end
                                              |
                                              v
                                         Agent stops only when
                                         verification passes
```

- **Instructions** — Tell the agent what to do, in what order, and what to read before starting. Not one giant file; a progressive disclosure structure the agent navigates on demand.
- **State** — Track what's been done, what's in progress, and what's next. Persisted to disk so the next session picks up exactly where the last one left off.
- **Verification** — Only a passing test suite counts as evidence. The agent cannot declare victory without runnable proof.
- **Scope** — Constrain the agent to one feature at a time. No overreach. No half-finishing three things.
- **Session Lifecycle** — Initialize at the start. Clean up at the end. Leave a clean restart path for the next session.

## The $9-vs-$200 Experiment

The evidence is clear. Anthropic ran a controlled experiment: same model (Opus 4.5), same prompt ("build a 2D retro game editor").

- **Without a harness**, it spent $9 in 20 minutes and produced something that didn't work.
- **With a full harness** (planner + generator + evaluator), it spent $200 in 6 hours and built a game you could actually play.

The model didn't change. The harness did.

> [!note] Source enrichment (verified 2026-06-19)
> This is Anthropic's **Retro Game Maker** experiment — the article your dump flagged as "needs to find." Confirmed details: the solo run was rigid and produced broken mechanics (entity input was non-functional); the full-harness run worked from a **16-feature spec** and shipped functional gameplay with integrated AI sprite/level generation, at roughly a **20x** cost increase for a working result. The architecture is **GAN-inspired** — a generator agent produces work and a *separate* evaluator agent grades it, precisely because agents asked to judge their own output "tend to respond by confidently praising the work."

## Key Details

The contrast across sessions is where the harness earns its keep:

```text
    WITHOUT HARNESS                            WITH HARNESS
    ==============                             ============

    Session 1: agent writes code               Session 1: agent reads instructions
               agent breaks tests                         agent runs init.sh
               agent says "done"                          agent works on one feature
               you fix it manually                        agent verifies before claiming done
                                                          agent updates progress log
    Session 2: agent starts fresh                         agent commits clean state
               agent has no memory
               of what happened before         Session 2: agent reads progress log
               agent re-does work                         agent picks up where it left off
               you fix it again                           you review, not rescue

    Result: you spend more time                Result: agent does the work,
            cleaning up than if you                    you verify the result
            did it yourself
```

The mental shift: **the model decides what code to write at each step; the harness governs every transition.** Without the harness, "verify" becomes "agent says it looks fine." With the harness, "verify" is "tests pass, lint is clean, types check."

> [!info] ★ Insight
> The capability is already there. What's missing is the infrastructure that converts capability into reliable, resumable, verifiable work. Both Anthropic and OpenAI converge on the same statement: *everything in the engineering infrastructure outside the model determines how much of the model's capability actually gets realized.*

## Connections

- [[Harness-Engineering-Hub]] — the index for this deep dive
- [[Harness-Engineering-Where-Agents-Get-Stuck]] — the failure modes the harness exists to fix
- [[Harness-Engineering-Five-Subsystems]] — each subsystem in detail
- [[Harness-Engineering-Observability]] — the planner/generator/evaluator setup behind the $200 run

## References

- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Harness design for long-running apps — Anthropic](https://www.anthropic.com/engineering/harness-design-long-running-apps) — source of the Retro Game Maker ($9 vs $200) experiment
- [Harness Engineering — OpenAI](https://openai.com/index/harness-engineering/)
