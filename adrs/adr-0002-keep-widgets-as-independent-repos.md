---
id: adr-0002-keep-widgets-as-independent-repos
category: adrs
tags: [adr, submodules, workspace, autonomy]
aliases: ["ADR-0002"]
related: [adr-index, adr-0001-adopt-widget-studio-structure, adr-0003-validate-js-consumer-layout, workspace-slice]
version: 1.0
status: active
---

# ADR-0002: Keep each widget as an independent repository

## Problem

The reuse value of a widget for a *future* widget is in its **lore and skeleton**, not in its code. A
shared runtime core would couple two widgets that have nothing at runtime in common: one
(`tuya-bulb-widget`) shells out to a Python CLI, the other (`docker-status-widget`) runs shell
commands directly. A shared core would be a library shaped by the union of those needs, imported by
widgets that share none of them.

## Solution

Each widget stays its **own repository**, linked into this studio only as a **git submodule** under
`widgets/`. No widget code is absorbed, and there is no shared runtime core.

Considered:

- **Monorepo with a workspace.** Rejected: one dependency set, one CI and one cadence for unrelated
  widgets.
- **A shared `widget-core` library the widgets import.** Rejected: couples unrelated needs, forces a
  single dependency set, and pulls each widget toward the other's shape.
- **Git submodules.** **Chosen** — the studio records a pointer and links; the widget keeps its
  autonomy.

Consequences, stated honestly:

- two checkouts to keep in sync (initialize the submodules, or `widgets/` is empty);
- submodule pointers that must be **bumped deliberately** — `git submodule update --remote`;
- no cross-widget refactor: a shared improvement is a note or a skeleton change, not a patch applied
  in one place;
- each widget keeps its **own CI, its own dependencies and its own release cadence**, which is
  exactly what "no shared runtime" buys.

## When to use

Read this back whenever someone proposes "just move the widget in", or asks why a fix in one widget
does not appear in the other.

## When not to use

Do not read it as "the studio never touches widget code": the studio **documents and borrows** from
the widgets, and links to them — it just never owns them or links *against* them. Do not edit this
record to relax it; supersede it with a successor ADR.

## Examples

The declaration the topology lives in:

```ini
# .gitmodules
[submodule "widgets/tuya-bulb-widget"]
	path = widgets/tuya-bulb-widget
	url = https://github.com/DaveR-ui/tuya-bulb-widget.git
	branch = main
[submodule "widgets/docker-status-widget"]
	path = widgets/docker-status-widget
	url = https://github.com/DaveR-ui/docker-status-widget.git
	branch = master
```

Linking is one-directional: the studio's entry docs link to `widgets/<name>/README.md` and to the
widget's GitHub URL; nothing links back into the studio from a widget.

## Common mistakes

- Bumping a submodule pointer silently — the pointer move is a deliberate, reviewed step.
- Assuming a widget can import anything from this repository: there is no shared core to import.

## References

- [adr-0001-adopt-widget-studio-structure.md](adr-0001-adopt-widget-studio-structure.md) — the
  structure this topology completes.
- [adr-0003-validate-js-consumer-layout.md](adr-0003-validate-js-consumer-layout.md) — why the
  widget checkouts are skipped by the studio's validator.
- [adr-index.md](adr-index.md) — the hub this record is registered in.
- [../.gitmodules](../.gitmodules) — the submodule declarations themselves.
- [../docs/context/workspace-slice.md](../docs/context/workspace-slice.md) — the slice that reads
  the workspace.
- [../README.md](../README.md) — the widgets table that names both submodules.
