---
last_updated: 2026-10-12
status: active
description: Slice generalities for the copyable KPackage skeleton and the scaffolding tool that copies it — metadata, QML shell, pure-JS core, Node suite, install.sh and the token set.
tags: [slice, generality]
version: 1.0
related: [context-index]
---

# Skeleton and Tooling — Slice Generalities

## What this slice is

The studio's one shippable artifact that is not prose: a **copyable KPackage skeleton** under
`templates/widget-skeleton/`, plus the Bash tool `tools/new-widget.sh` that copies it, substitutes
its placeholder tokens and leaves a new widget repository behind. It is the "skeleton" half of the
reuse scope — **lore + skeleton only**.

## Boundaries (IN/OUT)

- **IN** — the skeleton package (metadata, QML shell, pure-JS core, Node suite, `install.sh`) and the token-substituting scaffolder.
- **OUT** — any per-widget logic, dependency or CI; those belong to the copied widget's own repository, not here.

## Entry points

- `templates/widget-skeleton/` — the copyable package, its `install.sh` and its `tests/` suite.
- `tools/new-widget.sh` — the scaffolding tool.
- `tools/README.md` — the tool's usage and the token set.
- `docs/protocols/create-a-new-widget.md` — the procedure that drives it.

## How it works

- `tools/new-widget.sh <id> --name "<name>" [--out <dir>] [--force]` validates the requested id, copies the skeleton to the target directory, and substitutes the `@WIDGET_ID@` / `@WIDGET_NAME@` tokens across the copied files.
- It refuses to write into a non-empty target unless `--force` is given; scratch output lands under the gitignored `build/`.
- The result is an **independent** package: the copied widget runs its own Node suite and its own CI, and can be installed with `kpackagetool6` or a plain copy. The studio does **not** track the copy afterwards.
- Registering the new repo as a submodule under `widgets/`, and linking it from the entrance docs, is a separate human step in the protocol.

## Conventions of this slice

- The pure-JS core carries **no QML types and no I/O**, so it runs under a bare JavaScript engine.
- **Commands are assembled in exactly one place** (a single builder function), never inline in QML.
- Every **one-shot command carries a run token**, because the data engine's sources are a set.
- **Severity is resolved in exactly one file**; QML only maps it onto a palette.
- New KPackage entry names are `kebab-case`; `install.sh` uses `set -euo pipefail`.

## Dependencies

- Upstream: `bash`, Node.js (for the suite), and `kpackagetool6` for installation.
- Downstream: every widget the tool scaffolds — each becomes a repository the studio only links.

## Known gaps & accepted debt

- The skeleton is distilled from the author's **two** widgets; it encodes a starting point, not a proven universal shape.
- There is no template engine and no merge path: substitution is literal, and an existing widget never receives later skeleton improvements (copy-only is deliberate).
- The skeleton's own `README.md` is a code asset inside `templates/widget-skeleton/` and is skipped by the corpus validator.
