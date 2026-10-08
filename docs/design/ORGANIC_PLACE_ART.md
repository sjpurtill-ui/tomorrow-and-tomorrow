# Organic places on the map

October 8, 2026. Task branch `codex/organic-place-art`, based on integrated
`b04c1bb27e710b7da0156adbb391870a175290e9`.

Status: tested draft ready for visual review; acceptance requires the user's
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
A bounded, sliced shoreline search (800 two-metre probes, 1.6 km maximum)
places shore details near the measured water edge,
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

Final combined headless validation: **228/228 passed across 20 suites**, with zero
errors, failures, skips or orphan nodes. This includes all 11 engine cases,
the new place plan/growth/visual suites, country plan/layer/visual/retention/
era/drape/chart, early/organic town rendering, terrain patch sampler/builder/
reuse, coastal water/masks, and supply/borders. Evidence is local and private:
`artifacts/final-integrated-tests.log`, `reports/report_6/results.xml`.

The separate broader architecture suite ran 83 cases: 81 pass and the two
baseline failures described above reproduce without this task's geometry or
renderer changes. Baseline evidence is in the plan worker's
`artifacts/architecture-baseline-final.log`.

Private GPU acceptance-5 passed all automatic invariants in twelve captures:
unchanged exact population/day, central stockpiles and completed construction;
no human batches; at most 24 parcels; fixed founding roofs through growth;
flood damage and roofless ruins. Visible home instances are 9 at founding,
44 at maturity, 41 after flood damage, and zero in the ruin. The four requested
states and root comparison use a 0.3 km camera span. The private probe exited
successfully (PID 64940); the player's input desktop remained Default.

User visual acceptance remains pending. A diagnostic found the real beach 828 metres
from the fixed town centre, beyond the initial 640-metre search. Extending the
sliced search to match the engine's shore survey now admits two hulls, a drying
rack, two salt pans and the access path, without moving the town. The bank's
12-metre slope sample is 0.0101 and is suitable dry ground.

GPU review also exposed a pre-existing 0.6-metre rendering lift that turned
shallow water into grassy land. The two terrain patch helpers now taper that
visual offset between one and four metres above sea level, preserving the
physical zero shoreline. Only the render builder opts in; default sampler
output remains byte-compatible for supply and borders. Final shore captures
show hulls drawn up beside visible water, with rack, salt pans and access path.
The additional terrain/coast/supply/border validation passed 62/62 cases.

Known limitation: exact-camera country-hidden, nation-wash-hidden and
coarse-terrain-hidden ablations leave a large beige terrain ribbon and a
background hole in the wider coastal context. A plain regional water material
fills the hole; that does not prove it represents actual sea. Those separate
terrain rendering defects remain visible in review evidence. No terrain
shader, simulation, or canonical checkout source was changed for this task.

Private evidence: `artifacts/organic-places/acceptance-5/` (four states, root,
shore, chart and layer ablations), and `shore-1/` (physical
shore diagnostics). These generated files and the copied save remain local,
outside Git. User visual approval is pending; this PR stays draft.

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
