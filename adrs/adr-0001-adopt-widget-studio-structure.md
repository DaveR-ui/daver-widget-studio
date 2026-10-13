---
id: adr-0001-adopt-widget-studio-structure
category: adrs
tags: [adr, structure, documentation, studio]
aliases: ["ADR-0001"]
related: [adr-index, adr-0002-keep-widgets-as-independent-repos, adr-0003-validate-js-consumer-layout, docs-corpus-slice, skeleton-tooling-slice]
version: 1.0
status: active
---

# ADR-0001: Adopt a docs-first widget-studio structure

## Problem

Two independent widget repositories each carried their own documentation. The lore overlapped: the
same Plasma packaging, data-engine and severity lessons were re-derived in both, and where they
overlapped they drifted. The human asked the structural question — group the widgets in one repo, or
write reference documentation instead?

## Solution

Adopt a **docs-first widget-studio structure**: one reference documentation corpus plus one copyable
KPackage skeleton, with the widgets staying independent repositories. The alternatives, with the cost
that sank each:

- **Absorb the widgets into a monorepo.** Rejected: one build, one CI and one release cadence for
  widgets that share nothing at runtime; the drift is replaced by coupling.
- **Extract a shared runtime core library.** Rejected: a core shaped by the union of two unrelated
  needs (one widget shells out to a Python CLI, the other runs shell commands directly); every widget
  pays for the other's dependencies.
- **Build a code generator.** Rejected: templates-as-code to maintain, and generation cannot express
  the per-widget judgement — a command boundary, a config key — that a copy step leaves visible.
- **Write reference documentation + one copyable skeleton.** **Chosen** — the fourth option.

The concrete artifact:

- the onrails v1.4 **consumer layout** at this repository's root: `README.md` as the single human
  entry point, `docs/project.md` as the agent entry point, `docs/context/`, `docs/protocols/`,
  `adrs/`, `templates/`, and the zero-dependency `validate.js`;
- the **three-slice taxonomy** — `documentation-corpus`, `skeleton-and-tooling`,
  `workspace-and-submodules` — in the Slices table;
- the **merged generalities** under `docs/context/`, behind `context-index`;
- the **vendored schema layer** (the copyable templates and the two adopted protocols) with the
  upstream guidelines referenced **by URL**, never vendored;
- widgets staying independent repositories
  ([adr-0002-keep-widgets-as-independent-repos.md](adr-0002-keep-widgets-as-independent-repos.md)).

## When to use

Reading back why the studio exists in this shape, and deciding where a new fact belongs: a widget's
own corpus, the reference corpus, a procedure, or a decision record.

## When not to use

Do not read this as licence to grow the studio into the thing it rejected — no shared core, no
runtime, no generator. Do not edit this record "for clarity": it is append-only; correct it with an
addendum or supersede it.

## Examples

The structure this decision installs:

```text
daver-widget-studio/
├── README.md                 # single human entry point
├── docs/
│   ├── project.md            # agent entry point — Overview, Stack, Slices, Commands
│   ├── context/              # merged generalities, behind context-index
│   └── protocols/            # the studio's own procedures
├── adrs/                     # append-only decision records, behind adr-index
├── templates/                # vendored schema layer + widget-skeleton/
├── tools/new-widget.sh       # scaffolding by copy
├── widgets/                  # widget git submodules (independent repos)
├── validate.js               # zero-dependency corpus validator
├── index.md / tag-index.md   # generated artifacts
└── .gitmodules
```

## Common mistakes

- Building a second entry point: README is the single entry point; nothing opens with a rival "start
  here".
- Turning the reference docs into a catalogue of every widget file — the studio is the reference, not
  the index of the widgets.
- Letting the skeleton grow into a runtime: it is copyable starting material, not a library.

## References

- [adr-0002-keep-widgets-as-independent-repos.md](adr-0002-keep-widgets-as-independent-repos.md) —
  the topology this decision pairs with.
- [adr-0003-validate-js-consumer-layout.md](adr-0003-validate-js-consumer-layout.md) — the validator
  this layout runs.
- [adr-index.md](adr-index.md) — the hub this record is registered in.
- [../README.md](../README.md) — the single human entry point.
- [../docs/project.md](../docs/project.md) — the agent entry point and the three Slices.
- [../docs/context/context-index.md](../docs/context/context-index.md) — the merged generalities.
- [../templates/adr-template.md](../templates/adr-template.md) — the shape this record follows.
