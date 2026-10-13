---
id: slice-generalities-template
category: templates
tags:
- template
- slice
- brownfield
aliases:
- Slice Generalities Template
related:
- hub-template
- project-md-template
version: 1.1
status: active
---

<!-- Vendored from documentation-onrails v1.4 (https://github.com/DaveR-ui/documentation-onrails).
     Contract and checks byte-identical in behaviour to upstream; only the reference links were
     re-pointed so they resolve inside this repo. -->

# Slice Generalities Template

## Problem

A brownfield repo documented per file drowns in volume and rots at the first refactor, and docs
that never answer *"where does my task land?"* get ignored by every reader, human or machine. The
first artifact worth making is the territory map — one generalities doc per slice.

## Solution

Copy the fenced shape below: exactly one generalities doc per slice, answering what the slice is,
where its boundaries are, which paths a reader starts from, and what is honestly unwritten.
Slice membership is metadata, not a key: it rides on `category` and `tags` — there is **no**
`slice:` frontmatter key, and inventing keys is a metadata-outside-contract error (see
[guidelines/04-validation.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/04-validation.md)).

## When to use

Brownfield Step 1 ([guidelines/08-brownfield.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/08-brownfield.md)): every slice
row in the Slices table gets one of these, before anything else — the slices are the hubs of the
retrofit and the routing unit of the query loop.

## When not to use

Greenfield corpora (notes + hubs suffice); per-file documentation (a map at 1:1 scale is
impossible to keep fresh); walkthroughs and tutorials — a different document type, linked *from*
the generalities, never replacing them.

## Examples

```markdown
---
id: <name>-slice
category: <topic-folder>
tags:
- slice
- generality
aliases:
- <Name> slice
related:
- <name>-index
version: 1.0
status: active
---
# <Name> — Slice Generalities
## What this slice is        ← purpose, form ("files ARE the store" style)
## Boundaries                ← explicitly IN and OUT; what belongs elsewhere and where
## Entry points              ← paths a reader starts from; the next read is determined, not guessed
## How it works              ← generalities: main flows, data shape, state ownership — high level
## Conventions of this slice ← the rules that hold *here* (may differ corpus-wide)
## Dependencies              ← upstream (what this needs) / downstream (what breaks)
## Known gaps & accepted debt ← honest "this is broken/unwritten" — feeds the accepted-debt list
```

## Common mistakes

- Inventing frontmatter keys (`slice: <name>`, `description:` on a note) instead of expressing
  membership through the contract's `category` and `tags`.
- Writing a walkthrough: the doc is the map — what, where, boundaries, gaps — not a sequence of
  steps through the code.
- Skipping "Known gaps & accepted debt": documented incompleteness beats silent staleness, and
  the section is what the review pass (08 Step 5) calibrates against.
- One doc per file, or thirty slices: routing scales with areas (2–7), not with file count.

## References

- [guidelines/08-brownfield.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/08-brownfield.md) — Step 1, the load-bearing move this shape serves.
- [guidelines/06-project-md.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/06-project-md.md) — the Slices table each doc is registered in.
- [hub-template.md](hub-template.md) — the folder-hub role the slices mirror for code.
- [documentation-onrails v1.4](https://github.com/DaveR-ui/documentation-onrails) — upstream source of this vendored template; contract and checks unchanged, only the reference links re-pointed.
