---
term: Self-Enhancement Bias
---

# Self-Enhancement Bias

An LLM judge rates its own generations higher than a human would. Zheng et al. measured GPT-4 favouring its own output by about 10 percentage points and Claude by about 25.

**Why it matters:** Using the same model family to generate and to judge inflates your numbers. Judge with a different model than the one under test, or keep a human-labelled holdout to calibrate against.

**Where it came up:** [[04 LLM as Judge - Arkadip Basu]]

**Source:** [Zheng et al. 2023, arXiv:2306.05685](https://arxiv.org/abs/2306.05685)
