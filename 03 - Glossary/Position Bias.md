---
term: Position Bias
---

# Position Bias

When an LLM judge compares two responses, it favours whichever one it sees in a particular slot, usually the first. The same pair swapped in order can flip the verdict.

**Why it matters:** Your pairwise eval can be measuring presentation order rather than quality. The standard mitigation is to run every comparison twice with the order swapped and only count it as a win if both runs agree.

**Where it came up:** [[04 LLM as Judge - Arkadip Basu]]

**Source:** [Zheng et al. 2023, arXiv:2306.05685](https://arxiv.org/abs/2306.05685)
