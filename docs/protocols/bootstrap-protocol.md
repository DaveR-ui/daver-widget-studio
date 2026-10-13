---
id: bootstrap-protocol
category: protocols
tags:
- protocol
- bootstrap
aliases:
- Bootstrap Protocol
related:
- new-note-protocol
- document-template
- project-md-template
version: 1.6
status: active
---

<!-- Vendored from documentation-onrails v1.4 (https://github.com/DaveR-ui/documentation-onrails).
     Contract and checks byte-identical in behaviour to upstream; only the reference links were
     re-pointed so they resolve inside this repo. -->

# Corpus Bootstrap Protocol

## Problem

The first ten minutes of a new documentation repo decide whether it becomes a navigable corpus
or a pile. The mistakes made here compound into migration debt.

## Solution

Order matters: each step makes the next one checkable.

**Skeleton**
- [ ] Create root `README.md` — THE single entry point: what the studio is, how to navigate, the
      rules, the table of docs (`File | Purpose | When to read`).
- [ ] Declare `doc_language` once, in the README frontmatter, identical to the value in
      `docs/project.md`. No exceptions after that.
- [ ] Write `docs/project.md` — the agent-facing entry point (overview, stack, Slices table,
      commands, conventions) — from [../../templates/project-md-template.md](../../templates/project-md-template.md).
- [ ] Bring the schema layer in: copy [../../templates/document-template.md](../../templates/document-template.md)
      for every new note shape, and keep this protocol and [new-note-protocol.md](new-note-protocol.md) beside it.
- [ ] Create the content folders: `docs/context/` for strategic docs, `docs/protocols/` for
      procedures, `adrs/` for decision records. Create 2–4 topic folders *only when the first real
      note needs one* — no speculative tree. Each starts with its hub `<folder>-index.md`
      ([../../templates/hub-template.md](../../templates/hub-template.md)).

**Runbook**
- [ ] Follow the ordered agent runbook: [guidelines/09-bootstrap-workflow.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/09-bootstrap-workflow.md).

**Store guarantees**
- [ ] `index.md` and `tag-index.md` are generated: create the two files with their marker pairs by
      hand to start, then `node validate.js --write` fills both regions from the repo root —
      overview stats + tree + hub list, and the tag → docs inverted index.
- [ ] Generated aids (index regions, diagrams) are marked as generated and rebuildable — never
      hand-patched. A hand-edit is reported as `stale-generated-index` and overwritten by the next
      `--write`.

**Review discipline from day one**
- [ ] Adopt the review catalog (see [guidelines/04-validation.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/04-validation.md)) — walk it over your first notes; the two protocols are the mechanism, no tools required.
- [ ] Calibrate: walk it against the corpus *as it exists* and demand zero gaps — or write down, explicitly, what you tolerate (accepted debt).
- [ ] Make the walk a step of every merge the day it catches a real error you agree with.
- [ ] Walk the catalog with code where it exists: `node validate.js` from the repo root (check mode, strictly read-only; any error exits 1).

**Agent-readiness (skip only if this stays a human-only corpus for now)**
- [ ] Query path is read-only; sandbox rejects absolute paths / `..` / symlink escapes.
- [ ] Not-found semantics chosen (`null` / `[]`), documented next to the tool surface.
- [ ] Snapshot staleness visible (a footer date on generated files is the minimum).

## When to use

Starting any new documentation repo, or auditing an existing one that "grew naturally".

## When not to use

Mid-scale restructuring of a healthy corpus — there, walk the review catalog first and follow its
findings; this protocol is for when there is no catalog walk yet.

## Examples

This studio dogfoods the protocol: `README.md` as the single entry point, `docs/project.md` as the
agent entry point, `docs/context/` and `docs/protocols/` as the content folders, `adrs/` for
decisions, `templates/` as the schema layer, and the two generated indexes rebuilt from the repo
root:

```sh
node validate.js --write   # fill the index.md / tag-index.md regions (existing files only)
node validate.js           # check mode: errors block
```

## Common mistakes

- Bootstrapping the tooling before the content. One real note + hub beats an empty perfect repo.
- Skipping the calibration step: an unchecked catalog graduates from advisor to nuisance in a week.
- Writing two entry points ("see also START-HERE.md") — navigation dies by branching at the root.

## References

- [guidelines/01-structure.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/01-structure.md) — the layout being bootstrapped.
- [guidelines/04-validation.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/04-validation.md) — the catalog being adopted.
- [guidelines/09-bootstrap-workflow.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/09-bootstrap-workflow.md) — the runbook that sequences this protocol.
- [new-note-protocol.md](new-note-protocol.md) — the per-note check this bootstrap turns on from day one.
- [documentation-onrails v1.4](https://github.com/DaveR-ui/documentation-onrails) — upstream source of this vendored protocol; contract and checks unchanged, only the reference links re-pointed.
