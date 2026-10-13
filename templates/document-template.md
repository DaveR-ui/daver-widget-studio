---
id: document-template
category: templates
tags:
- template
- contract
aliases:
- Template
related:
- new-note-protocol
version: 1.5
status: active
# supersedes: <old-doc-id>   # optional: id of the note this replaces — omit entirely when unused
# expires_at: 2027-01-01     # optional: strict YYYY-MM-DD review date — omit entirely when unused
# moved_from: <old/path.md>  # optional: former path(s) after a move — omit entirely when unused
---

<!-- Vendored from documentation-onrails v1.4 (https://github.com/DaveR-ui/documentation-onrails).
     Contract and checks byte-identical in behaviour to upstream; only the reference links were
     re-pointed so they resolve inside this repo. -->

# Document Template

## Problem

A corpus without a fixed note shape degenerates into arbitrary structures, missing metadata, and
tools that cannot rely on any of it. Without a template, manual maintenance becomes the bottleneck.

## Solution

Copy this file for every new note. The frontmatter is the machine API (7 required keys;
`supersedes`/`expires_at`/`moved_from` optional, format-checked only when present, never
present-but-blank). The seven body sections give every note the same outline, so a reader always
knows where to look for the problem, the solution, and the boundaries. Body wikilinks use
filename stems (`[[payments]]`); `related` uses ids (`payments-flow`); choose destinations with
intention, not as filler.

## When to use

When creating ANY new note in the wiki layer. Without complete frontmatter and all seven
sections, the note is not part of the corpus.

## When not to use

For files outside the wiki layer (repo READMEs, configs, generated artifacts). Hubs may shorten
sections but must keep the complete frontmatter.

## Examples

```markdown
---
id: my-topic
category: architecture
tags:
- pattern
aliases:
- My Topic
related:
- payments-flow
version: 1.0
status: draft
---

# My Topic

## Problem
What concrete problem this note solves. One or two sentences.

## Solution
How it is solved, with the necessary technical detail.

## When to use
In what situations to apply this solution.

## When not to use
In what situations NOT to apply it.

## Examples
Code fragments or concrete scenarios.

## Common mistakes
Frequent pitfalls and misunderstandings.

## References
Sources and links to related notes (for example [[payments]]).
```

## Common mistakes

- Omitting a required key that has no value (keep it with an empty list).
- Renaming or translating section headings — breaks the outline parsing the whole system relies on.
- Leaving `related` disconnected from the body's wikilinks: both sources should agree so the
  graph and the metadata stay coherent.

## References

- [guidelines/09-bootstrap-workflow.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/09-bootstrap-workflow.md) — the contract instantiated: the inline micro-vault in its Solution.
- [docs/protocols/new-note-protocol.md](../docs/protocols/new-note-protocol.md) — the same contract as a protocol.
- [documentation-onrails v1.4](https://github.com/DaveR-ui/documentation-onrails) — upstream source of this vendored template; contract and checks unchanged, only the reference links re-pointed.
