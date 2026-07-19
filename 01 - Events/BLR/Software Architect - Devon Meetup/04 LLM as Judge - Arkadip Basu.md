---
event: "[[Software Architects Meetup - Hub]]"
speaker: Arkadip Basu
title: "LLM as Judge: Removing Barriers in AI Evaluation"
---

# LLM as Judge: Removing Barriers in AI Evaluation

**In one line:** Manual evals do not scale and metric based evals do not measure what you care about, so we handed judging to LLMs. That works, provided you know the six ways they lie.

## Why legacy evals broke

The talk opened with the limits of what came before.

Manual review is **accurate and completely unscalable**. It is also slow enough that it stops functioning as a feedback loop.

Metrics based evaluation scales, but **measures surface similarity rather than quality**. BLEU and ROUGE will happily reward a fluent wrong answer that shares vocabulary with the reference.

The evolution he sketched:

```
Manual review  ->  Metrics based  ->  LLM as Judge  ->  Agent as Judge
                                      (now)             (next)
```

## The vocabulary

The evaluation strategies, which are the glossary you need before anything else makes sense:

| Strategy | What it does | Trade-off |
|---|---|---|
| Pointwise | Scores each response independently against criteria | Cheap and scalable, cannot capture relative quality |
| Pairwise | Compares two responses and picks the better | Best approximation of human preference, comparison count grows combinatorially |
| Listwise | Ranks a whole candidate set at once | Suits ranking and search style tasks |
| Reference based | Scores against a gold or ground truth answer | Reliable where ground truth exists, and often it does not |

## Making the judge reliable

Eval prompt engineering, the techniques that separate a usable judge from a random number generator:

- **Explicit rubrics.** State the criteria rather than asking "is this good?"
- **Chain of thought.** Make the judge reason before scoring. This is what [[G-Eval]] automates, generating a chain of thought that decomposes a criterion into structured evaluation steps.
- **Dimension decomposition.** Split a vague criterion like "fluency" into grammar, engagingness and readability, score each separately, then merge. Sometimes called Branch-Solve-Merge.
- **Structured output.** Constrain the judge to fill a predefined JSON schema rather than writing prose.
- **Calibration examples.** Few shot anchors that show the judge what a 2 and a 5 actually look like.

## The known biases

The most useful section of the talk. **These are not speculation.** They are measured and published, primarily in Zheng et al. 2023, "Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena" (arXiv:2306.05685), which found GPT-4 agreeing with humans about **85% of the time** against 81% human to human agreement. Good, but with systematic failure modes.

| Bias | What goes wrong |
|---|---|
| [[Position Bias]] | The judge favours whichever response came first or second, regardless of content |
| [[Verbosity Bias]] | Longer answers score higher independent of quality. Repetitive list attacks fooled GPT-3.5 and Claude around 91% of the time, GPT-4 only 8.7% |
| [[Self-Enhancement Bias]] | A model prefers its own outputs. Reported at +10% for GPT-4 and +25% for Claude |
| [[Style Bias]] | Markdown, structure and formatting get rewarded as if they were substance |
| [[Sycophancy Bias]] | The judge agrees with the stance it thinks you hold rather than judging on merit |
| [[Bandwagon Bias]] | Answers matching majority opinion score higher, even when the majority is wrong. Especially dangerous in technical domains |

> [!note] Note on my capture
> I wrote these down live as "Positive, Verbosity, Self-enhancement, Style, Scyphancy, Bandwagon Knowledge". The canonical names are above. "Positive" was position bias and "Scyphancy" was sycophancy. Further biases documented in the same literature but not covered in the talk: order, compassion fade, egocentric, salience and attentional bias.

## Agent as Judge

The forward looking section: extending judging from the final output to the entire task solving trajectory. **Rather than grading the answer, you grade the work.**

The steps he laid out:

1. **Trajectory analyser**, examine the full sequence of actions rather than just the result
2. **Subgoal validator**, check whether intermediate objectives were actually met
3. **Evidence gatherer**, collect supporting evidence from the trajectory
4. **Rubric interpreter**, apply the scoring criteria against that evidence
5. **Meta evaluator**, evaluate the quality of the evaluation itself

> [!info] The paper
> Zhuge et al., "Agent-as-a-Judge: Evaluate Agents with Agents" (arXiv:2410.10934, 2024). Evaluates agents on their whole trajectory rather than final output, benchmarked on DevAI, a set of 365 hierarchical developer agent requirements. Code at [metauto-ai/agent-as-a-judge](https://github.com/metauto-ai/agent-as-a-judge).

## Limits

LLM as Judge is **token expensive**, which is the practical constraint on running it continuously. His mitigation is to constrain output to JSON with predefined fields the model fills, rather than letting it write prose that then has to be summarised.

His closing point, which he was firm about, is that **this does not remove humans from evaluation**. You still need domain experts, and you need them precisely where domain specialisation is the thing being judged. The judge scales the volume. It does not replace the expertise.

## Unresolved

> [!warning] Needs verification
> The five Agent as Judge steps above are as I captured them from the slides. I have not verified these exact module names against the primary text of the Zhuge et al. paper. The abstract and repo describe evidence gathering and hierarchical requirement checking in general terms without naming these five verbatim. The mapping is plausible but should be checked against the PDF before being cited as the paper's own terminology.

## My Take

This talk was really good. I was not able to capture everything. The speaker had a lot to say and was moving quickly through material that deserved more room.

Because of the time constraint we could not hear him out fully, and honestly I would have sat through a full day session on just this topic. That is how good it was. **The bias catalogue alone changes how you would design an eval pipeline**, and he covered it in what felt like five minutes.

If he speaks again, go.
