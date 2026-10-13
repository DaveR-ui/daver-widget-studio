---
id: adr-0003-validate-js-consumer-layout
category: adrs
tags: [adr, validation, tooling, consumer-layout]
aliases: ["ADR-0003"]
related: [adr-index, adr-0001-adopt-widget-studio-structure, adr-0002-keep-widgets-as-independent-repos, docs-corpus-slice]
version: 1.0
status: active
---

# ADR-0003: Adapt validate.js to the consumer layout and skip two non-corpus directories

## Problem

The upstream `validate.js` is written for the methodology repository itself: its `classify()` maps
root `guidelines/`, `templates/`, `protocols/` and `adrs/`, and its `collectMarkdown()` walks every
`.md` under the root. Run in a consumer tree it misclassifies every file. This studio is a consumer
with **two properties tuya's consumer did not have**: `widgets/` holds **git submodule working
trees**, each with its own whole documentation corpus, and `templates/widget-skeleton/` holds a
copyable KPackage whose `README.md` is a **code asset**, not a note.

## Solution

Ship a locally adapted copy of the upstream validator. Exactly three **consumer adaptations**, plus
**this studio's two extra names** on the skip list:

1. `collectMarkdown()` skips dot-directories (`.git`, `.venv`, `.pytest_cache`, …) and common
   build/vendor directories.
2. `classify()` maps the consumer layout onto the same doc classes: `docs/project.md` →
   context-entry; `docs/` and `docs/context/` → context-doc; `docs/protocols/` → protocol; `adrs/` →
   adr. The class → contract mapping is untouched.
3. `checkCategory()` compares `category` against the **folder's final path segment**, so the nested
   `docs/protocols/` folder still matches `category: protocols`.
4. **This studio's two extra skip names — `widgets` and `widget-skeleton`** — added for the same
   non-weakening reason as (1). The invariant that makes them safe: they are **not corpus content**,
   so skipping them cannot hide a finding about the corpus (`widgets/` is submodule working trees,
   `templates/widget-skeleton/` is a code asset that would otherwise trip the kebab-case rule).

No check, severity, renderer or output format was changed. The normative upstream lives in
[documentation-onrails](https://github.com/DaveR-ui/documentation-onrails)
`guidelines/04-validation.md`; the guidelines were deliberately **not vendored** — a second copy
would be exactly the second-source-of-truth anti-pattern this studio documents.

## When to use

When updating the validator, or when a reviewer asks why the local copy differs from the upstream
reference.

## When not to use

Do not extend the adaptation to weaken or remove a check: any behavioural change beyond the path
mapping above needs its own ADR — the same rule tuya's `adr-0002-validate-js-consumer-layout` states.

## Examples

- `node validate.js` from the repo root — strictly read-only; exits 1 on errors.
- `node validate.js --write` — regenerates the `index.md` / `tag-index.md` regions in place
  (write-if-diff; never creates a missing file).
- The two skipped directories: `widgets/` (submodule checkouts) and `templates/widget-skeleton/`
  (the copyable KPackage).

## Common mistakes

- Replacing the adapted copy wholesale with the upstream file — reintroduces the misclassification
  and scans the submodule markdown.
- Running `--write` casually: it only rewrites marker regions in **existing** files, but it is the
  generator, so treat it as an intentional write.
- Hand-editing inside a `<!-- BEGIN GENERATED: … -->` / `<!-- END GENERATED: … -->` pair — the next
  `--write` overwrites it.

## References

- [adr-0001-adopt-widget-studio-structure.md](adr-0001-adopt-widget-studio-structure.md) — the
  consumer layout being classified.
- [adr-0002-keep-widgets-as-independent-repos.md](adr-0002-keep-widgets-as-independent-repos.md) —
  why `widgets/` exists and why it is skipped.
- [adr-index.md](adr-index.md) — the hub this record is registered in.
- [../validate.js](../validate.js) — the adapted copy, whose header documents the same list.
- [../docs/protocols/bootstrap-protocol.md](../docs/protocols/bootstrap-protocol.md) — the
  corpus-level protocol that runs the validator.
- [documentation-onrails — guidelines/04-validation.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/04-validation.md)
  — the normative catalog.
