---
term: Agent2Agent Protocol (A2A)
---

# Agent2Agent Protocol (A2A)

An open protocol for agents built by different teams to talk to each other. It runs over JSON-RPC 2.0 with server-sent events for streaming. Google announced it in April 2025 and donated it to the Linux Foundation in June 2025.

**Why it matters:** MCP connects an agent to tools. A2A connects an agent to another agent, including ones you did not build and cannot see inside. If you are planning multi-vendor agent systems, this is the interop layer.

**Where it came up:** [[01 Six Architecture Decisions - Sachin Garg]]

**Source:** [a2aproject/A2A](https://github.com/a2aproject/A2A)
