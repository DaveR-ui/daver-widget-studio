---
id: merge-widget-docs
category: protocols
tags: [protocol, documentation, reference-corpus, generality]
aliases: ["Merge Widget Docs Protocol", "Merge Widget Documentation Protocol"]
related: [new-note-protocol, create-a-new-widget, adr-0002-keep-widgets-as-independent-repos, docs-corpus-slice, workspace-slice]
version: 1.0
status: active
---

# Merge Widget Docs Protocol

## Problem

A widget's own corpus is authoritative for that widget, and it stays with the widget. But a widget
doc sometimes teaches something a **future** widget will need. Copying it into the studio duplicates
it, and two copies drift; copying everything defeats the point of keeping the repos separate.

## Solution

Promote the rule, never the instance, and only when the text describes a rule.

**Two kinds of merge — only one is this protocol**
- [ ] **(a) A widget's own corpus staying in the widget** — the normal case. The studio never absorbs
      it; the widget keeps its own docs and the studio links to them.
- [ ] **(b) A generality being promoted into the reference corpus** — only when a widget doc teaches
      something a *future* widget needs. That is what this protocol governs.

**Pass the decision test**
- [ ] Does the text describe a **rule that holds for any widget**, or the config key, file path or
      command of **one** widget? If it names a specific widget's config key, it is not a generality
      yet.
- [ ] Promote the **RULE**, never the **instance**: write "a one-shot command carries a run token",
      not "<widget>'s `buildActionCommand()` appends `# plasma-run-N`".

**Land it where the generality lives**
- [ ] Write one new topic file under `docs/context/`, one topic per file, and register it behind
      [../context/context-index.md](../context/context-index.md).
- [ ] Use the mechanics of [new-note-protocol.md](new-note-protocol.md) for the file itself; the
      context-doc contract applies because the file lands in `docs/context/`.

**Keep the two copies from drifting**
- [ ] The **widget doc links back** to the studio doc — its own corpus points at the reference.
- [ ] The **studio doc never enumerates the widget's files**; it links out to the widget repository,
      never into a list of the widget's own docs.

**Review gate**
- [ ] From the studio root, `node validate.js` is green — the *whole* corpus must stay green, not
      just the new file.

## When to use

When a widget doc teaches a rule the next widget would otherwise re-derive: a contract, a boundary,
an invariant, a convention — stated as a rule, not as one widget's config.

## When not to use

- Do not merge to "keep everything together": collect-everything is the monorepo instinct the studio
  rejected in
  [../../adrs/adr-0002-keep-widgets-as-independent-repos.md](../../adrs/adr-0002-keep-widgets-as-independent-repos.md).
- Do not merge a symptom write-up: troubleshooting stays with the widget that has the symptom.
- Do not merge release or CI steps: they belong to the widget's own repo
  ([release-a-widget.md](release-a-widget.md)).

## Examples

The rule, not the instance:

```text
Widget doc (stays in the widget)              Studio doc (the generality)
docs/privilege/privilege-slice.md             docs/context/...
"49-docker-status-widget.rules grants         "A widget that needs one privileged action
 exactly systemctl start docker"              requests exactly that action id, unit and
                                              verb — never a broad grant."
```

The back-reference that keeps the pair honest (the widget points at the studio; the studio never
enumerates the widget):

```md
<!-- in the widget's own doc -->
The general rule for scoped grants lives in the studio's reference corpus:
https://github.com/<user>/daver-widget-studio/blob/main/docs/context/<topic>.md
```

## Common mistakes

- Copying a widget's README into the studio verbatim.
- Merging the same fact twice under two names — the validator's near-duplicate check will warn.
- Forgetting that the studio's corpus is the reference, not the index of every widget file.

## References

- [new-note-protocol.md](new-note-protocol.md) — how to write the file once you decide to promote.
- [create-a-new-widget.md](create-a-new-widget.md) — where the widget, and its corpus, originates.
- [../context/docs-corpus-slice.md](../context/docs-corpus-slice.md) — the corpus this promotion
  extends.
- [../context/workspace-slice.md](../context/workspace-slice.md) — the workspace where the widget
  repos live.
- [../../adrs/adr-0002-keep-widgets-as-independent-repos.md](../../adrs/adr-0002-keep-widgets-as-independent-repos.md)
  — why compare, never merge.
