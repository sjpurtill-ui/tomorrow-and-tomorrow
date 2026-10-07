# Shared settlement growth for expansion seeds

October 6, 2026. This replaces the earlier country-cluster layout. The reported
Ashfire save (2,485 people, day 77,329, world seed 1811640852) reproduced a ring
of 19 repeated compounds around an empty population-sized exclusion circle.
That layout was separate from the root settlement and did not meet the user's
requirement that every expansion seed grow like the root.

## One geometry and building-placement implementation

`settlement_plot_geometry.gd` contains the existing root founding, household
candidate selection, inherited-lane/nucleus scoring, terrain checks, irregular
parcel geometry and bent route geometry. `settlement_model.gd` delegates to it.
Original and extracted founding records and 72 household/route additions were
compared across three world seeds, including consumed RNG values; they match.
Simulation costs, capacity, residents, construction, history and state authority
stay in the model. The shared helper is pure geometry.

Country seeds now use that same helper and `EarlySettlementVisual.layout` /
`EarlySettlementVisual.render`, the root's building solver and architecture.
They inherit completed root construction forms and use its parcel frontage,
road clearance, land checks and saved building-site retention. Ground follows
actual parcel polygons and routes. The fixed twelve-roof pattern, rectangular
field pair, universal round yard and generated straight connector are bypassed
for these seeds. There are no human map figures.

The nucleus sequence uses the household accretion selector at a larger spacing
for its reserved founding ground. It has no radial shells, sectors, grid cells,
population-radius exclusion or distance-ranked ring. Seed IDs and centres stay
fixed as population or worked reach increases. Real occupied root polygons
constrain parcel growth and absorb overlapping rendered roofs individually;
a far field cannot erase a circle of settlement. Existing unaffected roofs do
not move. Stable neighboring claims prevent overlapping seed footprints while
their irregular parcels fill toward shared edges; claim boundaries are not drawn.

## Bounds and retained work

There are at most 24 local seeds, each with at most 24 private display parcels.
Population adds parcels to retained state; it does not relocate existing ones.
This is a bounded visual sample, not another population ledger or supply node.
No new saved fields or migrations are introduced. Old generated architecture is
retained; newly appended claims use the current completed construction palette.

The renderer advances one geometry claim or one changed building parcel per
cooperative preparation step. Old complete patches stay visible until a new
patch is ready. Fog filters visibility after physical placement, so exploration
cannot reroll homes. Canopy masks use installed parcel geometry and refresh when
asynchronous installation completes. The existing global canopy-slot budget
still applies; it is not expanded to one unbounded mask per house.

## Verification

79 distinct focused checks pass: geometry 9, country plan 28, visual 31, layer 9,
and country canopy 2. Report 60 passed the first combined 75; report 61 passed
the final 42 covering absorption, neighboring footprints and immediate canopy
refresh. No script/engine errors, warnings or orphans in those runs.

The private GPU probe uses a copied current quicksave, never a generated campaign.
It captures a 3 km overview and equal-scale 0.75 km root/expansion views.
Baseline evidence is under `artifacts/organic-settlement-seeds/before*` and the
capture source is `tests/organic_settlement_capture.tscn`. Generated evidence,
save copies and import caches remain outside source delivery. The canonical
player is preserved; its normal relaunch loads the integrated scripts.

Final GPU capture succeeded on the copied Ashfire save. All five active seeds
were installed with current geometry signatures before each of the three views.
They contain 24/20/17/15/13 parcels and 34/32/29/23/20 homes. Visual inspection
confirms the old ring is gone: branching lanes and irregular roof groups now
sit against the root's fringe, with one smaller separate growth focus. The
equal-scale root and expansion views use the same architecture. Human batches
remain zero, drape skips are zero, and the probe exited 0 without engine errors.
Evidence: `after_overview.png`, `after_root.png`, `after_expansion.png` and
`after.json` under the same artifact directory. Maximum measured preparation
slice was 29.691 ms; individual parcel solves are not a hard 2 ms bound. The
unrelated far-worksite queue (100-102 entries) was not awaited for these local
seed views. The first attempt was stopped by Windows input-desktop verification;
the same approved runner succeeded on one retry without a bypass.
