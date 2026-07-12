---
type: enriched-note
topic: "Instructions: Drawing a Good Map"
original: "6 - Zettelkastem/Harness Engineering.md"
date: 2026-06-18
enriched_date: 2026-06-18
tags:
  - enriched
  - harness-engineering
  - ai-agents
  - instructions
---

# Instructions: Drawing a Good Map

> [!tip] Quick Recap
> `AGENTS.md` is the agent's landing page, not an encyclopedia (50–200 lines). Knowledge lives next to the code it governs. Test your map with a "fresh session test": give a brand-new agent only the repo and see if it can answer five basic questions.

## Core Idea

An agent has only three sources of input: system prompts and task descriptions, file contents from the repository, and tool execution output. Everything else — Slack, Jira, Confluence, the decision you made on Friday afternoon — is invisible. So getting instructions right isn't a writing problem; it's a **"put decision information in the right place"** problem.

![[Pasted image 20260618165704.png]]

How do you test whether your map is good enough? Run a **fresh session test**: open a brand-new agent session, give it only the repository contents, and see if it can answer five basic questions.

![[Pasted image 20260618165722.png]]

## How It Works — Four Principles

**Principle 1: Knowledge lives next to code.** A rule about API endpoint authentication belongs next to the API code, not buried in a giant global document. Put a short doc in each module directory explaining that module's responsibilities, interfaces, and special constraints. The module directory itself is a natural index — when the agent reaches the code, it also reaches the constraints, no searching required.

**Principle 2: Use a standardized entry file.** `AGENTS.md` (or `CLAUDE.md`) is the agent's landing page. It doesn't need all information, but it must let the agent quickly answer three questions: "What is this project," "How do I run it," and "How do I verify it." 50–100 lines is enough.

**Principle 3: Minimal but complete.** Every piece of knowledge should have a clear use case. If removing a rule doesn't affect the agent's decision quality, that rule shouldn't exist. But every question from the fresh session test must have an answer. Not too much, not too little — just enough.

**Principle 4: Update with code.** Bind knowledge updates to code changes. The simplest approach: put architecture docs in the corresponding module directory, so modifying code naturally surfaces the doc. CI can remind you to check whether docs need updating after code changes.

## Concrete Repo Structure

```text
project/
├── AGENTS.md              # Entry: project overview, run commands, hard constraints
├── src/
│   ├── api/
│   │   ├── ARCHITECTURE.md  # API layer architecture decisions
│   │   └── ...
│   ├── db/
│   │   ├── CONSTRAINTS.md   # Database operation hard constraints
│   │   └── ...
│   └── ...
├── PROGRESS.md             # Current progress: done, in-progress, blocked
└── Makefile
```

## Key Details — A Real Transformation

A team maintained an e-commerce platform with ~30 microservices. Architecture decisions — communication protocols, consistency strategies, API versioning — were scattered across Confluence (partially outdated), Slack (hard to search), a few senior engineers' heads (not scalable), and sporadic code comments (not systematic).

After introducing AI agents, **70% of tasks required human intervention.** Nearly every failure involved the agent violating an implicit constraint that "everyone knows but nobody ever wrote down." The agent had no way to know what it didn't know.

The transformation:
1. Created `AGENTS.md` in the repo root with project overview, tech-stack versions, and global hard constraints.
2. Added `ARCHITECTURE.md` in each microservice directory describing responsibilities, interfaces, and dependencies.
3. Created a centralized `CONSTRAINTS.md` using explicit "MUST / MUST NOT" language.
4. Added `PROGRESS.md` in each service directory tracking work status.

After: the same agent could answer all key project questions on a fresh session, and task completion quality improved significantly.

> [!info] ★ Insight
> The module directory is a free index. By co-locating constraints with the code they govern, you make discovery automatic — the agent can't reach the code without passing the rule. This is the opposite of the giant-file approach, where the rule and the code drift further apart with every commit.

## Connections

- [[Harness-Engineering-Five-Subsystems]] — the Instruction subsystem this expands
- [[Harness-Engineering-Instruction-File-Trap]] — what happens when the map becomes an encyclopedia
- [[Harness-Engineering-State-Persistence]] — PROGRESS.md lives alongside the map

## References

- [Harness Engineering — OpenAI](https://openai.com/index/harness-engineering/)
- [Effective harnesses for long-running agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
