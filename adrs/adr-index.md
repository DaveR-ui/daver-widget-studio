---
id: adr-index
category: adrs
tags: [hub, adr, index, navigation]
aliases: ["ADR Index"]
related: [adr-0001-adopt-widget-studio-structure, adr-0002-keep-widgets-as-independent-repos, adr-0003-validate-js-consumer-layout]
version: 1.0
status: active
---

# ADR Index

An **ADR** (architecture decision record) captures a structural or schema decision and the forces
behind it, for the reader who later asks *why*. The records here are **append-only**: never edit the
original text — corrections arrive as an addendum block, and reversals as a successor ADR carrying
`supersedes`. Naming is `adr-NNNN-<slug>.md`, the next free number, never reused. Each record carries
the note contract and the seven-section body defined by
[../templates/adr-template.md](../templates/adr-template.md).

## Decision records

| ADR | Decision |
|---|---|
| [adr-0001-adopt-widget-studio-structure](adr-0001-adopt-widget-studio-structure.md) | Adopt a docs-first widget-studio structure: a reference corpus plus one copyable skeleton, with the widgets staying independent repositories. |
| [adr-0002-keep-widgets-as-independent-repos](adr-0002-keep-widgets-as-independent-repos.md) | Keep each widget as its own repository, linked as a git submodule; no shared runtime core. |
| [adr-0003-validate-js-consumer-layout](adr-0003-validate-js-consumer-layout.md) | Ship a consumer-adapted `validate.js` and skip two non-corpus directories (`widgets`, `widget-skeleton`). |

## When not to use

An ADR is **not a changelog**: read it when you need the *why* behind a decision, not to see what
changed. Day-to-day changes are prose notes and protocols; only a structural or schema decision earns
a record, and a record is never edited to match later reality.

## Elsewhere

- The single human entry point — [../README.md](../README.md)
- The agent entry point and Slices table — [../docs/project.md](../docs/project.md)
- The corpus validator — [../validate.js](../validate.js)
- The copyable decision-record shape — [../templates/adr-template.md](../templates/adr-template.md)
