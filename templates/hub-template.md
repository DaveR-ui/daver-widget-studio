---
id: hub-template
category: templates
tags:
- template
- hub
- navigation
aliases:
- Hub Template
related:
- document-template
version: 1.2
status: active
---

<!-- Vendored from documentation-onrails v1.4 (https://github.com/DaveR-ui/documentation-onrails).
     Contract and checks byte-identical in behaviour to upstream; only the reference links were
     re-pointed so they resolve inside this repo. -->

# Hub Template

## Problem

A folder without a gatekeeper is a pile: readers enter blind, and a note that no hub lists is
unreachable through `entry → hub → note` — invisible content, an error at review (the
missing-from-hub check).

## Solution

Every topic folder gets exactly one hub, named `<folder>-index.md`. Its body has three duties and
nothing else: **what belongs here** (the folder's scope, one or two lines), **what is in here** (a
linked list of every note in the folder — the registration that keeps each one reachable), and
**what belongs elsewhere and why** (the boundary that stops the folder from absorbing drift). A
hub routes and catalogs; it never restates note content.

## When to use

When creating any new folder in the wiki layer — the hub is born with the folder, before its
second note. Also as the review reference when a missing-from-hub finding appears.

## When not to use

Not for the root entry point (README is unique — a second "start here" is a maze); not for
hub-less schema folders (`templates/`, `protocols/`), whose files register in the entry point's
navigation table instead; never as a content page — duplication makes the hub a rival truth.

## Examples

```markdown
---
id: payments-index
category: payments
tags:
- hub
- index
aliases:
- Payments Index
related:
- payments-flow
version: 1.0
status: active
---

# Payments Index

What belongs here: how money is captured — authorization, settlement, failure handling.
Anything about *returning* money belongs in `refunds/` — different lifecycle, different owner.

## Contents
- [[payments]] (`payments-flow`) — how a charge is created, then settles or fails.

## Elsewhere
- Refund handling → `refunds/refunds-index.md`
- Dispute/chargeback policy → `disputes/disputes-index.md`
```

Hubs keep the **complete 7-key frontmatter** but may shorten the body — the three duties above
are the whole job; the verbatim note sections are optional here.

## Common mistakes

- A hub that duplicates note content — routing and cataloging only; duplication is a warning
  (the near-duplicate-body check) and future drift.
- Adding a note without adding its hub row in the same commit — the gap-close loop of
  [guidelines/08-brownfield.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/08-brownfield.md) closes only when note, hub row,
  and tag entry have all landed.
- A hub reading like a phone book: past ~30 notes, split the folder — a hub that doesn't route
  is decoration.

## References

- [guidelines/01-structure.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/01-structure.md) — the hub rule and folder anatomy.
- [guidelines/04-validation.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/04-validation.md) — the missing-from-hub check.
- [document-template.md](document-template.md) — the note shape the hub routes to.
- [documentation-onrails v1.4](https://github.com/DaveR-ui/documentation-onrails) — upstream source of this vendored template; contract and checks unchanged, only the reference links re-pointed.
