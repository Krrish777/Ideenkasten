---
type: enriched-note
topic: "Preventing Agents from Declaring Victory Too Early"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - verification
---

# Preventing Agents from Declaring Victory Too Early

> [!tip] Quick Recap
> Neural networks are systematically overconfident (Guo et al., 2017) — and coding agents are no different: they "feel" done when they're not. The harness must replace the agent's feelings with externalized, execution-based verification: a three-layer termination check the agent cannot skip or self-grade.

## Core Idea

This isn't an isolated incident. The classic 2017 ICML paper by **Guo et al.** proved that modern neural networks are systematically overconfident — the confidence reported by models is significantly higher than their actual accuracy. AI coding agents are no different. They "feel" done, but in reality they're far from it. **Your harness must replace the agent's "feelings" with externalized, execution-based verification.**

The failure compounds when the harness doesn't enforce comprehensive execution verification, so the agent skips actually running it or only runs partial tests. It runs unit tests but skips integration tests; it runs tests but doesn't check coverage. In the end, "the code looks fine" is taken as evidence that "the feature is complete."

![[Pasted image 20260618201118.png]]

![[Pasted image 20260618201135.png]]

## Why Unit Tests Aren't Enough

Passing unit tests ≠ task complete. This is the most common and most dangerous trap. The design philosophy of unit tests — isolating the tested unit and mocking dependencies — is precisely what makes them incapable of detecting cross-component issues:

- **Interface Mismatch** — the renderer passes a relative file path to the preload script, but the preload expects absolute. Both unit tests use mocks and both pass. The issue only surfaces in end-to-end testing.
- **State Propagation Errors** — a migration changes the table schema, but the ORM's caching layer still holds old-schema entries. Unit tests run in a fresh mock environment every time, so cross-layer inconsistency never surfaces.
- **Environment Dependency** — code behaves correctly in the mocked test environment but fails in the real environment due to config differences, network latency, or service unavailability.

### "Refactoring While We're at It" Is Poison

Claude Code commonly starts refactoring, optimizing performance, and improving style *before* the core functionality has passed verification. Knuth's "premature optimization is the root of all evil" takes on new meaning here: refactoring shifts the boundary between verified and unverified code, potentially breaking code paths that were previously implicitly correct.

## How to Do It Right

**1. Externalize termination judgment.** The completion judgment should not be made by the agent itself. The harness independently executes termination validation, using runtime signals as input rather than the agent's confidence:

```text
## Definition of Done
- Feature complete = end-to-end verification passed, not "code is written"
- Required verification levels:
  1. Unit tests pass
  2. Integration tests pass
  3. End-to-end flow verification passes
- Do not proceed to level 2 if level 1 fails
- Do not proceed to level 3 if level 2 fails
```

**2. Build three-layer termination validation:**

- **Layer 1: Syntax & Static Analysis.** Lowest cost, least information, but must pass. Spell the words correctly before reading further.
- **Layer 2: Runtime Behavior Verification.** Test execution, application startup checks, critical-path validation. The core evidence of completion — not just written, but runnable.
- **Layer 3: System-Level Confirmation.** End-to-end testing, integration validation, user-scenario simulation. The last line of defense against premature declarations — not just runnable, but correct.

**3. Provide actionable error feedback to the agent.** (See [[Harness-Engineering-Architectural-Boundaries]] for agent-oriented error messages.)

**4. Capture runtime signals:**

- Did the application successfully start and reach a ready state?
- Did critical feature paths execute successfully at runtime?
- Were database writes, file operations, and other side effects correct?
- Were temporary resources cleaned up?

## Key Details — The Password-Reset Case

**Task:** Implement password reset (database, email sending, API endpoint changes).

**Premature hand-in path:** The agent modifies the schema, writes the endpoint, adds the email template, runs unit tests (all pass), and declares completion. Looks like a lot was done, but the critical steps were all skipped.

**Actual omissions:** (1) End-to-end flow untested — the actual sending and verification of the reset link was never confirmed. (2) Database migration failed after partial execution, leaving the schema inconsistent. (3) Email service configuration was missing in the target environment.

**Harness intervention:** Termination validation is enforced — (1) start the full application to verify the reset endpoint is accessible; (2) execute the complete reset flow; (3) verify database state consistency. All defects were discovered within the session, saving 5–10x the cost of post-hoc fixes.

> [!info] ★ Insight
> The deepest point here is that *confidence is not evidence.* A calibrated harness treats the agent's "I'm done" as a hypothesis, not a verdict — and the only thing that promotes a hypothesis to a verdict is a command that exits zero. This is the verification gap made operational.

## Connections

- [[Harness-Engineering-Beyond-Unit-Tests-E2E]] — why the system-level layer catches what units miss
- [[Harness-Engineering-Architectural-Boundaries]] — turning rules into checks and fix-instruction errors
- [[Harness-Engineering-Feature-List-Primitive]] — pass-state gating is termination judgment per feature
- [[Backend-Engineering-Testing-Quality]] — the broader testing discipline

## References

- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [On Calibration of Modern Neural Networks — Guo et al., ICML 2017](https://arxiv.org/abs/1706.04599)
