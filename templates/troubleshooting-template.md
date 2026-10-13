---
id: troubleshooting-template
category: templates
tags:
- template
- troubleshooting
- symptoms
aliases:
- Troubleshooting Template
related:
- document-template
- ui-inventory-template
version: 1.2
status: active
---

<!-- Vendored from documentation-onrails v1.4 (https://github.com/DaveR-ui/documentation-onrails).
     Contract and checks byte-identical in behaviour to upstream; only the reference links were
     re-pointed so they resolve inside this repo. -->

# Troubleshooting Template

## Problem

Failures recur verbatim — same error string, same hunt. When root causes live as prose buried in
slice docs, the next reader greps the error text, finds nothing, and re-diagnoses from zero.
Symptom-keyed sheets make a once-diagnosed failure findable by the exact string that woke someone up.

## Solution

Two shapes, one interplay rule. The **quick-ref sheet** is symptom-keyed: each entry is an H2 whose
text *is* the exact symptom string, carrying `**Context:**` → `**Root cause:**` → `**Fix:**` →
`**Reference:**`, where Reference points at a deep-dive. The **deep-dive spoke** unpacks one failure
class: Diagnosis summary, Anatomy of the failure (a File/Symbol/Role checkpoint table), Debug &
verify steps. The interplay rule: the entry point's Common Lookups table
([guideline 06](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/06-project-md.md)) routes exact symptom strings to these headings, the
folder's hub lists the sheet, and the write-up lives in EXACTLY ONE place — the sheet. The symptom
heading is a contract: the string doubles as grep pattern and routing key. The body shape is a
contracted exception under [02 §2](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/02-document-contract.md); the frontmatter is the
standard note contract. Rationale: [ADR-0002](https://github.com/DaveR-ui/documentation-onrails/blob/main/adrs/adr-0002-doc-classes-expansion-2026-09-07.md).

## When to use

When a failure has been diagnosed once and can plausibly recur — a build break, a runtime error, a
behavior that surprises users the same way every time. One quick-ref sheet per area; a deep-dive
spoke only where the anatomy will not fit four fields.

## When not to use

Conceptual explanation (that is a plain note); one-off incidents with no recurrence risk (git holds
them); root causes pasted into `project.md`'s Common Lookups — the table routes, it does not hold;
speculative entries for failures nobody has hit yet (an untested fix is folklore).

## Examples

Quick-ref sheet — entries keyed by the verbatim symptom:

```markdown
# <Area> Troubleshooting — Quick Ref

## ECONNREFUSED on every internal call after the proxy change
**Context:** service-to-service calls routed through the sidecar proxy.
**Root cause:** the config rewrite dropped the upstream port mapping.
**Fix:** restore the mapping, restart the sidecar, re-run the smoke check.
**Reference:** proxy-failure-deep-dive.md — the anatomy and why the rewrite lost it.

## build fails: "Module not found: payments/config"
**Context:** any build right after a folder rename in the payments area.
**Root cause:** a stale barrel import survived the rename.
**Fix:** update the import path; the rename protocol now catches this.
**Reference:** none
```

Deep-dive spoke — one failure class, unpacked:

```markdown
# Proxy ECONNREFUSED — Deep Dive

## Diagnosis summary
What fails, why it fails that way, and when this became understood. One paragraph.

## Anatomy of the failure
| File | Symbol | Role |
|---|---|---|
| proxy/config.ts | upstreamPort | reads the port mapping |
| proxy/route.ts | resolveUpstream | silently defaults on miss |

## Debug & verify
1. Reproduce with the proxy disabled: `npm run dev -- --no-proxy`.
2. Confirm the mapping is present in the rendered config.
3. Apply the fix; verify the smoke check exits 0.

## Related
- Quick-ref entry: the area's Troubleshooting sheet, heading "ECONNREFUSED on every internal call…".
```

## Common mistakes

- Paraphrasing the symptom in the heading: "proxy problems" greps nothing — the heading must be the
  string the reader pastes from their terminal.
- Pasting root causes into project.md's Common Lookups: duplication — the table points, the sheet
  holds; two homes means two versions.
- Deep-dives without a quick-ref pointer: the reader holding the error string never learns the
  spoke exists.
- Dropping the Reference field when the fix is one line: keep the field and say "none" — the shape
  is the contract, and "none" is information.

## References

- [guidelines/01-structure.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/01-structure.md) — the hub row that registers the sheet.
- [guidelines/06-project-md.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/06-project-md.md) — Common Lookups, the routing layer.
- [guidelines/05-agent-navigation.md](https://github.com/DaveR-ui/documentation-onrails/blob/main/guidelines/05-agent-navigation.md) — why exact strings beat prose search for agents.
- [ADR-0002](https://github.com/DaveR-ui/documentation-onrails/blob/main/adrs/adr-0002-doc-classes-expansion-2026-09-07.md) — the class decision (upstream).
- [document-template.md](document-template.md) — the base note shape.
- [documentation-onrails v1.4](https://github.com/DaveR-ui/documentation-onrails) — upstream source of this vendored template; contract and checks unchanged, only the reference links re-pointed.
