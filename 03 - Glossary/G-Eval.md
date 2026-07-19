---
term: G-Eval
---

# G-Eval

An LLM-as-judge method where the model first auto-generates a chain of thought that breaks your evaluation criterion into concrete steps, then scores the output against those steps.

**Why it matters:** Asking a model to rate coherence from 1 to 5 gives you noise. Making it derive the sub-steps first gives you a score you can inspect and argue with, and it correlates better with human ratings. You write the criterion, the model writes the rubric.

**Where it came up:** [[04 LLM as Judge - Arkadip Basu]]

**Source:** [G-Eval paper, arXiv:2303.16634](https://arxiv.org/abs/2303.16634)
