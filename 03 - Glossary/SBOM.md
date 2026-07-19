---
term: Software Bill of Materials (SBOM)
---

# Software Bill of Materials (SBOM)

A machine-readable inventory of every component and version inside a build artifact. SPDX and CycloneDX are the two common formats.

**Why it matters:** When the next Log4Shell lands, the question is which of your images contain the bad version. With SBOMs generated at build time you query it. Without them you rebuild and rescan everything.

**Where it came up:** [[01 Six Architecture Decisions - Sachin Garg]]

**Source:** [SPDX](https://spdx.dev/)
