---
last_updated: 2026-10-12
status: active
description: The cross-widget index the rest of the corpus hangs from — the two submodules compared topic by topic (language stack, shell reach, state model, privilege, i18n, packaging, testing, CI, release, update mechanism), which patterns a new widget should copy from which repository, the invariants both share, and the honest limits of a two-widget sample.
tags: [comparison, widgets, index, submodules, architecture, lore]
version: 1.0
related: [qml-shell-js-core, severity-and-state-model, privilege-and-polkit, i18n-gettext]
---

# Widget Comparison

The two widget repositories linked under `widgets/` are the evidence this corpus is
distilled from. They solve different problems and therefore demonstrate different
patterns; both are correct, and a new widget copies from the one whose pattern fits.
This is the index the other context docs hang from.

The two are independent git repositories, linked here only as submodules — each keeps
its own code, dependencies, build and CI, and the studio never absorbs either.

## The two widgets

| | tuya-bulb-widget | docker-status-widget |
|---|---|---|
| Plasmoid id | `io.github.daver-ui.tuyabulb` | `io.github.daver-ui.dockerstatus` |
| What it does | shows and controls a Tuya smart bulb over the LAN | reports the Docker daemon and starts/stops it |
| Repo | [`widgets/tuya-bulb-widget/`](../../widgets/tuya-bulb-widget/README.md) | [`widgets/docker-status-widget/`](../../widgets/docker-status-widget/README.md) |

## Topic by topic

| Topic | tuya-bulb-widget | docker-status-widget | Take this from |
|---|---|---|---|
| **Language stack** | Python CLI (`tuya-bulb`) + a QML/JS applet that shells out to it | pure QML/JS logic; no external program of its own | either; the split, not the language |
| **How it reaches a shell** | runs the `tuya-bulb` CLI and parses its `--format json` | runs `systemctl` / `docker` directly through the `executable` engine | tuya when a helper owns the real logic |
| **Command assembly** | every command is a `build*Command()` in the core; only fixed strings | mostly fixed string constants; three recorded build boundaries | the invariant (one assembly point) |
| **State model** | `on` / `off` / `mixed` / `unknown`, plus `offline` for a linked bulb | `active` / `inactive` / `failed` / `unknown` (containers: `running`/`exited`/…) | [severity-and-state-model](severity-and-state-model.md) |
| **Severity** | four values plus `warning` for "offline but retrying" | four values | [severity-and-state-model](severity-and-state-model.md) |
| **Privilege model** | **none** — the user's own CLI and file credentials authorise | **scoped polkit rule**: one action id, one unit, one verb, local active `wheel` | [privilege-and-polkit](privilege-and-polkit.md) |
| **Destructive actions** | none escalates; a blind `toggle` is refused | stop is arm-then-confirm and outside the grant; a widget-owned shutdown countdown | docker's confirm pattern |
| **i18n** | gettext: hand-authored `es.po` compiled to a shipped `.mo`, domain pinned to the id | none: only `Name[es]`/`Description[es]` metadata keys baked into `metadata.json` | [i18n-gettext](i18n-gettext.md) |
| **Packaging** | a **rendered template**: `contents/config/main.xml.in` with `@CLI_PATH@` substituted at install time | the KPackage **committed in place** (`contents/config/main.xml`) | tuya only when a value must be resolved at install time |
| **Testing** | pytest (Python CLI) **plus** `node --test` driven through the Python suite | `node --test` only, over the pure core | either; the pure-core harness is shared |
| **CI** | none in-tree (no `.github/`) | three-job GitHub Actions (`test`, `qmllint`, `docs`) on PR; a Pages workflow on push | docker |
| **Release** | no release automation; version authored by hand in `metadata.json` (and a separate `pyproject.toml` version) | a manifest (`site/latest.json`) generated from `metadata.json` and published by GitHub Pages | docker |
| **Update mechanism** | none | one fixed https manifest the widget polls, silent on every failure | docker |

## What "copy which" means in practice

A new widget should take different patterns from different places rather than cloning
one repo:

- **Start from the skeleton**, not from either widget: `templates/widget-skeleton/` is
  the copyable shape that already encodes the pure-core/QML-shell invariant, the run
  token, the single severity mapping and a passing zero-dependency Node suite. Use
  `tools/new-widget.sh` to copy it (see [docs/project.md](../project.md)).
- **Copy the user-owned-CLI shape from tuya** when the widget's real work needs a
  protocol, secrets or a network stack that should not live in QML. Let the widget run
  a user-installed command and parse its JSON; keep the widget itself privilege-free.
- **Copy the install-time template from tuya** only when a value (an absolute path to a
  helper) must be resolved on the installing machine: ship `main.xml.in` and substitute
  at render time.
- **Copy the scoped polkit grant from docker** only if the widget genuinely must change
  system state and cannot delegate to a user-owned tool. Copy the *shape* — narrowest
  predicate, separate explicit installer command — never the scope.
- **Copy the arm-then-confirm pattern from docker** for any destructive action.
- **Copy the CI trio and the Pages release site from docker** if the widget ships to
  users: `test` + `qmllint` (Qt6) + `docs` as the PR gate, and a generated manifest
  published by Pages for an in-widget update check.
- **Copy docker's fixed palette only if you must reproduce a design mockup verbatim**;
  otherwise follow the theme like tuya (see the trade-off in
  [severity-and-state-model](severity-and-state-model.md)).

## Invariants both widgets share

These hold in both repositories, and any new widget keeps them:

1. **A pure-JS core with no QML types and no I/O**, ES5 style, evaluated as shipped
   bytes by a `node --test` suite.
2. **A single scope→severity decision in the core**, and a single severity→colour
   mapping in `SeverityDot.qml`; no colour chosen at a call site.
3. **Commands assembled in exactly one place** — the core's `build*Command()` functions;
   no flag, subcommand or path spelled in QML.
4. **A run token on every one-shot command**, because the `executable` engine treats its
   sources as a set.
5. **`kpackagetool6` for install**, with a plain-copy fallback into
   `~/.local/share/plasma/plasmoids/`.
6. **`Plasmoid.configuration` read in exactly one file**, and the representations are
   pure consumers (properties in, signals out).
7. **`unknown` is muted, never neutral**, and `Plasmoid.status` is not overridden.
8. **Docs-only testability**: the logic that matters is in a file a bare engine can run,
   so it is tested without Plasma — the harness is the reason both suites exist.

The per-invariant detail lives in [qml-shell-js-core](qml-shell-js-core.md) and
[severity-and-state-model](severity-and-state-model.md); this table only records that
both widgets agree.

## Points where the two widgets disagree

These are genuine differences, resolved rather than hidden:

- **Where severity is computed.** tuya hoists it into `main.qml` and passes one value
  down; docker calls the core function at each consumer. Both keep the decision in the
  core, so the invariant holds; tuya's hoist is preferable when one severity drives more
  than one consumer.
- **The meaning of the colour `neutral`.** tuya's neutral is a grey; docker's is orange.
  The vocabulary is shared; the palette is not. A widget picks one palette and maps the
  four meanings into it.
- **A fifth severity (`warning`).** tuya needs it for a linked bulb that is offline but
  retried; docker does not. Add `warning` only when a state is genuinely
  "attention, not failure, not merely off".
- **verified `executable`-engine version.** docker records plasma5support 6.7.4, tuya
  6.7.5. Same mechanism; the stamp is each widget's own measurement.

## Known gaps

- **Two widgets is a small sample.** The corpus is a distillation of *practice*, not of
  the KDE standard. Where a claim could not be verified from either codebase it is
  hedged in the doc that makes it.
- **Some claims are unverified and recorded as such** in their own docs: the KAuth-helper
  and `AuthDialog` privilege shapes, the exact `xgettext`/`msginit` flags, and the
  `KLocale`/Plasma-6 statement (see [privilege-and-polkit](privilege-and-polkit.md) and
  [i18n-gettext](i18n-gettext.md)).
- **tuya's version is authored in two places** — `metadata.json` (`0.4.2`) and
  `pyproject.toml` (`0.1.0`) — with no automation tying them together; a reader must not
  assume they agree.
- **docker's update check is one-directional**: a widget can learn a newer release
  exists, never that its own build is current, and the site's static version text is a
  second source of truth nothing guards (accepted debt in its own corpus).

## References

- [docs/project.md](../project.md) — the workspace-and-submodules slice, and where a change routes.
- [qml-shell-js-core](qml-shell-js-core.md) — the architecture both widgets implement.
- [severity-and-state-model](severity-and-state-model.md) — the shared severity model and the palette trade-off.
- [privilege-and-polkit](privilege-and-polkit.md) — the one widget with a grant, and the one without.
- [i18n-gettext](i18n-gettext.md) — the one widget with a catalogue, and the one without.
- [README.md](../../README.md) — the studio's own entry point and submodule list.
