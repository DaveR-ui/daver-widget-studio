---
last_updated: 2026-10-12
status: active
description: gettext in a Plasma 6 applet — the domain pinned to the plugin id (plasma_applet_ + KPlugin.Id), the i18n()/i18nc()/i18ncp() family and msgctxt context strings, the catalogue as source of truth compiled by msgfmt --check-format into a .mo shipped inside the package, the untranslated-build fallback, translated metadata keys, and the drift guard that keeps msgids alive.
tags: [i18n, gettext, translations, qml, metadata, locale, msgfmt]
version: 1.0
related: [widget-comparison, qml-shell-js-core]
---

# i18n with gettext

A Plasma applet translates its user-facing strings with the `i18n()` family, looked up
in a **gettext catalogue compiled into the package**. This doc is the rule, taken from
`tuya-bulb-widget` — **the only one of the two widgets with a gettext runtime**.
`docker-status-widget` has none: its user-facing *metadata* is translated, its QML
strings are English only. That asymmetry is real and is recorded below rather than
papered over.

## The domain is pinned to the plugin id

libPlasma looks an applet's catalogue up under a fixed domain name:

```
plasma_applet_ + KPlugin.Id
```

For `io.github.daver-ui.tuyabulb` that is
`plasma_applet_io.github.daver-ui.tuyabulb`. A mismatch between the domain and the id
silently disables translation — no error, just English. tuya pins the agreement in two
places and a test asserts it:

- the domain constant in `plasmoid/render-plasmoid.sh`
  ([render-plasmoid.sh](../../widgets/tuya-bulb-widget/plasmoid/render-plasmoid.sh)):
  `PLASMOID_I18N_DOMAIN="plasma_applet_io.github.daver-ui.tuyabulb"`;
- `test_i18n_domain_matches_the_plasmoid_id` in
  [test_plasmoid.py](../../widgets/tuya-bulb-widget/tests/test_plasmoid.py), which
  reads `metadata.json` and asserts `I18N_DOMAIN == "plasma_applet_" + KPlugin.Id`.

The skeleton's README names the same rule for a forked widget: the id is also the i18n
domain prefix.

## The `i18n()` family and context strings

Use the plain form for a bare string and the context form when the same English word
means different things (or needs a disambiguating hint):

| Call | Use |
|---|---|
| `i18n("Refresh now")` | a plain string |
| `i18nc("@title", "Tuya Bulb — %1", scopeLabel)` | a string needing context |
| `i18np` / `i18ncp` | singular/plural forms, with numbers |

The `msgctxt` in the `.po` is the literal context string (the `"@title"` / `"@info"` of
`i18nc`). In tuya's catalogue
([es.po](../../widgets/tuya-bulb-widget/plasmoid/translations/es.po)) you see both:

```po
msgctxt "@title"
msgid "Key %1"
msgstr "Tecla %1"

msgctxt "@info"
msgid "%1 key"
msgid_plural "%1 keys"
msgstr[0] "%1 tecla"
msgstr[1] "%1 teclas"
```

Plural entries carry `msgid` + `msgid_plural` + `msgstr[n]`, and the header declares
`Plural-Forms: nplurals=2; plural=(n != 1);` for Spanish. Consumers read a contextual
entry with `pgettext()` / `npgettext()` — the widget's own test does exactly this.

Keep all translation out of the pure-JS core: it carries no `i18n()` because it must run
under a bare engine (see [qml-shell-js-core](qml-shell-js-core.md)). The core returns
data; the QML layer, where the translation helper lives, composes the sentence.

## The catalogue is the source of truth; the `.mo` ships in the package

The `.po` is authored and reviewed; the compiled `.mo` is the machine artifact Plasma
loads. The shipping path is fixed:

```
contents/locale/<lang>/LC_MESSAGES/<domain>.mo
```

tuya compiles it at **render/install time**. `plasmoid_compile_locale()` in
render-plasmoid.sh loops over `plasmoid/translations/*.po` and runs, per language:

```bash
msgfmt --check-format -o "<staged>/contents/locale/es/LC_MESSAGES/plasma_applet_io.github.daver-ui.tuyabulb.mo" plasma/translations/es.po
```

Two deliberate properties of that call:

- **`--check-format` makes a malformed catalogue fail the render** instead of shipping
  silently broken.
- **The compiled `.mo` ships inside the package**, so `kpackagetool6` installs the
  translation with the applet — no separate install step.

### No gettext, no regression

If `msgfmt` is absent the plasmoid **still builds, untranslated**. The English `i18n()`
source strings are the fallback, so a machine without gettext gets a working English
widget rather than a failed build. `plasmoid_compile_locale()` returns early with a
one-line notice, and `test_render_without_a_catalog_stays_english` asserts the renderer
alone stages no `contents/locale/` tree at all.

The same fallback holds at runtime even with a catalogue present: an untranslated string
resolves to itself. tuya's test asserts `catalog.gettext("Some string not in the
catalog") == "Some string not in the catalog"`.

## Keep the catalogue honest: the drift guard

A `.po` entry whose `msgid` no longer appears in the QML is dead weight and hides a
renamed string that will never translate. tuya guards this with
`test_spanish_catalog_msgids_are_still_source_strings`, which asserts that **every
singular `msgid` in `es.po` is still a literal in some `contents/ui/*.qml` file**:

```python
missing = [m for m in msgids if f'"{m}"' not in qml_text]
assert missing == []
```

A second test, `test_spanish_catalog_compiles_and_translates`, actually runs the
compile and reads the `.mo` back with `gettext.GNUTranslations`, asserting a plain
string, a `@title`-context string, and two plural forms resolve — so the pipeline is
tested end to end, not just the text. It is skipped when `msgfmt` is unavailable.

## Metadata translations are a separate, smaller mechanism

A widget's *name and description* shown in "Add Widgets" are translated through
`metadata.json`, **not** the catalogue. The keys are suffixed with a language tag:

```json
"Name": "Docker Status",
"Name[es]": "Estado de Docker",
"Description": "Shows whether the Docker daemon is running, …",
"Description[es]": "Muestra si el demonio de Docker está corriendo, …"
```

This needs no `.po`, no `msgfmt`, and no domain — `docker-status-widget` ships it
([metadata.json](../../widgets/docker-status-widget/package/io.github.daver-ui.dockerstatus/metadata.json))
even though it has no gettext catalogue at all. So there are **two independent
translation surfaces**: applet metadata (suffixed keys, no tooling) and in-app strings
(`i18n()` + a compiled catalogue). A widget can have the first without the second.

Because docker has no catalogue, **its QML has no `i18n()` lookups translating anything
in practice** — every `i18n(...)` call falls back to its English source. That is an
honest state, not a bug: the widget was built English-first and its metadata is
translated. A reader comparing the two widgets must not conclude docker "does gettext".

## Commands

The command wired into the pipeline is the compile step:

```bash
msgfmt --check-format -o contents/locale/es/LC_MESSAGES/<domain>.mo translations/es.po
```

The standard gettext commands for *producing* a catalogue are these — **neither widget
wires them today**: the `es.po` is hand-authored and there is no `POTFILES`, no
`xgettext` target and no generation step in either repository. Recorded here as the
standard workflow, not as something this codebase does:

```bash
# 1. Extract msgids from the QML sources into a template.
xgettext --language=JavaScript --from-code=UTF-8 \
         --keyword=i18n --keyword=i18nc:1c,2 --keyword=i18np:1,2 --keyword=i18ncp:1c,2,3 \
         -o translations/plasma_applet_io.github.daver-ui.<id>.pot \
         contents/ui/*.qml contents/ui/config/*.qml

# 2. Start a catalogue for a language from the template.
msginit --locale=es --input=translations/<domain>.pot --output-file=translations/es.po

# 3. After editing, merge new strings into an existing catalogue.
msgmerge --update translations/es.po translations/<domain>.pot
```

(These flags are the conventional gettext invocation; they are **not** verified against
a live run in this repo — see the open gaps.)

## `KLocale` is not used in Plasma 6

The pre-Qt5 KDE configuration/localisation class `KLocale` is not part of Plasma 6
applet code; the `i18n()` family is the interface. Neither widget imports `KLocale` or
anything like it. *(This is stated as a platform fact; it is not exercised by a test in
either repo — see open gaps.)*

## The honest recommendation

**A brand-new widget should ship English first and add a catalogue only when a second
language actually matters.** English source strings are the fallback everywhere — in
the `.po` pipeline, at runtime, and in an untranslated build — so adding gettext later
is additive and cheap. Doing it early buys a maintenance surface (a separate `msgfmt`
toolchain requirement, a drift guard to keep green, a catalogue to keep in sync) that a
young widget does not need. Reuse the *shape* — pinned domain, shipped `.mo`, the
drift guard — when the second language arrives.

## Open gaps

- `xgettext` / `msginit` / `msgmerge` are the standard gettext commands and are
  documented above, but **neither widget uses them**; both maintain their catalogue by
  hand. The exact flags are not verified against a live run in this repo.
- The `KLocale` statement is a platform fact not covered by any test.
- Only singular `msgid` lines are drift-guarded; `msgid_plural`-only drift is not.
- docker's translated metadata is not covered by a drift guard either — a renamed
  `KPlugin.Name` would not fail its suite.

## References

- [es.po (tuya)](../../widgets/tuya-bulb-widget/plasmoid/translations/es.po) — a real catalogue.
- [render-plasmoid.sh](../../widgets/tuya-bulb-widget/plasmoid/render-plasmoid.sh) — the `msgfmt --check-format` compile and the pinned domain.
- [test_plasmoid.py](../../widgets/tuya-bulb-widget/tests/test_plasmoid.py) — the domain test, the drift guard and the compile/translate test.
- [metadata.json (docker)](../../widgets/docker-status-widget/package/io.github.daver-ui.dockerstatus/metadata.json) — translated metadata keys without a catalogue.
- [widget-comparison](widget-comparison.md) — the two widgets' i18n postures side by side.
