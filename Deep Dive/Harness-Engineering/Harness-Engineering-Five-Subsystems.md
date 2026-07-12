---
type: enriched-note
topic: "The Five Subsystems"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - subsystems
---

# The Five Subsystems

> [!tip] Quick Recap
> A harness has five subsystems: Instructions, Tool, Environment, State, Feedback. The feedback subsystem is the highest-ROI of the five. Add them one at a time and you can take a fixed model from a 20% success rate to near 100% — without changing the model at all.

## Core Idea

Everything in the engineering infrastructure outside the model determines how much of the model's capability actually gets realized. Two principles frame the whole design:

- **Give a map, not a manual.** OpenAI's experience: `AGENTS.md` should be a directory page, not an encyclopedia. Around 100 lines is enough. If it doesn't fit, split it into a `docs/` directory and let the agent read on demand.
- **Constrain, don't micromanage.** A good harness uses executable rules to constrain the agent rather than enumerating instructions one by one. OpenAI: "enforce invariants, don't micromanage implementation." Anthropic found that agents confidently praise their own work, and the solution is to separate "the person who does the work" from "the person who checks the work."

![[Pasted image 20260618165118.png]]

## How It Works — The Five Subsystems

**Instruction subsystem.** Create `AGENTS.md` (or `CLAUDE.md`) containing a project overview and purpose, tech stack and versions, first-run commands, non-negotiable hard constraints, and links to more detailed documentation.

**Tool subsystem.** Ensure the agent has sufficient tool access. Don't disable shell for "security reasons" — if the agent can't even run `pip install`, how is it supposed to get anything done? But don't open everything either — follow the principle of least privilege.

**Environment subsystem.** Make the environment state self-describing. Use `pyproject.toml` or `package.json` to lock dependencies, `.nvmrc` or `.python-version` to specify runtime versions, and Docker or devcontainers to make the environment reproducible.

**State subsystem.** Long tasks must have progress tracking. Use a simple `PROGRESS.md` recording: what is done, what is in progress, what is blocked. Update before each session ends; read when the next session starts.

**Feedback subsystem.** This is the highest-ROI subsystem. Explicitly list verification commands in `AGENTS.md`:

```text
Verification commands:
- Tests: pytest tests/ -x
- Type check: mypy src/ --strict
- Lint: ruff check src/
- Full verification: make check (includes all above)
```

## The Staged Experiment — 20% to ~100%

A team used GPT-4o to develop a TypeScript + React frontend (~20,000 lines). They went through four stages, essentially adding harness components one at a time:

| Stage | What was added | Success rate |
|-------|----------------|--------------|
| 1 | Only a basic README description | 20% (1/5) |
| 2 | `AGENTS.md` with tech-stack versions, naming conventions, key architecture decisions | 60% |
| 3 | Verification commands in `AGENTS.md` (`yarn test && yarn lint && yarn build`) | 80% |
| 4 | Progress file templates the agent updates each run | 80–100% |

Four iterations, the model did not change at all, and success rate went from 20% to near 100%. You didn't switch to a better model — what changed was the harness.

## Key Details — Quantifying Each Component's Value

Use a **controlled-variable exclusion test.** Keep the model fixed, remove the five subsystems one at a time, and see which subsystem's removal causes the biggest performance drop. The component with the largest drop has the highest marginal contribution for the current task and is worth prioritizing. Whether to strengthen it depends on failure attribution, not just the size of the drop.

> [!info] ★ Insight
> The staged data reframes the whole "which model should I use?" debate. For a fixed task, the marginal return on harness investment (20% → 100%) dwarfed any plausible model upgrade. The cheapest reliability gains are almost always in the harness, not the weights.

## Connections

- [[Harness-Engineering-Instructions-Drawing-A-Map]] — the Instruction subsystem in depth
- [[Harness-Engineering-State-Persistence]] — the State subsystem in depth
- [[Harness-Engineering-Preventing-Premature-Victory]] — the Feedback subsystem in depth
- [[Harness-Engineering-Where-Agents-Get-Stuck]] — the failure modes each subsystem addresses

## References

- [Harness Engineering — OpenAI](https://openai.com/index/harness-engineering/)
- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
