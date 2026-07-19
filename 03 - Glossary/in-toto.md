---
term: in-toto
---

# in-toto

A framework for attesting to each step of a software supply chain. Every step produces a signed statement about what went in and what came out, and a layout defines which steps must happen and who is allowed to perform them.

**Why it matters:** Signing the final artifact only proves who published it. in-toto lets you verify the whole path from source to image, so a tampered intermediate step fails verification. It is the attestation format underneath much of SLSA.

**Where it came up:** [[01 Six Architecture Decisions - Sachin Garg]]

**Source:** [in-toto.io](https://in-toto.io/)
