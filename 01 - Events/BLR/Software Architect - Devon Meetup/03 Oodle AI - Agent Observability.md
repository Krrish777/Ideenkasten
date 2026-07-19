---
event: "[[Software Architects Meetup - Hub]]"
speaker: Oodle AI (founder)
title: "Cutting Token Costs in Agent Observability"
---

# Oodle AI: Cutting Token Costs in Agent Observability

**In one line:** A four stage architecture evolution for letting an LLM analyse production logs without blowing its context window, and a case study in building a good system by fixing one flaw at a time.

> [!note] About this talk
> This was an unscheduled replacement. The original slot, "Spend Less, Ship More: Cutting Token Costs in Coding Agents" by Vinit Kumar Goel, was cancelled when the speaker could not reach the venue, and this went on in its place. It ended up being the most technically detailed session of the day.
>
> **The v0 to v3 walkthrough below was presented for this event only and has not been published anywhere.** It is not in Oodle's blog or documentation. This writeup is my capture of the live talk, so treat it as an attendee account rather than an official one.

## What Oodle is

An agent observability platform. The pitch is that **an AI cannot debug what it cannot see**, so Oodle stores every log, trace and metric on object storage and makes it instantly queryable with serverless compute.

The architectural bet is **decoupling storage from compute**. Telemetry lands on S3 compatible object storage, which is cheap and elastically sized rather than provisioned in advance. Queries then spin up serverless compute per request instead of paying for always on indexing clusters. That is what makes the cost story work, and they position against Datadog and Grafana at a fraction of the price.

For scale context from their public material: their largest deployment handles **20TB+ per day** of logs, 100M+ metrics per hour and 4M+ agent traces per day at sub second P99. They have raised around **$5.5M** from Engineering Capital, Pear VC and SNR VC.

## The architecture evolution

The heart of the talk. Rather than presenting a finished architecture, the founder walked through how they got there: **four versions, each fixing the previous one's specific failure**.

| Version | Technique | What it fixed | What it broke |
|---|---|---|---|
| **v0** | Dump raw logs into the LLM | Nothing, it was the naive baseline | Context window overflow, immediately |
| **v1** | Fingerprint and compact heuristically | Token cost dropped hard | Lossy compaction, distinct errors got merged |
| **v2** | Expanded toolset and query aggregation | Aggregation became lossless, accuracy up | Token consumption climbed again |
| **v3** | File backed tools, metadata to the LLM | Both cost and accuracy | Current production version |

### v0, dump everything

The first version did the obvious thing: read the logs into a file and hand the whole thing to the LLM. **This fails immediately and predictably.** The context window is finite, and the system prompt already eats part of it. Not a surprise, but a necessary starting point.

### v1, fingerprinting

The fix was **log fingerprinting**: parse logs into templates that separate static text from variable parts, then collapse repeated patterns.

His worked example was hitting many different endpoints where each produces its own error line. Fingerprinting recognises the shared shape and compacts them into a single templated entry with the varying part replaced by a wildcard.

My analogy at the time was `SELECT * FROM table`, saying "all of these" rather than enumerating them. That is roughly right for the compaction, though the wildcard stands in for the variable field rather than the columns.

The gain was a large token cost reduction. The cost was **lossy compaction**. If `/check` and `/verify` fail for different underlying reasons, collapsing them into one template destroys the distinction that mattered for debugging.

> [!info] The technique has a name and a paper
> This is [[Drain Algorithm|Drain]], a streaming tree based log parser from He, Zhu, Zheng and Lyu (ICWS 2017), productionised by IBM as Drain3. It is the standard approach to log templating and part of the [LogPai logparser](https://github.com/logpai/logparser) toolkit. **Oodle arrived at the same shape independently**, which is a decent signal it is the right shape.

### v2, tools and aggregation

v2 extended the toolset and added **query aggregation**, making the aggregation step lossless rather than heuristic. Accuracy went up meaningfully and the v1 lossy compaction problem was solved.

The trade was that token consumption rose again. He showed two tables comparing tool calls against token counts across the versions, illustrating the tension: **the more faithful the data, the more of it the model has to read**.

### v3, file backed tools

The current production architecture, and the interesting one.

Instead of tool results flowing back into the model's context, **tools execute deterministically and write their output to local files**. The LLM receives only metadata about what was written. It then progressively discovers what is relevant, requesting more only when it needs it. Tools also write query friendly files to make later search cheaper.

The result is **lower token cost with accuracy preserved**. The data is never destroyed by compaction, it is just not all in context at once.

> [!info] This is a recognised pattern
> Oodle got here independently, but the industry converged on the same idea.
>
> Anthropic's "Code execution with MCP" has agents call tools as code APIs and keep intermediate results in the execution environment rather than the context window. Their worked example goes from around 150,000 tokens to around 2,000, a **98.7% reduction**.
>
> Manus's "Context Engineering for AI Agents" describes "File System as Context", using the filesystem as unlimited external memory and re-accessing via glob and grep. They call it **recoverable compression**, which is exactly the property v1 lacked and v3 has.

## Business notes

He mentioned partnering with Cult.fit. This is confirmed in their public material as a design partner, with a cited **3x cost drop within six hours** of migrating off Grafana.

## Unresolved

> [!warning] Unidentified
> - **"BUOM", named during the talk, is still unidentified.** It is likely an **acronym** rather than a product name.
>
>   Best hypothesis: **BYOC**, meaning Bring Your Own Cloud. This is Oodle's own product vocabulary rather than generic jargon. They publish three deployment models: SaaS, BYOB (Bring Your Own Bucket, your S3 and your encryption) and [BYOC](https://www.oodle.ai/product/byoc) (the full stack in your VPC with your KMS keys and no egress). Spoken as letters it has the same shape as what I wrote down, and it came up next to the Cult.fit partnership, which is exactly where deployment topology gets discussed. Unconfirmed. If you were there, please open an issue.
> - There was a point about "a problem in computer science" alongside the v2 tables that I could not write down in time.

## My Take

This talk was unexpected but it kind of blew my mind, purely because of how much I got out of it.

What I liked was how the founder broke everything down from basic to advanced, **not presenting the finished thing but walking the path**. Most architecture talks show you v3 and let you assume it was designed that way.

The takeaway that will stick with me is not about logs at all. It is that this is how software engineering actually works. You pick one problem or one cost you are facing, improve that specific thing, and **accept that your fix will expose the next problem**. Then you layer on top of it. v1 fixed cost and broke accuracy. v2 fixed accuracy and cost tokens. v3 fixed both. Each step required looking honestly at what the last step broke.

That is a planning lesson more than a technical one, and it is the thing I took home.
