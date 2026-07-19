---
term: Confidential Containers (CoCo)
---

# Confidential Containers (CoCo)

A CNCF Sandbox project that brings confidential computing to Kubernetes. Pods run inside hardware trusted execution environments such as Intel SGX and TDX or AMD SEV-SNP, so memory stays encrypted from the host.

**Why it matters:** It shrinks the trust boundary to exclude your own cloud provider and your own cluster operators. For regulated workloads or model weights you cannot let the infrastructure owner read, that is the difference between shipping and not.

**Where it came up:** [[01 Six Architecture Decisions - Sachin Garg]]

**Source:** [confidentialcontainers.org](https://confidentialcontainers.org/)
