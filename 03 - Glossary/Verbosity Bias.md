---
term: Verbosity Bias
---

# Verbosity Bias

LLM judges score longer answers higher, even when the extra length adds nothing. In the MT-Bench work, an attack that simply restated a list repetitively fooled GPT-3.5 and Claude around 91% of the time. GPT-4 fell for it 8.7% of the time.

**Why it matters:** If you optimise a model against a verbose judge, you train it to pad. Cap output length in the eval, or make the rubric penalise redundancy explicitly.

**Where it came up:** [[04 LLM as Judge - Arkadip Basu]]

**Source:** [Zheng et al. 2023, arXiv:2306.05685](https://arxiv.org/abs/2306.05685)
