---
last_updated: 2026-10-12
status: active
description: Slice generalities for the widgets workspace — the two widget git submodules, their independent repositories and CI, and the cross-widget comparison of what each demonstrates.
tags: [slice, generality]
version: 1.0
related: [context-index]
---

# Workspace and Submodules — Slice Generalities

## What this slice is

The `widgets/` workspace: the place where the studio's independent widget repositories appear
side by side. Two submodules are declared in `.gitmodules` — `tuya-bulb-widget` (branch `main`) and
`docker-status-widget` (branch `master`) — and the cross-widget comparison doc records what each one
demonstrates. The workspace is a **view**, not a build.

## Boundaries (IN/OUT)

- **IN** — `widgets/` as a checkout area, `.gitmodules` as the declaration, and `docs/context/widget-comparison.md` as the comparison.
- **OUT** — the widget source repositories themselves, their builds, their tests and their own docs corpora. The studio reads them; it never owns them.

## Entry points

- `widgets/` — the submodule working trees.
- `.gitmodules` — the pinned submodule URLs and branches.
- `docs/context/widget-comparison.md` — the two widgets compared, and what each demonstrates.

## How it works

- Each widget stays an **independent repository**; the studio only records a pointer to it as a submodule, so a clone of the studio must initialize the submodules to see them.
- The corpus validator **skips `widgets/`** entirely, because every widget ships its own documentation corpus — the studio measures its own docs, not the widgets'.
- Each widget runs its **own CI and its own test suite from inside its own directory**, never from the studio root.
- Linking is one-directional: the studio's entry docs link to `widgets/<id>/README.md` and to the widget's GitHub URL; nothing links back into the studio from a widget.

## Conventions of this slice

- **Never vendor widget code** into the studio; link it.
- **Compare, do not merge**: shared lessons are distilled into the reference corpus as prose, not shared as runtime.
- Keep the submodule list in `.gitmodules` and the widgets table in the entry docs in agreement.
- New widgets are registered here only as submodules, after they exist as their own repositories.

## Dependencies

- Upstream: `git` submodule support and each widget's own repository.
- Downstream: the entry-point navigation tables and `widget-comparison.md`, which read this workspace.

## Known gaps & accepted debt

- The comparison rests on **only two widgets**, so "what each demonstrates" is a small, possibly unrepresentative sample.
- An uninitialized clone shows empty `widgets/` directories; the workspace is meaningful only after `git submodule update --init`.
- The validator cannot see into the widgets, so nothing machine-checks that the submodule links in the entry docs still match `.gitmodules`.
