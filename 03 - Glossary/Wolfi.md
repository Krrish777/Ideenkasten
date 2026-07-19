---
term: Wolfi
---

# Wolfi

Wolfi is a minimal Linux "undistro" from Chainguard. It has a package manager and glibc but no kernel, and it is built specifically to produce small container base images with supply chain metadata attached.

**Why it matters:** It gives you most of the CVE reduction of distroless while keeping apk, so you can still install packages at build time. Every package ships with provenance and an SBOM by default.

**Where it came up:** [[01 Six Architecture Decisions - Sachin Garg]]

**Source:** [wolfi.dev](https://wolfi.dev/)
