---
last_updated: 2026-10-12
status: active
description: The studio's technology stack, row by row, separating what is implemented in this repository from what is only documented as widget practice — Plasma 6 plasmoid API, KPackage and kpackagetool6, the QtQuick/Kirigami/PlasmaComponents3 toolkit, the plasma5support executable engine, the ES5 .pragma library core, kcfg, gettext, the bash and zero-dependency Node tooling, git submodules, the onrails v1.4 documentation schema and the licenses — plus what is deliberately absent.
tags: [technology, stack, plasma6, kpackage, qml, javascript, node, submodules, tooling]
version: 1.0
related: [context-index, plasmoid-anatomy, qml-shell-js-core, executable-dataengine, packaging-and-install, skeleton-tooling-slice, docs-corpus-slice]
---

# Technology Stack — daver-widget-studio

The honest summary first: **this studio ships documentation and a copyable skeleton, not a
runtime.** Nothing here executes as a product. Two postures appear in the table below, and the
difference is the point of reading it carefully:

- **implemented in the studio** — code that lives in this repository and runs here. It is exactly
  the scaffolding tool, the corpus validator and the skeleton package.
- **documented as widget practice** — prose in this corpus, plus the shape the skeleton encodes.
  It is *not* a library the studio provides, and no widget imports it from here.

| Layer | Technology | Version / posture | Where it lives |
|---|---|---|---|
| Plasmoid runtime | KDE Plasma 6 plasmoid API | `X-Plasma-API-Minimum-Version: 6.0`; verified on the author's Plasma 6.7.x machine — a reference, not a supported floor | documented as widget practice, encoded by the skeleton's `metadata.json` ([plasmoid-anatomy](plasmoid-anatomy.md)) |
| Packaging | KPackage `Plasma/Applet` via `kpackagetool6` | the Plasma 6 tool; `plasmapkg2` is the Plasma 4/5-era tool and obsolete here; plain-copy fallback into `~/.local/share/plasma/plasmoids/` when the tool is absent | documented as widget practice, plus the skeleton's `install.sh` ([packaging-and-install](packaging-and-install.md)) |
| UI toolkit | QtQuick, QtQuick.Layouts, QtQuick.Controls, Kirigami, and the Plasma modules `org.kde.plasma.components` (as `PlasmaComponents3`), `org.kde.plasma.core`, `org.kde.plasma.plasmoid`, `org.kde.plasma.plasma5support`, `org.kde.plasma.configuration` | imported by module URI; no pinned patch version | documented as widget practice — the skeleton's `contents/ui/` ([qml-shell-js-core](qml-shell-js-core.md)) |
| Data engine | `org.kde.plasma.plasma5support` `DataSource` with `engine: "executable"` | commands as sources; set semantics; measured against plasma5support 6.7.4 / 6.7.5, each stamp being that widget's own measurement | documented as widget practice — `main.qml`, the only file that assigns a command ([executable-dataengine](executable-dataengine.md)) |
| Core logic | plain JavaScript, one `.pragma library` file | **ES5 on purpose** (`var`, `function`, `switch`; no `let`/`const`, no arrow functions, no classes) — the plasmoid's engine and a bare V8 must both accept these exact bytes. No QML types, no I/O | documented as widget practice — `contents/ui/widget.js` ([qml-shell-js-core](qml-shell-js-core.md)) |
| Configuration | QML kcfg schema plus `cfg_<entry>` aliases | a setting exists in three places that must agree — `main.xml`, the config page, `main.qml`; a combo-box value cannot be an alias | documented as widget practice ([plasmoid-anatomy](plasmoid-anatomy.md)) |
| Privilege | a polkit JavaScript rule | only when a widget genuinely must change system state; narrowest predicate, installed by its own explicit command | documented as widget practice, and only one of the two widgets has one ([privilege-and-polkit](privilege-and-polkit.md)) |
| Translations | gettext `.po` compiled by `msgfmt --check-format` into a shipped `.mo`, domain `plasma_applet_<KPlugin.Id>` | only when translations exist — one of the two widgets ships a catalogue, the other has none | documented as widget practice ([i18n-gettext](i18n-gettext.md)) |
| Scaffolding | Bash with `set -euo pipefail`; paths resolved from the script's own directory | `tools/new-widget.sh` (copy-and-rename, no template engine) and the skeleton's `install.sh` | **implemented in the studio** ([tools/README.md](../../tools/README.md)) |
| Tests and corpus gate | Node.js, zero dependencies | `node --test tests/*.mjs` inside a widget; `node validate.js` (check) / `--write` (regenerate) in the studio. No `package.json`, no `npm install`, no build step | **implemented in the studio** — `validate.js`, plus the skeleton's `tests/` ([testing-a-plasmoid](testing-a-plasmoid.md)) |
| Widget linking | git submodules | `widgets/`, declared in `.gitmodules`; pointers bumped deliberately, never silently | **implemented in the studio** ([workspace-slice](workspace-slice.md)) |
| Documentation | Markdown, governed by the `documentation-onrails` **v1.4** consumer layout | upstream referenced **by URL**; only its **schema layer** is vendored under `templates/` | **implemented in the studio** ([docs-corpus-slice](docs-corpus-slice.md)) |
| Licensing | MIT for the studio; each widget keeps its own | per-repository `LICENSE`; the skeleton ships MIT as the example | **implemented in the studio** |

## Deliberately absent

- **No build step** and **no bundler** — the studio's own artifacts are two generated Markdown
  regions rendered by `validate.js`, and a widget's artifact is the package directory itself
  (staged into a gitignored `build/`).
- **No `package.json`** and **no npm dependencies** — `validate.js` and the skeleton suite are
  plain Node scripts, so there is nothing to install and no lockfile to drift.
- **No shared runtime** — the widgets do not link against anything here, so there is no core to
  import ([ADR-0002](../../adrs/adr-0002-keep-widgets-as-independent-repos.md)).
- **No CI in the studio itself** — each widget has its own workflows inside its own repository; the
  studio's gate is `node validate.js` run by hand
  ([release-a-widget.md](../protocols/release-a-widget.md)).

## Known gaps

- The stack table covers the layers **both author widgets exercise**. A layer neither widget uses
  is not asserted here, and the absence of a row is not a claim that the layer cannot be used.
- Version stamps in the table are **observations on one machine**, not a compatibility matrix. The
  plasma5support stamp is the one place the two widgets disagree, and each is recorded as its own
  measurement in [widget-comparison](widget-comparison.md).
- `plasmapkg2` is declared obsolete from the tool's era, not measured against a Plasma 6 install
  ([packaging-and-install](packaging-and-install.md) says the same).

## References

- [docs/project.md](../project.md) — the same stack compressed into the agent entry point's table.
- [plasmoid-anatomy](plasmoid-anatomy.md) and [packaging-and-install](packaging-and-install.md) —
  the package and its lifecycle.
- [qml-shell-js-core](qml-shell-js-core.md) and [executable-dataengine](executable-dataengine.md) —
  the boundary and the engine behind it.
- [testing-a-plasmoid](testing-a-plasmoid.md) — why the Node row exists at all.
- [skeleton-tooling-slice](skeleton-tooling-slice.md) and [docs-corpus-slice](docs-corpus-slice.md) —
  the two slices that own the rows marked "implemented in the studio".
- [widget-comparison](widget-comparison.md) — the two widgets the "documented as widget practice"
  rows were distilled from.
