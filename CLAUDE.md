# CLAUDE.md

Entry file for this vault. Read fully before touching anything.

## What this is

A community knowledge vault run by Krrish. Bangalore runs several tech meetups on the same day and many are invite-only, so people miss a lot. Krrish attends, takes notes, researches the topics afterwards, and publishes the writeups so people who could not attend still get the substance.

Community first. Krrish maintains it, other attendees contribute and co-author. Docs and templates must be self-explanatory to a stranger, because strangers are the intended contributors.

Not a codebase. No build, no tests, no dependencies. The work is writing and editing markdown.

## MUST NOT

Hard constraints. Breaking any of these is a failure, not a judgment call.

1. **Never use an em dash.** Not in notes, not in filenames, not in chat replies to Krrish. Use commas, colons, periods or parentheses.
2. **Never use AI-tell phrasing.** Banned: "genuinely", "worth noting", "the kind of thing", "isn't X, it's Y" reversals, "not just X but Y", "Here's the thing", "delve", "leverage", "robust", "seamless", "crucial", "landscape", "realm", "testament to", "showcases", "underscores", "in the world of", "at its core", "dive into". Rhetorical triads for emphasis are out. Krrish rejected an entire batch of notes for reading as machine-written.
3. **Never write anything the source did not say.** See "The evening incident" below.
4. **Never resolve BLUG or BUOM by guessing.** See "Open questions" below.
5. **Never edit `02 - Deep Dives/`.** See the exemption below.
6. **Never commit or push without explicit permission.** Never add a `Co-Authored-By: Claude` trailer.

## How to verify

Run before claiming any writing task is done:

```bash
bash .claude/scripts/check-style.sh
```

It checks em dashes, banned phrasing, angle-bracket placeholders in headings, and unresolved wikilinks, with the right folders excluded. Must pass before you say a task is complete.

Note for anyone writing a new check: `grep -P "\x{2014}"` fails on this machine. Use a literal em dash.

## Structure

```
README.md · CONTRIBUTING.md · CLAUDE.md
.github/ISSUE_TEMPLATE/ · pull_request_template.md
.claude/scripts/check-style.sh

01 - Events/<CITY>/<Event name> - <Organizer>/
    <Event> - Hub.md
    01 <Talk> - <Speaker>.md      numbered by running order

02 - Deep Dives/<Topic>/          Krrish's personal research, one folder per topic
    <Topic>-Hub.md                or -Overview.md, the entry point
    <Topic>-<Subtopic>.md         hyphen-cased, topic-prefixed

03 - Glossary/                    one note per jargon term
08 - Attachments/
09 - Templates/                   wired to .obsidian/templates.json
```

**Events and deep dives are separate content types and never cross-link.** Deep dives are Krrish's own research, standalone, often unrelated to any event. Do not describe them as event follow-up and do not route event content into them.

**The glossary is the only shared connective tissue.** `[[NUMA]]` means the same thing from either half.

### 02 - Deep Dives is exempt from everything above

Those 53 notes predate this vault's house style. They contain about 5,800 em dashes, many banned phrases, and frontmatter carrying `type`, `date` and `tags`. **This is known and accepted.** Do not rewrite them, do not strip their frontmatter, do not report them as violations, and do not use one as a style reference.

The style rules apply to `01 - Events/`, `03 - Glossary/`, `09 - Templates/` and the root docs. Those are at zero violations today. Keep them there. New deep dives written from now on follow house style.

## Writing style and workflow

**`CONTRIBUTING.md` is the single source of truth.** Read it. Section 3 is house style, section 2 is the contribution workflow. Do not restate its rules here or paraphrase them back at contributors, because two copies drift apart.

The only things that live here and not there: the MUST NOT list above, the verification command, and the vault-specific facts below.

## Note anatomy

**Hub:** frontmatter (`event`, `organizer`, `city`, `link`), `> [!abstract]` "What this was", `## Key Takeaways` as the 60-second crunch, `## Talks` table, `## Open Threads`, `## Provenance`.

**Talk:** frontmatter (`event`, `speaker`, `title`), H1, `**In one line:**`, optional `> [!note]` capture caveat, body, `## Unresolved`, `## My Take` last.

**Glossary:** `term` frontmatter, H1, what it is, `**Why it matters:**`, `**Where it came up:**`, `**Source:**`. Around 60 to 100 words.

`Unresolved` is per talk. `Open Threads` on the hub aggregates them upward. Contributors only ever touch `Unresolved`.

**Frontmatter stays minimal in events and glossary.** Only the fields above. Krrish explicitly removed `type`, `date`, `tags`, `status`, `attendees` and `capture-confidence`. Do not reintroduce them. Deep-dive notes keep their own, per the exemption.

## Voice

Body is Krrish's active voice, mixing what the speaker said with what research filled in. Researched context goes in `> [!info]` callouts so it stays visibly separate from what was said in the room.

Opinion belongs only in `My Take`, and there is one per note written by whoever opens the PR. If the issue thread disagreed, the take must say so and name them.

**Do not launder personality out of Krrish's writing.** "It kind of blew my mind" and "props to him, it was his first talk" are why someone reads a community writeup instead of the slides. Enrichment adds a layer, it does not sand down the voice.

## The evening incident

Claude once wrote that a meetup was an evening event. The notes never said so. The meetup page later showed it ran at 11:00 AM. The invented detail survived into four files and read as confident fact.

Enrichment adds real value and it also adds a category of error the raw notes could never contain, because raw notes only hold what someone actually saw. **If the source did not say it, do not write it, even when it seems obviously true.**

When a term was captured phonetically and cannot be identified, keep it as written and put it under `Unresolved`. A wrong plausible term is worse than a blank, because nobody knows to check it. Never fabricate a URL, a paper or a citation. "Unresolved" is an acceptable answer and is often the useful one.

## Current state, check before touching

**Open questions, do not resolve by guessing.** "BLUG" (talk 1) and "BUOM" (talk 3) were captured phonetically at the Devon meetup and are listed in that hub's `Open Threads`. Both are acronyms. Plausible expansions exist for each and none are sourced. If you cannot source it, it stays in `Open Threads`.

**`08 - Attachments/software-architect-devon.png` is referenced by nothing.** Do not delete it, do not assume it is safe to embed. Ask Krrish what it is.

**`.remember/` exists at the repo root and inside `02 - Deep Dives/Harness-Engineering-Internals/`.** Agent tooling state, not vault content. Exclude from every sweep and every note count.

**`.obsidian/workspace.json` is tracked and rewrites itself on every vault open.** Expect it dirty, do not stage it. The rest of `.obsidian/` stays tracked so the Templates plugin works on clone.

**The event folder name does not follow its own rule.** The rule is `<Event name> - <Organizer>`. The hub frontmatter says `Software Architects Bangalore` and `Devon`, so the conforming name is `Software Architects Bangalore - Devon`. The actual folder is `Software Architect - Devon Meetup` and the hub file inside is a third variant. Copy the rule, not that folder. Ask before renaming, it is referenced from CONTRIBUTING and README.

**A large migration is staged and uncommitted:** `Deep Dive/` renamed to `02 - Deep Dives/`, plus the event folder and `.github/` as new adds. Expected. Leave it.

## Decisions already made, do not re-propose

- No date prefixes on event folders. Disambiguation is by organizer.
- A dense talk stays one note. Talks never graduate into deep dives.
- No events-to-deep-dives cross-linking.
- No `status` field and no Dataview maintainer queue.
- No quote-callout apparatus separating speaker claims from research in the body. Clean prose plus a separate `My Take`.
- No `00 - Start Here` folder. README and CONTRIBUTING live at the repo root so GitHub renders them.
- No per-attendee `My Take` sections. One merged take that reports disagreement.
- `CONTINUITY.md` was deleted as unnecessary. Do not recreate it. The hub's `Open Threads` does that job where readers look.

## Working here

Show work before scaling it. Improve one real artifact, get Krrish's sign-off, then extract the pattern. Templates get derived from finished notes, never invented upfront and imposed.

Do not write spec or design documents for this project. Krrish wants the output directly.
