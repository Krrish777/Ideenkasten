---
event: "[[Software Architects Meetup - Hub]]"
speaker: Sachin Garg
title: Six Architecture Decisions the Open Source World Just Made For You
---

# Six Architecture Decisions the Open Source World Just Made For You

**In one line:** Six things you probably treat as DevOps details are actually architecture decisions, and the open source ecosystem has already made most of them for you.

> [!note] About this note
> This talk moved fast and assumed a lot of prior context. My live capture got the skeleton and about half the detail. I have since researched each of the six decisions and filled in what I could not write down at the time. One term I captured phonetically is still unidentified. See [[#Unresolved]].

## The framing

Sachin opened by saying what he was not going to do. He was not going to teach any one of these six things properly. **The objective was breadth**: put six decisions in front of the room, give enough of each that you would recognise it when it bites you, and let people go deep on whichever one matters to their stack.

That framing explains the pace. **This was a map, not a tutorial.**

## 1. The base image

The first decision, and the one he spent most time on, is what you put after `FROM`.

His argument is that most teams treat the base image as a given. You inherit whatever the tutorial used, and it arrives with a package manager, a shell, a set of debug tools and a standing CVE surface, none of which your application needs in production. He pushed for **standardising on a minimal base image across all services**, and treating that standard the way you would treat a language version: shared, versioned and deliberately upgraded rather than a per repo accident.

**The cost of getting this wrong compounds.** A heavy base image multiplied across every service turns every CVE announcement into an org wide patching exercise, and every image pull is slower forever.

What this looks like in practice, filling in the ecosystem he gestured at:

- **Alpine** is the usual starting point when people first go minimal, and he named it directly.
- [[Distroless]] images go further, stripping out shells, package managers and debug tooling, leaving only your application and its runtime dependencies.
- [[Wolfi]] is Chainguard's minimal Linux "undistro", built for supply chain security rather than adapted to it.
- [[Chainguard Images]] and [[Minimus]] both ship hardened, near zero CVE images with provenance and SBOMs generated at build time. Minimus was one of the sites he told the room to go look at.
- [[Confidential Containers]] (CoCo) came up alongside these, a CNCF Sandbox project that pushes confidential computing down to the container and Kubernetes level using hardware TEEs.

## 2. Provenance

The second decision follows from the first. Once you have chosen what goes in the image, **can you prove it?**

This is the supply chain attestation problem. The ecosystem has converged on a fairly clear stack, and **not adopting it is now a decision you are making by omission**:

- [[SLSA]], a framework of levels from L0 to L3+ describing how trustworthy your build provenance is.
- [[Sigstore]] and cosign, for keyless signing of container images and attestations.
- [[SBOM]], a machine readable inventory of everything in the artifact, commonly in SPDX format.
- [[in-toto]], an attestation framework for the steps of the supply chain itself.

## 3. ML deployment

Here the argument became concrete. His core claim is that **code, data and model are one unit**, and any pipeline that versions them separately will eventually deploy a combination nobody tested.

The reference architecture he laid out:

1. Git plus [[DVC]]. Git versions the code, DVC versions the datasets and model artifacts alongside it, so a single commit identifies a complete state.
2. **Bake the model and runtime into the Docker image.** The model is not fetched at boot. It is part of the artifact you tested.
3. **Blue green** on Kubernetes. Stand up the new version alongside the old, validate, then switch traffic. Rollback becomes a traffic switch rather than a redeploy.
4. **Human gate for promotion.** The pipeline stops and waits for a person before production.

## 4. AI inference

The most systems heavy section, and where my notes thinned out most.

The claim is that **inference processes tokens in bursts, and that burstiness interacts badly with the operating system**. Every thread sleep and wake cycle pays a scheduler latency tax under Linux's [[CFS Scheduler]], which is built for fairness rather than deadline sensitivity. At high throughput this becomes a real bottleneck.

Researching this afterwards, it is an active area rather than a throwaway remark. Reported worst case scheduling jitter sits around **11ms untuned**, dropping to tens of microseconds when inference threads are pinned to dedicated cores. [[NUMA]] locality matters on the same order. Keeping GPU and CPU allocation within a single NUMA node avoids cross socket penalties measured at **over three times the intra node cost**.

His conclusion was that the performance model for inference has to include the OS layer explicitly:

- OS layer behaviour
- CPU pinning
- scheduler policy
- NUMA topology

All four belong in **the architecture review** rather than a post launch tuning ticket.

He also mentioned **LLM based kernel crash analysis** as an emerging use case. Ops messages are highly structured and traceable, which makes them good input for LLM matching. He said this is running in production for on call triage.

## 5. AI as a participant

The most opinionated section, and the one that got the most reaction in the room.

The premise is that open source projects designed for human scale contribution are being invalidated. AI generated pull requests arrive faster than maintainers can review them, so **contribution volume has stopped correlating with project health**. On net, AI generated PRs have increased human burden.

His prescription was to **design for AI participation explicitly** rather than pretending it is not happening. Two consequences he drew out:

- "Architecture that is easy to review is the new architecture that is easy to write." If review is the bottleneck, optimise for reviewability.
- Open, standardised agent interoperability matters. He pointed at the [[A2A Protocol]] as "HTTP for agents".

He anchored this with a Linus Torvalds line, roughly: AI coding is a compiler level tool that changes what engineers do, not a replacement for engineering judgment.

## 6. Abstraction rent

The closing idea, and the one that ties the other five together.

**Every abstraction charges rent, and you pay it in opacity.** Pull in a prebuilt library and you buy convenience while selling understanding. You no longer know what the internals do, and you cannot debug what you do not understand.

His framing was to **apply the Unix instinct to MLOps**: do one thing well, and compose. Prefer small comprehensible pieces over large convenient ones.

The lines from this section that stuck:

- **The best system is the one you fully understand.**
- Every layer of abstraction is a layer of failure you cannot debug.
- Governance structure matters more than tooling choice.
- Legal review is the bottleneck, not engineering.
- Community trust takes two to three years after the code goes public.

He closed by noting that LLVM and clang have been displacing GCC. Researching this afterwards, **"displacing" overstates it**. Major vendors including AMD, Arm, IBM, Intel and Sony have moved to LLVM and Clang, largely for tooling quality and permissive licensing, but most Linux distributions still default to GCC. "Gaining significant ground" is more accurate.

His final line was the thesis of the whole talk: **every layer above scratch is there because you chose it**.

## Go explore

Sites and projects he explicitly told the room to look at:

- [Coder.com](https://coder.com/), self hosted cloud development environments with Terraform defined remote workspaces, governance and auditing
- [Kilo Code](https://github.com/Kilo-Org/kilocode), an open source AI coding agent for VS Code, JetBrains and CLI, with 400+ hosted models at no markup
- [Minimus](https://www.minimus.io/), hardened near zero CVE container images with FIPS, SLSA L3 and SBOM compliance
- NTP and OpenSSL, as case studies in critical infrastructure maintained by almost nobody

## Unresolved

> [!warning] One term still unidentified
> During the base image section he named three things rapidly. I captured them as "pine", "BLUG" and "coco's net". Two are now confirmed and appear in the body above. The third is still open:
>
> - **"BLUG" is unidentified.** It is an **acronym**, not a product name, which rules out the obvious candidates (Buildpacks, BuildKit, Bazel, Buildah). Given its two confirmed neighbours were a minimal base image and a CNCF project, it most likely sits in the same CNCF or OpenSSF supply chain space.
>
> If you attended and know what BLUG stands for, please open an issue.

Also unverified: he made a point about "a problem in CS" during the inference section that I could not capture in time.

## My Take

This talk used a lot of technical terms that only a highly experienced person would fully follow. I got some of the concepts live and definitely not all of them. I had to research several topics after the event just to write this note.

I think that was the intent. He was not trying to teach six things properly in forty minutes. He was giving a general overview of what is going on and making sure the audience goes and explores each one based on their own interest. Read that way it did its job, and the "go explore" list above is really the deliverable of the talk. I have followed up on more of it than I would have from a narrower session.

**Abstraction rent is the idea that stayed with me.** "Every layer of abstraction is a layer of failure you cannot debug" sounds obvious until you count how many layers are in your own stack that you could not explain.
