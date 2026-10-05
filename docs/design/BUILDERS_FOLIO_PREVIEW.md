# Builders folio — integrated

The user requested integration on October 5, 2026. Source `301e20e0` is merged
with current main `ab211f42` in runtime
`ae1a4a03b6755e7f86f2f3414a5d58e45539a406`. This was pushed to origin/main
and freshly verified before advancing the canonical checkout. All 4,747
pre-existing local files retained their hashes. Combined validation passed
32/32 cases across construction, town works, Food and the persistent top bar.
Private GPU probes at 1536px and 1138px passed, including preservation of open
details across changed construction progress; both test processes exited.
The historical preview hold below is resolved.

Original preview status: HELD. This was the first Buildings / The Town
presentation example. The user requires a rendered example before
each page enters the game. Civic Works, Infrastructure and Landmarks retain
their existing content renderers pending subsequent visual review.

Base: `a7877e0de26cf638d3ee6bd2bc9f630e17dd21b3`.
Branch: `codex/builders-folio`.
Worktree: `C:/Users/sjpur/.codex/worktrees/court-walk-facing/TomorrowandTomorrow`.

The current work uses the existing era-aware building illustration. Housing,
builders, condition, building era and workshop staffing become large readings
with expandable explanations. Recent completion, defence controls and new homes
follow them. All provider calculations, values and action callbacks remain in
the construction provider. Existing built-fabric and impact data remain below,
with larger section headings. Open details survive the dock's live refresh.
The approved rail, page frame and persistent top bar are reused.

## Validation

- `test_construction_city_tab.gd`: 14 passing cases (report 18).
- `test_opening_framed_construction.gd`: 5 passing cases (report 18).
- `test_town_works_board.gd`: 6 passing cases (report 19). Updated the renderer
  discovery to recognize the derived folio widget and the new three-section
  arrangement; existing data, callback, concise-label and palette assertions
  still run. Initial failures were the old two-board/name assertion.
- Private desktop GPU previews: active construction and completed civic works
  with material shortage at 1536 × 1024; construction at 1138 × 1024.
  Top, scrolled town, open details and bottom impact sections captured.
- The final preview also changes active project progress before rebuilding,
  and checks that its open details remain open across the live data change.

Reproduce with `tools/run_isolated_gpu_probe.ps1`, the explicit worktree path,
scene `res://tests/builders_folio_preview.tscn`, and user arguments
`--builders-preview --case=building --out=res://artifacts/builders-final-building`.
Use an ignored override.cfg with acceptance-specific custom userdata. The probe
reuses prepared test records, never loads or writes a campaign, and exits.
Captures, caches, imports and generated UID files are excluded from the commit.

## Integration notes

No save schema, simulation or labor authority changes. Shared UI touchpoints:
`dock_blocks.gd` chooses the opt-in construction renderer and styles its section
headings; `dock_panel.gd` applies the opt-in unboxed summary style. Other page
renderers are unchanged. Preserve concurrent edits when integrating these files.
Approval and integration are recorded above. This delivery concerns the page
presentation; it does not change the undertaking-abandonment rule. Generated
captures, imports and test userdata remain local.
