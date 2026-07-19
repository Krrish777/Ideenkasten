---
term: Non-Uniform Memory Access (NUMA)
---

# Non-Uniform Memory Access (NUMA)

On multi-socket servers each CPU has memory attached directly to it. Reading memory attached to another socket goes over an interconnect and costs more.

**Why it matters:** Cross-socket access was measured at over 3x the cost of local access. For inference that means the GPU, its host CPU and the memory feeding it should all sit on the same NUMA node, or you pay the penalty on every token.

**Where it came up:** [[01 Six Architecture Decisions - Sachin Garg]]

**Source:** [Linux NUMA docs](https://docs.kernel.org/mm/numa.html)
