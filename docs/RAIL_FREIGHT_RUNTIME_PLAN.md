# Physical rail freight — implementation in progress

HELD worktree `/Users/seanpurtill/Documents/Codex/tt-rail-freight`, branch `codex/rail-freight`, base `368b7718c419ff73d788e29d3bf9e5ad212a37ce`. Integrator authorized rail-only additions in shipment dispatch, optional save state, civilian recipes and investment dispatch. No player build or discovery promotion is claimed.

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

## Isolated foundation checkpoint

The route survey and paid fabrication helpers are written. Route geometry uses the canonical terrain's kilometre units, at 250-metre sample spacing with a 2% supported grade, a 120-km route bound and rejection of unsupported river crossings. These are declared game-service bounds, not certification of an engineered alignment. The owner must resurvey before installation and validate endpoint access before dispatch.

The fabrication model pays for gauge templates, timber rail panels, support material, gauge-specific wagons and brakes; it retains partial work and a single exclusive round-trip commitment. It quotes reserved crew count separately from cumulative worker-days, so integration can subtract actual committed workers without multiplying their daily reservation by the trip duration a second time. Maintenance consumes replacements and closes the line for that day. These helpers are not registered or connected to game state yet.

Godot 4.7.2 syntax compilation is the current validation scope only. Operating tests belong after owner connection; no runtime acceptance or new live discovery is claimed. Next: optional-state validation, owner-local installation/construction and shipment dispatch, supply/UI, then the cohesive acceptance set above.
