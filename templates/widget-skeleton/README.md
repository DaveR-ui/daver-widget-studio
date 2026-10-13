# Widget Skeleton

A working, copyable KDE Plasma 6 applet — the starting point every new widget in this
studio is forked from. It is a **template**: it lives under the studio's `templates/`,
is never installed from there, and is copied out by `tools/new-widget.sh`.

What it demonstrates, end to end and with a passing test suite:

- a real KPackage (`Plasma/Applet`, Plasma 6) that installs and adds as a widget;
- a **pure-JavaScript core** (`.pragma library`) that a bare JavaScript engine can execute;
- a QML shell that reaches a shell only through the `plasma5support` `executable` engine, with a run token on every one-shot command;
- a single severity mapping, so no state is mapped onto a colour twice;
- a zero-dependency Node suite that evaluates the shipped core bytes in `node:vm`.

## Copy it

```bash
tools/new-widget.sh <widget-id> --name "<human name>" [--out <dir>] [--force]
```

```bash
tools/new-widget.sh io.github.daver-ui.my-widget --name "My Widget" --out build/my-widget
```

The tool copies this whole tree, substitutes the two tokens below in every regular
file, and prints the next steps. It never writes into `templates/widget-skeleton/`.

## Tokens

The scaffolder copies this tree and substitutes two placeholders in every regular file
of the copy. The table records each placeholder and where it lands — and because a
scaffolded copy has already been through the tool, its first column shows the **value
that was written**, not the placeholder the skeleton ships.

| Placeholder (resolved in a copy) | Where it lands | What it becomes |
| --- | --- | --- |
| `@WIDGET_ID@` | `metadata.json` (`KPlugin.Id`), `install.sh` (`PLASMOID_ID`) | the applet id: what Plasma registers, what `kpackagetool6` installs, and the i18n domain prefix (`plasma_applet_<id>`) |
| `@WIDGET_NAME@` | `metadata.json` (`KPlugin.Name`), `contents/ui/main.qml` (`widgetName`, used by the panel title and the tooltip) | the human name shown in the "Add Widgets" list, on the panel and in the tooltip |

The id must be reverse-DNS shaped (lowercase labels separated by dots, e.g.
`io.github.daver-ui.my-widget`); the name may carry any character that is safe inside
a JSON string and a QML string literal — the tool rejects a name containing a double
quote, a backslash, a backtick or a control character **before** anything is written,
which is what makes the substitution safe in both contexts.

`metadata.json` also ships `Website` and `BugReportUrl` pointing at the studio, so
the pattern is visible. **A real widget overrides both with its own repository** (that
is where `docker-status-widget` points them).

## Run the test suite

```bash
cd templates/widget-skeleton && node --test tests/*.mjs
```

Node's own runner, zero dependencies. The suite reads the shipped
`contents/ui/widget.js`, strips the `.pragma library` line and evaluates the exact
bytes in a bare V8 context — no Plasma, no QML, no display. Run it from the package
directory, as above; the harness resolves the core relative to its own URL, so it
works from any working directory.

## Install it

```bash
./install.sh             # install or upgrade (default)
./install.sh uninstall   # remove
```

The script resolves every path from its own directory, stages the package into
`build/<id>/`, and installs through `kpackagetool6` — falling back to a plain copy in
`~/.local/share/plasma/plasmoids/` when `kpackagetool6` is absent. Then right-click the
panel or desktop → **Add Widgets…** → search the widget's name. If it does not appear:
`kquitapp6 plasmashell && kstart plasmashell`.

`build/` is staging output — add it to the new repository's `.gitignore`.

## Conventions the skeleton encodes

- **The pure-JS core has no QML types and no I/O** — no process, no file, no network.
  That is what lets a bare JavaScript engine execute it, and it is asserted by the
  suite. It is written in ES5 style (`var`, `function`) on purpose.
- **Commands are assembled in exactly one place**: the `build*Command` functions in
  `contents/ui/widget.js`. `main.qml` is the only file that reads
  `Plasmoid.configuration` and the only file that assigns a command to a data
  source, and it never spells a flag, a subcommand or a path.
- **Every one-shot command carries a run token**, because the `executable` engine
  treats `connectedSources` as a *set*: assigning an identical command string twice is
  a no-op, so a second click would silently do nothing.
- **Severity is decided in exactly one file.** `widget.js` maps a state onto
  `positive` / `neutral` / `negative` / `muted`; `SeverityDot.qml` is the only place a
  severity becomes a colour; the representations receive the severity and map nothing
  themselves.
- **The payload contract is documented where it is parsed**: the state word on the
  first line, one detail per line after it, unknown words degrading to `unknown`.
- **Config values are plain properties**. A setting carried by a combo box cannot be a
  `cfg_*` alias (Plasma's initial write lands before the control initialises), so
  `cfg_panelIcon` is a plain property seeded in the combo's `Component.onCompleted`.
- `source:` in `contents/config/config.qml` resolves relative to `contents/ui/`, not
  to `contents/`.

## Layout

```text
templates/widget-skeleton/
├── metadata.json                  # KPackageStructure: Plasma/Applet, @WIDGET_ID@, @WIDGET_NAME@
├── install.sh                     # install / uninstall, stages into build/<id>/
├── contents/
│   ├── config/
│   │   ├── main.xml               # kcfg entries -> cfg_* aliases
│   │   └── config.qml             # the config page (source: resolves under contents/ui/)
│   ├── icons/widget.svg           # the bundled app icon (Icon: /icons/widget.svg)
│   └── ui/
│       ├── main.qml               # PlasmoidItem: configuration, polling, commands, state
│       ├── CompactRepresentation.qml  # panel icon + severity dot
│       ├── FullRepresentation.qml     # popup: state, detail list, one action, feedback
│       ├── SeverityDot.qml        # the single severity -> colour mapping
│       ├── widget.js              # pure logic, unit tested in Node
│       └── config/ConfigGeneral.qml   # config page
└── tests/widget.test.mjs           # node --test, zero dependencies
```

## Replace these first

1. `buildStatusCommand()` and `buildActionCommand()` in `contents/ui/widget.js` — the
   shipped probes are `printf` stand-ins, so a fresh install runs anywhere and clicks
   nothing dangerous. Keep the two builders as the only command surface, keep the
   action guard, and keep the run token.
2. The state vocabulary (`STATE_*`) if your domain does not read as
   active/inactive/failed/unknown — and `severityFor()` with it.
3. `metadata.json`: `Website`, `BugReportUrl`, `Description`, `Icon`, and the author.
4. `contents/icons/widget.svg` with your own icon.
5. The panel icon list in `ConfigGeneral.qml`, if the defaults are not sensible.
6. `LICENSE` — the skeleton is MIT, like the studio; your widget may choose its own.

Full procedure: `docs/protocols/create-a-new-widget.md` in the studio.
