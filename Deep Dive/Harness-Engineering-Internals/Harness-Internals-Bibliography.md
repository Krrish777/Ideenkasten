---
type: research-bibliography
topic: "Harness Engineering Internals"
overview: "[[Harness-Internals-Overview]]"
date: 2026-07-02
tags:
  - research
  - harness-engineering
  - bibliography
---

# Harness Engineering Internals — Annotated Bibliography

> [!info] Context
> The curated source library for [[Harness-Internals-Overview|Harness Engineering Internals]]. These are the sources the twelve chapter authors judged most load-bearing — each entry says what it teaches, why it matters, and when to read it. Chapter reference sections carry the longer tails; this note is the short list you'd actually hand a colleague.

## Reading strategy

Primary sources beat summaries everywhere in this field, and the field is young enough that you can actually read the primary sources — the entire canonical literature is maybe thirty documents. The pattern below repeats per topic: one company engineering post that states a position, one primary counter-position, one arXiv paper that measures the disagreement, and official docs for the mechanics. Read positions before mechanics; the docs only make sense once you know what fight each feature settles.

## Foundations

- [Mitchell Hashimoto — My AI Adoption Journey](https://mitchellh.com/writing/my-ai-adoption-journey) — The February 2026 post that named the discipline: every agent mistake gets a permanent, structural environment fix. Read first; ten minutes; everything else in this library is elaboration or rebuttal.
- [OpenAI — Harness Engineering](https://openai.com/index/harness-engineering/) — The field report that put numbers behind Hashimoto's stance: a 1M-line production app with no human-written lines. Read for what a maximal harness investment buys. (Blocks automated fetchers; [InfoQ's coverage](https://www.infoq.com/news/2026/02/openai-harness-engineering-codex/) is a faithful summary.)
- [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — Anthropic's builder-side counterpart; the bridge from your operator-side notes to this repository. Read second.
- [Birgitta Böckeler (martinfowler.com) — Harness engineering](https://martinfowler.com/articles/harness-engineering.html) — The synthesis piece that made the term legible to mainstream engineering. Read when you need to explain the discipline to someone who distrusts AI hype.
- [Zhang et al. — Stop Comparing LLM Agents Without Disclosing the Harness](https://arxiv.org/abs/2605.23950) — The paper that measures harness sensitivity and demands disclosure standards. Read before you ever cite a benchmark score in an interview.
- [Architectural Design Decisions in AI Agent Harnesses](https://arxiv.org/abs/2604.18071) — Academic survey of the design space. Read late, as a checklist that you haven't missed a dimension.

## Context Engineering

- [Anthropic — Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — The canonical statement that context, not prompts, is the unit of engineering. Read before the Manus post; it gives the vocabulary.
- [Manus — Context Engineering for AI Agents: Lessons from Building Manus](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus) — The single densest practitioner document in the field: KV-cache hit rate as THE production KPI, the 100:1 input/output ratio, mask-don't-remove, file-system-as-context, recitation. A team that rebuilt its harness four times telling you what survived. Read slowly.
- [Anthropic — Prompt caching documentation](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) — The mechanics: cache hierarchy (tools→system→messages), breakpoints, 5m/1h TTLs, 1.25x-write/0.1x-read pricing. Read with a calculator; the design consequences fall out of the numbers.
- [Codex Knowledge Base — Prompt Caching in Codex CLI](https://codex.danielvaughan.com/2026/04/21/codex-cli-prompt-caching-maximise-cache-hits-cost-reduction/) — Source-grounded walkthrough of how a real agent loop stays linear and append-only for cache's sake. The best worked example of gap #1 from the gap-map.
- [Chroma — Context Rot](https://www.trychroma.com/research/context-rot) — The empirical study (18 models) showing performance degrades with input length even on trivial tasks. Read when you need evidence, not vibes, for why context is a scarce resource.

## Tool Calling

- [Anthropic — Writing effective tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents) — The tool-design canon: namespacing, response formats, token efficiency, evaluation. Read before designing any tool surface.
- [Anthropic — Introducing advanced tool use](https://www.anthropic.com/engineering/advanced-tool-use) — Tool Search, Programmatic Tool Calling, input examples — with benchmark numbers. Read as the current frontier of the tool-calling API surface.
- [Anthropic — Structured outputs / strict tool use docs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) — Grammar caching, schema subset limits, complexity caps: where constrained decoding meets a production API. Read alongside the OpenAI guide for the comparison.
- [OpenAI — Function calling guide](https://developers.openai.com/api/docs/guides/function-calling) — Strict mode, parallel_tool_calls, allowed_tools, Lark-grammar custom tools. The other half of the provider comparison.
- [MCP — 2026 Roadmap](https://blog.modelcontextprotocol.io/posts/2026-mcp-roadmap/) — Stateless core, Tasks primitive, server discovery. Doubles as the protocol maintainers' honest list of what's broken in production MCP today. Read after the spec, not before.

## Agent Loops & Orchestration

- [Anthropic — Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) — The workflow/agent taxonomy the whole industry now uses. Read first in this section; it's the shared vocabulary.
- [Cognition — Don't Build Multi-Agents](https://cognition.com/blog/dont-build-multi-agents) — The single-threaded-context position stated at full strength. Read back-to-back with the next entry.
- [Anthropic — How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — The counter-position with token costs attached (~15x). The pair is the field's defining argument; hold both and you can answer any orchestration question.
- [OpenAI — Unrolling the Codex agent loop](https://openai.com/index/unrolling-the-codex-agent-loop/) — A frontier lab walking through its actual loop, turn by turn. The best public description of a production loop's inner mechanics.
- [GitHub — Multi-agent workflows often fail. Here's how to engineer ones that don't](https://github.blog/ai-and-ml/generative-ai/multi-agent-workflows-often-fail-heres-how-to-engineer-ones-that-dont/) — Failure-mode-first treatment from a team operating at fleet scale. Read for the postmortem energy the vendor posts lack.

## Claude Code

- [Claude Code docs — How the agent loop works](https://code.claude.com/docs/en/agent-sdk/agent-loop) — The official, verified description of the loop. Anchor every inference against this.
- [Claude Code docs — Best practices](https://code.claude.com/docs/en/best-practices) — Officially documented harness behavior (CLAUDE.md, permissions, hooks, subagents). The operator-side surface of the builder-side machinery.
- [Karan Prasad — How Claude Code Actually Works: Reverse-Engineering 512K Lines](https://karanprasad.com/blog/how-claude-code-actually-works-reverse-engineering-512k-lines) — The most thorough public teardown; minified-source analysis with methodology. Read with the epistemic caveat that it snapshots one version.
- [VILA-Lab — Dive into Claude Code](https://github.com/VILA-Lab/Dive-into-Claude-Code) — Systematic academic analysis of the design for reuse in future agent systems. The most citable of the teardowns.
- [Boris Cherny on dropping RAG for agentic search](https://x.com/bcherny/status/2017824286489383315) + [Pragmatic Engineer interview](https://newsletter.pragmaticengineer.com/p/building-claude-code-with-boris-cherny) — The no-index decision from the person who made it, with reasoning. Primary source for the field's most interviewed design choice.

## Codex

- [openai/codex — source repository](https://github.com/openai/codex) — The only major agent whose harness you can read. ToolRouter, unified_exec, landlock.rs, execpolicy — verifiable, not inferred. Read code here before believing any blog post, including OpenAI's.
- [Codex CLI is Going Native — GitHub discussion #1174](https://github.com/openai/codex/discussions/1174) — The Rust rewrite rationale in the maintainers' own words (runtime independence, GC pauses, native sandbox bindings). Short, primary, load-bearing.
- [Codex docs — Sandboxing](https://developers.openai.com/codex/concepts/sandboxing) — The normative reference for sandbox modes × approval policies. Read with the [Codex Knowledge Base source-reads](https://codex.danielvaughan.com/) which trace the docs back to the code.

## Cursor & AI IDEs

- [Cursor — Securely indexing large codebases](https://cursor.com/blog/secure-codebase-indexing) — Merkle-tree sync, chunk-hash caching, and the privacy architecture, from the primary source, with real latency numbers (median index 7.87s→525ms).
- [Cursor — Iterating with shadow workspaces](https://cursor.com/blog/shadow-workspace) — The hidden-window + LSP feedback loop design, including the kernel-level ambitions. The clearest statement of "give the AI an environment, not just a prompt" applied to editing.
- [Cursor — Editing files at 1000 tokens per second](https://cursor.com/blog/instant-apply) — Speculative edits / fast apply: why diffs fail and full-rewrite-with-speculation wins. The signature harness/inference co-design story.
- [Lex Fridman #447 — Cursor team transcript](https://lexfridman.com/cursor-team-transcript/) — Four founders talking architecture unscripted for hours: Tab latency budgets, model routing, why they forked VS Code. The highest-density secondary source on AI IDE engineering.
- [Zed — Zeta edit prediction](https://zed.dev/blog/edit-prediction) — The open-source recipe for a Tab-class model (data construction, training, serving). Read to de-mystify what Cursor won't publish.

## Guardrails & Sandboxing

- [Simon Willison — The lethal trifecta](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/) — The most useful security idea in the field per word: private data + untrusted content + exfiltration channel = exploitable, regardless of model quality. Read first; it reframes everything else.
- [CaMeL — Defeating Prompt Injections by Design](https://arxiv.org/abs/2503.18813) — DeepMind's capability-based architecture: untrusted content can produce values, never control flow. The strongest architectural (non-detection) defense on paper. Read after Willison.
- [Anthropic — Making Claude Code more secure and autonomous with sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing) — How sandboxing changes the permission calculus: contain more, ask less. The autonomy-security trade stated by a vendor shipping it.
- [PCAS — Formal Policy Enforcement for Real-World Agentic Systems](https://arxiv.org/abs/2602.16708) — Datalog dependency-graph policies with a reference monitor; where policy engines are heading past OPA-style rules. Read late; it assumes the rest of the section.
- [Microsoft — Spotlighting (arXiv 2403.14720)](https://arxiv.org/pdf/2403.14720) — Data/instruction separation via encoding. Read as the honest middle ground: helpful, measurable, and explicitly not sufficient alone.

## Runtime Optimization

- [Kwon et al. — PagedAttention / vLLM (SOSP '23)](https://arxiv.org/abs/2309.06180) — The paper that made KV memory a solved allocation problem (20–38% utilization → near-full) and enabled cheap prefix sharing. The serving-side foundation of every caching claim in this repository.
- [kipply — Transformer Inference Arithmetic](https://kipp.ly/transformer-inference-arithmetic/) — Back-of-envelope FLOPs/bandwidth math for inference. Read early; it's the mental arithmetic that makes every other performance claim checkable.
- [NVIDIA — Full-stack optimizations for agentic inference with Dynamo](https://developer.nvidia.com/blog/full-stack-optimizations-for-agentic-inference-with-nvidia-dynamo/) — Agentic workloads (95–98% cache-hit coding agents) reshaping the serving stack: disaggregation, KV offload tiers. Read for where inference and harness design are co-evolving.

## Memory Systems

- [MemGPT — Towards LLMs as Operating Systems](https://arxiv.org/abs/2310.08560) — The paper that framed memory as paging: main context vs external context, self-editing via tools, memory-pressure interrupts. The conceptual root of the whole subfield.
- [Zep — A Temporal Knowledge Graph Architecture for Agent Memory](https://arxiv.org/abs/2501.13956) — Why edges need validity intervals: facts get invalidated, not just accumulated. The strongest argument that memory is a consistency problem.
- [Mem0 — Scalable Long-Term Memory](https://arxiv.org/abs/2504.19413) — The extraction-pipeline architecture (extract→dedupe→resolve). Read together with the next entry.
- [Zep — Is Mem0 Really SOTA in Agent Memory?](https://blog.getzep.com/lies-damn-lies-statistics-is-mem0-really-sota-in-agent-memory/) — The benchmark dispute as a case study in eval integrity: configuration fragility, baseline choice, motivated measurement. Read for the meta-lesson, not the verdict.
- [Anthropic — Memory tool docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/memory-tool) — File-based, auditable, model-driven memory as a shipped product decision. The minimal-architecture counterpoint to the graph/vector systems.

## Evaluation

- [Anthropic — Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) — The framework: what to measure, with what verifiers, gated how. The section's spine.
- [Han-Chung Lee — Hidden Technical Debt of Agent Evaluation Infrastructure](https://leehanchung.github.io/blogs/2026/06/13/hidden-technical-debt-agent-evaluation-infra/) — Control-plane/data-plane decomposition; why the infrastructure, not the metric, is the cost. The Sculley "technical debt" paper's spiritual successor for agents.
- [OpenAI — Introducing SWE-bench Verified](https://openai.com/index/introducing-swe-bench-verified/) — The post-mortem that revealed the benchmark everyone cited had unsolvable tasks. Read as the template for auditing any benchmark you're handed.
- [Harness-Bench (arXiv 2605.27922)](https://arxiv.org/abs/2605.27922) — Same models, different harnesses, different scores — quantified. The empirical heart of this repository's founding claim.
- [AgentLens — The Lucky Pass Problem (arXiv 2605.12925)](https://arxiv.org/abs/2605.12925) — Right diff, wrong reasoning: why pass@1 overstates competence. Pair with [MT-Bench / LLM-judge biases (arXiv 2306.05685)](https://arxiv.org/abs/2306.05685) and [Terminal-Bench](https://www.tbench.ai/).

## Production Platforms

- [AWS — AgentCore Runtime: How it works](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-how-it-works.html) — The official per-session microVM isolation model, session lifecycle, versioned runtimes. The best-documented agent platform; read as the reference architecture.
- [Joud W. Awad — AWS Bedrock AgentCore Deep Dive](https://joudwawad.medium.com/aws-bedrock-agentcore-deep-dive-6822e4071774) — The practitioner walkthrough that connects the seven AgentCore services into one system. Read after the docs to see the seams.
- [Anthropic — Building agents with the Claude Agent SDK](https://claude.com/blog/building-agents-with-the-claude-agent-sdk) — The harness-as-product position: ship the loop, not a framework. Contrast with AWS's infrastructure-primitives position.
- [Linux Foundation — A2A protocol project launch](https://www.linuxfoundation.org/press/linux-foundation-launches-the-agent2agent-protocol-project-to-enable-secure-intelligent-communication-between-ai-agents) — Cross-vendor agent interop going to neutral governance; the signal that agent-to-agent is becoming plumbing.
- [OpenTelemetry — GenAI observability (2026)](https://opentelemetry.io/blog/2026/genai-observability/) — The semantic-convention standardization of agent tracing. Read when instrumenting anything; it's what every platform's observability now emits.

## Level 2 — Deep-Dive Wave (batch 1)

Each Level 2 chapter carries its own full annotated reference list in its §17; those are the detailed bibliographies. Indexed here are only the strongest *new* anchor primaries the batch added to the library.

**Prompt Assembly & Cache Economics** → full list in [[Harness-Internals-Prompt-Assembly-Cache-Economics]] §17
- [Anthropic — Prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) — the authoritative explicit-breakpoint mechanics and pricing; every cache-cost figure traces here.
- [OpenAI — Prompt Caching 201](https://developers.openai.com/cookbook/examples/prompt_caching_201) — the automatic model's internals (1,024-token floor, routing hash, `prompt_cache_key`); read against the Anthropic docs to feel the explicit-vs-automatic fork.
- [Codex source — `client.rs`](https://github.com/openai/codex) (`codex-rs/core/src/client.rs`) — the primary artifact proving `prompt_cache_key` defaults to `thread_id`; read the source, not the reimplementations.
- [Ankit Sinha — Prompt Engineering for KV-Cache](https://ankitbko.github.io/blog/2025/08/prompt-engineering-kv-cache/) — the controlled TTFT/hit-rate measurement behind the latency numbers.

**Compaction Pipelines** → full list in [[Harness-Internals-Compaction-Pipelines]] §17
- [Anthropic — Server-side compaction](https://platform.claude.com/docs/en/build-with-claude/compaction) — the official `compact_20260112` primitive and default summary prompt.
- [Piebald-AI — claude-code-system-prompts](https://github.com/Piebald-AI/claude-code-system-prompts) — source-extracted, versioned verbatim summary templates; the most authoritative non-Anthropic source for what the summarizer is told.
- [OpenAI Codex — `compact.rs`](https://github.com/openai/codex/blob/main/codex-rs/core/src/compact.rs) and [Gemini CLI — `chatCompressionService.ts`](https://github.com/google-gemini/gemini-cli/blob/main/packages/core/src/context/chatCompressionService.ts) — the two richest open compactor implementations; read the actual code.
- [MemGPT](https://arxiv.org/abs/2310.08560) and [MEM1](https://arxiv.org/abs/2506.15841) — the OS-paging framing and the RL-trained constant-memory agent; theory and training frontier.

**Subagent Orchestration** → full list in [[Harness-Internals-Subagent-Orchestration]] §17
- [Anthropic — How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — the primary source for delegation fields, the 90.2%/15×/80%-variance numbers; the chapter's central argument.
- [Cemri, Pan et al. — Why Do Multi-Agent LLM Systems Fail? (MAST)](https://arxiv.org/abs/2503.13657) — the 14-mode failure taxonomy with per-mode percentages; the empirical map of the failure section.
- [Single-Agent LLMs Outperform Multi-Agent Systems Under Equal Thinking Token Budgets](https://arxiv.org/abs/2604.02460) — the equal-budget correction; the strongest skeptical counterweight to Anthropic's numbers.
- [Agent Contracts: Resource-Bounded Autonomous AI Systems](https://arxiv.org/abs/2601.08815) — the budget-conservation law and runtime enforcement grounding budget propagation.

**Speculative Decoding** → full list in [[Harness-Internals-Speculative-Decoding]] §17
- [Leviathan et al. — Fast Inference from Transformers via Speculative Decoding](https://arxiv.org/abs/2211.17192) — the original formulation and the distribution-preservation proof reconstructed in the chapter.
- [Li et al. — EAGLE-1/2/3](https://github.com/SafeAILab/EAGLE) — feature-level autoregression and dynamic draft trees; why self-drafting beats independent drafts.
- [Su et al. — The Synergy of Speculative Decoding and Batching](https://arxiv.org/abs/2310.18813) and [MagicDec](https://arxiv.org/abs/2408.11049) — the batching-collapse result and its long-context reversal; read as a pair for the non-monotone picture.
- [Cursor — Editing Files at 1000 Tokens per Second](https://cursor.com/blog/instant-apply) — the production deterministic speculative-edits variant.

**Memory Poisoning Defense** → full list in [[Harness-Internals-Memory-Poisoning-Defense]] §17
- [MINJA — Memory Injection via Query-Only Interaction](https://arxiv.org/abs/2503.03704) — proves poisoning needs no backend access, only ordinary queries; why the write path is the boundary.
- [AgentPoison](https://arxiv.org/abs/2407.12784) (NeurIPS 2024) and [PoisonedRAG](https://arxiv.org/abs/2402.07867) (USENIX Sec 2025) — the embedding-space and knowledge-corruption attack formalizations.
- [CaMeL](https://arxiv.org/abs/2503.18813) and [FIDES](https://arxiv.org/abs/2505.23643) — capability-based defense and the dual-lattice information-flow-control foundation the defense rests on.
- [OWASP Top 10 for Agentic Applications (ASI06)](https://genai.owasp.org/2025/12/09/owasp-top-10-for-agentic-applications-the-benchmark-for-agentic-security-in-the-age-of-autonomous-ai/) — places memory poisoning in the standard taxonomy.

## Level 2 — Deep-Dive Wave (batch 2)

Same rule as batch 1 — each chapter's §17 holds its full annotated reference list, and those §17 URLs were fetched during research. To avoid re-transcribing (and risking corrupting) links I did not personally re-verify this session, this index names each chapter's strongest anchor sources and points to its §17 for the exact URLs. The two arXiv links reproduced below are the ones already vetted elsewhere in this bibliography.

**Kernel Sandbox Enforcement** → full list in [[Harness-Internals-Sandbox-Kernel-Enforcement]] §17
- The `openai/codex` source itself (`codex-rs/linux-sandbox`, `sandboxing/`) — the open reference implementation; the chapter reproduces the real Seatbelt `.sbpl` profiles and the `landlock.rs`/`bwrap.rs` modules line-level. This is the primary artifact proving Codex now defaults to bubblewrap with Landlock behind `use_legacy_landlock` (independently confirmed this session via the GitHub API).
- Landlock kernel documentation (ABI V1–V5 versioning + `best_effort` negotiation), the seccomp(2)/landlock(7) man pages, and Chromium's Linux sandboxing design doc — the canonical two-layer prior art. Exact URLs in the chapter §17.

**MicroVM Sandbox Infrastructure** → full list in [[Harness-Internals-MicroVM-Sandbox-Infrastructure]] §17
- The Firecracker paper (Agache et al., NSDI 2020), Firecracker's snapshotting docs, AWS Bedrock AgentCore runtime docs, and Modal's memory-snapshots engineering post — the foundational paper plus the production CoW/warm-pool accounts. AgentCore VMM internals are labeled inference in the chapter. Exact URLs in the chapter §17.

**Agentic Search vs Embedding Retrieval** → full list in [[Harness-Internals-Agentic-Search-vs-Embedding-Retrieval]] §17
- Cursor's code-search blog posts, Voyage's voyage-code-3 writeup (code-specialized embedder deltas), the RAG-MCP / "too many tools" paper (tool-selection as IR), and Zoekt's trigram-index internals. Exact URLs in the chapter §17.

**Information-Flow Control for LLM Agents** → full list in [[Harness-Internals-Information-Flow-Control-Agents]] §17
- [CaMeL](https://arxiv.org/abs/2503.18813) and [FIDES](https://arxiv.org/abs/2505.23643) — already anchor sources for the batch-1 Memory-Poisoning chapter; here they are the capability-algebra and dual-lattice foundations. The chapter adds NeuroTaint, MVAR, RTBAS, and the GIF/quantitative-information-flow line (all arXiv IDs reported verified-to-resolve by the research agent), plus the classic IFC theory (Denning's lattice model, Myers–Liskov decentralized labels). Exact URLs in the chapter §17.

## Level 2 — Deep-Dive Wave (batch 3)

Same URL-honest rule: each chapter's §17 holds its full annotated reference list with the exact URLs the research agent fetched; indexed here are the strongest anchors by name, with URLs reproduced only where already vetted elsewhere in this bibliography or reported verified-to-resolve this session.

**Durable Execution and Event-Sourced Agent State** → full list in [[Harness-Internals-Durable-Execution]] §17
- Temporal's durable-execution + workflow-definition docs, LangGraph persistence/checkpointer docs, and Martin Fowler's *Event Sourcing* — the three reference models the chapter compares (durable-workflow engine vs checkpointer vs event-sourced store). Diagrid's "Checkpoints Are Not Durable Execution" and DBOS-vs-Temporal are the sharpest contrast pieces. Exact URLs in the chapter §17. The load-bearing verifiable primitive throughout is the Anthropic Messages API constraint that every `tool_result` must follow its `tool_use` (the compaction/durability collision).

**Schedulers, Background Tasks, and Mid-Turn Steering** → full list in [[Harness-Internals-Scheduling-And-Steering]] §17
- The Codex `app-server` README (the exact `turn/start` · `turn/interrupt` · `turn/steer` protocol) is the single most valuable primary here; plus Dean & Barroso's *The Tail at Scale* for hedging, Claude Code interactive-mode docs, and the cooperative-cancellation literature (Go `context`, structured concurrency). Exact URLs in the chapter §17; codex-rs cancellation-token internals are labeled inference.

**Planning Layers: Plan Mode, Todo State, and Reflection Loops** → full list in [[Harness-Internals-Planning-And-Reflection]] §17
- The *skeptical* literature is the point: Huang et al. "Large Language Models Cannot Self-Correct Reasoning Yet" (arXiv 2310.01798), Kamoi et al.'s self-correction survey (2406.01297), and Stechly/Kambhampati on self-verification limits (2402.08115) — read against the original Reflexion (2303.11366) and Self-Refine (2303.17651) claims. Manus's context-engineering post is the source for the "recitation" pattern. Exact URLs in the chapter §17.

**The Economics of Agent Topologies** → full list in [[Harness-Internals-Agent-Topology-Economics]] §17
- [Single-Agent LLMs Outperform Multi-Agent Systems Under Equal Thinking Token Budgets](https://arxiv.org/abs/2604.02460) and [Agent Contracts](https://arxiv.org/abs/2601.08815) — both already anchor sources in this bibliography; here they bound the two regimes of the cost model. The chapter adds an affine-budget-type-system line (arXiv 2606.04056, reported verified) as the principled fork-bomb fix, plus Anthropic's multi-agent-research economics (the 15×/90.2% figures) and the context-rot measurements (Chroma/Stanford). Exact URLs in the chapter §17.

**Agent Progress Metrics** → full list in [[Harness-Internals-Agent-Progress-Metrics]] §17
- The two research leads the agent verified-to-resolve: [The Irrational Machine / perseveration loops](https://arxiv.org/abs/2510.10823) and [Semantic Early-Stopping](https://arxiv.org/abs/2606.27009). Plus the process-reward-model line (PRM800K "Let's Verify Step by Step", Math-Shepherd) and RePro's online-vs-retrospective progress-prompting result (online prompting −8.6%, retrospective +7.9%). Exact URLs in the chapter §17; recent-2026 preprints are labeled reported-not-settled.

## Level 2 — Deep-Dive Wave (batch 4)

Same URL-honest rule: each chapter's §17 holds the full annotated reference list with the exact URLs the research agent fetched; indexed here are the strongest anchors by name, with URLs reproduced only where already vetted or reported verified-to-resolve this session.

**Constrained Decoding Engines** → full list in [[Harness-Internals-Constrained-Decoding-Engines]] §17
- The four engine references the chapter compares — the Outlines efficient-guided-generation paper, XGrammar (MLC blog + paper, the compressed-FSM/context-expansion approach), llguidance, and the vendor structured-outputs docs (OpenAI's Lark-CFG + Anthropic tool-use forcing). The load-bearing critique thread is the "constrained decoding degrades reasoning" literature ("Let Me Speak Freely" and the CRANE reason-then-constrain fix) plus JSONSchemaBench's finding that engines silently approximate hard schemas. Exact URLs in the chapter §17; Anthropic's structured-outputs backend engine is undocumented and labeled inference, while OpenAI→llguidance is the one confirmed vendor-backend link.

**MCP Protocol Internals** → full list in [[Harness-Internals-MCP-Protocol-Internals]] §17
- The [Model Context Protocol specification](https://modelcontextprotocol.io) (Lifecycle, Transports, Tools, Authorization pages, 2025-06-18 — quoted verbatim for the JSON-RPC message shapes) is the single load-bearing primary; plus the 2026 Release-Candidate announcement (the `initialize`-handshake removal SEP-2575, stateless core, Tasks), the SSE-deprecation postmortem, and Simon Willison's MCP prompt-injection writeup. Exact URLs in the chapter §17; the RC is flagged near-final-but-not-ratified (locked May 2026, unpublished as of this session).

**Programmatic Tool Calling and Code Mode** → full list in [[Harness-Internals-Programmatic-Tool-Calling]] §17
- Anthropic's Programmatic Tool Calling / advanced-tool-use docs and "Code Execution with MCP" post; Cloudflare's two Code Mode posts; the [CodeAct paper](https://arxiv.org/abs/2402.01030) (reported fetched by the agent); HuggingFace smolagents (launch + secure-code-execution docs) and the NCC Group smolagents security teardown. The verified token-savings band (37% / 98.7% MCP / 99.9% Cloudflare / +11%−24% dynamic filtering) and the permission-enforcement contrast (Anthropic re-surfaces each call; Cloudflare binds at the isolate perimeter) live in §2–§10. Exact URLs in the chapter §17.

**The Responses API as an Agent Protocol** → full list in [[Harness-Internals-Responses-API-Protocol]] §17
- OpenAI's own docs are the spine — migrate-to-responses, the reasoning guide (encrypted reasoning, ZDR), conversation-state, the streaming-events reference, and the reasoning-items/function-calls cookbooks. Source-verified Codex GitHub issues (#4047, #17541, #20774, #25290) supply the `ResponseItem` enum fields, the well-formedness 400-error surface, and the client-side rollout-persistence evidence. Exact URLs in the chapter §17; the *contents* of `encrypted_content` are opaque by design and labeled community-analysis inference.

**A2A Protocol Internals** → full list in [[Harness-Internals-A2A-Protocol-Internals]] §17
- The [A2A specification](https://a2a-protocol.org) (both the stable v0.3.0 JSON-RPC representation and the v1.0 protobuf-canonical generation — the chapter teaches on the former and flags the wire-spelling drift), the two Linux Foundation press releases (launch + one-year), Google's launch blog, the Credal critique, and the CSA/MAESTRO threat-modeling thread. Exact URLs in the chapter §17; production traffic volume is unpublished, so the "little meaningful traffic yet" read is labeled inference.

## Community index

- [awesome-harness-engineering](https://github.com/ai-boost/awesome-harness-engineering) — The living index of the field. Not a source itself; the place to check quarterly for what this bibliography is missing.

## Connections

- [[Harness-Internals-Overview]] — study order for the chapters these sources feed
- [[Harness-Internals-Explore-Next]] — the deferred second wave; most of its topics start from a source on this page
