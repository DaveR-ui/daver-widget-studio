---
last_updated: 2026-10-12
status: active
description: The plasma5support executable DataSource contract — connect/disconnect, payload fields, the connectedSources set semantics that make an identical command not re-run, the run-token trick that makes a repeated one-shot re-run, why the JS core never touches I/O, poll-interval sizing and unknown as first-class data.
tags: [plasma5support, dataengine, executable, datasource, shell, polling]
version: 1.0
related: [context-index]
---

# The Executable Data Engine

A plasmoid does not run processes itself. It asks the `org.kde.plasma.plasma5support`
`DataSource` with `engine: "executable"` to run a shell command and hand back the result.
That engine is the whole contract between the QML shell and a shell.

## The source

```qml
import org.kde.plasma.plasma5support as P5Support

P5Support.DataSource {
    id: statusSource
    engine: "executable"
    interval: root.pollEnabled ? root.effectivePollIntervalMs : 0
    connectedSources: root.pollEnabled ? [root.statusCommand] : []

    onNewData: (sourceName, data) => {
        root.applyStatus(data["stdout"], data["stderr"], data["exit code"]);
    }
}
```

- `connectedSources` is the **list of command strings the source runs**.
- `interval` is the milliseconds between runs; `0` disables repetition (a one-shot).
- `onNewData(sourceName, data)` is called once per completed run, with `sourceName` being the
  full command string that ran.

## Connect, disconnect and the payload

| Group | Fields | Meaning |
|---|---|---|
| Addressing | `connectedSources` | the commands to run — an **assignment**, not an append |
| Payload | `stdout`, `stderr`, `exit code`, `exit status` | the run's result, delivered to `onNewData` |
| Cadence | `interval` | ms between runs; `0` disables repetition (quantised to roughly a second) |
| Lifecycle | `connectedSources = []` | disconnect — no further `onNewData` |

The payload values arrive **as strings** (convert before comparing), and the engine normalises
nothing: a consumer calls its own `normalizeOutput()` to collapse CRLF, stray whitespace and
`null`. `stderr` can be empty on a failure, so the caller owns the fallback message. A source
is stopped by assigning `connectedSources = []`; a binding that evaluates to `[]` is the
mechanism a poller uses to disconnect itself while its precondition is false.

### One event, at exit — not a stream

A long one-shot delivers **exactly one** `onNewData`, at process exit, carrying the whole run
plus the exit code. A multi-second silence in the middle produces no event at all. That is why
a download row shows a busy indicator instead of a progress bar, and why a consumer treats the
event that carries `exit code` as the end of the run while ignoring any event without it
(defence against a future engine that streams).

## Set semantics — the trap that shapes the design

`connectedSources` is treated as a **set**, so assigning an *identical command string* twice
is a no-op: the command is **not re-executed**. Measured against plasma5support 6.7.4/6.7.5:

| Action | `onNewData` events |
|---|---|
| `connectedSources = ["echo A"]` | 1 |
| `connectedSources = ["echo A"]` again | **0** |
| `connectedSources = []` then `["echo A"]` | 1 |
| `connectedSources = ["echo A # run1"]` then `["echo A # run2"]` | 1 each |

The last row is the fix: **append a unique trailing shell comment**. The run-token helper does
exactly that:

```js
function withRunToken(command, token) {
    var safeToken = String(token).replace(/[\r\n]/g, "");
    return command + " # " + RUN_TOKEN_PREFIX + safeToken;   // " # plasma-run-7"
}
```

Each assignment is now a distinct source, so a one-shot re-runs. Two more consequences:

- The reply arrives with the **whole command string** — token comment included — as its
  `sourceName`, so the token is recovered from the string (`runTokenFromSource`), which is how
  a reply is traced back to the target that asked for it.
- Because the trick appends a **shell comment**, it is safe **only for command strings the
  widget builds itself** — fixed constants, or a sanctioned builder's output. **Never apply it
  to a command supplied by configuration.** A value that could end its own line could run
  whatever follows the `#`.

A stale-reply rule rides the token: the newest dispatch for a target wins, compared by
monotonic token and never by arrival order, so a slow command cannot roll its target back.

## Why the JS core never touches I/O

The logic file is a `.pragma library` module with **no QML types and no I/O**: it runs a
process nowhere, reads a file nowhere, talks to the network nowhere. That is what lets a bare
JavaScript engine execute it and its tests exercise what ships (see
[testing-a-plasmoid](testing-a-plasmoid.md)). **Processes belong in the QML layer, and the QML
layer reaches a shell only through the builders.**

Concretely:

- **Commands are assembled in exactly one place** — a single `build*Command` per command
  family, never inline in QML. Tuya's `main.qml` contains no command literal at all; its
  package test fails if one appears.
- A builder returns **`""`** for anything it will not run (an unrecognised action, an empty
  required value). The empty string is the contract *"there is no command"*; the caller refuses
  it before it reaches the engine, so an invalid choice can never be interpolated into a
  command.
- Every interpolated value goes through a `shellQuote()` helper (single quotes, an embedded
  quote closed and reopened as `'\''`), so a value can never end the quoting itself.

### The CLI-interface variant

Tuya's widget never speaks the device protocol and never reads the config: it runs the
installed CLI in JSON mode and parses the reply.

```js
function buildStatusCommand(cliPath, device) {
    return shellQuote(resolveCliPath(cliPath))
        + " --no-notify --format json"
        + deviceArgument(device)
        + " status";
}
```

All key handling, retries and exit-code vocabulary stay in the tested CLI; the widget holds no
secrets — it never reads the config file and never passes a `--config` flag. `--no-notify` is
deliberate: the engine captures `stdout`, so without it the CLI would notify on every poll.
`--device=<value>` binds the value to the flag, so a selector beginning with `-` is not read
as another option. The exit-code contract is a **cross-process** contract, so the widget
duplicates the CLI's numbered codes and maps each to a user-facing sentence rather than
showing a bare number.

## Exit code, stderr and a session's shape

- The `exit code` is the run's verdict; anything non-zero is a failure the user must see. A
  one-shot that surfaces a failure prints `stderr` verbatim (or a generic fallback when it is
  empty), so a denial is never swallowed.
- Tuya additionally maps a fixed vocabulary of exit codes to canned causes (unreachable bulb,
  bad local key, missing config, wrong permissions, `126` not-executable / `127` not-found
  from the shell itself), and appends any detail the CLI printed unless it merely repeats the
  cause.
- A **partial** run is its own code (`10`): some members succeeded, some failed. It is a real
  error **and** carries a full payload, so the caller shows which members made it and can offer
  a retry instead of a blanket failure.

## Sizing the poll interval

Set the interval above the **worst-case command duration** so polls never overlap.

- Tuya polls the CLI, whose worst case against an unreachable bulb is about **12 s**
  (`timeout 3 s`, `retries 1`), so its default interval is **20 s**.
- Docker polls the cheap probe (`systemctl is-active docker`, a few ms) every **3 s**, and
  polls `docker ps` **only while the daemon is up**, because against a dead daemon it blocks
  on the socket timeout.

Reads are read-only and idempotent, so a slow cycle overlapping the next is benign. Only a
**scope-wide write** pauses the poller (to avoid the next read misreading a half-applied
write); a per-row or per-key write never does.

## `unknown` is first-class data

A probe that cannot read a state is not "off, and therefore fine". The engine hands back a
successful run whose payload says nothing useful — tuya's CLI exits `0` with `state: "unknown"`
when the bulb is reachable but reports no power datapoint. That is a **muted informational
note, not a failure**; treating it as an error would paint a healthy bulb red on every poll.
Docker's `systemctl is-active` unrecognised output degrades to `DAEMON_UNKNOWN`, never to
"stopped". In both, `unknown` maps to *muted*, and muted is never neutral.

## Known gaps

- **All engine behaviour here is probe evidence**, measured in one session against
  plasma5support 6.7.4/6.7.5 on the author's reference machine; it is not reproducible by a
  committed test. Docker records the measurements in
  [data-engine-contract.md](../../widgets/docker-status-widget/docs/status/data-engine-contract.md).
- **The interval quantisation to ~1 s** is asserted only as "roughly"; exact rounding is not
  characterised.
- **A hypothetical streaming engine is handled defensively** (accumulate chunks, ignore events
  without an exit code) but no streaming engine was observed, so that path is untested against
  a real engine.

## References

- [plasmoid-anatomy](plasmoid-anatomy.md) — how `main.qml` exposes the sources to representations.
- [testing-a-plasmoid](testing-a-plasmoid.md) — testing the builders without a running Plasma.
- [../../widgets/docker-status-widget/docs/status/data-engine-contract.md](../../widgets/docker-status-widget/docs/status/data-engine-contract.md)
  — the measured contract sheet this doc distils.
- [../../widgets/tuya-bulb-widget/docs/context/kde-integration.md](../../widgets/tuya-bulb-widget/docs/context/kde-integration.md)
  — the CLI-interface variant in full.
