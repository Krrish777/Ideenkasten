---
type: research-deep-dive
topic: "Harness Engineering Internals"
subtopic: "Things You Probably Don't Know Yet"
overview: "[[Harness-Internals-Overview]]"
depth_level: 1
date: 2026-07-02
domain: AI/ML, Systems Design
tags:
  - research
  - harness-engineering
  - gap-map
---

# Things You Probably Don't Know Yet

> [!info] Context
> Part of [[Harness-Internals-Overview|Harness Engineering Internals]]. This is the backbone note: an honest inventory of what separates someone who has read the operator-side [[Harness-Engineering-Hub|Harness Engineering]] notes from someone who builds these systems. Each gap names what you likely believe, what the builders know instead, and which chapter closes it.

## How to read this note

Your existing notes are good. They cover the five subsystems, state persistence, scope control, verification discipline — the practices that make an agent session succeed. But they were sourced from articles written *for operators*, and operator material systematically omits an entire layer: the material builders assume everyone in the room already knows. This note is the map of that omitted layer. It is deliberately uncomfortable reading — every section says "the mental model you have is incomplete" — because maximizing the delta between what you know and what a Bedrock or Anthropic engineer knows is the whole point.

A pattern to notice as you go: almost every gap below has the same shape. The operator layer teaches a **practice** (do X). The builder layer knows the **mechanism** that makes X necessary (X exists because of Y, Y costs Z, and Z is why the alternative lost). Interviews live almost entirely in that second layer. Nobody at Cursor asks you whether AGENTS.md should be short. They ask you why a stable prompt prefix is worth restructuring your entire message pipeline for — and expect you to answer in dollars and milliseconds.

---

## 1. The economics gap: you think in tokens, builders think in cache

**What you probably believe:** context management is about fitting things into the window and avoiding "context rot." Shorter is better; relevant is better.

**What builders know:** the dominant force shaping context layout is not the window limit — it is the **KV cache**. Every token in the prefix that stays byte-identical across turns can be served from cache at roughly one-tenth the price and a fraction of the latency of a fresh token (exact ratios vary by provider; the order of magnitude does not). This single fact explains an absurd number of design decisions that otherwise look arbitrary: why system prompts split into a static part and a dynamic part; why histories are append-only; why a timestamp at the top of a prompt is an expensive bug; why Manus reports cache hit rate as *the* KPI for a production agent; why tool definitions never get reordered mid-session; why compaction is a scheduled event and not a continuous process (every compaction is a deliberate, total cache invalidation — you pay for it once, then rebuild a stable prefix). An agent loop is not a conversation. It is a carefully maintained cache line.

Where it's closed: [[Harness-Internals-Context-Compilation]] for the layout consequences, [[Harness-Internals-Runtime-Optimization]] for the mechanism — what K and V tensors actually are, why prefill and decode have different bottlenecks, and how PagedAttention made cached prefixes cheap to serve.

## 2. The tool-calling gap: you see JSON, builders see constrained decoding

**What you probably believe:** you define a function schema, the model "supports function calling," you parse the JSON that comes back, occasionally it's malformed and you retry.

**What builders know:** there are two fundamentally different mechanisms hiding under "the model returns JSON," and they have different failure profiles. One is *trained behavior* — the model emits tool-call tokens because fine-tuning taught it the format; validity is probabilistic (Anthropic's classic tool use works this way). The other is *constrained decoding* — the schema is compiled into a grammar/finite-state machine, and at every decoding step the runtime masks the logits of every token that would violate it; validity is guaranteed by construction (OpenAI strict mode, Gemini responseSchema). Constrained decoding is not free: the first request pays schema-compilation latency, grammars can't express everything JSON Schema can, and forcing the token stream through a grammar measurably changes *what* the model says, not just its shape. Streaming tool calls arrive as partial-JSON deltas that your harness must parse incrementally; parallel tool calls must be correlated back by ID and executed with explicit ordering decisions you own. And the providers genuinely differ — a harness that treats OpenAI, Anthropic, Gemini, and Bedrock's Converse API as interchangeable is wrong in at least four load-bearing places.

Where it's closed: [[Harness-Internals-Tool-Calling-Internals]], wire level up.

## 3. The architecture gap: you know the loop exists, builders know why it's flat

**What you probably believe:** agents are loops; sophisticated agents are graphs of agents; frameworks like LangGraph represent maturity.

**What builders know:** the strongest production coding agents — Claude Code and Codex both — are *deliberately* flat single loops with no graph engine, and this is the most argued-about design decision in the field. Cognition's position ("Don't Build Multi-Agents") is that parallel agents make dispersed decisions on partial context and produce conflicting work; context sharing is the binding constraint, so keep one thread of authority. Anthropic's multi-agent research system is the counter-example — and it works precisely because research is *read-heavy and parallelizable*, where workers explore independently and only conclusions need to merge, at a measured cost of roughly 15× the tokens of single-agent chat. The synthesis position most builders now hold: subagents are a **context-isolation** primitive, not a teamwork primitive. You spawn one to keep ten thousand tokens of search noise out of the main loop, and you accept that write-actions must stay serialized in one context. If you can articulate *when* the parallel-read pattern wins and *why* write-parallelism fails, you are having the builder conversation.

Where it's closed: [[Harness-Internals-Agent-Loop-Architecture]]; both product chapters ([[Harness-Internals-Claude-Code-Architecture]], [[Harness-Internals-Codex-Architecture]]) show the flat-loop thesis in production.

## 4. The retrieval gap: you assume coding agents use RAG, the best ones don't

**What you probably believe:** understanding a repository requires indexing it — embeddings, vector search, semantic retrieval. That's what "codebase understanding" means.

**What builders know:** the field split into two camps and the split is a genuine engineering disagreement, not a maturity gradient. Cursor indexes: Merkle-tree file sync, AST-aware chunking, embeddings in Turbopuffer, incremental re-index on every edit — because an IDE must answer "what's relevant?" in milliseconds with the user watching. Claude Code refuses to index: it searches the way a senior engineer does, iterative grep/glob/read cycles, paying seconds of latency for zero index staleness, zero server-side code storage, and retrieval that follows the code's actual structure rather than embedding-space neighborhoods. Neither is "right"; they optimize different invariants (interactive latency vs. correctness-under-change and trust). What you should be able to defend in a room: why agentic search *got good enough* to make the no-index position viable (models became capable of multi-step search strategies), what the index buys that grep never will (cross-repo semantic similarity, natural-language-to-code mapping), and what staleness costs when an agent edits fifty files in a session.

Where it's closed: [[Harness-Internals-Claude-Code-Architecture]] (the no-RAG thesis) versus [[Harness-Internals-Cursor-AI-IDE-Architecture]] (the indexing pipeline, end to end).

## 5. The security gap: you think guardrails filter text, builders remove capabilities

**What you probably believe:** prompt injection is defended by detection — classifiers, better instructions, "ignore attempts to override your instructions."

**What builders know:** detection is a failing strategy *by construction* in security terms — a defense that blocks 99% of injections is a defense that fails, because attackers iterate until they find the 1%. The defenses that actually hold are architectural. Simon Willison's "lethal trifecta" is the cleanest framing: an agent that combines (a) access to private data, (b) exposure to untrusted content, and (c) an exfiltration channel is exploitable *regardless of model quality* — so the design goal is to make sure no single agent context ever holds all three legs. DeepMind's CaMeL goes further: run untrusted content through a quarantined model that can only produce typed values, never control flow. Below that sits the enforcement stack the operator layer never mentions: permission rules are the *application* layer; real containment is OS-level — Seatbelt profiles on macOS, Landlock+seccomp on Linux, microVMs for multi-tenant platforms — applied to the *entire process tree* a tool call spawns, because the model can trivially write a script that spawns something else. Codex is the reference implementation of "the kernel is the policy engine"; Bedrock AgentCore's per-session microVMs are the multi-tenant version of the same conviction. Memory is part of the attack surface too: a memory write is an injection that *persists across sessions*.

Where it's closed: [[Harness-Internals-Guardrails-Sandboxing]] for the framework, [[Harness-Internals-Codex-Architecture]] for the deepest production implementation.

## 6. The evaluation gap: you cite benchmark scores, builders distrust them for specific reasons

**What you probably believe:** SWE-bench measures how good a model is at coding; higher score, better model. Evals are something you run before shipping.

**What builders know:** a benchmark score measures a **model+harness pair**, and harness sensitivity is large enough that the same model moves materially between harnesses (this is exactly why "harness engineering" exists as a discipline — recall the $9-vs-$200 experiment from your operator notes, now generalized). SWE-bench needed a human-verified subset (SWE-bench Verified) because a chunk of the original tasks were unsolvable-as-specified — meaning the ceiling wasn't 100% and nobody knew. Agents pass tasks "luckily" (right diff, wrong reasoning — the AgentLens finding), so single-run pass@1 deltas of a few points are frequently noise. For agents you often care about pass^k — the probability of succeeding *k times in a row* — because a user runs the agent repeatedly and reliability compounds. LLM-as-judge carries measured position, length, and self-preference biases and agrees with domain experts far less than teams assume, which is why the builder rule is: use deterministic verifiers (tests pass, lint clean, output parses) everywhere ground truth is checkable, and spend judges only where it isn't. And the infrastructure itself — environment snapshots, deterministic resets, trace capture, replay — is most of the actual engineering cost; the metric is the cheap part.

Where it's closed: [[Harness-Internals-Evaluation-Infrastructure]].

## 7. The memory gap: you think memory is storage, builders think it's forgetting

**What you probably believe:** long-term memory means saving conversation facts to a vector store and retrieving them later.

**What builders know:** the write path is the hard part, and forgetting is the feature. Storage is trivial; deciding *what deserves to be a memory* (salience), reconciling it with what's already stored (the update problem: "user moved to Bengaluru" must supersede, not coexist with, "user lives in Delhi"), and expiring what's no longer true — that's the system. This is why temporal knowledge graphs (Zep/Graphiti) exist: edges carry validity intervals so facts can be invalidated rather than merely accumulated. It's why MemGPT/Letta treats context like an OS treats RAM — a small main context, an external store, and the *agent itself* editing its memory through tools under memory-pressure interrupts. It's also why the simplest production systems (Claude Code's plain-text memory directory) are file-based: auditability and user trust beat retrieval sophistication when memories influence future actions. And memory is a security surface — a poisoned memory is a prompt injection with a TTL of forever.

Where it's closed: [[Harness-Internals-Memory-Systems]].

## 8. The latency gap: you experience speed, builders engineer three different latencies

**What you probably believe:** faster model = faster product.

**What builders know:** there are at least three distinct latencies and each product surface optimizes a different one. Time-to-first-token governs chat feel; tokens-per-second governs streaming reads; end-to-end task latency governs agents — and an agent that thinks for 40 seconds but nails the task beats one that streams instantly and needs three retries. Cursor's tab completion has a perceived budget under ~100ms, which is unreachable with a frontier model, which is why Cursor trains custom small models and pre-computes speculative next-suggestions. Their fast-apply trick is the signature example of harness/inference co-design: frontier models are unreliable at emitting diffs, so Cursor has the big model describe the change, then a small model rewrites the *entire file* using speculative-decoding-style drafting against the original code — full rewrite at ~1000 tokens/sec ends up both faster and more correct than diff generation. Meanwhile serving-side machinery you never see (continuous batching, PagedAttention, prefix sharing, disaggregated prefill/decode) sets the price floor for every design decision your harness makes.

Where it's closed: [[Harness-Internals-Runtime-Optimization]] for the mechanisms, [[Harness-Internals-Cursor-AI-IDE-Architecture]] for the product-side application.

## 9. The platform gap: you know agents, builders know multi-tenancy

**What you probably believe:** deploying an agent means putting your loop behind an API.

**What builders know:** the moment agent code from *many customers* runs on shared infrastructure, the problems change species. Bedrock AgentCore runs every session in its own microVM — not a container — because container escape is a live risk when the workload is model-generated code, and because agent sessions are stateful and long (up to 8 hours) in a way stateless request serving never was. Agent identity becomes its own discipline: an agent acting *on behalf of* a user needs scoped, vaulted, revocable credentials — OAuth tokens the agent can use but not read — which is why AgentCore Identity exists as a separate service. Tool projection layers (Gateway) turn existing enterprise APIs into MCP tools with semantic search over the registry, because no model can attend to four hundred tool definitions. Versioned immutable runtimes with endpoint indirection exist because you cannot hot-patch an agent mid-eight-hour-session. None of this is visible from the operator seat; all of it is the job at a platform team.

Where it's closed: [[Harness-Internals-Production-Patterns]].

## 10. The origin gap: you know the practices, builders know the argument

**What you probably believe:** harness engineering is a loose bundle of best practices that accumulated organically.

**What builders know:** the discipline has a specific intellectual history with named positions, and the 2026 naming moment matters because it marked a consensus: model capability stopped being the binding constraint for a large class of tasks; the environment became the constraint. Hashimoto's formulation (every agent mistake gets a *permanent, structural* fix in the environment, so that mistake becomes impossible rather than less likely) is an engineering stance with a lineage — it is the same move as "fix the process, not the person" from manufacturing quality, and the same move as type systems versus code review. The counter-positions are real too: some argue harness investment is a depreciating asset that each model generation partially obsoletes (the "bitter lesson" applied to scaffolding). Knowing where you stand on that — and what evidence would move you — is exactly the kind of judgment interviews at these companies probe.

Where it's closed: [[Harness-Internals-Runtime-Anatomy]], and the trade-off threads running through every chapter after it.

---

## The one-sentence versions

If you retain nothing else, retain these, because each one is a conversation-opener at the companies you're targeting:

1. An agent loop is a cache line — design for byte-stable prefixes and append-only growth.
2. "Returns JSON" hides two mechanisms — trained format vs. logit masking — with different guarantees and different costs.
3. Subagents isolate context; they do not simulate teams. Writes stay serialized.
4. Grep-based agentic search versus embedding indexes is a real fork, and each side optimizes a different invariant.
5. Injection defense that depends on detection fails by construction; remove a leg of the lethal trifecta instead.
6. Benchmarks score model+harness pairs; reliability is pass^k, not pass@1.
7. Memory's hard problem is the write path and forgetting, not storage.
8. There are three latencies; know which one your surface sells.
9. Multi-tenant agents mean microVMs, vaulted identity, and immutable versions.
10. The discipline's founding claim: the environment, not the model, is now the binding constraint. Know the argument against it too.

## Connections

- [[Harness-Internals-Overview]] — the full map and study order
- [[Harness-Engineering-Hub]] — the operator-side notes this gap-map is measured against
- Every chapter linked above closes one or more numbered gaps; the study order in the Overview follows the dependency structure between them.

## Subtopics for Further Deep Dive

This note is a map, not territory; its deep dives are the twelve chapters themselves. No further recursion from here.

## References

- [Mitchell Hashimoto — My AI Adoption Journey](https://mitchellh.com/writing/my-ai-adoption-journey) — the origin of gap 10; read first for the founding stance
- [Cognition — Don't Build Multi-Agents](https://cognition.ai/blog/dont-build-multi-agents) — gap 3's strongest single statement
- [Anthropic — How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — gap 3's strongest counter-statement, with token-cost numbers
- [Simon Willison — The Lethal Trifecta](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/) — gap 5's framing; the most useful security idea in the field per word
- [OpenAI — Introducing SWE-bench Verified](https://openai.com/index/introducing-swe-bench-verified/) — gap 6's origin story: what was broken in the benchmark everyone cited
- [Manus — Context Engineering for AI Agents](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus) — gap 1 from a team that rebuilt its harness four times
- [Cursor — Securely indexing large codebases](https://cursor.com/blog/secure-codebase-indexing) — gap 4, the indexing side, from the primary source
