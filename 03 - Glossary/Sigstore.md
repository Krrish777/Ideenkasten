---
term: Sigstore
---

# Sigstore

A set of tools for signing software artifacts without managing long-lived private keys. The cosign CLI signs container images and attestations using short-lived certificates tied to an OIDC identity, with the record written to a public transparency log.

**Why it matters:** Key management is why most teams never signed anything. Keyless signing removes that excuse, so a CI job can sign every image it builds and consumers can verify who built it.

**Where it came up:** [[01 Six Architecture Decisions - Sachin Garg]]

**Source:** [sigstore.dev](https://www.sigstore.dev/)
