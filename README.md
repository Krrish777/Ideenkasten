# Ideenkasten

Notes from tech events, written up properly so people who could not attend still get the substance.

## The problem

Bangalore runs several tech meetups on the same day. You pick one and lose the rest. Many of the good ones are invite-only or run a selection process, so attending is not even your decision. People miss a lot.

This vault is the workaround. Krrish attends events, takes notes during the talks, researches the material afterwards, and publishes the writeups here. The aim is that reading a note gets you close to what a room full of people got on the night.

It is community-first. Krrish maintains it, and other people are expected to add writeups from events they attended. See [CONTRIBUTING.md](CONTRIBUTING.md).

## How to read it

Start at an event hub note. Every event folder has one. The hub tells you what the event was, lists the key takeaways, and has a table of the talks with a line on each explaining whether that note is worth opening. Read the hub, then open the talk notes you care about.

Talk notes open with a one-line summary, then the speaker's content, then an `Unresolved` section, then `My Take` (the writer's own opinion, kept separate from the speaker's material).

## Folder numbers

The numbers keep the sidebar in a fixed order. They are not a reading sequence.

- `01 - Events/` writeups, organised as city code, then event folder, then one hub note plus numbered talk notes. Example: `01 - Events/BLR/Software Architect - Devon Meetup/`.
- `02 - Deep Dives/` Krrish's own research. Standalone, not tied to any event.
- `03 - Glossary/` one short note per jargon term. Events and deep dives both link into it. It is the only thing connecting the two halves.
- `08 - Attachments/` images, slides, PDFs.
- `09 - Templates/` Obsidian templates, wired to the Templates core plugin.

## Opening it in Obsidian

Clone the repo, then in Obsidian pick "Open folder as vault" and select the cloned folder. The `.obsidian` config is committed, so the Templates plugin and the template folder are already set up. Wikilinks and the graph view only work inside Obsidian. On GitHub the notes are still readable, but `[[links]]` will not resolve.

## Honesty about accuracy

These notes are taken live and enriched afterwards from primary sources. Talks move faster than a pen. Where the capture was thin, gaps are filled from research and that is stated in the note.

Anything that could not be caught or could not be verified is listed under `Unresolved` in the talk note and `Open Threads` in the hub. It is never smoothed over into a confident sentence. If you were in the room and can resolve one of those items, open an issue or a pull request.
