# Year 201 expansion map repair

READY for preview review on `codex/year201-expansion`, based on
`1df2277270556b175377fbe6933dbccbc25ec8b5`.
Worktree: `C:/Users/sjpur/.codex/worktrees/food-folio/TomorrowandTomorrow`.
No canonical checkout integration or player restart has occurred.

## Reproduction and causes

The user's saved Ashleyfire campaign loads at day 73,000 (Year 201), population
3,422, with 200 plots and 200 routes. The houses remain in the ledger: 104
residential/mixed-household plots are stressed, with zero structural damage.
The city condition is low, but the apparent disappearance is a visual failure.

The exact saved-game reproduction showed three interacting defects:

- The surface tier inflated a 0.72 m field track into a 6.4 m gray paved strip.
  Placement also reserved this fictitious width, rejecting surrounding houses.
- Later building prototypes could not fit small expansion lots without saved
  earlier footprints. The previous inherited-site fix only covered old houses.
- Aggregate one-storey roofs were below the raised parcel and yard layers after
  crossing the detailed-model budget. Uniform scaling also shrank the storey
  heights of inherited models when fitting their smaller footprints.

## Correction

One shared width function now governs road drawing and building clearance.
Recorded width and existing hierarchy minimums determine the footprint; surface
quality does not invent additional width. Field tracks retain their field-track
palette and opacity even if their shared surface-tier value increases. Routes
serving expansion plots keep the same low ground offset beyond plot ID 128.

Small lots use compact building envelopes through the original bounded placement
solver. Parcel, road, neighboring-building and dry-land checks still apply.
Persisted building sites stay fixed. Horizontal fitting preserves the model's
recorded storey height. Yard and density layers stay below aggregate roofs.
No unchecked fallback roofs are added to rejected detailed lots.

## Verification

54/54 headless checks across early settlement visuals, architecture kit, organic
town visuals, city evolution visuals and settlement patch rendering pass with no
errors, failures, skips or orphans (report 33). New regressions cover surface-only
road upgrades, roofs above ground layers, and compact building placement with
unchanged storey height. Existing road/parcel/water/slope rejection, bounded
representatives, inherited sites and incremental patch tests continue to pass.

An isolated copy of the actual save reproduces the original screenshot. Private
GPU acceptance after the correction renders 164 detailed representatives versus
95 before, at the same population and same wide camera span (0.7 km). It also
checks Overview/History, save-codec album roundtrip, camera restoration and Visit.
Final private GPU PID 62960 exited 0; no script or engine errors. The model count
is visual representation, not a new population or household count.

Local evidence (excluded from Git):
- `artifacts/year201-before/visit.png`
- `artifacts/year201-final/visit.png`
- `artifacts/year201-final/close.png`
- `artifacts/year201-final-gpu.log`
- `artifacts/year201-verified-tests.log`

For reproduction, copy the save to an isolated acceptance user directory as
`year201.save`. Run `tests/living_village_preview.tscn` through
`tools/run_isolated_gpu_probe.ps1` with `--save-slot=year201` and
`--output=res://artifacts/year201-review`. The preview now accepts these optional
arguments while preserving its original defaults. The final diagnostic also
captured a closer 0.16 km view and compared against an unrestricted-land layout;
that extra diagnostic script and its local data are not release files.

## Compatibility and scope

No save schema, simulation, population, resources, parcel geometry or route data
changes. The renderer can record additional valid visual sites in existing saves;
it does not move retained sites or manufacture completed construction. Narrow
inherited footprints remain narrow, now with full-height storeys. Genuine wear,
ruins and terrain occlusion remain represented. Models remain bounded at 512;
plots beyond the detailed budget continue to use checked aggregate roofs.

Shared hotspot: `scripts/local_terrain.gd`. Other runtime changes are limited to
`early_settlement_visual.gd`, `organic_town_visual.gd`, and
`settlement_architecture_kit.gd`. Pending appearance-progression, top-bar brightness
and settlement-figure removal branches are deliberately not included here.
Generated imports, caches, saves, captures and diagnostic dumps remain local.
