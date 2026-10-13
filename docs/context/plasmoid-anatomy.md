---
last_updated: 2026-10-12
status: active
description: The anatomy of a Plasma 6 applet KPackage — metadata.json keys, the deliberately-absent X-Plasma keys, the contents/ tree, kcfg-to-cfg_ aliases, the config.qml source gotcha, PlasmoidItem representations, and the two package shapes (rendered template vs committed in place) with their install commands.
tags: [plasmoid, kpackage, plasma6, qml, metadata, anatomy]
version: 1.0
related: [context-index]
---

# Plasmoid Anatomy — a Plasma 6 Applet KPackage

A Plasma 6 applet is a **KPackage** of type `Plasma/Applet`: a directory with a
`metadata.json` at its root and a `contents/` tree beside it. Plasma discovers, loads and
configures the applet from that layout alone. This doc is the rule for writing one; the two
author widgets are the evidence (see [[workspace-slice]] for where they live).

## The package shape

```
<package-dir>/                     # one directory, named by the applet id
├── metadata.json                  # KPackageStructure + KPlugin block
└── contents/
    ├── config/
    │   ├── main.xml               # kcfg entries -> cfg_<entry> aliases
    │   └── config.qml             # ConfigModel registering the pages
    ├── icons/<id>.svg             # the app icon metadata.json points at
    ├── ui/
    │   ├── main.qml               # PlasmoidItem — the entry point KPackage finds
    │   ├── CompactRepresentation.qml
    │   ├── FullRepresentation.qml
    │   ├── SeverityDot.qml        # the single severity -> colour mapping
    │   ├── <core>.js              # the pure-JS core (".pragma library")
    │   └── config/ConfigGeneral.qml
    └── locale/<lang>/LC_MESSAGES/plasma_applet_<id>.mo   # optional compiled catalog
```

Both widgets use exactly this tree. Compare
[tuya's metadata.json](../../widgets/tuya-bulb-widget/plasmoid/io.github.daver-ui.tuyabulb/metadata.json)
and
[docker's metadata.json](../../widgets/docker-status-widget/package/io.github.daver-ui.dockerstatus/metadata.json).

## metadata.json

The root carries `KPackageStructure: "Plasma/Applet"` (the package type every
`kpackagetool6 --type Plasma/Applet …` command matches) and one `KPlugin` object.

| `KPlugin` key | Required | Value observed | Notes |
|---|---|---|---|
| `Id` | yes | `io.github.daver-ui.tuyabulb` / `io.github.daver-ui.dockerstatus` | reverse-DNS slug; the id every install/remove command takes |
| `Name` | yes | display name | localizable — docker adds `Name[es]` |
| `Description` | yes | one-line summary | localizable — docker adds `Description[es]` |
| `Icon` | yes | `/icons/<file>.svg` | package-root-relative; both bundle `contents/icons/<file>.svg` |
| `License` | yes | `MIT` | keep the widget's own license |
| `Version` | yes | `MAJOR[.MINOR[.PATCH]]` | the single version source (see [packaging-and-install](packaging-and-install.md)) |
| `Category` | recommended | `System Information` | both use it |
| `Authors` | recommended | list of `{ "Name": … }` | both list `DaveR-ui` |
| `Website` | optional | a project URL | docker sets it; tuya omits it |
| `BugReportUrl` | optional | an issues URL | docker sets it; tuya omits it |

**Website / BugReportUrl — the two widgets disagree, and setting them is preferable.**
Docker sets both; tuya omits both. The cost of omitting is concrete: Plasma's widget
information surface has no *website* or *report a bug* link to offer, so a user who hits a
defect has no path back to the author. A **public** widget should set both; only a purely
private experiment can afford to leave them out.

The minimum-API key is set explicitly:

```json
"X-Plasma-API-Minimum-Version": "6.0"
```

### The keys that must be ABSENT in Plasma 6

`X-Plasma-API` and `X-Plasma-MainScript` are **deliberately absent**. In the 6.x layout,
KPackage discovers the entry point from `contents/ui/main.qml`; declaring the old
`X-Plasma-API: declarativeappletscript` / `X-Plasma-MainScript` pair is a Plasma 5 idiom that
the 6.x loader does not expect. Tuya's package test asserts both absences
([test_plasmoid.py](../../widgets/tuya-bulb-widget/tests/test_plasmoid.py), `test_metadata_declares_a_plasma_applet`).

## The contents/ tree

### config/main.xml — the kcfg schema

`contents/config/main.xml` (docker, committed) or `contents/config/main.xml.in` (tuya, a
template — see below) declares a kcfg `<group>` of `<entry>` elements. Each entry's `name`
becomes a `cfg_<name>` property Plasma writes into and reads back from
`~/.config/plasma-org.kde.plasma.desktop-appletsrc`. A `<default>` is mandatory in practice;
`<min>`/`<max>` bound the `Int` entries.

```xml
<group name="General">
  <entry name="pollIntervalSeconds" type="Int">
    <label>How often the widget asks the bulb for its state, in seconds.</label>
    <default>20</default>
    <min>2</min>
    <max>300</max>
  </entry>
</group>
```

An entry with no value yet is a **blank** `<default></default>`, which is how an optional
setting is expressed. A `<label>` is user-facing text and is translatable.

### config.qml — registering the config page

`contents/config/config.qml` names the pages and points at their sources:

```qml
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "config/ConfigGeneral.qml"
    }
}
```

> **Gotcha — `source:` is resolved relative to `contents/ui/`, not to `contents/`.**
> The page itself lives at `contents/ui/config/ConfigGeneral.qml`, but the string here is
> `"config/ConfigGeneral.qml"`. Writing `"ui/config/ConfigGeneral.qml"` produces a page that
> Plasma cannot load. Docker's README records the same trap, learned the hard way.

The page is a `Kirigami.FormLayout` whose `cfg_<entry>` **aliases** bind the controls:

```qml
property alias cfg_pollIntervalSeconds: pollInterval.value
property alias cfg_iconName: iconName.text
```

The alias target must be a plain writable property; aliasing an expression is a silent no-op
on save. A setting carried by a combo box **cannot** be a `cfg_` alias, because Plasma's
initial write lands before the control initialises — docker keeps `cfg_cookiesBrowser` a plain
property and seeds the combo in its own `Component.onCompleted`.

### ui/main.qml — the entry point

`main.qml` is a `PlasmoidItem` (import `org.kde.plasma.plasmoid`). It owns the applet's
metadata and its two representations:

```qml
PlasmoidItem {
    Plasmoid.title: i18n("Docker Status")
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : null
    toolTipMainText: …
    toolTipSubText: …
    compactRepresentation: CompactRepresentation { … }
    fullRepresentation: FullRepresentation { … }
    Plasmoid.contextualActions: [ PlasmaCore.Action { … } ]
}
```

- `compactRepresentation` is what a **panel** draws: an icon plus a severity dot, nothing
  interactive.
- `fullRepresentation` is what the **desktop** draws, and what the panel **popup** shows when
  the compact icon is clicked.
- `preferredRepresentation` selects the full representation only on a planar (desktop)
  containment; in a panel it is `null`, so the compact representation is used and expands into
  the popup on click.

`main.qml` is the single place allowed to read `Plasmoid.configuration`; the representations
receive what they render as properties and emit intents as signals. Docker's `ConfigGeneral`
page and tuya's both call the *same* pure JS resolvers `main.qml` calls, so a config-page hint
can never disagree with the command the widget will run.

### SeverityDot.qml and the icon

`SeverityDot.qml` is the **one** file that maps a severity string onto a colour; every
representation consumes it. The severity vocabulary itself lives in the JS core. Tuya maps
onto `Kirigami.Theme.*` colours; docker maps onto a bundled `DockerStatusPalette.qml`, a
sanctioned fixed-palette override — either way the mapping exists once. The full severity
model is a sibling strategic doc (see [context-index](context-index.md)).

The `Icon` in `metadata.json` is the package's bundled app icon (a path under `contents/`);
the panel icon a user sees is a separate setting (`cfg_iconName` / `cfg_iconOn`). Do not
confuse the two.

## Two package shapes — rendered template vs committed in place

The repository has both, because the two widgets have different needs:

| | Tuya — rendered template | Docker — committed in place |
|---|---|---|
| package dir | `plasmoid/io.github.daver-ui.tuyabulb/` | `package/io.github.daver-ui.dockerstatus/` |
| kcfg | `contents/config/main.xml.in` with `@CLI_PATH@` | `contents/config/main.xml` (final) |
| build step | `plasmoid/render-plasmoid.sh` renders into `plasmoid/build/<id>/` | none |
| shipped bytes | the rendered staging dir | the committed dir itself |

**Rendered template** is right when the package must contain an **install-time value** the
author cannot know in advance — tuya bakes the absolute path of its virtualenv-installed CLI
into the kcfg default. `render-plasmoid.sh` rewrites the whole target from the template
(`rm -rf` then `cp -r`) so a stale file from a previous render cannot survive, and XML-escapes
before sed-escaping so a path containing `&`/`<`/`>` stays literal.

**Committed in place** is right when the package is **byte-identical to what ships**: docker
has no install-time substitution, so `package/<id>/` is the artifact and there is nothing to
render. This is the simpler default; reach for the template shape only when a value must be
computed at install time.

Either way: **never install an unrendered template, and never rewrite a template in place.**
The render lands in a staging directory inside the (gitignored) build tree, and the installer
installs from there (see [packaging-and-install](packaging-and-install.md)).

## Install, upgrade, remove

```sh
# install a package directory (the package dir, not the id)
kpackagetool6 --type Plasma/Applet --install   <package-dir>
# upgrade an already-installed applet
kpackagetool6 --type Plasma/Applet --upgrade   <package-dir>
# remove by id
kpackagetool6 --type Plasma/Applet --remove    <id>
# probe whether an id is installed (non-zero exit when it is not)
kpackagetool6 --type Plasma/Applet --show      <id>
```

**Plain-copy fallback** when `kpackagetool6` is absent — copy the package (or the rendered
staging dir) into the user's plasmoid store:

```sh
target="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/<id>"
rm -rf "$target"; mkdir -p "$target"; cp -r "<package-or-stage>/." "$target/"
```

The installer picks `--install` vs `--upgrade` by the `--show` probe, so re-running it is
idempotent. After installing or upgrading, the widget is added through the panel/desktop
**Add Widgets…** dialog. If it does not appear, the shell has not reloaded it:

```sh
kquitapp6 plasmashell && kstart plasmashell
```

Both installers print exactly this reminder.

## Known gaps

- **KPackage metadata keys beyond the ones observed are not documented here.** The table
  covers every key both author widgets use; other `KPlugin` keys exist in the Plasma
  ecosystem but were not exercised, so none is asserted.
- **`kpackagetool6 --show` exit semantics** are inferred from both installers using it as a
  branch condition, not measured from a clean/installed pair in a recorded test.
- **`plasmapkg2`** (the Plasma 5-era tool) is not used or covered; see
  [packaging-and-install](packaging-and-install.md) for why `kpackagetool6` replaces it.
- The exact Plasma version the two widgets were verified against (Plasma 6.7.4 /
  plasma5support 6.7.4) is the author's reference machine, not a supported floor.

## References

- [docs/project.md](../project.md) — the studio's entry point and routing.
- [workspace-slice](workspace-slice.md) — where the two evidence widgets live.
- [packaging-and-install](packaging-and-install.md) — the version/install/release lifecycle.
- [executable-dataengine](executable-dataengine.md) — how `main.qml` reaches a shell.
- [testing-a-plasmoid](testing-a-plasmoid.md) — how the package's invariants are asserted.
