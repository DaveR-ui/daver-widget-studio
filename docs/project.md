---
last_updated: 2026-10-12
status: active
description: Agent entry point for daver-widget-studio — a docs-first KDE Plasma 6 widget studio: overview, technology stack, the Slices routing table, commands, structure, conventions, domain entities and common lookups.
tags: [project, entry-point, routing, slices]
version: 1.0
doc_language: en
related: [project-overview]
---

# Project Entry Point — daver-widget-studio

## Overview

`daver-widget-studio` is a **docs-first widget studio** for KDE Plasma 6 widgets written by
one author. It is **not** a code-generation monorepo and it is **not** a shared runtime: it
merges the authoring knowledge of the author's widgets into **one reference documentation
corpus** and **one copyable KPackage skeleton**. The reuse scope is deliberately narrow —
**lore + skeleton only**, with **no shared runtime core**: every widget keeps its own code,
dependencies, build and CI, and the studio never absorbs them.

Topology: the widgets stay **independent git repositories**, linked here only as **git
submodules** under `widgets/`. The studio references them; it does not own their source. This
repository is **public** — the authoring reference is a product, not private scaffolding — and
the documentation methodology it follows, **`documentation-onrails` v1.4**, is an **upstream
dependency referenced by URL**, never copied.

Anti-goals, stated so nobody adds them by accident: no shared core library linked by the
widgets; no monorepo; no code generator (scaffolding is copy-and-rename); no vendored copy of
the upstream guidelines; no widget source committed under `widgets/` beyond the submodule
checkout.

## Technology Stack

| Layer | Technology | Version / posture | Where it lives |
|---|---|---|---|
| Plasmoid runtime | KDE Plasma 6 plasmoid API | `X-Plasma-API-Minimum-Version: 6.0` | documented as widget practice; encoded by the skeleton |
| Packaging | KPackage `Plasma/Applet` via `kpackagetool6` | plain-copy fallback when absent | skeleton + widget practice |
| Data engine | `org.kde.plasma.plasma5support` `DataSource`, `executable` engine | commands as sources; set semantics | documented as widget practice |
| Core logic | plain JavaScript, `.pragma library` | no QML types, no I/O — runs under a bare engine | skeleton + widget practice |
| Scaffolding | Bash, `set -euo pipefail` | `tools/new-widget.sh`, widget `install.sh` | implemented in the studio |
| Documentation tooling | Node.js, zero dependencies | `node --test` (skeleton suite), `node validate.js` (corpus gate) | implemented in the studio |
| Widget linking | git submodules | `widgets/`, declared in `.gitmodules` | implemented in the studio |
| License | MIT | studio; widgets keep their own | implemented in the studio |

The studio itself ships **docs plus a copyable skeleton** and has **no runtime**: the rows marked
"implemented in the studio" are the only things that execute here. The rows marked "documented as
widget practice" describe the shape a widget (or the skeleton) takes; they are not a library the
studio provides.

## Slices

| Slice | Description | Keywords | Entry points | Primary agents |
|---|---|---|---|---|
| documentation-corpus | The studio's own onrails v1.4 corpus: entry points, hubs, generated indexes, the validator, the vendored schema layer, the studio protocols and the ADRs | docs, onrails, frontmatter, hub, index, tag-index, validate, adr, protocol, kebab, entry point, navigation | README.md, docs/project.md, docs/context/, docs/protocols/, adrs/, index.md, tag-index.md, validate.js | documenter, reviewer, explorer |
| skeleton-and-tooling | The copyable KPackage skeleton and the scaffolding tool that copies it: metadata, QML shell, pure-JS core, Node suite, install.sh, and the @WIDGET_ID@/@WIDGET_NAME@ token set | skeleton, kpackage, plasmoid, qml, javascript, node --test, kpackagetool6, scaffolding, token, new-widget, install | templates/widget-skeleton/, tools/new-widget.sh | general, tester, reviewer |
| workspace-and-submodules | The widgets/ workspace: the two widget git submodules, their independent repos and CI, and the cross-widget comparison of what each one demonstrates | submodule, gitmodules, workspace, widget repo, ci, independent, comparison | widgets/, .gitmodules, docs/context/widget-comparison.md | explorer, documenter |

## Commands

Run from the repo root unless noted.

| Command | Purpose |
|---|---|
| `node validate.js` | Documentation gate in **check mode** — strictly read-only, never writes. Exit 1 on errors. |
| `node validate.js --write` | Regenerate the two generated regions (`index.md`, `tag-index.md`) write-if-diff, then run the full check. |
| `tools/new-widget.sh <id> --name "<name>" [--out <dir>] [--force]` | Scaffold a new widget by copying `templates/widget-skeleton/` and substituting the token set. |
| `cd templates/widget-skeleton && node --test tests/*.mjs` | Run the skeleton's own Node suite (zero dependencies). |
| `kpackagetool6 --type Plasma/Applet --install\|--upgrade\|--remove <id>` | Install, upgrade or remove a built widget package. |

Notes:

- The **studio has no build step, no `package.json` and no `npm install`** — `validate.js` and the
  skeleton suite are plain Node scripts.
- A **widget's own tests and CI run in its own submodule directory** (`.github/workflows/` inside
  `widgets/<id>/`), never from the studio root. The studio only links the widget.

## Repository Structure

```text
daver-widget-studio/
├── README.md                   # single human entry point
├── docs/
│   ├── project.md              # this agent entry point (nine fixed sections)
│   ├── context/                # strategic docs + slice generalities, behind context-index
│   └── protocols/              # studio procedures (bootstrap, new note, new widget, merge, release)
├── adrs/                       # append-only decision records, behind adr-index
├── templates/                  # the vendored documentation-onrails schema layer
│   └── widget-skeleton/        # the copyable KPackage skeleton (skipped by the corpus scan)
├── tools/                      # the scaffolding tool + its README
├── widgets/                    # widget git submodules (independent repos; skipped by the scan)
├── validate.js                 # zero-dependency corpus validator and index renderer
├── index.md                    # generated corpus index
├── tag-index.md                # generated tag index
├── .gitmodules                 # submodule declarations
├── .gitignore                  # ignores build/, node_modules/, local agent runtime state
└── LICENSE                     # MIT + the documentation-onrails attribution
```

## Key Conventions

Corpus rules:

- Documentation is **English** (`doc_language: en`); filenames and folders are lowercase kebab-case.
- **One topic per file**; every topic folder has exactly one hub (`*-index.md`).
- Schema folders (`templates/`, `docs/protocols/`, `tools/`) have **no hub**; their members register
  through the navigation table in the root `README.md` instead.
- **Membership rides on `tags`**; `related` uses ids (or stems/aliases); frontmatter keys are never invented.
- Generated content lives only between the `<!-- BEGIN GENERATED: … -->` / `<!-- END GENERATED: … -->`
  markers and is rebuilt by `node validate.js --write`, never hand-edited.
- The upstream methodology is **referenced by URL**; only the **schema layer** (templates and the two
  adopted protocols) is vendored.

Engineering conventions the studio preaches and the skeleton encodes:

- The **pure-JS core has no QML types and performs no I/O**; it is testable under a bare engine.
- **Commands are assembled in exactly one place** — a single `build*Command` per command, never inline in QML.
- Every **one-shot command carries a run token**, because the `executable` engine treats its sources as a set.
- **Severity is resolved in exactly one file**; QML only maps the result onto a palette.
- New **KPackage entry names** are `kebab-case`.

Seat note: this repository has **no Angular, Go or CSS surface**, so implementation work routes to the
**`general` subagent** rather than the language-parameterized `coder` seat — recorded here so nobody waits
for a coder seat that does not exist in this studio.

## Domain Entities

- **Studio** — this repository: the reference corpus, the skeleton, the tooling and the submodule links. No runtime.
- **Widget repo** — an independent git repository (own code, deps, build, CI) linked into `widgets/` as a submodule.
- **Plasmoid / KPackage** — a `Plasma/Applet` package (`metadata.json` + `contents/`) that Plasma loads via `kpackagetool6`.
- **Skeleton** — `templates/widget-skeleton/`: the copyable KPackage shell with a pure-JS core, Node suite and `install.sh`.
- **Scaffolding-by-copy** — creating a widget by copying the skeleton and renaming it, not by code generation.
- **Token** — a placeholder in the skeleton (`@WIDGET_ID@`, `@WIDGET_NAME@`) substituted by the scaffolding tool.
- **Slice** — a routing unit in the Slices table binding a change area to entry points and primary agents.
- **Hub** — the single `*-index.md` page that registers and routes a topic folder; never restates note content.
- **Generated region** — the marker-delimited block of `index.md` / `tag-index.md` that `validate.js` rewrites.
- **Schema layer** — the vendored copyable shapes/templates and the two protocols adopted from upstream.
- **Upstream** — `documentation-onrails` v1.4, referenced by URL; the methodology the corpus follows.
- **Pure-JS core** — the widget logic file with no QML types and no side effects, unit-tested in Node.
- **Severity** — the single answer to "how bad is this state" (`positive` / `neutral` / `negative` / `muted`).
- **Run token** — a unique trailing shell comment that makes a repeated one-shot a distinct engine source.
- **Executable data engine** — the `plasma5support` `DataSource` running a widget's fixed commands and reporting stdout.

## Context Index

- [project-overview](context/project-overview.md) — the studio's purpose, reuse scope and anti-goals at a glance.
- [technology-stack](context/technology-stack.md) — every layer of the studio, separating what is implemented here from what is documented as widget practice.
- [plasmoid-anatomy](context/plasmoid-anatomy.md) — how a KDE Plasma 6 plasmoid packages a QML shell and its parts.
- [packaging-and-install](context/packaging-and-install.md) — the widget lifecycle: where the version lives, install/upgrade/uninstall, and a published release site.
- [qml-shell-js-core](context/qml-shell-js-core.md) — the QML-shell + pure-JS-core split and the invariants that keep the core testable.
- [executable-dataengine](context/executable-dataengine.md) — the `plasma5support` `executable` engine contract and its set semantics.
- [severity-and-state-model](context/severity-and-state-model.md) — where severity is decided and how a state maps onto it.
- [privilege-and-polkit](context/privilege-and-polkit.md) — the narrowest-grant discipline, and what to do instead when a widget needs no root.
- [i18n-gettext](context/i18n-gettext.md) — how an applet's translations are compiled into the package, and when to bother.
- [testing-a-plasmoid](context/testing-a-plasmoid.md) — testing widget logic without a running Plasma.
- [widget-comparison](context/widget-comparison.md) — the two widget submodules side by side, and what each demonstrates.
- [context-index](context/context-index.md) — hub for the strategic docs and the slice generalities.
- [docs-corpus-slice](context/docs-corpus-slice.md) — slice generalities for the studio's own documentation corpus.
- [skeleton-tooling-slice](context/skeleton-tooling-slice.md) — slice generalities for the skeleton and its scaffolding tool.
- [workspace-slice](context/workspace-slice.md) — slice generalities for the widget workspace and its submodules.

## Common Lookups

| Question | File |
|---|---|
| Where do I start a new widget? | [docs/protocols/create-a-new-widget.md](protocols/create-a-new-widget.md) |
| How do I fold a widget's docs into the reference corpus? | [docs/protocols/merge-widget-docs.md](protocols/merge-widget-docs.md) |
| How do I cut a widget release? | [docs/protocols/release-a-widget.md](protocols/release-a-widget.md) |
| How do I add a doc and keep validation green? | [docs/protocols/new-note-protocol.md](protocols/new-note-protocol.md) |
| How do I bootstrap or audit the corpus? | [docs/protocols/bootstrap-protocol.md](protocols/bootstrap-protocol.md) |
| Why is there no shared core? | [adrs/adr-0002-keep-widgets-as-independent-repos.md](../adrs/adr-0002-keep-widgets-as-independent-repos.md) |
| Why a docs-first studio instead of grouping the widgets? | [adrs/adr-0001-adopt-widget-studio-structure.md](../adrs/adr-0001-adopt-widget-studio-structure.md) |
| Why is `widgets/` skipped by the validator? | [adrs/adr-0003-validate-js-consumer-layout.md](../adrs/adr-0003-validate-js-consumer-layout.md) |
| How does a plasmoid package a QML shell? | [context/plasmoid-anatomy.md](context/plasmoid-anatomy.md) |
| How is a state's severity decided? | [context/severity-and-state-model.md](context/severity-and-state-model.md) |
| How do I test without Plasma? | [context/testing-a-plasmoid.md](context/testing-a-plasmoid.md) |
| What is the executable data-engine contract? | [context/executable-dataengine.md](context/executable-dataengine.md) |
| What does each widget demonstrate? | [context/widget-comparison.md](context/widget-comparison.md) |
