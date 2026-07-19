---
term: Completely Fair Scheduler (CFS)
---

# Completely Fair Scheduler (CFS)

CFS is the default Linux process scheduler. It divides CPU time fairly between runnable tasks. It optimises for fairness, not for meeting deadlines.

**Why it matters:** Fairness is the wrong goal for bursty LLM inference. Untuned CFS was measured at around 11ms worst case scheduling delay. Pinning inference threads to specific CPUs dropped that to tens of microseconds.

**Where it came up:** [[01 Six Architecture Decisions - Sachin Garg]]

**Source:** [Linux CFS scheduler docs](https://docs.kernel.org/scheduler/sched-design-CFS.html)
