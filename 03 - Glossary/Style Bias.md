---
term: Style Bias
---

# Style Bias

LLM judges reward surface presentation: markdown headers, bullet points, confident tone, tidy formatting. A well-formatted wrong answer can beat a plain correct one.

**Why it matters:** Formatting is easy to game and correctness is not, so any leaderboard driven by an unguarded judge drifts toward pretty output. Strip or normalise formatting before judging when what you care about is factual accuracy.

**Where it came up:** [[04 LLM as Judge - Arkadip Basu]]

**Source:** [Justice or Prejudice, arXiv:2410.02736](https://arxiv.org/abs/2410.02736)
