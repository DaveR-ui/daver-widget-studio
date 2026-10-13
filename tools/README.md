---
id: tools-readme
category: tools
tags: [tool, scaffolding, tokens, reference]
aliases: ["Tools README", "New Widget Tool"]
related: [create-a-new-widget, skeleton-tooling-slice, docs-corpus-slice]
version: 1.0
status: active
---

# Tools — the New-Widget Scaffolder

`tools/new-widget.sh` copies `templates/widget-skeleton/` and substitutes its two placeholder
tokens. It is the one tool the studio ships, and it scaffolds **by copy**, not by code generation.

## Problem

Starting a widget by hand means a `cp -r`, a `sed` per file, and no way to prove the substitution
covered everything: a token left behind reaches `metadata.json` as a literal string, a mistyped id
installs under the wrong applet id, and a template edited "just this once" poisons every later
scaffold. The tool turns that into one checked command that validates first, substitutes
everywhere, and proves both afterwards.

## Solution

A reference card for the script. The step-by-step walk-through — submodule registration, install,
round-trip — lives in [create-a-new-widget.md](../docs/protocols/create-a-new-widget.md) and is not
repeated here.

```
tools/new-widget.sh <widget-id> [--name <human name>] [--out <dir>] [--force]
tools/new-widget.sh -h        # or --help — print the usage block and exit 0
```

| Flag | Default | What it does |
|---|---|---|
| `<widget-id>` (positional, required) | — | the Plasma applet id. A second positional is rejected as an unexpected argument |
| `--name` | the id's **last dot-label with its first character upper-cased** — `io.github.daver-ui.mything` becomes `Mything` | the human-readable name written into the package |
| `--out` | `build/<widget-id>` under the studio root, resolved **from the script's own directory** (gitignored) | the target directory. An absolute path is used as given; a **relative** path resolves against the **caller's** working directory, not the studio root |
| `--force` | off | `rm -rf` the target first. Needed only when the target already exists **and is non-empty** |
| `-h` / `--help` | — | print the usage block, exit 0, write nothing |

**Input validation — everything is checked before a single byte is written:**

- the id must match `^[a-z][a-z0-9-]+(\.[a-z0-9-]+)+$` — lowercase reverse-DNS labels, each starting
  with a letter, at least one dot. The pattern is what keeps the installed package name, the config
  group and the i18n domain aligned;
- the name is trimmed first, then must be non-empty and contain **no double quote, no backslash, no
  backtick and no control character** (a newline is a control character). Those four would terminate
  the JSON or QML string literal the name is written into;
- `--name` and `--out` each require a value, an unknown option is refused, and the template
  directory must exist.

**What a rejection does:** it prints `new-widget: <reason>` to stderr, exits **1**, and writes
nothing — the target directory is not created. A rejected run leaves the tree exactly as it was.

**The token set — two placeholders, four landing sites:**

| Token | Where it lands | What it becomes |
|---|---|---|
| `@WIDGET_ID@` | `metadata.json` → `KPlugin.Id`; `install.sh` → `PLASMOID_ID` | the applet id Plasma registers, what `kpackagetool6` installs and removes, and the `plasma_applet_<id>` translation-domain prefix |
| `@WIDGET_NAME@` | `metadata.json` → `KPlugin.Name`; `contents/ui/main.qml` → `widgetName` | the human name, which `Plasmoid.title` and `toolTipMainText` both read — the label in "Add Widgets", on the panel and in the tooltip |

**The substitution discipline.** The whole tree is copied with `cp -a` and only the **copy** is
touched: `find` walks every regular file of the target (pruning `.git` and nothing else) and `sed`
replaces both tokens in place. The replacement value is escaped so `&`, `\` and the `|` delimiter
stay literal, which is what makes a name containing `&` safe. The template itself is only ever read.

**The two self-checks it runs afterwards:**

1. **No placeholder may survive.** A `grep -rIl` over the copy for either token; a survivor aborts
   the run, because a leftover token would reach the installed package as a literal.
2. **The template must be byte-identical before and after.** A sha256 digest of the template's file
   names and bytes is taken before the copy and recomputed afterwards; a mismatch aborts the run.
   This is the proof that nothing ever renders in place — a regression that did would fail loudly
   instead of poisoning every future scaffold.

It also re-asserts the executable bit on the copied `install.sh`, and finishes by printing the
resolved target, the id, the name and the next steps.

**The exit-code contract.**

| Exit | When |
|---|---|
| `0` | success — the scaffolded directory is complete and both self-checks passed. Also `--help` |
| `1` | any rejection: missing or malformed id, malformed name, a flag missing its value, an unexpected argument, an unknown option, a non-empty target without `--force`, a missing template, a surviving placeholder, or a template that changed during the run |

## When to use

- A genuinely new widget is being born — a new applet id that will become its own repository — and
  you want the skeleton copied with the id and the name already in the right places.
- You have just invalidated a previous scaffold (wrong id, wrong name, a hand-edit you cannot
  trust) and want a clean copy with the checks run for you.

## When not to use

- **Do not hand-substitute the tokens.** A value typed by hand after scaffolding is invisible to
  the post-condition that greps for leftovers. Re-run the tool instead.
- **Do not edit `templates/widget-skeleton/` in place.** The template is read-only by contract;
  the manifest check is there to catch exactly that, and a forked widget never receives later
  skeleton improvements anyway — copy-only is deliberate, and there is no merge path and no
  "update" command.
- **Do not use this tool to generate anything other than a KPackage skeleton.** There is no
  template engine and no hook for a second template; a shape that is not the skeleton belongs in a
  widget's own repository.
- **Do not use it to extend an existing widget.** Extending a widget is a change in that widget's
  own repo, not a scaffold.
- **Do not treat it as a build, test or install step.** It only writes a directory. Running the
  suite and installing are separate steps, and both happen inside the new tree.

## Examples

```sh
# the usage block, without touching anything
tools/new-widget.sh --help

# the common case: default target build/<id>, name defaulted to "Mything"
tools/new-widget.sh io.github.daver-ui.mything --name "My Thing"

# a target of your choosing — absolute, or relative to the shell you are in
tools/new-widget.sh io.github.daver-ui.mything --out /tmp/opencode/mything

# replace a non-empty target (destructive: the previous contents are removed)
tools/new-widget.sh io.github.daver-ui.mything --force
```

A rejection, and what it leaves behind:

```sh
$ tools/new-widget.sh BadId --name x --out /tmp/should-not-exist
new-widget: invalid widget id 'BadId': expected lowercase reverse-DNS labels, e.g. io.github.daver-ui.my-widget
$ echo $?
1
$ ls -d /tmp/should-not-exist
ls: cannot access '/tmp/should-not-exist': No such file or directory
```

## Common mistakes

- Assuming a relative `--out` resolves against the studio root. It resolves against the caller's
  working directory — run the tool from where you mean the output to land, or pass an absolute path.
- Passing `--force` without re-reading the resolved path. It is an `rm -rf` of whatever is there.
- Re-deriving the default name by hand and passing something else: the default is the last dot-label
  with its **first character** upper-cased, so `my-widget` defaults to `My-widget`, not `My-Widget`.
- Expecting `--force` to be needed for an existing but **empty** target. It is only consulted when
  the target is non-empty.
- Editing or renaming a token in the copy afterwards, or running the skeleton suite from the studio
  root instead of from inside the scaffolded tree.
- Assuming the copy will track the skeleton. It will not, and that is the designed behaviour.

## References

- [../docs/protocols/create-a-new-widget.md](../docs/protocols/create-a-new-widget.md) — the
  procedure this card serves: submodule registration, install, round-trip and follow-ups.
- [../templates/widget-skeleton/README.md](../templates/widget-skeleton/README.md) — the skeleton's
  own README: layout, token table, conventions and the "replace these first" list. Not duplicated
  here.
- [../docs/context/skeleton-tooling-slice.md](../docs/context/skeleton-tooling-slice.md) — the
  slice that owns this tool and its boundaries.
- [../docs/context/docs-corpus-slice.md](../docs/context/docs-corpus-slice.md) — the corpus this
  README is registered in.
- [daver-widget-studio](https://github.com/DaveR-ui/daver-widget-studio) — the studio repository
  this tool ships in.
