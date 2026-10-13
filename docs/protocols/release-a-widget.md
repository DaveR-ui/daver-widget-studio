---
id: release-a-widget
category: protocols
tags: [protocol, release, widget-repo, version]
aliases: ["Release a Widget Protocol", "Widget Release Protocol"]
related: [create-a-new-widget, merge-widget-docs, workspace-slice, adr-0002-keep-widgets-as-independent-repos]
version: 1.0
status: active
---

# Release a Widget Protocol

## Problem

The studio has no release, no version and no build, so "release a widget" must not be run from here.
A version can be authored in two files, a widget's own gate can be run from the wrong tree, and a
repository rename silently orphans every installed copy that carries the old address as a constant.

## Solution

Cut the release from the widget's **own** repository. Every step runs there, never at the studio
root.

**Bump the version where it is authored — exactly once**
- [ ] The version is authored in exactly one place: `metadata.json` → `KPlugin.Version`. Bump it
      there and nowhere else.

**Regenerate everything derived from it**
- [ ] If the widget publishes a Pages release site, regenerate its manifest from `metadata.json` so
      the version is still authored once. `docker-status-widget` does this with
      `node .github/scripts/sync-manifest.mjs --write` (its CI runs the `--check` form).

**Run the widget's own gate — from inside its own repo**
- [ ] `node --test tests/*.mjs`, `qmllint`, and the widget's own docs validator
      (`node docs/validate.js` for `docker-status-widget`). Never from the studio root: the studio's
      `validate.js` measures the studio's corpus, not the widget's.

**Commit, push, publish**
- [ ] Commit with a `V x.y.z` label (convention), push, then let the widget's own CI publish.

**Re-install on this machine**
- [ ] `./install.sh` upgrades the local install through `kpackagetool6 --upgrade`.

**Keep the repo name and the published URL STABLE**
- [ ] The repository name and the published URL are constants inside the shipped widget: a
      `metadata.json` `Website`/`BugReportUrl`, and a fixed manifest URL (`docker-status-widget`'s
      `UPDATE_CHECK_URL`). Renaming or moving a widget repo breaks installed copies that will never
      learn the new address.

**The studio's registration duty after a release**
- [ ] Move the submodule pointer deliberately: `git submodule update --remote widgets/<name>`.
- [ ] Review the `## The widgets` table in [README.md](../../README.md) and
      [docs/context/widget-comparison.md](../context/widget-comparison.md) for anything the release just changed.

## When to use

Whenever a widget ships a release — from its own repository.

## When not to use

Releasing the studio itself: there is no studio release, version or build. Editing the studio's own
docs is [new-note-protocol.md](new-note-protocol.md); folding a widget lesson back in is
[merge-widget-docs.md](merge-widget-docs.md).

## Examples

`docker-status-widget` is the full evidence: `metadata.json`'s `KPlugin.Version` is the single source
of the version; `site/latest.json` is generated from it by `.github/scripts/sync-manifest.mjs`; and
`.github/workflows/ci.yml` runs `test`, `qmllint` and `docs` inside the widget's own repo.
`tuya-bulb-widget` has no Pages site — it has no second place to publish a version, so its release is
the bump, the gate and the push.

```sh
# from inside the widget's own repository — never from the studio root
# (widgets/<name>/ is the widget repo's checkout)

# 1. bump KPlugin.Version in the package metadata (the single source)
$EDITOR package/io.github.daver-ui.dockerstatus/metadata.json

# 2. regenerate the published manifest from that source (widgets with a release site)
node .github/scripts/sync-manifest.mjs --write

# 3. the widget's own gate
node --test tests/*.mjs
qmllint package/io.github.daver-ui.dockerstatus/contents/ui/*.qml
node docs/validate.js

# 4. commit, push, let the widget's CI publish
git commit -am "V 0.5.1"
git push
./install.sh                       # upgrade the local install (kpackagetool6 --upgrade)
```

Back in the studio, after the release:

```sh
git submodule update --remote widgets/docker-status-widget   # move the pointer deliberately
```

## Common mistakes

- Bumping the version in two files — `metadata.json` is the only author; a manifest is generated.
- Releasing from the studio root: a widget's tests and CI run in its own repo.
- Forgetting the manifest regeneration — the committed copy goes stale and the widget's CI fails.
- Renaming a widget repo — installed copies carry the old address as a constant.

## References

- [create-a-new-widget.md](create-a-new-widget.md) — the repo this release runs in.
- [merge-widget-docs.md](merge-widget-docs.md) — what to do if the release taught a generality.
- [../context/workspace-slice.md](../context/workspace-slice.md) — the submodule pointer this step
  bumps.
- [../../adrs/adr-0002-keep-widgets-as-independent-repos.md](../../adrs/adr-0002-keep-widgets-as-independent-repos.md)
  — why each widget owns its own release cadence.
