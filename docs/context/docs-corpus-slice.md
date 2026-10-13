---
last_updated: 2026-10-12
status: active
description: Slice generalities for the studio's own documentation corpus — the entry points, hubs, generated indexes, validator, vendored schema layer, protocols and ADRs.
tags: [slice, generality]
version: 1.0
related: [context-index]
---

# Documentation Corpus — Slice Generalities

## What this slice is

The studio documenting itself: `README.md` and `docs/project.md` as the two entry points, the
`docs/context/` reference tree behind its `context-index` hub, the `docs/protocols/` procedures, the
append-only `adrs/` behind their own hub, the vendored schema layer under `templates/`, and the
zero-dependency `validate.js` that renders `index.md` and `tag-index.md`.

## Boundaries (IN/OUT)

- **IN** — the corpus's own documents, frontmatter contracts, hubs, generated regions, the validator, the adopt/adapt decision records.
- **OUT** — every widget's code and every widget's *own* docs corpus; anything under `widgets/`.

## Entry points

- `README.md` — the single human entry point and the navigation table for hub-less folders.
- `docs/project.md` — the agent entry point and the Slices routing table.
- `docs/context/` — the strategic docs, routed by `docs/context/context-index.md`.
- `docs/protocols/`, `adrs/`, `templates/` — procedures, decisions, copyable shapes.
- `validate.js`, `index.md`, `tag-index.md` — the gate and its two generated artifacts.

## How it works

- `validate.js` walks every `.md` outside the skip list, parses a YAML-subset frontmatter, and classifies each file as context-entry, context-doc, hub, adr, template, protocol or note.
- It then checks metadata contracts per class, duplicate ids, kebab-case names, dangling `related` targets and links, orphans, hub membership, generated-region freshness and secret patterns, and warns on missing H1s, folder/category mismatches and near-duplicate bodies.
- `node validate.js` is strictly read-only; `node validate.js --write` regenerates the two marker-delimited regions write-if-diff and then checks.
- A hub (`*-index.md`) registers its whole folder; a folder without a hub registers its members through the root README navigation table instead.

## Conventions of this slice

- Two frontmatter families: **context-doc** (`last_updated`, `status`, `description`, `tags`, `version`) and **note** (`id`, `category`, `tags`, `aliases`, `related`, `version`, `status`).
- Slice maps keep the context-doc family with membership on `tags: [slice, generality]` — the adopted deviation recorded in the corpus ADR.
- Generated regions are rebuilt, never hand-edited; `related` uses ids, body links use stems.
- Upstream guidelines are referenced by URL; only the schema layer is vendored.

## Dependencies

- Upstream: `documentation-onrails` v1.4 (referenced by URL) and Node.js.
- Downstream: every human and agent reader of this studio.

## Known gaps & accepted debt

- The reference generalities are distilled from the author's two widgets only; a third widget is expected to contradict or extend them.
- `validate.js` is a consumer-adapted copy of the upstream validator; where it and the upstream prose disagree, the prose wins.
- `widgets/` and `templates/widget-skeleton/` are skipped by the scan, so their `README.md` files are outside the corpus contract.
