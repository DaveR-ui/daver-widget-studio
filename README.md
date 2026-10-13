---
last_updated: 2026-10-12
status: active
description: Single human entry point for daver-widget-studio — a docs-first widget studio that merges the authoring lore of KDE Plasma 6 widgets into one reference corpus and one copyable KPackage skeleton.
tags: [entry-point, index, navigation, studio]
version: 1.0
doc_language: en
related: [project-overview]
---

# daver-widget-studio

This is a **docs-first widget studio** for KDE Plasma 6 widgets written by one author.
It is **not** a code-generation monorepo and it is **not** a shared runtime: it merges the
authoring knowledge of the author's widgets into **one reference documentation corpus** and
**one copyable KPackage skeleton**. Every widget stays its own repository with its own code,
dependencies, build and CI, and is linked here as a git submodule under `widgets/`.
The reuse scope is deliberately narrow — **lore + skeleton only**, with **no shared runtime core**.

The studio is public: the authoring reference itself is a product, not private scaffolding.

## What lives here

| Entry | What it is |
|---|---|
| `README.md` | This file — the single human entry point. |
| `docs/project.md` | The agent entry point: overview, stack, the Slices routing table, commands, conventions, entities and lookups. |
| `docs/context/` | Strategic, one-topic reference docs, behind the `context-index` hub. |
| `docs/protocols/` | Step-by-step studio procedures (bootstrap, new note, new widget, merge docs, release). |
| `adrs/` | Append-only architecture decision records, behind the `adr-index` hub. |
| `templates/` | The vendored `documentation-onrails` schema layer — copyable shapes — plus the widget skeleton under `templates/widget-skeleton/`. |
| `tools/` | The scaffolding tool that copies the KPackage skeleton. |
| `widgets/` | The widget git submodules — independent repos, never absorbed. |
| `validate.js` | Zero-dependency corpus validator and generated-index renderer. |
| `index.md` | Generated tree and stats of the corpus. |
| `tag-index.md` | Generated tag → docs surface. |

## How to navigate this corpus

**Start with [`docs/project.md`](docs/project.md)** — the canonical agent-facing entry point
(overview, stack, the Slices routing table, commands, conventions and common lookups). This
README is the single human entry point; there is no second "start here".

| File | Purpose | When to read |
|---|---|---|
| [docs/project.md](docs/project.md) | Canonical agent entry point: overview, technology stack, Slices routing table, commands, repository structure, conventions, domain entities, context index, common lookups. | First, if you are an agent; whenever you need to know where a task lands. |
| [docs/context/context-index.md](docs/context/context-index.md) | Hub for the strategic context docs and the slice-generalities maps. | To find the detail behind a topic or a slice. |
| [adrs/adr-index.md](adrs/adr-index.md) | Hub for the append-only decision records. | When questioning *why* the studio is shaped this way. |
| [templates/document-template.md](templates/document-template.md) | Copyable shape for a new strategic context doc (context-doc contract). | Before writing a context doc. |
| [templates/hub-template.md](templates/hub-template.md) | Copyable shape for a new topic-folder hub (note contract). | Before creating a hub for a new topic folder. |
| [templates/adr-template.md](templates/adr-template.md) | Copyable shape for a decision record. | Before writing an ADR. |
| [templates/project-md-template.md](templates/project-md-template.md) | Copyable shape for an agent entry point with the nine fixed sections. | When bootstrapping or auditing `docs/project.md`. |
| [templates/slice-generalities-template.md](templates/slice-generalities-template.md) | Copyable shape for a slice-generalities map. | Before writing a slice doc. |
| [templates/interface-surface-template.md](templates/interface-surface-template.md) | Copyable shape for an interface/contract surface sheet. | Before documenting a boundary between two parts. |
| [templates/troubleshooting-template.md](templates/troubleshooting-template.md) | Copyable shape for a symptom-keyed troubleshooting doc. | Before writing symptom → cause → fix guidance. |
| [templates/ui-inventory-template.md](templates/ui-inventory-template.md) | Copyable shape for a UI inventory sheet. | Before cataloguing the surfaces of a widget. |
| [docs/protocols/bootstrap-protocol.md](docs/protocols/bootstrap-protocol.md) | Procedure: bootstrap or audit the studio corpus skeleton. | When starting or auditing the docs. |
| [docs/protocols/new-note-protocol.md](docs/protocols/new-note-protocol.md) | Procedure: add a doc to this corpus and keep validation green. | Before writing any documentation here. |
| [docs/protocols/create-a-new-widget.md](docs/protocols/create-a-new-widget.md) | Procedure: scaffold a new widget from the skeleton and register it as a submodule. | When a new widget is born. |
| [docs/protocols/merge-widget-docs.md](docs/protocols/merge-widget-docs.md) | Procedure: fold a widget's own docs back into this reference corpus as lore. | When a widget teaches the studio something worth keeping. |
| [docs/protocols/release-a-widget.md](docs/protocols/release-a-widget.md) | Procedure: cut a widget release from its own repository. | When shipping a widget. |
| [tools/README.md](tools/README.md) | The scaffolding tool's usage and the token set it substitutes. | Before running `tools/new-widget.sh`. |
| [index.md](index.md) | Generated tree and stats of the whole corpus (region `index`). | To see everything the corpus holds. |
| [tag-index.md](tag-index.md) | Generated tag → docs surface (region `tags`). | When the vocabulary is unknown — search by tag. |
| [validate.js](validate.js) | Zero-dependency corpus validator. Run `node validate.js` (read-only) or `node validate.js --write` (regenerate the two indexes) from the repo root. | Before every change; after adding or moving docs. |

## Start a new widget

Copy the skeleton, run its suite, install it:

```sh
tools/new-widget.sh io.github.daver-ui.mything --name "My Thing"   # copies templates/widget-skeleton to build/io.github.daver-ui.mything
cd build/io.github.daver-ui.mything
node --test tests/*.mjs                                            # the skeleton's Node suite, zero dependencies
./install.sh                                                       # install the plasmoid for the current user
```

The full procedure — output directory, submodule registration and follow-ups — is
[docs/protocols/create-a-new-widget.md](docs/protocols/create-a-new-widget.md).

## The widgets

| Repo (submodule) | Plasmoid id | What it demonstrates | Its own docs |
|---|---|---|---|
| [widgets/tuya-bulb-widget](widgets/tuya-bulb-widget/README.md) · [GitHub](https://github.com/DaveR-ui/tuya-bulb-widget) | `io.github.daver-ui.tuyabulb` | A Python CLI plus a Plasma applet that shells out to it: the reference consumer of this methodology. | `widgets/tuya-bulb-widget/docs/` |
| [widgets/docker-status-widget](widgets/docker-status-widget/README.md) · [GitHub](https://github.com/DaveR-ui/docker-status-widget) | `io.github.daver-ui.dockerstatus` | Pure QML/JS logic, a scoped polkit grant, and a GitHub Pages release site. | `widgets/docker-status-widget/docs/` |

Each widget keeps its **own CI** and its **own test suite**, run from inside its submodule
directory. The studio documents and borrows from them; it never absorbs their code.

## What is NOT here

- **No shared runtime** and no common core library — the widgets do not link against anything in this repo.
- **No monorepo** — each widget is an independent repository, linked here only as a submodule.
- **No code generation** — scaffolding is **copy-and-rename**, not a generator with templates-as-code.
- **No vendored copy of the upstream guidelines** — `documentation-onrails` is referenced by URL (see Upstream).
- **No widget source under `widgets/`** beyond the submodule checkout itself.

## Conventions

- Documentation is English (`doc_language: en`).
- Filenames and folders are lowercase kebab-case; the root `README.md` is the single exemption.
- One topic per file; every topic folder has exactly one hub.
- Schema folders (`templates/`, `docs/protocols/`, `tools/`) have no hub and register through the navigation table above.
- Generated content lives only between `<!-- BEGIN GENERATED: … -->` / `<!-- END GENERATED: … -->`
  markers and is rebuilt with `node validate.js --write`, never hand-edited.
- `related` uses ids (or stems/aliases); body links use filename stems; frontmatter keys are never
  invented — membership rides on `tags`.

## Upstream

The documentation methodology is [`documentation-onrails`](https://github.com/DaveR-ui/documentation-onrails)
**v1.4** (MIT), an **upstream dependency referenced by URL**. Only its **schema layer** is vendored —
the copyable shapes under `templates/` and the two protocols adopted under `docs/protocols/`. A second
copy of the guidelines would be exactly the second-source-of-truth anti-pattern this studio documents.

The guidelines, read upstream:

- [00 — Core principles](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/00-core-principles.md)
- [01 — Structure](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/01-structure.md)
- [02 — Document contract](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/02-document-contract.md)
- [03 — Lifecycle and generated files](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/03-lifecycle-and-generated-files.md)
- [04 — Validation](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/04-validation.md)
- [05 — Agent navigation](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/05-agent-navigation.md)
- [06 — The project entry point](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/06-project-md.md)
- [07 — Agent consumption](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/07-agent-consumption.md)
- [08 — Brownfield adoption](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/08-brownfield.md)
- [09 — Bootstrap workflow](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/09-bootstrap-workflow.md)

## License

MIT. The widgets under `widgets/` keep their own licenses.
