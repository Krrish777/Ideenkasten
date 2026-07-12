---
type: enriched-note
topic: "Observability for Agent Harnesses"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - observability
---

# Observability for Agent Harnesses

> [!tip] Quick Recap
> Without observability, agents decide under uncertainty, evaluations become subjective, and retries become blind wandering. Observability has two layers: runtime (what the system did) and process (why a change should be accepted). The planner-generator-evaluator pattern operationalizes both — and roughly 3x'd efficiency in Anthropic's experiment.

## Core Idea

Without observability, agents make decisions under uncertainty, evaluations become subjective judgments, and retries become blind wandering.

Consider a harness using a planner-generator-evaluator workflow for the task "add dark mode to the app":

- **Without observability:** The planner outputs a vague description. The generator implements based on that vagueness; the result doesn't match the planner's implicit expectations. The evaluator rejects it on implicit standards but can't articulate what's wrong — just "it doesn't feel right." The generator retries blindly. The cycle repeats 3–4 times, ~45 minutes, barely producing acceptable output.
- **With full observability:** The planner outputs a sprint contract listing which components to modify, verification standards for each, and exclusions (e.g., no print styles). The generator implements to the contract; runtime observability records each component's style loading. The evaluator uses a scoring rubric dimension by dimension, citing specific evidence: "Button color contrast is insufficient (WCAG AA standard 4.5:1, measured 2.1:1)." One iteration produces a high-quality result, ~15 minutes.

**3x efficiency difference. The only variable is observability.**

## Layered Observability

Observability isn't just "add more logging." It operates on two layers, both essential.

![[Pasted image 20260618204944.png]]

- **Runtime observability** — system-level signals: logs, traces, process events, health checks. Answers "what did the system do."
- **Process observability** — visibility into harness decision artifacts: plans, scoring rubrics, acceptance criteria. Answers "why should this change be accepted."
- **Task trace** — a complete decision-path record from task start to completion, analogous to request tracing in distributed systems. Every step the agent takes, with its context, is recorded — so when something goes wrong, you can replay the entire process.
- **Sprint contract** — a short-term agreement negotiated before coding, specifying scope, verification standards, and exclusions. The core tool for process observability.
- **Evaluator rubric** — transforms quality evaluation from subjective judgment into evidence-based structured scoring.

### Why Agents Can't Solve This Themselves

1. **Agents don't know what they don't know.** They won't proactively record signals they don't realize they need.
2. **Log formats are inconsistent** across sessions, making systematic analysis impossible.
3. **Process observability can't be solved by logging.** Sprint contracts and rubrics are structured artifacts requiring harness-level support — print statements won't cut it.

## How to Build Observability

**1. Build runtime signal collection into the harness** — don't rely on the agent. Automatically collect: application lifecycle (startup/ready/running/shutdown), feature-path execution (entry, checkpoints, exits), data flow between components, resource utilization (e.g., growing memory), and full error context.

**2. Implement sprint contracts.** Before each task, generator and evaluator negotiate what to build and what "done" looks like:

```text
# Sprint Contract: Dark Mode Support

## Scope
- Modify the theme toggle component
- Update global CSS variables
- Add dark mode tests

## Verification Standards
- Visual regression tests pass for each component
- Main flow end-to-end tests pass
- No flash of unstyled content (FOUC)

## Exclusions
- Not handling print styles
- Not handling third-party component dark mode
```

**3. Establish an evaluator rubric** — turn "is it good" into quantifiable scoring:

```text
| Dimension | A | B | C | D |
|-----------|---|---|---|---|
| Code correctness | All tests pass | Main flow passes | Partial pass | Build fails |
| Architecture compliance | Fully compliant | Minor deviations | Obvious deviations | Serious violations |
| Test coverage | Main + edge cases | Main flow only | Only skeleton | No tests |
```

> [!note] Source enrichment (Anthropic, verified 2026-06-19)
> Why a *separate* evaluator matters: "when asked to evaluate work they've produced, agents tend to respond by confidently praising the work — even when, to a human observer, the quality is obviously mediocre." Anthropic's frontend variant scores four dimensions — **design quality, originality, craft, functionality** — and explicitly penalizes "telltale signs of AI generation like purple gradients over white cards," weighting originality and quality more heavily since models already clear the craft/functionality bar. The whole setup is **GAN-inspired**: generator versus evaluator in an adversarial improvement loop.

**4. Standardize with OpenTelemetry** — a trace per harness session, a span per task, sub-spans per verification step. This integrates observability data with standard toolchains (Jaeger, Zipkin).

## Key Details — Anthropic's Three-Agent Experiment

In March 2026, Anthropic published a systematic harness experiment. They ran the same task ("build a browser-based DAW using the Web Audio API") and recorded phase-by-phase data:

| Agent & Phase | Duration | Cost |
|---|---|---|
| Planner | 4.7 min | $0.46 |
| Build round 1 | 2 hr 7 min | $71.08 |
| QA round 1 | 8.8 min | $3.24 |
| Build round 2 | 1 hr 2 min | $36.89 |
| QA round 2 | 6.8 min | $3.09 |
| Build round 3 | 10.9 min | $5.88 |
| QA round 3 | 9.6 min | $4.06 |
| **Total** | **3 hr 50 min** | **$124.70** |

Each agent had a distinct role:

- **Planner** — receives a 1–4 sentence requirement and expands it into a full product spec. Instructed to "be bold in scope" and focus on product context and high-level design rather than detailed implementation. If the planner prematurely specifies granular technical details and gets them wrong, those errors cascade downstream. Better to constrain deliverables and let the agent find its own path during execution.
- **Generator** — implements feature by feature, sprint by sprint. Before each sprint, negotiates a sprint contract with the evaluator defining "done," implements, self-evaluates, and hands off to QA.
- **Evaluator** — uses Playwright MCP to interact with the running app like a real user — testing UI, API endpoints, and database state. Scores each sprint across four dimensions: product depth, functionality, visual design, and code quality. Each dimension has a hard threshold; if any falls short, the sprint fails and the generator gets detailed feedback.

Example QA-round-1 feedback: *"This is a visually impressive app with good AI integration, but several core DAW features are presentational only: clips can't be dragged/moved, there's no instrument UI panel, and no visual effects editor."* Specific, evidence-backed — not "it doesn't feel right."

> [!info] ★ Insight
> The evaluator wasn't always this sharp. Early versions would identify reasonable issues, then talk themselves into dismissing them as not severe, ultimately approving the work. The fix was a development loop: read the evaluator's logs, find where its judgment diverged from human judgment, and update the QA prompt to address those specific points. The evaluator is itself a harness component you debug — process observability is what makes that debugging possible.

## Connections

- [[Harness-Engineering-What-Is-A-Harness]] — the planner/generator/evaluator behind the $200 run
- [[Harness-Engineering-Preventing-Premature-Victory]] — the evaluator is externalized termination judgment
- [[Harness-Engineering-Session-Hygiene]] — process artifacts feed the quality document
- [[Backend-Engineering-Structured-Logging]] — the runtime signal layer in practice

## References

- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Harness design for long-running apps — Anthropic](https://www.anthropic.com/engineering/harness-design-long-running-apps)
