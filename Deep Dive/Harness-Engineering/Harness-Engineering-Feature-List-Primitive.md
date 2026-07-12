---
type: enriched-note
topic: "The Feature List Primitive"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - feature-list
---

# The Feature List Primitive

> [!tip] Quick Recap
> A feature list isn't a memo for humans — it's the foundational data structure the whole harness is built on. The scheduler picks tasks from it, the verifier judges completion against it, the handoff reporter summarizes from it. Every entry is a triple: behavior, verification command, state. The harness controls state transitions, not the agent.

## Core Idea

Feature lists, in many people's eyes, are just a memo — write things down so you don't forget, then toss them aside. But in the harness world, a feature list isn't a memo for humans. **It's the foundational structure the entire harness is built on.** The scheduler relies on it to pick tasks, the verifier relies on it to judge completion, and the handoff reporter relies on it to generate summaries. Without it, these components have no shared consensus to depend on.

Neither Claude Code nor Codex automatically knows what you mean by "done." You say "add a shopping cart feature," and the model's interpretation might be "write a Cart component and an `addToCart` method." But you meant "the user can browse products, add to cart, and complete checkout end-to-end." Without a feature list, the agent uses its own implicit standard — usually "the code has no obvious syntax errors."

Look at this common progress note:

```text
Did user auth, shopping cart mostly done, still need payments
```

Can a new session answer anything from this? What does "mostly done" mean? Which tests did the cart pass? What's blocking payments? Nobody knows. The new session spends 20 minutes inferring state and may re-implement completed features. Anthropic's data: good progress records reduce session startup diagnostic time by **60–80%.**

![[Pasted image 20260618194828.png]]

![[Pasted image 20260618194929.png]]

## How It Works — The Core Primitives

- **Feature lists are harness primitives** — not optional planning tools, but foundational data structures all other components depend on.
- **Triple structure** — each item contains `(behavior description, verification command, current state)`. The behavior tells the agent what to do, the verification what counts as done, the state where things stand. Missing any element makes the item incomplete.
- **State machine model** — each item has four states: `not_started`, `active`, `blocked`, `passing`. Transitions are controlled by the harness, not freely changed by the agent.
- **Pass-state gating** — the only way a feature moves from `active` to `passing` is the verification command executing successfully. This transition is irreversible.
- **Single source of truth** — all "what needs to be done" derives from one feature list. No contradictions between the list and conversation history.
- **Back-pressure** — the number of features that haven't passed yet is the pressure the harness exerts on the agent. Zero pressure = project complete.

## How to Do It

**1. Define a minimal feature-list format.** A structured Markdown or JSON file works. The key is every entry has the triple:

```json
{
  "id": "F03",
  "behavior": "POST /cart/items with {product_id, quantity} returns 201",
  "verification": "curl -X POST http://localhost:3000/api/cart/items -H 'Content-Type: application/json' -d '{\"product_id\":1,\"quantity\":2}' | jq .status == 201",
  "state": "passing",
  "evidence": "commit abc123, test output log"
}
```

> [!note] Source enrichment (Anthropic, verified 2026-06-19)
> Anthropic's own harness stores the feature list as **JSON, not Markdown — specifically because "the model is less likely to inappropriately change or overwrite JSON files compared to Markdown files."** Each feature is `{ "description", "steps": [...], "passes": false }`, and **every feature is initialized as failing** so the agent has to earn each pass. Their claude.ai-clone example tracked **over 200 features** this way.

**2. Let the harness control state transitions.** The agent can't directly set a feature to `passing`. It can only submit a verification request; the harness executes the command and decides whether to allow the transition. That's pass-state gating.

**3. Write the rules in CLAUDE.md:**

```text
## Feature List Rules
- Feature list file: /docs/features.md
- Only one feature active at a time
- Verification command must pass before marking as passing
- Don't modify feature list states yourself — the verification script updates them automatically
```

**4. Calibrate granularity.** Each item should be "completable in one session." Too broad and it won't finish; too narrow and overhead grows. "User can add items to cart" is good. "Implement the shopping cart" is too broad. "Create the name field on the Cart model" is too narrow.

## Key Details — Memo vs Structured

An e-commerce platform with 10 features, two tracking approaches:

- **Memo mode** — unstructured notes degrade to "did user auth and product list, cart mostly done but has bugs, payments not started." A new session needs 20 minutes to infer state and re-implements completed features.
- **Structured mode** — every feature has a clear state and verification command. A new session reads the list and in 3 minutes knows F01–F05 are `passing`, F06 is `active`, F07–F10 are `not_started`. It picks up directly from F06, zero rework.

Quantified: structured feature lists show **45% higher completion rate** than free-form tracking, with **zero duplicate implementations.**

> [!info] ★ Insight
> Pass-state gating is what makes "done" objective. By taking the `active → passing` transition out of the agent's hands and binding it to a command exit code, the harness removes the single most common lie an agent tells — "I'm done" — and replaces it with a fact the scheduler, verifier, and handoff reporter can all trust.

## Connections

- [[Harness-Engineering-Scope-Control-WIP]] — the feature list externalizes the scope surface
- [[Harness-Engineering-Preventing-Premature-Victory]] — pass-state gating is termination judgment in miniature
- [[Harness-Engineering-State-Persistence]] — the structured alternative to free-form progress notes
- [[Harness-Engineering-Initialization-Phase]] — the task breakdown seeds the feature list

## References

- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Harness Engineering — OpenAI](https://openai.com/index/harness-engineering/)
