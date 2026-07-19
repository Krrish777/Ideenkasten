---
event: Software Architects Bangalore
organizer: Devon
city: BLR
link: https://www.meetup.com/softwarearchitectsbangalore/events/315179809/
---

# Software Architects Meetup - Hub

> [!abstract] What this was
> A four talk session run by the Software Architects Bangalore group, hosted by Devon. The idea that kept coming back across all four talks was **the cost of abstraction**: what you give up when you accept someone else's default, whether that default is a base image, a framework, a benchmark or a scoring function, and what it takes to get that control back.
>
> Five talks were scheduled. One was cancelled when the speaker could not make it, and was replaced on the spot by a founder walkthrough that turned out to be **the most technically detailed session of the day**.

## Key Takeaways

- **Convenience is paid for with opacity.** Every abstraction you adopt is a layer of failure you cannot debug. Adopt deliberately rather than by default.
- **Minimal base images are an architecture decision**, not a DevOps chore. What you inherit at `FROM` sets your CVE surface, your image size and your compliance story for the life of the service.
- **Treat code, data and model as one versioned unit.** Git for code, [[DVC]] for data and models, bake both into the image, promote through **blue green** with a human gate.
- **Scaling is a measurement discipline** rather than a pattern catalogue. Measure, find the actual bottleneck, fix that one thing, measure again.
- **Inference performance is an OS problem too.** Token generation is bursty, so every thread sleep and wake pays a [[CFS Scheduler]] latency tax. **CPU pinning** and [[NUMA]] locality belong in the architecture review.
- Agent token cost is an architecture problem with a known solution shape. **Do not send data to the model.** Send metadata and let tools write results to disk. Oodle's v0 to v3 journey arrived independently at what Anthropic and Manus have since published.
- **LLM as Judge has a documented bias catalogue.** Position, verbosity, self enhancement, style, sycophancy and bandwagon biases are named, measured and published. Running LLM evals without controlling for these produces numbers that look precise and mean nothing.
- **Open source now has to be designed for AI participants.** Projects built for human scale contribution are being overwhelmed by AI generated PR volume. **Architecture that is easy to review beats architecture that is easy to write.**

## Talks

| # | Talk | Speaker | What you'll get |
|---|------|---------|-----------------|
| 1 | [[01 Six Architecture Decisions - Sachin Garg\|Six Architecture Decisions the Open Source World Just Made For You]] | Sachin Garg | A fast tour of six defaults: base images, provenance, ML deployment, inference, AI contributors and abstraction rent, and why each is now a decision you are making whether you know it or not |
| 2 | [[02 Architecting for 1M+ RPS - Subal Bain\|Architecting Systems for 1M+ Requests Per Second]] | Subal Bain | The measure, optimise, measure loop and the standard scaling toolkit: horizontal scaling, indexing, connection pooling, read/write splitting |
| 3 | [[03 Oodle AI - Agent Observability\|Oodle AI: Cutting Token Costs in Agent Observability]] | Oodle AI (replacement talk) | A four stage architecture evolution for making an LLM analyse production logs without drowning in tokens. The best worked example of the day |
| 4 | [[04 LLM as Judge - Arkadip Basu\|LLM as Judge: Removing Barriers in AI Evaluation]] | Arkadip Basu | The evaluation ladder from manual review to Agent as a Judge, the prompt techniques that make judges reliable, and the six biases that make them lie |

> [!info] Scheduled but cancelled
> "Spend Less, Ship More: Cutting Token Costs in Coding Agents" by Vinit Kumar Goel. The speaker could not reach the venue. Replaced live by talk 3. The two talks covered adjacent ground, so the session kept its token economics thread.

## Open Threads

Things raised at this event that are still unresolved:

- [ ] **"BLUG"**, named in talk 1 and captured phonetically. It is an **acronym**, which rules out Buildpacks, BuildKit and Bazel. Its two confirmed neighbours were Alpine and Confidential Containers, so it most likely sits in the same CNCF or OpenSSF supply chain space.
- [ ] **"BUOM"**, named during talk 3. Also likely an **acronym**. No match found in any observability context.
- [ ] The exact module names in the [[Agent as a Judge]] paper, to check against the five steps captured in talk 4.

Resolved since publishing:

- [x] **"pine"** is **Alpine**, confirmed. Now in the body of talk 1.
- [x] **"coco's net"** is **[[Confidential Containers]]** (CoCo), confirmed. Now in the body of talk 1.

## Provenance

Written from handwritten notes taken during the event, then enriched with research afterwards. The talks moved faster than any pen. Where my capture was thin I have filled gaps from primary sources and said so. Anything I could not verify is listed under Open Threads rather than smoothed over.

Corrections welcome. See [[CONTRIBUTING]].
