# Organic places on the map

October 8, 2026. Task branch `codex/organic-place-art`, based on integrated
`b04c1bb27e710b7da0156adbb391870a175290e9`.

Status: implementation under validation; visual acceptance requires the user's
review of the private GPU captures. This branch has not been integrated into
the canonical player checkout.

## Read-only map contract

The country layer captures `settlement_places.snapshot()` in the owner's
WorldSimulation scope. Named places use their exact world positions and copied
metadata. Twelve living places and four ruins share the existing 24-seed limit
with retained root expansion clusters. No place is added to player_settlements.
The engine, monthly shares, food, labour, water and save schema are unchanged.

Founding/leaving revisions invalidate immediately. Population buckets, flood
setbacks, trends and annual ruin weathering use the existing visual refresh.
Terrain checks and mesh preparation happen within retained rendering jobs;
old patches remain visible until replacement is complete.

Parcels use the seat's existing geometry solver and completed construction
templates, with MAX_PARCELS enforced. Water-facing orientation is checked
before roof/parcel/road/land collision tests. Existing sites and headings are
retained as more parcels are admitted. Unknown river bearings use five samples
of actual river distance; unbuildable dry slopes are never treated as water.

## Visible details

Coastal places have hulls, drying racks and, at open-water exposure >=0.4, salt
pans. Lake places have reeds and a short jetty only when actual water is found.
River places have bank frontage and a crossing track. Inland places have fields.
A bounded, sliced shoreline search places shore details near the measured water edge,
with an access path from the inherited town centre. Tracks to the seat use the
existing road tier, prefer dry detours and clip impossible crossings.
Low dry banks use a shore predicate independent of the house elevation buffer;
unverified shores do not receive invented boats, reeds or river crossings.

Growing places show an edge building site. Declining places show a bounded
subset of fallen roofs. Floods wash the water-facing side. Ruins retain their
original kit's roofless walls and acquire overgrowth with age. Names use the
existing italic chart font. No human map batches or calendar-driven architecture
are introduced.

## Validation and review

The capture harness is `tests/organic_places_capture.tscn`. It requires private
`TomorrowOrganicPlacesQA` user data, a save copied under the worktree's ignored
artifacts directory, and `--organic-places-capture`. It runs only through
`tools/run_isolated_gpu_probe.ps1`, on a private desktop with Dummy audio.

The four requested moments are explicit in-memory specimens on the copied
save's actual terrain, not claimed historical campaign checkpoints. The source
copy's SHA is checked after capture; population, stockpiles, completed buildings
and simulation-settlement count must remain unchanged. Root and mature place
use identical camera scale. Additional shore and chart views expose details.

Baseline finding: `test_settlement_visual_architecture.gd` has two reproducible
pre-existing failures on the original renderer as well as this branch:
`test_close_metropolis_uses_one_strictly_bounded_district_clipmap` expects at least
six batches but receives five; `test_strategic_city_field_feathers_real_river_edges_without_coarse_triangle_holes`
receives an empty mesh and then indexes its missing surface. These unrelated
terrain systems are outside this change.

Combined headless validation: **165/165 passed across 13 suites**, with zero
errors, failures, skips or orphan nodes. This includes all 11 engine cases,
the new place plan/growth/visual suites, country plan/layer/visual/retention/
era/drape/chart, and early/organic town rendering. Evidence is local and private:
`artifacts/final-combined-tests.log`, `reports/report_4/results.xml`.

The separate broader architecture suite ran 83 cases: 81 pass and the two
baseline failures described above reproduce without this task's geometry or
renderer changes. Baseline evidence is in the plan worker's
`artifacts/architecture-baseline-final.log`.

Private GPU acceptance-3 passed all automatic invariants in ten captures:
unchanged exact population/day, central stockpiles and completed construction;
no human batches; at most 24 parcels; fixed founding roofs through growth;
flood damage and roofless ruins. The four requested states and root comparison
use a 0.3 km camera span. The private probe exited successfully.

Visual acceptance is still pending. This saved coast currently admits no shore
props, which is under diagnosis. Exact-camera country-hidden and nation-wash
ablations leave a large beige terrain ribbon visible. A plain regional water
material fills the missing dark sea, isolating that gap to the existing water
rendering path. These underlying terrain defects are not concealed in review
captures. Evidence: `artifacts/organic-places/acceptance-3/`.

## Reproduction

Use an ignored override.cfg with:

```ini
[application]
config/use_custom_user_dir=true
config/custom_user_dir_name="TomorrowOrganicPlacesQA"
```

Run Godot headless with an explicit worktree `--path` and GdUnit suites for
settlement places, place plan/growth/visual, country plan/layer/visual/retention,
and existing early/organic town rendering. For GPU review, provide the private
runner with `res://tests/organic_places_capture.tscn`, `--span=.3`, `--frames=90`,
the copied save path, and a 600-second timeout. Do not launch this scene as the
player game or change the canonical project settings.
