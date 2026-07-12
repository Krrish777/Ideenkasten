---
type: enriched-note
topic: "Beyond Unit Tests — End-to-End Verification"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - testing
  - e2e
---

# Beyond Unit Tests — End-to-End Verification

> [!tip] Quick Recap
> Every module can pass its unit tests and the system still break the moment they're wired together. Unit tests are isolated by design, which is exactly their blind spot. Only end-to-end testing proves the absence of system-level defects — and knowing it will be E2E-tested changes how the agent writes code in the first place.

## Core Idea

You ask the agent to add a file export feature to an Electron app. It writes the renderer component, the preload script, and the service layer. Unit tests for every component pass. The agent says "done." You actually click the export button — the file path format is wrong, the progress bar doesn't respond, and exporting large files leaks memory. Five component-boundary defects, and unit tests didn't catch a single one.

Each part looks correct on its own, but problems surface the moment they're wired together. Google's Testing Pyramid tells us a large base of unit tests is essential, but stopping there means systematically missing component-interaction issues. For AI coding agents the problem is worse, because agents tend to run only the fastest tests and then declare completion. **Only end-to-end testing can prove the absence of system-level defects.**

## The Blind Spots of Unit Tests

The design philosophy of unit testing is isolation: mock dependencies, focus on the unit under test. That makes unit tests fast and precise — and creates systematic blind spots:

- **Interface Mismatch** — the renderer passes the preload script a relative file path, but the preload expects absolute. Both unit tests mock and both pass. Discovered only when the end-to-end flow is exercised.
- **State Propagation Errors** — a migration changes the schema, but the ORM caching layer still holds old-schema entries. Fresh mock environments never expose this cross-layer inconsistency.
- **Resource Lifecycle Issues** — acquisition and release of file handles, DB connections, and sockets span multiple components. Unit tests create and tear down independent resources per case, so they never surface contention or leaks.
- **Environment Dependency** — code works in the mocked test environment but fails in the real one due to config, latency, or service unavailability.

## How It Works — E2E Changes Behavior, Not Just Results

This is something many people overlook: when an agent knows its work will be validated by end-to-end tests, its coding behavior shifts.

1. **Considering component interactions** — while writing code it starts asking "how does this interface connect upstream?" rather than focusing on a single function in isolation.
2. **Respecting architectural boundaries** — in systems with architectural constraints, end-to-end tests force the agent to follow boundary rules.
3. **Handling error paths** — end-to-end tests typically include failure scenarios, pushing the agent to think about exception handling.

![[Pasted image 20260618203545.png]]

![[Pasted image 20260618203605.png]]

## Adding an E2E Layer to the Harness

Make it explicit in your validation flow: for tasks involving cross-component changes, passing end-to-end tests is a prerequisite for completion.

```text
## Validation Hierarchy
- Level 1: Unit tests (Must pass)
- Level 2: Integration tests (Must pass)
- Level 3: End-to-end tests (Must pass when cross-component changes are involved)
- Skipping any required level = Not Complete
```

## Key Details — The Electron Export Case

**Task:** A file export feature in an Electron app (renderer UI, preload filesystem proxy, service-layer transformation).

**Unit-test phase:** renderer tests pass (file ops mocked), preload tests pass (filesystem mocked), service tests pass (data source mocked). Agent declares completion.

**Defects revealed by end-to-end tests:**

| Defect | Description | Unit Test | E2E |
|--------|-------------|-----------|-----|
| Interface Mismatch | Inconsistent file path format | Missed | Caught |
| State Propagation | Export progress not sent to UI via IPC | Missed | Caught |
| Resource Leak | Large-file export handles not released | Missed | Caught |
| Permission Issue | Different permissions in packaged environment | Missed | Caught |
| Error Propagation | Service-layer exceptions didn't reach UI | Missed | Caught |

All 5 defects were caught by end-to-end tests; unit tests caught none. The trade-off: test time rose from 2 seconds to 15 seconds — perfectly acceptable in an agent workflow.

> [!note] Source enrichment (Anthropic, verified 2026-06-19)
> In Anthropic's harness the end-to-end layer is driven by **browser automation** — the agent exercises the running app through a browser MCP (Puppeteer / Playwright) the way a human would, rather than trusting unit tests. One concrete limitation worth knowing: Claude's **vision constraints** affect what it can verify this way — browser-native **alert modals aren't visible to it**, so features depending on them came out buggier. The E2E layer is powerful, but not omniscient.

> [!info] ★ Insight
> The behavioral effect is the underrated half. E2E tests don't just catch more bugs after the fact — knowing the work will be exercised as a whole nudges the agent toward writing boundary-respecting, error-handling code from the start. The test you commit to running changes the code you get.

## Connections

- [[Harness-Engineering-Preventing-Premature-Victory]] — E2E is the Layer-3 termination check
- [[Harness-Engineering-Architectural-Boundaries]] — boundaries make E2E results interpretable
- [[Backend-Engineering-Integration-Testing]] — the integration/E2E testing craft
- [[Backend-Engineering-Testing-Quality]] — the testing pyramid in context

## References

- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Harness Engineering — OpenAI](https://openai.com/index/harness-engineering/)
