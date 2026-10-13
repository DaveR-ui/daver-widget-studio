---
last_updated: 2026-10-12
status: active
description: The one model that makes a widget honest — state as data, severity as the single answer to "how bad is this", the four (plus one) severity levels, the state-to-severity-to-colour mapping from both widgets, the rule that unknown never renders as a healthy state, and the trade-off between theme colours and a fixed palette.
tags: [severity, state, model, qml, colours, status, honesty]
version: 1.0
related: [qml-shell-js-core, widget-comparison]
---

# Severity and the State Model

Two ideas make a status widget honest instead of decorative: **state as data**, and a
single **severity** that answers one question — *how bad is this?*. This doc is the
rule, distilled from `tuya-bulb-widget` and `docker-status-widget`.

## State as data

A widget's state is a small, closed vocabulary of strings, decided in the pure-JS core
from raw command output. It is not a colour and not a sentence.

| Widget | States | Where decided |
|---|---|---|
| tuya | `on`, `off`, `mixed`, `unknown`, plus `offline` for a linked bulb the mirror could not reach | `parseState()`, `parseMultiState()`, `bulbState()` in [tuyabulb.js](../../widgets/tuya-bulb-widget/plasmoid/io.github.daver-ui.tuyabulb/contents/ui/tuyabulb.js) |
| docker | `active`, `inactive`, `failed`, `unknown` | `parseDaemonState()` in [dockerstatus.js](../../widgets/docker-status-widget/package/io.github.daver-ui.dockerstatus/contents/ui/dockerstatus.js) |

Container states are a second vocabulary on the docker side (`running`, `exited`,
`created`, `restarting`, `dead`, `paused`, …), parsed by `parseContainers()` and mapped
by `containerSeverity()`.

**The load-bearing rule: a broken probe degrades to `unknown`, never to a healthy
reading.** Both parsers send anything they do not recognise — empty output, malformed
JSON, a state word outside the set — to `unknown`. A `systemctl is-active` value the
widget does not understand never reads as `inactive`, and a bulb reply whose `ok` is
not `true` never reads as `off`.

## Severity: one answer, decided once

Severity is a four-value vocabulary — `positive`, `neutral`, `negative`, `muted` — and
it is the **single source of truth for "how bad is this state"**. It is decided in the
core and nowhere else; the QML layer only maps the *severity* onto a colour
(`SeverityDot.qml`). See [qml-shell-js-core](qml-shell-js-core.md) for where that
mapping lives and why.

tuya adds a fifth value, `warning`, for exactly one situation: a **linked bulb that is
offline but still retried** — attention without failure. It is produced only by
`stateSeverity()`. docker has no `warning`; its four values cover everything it shows.
That asymmetry is real and deliberate: a `warning` is worth adding only when a state is
"not fine, but not an error and not merely off", which is what an unreachable-but-linked
bulb is.

### The rule that matters most: `unknown` is muted, never neutral

`neutral` (a stopped daemon, an off bulb) is a *known, fine* reading. `unknown` (the
probe could not tell) is not. Rendering `unknown` as `neutral` would make a broken probe
look like a healthy "stopped" — the exact lie a four-level model exists to prevent.
Both `SeverityDot.qml` files resolve their `default` branch to the muted colour and say
so in a comment. tuya states it again in `statusSeverity()`: *"unknown is never neutral
— an unreadable bulb must not read as 'off, and therefore fine'."*

## The mapping tables

**tuya** — state → severity → colour:

| State | Severity | Colour (`SeverityDot.qml`) |
|---|---|---|
| `on` | `positive` | `Kirigami.Theme.positiveTextColor` (green) |
| `off` | `neutral` | `Qt.alpha(Kirigami.Theme.textColor, 0.6)` (grey) |
| `mixed` (some on, some off) | `neutral` | grey — a legitimate reading, not a fault |
| `unknown` | `muted` | `Kirigami.Theme.disabledTextColor` |
| `offline` (linked bulb) | `warning` | `Kirigami.Theme.neutralTextColor` (amber) |
| any state with an error flag | `negative` | `Kirigami.Theme.negativeTextColor` (red) |

tuya's severity is driven by an explicit `isError` boolean, not by "is there feedback
text". A successful run that carries an informational note (a reachable bulb that
reports no power datapoint) stays `muted`, not red. A per-link failure is *data*: the
offline bulb is drawn inside its block as `warning`, and only a hard command failure
becomes a negative error.

**docker** — daemon state → severity → colour, against its fixed palette
(`DockerStatusPalette.qml`):

| State | Severity | Colour |
|---|---|---|
| `active` | `positive` | green `#55d69e` |
| `inactive` | `neutral` | orange `#ffad5c` |
| `failed` | `negative` | red `#ff737d` |
| `unknown` | `muted` | grey `#b3c1c8` |

docker's container states map as: `running` → positive; `exited`/`created` → neutral;
`restarting`/`dead`/`paused` → negative; anything else → muted. Compose groups, the
download feedback, the shutdown feedback and the update line each reuse the same
`SeverityDot`, so there is still one mapping and one colour source.

Note that the *word* `neutral` does not carry one fixed colour across the two widgets:
tuya's neutral is a grey, docker's neutral is orange. That is not a contradiction of
the model — the model fixes the *meaning* of each severity, and each widget resolves
meaning to colour against its own palette (see below).

## Theme colours vs a fixed palette

The two widgets make opposite, deliberate choices:

- **tuya follows the Kirigami theme.** Every colour is a `Kirigami.Theme.*` token, so
  the widget matches whatever desktop theme the user runs. This is the default to
  prefer: a panel widget that ignores the user's theme can look wrong.
- **docker paints a fixed dark palette** (`DockerStatusPalette.qml`), and switches
  Plasma's own frame off (`Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground`)
  because the popup paints its own card. This is a **sanctioned override** recorded as
  a decision (ADR-0011 in the widget's own corpus), not drift: the human operator asked
  for the look of a design mockup verbatim, including the Inter typeface, and a
  theme-following widget cannot reproduce a fixed palette.

The trade-off, and when to choose which:

| Approach | Gain | Cost |
|---|---|---|
| Theme colours (tuya) | always matches the user's desktop; no palette to maintain; accessible by default | the widget's look is "a function of somebody else's palette" — you cannot pin a brand or a mockup |
| Fixed palette (docker) | exact, reproducible look; a mockup can be reproduced token by token | the widget no longer follows the system colour scheme; contrast and accessibility become your job |

What is *invariant* either way: the palette is **neutral chrome** and never carries a
severity. Severity is still computed in the core; the colour still resolves in
`SeverityDot.qml` and nowhere else; and a second severity-to-colour mapping is
forbidden. A palette swap must not move the decision of *which* severity a state has.

## `Plasmoid.status` is deliberately not overridden

Both widgets leave `Plasmoid.status` alone. A failing probe is carried by the severity
dot, the tooltip and the popup banner — not by a panel icon that would nag forever. A
permanent configuration error must not turn the panel item into a permanent alarm; a
user who has not yet filled in a config should see a muted dot, not a red one. The
skeleton states the same rule in its `main.qml`.

## Rules to carry

1. **State is data, decided in the core from raw output**; degrade unrecognised output
   to `unknown`.
2. **Severity is decided in the core and nowhere else**; the QML layer only maps
   severity to a colour, and in exactly one file.
3. **`unknown` is `muted`, never `neutral`.** No reading must ever dress up as a
   healthy one.
4. **A failure is an explicit flag, not "there is text".** A success that carries a
   note stays muted.
5. **`Plasmoid.status` is not overridden**; a persistent config error must not nag the
   panel forever.
6. **A hard command failure is `negative`; per-item trouble can be data**, handled
   inside the item (tuya's `offline` → `warning`).
7. **A palette never carries severity.** If you adopt a fixed palette, keep the
   severity→colour switch as the one place colour is chosen.

## Common mistakes

- Treating `unknown` as `neutral` — a broken probe then reads as "stopped, and
  therefore fine".
- Deciding severity in QML, or mapping a state to a colour at a call site. Grey in two
  places is two sources of truth.
- Painting a success-with-a-note red because it has feedback text; use an error flag.
- Overriding `Plasmoid.status` for a configuration error, so the panel nags forever.
- Adopting a fixed palette and then letting a call site read a palette token directly
  instead of going through `SeverityDot`.

## References

- [qml-shell-js-core](qml-shell-js-core.md) — where severity is decided and where the colour mapping lives.
- [widget-comparison](widget-comparison.md) — the two widgets' severity models side by side.
- [dockerstatus.js](../../widgets/docker-status-widget/package/io.github.daver-ui.dockerstatus/contents/ui/dockerstatus.js) — `daemonSeverity()` and `containerSeverity()`.
- [tuyabulb.js](../../widgets/tuya-bulb-widget/plasmoid/io.github.daver-ui.tuyabulb/contents/ui/tuyabulb.js) — `statusSeverity()`, `stateSeverity()`, `linkSeverity()`.
- [SeverityDot.qml (docker)](../../widgets/docker-status-widget/package/io.github.daver-ui.dockerstatus/contents/ui/SeverityDot.qml) and
  [SeverityDot.qml (skeleton)](../../templates/widget-skeleton/contents/ui/SeverityDot.qml) — the single colour mapping.
