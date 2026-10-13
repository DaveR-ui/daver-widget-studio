---
id: context-index
category: context
tags: [hub, index, navigation]
aliases: ["Context Index"]
related: [docs-corpus-slice, skeleton-tooling-slice, workspace-slice]
version: 1.0
status: active
---

# Context Index

Navigation hub for the strategic docs in `docs/context/`. Each file covers exactly one topic.
Start at the [project entry point](../project.md) for routing, then open the doc that matches your
change. This page routes and catalogs; it deliberately does not restate what the docs say.

## What this folder is

`docs/context/` holds the studio's **strategic reference** — the durable "how this studio thinks"
material — plus one **slice-generalities** map per slice in the [Slices table](../project.md#slices).
Every file here carries the **context-doc** frontmatter (`last_updated`, `status`, `description`,
`tags`, `version`), and the slice maps ride on `tags: [slice, generality]`.

## Strategic docs

| Doc | What it answers |
|---|---|
| [project-overview](project-overview.md) | What the studio is, its reuse scope (lore + skeleton) and its anti-goals. |
| [technology-stack](technology-stack.md) | Every layer of the studio, separating what is implemented here from what is documented as widget practice. |
| [plasmoid-anatomy](plasmoid-anatomy.md) | How a Plasma 6 KPackage is structured and how a QML shell is loaded. |
| [packaging-and-install](packaging-and-install.md) | The widget lifecycle: where the version lives, install/upgrade/uninstall, and a published release site. |
| [qml-shell-js-core](qml-shell-js-core.md) | The QML-shell + pure-JS-core split, and the invariants that keep the core testable. |
| [executable-dataengine](executable-dataengine.md) | The `executable` engine's payload shape and why its sources behave as a set. |
| [severity-and-state-model](severity-and-state-model.md) | How a raw probe result becomes one severity, and where that happens. |
| [privilege-and-polkit](privilege-and-polkit.md) | The narrowest-grant discipline, and what to do instead when a widget needs no root. |
| [i18n-gettext](i18n-gettext.md) | How an applet's translations are compiled into the package, and when to bother. |
| [testing-a-plasmoid](testing-a-plasmoid.md) | How to exercise widget logic without a running Plasma session. |
| [widget-comparison](widget-comparison.md) | The two widget submodules compared, and what each one demonstrates. |

## Slice generalities

| Slice doc | The slice it maps |
|---|---|
| [docs-corpus-slice](docs-corpus-slice.md) | `documentation-corpus` — the studio's own onrails corpus, validator and schema layer. |
| [skeleton-tooling-slice](skeleton-tooling-slice.md) | `skeleton-and-tooling` — the copyable KPackage skeleton and the tool that copies it. |
| [workspace-slice](workspace-slice.md) | `workspace-and-submodules` — the `widgets/` submodules and their independent repos. |

## What belongs elsewhere

- **`docs/protocols/`** — step-by-step procedures. If it is a sequence of commands, it is a protocol, not a context doc.
- **`adrs/`** — append-only decisions and their rationale, behind the [adr-index](../../adrs/adr-index.md).
- **`templates/`** — copyable shapes for new docs; the schema layer, not prose.
- **The root `README.md`** — the human entry point and the navigation table for every hub-less folder.
