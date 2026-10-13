---
id: new-note-protocol
category: protocols
tags:
- protocol
- contract
aliases:
- New Note Protocol
related:
- document-template
- bootstrap-protocol
- project-md-template
version: 1.6
status: active
---

<!-- Vendored from documentation-onrails v1.4 (https://github.com/DaveR-ui/documentation-onrails).
     Contract and checks byte-identical in behaviour to upstream; only the reference links were
     re-pointed so they resolve inside this repo. -->

# New-Note Protocol

## Problem

The contract has ~20 individual requirements; "I'll remember them all" fails silently at exactly
the moment nobody checks.

## Solution

Run this list before declaring a new note done — this list *is* the check. Every item is
objective enough to automate someday; today, the walking is the point.

**Metadata**
- [ ] All 7 required keys present: `id`, `category`, `tags`, `aliases`, `related`, `version`, `status` — the note contract in [../../templates/document-template.md](../../templates/document-template.md).
- [ ] `id` is a slug, unique corpus-wide, ≈ filename stem; `category` equals the folder's final path segment.
- [ ] `status` ∈ {`draft`, `active`, `superseded`, `expired`} (`archived` notes live outside the served root).
- [ ] Optional keys (`supersedes`, `expires_at`, `moved_from`) either valid or *entirely absent* — never blank.

**Body**
- [ ] H1 title present (`no H1 title` warning), then the 7 sections verbatim and in order.
- [ ] "When not to use" and "Common mistakes" are real, not "N/A" filler.
- [ ] Language matches the corpus `doc_language`.

**Graph**
- [ ] Every `related` id resolves (the dangling-related-target check).
- [ ] Every `[[wikilink]]` stem/alias resolves, outside syntax citations — fenced or backticked (the dangling-link check).
- [ ] Note has ≥1 resolved non-self edge (the orphan-note check) — otherwise it is an island.
- [ ] Note is listed in its folder's hub via wikilink or markdown link (missing from its hub); a note in a hub-less folder like `templates/` or `docs/protocols/` is registered by a resolvable markdown link in root `README.md`.

**Hygiene**
- [ ] No secret-like tokens in prose or frontmatter (secret in prose); don't put secrets in the corpus at all.
- [ ] The generated index region of `index.md` lists the note (the stale-index check); follow every link in the note once — a dead end is a finding.

**Registration & validation**
- [ ] New file named lowercase kebab-case; `id` equals the filename stem.
- [ ] Registered in the same change: a row in the folder hub, or a markdown link in root `README.md` for a hub-less folder.
- [ ] From the repo root, `node validate.js` is green (check mode, strictly read-only; errors block); `node validate.js --write` refreshes the `index.md` / `tag-index.md` regions in existing files only.

## When to use

Every note creation or major edit, before the merge.

## When not to use

Repo-level docs under the context-doc contract (see
[guidelines/02 §4](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/02-document-contract.md)) — required
keys `last_updated`, `status`, `description`, `tags`, `version`; that covers the `README.md` and
`docs/project.md` entry points and everything under `docs/context/`. Still check links and language.

## Examples

Frontmatter for a new protocol, ready to copy:

```yaml
---
id: new-note-protocol
category: protocols
tags: [protocol, contract]
aliases: ["New Note Protocol"]
related: [bootstrap-protocol]
version: 1.0
status: active
---
```

Register and validate, from the repo root:

```sh
# add the file, then link it from its hub (or the README nav table when the folder is hub-less)
node validate.js
node validate.js --write   # only when the generated index regions are stale
```

## Common mistakes

- Checking the boxes by editing this protocol instead of the note.
- Adding `related` targets "that sound right" without verifying resolution — the next reviewer
  will, now or later.
- Leaving a frontmatter key blank instead of omitting it.

## References

- [../../templates/document-template.md](../../templates/document-template.md) — the contract itself.
- [guidelines/04-validation.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/04-validation.md) — the review catalog this mirrors.
- [bootstrap-protocol.md](bootstrap-protocol.md) — the corpus-level bootstrap this note-level check assumes.
- [documentation-onrails v1.4](https://github.com/DaveR-ui/documentation-onrails) — upstream source of this vendored protocol; contract and checks unchanged, only the reference links re-pointed.
