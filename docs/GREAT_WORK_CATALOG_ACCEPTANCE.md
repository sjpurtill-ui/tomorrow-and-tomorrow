# Great Work catalog acceptance

Base: `01ce6be538e9ce3491686313bb99cd5f199caf09`. This new isolated probe inventories
all 18 conceived form families and all 12 legacy IDs from the actual catalogs.
Authored architecture and per-work dedication profile integration is pending.
An inventory-only or non-strict baseline is not visual acceptance of that work.

The first non-strict headless baseline passed 1508/1508 checks with a clean exit:
120 canonical progress builds, 900 allowed material/tier/ambition builds and
216 purpose builds. Evidence is local at
`artifacts/great-work-catalog-baseline/functional.json` and the matching `.log`.
This validates the harness and existing renderer's finite geometry only; the
strict authored-profile, unique-shape and GPU visual checks remain pending.

The planned GPU matrix uses actual Model/View/Stage components in one process:
five contact pages with six works each, each work at 0/30/70/100 percent, then
one whole-work preview and one dedication action image for every catalog entry.
The contact pages are 2400x1800; individual ceremonies are 1280x900, alternating
light/dark. Every completed work also gets an actual pixel sleep/wake check.
Orbit/zoom must retain geometry, and the whole-work camera must contain its bounds.

Prepared work records are explicitly read-only visual fixtures. They do not
claim a continuous campaign or engine-earned completion. A separate existing
12-case `great_work_3d_acceptance` probe covers real commissions, daily engine
completion, dedication ledger transfers, one-time gifts and pause ownership.
The new catalog probe uses one actual commission and the existing seeded world
fixture to provide recorded court participants, then instantiates presentations.

`--variants` additionally builds every encoded allowed material x tier 0..5 x
ambition combination for the 18 forms at completion. Canonical records cover
all four progress values, including a functioning-label/incomplete-fraction
check. All twelve purposes are also built for every form, recording their
actual emblem and color-independent geometry fingerprint. These are renderer
robustness combinations, not claims that every tier
can commission every technology. Ceremony fixtures provide real known catalog
skills and use supported tiers, including modern tier 5 at year 3000.

Run headlessly with an explicit isolated project, Dummy audio, an ignored
acceptance-specific userdata override, and:

```text
res://tests/great_work_catalog_acceptance.tscn -- --great-work-catalog --inventory-only
res://tests/great_work_catalog_acceptance.tscn -- --great-work-catalog --require-authored --variants
```

For GPU captures use `tools/run_isolated_gpu_probe.ps1`, the explicit worker
project path, and user arguments `--great-work-catalog --require-authored --capture`.
`--group=structure`, `--group=construction` or `--group=ceremonies` selects a section;
`--design=form:tower` or `--design=legacy:ancestor_ring` selects one identity;
`--out=res://artifacts/<folder>` separates evidence. Generated images, JSON,
logs, imports and isolated userdata stay local and are never committed.

This task owns only these two new probe files and this document. No runtime,
simulation, player preferences, save format, or player process is changed.
