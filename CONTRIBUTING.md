# Contributing

You attended a talk. You took notes. Publishing them here means the people who could not get in still get the content. This page tells you exactly how.

Read it end to end before you start. The house style rules in section 3 are hard rules, not preferences.

## 1. What makes a good contribution

A good contribution is:

- A talk you actually attended, written from your own notes.
- Detailed enough that someone who was not there understands the argument, not just the topic.
- Honest about what you missed.

Not accepted:

- Summaries of a talk you watched a recording of and did not attend, unless you say so clearly in the Provenance section.
- Rewrites of the speaker's slide deck with nothing added.
- Anything generated from a title and a guess.

Short is fine. A 300 word note on one talk is a real contribution. Do not pad it to look substantial.

## 2. Step by step

### 2.1 Open an issue first, always

**Do not open a pull request before there is an issue for the event.** This is the one rule with no exceptions.

The reason: ten people attend the same meetup and each of them catches a different half of it. One person got the numbers off a slide, another remembers the name of the tool that got mumbled, a third asked a question in the hallway afterwards. Ten separate pull requests for one event cannot be merged into anything good. **One issue per event, collecting everyone's material, produces a far better note than any single attendee could write.**

How it works:

1. **Check whether an issue already exists** for the event. Search open issues for the meetup name.
2. **If it exists, comment on it.** Add whatever you have: your own notes, a correction, a photo of a slide, the answer to something already marked unresolved. Partial notes are welcome. You do not need to write a whole talk up.
3. **If it does not exist, open one.** Title it `Event: <Meetup name>, <City>, <Month Year>`. In the body put the event link, the talk list with speakers as far as you know them, and which talks you personally attended.
4. **Wait for the thread to settle.** Give other attendees a few days to add their side. This is the whole point of the step.
5. **Then someone opens the PR** consolidating the thread into notes. That can be you, another contributor, or Krrish. Say in the issue that you are picking it up so two people do not write it twice.

The same flow applies to an existing note. If you want to fix or extend one, open an issue against it, or comment on the event's original issue if it is still open.

### 2.2 Fork and branch

Only once the issue exists and you are the person writing it up.

1. Fork the repo on GitHub.
2. Clone your fork.
3. Branch: `git checkout -b blr-<short-event-name>`, for example `blr-software-architects`.

You can write in Obsidian ("Open folder as vault" on the cloned folder) or in any text editor. Obsidian is easier because wikilinks autocomplete.

### 2.2 Where the folder goes

Path shape:

```
01 - Events/<CITY>/<Event name> - <Organizer>/
```

- `<CITY>` is a three letter code. `BLR` for Bangalore, `DEL` for Delhi, `HYD` for Hyderabad. Create the folder if your city does not exist yet.
- The event folder is named for the meetup and its organizer, separated by ` - `. Existing example: `Software Architect - Devon Meetup`.

### 2.3 File naming

Inside the event folder:

- **One hub note**, named `<Event name> - Hub.md`. Example: `Software Architects Meetup - Hub.md`.
- **One note per talk**, numbered in running order: `NN <Short talk name> - <Speaker>.md`. Two digits, leading zero, space separated. Examples:

```
01 Six Architecture Decisions - Sachin Garg.md
02 Architecting for 1M+ RPS - Subal Bain.md
04 LLM as Judge - Arkadip Basu.md
```

Numbering follows the running order on the night, including talks that were cancelled (skip the number, and say what happened in the hub). The short name is yours to pick: keep it under about six words so the filename stays readable in the sidebar.

Images, slides and PDFs go in `08 - Attachments/`, not in the event folder.

### 2.4 Which template to start from

- **Hub note:** start from `09 - Templates/Event Hub Template.md`. In Obsidian use the Templates plugin (command palette, "Insert template"). The template is full of HTML comments explaining each section. Delete the comments before you commit.
- **Glossary entry:** start from `09 - Templates/Glossary Entry Template.md`. Add one for any jargon term you link that does not already have a note in `03 - Glossary/`.
- **Talk note:** start from `09 - Templates/Talk Note Template.md`. For a worked example of the finished result, read `01 - Events/BLR/Software Architect - Devon Meetup/04 LLM as Judge - Arkadip Basu.md`. The structure is:

```
---
event: "[[<Hub note name>]]"
speaker: <Speaker name>
title: "<Full talk title>"
---

# <Full talk title>

**In one line:** <the whole talk compressed to one or two sentences>

## <Your own section headings for the speaker's content>

## Unresolved

## My Take
```

Section headings in the body are yours to choose. Follow the shape of the talk. `Unresolved` and `My Take` are fixed and always last, in that order.

The hub's `Open Threads` section should collect the unresolved items from every talk note, so a reader sees all of them in one place.

### 2.5 Glossary entries

Every jargon term that a reader might not know gets a wikilink to `03 - Glossary/`, written as `[[NUMA]]`. If the entry does not exist, write it. One short note, a few sentences, plain definition. Do not link a term and leave a dead link.

### 2.6 Submit and credit everyone

Commit, push to your fork, open a pull request.

In the PR description: **link the issue** it came from (`Closes #12`) and say which talks you personally attended.

**Credit everyone whose material you used.** If you built the note from an issue thread, the people in that thread are co-authors, not sources. Two things to do:

1. Add a `Co-authored-by: Name <email>` trailer to the commit for each contributor. GitHub then shows them as authors on the commit.
2. List them in the note's `Provenance` section, saying who contributed what. "Talk 3 numbers from @someone, who was sitting closer to the screen" is a useful line.

If someone gave you a correction that changed the note, they get credit even if they wrote no prose. Catching an error is a contribution.

## 3. House style (hard rules)

These are not suggestions. A PR that breaks them gets sent back.

**No em dashes.** Not anywhere, in any file. Use a comma, a colon, a period or parentheses. If a sentence needs an em dash it is usually two sentences.

**Write plainly.** No warm-up sentences, no filler, no padding. Cut phrases that carry no information. Say the thing.

**Keep the speaker's content separate from yours.** Everything in the body is what the speaker said. Your opinion, your criticism, your recommendation to go see them again: all of it goes in `My Take` at the end and nowhere else. If you are correcting or extending the speaker with your own research, mark it as yours in a callout.

**One `My Take`, written by whoever opens the PR, and it must report disagreement.** The note keeps a single voice rather than stacking a section per attendee. But if people in the issue thread saw the talk differently, say so and name them: "@asha thought the v2 numbers were shaky, and having re-read my notes I think that is fair." Dropping a dissenting view because you did not share it is not allowed. Several people watching one talk and disagreeing is worth more to a reader than a clean consensus that was never real.

**Never guess.** If you could not catch a word, a name, a number or a claim, and you cannot verify it, put it under `Unresolved`. Write down what you actually heard, what you already ruled out, and your best guess if you have one, clearly labelled as a guess. Preserving an unidentified term exactly as you heard it is more useful than replacing it with a plausible invention. A wrong plausible term is worse than a blank, because nobody knows to check it.

**Bold the load-bearing claim in each paragraph.** One bolded phrase per paragraph, roughly. The point is that someone skimming the bold text alone should follow the argument. Do not bold whole paragraphs and do not bold for emphasis.

**Link jargon to the glossary.** See 2.5.

## 4. What the maintainer checks in review

Krrish reviews every PR against this list:

0. Is there an issue, and does the PR link it? A PR with no issue behind it gets closed with a request to open one. See 2.1.
1. Did you attend? Provenance section says how the note was made, and credits everyone who contributed to the issue thread.
2. Folder path, folder name and file names match section 2.
3. Frontmatter is present and correct on both hub and talk notes. No extra fields.
4. No em dashes.
5. Opinion is confined to `My Take`, and any disagreement in the issue thread is reported there rather than dropped.
6. Uncertain items are in `Unresolved` and not smoothed into confident sentences. This is the one that gets PRs sent back most often.
7. Bold is doing skim-navigation work, not decoration.
8. Wikilinks resolve. Every new glossary term has a note.
9. The hub's `Open Threads` collects the unresolved items from the talk notes.

Review is on the writing, not on you. Expect comments. Revising and re-pushing is normal.

## 5. Corrections to existing notes

Corrections are welcome on any note, including Krrish's.

**Resolving someone's Unresolved item is the most valuable correction there is** and is explicitly encouraged. If you were in the room and know what the misheard term was, or you checked the paper and can confirm the claim, say so.

**Start with an issue in every case.** Comment on the event's original issue if it is still open, otherwise open a new one naming the note. Then:

- **Small fix** (a name, a number, a broken link): the issue can be one line. Say what is wrong and what it should be. Krrish or anyone else can then push the fix, or you can open the PR yourself once the issue is up.
- **Resolving an Unresolved or Open Threads item:** say in the issue what the answer is and how you know, whether that is a link, a paper, or "I was at the talk and it was X". The PR then moves the item out of `Unresolved` into the body written as fact, and ticks the matching checkbox in the hub's `Open Threads`.
- **Not sure, but suspicious:** the issue is the whole contribution. Quote the line and say what looks wrong. Do not silently change something you cannot source. Flagging a doubt is useful on its own and you do not need to resolve it.

If a claim turns out to be wrong rather than just unverified, correct the body and note the correction in Provenance. The record of what changed matters.
