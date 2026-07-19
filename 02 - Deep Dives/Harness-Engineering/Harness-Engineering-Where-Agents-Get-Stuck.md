---
type: enriched-note
topic: "Where Agents Get Stuck"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - failure-modes
---

# Where Agents Get Stuck

> [!tip] Quick Recap
> Real-world agent failures come down to a handful of structural defects: vague requirements, unwritten conventions, broken environments, no verification, and lost cross-session state. None of these are "the model isn't smart enough." Each is a harness gap with a specific fix.

## Core Idea

The specific failure modes really come down to just a handful. Whenever something went wrong, the problem was almost never "not trying hard enough." It was always: **what is the agent still missing, and can that missing capability be supplied in a way that is both understandable and executable?**

An AI agent has only three sources of input: system prompts and task descriptions, file contents from the repository, and tool execution output. Your Slack history, Jira tickets, Confluence pages, and the architecture decision you hashed out with a colleague on Friday afternoon — the agent can't see any of it.

## How It Works — The Five Failure Modes

**1. Vague requirements — the agent can only guess.** "Add a search feature" means almost nothing. Search what? Full-text or structured queries? Paginated? Highlighted? You didn't spell it out, so the agent has to guess. A correct guess is luck; a wrong one means rework that costs several times more than being specific would have.

**2. Implicit conventions not written down — the agent has no way to comply.** Your team uses SQLAlchemy 2.0 syntax, but the agent writes 1.x by default. All endpoints must go through OAuth 2.0, but that rule only exists in your head and a Slack message from three months ago. The agent has never seen the rule — it's not unwilling, it literally cannot know.

**3. Incomplete environment setup — the agent spends energy fixing the environment.** Missing dependencies, wrong tool versions, incomplete dev setup — the agent burns precious context window on `pip install` errors and Node version conflicts instead of the actual work.

**4. No verification methods — the agent calls it done when it feels done.** No tests, no lint, or verification commands that were never communicated. The agent writes code, looks it over, decides it seems fine, and declares completion.

**5. Cross-session state loss — every new session starts from scratch.** All discoveries from the previous session are lost. Every new session has to re-explore the project structure. Agents without persistent state see failure rates spike sharply on tasks exceeding 30 minutes.

## Key Details

A concrete demonstration: a team used Claude Sonnet to add new API endpoints to a mid-sized Python web app (FastAPI + PostgreSQL + Redis, ~15,000 lines).

Initially they gave one sentence: *"add user preferences endpoints under `/api/v2/users`."* The result? The agent spent **40% of its context window** exploring the repo, produced code that looked reasonable but didn't follow the project's error-handling patterns, used old SQLAlchemy syntax, and declared completion while the endpoint had runtime errors. The next session had to redo all the discovery work.

Later they added `AGENTS.md` (architecture and tech-stack versions), explicit verification commands (`pytest tests/api/v2/ && python -m mypy src/`), and architecture decision records. The same model succeeded in all three independent runs, with **~60% better context efficiency.**

> [!info] ★ Insight
> Imagine being a newly hired engineer dropped into a project with zero documentation. You *can* write good code eventually — but you'll spend enormous time figuring out what the project is about rather than solving the problem. The agent faces the same predicament, only worse: you can at least ask a colleague. The agent can only see the files you put in front of it and the commands it can execute.

## Connections

- [[Harness-Engineering-What-Is-A-Harness]] — why these gaps matter
- [[Harness-Engineering-Five-Subsystems]] — each failure mode maps to a subsystem fix
- [[Harness-Engineering-State-Persistence]] — fixes cross-session state loss
- [[Harness-Engineering-Preventing-Premature-Victory]] — fixes "done when it feels done"

## References

- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Harness Engineering — OpenAI](https://openai.com/index/harness-engineering/)
