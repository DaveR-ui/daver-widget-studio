---
last_updated: 2026-10-12
status: active
description: How to test a widget that only runs inside plasmashell — the pure-JS .pragma library core as the testable seam, the bare-V8 harness, node --test with zero dependencies, running assembled commands through a real /bin/sh, the architectural invariants worth asserting, qmllint caveats, headless render previews, and CI shape.
tags: [testing, javascript, node, qmllint, ci, plasmoid, verification]
version: 1.0
related: [context-index, skeleton-tooling-slice]
---

# Testing a Plasmoid

A plasmoid `main.qml` only runs inside plasmashell, and there is no QML-level test runner.
The way out is a **pure-JS seam**: put every decision that can be decided without a running
desktop into a `.pragma library` core, and test that core in plain Node.

## The testable seam — the pure-JS core

The core (`contents/ui/<name>.js`) opens with the QML directive:

```js
.pragma library
```

and then contains **no QML types and no I/O** — no `import`, no `require`, no
`XMLHttpRequest`, no `fetch`, no `Qt.`, no `i18n`. It is deliberately **ES5** (manual zero
padding instead of `padStart`, `var` throughout) so it runs under a bare engine. Everything a
widget must decide — command assembly, JSON parsing, the exit-code vocabulary, the severity
mapping, config resolution — lives here and is unit tested. Running processes, reading files
and showing translated text stay in the QML layer.

## The bare-V8 harness — test what ships

The test file reads the **shipped bytes** and evaluates them in a fresh V8 context; it never
imports a copy. QML's `.pragma library` line is not valid JavaScript, so it is stripped first:

```js
const source = readFileSync(sourceUrl, "utf8").replace(/^\s*\.pragma\b.*$/gm, "");
const sandbox = {};
runInContext(source, createContext(sandbox));
```

That the pragma is the *only* manipulation is the point: the tests exercise the file that
actually ships in the KPackage. Because objects built inside the vm belong to a different
realm, their prototypes are not reference-equal to the test realm's, so values are
round-tripped through `JSON.parse(JSON.stringify(value))` before a deep comparison. See
[tuyabulb.test.mjs](../../widgets/tuya-bulb-widget/tests/tuyabulb.test.mjs) and
[dockerstatus.test.mjs](../../widgets/docker-status-widget/tests/dockerstatus.test.mjs).

## `node --test`, zero dependencies, no `package.json`

```sh
node --test tests/*.mjs
```

Run from the repo root. **No `npm install`, no build step, no `package.json`** — the suite is
plain Node. Use the **glob**, not a directory argument: on Node 22 a directory argument is
treated as a module entry point and fails `MODULE_NOT_FOUND`; directory search only arrives in
Node 23. The glob is green from Node 18 through 26.

## Run the assembled command through a real `/bin/sh`

Unit-testing a string proves nothing about shell quoting. The strongest available check is to
run the **real assembled command** through a real shell and assert the arguments survive:

- **Tuya** runs `buildStatusCommand(...)` and lets `set --` split it, then reads back the value
  with the `--device=` prefix stripped, for a hostile set of inputs (spaces, embedded quotes,
  `$(id)`, backticks, newlines, non-ASCII) — proving the value round-trips byte for byte.
- **Docker** writes a stub executable that records its own `argv` to a temp file, prepends the
  stub dir to `PATH`, runs the command through `/bin/sh`, and asserts each argument arrived as
  exactly one inert argument — including a composed `docker start $(docker ps …)` where the
  stub is invoked twice. A quoting failure shows up as an injection marker file existing.

## Architectural invariants worth asserting

The invariant tests are as valuable as the behaviour tests; they stop the design from eroding.
Tuya's package test asserts:

- **Only `main.qml` reads `Plasmoid.configuration`**; representations receive properties.
- **Only one file maps a severity onto a colour** (`SeverityDot.qml`); no second mapping.
- **No command literal outside the JS core** — `main.qml` contains no `--format`, `--no-notify`
  or `--device` token, and every `connectedSources` assignment is a builder call.
- **The shipped tree never references a secret** — no `local_key`, no config flag, nowhere.
- **The JS module is pure** — no I/O primitives, no QML types, no `i18n`.

These are cheap string/AST-lite assertions and they catch exactly the drift a review misses.

## `qmllint` — the Qt6-vs-Qt5 caveat

`qmllint` checks syntax and (on Qt6) semantics. Two rules:

- **Use the Qt6 binary.** On Ubuntu it is `/usr/lib/qt6/bin/qmllint` (package
  `qt6-declarative-dev-tools`). The `qmllint` that may be on `PATH` from Qt5 packages is
  **syntax-only** and reports nothing useful for a Plasma 6 target. Fall back to it only with a
  warning.
- **Warnings and infos are not gating; errors are.** Qt6 `qmllint` exits `0` with any number
  of warnings, so the gate is **an `Error:`-severity diagnostic** *or* a **non-zero exit
  status** (how "could not parse/open this file" surfaces). The whole diagnostic stream is
  printed, never summarised away.

Tuya's lint test skips itself when `qmllint` cannot resolve the Plasma QML imports on the
machine, so a missing module set is a skip, not a false failure.

## Headless render previews — a dev aid that never ships

`main.qml` is a `PlasmoidItem`, so it cannot load in a bare QML runtime (the attached-property
factory fails with `PlasmaQuick::PlasmoidAttached`). But a **pure-consumer** representation can
be previewed offline. Docker's `tools/render_preview.py` loads the shipped
`FullRepresentation.qml` by `file://` URL (no copy, the KPackage is untouched), injects the
properties `main.qml` would push for a given state, and grabs the window with `grabToImage()`
under `QT_QPA_PLATFORM=offscreen`.

- It renders with **no display, no installed package, no running session**.
- It works **only for `FullRepresentation.qml`**; `main.qml` and `CompactRepresentation.qml`
  read `Plasmoid.configuration` / are the `PlasmoidItem` and still need plasmashell.
- It lives under `tools/`, which is **not part of the KPackage** — nothing here ships.
- It is **review-grade evidence, never a release gate**; output PNGs are scratch and are never
  committed. See [render-preview.md](../../widgets/docker-status-widget/docs/verification/render-preview.md).

## CI shape

Docker's CI is **three independent jobs**, three exact status-check contexts
([ci.yml](../../widgets/docker-status-widget/.github/workflows/ci.yml)):

| Job | Command | What it gates |
|---|---|---|
| `test` | `node --test tests/*.mjs` | the widget's behaviour |
| `qmllint` | Qt6 `qmllint` over both QML roots, errors only | QML syntax/semantics |
| `docs` | `node docs/validate.js` (check mode only) | the widget's own corpus |

It triggers on **pull requests only** — running the same checks on both push and pull request
reports every context twice, which branch protection cannot tell apart. There is **no
`paths-ignore`**: the suite is fast, and **a pull request that touches only docs must still be
stopped by a broken widget**. That is the answer to "what a docs-only change must prove": the
widget's own suite is the regression guard, and it runs regardless.

Tuya ships **no CI** — it has no `.github/` directory at all. Its suites run locally: the Node
suite above plus a `pytest` package test
([test_plasmoid.py](../../widgets/tuya-bulb-widget/tests/test_plasmoid.py)). This asymmetry is
the evidence, not a recommendation: the studio documents both and prefers the CI-gated shape.

## Known gaps

- **No QML behaviour test exists.** `main.qml`'s source wiring is asserted by string checks,
  not executed; a defect only it can show needs a running plasmashell.
- **The render preview is not automated** — no CI runner has a display, so every capture tier
  is a manual probe.
- **`qmllint` warning counts are version-bound** and are deliberately not recorded as evidence.
- **Coverage of the QML layer is structural (invariants), not behavioural**; a bug inside a
  binding that still references the right builders would not be caught.

## References

- [executable-dataengine](executable-dataengine.md) — the contract the builders are written against.
- [plasmoid-anatomy](plasmoid-anatomy.md) — the package the tests inspect.
- [packaging-and-install](packaging-and-install.md) — the release gate this suite feeds.
- [skeleton-tooling-slice](skeleton-tooling-slice.md) — the skeleton these conventions are encoded in.
