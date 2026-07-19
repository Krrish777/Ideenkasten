---
term: Chainguard Images
---

# Chainguard Images

Hardened container base images built on Wolfi and maintained by Chainguard. They ship minimal, signed, with an SBOM and build provenance, and are rebuilt continuously to keep CVE counts near zero.

**Why it matters:** Adopting them is mostly a base image swap in your Dockerfile, and it removes a large share of scanner findings without you patching anything. The commercial tier is where the fresh tags and support live.

**Where it came up:** [[01 Six Architecture Decisions - Sachin Garg]]

**Source:** [chainguard.dev](https://www.chainguard.dev/)
