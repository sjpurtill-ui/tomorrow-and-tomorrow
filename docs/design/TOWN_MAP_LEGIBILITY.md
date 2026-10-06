# Expansion-map legibility preview

Status: approved for integration by the user on October 6, 2026.
Source `42a5ff21`; canonical and remote main `1fd8ad8b` are included.
Combined checks pass again: 56/56, report 36. Delivery is remote-first, then
canonical fast-forward; no running player/editor is restarted.
Branch: `codex/town-map-legibility`; base `1fd8ad8b70e6812d771152982be5852aa0b49ab2`.
Worktree: `C:/Users/sjpur/.codex/worktrees/food-folio/TomorrowandTomorrow`.

The user rejected the previous Year-201 repair after reboot. Correct road widths
and additional fitted meshes alone did not make the town readable. The current
quicksave has advanced to Year 206, Summer, with 3,665 people in Ashleyfire.

## Changes

- Extend detailed plot admission from IDs 1–128 to IDs 1–512. The existing hard
  limit of 512 building representatives remains. This is a rendering budget,
  not a population count or a construction/progression rule.
- Keep inherited town ground presentation when additional field records take
  the total plot count beyond the detail limit.
- Use the architecture shader's painted directional lighting without applying
  scene lighting a second time. Existing outlines, surface markings, glazing,
  cloud modulation and ground shadows remain.
- Weather completed architecture toward a lighter warm stone tint. Condition
  still affects appearance; worn occupied houses no longer become near-black.
  Ruin, construction, structural damage and placement eligibility are unchanged.

No simulation, population, research, camera scale or save schema changes.
Existing saves load without migration. Footprints remain subject to parcel,
road, water and neighboring-building checks. Buildings are not inflated for zoom.

## Verification

Godot 4.7.2, Compatibility renderer, RTX 4090. All five relevant headless suites
pass: early settlement, architecture kit, organic town, city evolution and patch
renderer. 56/56 tests; zero failures/errors/orphans, report 35. New regressions
cover detailed buildings after plot ID 128 and stable ground presentation when
extra fields cross the budget. Existing over-budget fallback tests now use the
configured boundary rather than a hardcoded obsolete ID.

Copied the current quicksave into the isolated acceptance user directory as
`town-readability.save`; the original save and running player were untouched.
Private GPU baseline and revised captures use the same save, 1600 × 1050 viewport
and 0.75 km camera span. Baseline: 167 detailed architecture instances. Revised:
243. Final GPU probe PID 21368 exited 0 with `LIVING_VILLAGE_PREVIEW_OK`.
This count measures renderer coverage, not visual approval or population.

Local evidence (captures and saves intentionally excluded from Git):

- `artifacts/town-readability-before/visit.png`: integrated main baseline.
- `artifacts/town-readability-light/visit.png`: initial revised map.
- `artifacts/town-readability-light/close.png`: closer 0.16 km inspection.
- `artifacts/town-readability-final/visit.png`: final revised map.
- `artifacts/town-readability-final.log`: final public preview harness result.
- `artifacts/town-readability-tests.log`: full regression output.

Reproduce through `tools/run_isolated_gpu_probe.ps1`, with this explicit worktree,
`res://tests/living_village_preview.tscn` and user arguments
`--save-slot=town-readability --output=res://artifacts/town-readability-final`.
The acceptance user-directory override must be enabled. The harness verifies
actual rendered homes, exact population metadata, portrait serialization, camera
restoration and Visit behavior. Graphical probes use a private desktop and Dummy
audio; no player or editor restart is required for the test.

## Limitations and integration

This is a legibility revision, not a redesign of settlement density or house
proportions. Painted lighting deliberately favors readability over physically
lit faces. The finite detail budget still uses aggregate fallback after plot ID
512. No new discoveries or buildings are granted. Pending appearance-progression,
figure-removal and brighter-topbar branches are excluded.

Owned runtime files: `early_settlement_visual.gd`, `organic_town_visual.gd`,
`settlement_architecture_kit.gd`, `settlement_ink.gd`. No shared simulation hotspot
was edited. Concurrent architecture/placement changes can conflict in these
files; unrelated preview branches remain excluded from this integration.
