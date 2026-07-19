---
term: Agent as a Judge
---

# Agent as a Judge

An evaluation approach from Zhuge et al. (2024) where the judge is itself an agent that inspects the full trajectory of the system under test, every intermediate step, tool call and file written, rather than only the final answer. It was introduced with DevAI, a benchmark of 365 requirements.

**Why it matters:** Agentic tasks fail in the middle. Grading only the output tells you a run failed but not where, and it rewards a lucky answer reached by a broken path.

**Where it came up:** [[04 LLM as Judge - Arkadip Basu]]

**Source:** [metauto-ai/agent-as-a-judge](https://github.com/metauto-ai/agent-as-a-judge)
