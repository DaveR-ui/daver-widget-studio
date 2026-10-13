---
last_updated: 2026-10-12
status: active
description: The narrowest-grant privilege discipline — how docker-status-widget grants exactly one systemd verb via a scoped polkit rule, why the grant is installed by a separate never-implicit command and never widened for stop, what a widget does instead when it has no privilege to grant (tuya has none), the alternative privilege shapes and their costs, and a checklist for deciding whether a new widget needs root at all.
tags: [privilege, polkit, security, sudo, systemd, grant, installer]
version: 1.0
related: [widget-comparison, severity-and-state-model]
---

# Privilege and polkit

A widget that only *observes* needs no privilege. A widget that *changes* system state
sometimes does — and then the whole design question is how small the grant can be. This
doc is the rule, distilled from `docker-status-widget` (which has a grant) and
`tuya-bulb-widget` (which has none). **Default answer: a new widget does not need root.**

## The narrowest-grant discipline

`docker-status-widget` wants one-click "Start Docker daemon" without a password. Rather
than escalate, it grants exactly what that needs, through a **polkit JavaScript rule**:
[polkit/49-docker-status-widget.rules](../../widgets/docker-status-widget/polkit/49-docker-status-widget.rules),
installed at `/etc/polkit-1/rules.d/49-docker-status-widget.rules`.

The rule returns `polkit.Result.YES` only when **all** of these hold, and
`NOT_HANDLED` otherwise:

| Gate | Lookup | Must be |
|---|---|---|
| Action id | `action.id` | `org.freedesktop.systemd1.manage-units` |
| Unit | `action.lookup("unit")` | `docker.service` |
| Verb | `action.lookup("verb")` | a member of `ALLOWED_VERBS`, which contains exactly `["start"]` |
| Session | `subject.local && subject.active` | both true — no remote/SSH, no inactive session |
| Group | `subject.isInGroup("wheel")` | true |

`NOT_HANDLED` hands the decision back to polkit's normal agent, so a denial shows up as
the ordinary password prompt rather than as a dead button. `ALLOWED_VERBS` is one verb
on one unit of one action id; the rule grants no ability to stop, restart, reload,
disable, mask or otherwise modify the unit, and nothing else on the system.

Two supporting decisions belong to the grant's correctness:

- **The verb check stays an array membership test.** Widening the grant means editing
  `ALLOWED_VERBS` deliberately; replacing the lookup with a wildcard is the one edit the
  privilege slice forbids outright. That edit is the review surface for the whole
  privilege model.
- **The `isInGroup` compatibility shim stays.** polkit ≥ 0.121 exposes `isInGroup()` as
  a method; older releases exposed it as a boolean property. The rule branches on
  `typeof subject.isInGroup === "function"`. Without the shim the rule can be silently
  dead on one of the two API generations — failing closed, but for the wrong reason.

### Rejected shapes, and why the rule won

The widget's own ADR-0004 records the three candidates and their trade-offs:

| Shape | Grant unit | Cost |
|---|---|---|
| `pkexec` per click | exactly one command | prompts **every** click — defeats the widget |
| A `sudoers` NOPASSWD entry | a whole binary | not auditable per action; far coarser than "start this one unit" |
| A scoped polkit rule | this action id, this unit, this verb, this session, this group | more setup; the grant is reviewable and narrow |

## Installing a grant is a separate, never-implicit command

The privileged step is never folded into the widget install. In
[install.sh](../../widgets/docker-status-widget/install.sh) the commands are split:

| Command | Privilege | What it does |
|---|---|---|
| `./install.sh install` | **none** | installs/upgrades the plasmoid for the current user; reversible |
| `./install.sh uninstall` | none | removes the plasmoid |
| `./install.sh install-polkit` | **`sudo` internally** | copies the rule to `/etc/polkit-1/rules.d/`, restarts polkit best-effort |
| `./install.sh remove-polkit` | `sudo` internally | removes the rule |
| `./install.sh status` | none | reports plasmoid, rule and unit state |

Installing the **widget itself is unprivileged and trivially reversible**; making a
privilege grant is a deliberate, visibly separate act that escalates with `sudo`
*inside* the installer. The collector can verify a live grant with the same probe the
installer prints:

```bash
pkcheck --action-id org.freedesktop.systemd1.manage-units \
        --process $$ --detail unit docker.service --detail verb start
```

## Stop is deliberately outside the grant

docker can also **stop** the daemon, and stopping it kills every running container. The
stop is offered, but:

- **The grant is not widened for it.** `ALLOWED_VERBS` stays `["start"]`, so starting
  is passwordless and stopping keeps polkit's interactive prompt. **The asymmetry is the
  feature**, not a gap: the benign action is silent, the destructive one asks.
- **Adding `"stop"` to the array is a security decision, not a fix.** It is the edit
  ADR-0007 exists to make deliberate.
- **Stop never fires on one click.** The first click *arms* a confirmation and shows a
  warning ("stopping the daemon stops every running container; press again to
  confirm"); only the second click runs `systemctl stop docker`. The arming expires on
  its own (five seconds), and a minimum dwell separates arming from confirming so a
  single double-click cannot arm and stop in one gesture.
- **There is no stop entry in the context menu.** A menu is still a one-click surface,
  so the button behind the confirmation is the only stop path.

An **arm-then-confirm button** for the destructive action is the pattern to reuse
whenever a widget's action is genuinely destructive: first click arms with a warning,
runs nothing; second click runs; the arming expires.

The widget's shutdown countdown (`systemctl poweroff`) is a third case: it is **outside
the grant by decision** and adds no rule. Unlike the docker stop it does **not** prompt,
because logind's default policy for `org.freedesktop.login1.power-off` is
`allow_active=yes` — a local active session powers off without authentication. Its
safeguards are the deliberate activation, a countdown floor, a live countdown and a
Cancel button, not a password gate.

## What a widget does instead when there is no privilege to grant

**tuya has no polkit rule, no `pkexec`, no helper binary and no `sudo` anywhere.** Its
widget shells out to a user-installed CLI (`tuya-bulb`) that owns the network protocol
and the local key; the user's own filesystem credentials (the config at `0600`, the
local key inside it) do the authorising. Nothing in the package escalates. This is the
default shape and the one to prefer: **put the privileged work in a user-owned tool and
let the widget run that tool as the user.**

The tests pin that shape indirectly rather than by naming a helper: tuya's
`test_qml_never_reads_files_or_shells_out_directly`, `test_js_module_is_pure_javascript_without_io`
and `test_plasmoid_tree_never_touches_secrets_or_a_config_flag` assert the widget has no
I/O, no shell access and no secret handling of its own
([test_plasmoid.py](../../widgets/tuya-bulb-widget/tests/test_plasmoid.py)). No test in
either widget asserts "no privileged helper exists" by name — that absence is a
documentation claim, not a machine-checked one (recorded as an open gap below).

## Alternative privilege shapes and their costs

If a widget genuinely must escalate, these are the shapes on the table. Cost is both
"size of the grant" and "how much the user notices".

| Shape | Grant size | Prompt behaviour | Notes |
|---|---|---|---|
| **User-owned CLI** (tuya) | none | none — the user's own credentials authorise | the default; no rule to review, no escalation surface in the widget |
| **Scoped polkit rule** (docker) | one action id + one unit + one verb + session + group | none when the five gates pass; normal prompt otherwise | the narrowest way to be passwordless; needs a separate `sudo` install step |
| **`pkexec` per click** | exactly one command | every click | zero setup, but the prompt defeats a one-click button |
| **`sudoers` NOPASSWD** | a whole binary | none | not auditable per action; the coarsest grant; avoid |
| **A KAuth helper** | a helper binary with declared actions, `kauth_*` | none if the helper's actions allow | the KDE-native alternative; a new binary to build, ship and keep in sync |
| **`AuthDialog`** | none beyond the dialog | a KDE password dialog on demand | at least a real KDE prompt rather than a raw shell prompt, but still per use |
| **A daemon** | whatever the daemon is granted | none | a service of its own to run and be down; the largest structural cost |

The two printed KDE-native options (`KAuth` helper, `AuthDialog`) are recorded here as
shapes, not as patterns either widget implements — neither repo contains a KAuth helper
or an `AuthDialog`, so their details are **not verified against this codebase** (open
gap below). What *is* verified is which shape each widget chose and why.

## Checklist for a new widget

1. **Does this widget actually need root?** Default answer: **no**. Observing state
   (`systemctl is-active`, `docker ps`) never does.
2. If it changes system state, can the change live in a **user-owned CLI the widget
   runs**? Prefer that.
3. If it must escalate, express the smallest grant you can: **one action id, one
   resource, one verb, one session kind, one group**. Copy the *shape*, never the scope.
4. **Keep the widget install unprivileged and reversible**; put the grant behind its own
   explicit, `sudo`-gated command that never runs implicitly.
5. **Never widen a grant for a destructive verb.** Make the destructive action
   *arm-then-confirm* instead, and let polkit prompt.
6. **Never replace a predicate with a wildcard**, and keep any API-compatibility shim so
   the rule cannot go silently dead.
7. Verify a live grant with `pkcheck`; remember a text test proves intent, not
   enforcement.

## Known gaps (carried honestly)

- No automated test exercises the polkit rule **at runtime** against polkit; the Node
  suite pins the rule *as text* and evaluates the captured predicate against a stub over
  a default-deny matrix. `pkcheck` remains the only runtime confirmation.
- The group is fixed to `wheel` with no configurable alternative; a user outside `wheel`
  gets a password prompt and no explanation from the widget.
- The `KAuth` helper and `AuthDialog` shapes are not implemented in either widget, so
  their descriptions above are unverified against this codebase.

## Common mistakes

- Folding the privilege grant into the widget install so it "just works".
- Widening `ALLOWED_VERBS` "for parity" so a destructive action becomes passwordless.
- Replacing the verb lookup with a wildcard.
- Assuming the confirmation is a security control — it stops an accident, not a
  determined caller; the password prompt (when there is one) is the only real gate.
- Assuming `systemctl poweroff` prompts — a logind default makes it passwordless on a
  local active session.
- Debugging a prompt by editing the widget instead of checking session locality and
  group membership first.

## References

- [polkit rule (docker)](../../widgets/docker-status-widget/polkit/49-docker-status-widget.rules) — the grant itself.
- [install.sh (docker)](../../widgets/docker-status-widget/install.sh) — the separate `install-polkit` / `remove-polkit` commands.
- [widget-comparison](widget-comparison.md) — the two privileges models side by side.
- [severity-and-state-model](severity-and-state-model.md) — how a daemon's state reads at a glance.
- [docs/project.md](../project.md) — the slice routing for a privilege change.
