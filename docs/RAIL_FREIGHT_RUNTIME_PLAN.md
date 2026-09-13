# Physical rail freight — worker delivery

INTEGRATED in runtime merge `fbaf803`, canonical verified at `e94ffa8e5d65684bf62e7f73b58a0c7b5ec77fc3`; original worker delivery: isolated worktree `/Users/seanpurtill/Documents/Codex/tt-rail-freight`, branch `codex/rail-freight`, base `368b7718c419ff73d788e29d3bf9e5ad212a37ce`. Integrator authorized rail-only additions in shipment dispatch, optional save state, civilian recipes and investment dispatch. Five identities are promoted after canonical verification; see `RAIL_CONDITIONING_INTEGRATION.md`. The packaged player has not been rebuilt.

Existing intercity trade debits actual source goods, occupies carrier capacity and delivers later. It has no installed track, gauge-specific rolling stock or return-trip asset commitment. Rail must become an alternative physical mode for those same shipments, preserving all water/naval supply targets and laundry power demand.

## Required delivery

- Survey a revealed route between actual owned settlements. Use terrain heights in world kilometres and bounded sample spacing; require buildable land, no unsupported river crossing and a supported grade. Missing geography is not flat ground. Keep surveyed endpoints and samples with the installed route; moved settlements cannot keep using an old line.
- Build paid timber rail panels, gauge tooling, rail wheelsets, wagons and brakes through ordinary manufacturing. Imported finished equipment remains usable without granting manufacture.
- Installation pays a complete material bill atomically from the construction city's inventory. Incomplete projects produce no capacity. Rail projects share the existing civilian monthly builder pool with settlement and water projects, preserving the military construction reservation and local population scope.
- Retain installed route material, selected gauge, rolling stock, condition, construction work and dated commitments. No arbitrary road cart becomes a rail wagon. The initial supported haulage is human-worked on shallow grades; no animals, engines, electricity or fuel appear from knowledge alone.
- Use the existing cargo issue/arrival path. Rail changes only a paid, installed route's qualified capacity and travel duration. The same workers cannot haul both modes without accounting. A finite wagon pool and crew commitment remain occupied through the empty return trip, including when the delivery already arrived.
- A first single-track line has exclusive service occupancy; reverse movements cannot pass through it. Braking capability is tied to installed brakes and loaded operation. Later block working, steam/electric traction, branching yards and bridge/tunnel service require their own physical consumers before promotion.
- Maintenance uses local replacement materials and existing labor while the line is clear. Wear or failed inspection can suspend service. Occupation, missing endpoints and terrain incompatibility prevent new dispatch; departed cargo and committed assets are not silently duplicated or discarded.
- Player controls and autonomous investment share the same install/dispatch actions. The UI reports physical condition, work, costs and occupied stock. No mandatory logistics forms or direct cohort controls.
- Optional rail state validates and round-trips for human and owned actors. Legacy absent state remains valid. Tests must reject malformed coordinates, work, dates, stocks and commitments, and verify complete SaveSystem continuation.

Candidate existing promotions: `aggregate_road_foundations`, `rail_gauge_standards`, `rail_track_foundations`, `wagonway_haulage`, `rail_vehicle_braking`. Review draft predicates: manual wagon haulage must not require animal harness knowledge. Keep other rail definitions drafted until their mechanisms work.

Acceptance must cover paid install and shortages, real shared construction, gauge/grade/access rejection, finite stock and crew return occupancy, both shipment directions, maintenance closure and shortages, primary/secondary/actor isolation, autonomous supply, actual controls, save continuation, and dependency closure. Run one cohesive affected test set after connection, then focused follow-ups only for changed or failed behavior. No long pacing simulation is needed to establish these local mechanics; full 2,500–3,000-year balance remains separately unfinished.

## Delivered behavior and evidence

The owner is connected to optional GameState rail state, monthly shared construction,
existing delayed city shipments, civilian manufacturing, autonomous investment, and
research-card controls. Eight paid recipes produce ballast, templates, rail panels,
two compatible wheelset/wagon families and brakes. The UI selects endpoints, gauge
and one to eight wagons; it refreshes supply and operating status every five seconds.
Installation and autonomous investment call the same paid action. Established trade
partners are considered for autonomous installation, with up to three surveys per call.

Routes use actual returned knowledge and current terrain. Positive infinity from the
terrain water-distance provider means no nearby water; NaN, negative distance,
unsupported crossings, excessive grade and missing callbacks remain rejected.
No resurvey occurs for active cargo; dispatch checks the installed alignment again.
Occupation holds cargo and committed stock until endpoint access resumes. Cargo
arrives through the existing inventory/food ledger and cannot release its fleet
before the scheduled return. Gauge-specific equipment and source-city supplies
are debited once. Maintenance closes the line for its work day.

Validation on Godot 4.7.2, explicit isolated worktree:

- 46-case combined run: 14 rail, 13 city-resource and 19 owned-civilization cases,
  zero errors/failures, terminal exit 0. Log `/tmp/tt-rail-freight-acceptance.log`.
- Final rail suite: 16 cases, zero errors/failures, terminal exit 0, 1.950 seconds.
  Adds paid autonomous wagon manufacturing before installation and full owned-actor
  save restoration of partial construction. Log `/tmp/tt-rail-freight-final-focused.log`.
  Across the two runs there are 48 distinct cases, not 62 distinct cases.
- Tests cover atomic shortage rejection, gauge incompatibility, grade/chart/water
  evidence, shared builders, actual food cargo, same-material upkeep, finite return
  occupancy, reverse service after occupation clears, maintenance closure, secondary
  stores, actual button action, human full save with cargo, actor full save with work,
  malformed saved dates/coordinates/commitments and duplicate consignments.
- Graph audit: 681 live definitions on this older 676-definition base, 463 explicit
  learning routes, 318 reachable recipes and 17 reachable plants; no graph errors or
  blocked plants/products. Log `/tmp/tt-rail-freight-graph.log`, terminal exit 0.
  This structural closure does not prove campaign pacing.
- Normal headless project boot reaches DIRECTION_SCREEN_READY and exits 0 without
  parse/runtime errors. Log `/tmp/tt-rail-freight-boot.log`. No player was launched.

## Integration, compatibility and remaining scope

Deliver the complete branch range after base
`368b7718c419ff73d788e29d3bf9e5ad212a37ce`, including foundation `6eb949b`.
Shared additive edits are in GameState, SaveSystem, WorldSimulation, SettlementModel,
CivilianIndustry, CivilizationController, DiscoverySystem and the technology operations
panel. Preserve subsequent record-media and geared-workshop additions on main,
especially their recipes, plants and service bounds. This branch does not modify
TechnologyOperations, LocalTerrain, military authority or project settings.

Promote only the five existing identities listed above after canonical acceptance.
Wagonway Haulage intentionally drops `draft_harness_fitting` from its prior mandatory
parents: this operating mode uses human crews. Retain `rail_track_foundations` and
`cart_running_gear`; record the old/new predicate in the promotion reconciliation.
Promotions add zero authored identities. Existing disadvantaged research acquisition
systems remain in place; these five definitions add local method routes, not a new
foreign research service.

Absent rail state migrates to an empty register. Saved partial work, local materials,
gauge, stock wear, active cargo and return commitments round-trip through whole-game
saves for human and owned civilizations. Validation rejects mismatched paid bills,
route sampling, trip quantities/crew/dates and duplicated pending rail consignments.

Explicit limits: first human-powered single-track wagonways only; 120 km maximum,
2% grade and 250-metre terrain samples are game-service bounds, not engineering
certification. UI/automatic proposals survey straight alignments; the owner API can
accept explicit waypoints, but automatic detour planning is unfinished. Existing
city-trade logistics range still limits donor selection. No rail bridges, tunnels,
yard junctions, block signaling, steam/electric traction, passenger traffic or military
rail supply is claimed. Later rail technology consumers and additional imagery remain
unfinished, as does full 2,500–3,000-year pacing validation and the 5,000-discovery goal.
