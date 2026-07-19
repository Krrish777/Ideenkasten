---
term: Drain Algorithm
---

# Drain Algorithm

A streaming log parser published by He, Zhu, Zheng and Lyu at ICWS 2017. It uses a fixed-depth parse tree to group raw log lines into templates, separating the static text from the variable fields. IBM productionised it as Drain3.

**Why it matters:** It turns millions of unique log lines into a few hundred templates in one pass, with no training and no schema. That is what makes clustering, anomaly detection and cost-effective log storage possible at volume.

**Where it came up:** [[03 Oodle AI - Agent Observability]]

**Source:** [logpai/Drain3](https://github.com/logpai/Drain3)
