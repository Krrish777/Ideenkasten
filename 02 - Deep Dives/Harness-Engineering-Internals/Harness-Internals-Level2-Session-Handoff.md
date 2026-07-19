---
type: session-handoff
topic: "Harness Engineering Internals"
overview: "[[Harness-Internals-Overview]]"
date: 2026-07-03
status: ready-to-dispatch
batch: 5
tags:
  - research
  - harness-engineering
  - handoff
---

# Level 2 Wave — Session Handoff (Batch 5)

> [!success] Batches 1–4 shipped
> Twenty chapters written, QA'd, and integrated. **Clusters A, B, and C are complete.** The security cluster's data-flow spine (Information-Flow Control), its first discovered topic (Agent Progress Metrics), and the entire tool-calling/protocol layer (constrained decoding, MCP, programmatic tool calling, Responses API, A2A) are built. See [[Harness-Internals-Explore-Next]] for check-off state and the unknown-unknowns (U7–U20). This note is the ready-to-run contract for **batch 5**.

> [!warning] Composition is a flagged decision — confirm or redirect before running
> The staged batch below is the **recommended** composition: **Cluster D's product-internals core** (#18, #19, #20, #21, #22) — the Claude Code permission/isolation layer and the Codex execution layer, as one thematically tight "harness guts" batch. This mirrors the "finish the coherent cluster" choice made for batch 4 (Cluster C), and it leaves the two remaining Cluster D topics (#23 Edit-Prediction, #24 Verification-Sandboxes-LSP — both Cursor) to pair naturally with Clusters E/F in batch 6.
> **The honest counter-pressure:** two 2-source unknown-unknowns have now been *parked for two batches* — **U11 Reward-Hacking & the Verification Horizon** and **U12 Fleet Cost-Governance Gateway** — plus batch 4 added a third strong one, **U16 the cross-vendor protocol standard**. By the "promote the top corroborated unknown-unknown each batch" discipline used in batches 2–3, these are overdue. So the clean alternative is (B) **the reliability/protocol UU cash-out**: U11 + U12 + U16 + U13 (process reward models) + U17 (capability-typed bindings). A third option (C) is to interleave: 3 Cluster D + U11 + U12. Swapping is a 5-minute edit to the chapter blocks below. **If in doubt, ask the user which they want before dispatching.**

## How to run this batch

1. Every agent reads the verbatim contract first: [[Harness-Internals-Research-Contract]] (paste it, don't paraphrase). Its `date:` is already today; tell each agent to set `date:` to today in its chapter frontmatter.
2. Dispatch all 5 as parallel general-purpose agents in a single message. Each prompt = the contract + the chapter block below. Restate the output path and contract path in each prompt — that preempts the "finished research, didn't write the file" stall.
3. If an agent finishes research but doesn't write the file, resume it (SendMessage) with the output path + contract path restated.
4. When all land: verify each (18 sections, word count, Mermaid safety, wikilinks, frontmatter), then integrate exactly as batches 1–4 — Overview Level 2 table (add a Batch-5 block, bump `subtopics_count` 32→37), URL-honest Bibliography section, Explore-Next check-offs + a "Unknown-Unknowns surfaced by batch 5" section, and **propagate any flagged parent correction ONLY after independently verifying it against primary source** (batch 2 confirmed the Codex/bubblewrap correction via the GitHub API before editing; batch 3 declined a single-source teardown and softened-with-cross-link; batch 4 *deepened-with-cross-link* the Codex encrypted-reasoning claim without importing an unverified forensic count). Update memory, then rewrite this handoff for batch 6.

## Why these five (recommended slate)

Batch 5 does the **product-system internals of the two open coding agents** — the parts of Claude Code and Codex that a Level 1 chapter sketched but never opened: the permission pipeline and its shell-AST parser, subagent isolation/IPC, Codex's unified-exec PTY lifecycle, its cloud container execution, and execpolicy's semantic command analysis. These five interlock (permission → isolation → execution → cloud → policy) and are the highest interview-load-bearing "how does the harness actually enforce and execute" material left. After this batch, 5 roadmap topics remain (D: 23–24, E: 25–26, F: 27), plus the still-unbuilt UUs.

## The 5 chapter contracts (batch 5 — recommended: Cluster D core)

### B5-1 — Claude Code's Permission Pipeline and the Bash AST Parser *(Cluster D #18)*
- **Output**: `Harness-Internals-Claude-Code-Permission-Pipeline.md`
- **Parents (read in full first)**: [[Harness-Internals-Claude-Code-Architecture]], [[Harness-Internals-Guardrails-Sandboxing]] (reference [[Harness-Internals-Runtime-Anatomy]] for the permission-engine sketch and [[Harness-Internals-Sandbox-Kernel-Enforcement]] for the layer *below* the parser)
- **Why**: the permission pipeline is where Claude Code's safety actually lives, and its shell-command parser (community-reported ~4,400 lines) is the single most attacked-and-defended surface in the harness — a parser bug is a sandbox escape.
- **Must answer**: (1) The deny-first evaluation cascade — the precedence order of hooks, rules, permission mode, and sandbox, with what wins when they conflict. (2) How the Bash command is parsed into an AST and matched against allow/deny rules — and how metacharacter/obfuscation attacks (command substitution, quoting tricks, `$IFS`, newline injection) are defeated or missed. (3) Where the parser *fails open vs fails closed*, and why that choice. (4) How `allowedTools`/`disallowedTools`, `--dangerously-skip-permissions`, and hooks compose in practice. (5) The relationship between the prompt-level permission gate and the kernel sandbox below it (defense in depth vs redundancy). (6) How this compares to Codex's execpolicy (cross-link B5-5) — AST-matching rules vs semantic classification.
- **Leads**: Claude Code docs (permissions, hooks, settings, IAM), community teardowns of the permission engine and the shell parser, the `--dangerously-skip-permissions` discussion, prompt-injection-via-bash writeups, any published parser CVE/bypass analyses. Label reverse-engineered internals as community analysis.

### B5-2 — Claude Code Subagent Isolation and IPC *(Cluster D #19)*
- **Output**: `Harness-Internals-Claude-Code-Subagent-Isolation.md`
- **Parents (read in full first)**: [[Harness-Internals-Claude-Code-Architecture]] (reference [[Harness-Internals-Subagent-Orchestration]] for the fork-boundary theory this makes concrete, and [[Harness-Internals-MicroVM-Sandbox-Infrastructure]] for the isolation substrate)
- **Why**: subagent orchestration (A3) covered the *decision*; this covers the *mechanism* — how Claude Code actually isolates a subagent's context, transcript, and filesystem, and where the isolation is leaky.
- **Must answer**: (1) The sidechain-transcript model — how a subagent's conversation is kept separate from the parent's and what exactly crosses back. (2) The file-mailbox / result-passing IPC and its race windows (concurrent writes, partial reads, TOCTOU). (3) Worktree isolation vs remote isolation vs same-process subagents — the spectrum and when each is used. (4) What state is *shared* vs *copied* (filesystem, env, MCP connections, permissions) and the leakage implications. (5) How `agent-teams` (peer-to-peer messaging, the batch-1 U4 primitive) changes the isolation model vs the orchestrator/worker tree. (6) Failure modes: orphaned subagents, budget/permission inheritance bugs, transcript bleed.
- **Leads**: Claude Code subagents docs + agent-teams docs/changelog, community teardowns of the sidechain/IPC mechanism, worktree/remote isolation docs, the file-mailbox reverse-engineering. Label internals as community analysis; verify the agent-teams primitive against current docs.

### B5-3 — Unified Exec and PTY Session Management *(Cluster D #20)*
- **Output**: `Harness-Internals-Codex-Unified-Exec.md`
- **Parents (read in full first)**: [[Harness-Internals-Codex-Architecture]] (reference [[Harness-Internals-Guardrails-Sandboxing]] for the per-command sandbox wrapping that unified-exec must preserve)
- **Why**: unified exec is how Codex gets *stateful* shell interaction (activated venvs, running dev servers, REPLs) without giving up per-command sandboxing — a genuinely hard lifecycle problem the Codex-Architecture chapter only sketched (transient/persistent promotion, the LRU-64 cap, stuck-session issue #5948).
- **Must answer**: (1) The transient-vs-persistent promotion logic — the yield window, and how a process that outlives it gets parked in the session store. (2) PTY buffering, output multiplexing, and how the model sends further input to a live session by `session_id`. (3) Stuck-session detection — the `docker compose logs --follow` class of hang (issue #5948) and what heuristics catch "this is a server, stop waiting." (4) How per-command sandbox wrapping survives a persistent shell (or doesn't). (5) The LRU cap (community-reported 64), reclaim, and what happens on eviction of a live session. (6) How this compares to a naive one-shot `exec()` per command and to a single persistent unsandboxable shell.
- **Leads**: the `openai/codex` source (`core/src/tools/unified_exec.rs` and the process/session store), Codex docs, GitHub issues (#5948 and related stuck-session reports), DeepWiki/community source reads. Source-verify file/crate names before asserting them; label buffering/LRU internals as community analysis where not in the source you read.

### B5-4 — Codex Cloud Container Execution *(Cluster D #21)*
- **Output**: `Harness-Internals-Codex-Cloud-Execution.md`
- **Parents (read in full first)**: [[Harness-Internals-Codex-Architecture]], [[Harness-Internals-MicroVM-Sandbox-Infrastructure]] (reference [[Harness-Internals-Durable-Execution]] for container caching/resume as a persistence problem)
- **Why**: Codex Cloud is the multi-tenant, best-of-N, egress-controlled execution platform behind the local agent — container caching/resume, phase-split network proxying, and fan-out scheduling are exactly the platform-engineering details the microVM chapter generalized but didn't pin to Codex.
- **Must answer**: (1) The container lifecycle — cold start, caching/warm reuse, and resume of a paused task. (2) Phase-split egress proxying — how network access is opened during setup and closed during the agent phase (the "setup can reach the internet, the agent can't" model) and why. (3) Best-of-N fan-out — how N parallel attempts are scheduled, isolated, and reconciled, and the cost model. (4) How the local↔cloud handoff works (what state transfers, how the same task runs both places). (5) Multi-tenant isolation and reclaim (cross-link the microVM chapter). (6) Failure modes: cache poisoning, egress-policy bypass, straggler tasks in a best-of-N batch.
- **Leads**: OpenAI Codex Cloud / Codex platform docs, the Codex cloud announcement + engineering posts, `openai/codex` cloud-related source and docs, egress-proxy/network-policy writeups, best-of-N discussion. Distinguish verified platform docs from inference about internal scheduling.

### B5-5 — execpolicy and Semantic Command Analysis *(Cluster D #22)*
- **Output**: `Harness-Internals-Codex-Execpolicy.md`
- **Parents (read in full first)**: [[Harness-Internals-Codex-Architecture]], [[Harness-Internals-Guardrails-Sandboxing]] (reference [[Harness-Internals-Sandbox-Kernel-Enforcement]] for the kernel layer below and cross-link B5-1 for the Claude Code contrast)
- **Why**: execpolicy is Codex's third enforcement layer — between "prompt" and "kernel" — that reasons about command *semantics* (which binary, which flags) the kernel can't see. It is where "block `git push --force`"-style rules live, and it is the direct architectural counterpart to Claude Code's AST-matching permission pipeline.
- **Must answer**: (1) How execpolicy statically classifies a proposed command — the parse, the trusted-command set, and the allow/deny/ask decision. (2) The rule language/format and how a rule expresses "this binary with these flags is safe." (3) Model-evaluated approval plug-ins — where an LLM judges a command the static policy can't classify, and the risk that introduces. (4) The trusted-command set — what's on it by default and the blast radius of a wrong entry. (5) How execpolicy composes with the kernel sandbox and unified-exec (cross-link B5-3) — three layers, who decides first. (6) execpolicy vs Claude Code's Bash-AST permission pipeline (cross-link B5-1) — declarative semantic classification vs AST rule-matching, compared honestly.
- **Leads**: the `openai/codex` `execpolicy` crate source + docs, Codex approval-mode docs, community teardowns of the trusted-command set, the model-evaluated-approval discussion. Source-verify crate/rule syntax before asserting; label undocumented internals as inference.

## Connections

- [[Harness-Internals-Research-Contract]] — the verbatim binding contract every agent reads first
- [[Harness-Internals-Explore-Next]] — full roadmap + unknown-unknowns; after batch 5 (recommended slate), 5 roadmap topics remain (D: 23–24, E: 25–26, F: 27) plus unbuilt U7–U15, U18–U20
- [[Production-Research-Chapter-Standard]] — the topic-agnostic reusable sibling of the contract
- Likely batch-6 shape: the reliability/protocol UU cash-out (U11 reward hacking + U12 cost-governance + U16 protocol standard) if not taken here, or the Cursor pair (#23 Edit-Prediction + #24 Verification-Sandboxes-LSP) folded with Clusters E (#25–26) and F (#27) into an "evaluation & frontier" batch. Decide from what batch 5 surfaces and how overdue the parked UUs feel.
