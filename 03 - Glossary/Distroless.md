---
term: Distroless Images
---

# Distroless Images

Container images that ship your application and its runtime dependencies and nothing else. No shell, no package manager, no coreutils.

**Why it matters:** Most CVEs in a typical image come from packages your app never calls. Removing them removes the finding and the attack surface at once. The tradeoff is debugging: there is no shell to exec into, so you need sidecars or ephemeral debug containers.

**Where it came up:** [[01 Six Architecture Decisions - Sachin Garg]]

**Source:** [GoogleContainerTools/distroless](https://github.com/GoogleContainerTools/distroless)
