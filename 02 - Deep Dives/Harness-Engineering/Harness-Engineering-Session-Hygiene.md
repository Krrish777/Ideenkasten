---
type: enriched-note
topic: "Session Hygiene & Long-Term Reliability"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - maintenance
  - reliability
---

# Session Hygiene & Long-Term Reliability

> [!tip] Quick Recap
> Long-term reliability depends on operational discipline, not single-run success. Agents copy whatever's already in the repo, so messes compound — Lehman's laws in action. The fix: make clean state a completion condition, run dual-mode (immediate + periodic) cleanup, keep a live quality document, and periodically simplify the harness as models improve.

## Core Idea

Long-term reliability depends on operational discipline, not just single-run success. The quality of state at the end of each session directly determines the next session's efficiency.

**Lehman's laws of software evolution** tell us that systems undergoing continuous change inevitably grow more complex unless actively managed. This is especially true for AI coding agents. Every session introduces changes, and without cleanup at exit, technical debt accumulates exponentially.

> [!note] Source enrichment (verified 2026-06-19)
> The two Lehman laws doing the work here are the **1st — Continuing Change** (a system in use must keep adapting or grow progressively less satisfactory) and the **2nd — Increasing Complexity** (as it evolves, complexity rises unless deliberate effort is spent to contain it). The IEEE reference (document 1702314) is the canonical Lehman software-evolution paper; its full text is **paywalled**, so these statements come from the public summaries, not the original PDF.

During five months of Codex experiments, OpenAI observed something striking: **agents copy patterns already present in the repository, even when those patterns are inconsistent or suboptimal.** Over time, this copying inevitably leads to drift. The first person leaves a coffee cup in the common area; the second figures "it's already messy" and leaves another; a week later the table is buried under cups. A codebase works the same way.

![[Pasted image 20260618205714.png]]

## How It Works — OpenAI's Systematic Solution

The team initially spent 20% of every Friday manually cleaning up "AI slop," but that doesn't scale. They arrived at a systematic solution:

1. **Encode "golden rules" into the repository** — rules like "prefer the shared utility package over hand-rolled helpers" (keep invariants centralized) and "don't YOLO-guess data structures" (validate boundaries or depend on typed SDKs). Concrete, mechanical, automatically checkable.
2. **Establish periodic cleanup workflows** — a fleet of background Codex tasks that regularly scan for deviations, update quality scores, and open targeted refactoring PRs. Most can be reviewed and auto-merged within a minute.
3. **Capture human taste once, enforce it continuously** — review comments, refactoring PRs, and user-facing bugs are all translated into documentation updates or encoded directly into tooling. When documentation isn't enough, promote the rule into code.

Technical debt is a high-interest loan. Continuously paying it off in small increments is almost always better than letting it accumulate into one massive payoff event.

Good progress records reduce session startup diagnostic time by **60–80%.** Temporary artifacts — debug logs, temporary files, commented-out code, TODO markers — must also be cleaned up, because they increase cognitive load for the next session. The standard startup path must remain functional: environment init, codebase loading, context acquisition, task selection — none of these paths can be broken.

![[Pasted image 20260618205845.png]]

The most common mental trap is "no time to clean up this session, I'll do it next time." But the next session doesn't know what you left behind — it sees a mess of code and uncertain state, spends time inferring "which parts are intentional and which are temporary," then ignores the chaos and builds new work on top of it. This is entropy's positive feedback loop.

## The Numbers — 12 Weeks With vs Without Cleanup

A project developed with agents for 12 weeks, **without** a cleanup strategy:

| Week | Build pass | Test pass | New-session startup |
|------|-----------|-----------|---------------------|
| 1 | 100% | 100% | 5 min |
| 4 | 95% | 92% | 15 min |
| 8 | 82% | 78% | 35 min |
| 12 | 68% | 61% | 60+ min |

Same project **with** a cleanup strategy: Week 1 was 100% / 100% / 5 min, and Week 12 was **97% / 95% / 9 min.** After 12 weeks: build pass rate differs by 29 percentage points, startup time by 85%. Not theoretical — observed.

## How to Do It

**1. Clean state is a necessary condition for completion.** Session completion = task passes verification AND clean-state check passes.

```text
## Session Exit Checklist
- [ ] Build passes (npm run build)
- [ ] All tests pass (npm test)
- [ ] Feature list updated
- [ ] No debug code remaining (console.log, debugger, TODO)
- [ ] Standard startup path available (npm run dev)
```

**2. Dual-mode cleanup strategy:**
- **Immediate cleanup (every session end)** — clean temporary artifacts, update feature-list state, ensure build/tests pass. This is "reference counting" cleanup.
- **Periodic cleanup (weekly)** — full-system scan, handle structural issues, update quality docs, run benchmarks to detect drift. This is "tracing" cleanup.

**3. Maintain a quality document** — an active artifact that continuously scores each module so new sessions know where to prioritize (fix the lowest-scoring module first):

```text
## User Authentication Module (Quality: A)
- Verification passing: Yes
- Agent understandable: Yes
- Architecture boundaries: Compliant

## Payment Module (Quality: C)
- Verification passing: Partial (payment callback untested)
- Agent understandable: Difficult (logic spread across 3 files)
- Architecture boundaries: Violations present
```

**4. Periodically simplify the harness.** Every harness component exists because the model couldn't reliably do something on its own. As models improve, these assumptions become outdated. Anthropic's initial harness included a sprint-splitting mechanism for Sonnet 4.5; when **Opus 4.6** shipped, the model could handle work decomposition autonomously, making sprint construction unnecessary overhead.

**5. Cleanup operations must be idempotent** — safe to run repeatedly:

```bash
rm -f /tmp/debug-*.log       # -f ensures no error when files don't exist
git checkout -- .env.local   # Restore to known state
npm run test                 # Verify cleanup didn't break anything
```

**6. High throughput changes the merge philosophy.** When agent output far exceeds human review capacity, minimize blocking merge gates. In an environment where an agent opens 3.5 PRs per day (and later more), PRs should be short-lived; test flakiness is usually resolved with subsequent runs rather than indefinitely blocking progress. The key criterion: **average cost of fixing a bug vs. average cost of waiting for a human to review a PR.** When the former is lower, fast merging is right.

> [!warning] Caveat
> Fast merging is irresponsible in a low-throughput environment. It's only the correct tradeoff when agent output far exceeds human attention and the cost of fixing is low relative to the cost of waiting.

## Design Principles

- Short entrypoint, deeper linked docs
- Repository as system of record
- Mechanical checks beat remembered rules
- Plans and quality history live beside the code
- Cleanup and simplification are first-class responsibilities

![[Pasted image 20260618210717.png]]

> [!info] ★ Insight
> The harness is not a fixed artifact — it's a living one with its own technical debt. Every rule you add was a patch for a model limitation; as models improve, some patches become pure overhead. So "periodically simplify the harness" is the mirror image of "periodically clean the code": both fight Lehman-style complexity growth, one in the product and one in the scaffolding.

## Connections

- [[Harness-Engineering-State-Persistence]] — clean handoff state is what hygiene protects
- [[Harness-Engineering-Architectural-Boundaries]] — drift is un-enforced boundaries accumulating
- [[Harness-Engineering-Instruction-File-Trap]] — simplification applies to instructions too
- [[Harness-Engineering-Observability]] — quality docs are fed by process artifacts

## References

- [Harness Engineering — OpenAI](https://openai.com/index/harness-engineering/)
- [Laws of software evolution (Lehman) — IEEE](https://ieeexplore.ieee.org/document/1702314) — canonical Lehman paper; full text paywalled (abstract only)
- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
