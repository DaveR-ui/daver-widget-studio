---
id: create-a-new-widget
category: protocols
tags: [protocol, widget, scaffolding, submodule]
aliases: ["Create a New Widget Protocol", "New Widget Protocol"]
related: [new-note-protocol, release-a-widget, merge-widget-docs, skeleton-tooling-slice, adr-0002-keep-widgets-as-independent-repos]
version: 1.0
status: active
---

# Create a New Widget Protocol

## Problem

A new widget starts as an empty directory and a mental checklist. The defects planted at scaffold
time — a malformed id, a hand-edited token, a suite run from the wrong tree, a widget that exists
only on this machine — are cheap to prevent now and expensive to unpick once the widget is installed
and published.

## Solution

Scaffold by copy, prove the copy, then register it. Do the steps in order; each one makes the next
checkable.

**Decide it is really a new widget**
- [ ] The thing is a new applet with its own id, its own repository, its own CI and its own
      dependencies. The studio's anti-goals are firm: **no shared runtime**, **no monorepo**, **no
      code generation**. If the change only extends an existing widget, it is a change in that
      widget's own repo, not a scaffold.
- [ ] A lesson the new widget teaches is not a reason to scaffold first — promote the rule, not the
      instance, once the widget exists ([merge-widget-docs.md](merge-widget-docs.md)).

**Pick the id and the name**
- [ ] The id is a Plasma applet id in reverse-DNS form and lowercase — the tool enforces the pattern
      `^[a-z][a-z0-9-]+(\.[a-z0-9-]+)+$`, e.g. `io.github.daver-ui.mything`. Every label starts with
      a letter; no uppercase, no underscore, at least one dot.
- [ ] The human name is the label shown in "Add Widgets", on the panel and in the tooltip — free
      text, except that the tool rejects a double quote, a backslash, a backtick, a newline or a
      control character. Omit `--name` and it defaults to the id's last label with its first
      letter upper-cased (`io.github.daver-ui.my-widget` becomes `My-widget`).

**Scaffold by copy**
- [ ] From the studio root: `tools/new-widget.sh <id> --name "<name>"`.
- [ ] `--out <dir>` chooses the target; the default is `build/<id>` under the studio root
      (gitignored). A **relative** `--out` resolves against your current directory, not the root.
- [ ] The tool **refuses to overwrite a non-empty target** ("target directory is not empty") unless
      you pass `--force`, which removes the target first. Treat `--force` as destructive: re-read the
      resolved path before you type it.
- [ ] The template is only ever read. The tool hashes it before and after the copy and dies if it
      changed, so a regression that rendered in place fails the run instead of poisoning the
      template. There is no template engine, no merge path and no "update" command — a forked widget
      never receives later skeleton improvements (deliberate).

**Inspect what was substituted**
- [ ] The tool greps the copy for a leftover token and dies if one survives; read the two landing
      files yourself all the same.

| Token | Where it lands | What it becomes |
|---|---|---|
| `@WIDGET_ID@` | `metadata.json` (`KPlugin.Id`), `install.sh` (`PLASMOID_ID`) | the applet id Plasma registers and `kpackagetool6` installs, and the translation-domain prefix |
| `@WIDGET_NAME@` | `metadata.json` (`KPlugin.Name`), `contents/ui/main.qml` (`widgetName`, used by `Plasmoid.title` and `toolTipMainText`) | the human name shown in "Add Widgets", on the panel and in the tooltip |

- [ ] Never rename a token by hand and never hand-substitute a value after scaffolding: **re-run
      `tools/new-widget.sh`**. A hand-substituted token is invisible to the tool's post-condition.

**Prove the copy**
- [ ] From **inside the scaffolded tree**, run the skeleton's suite: `node --test tests/*.mjs`. It
      is the only gate that must be green before you install.
- [ ] Run `qmllint` over `contents/` when it is available — a lint signal, not a substitute for the
      suite.

**Install and round-trip**
- [ ] `./install.sh` — it stages the package into `build/<id>/` and installs or upgrades through
      `kpackagetool6`, falling back to a plain copy into `~/.local/share/plasma/plasmoids/` when
      `kpackagetool6` is absent.
- [ ] Right-click the panel or desktop → "Add Widgets…" → search the name; confirm the widget loads
      and its action behaves.
- [ ] When it does not appear, restart plasmashell: `kquitapp6 plasmashell && kstart plasmashell`.

**Register the widget**
- [ ] Override `Website` and `BugReportUrl` in `metadata.json`: the skeleton points them at the
      studio so the pattern is visible; a real widget points them at its own repository.
- [ ] Publish the widget as **its own repository** — own README, own `.gitignore` with `build/`,
      own CI, own license.
- [ ] Declare it in the workspace as a submodule: `git submodule add -b <branch> <url> widgets/<name>`.
- [ ] Keep the two registration surfaces in sync: the `## The widgets` table in the root
      [README.md](../../README.md) and [docs/context/widget-comparison.md](../context/widget-comparison.md).
- [ ] From the studio root, `node validate.js` stays green
      ([new-note-protocol.md](new-note-protocol.md)).

## When to use

When a genuinely new widget is born — a new applet id, a new repository — not when an existing one
grows.

## When not to use

- Extending an existing widget's code, docs or CI: that is a change in the widget's own repo.
- Writing documentation: use [new-note-protocol.md](new-note-protocol.md); to promote a lesson into
  the reference corpus, use [merge-widget-docs.md](merge-widget-docs.md).
- A "new widget" that would import from another widget through a shared core: the studio has no
  shared runtime, and a widget cannot import anything from this repository
  ([../../adrs/adr-0002-keep-widgets-as-independent-repos.md](../../adrs/adr-0002-keep-widgets-as-independent-repos.md)).

## Examples

The full path, from scaffold to submodule:

```sh
# 1. scaffold by copy (default target: build/<id>, gitignored)
tools/new-widget.sh io.github.daver-ui.mything --name "My Thing"

# 2. prove the copy, from inside it
cd build/io.github.daver-ui.mything
node --test tests/*.mjs
./install.sh
# add it via "Add Widgets…"; restart plasmashell if it does not appear

# 3. publish the repo, then register it in the studio
git submodule add -b main https://github.com/<user>/mything.git widgets/mything
```

A custom output directory, and a deliberate `--force` (it destroys the previous target):

```sh
tools/new-widget.sh io.github.daver-ui.mything --name "My Thing" --out /tmp/opencode/mything
tools/new-widget.sh io.github.daver-ui.mything --force   # replaces build/io.github.daver-ui.mything
```

## Common mistakes

- Editing the template in place instead of the copy — the skeleton is read-only; re-run the tool.
- Hand-substituting the tokens, or renaming them — re-run `tools/new-widget.sh` instead.
- Running the tests from the studio root instead of from inside the scaffolded tree.
- Forgetting that the skeleton suite is the only thing that must be green before install.
- Treating the skeleton's placeholder probe as a real command: replace `buildStatusCommand()` and
  `buildActionCommand()` in `contents/ui/widget.js` first — the shipped probes are `printf`
  stand-ins.

## References

- [../../tools/new-widget.sh](../../tools/new-widget.sh) — the implementation this protocol drives.
- [../../templates/widget-skeleton/README.md](../../templates/widget-skeleton/README.md) — the
  skeleton's own token table, layout and "replace these first" list.
- [../../.gitmodules](../../.gitmodules) — the submodule declarations this step extends.
- [merge-widget-docs.md](merge-widget-docs.md) — folding a widget's lesson back into the corpus.
- [release-a-widget.md](release-a-widget.md) — cutting the release from the widget's own repo.
- [new-note-protocol.md](new-note-protocol.md) — the per-note check for anything you write here.
- [../../adrs/adr-0002-keep-widgets-as-independent-repos.md](../../adrs/adr-0002-keep-widgets-as-independent-repos.md)
  — why the widget stays its own repository.
- [../../adrs/adr-0001-adopt-widget-studio-structure.md](../../adrs/adr-0001-adopt-widget-studio-structure.md)
  — the reference-corpus + skeleton decision this protocol serves.
