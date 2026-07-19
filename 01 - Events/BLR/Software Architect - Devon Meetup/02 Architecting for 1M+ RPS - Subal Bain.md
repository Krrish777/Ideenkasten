---
event: "[[Software Architects Meetup - Hub]]"
speaker: Subal Bain
title: "Architecting Systems for 1M+ Requests Per Second: Patterns for Extreme Scale"
---

# Architecting Systems for 1M+ Requests Per Second

**In one line:** Scaling is not a pattern you pick. It is a loop you run: measure, find the real bottleneck, fix that one thing, measure again.

## The agenda he set out

The talk walked up the scaling ladder, from finding problems to fixing them to proving they are fixed:

- find the bottleneck instead of guessing
- application level optimisation
- database scaling strategies
- caching
- monitoring
- benchmarking
- how it all fits together in a real product

## What to actually measure

The first substantive point, and the one that matters most, is that **you cannot optimise what you have not measured**, and most teams guess. The baseline metrics he put in front of the room:

- requests per second
- response latency
- CPU usage
- memory usage
- database activity
- benchmark results

This is deliberately unglamorous. The argument is that **the bottleneck is almost never where your intuition says it is**, and instrumentation is the only way to find out.

## The loop

The core of the talk, reduced to a repeatable process:

1. Measure what is actually going on.
2. Identify the bottleneck and optimise that specific thing.
3. Measure again to confirm the fix moved the number you cared about.
4. Use all available resources. Do not leave cores or connections idle.
5. Parallelise where the work allows it, for example with multi threading.
6. Do not waste anything.

**Step 3 is the one people skip**, and skipping it is how teams accumulate optimisations that never helped.

## The toolkit

The standard levers for getting from thousands to hundreds of thousands of requests per second:

- **Horizontal scaling**, add instances rather than growing one
- **Indexing**, the biggest database win and the most commonly missed
- **Connection pooling**, stop paying connection setup cost on every request
- **Read/write splitting**, route reads to replicas and keep the primary for writes

## Unresolved

The staged progression he presented, the specific sequence for taking a system from zero to a hundred thousand requests per second, was hard to follow as delivered and **I am not confident I captured the ordering correctly**. I have left it out rather than invent a sequence he did not give.

## My Take

The slides looked AI generated, and it read like the speaker was underprepared. But I believe this was **his first time speaking**, and he presented to a room of 50 to 60 people, so props to him. That is not an easy first outing.

The talk was okay overall. I would not call it next level, and I was expecting more depth than I got. The content is correct and it works as a checklist, but if you have done any scaling work before there was not much here you did not already know. **The measure, optimise, measure loop is the part worth keeping.**
