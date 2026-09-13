# Physical water conveyance — implementation contract

Status: frozen implementation delivered as `5d08c2b8c949c08d89c49a8eefdaf87e2e87e205`; the integrator is validating it with canonical clothing and grain changes. The original design contract below defines the scope; the delivery section records implemented behavior and tests. Canonical inclusion is recorded separately in `INTEGRATION_STATUS.md`.

## Existing authority and observed gap

`ResourceSystem._process_water_flow` selects accessible surveyed deposits or mapped surface hydrology, calculates household and organized collection, and owns the Freshwater stock debit for drinking. `SettlementModel.with_city_resources` swaps local inventories and persists them back to the owning city. Both remain authoritative. Nearby exposed water must remain usable by households without pipe technology.

The current water context supplies distance and sometimes a source identifier, but does not establish an intake position, hydraulic head or a surveyed route. Distance alone cannot justify gravity conveyance. A line must retain a verified source position, destination, route length and supporting grade observations. Unknown geometry blocks gravity commissioning; it must never be replaced with invented height values. Surveyed terrain and visible hydrology are evidence sources, not permission to expose hidden deposits.

## Paid construction and operation

Promote the ten conduit draft identities only when each has an actual consumer. Clay forming and firing produce intermediate and finished pipe stocks through existing workshops; fit gauges and gravity socket joints qualify installation choices. Timber conduits remain an alternative with their own raw inputs, tooling, losses and upkeep. Imported finished sections can supply construction without unlocking their manufacture.

Quotes select an actual source and a bounded route. They show length, materials, construction work, expected service limits and blockers. Starting work consumes the quoted local bill once. Installed lines retain their paid material provenance, construction progress, grade evidence, condition, obstruction, leakage estimate and last processed day. Finite Construction work competes with existing construction obligations; repeated calls for the same day cannot grant more work or delivery.

Gravity grade control accepts only a verified feasible route. Pumped service is a separate future or already-qualified equipment path requiring actual pumping capacity and power; do not smuggle it into gravity pipe technology. Bedding and loading assessment affect the installed section they treat. Inspection consumes work and updates observed condition; rodding removes supported obstructions through accessible maintained runs. Neither inspecting nor knowing a repair method restores condition for free.

The daily conveyance result reports water delivered to the same ResourceSystem collection calculation. Source availability, installed throughput, condition, obstructions and leakage bound delivery. It is not credited once to pipe stock and again to city stock. Household collection, carried water and conveyed water must share the existing collection/storage accounting, including overflow and drinking consumption. Pipe work must not increase source quality or grant disinfection. Conveyance should reduce dependence on hauling or extend verified access, not merely add a global research percentage.

## Player and rival use

Use the existing settlement/service inspector and ordinary investment flow. Show construction status, verified route, delivered quantity, losses and the concrete missing input. No mandatory logistics form or new population authority. Rival decisions use the same feasibility quote, local supply planning and paid start operation. They must account for benefit, competing labor and maintenance; they cannot construct using global or another city's stock.

## State and integration boundaries

Keep new city-local line records in the established state/save system and include their default in CITY_RESOURCE_DEFAULTS. Validate finite quantities, bounded collections, recognized material methods, route references and nonnegative dates in both human and actor payloads. Legacy saves initialize empty lines. A destroyed or inaccessible source disables its line without destroying stored household water. Moving a settlement cannot silently move an installed pipeline with it.

Expected shared edits: one ResourceSystem daily service hook; civilian workshop recipe registration; discovery registration and operating-contract validation; city-local state/default and human/actor save checks; existing inspector and investment hooks. Coordinate exact terrain/hydrology sampling APIs with the integrator before changing LocalTerrain. Do not replace terrain, food/grain ownership, or construction systems wholesale.

## Evidence required for delivery

- Actual source-to-city route: downhill succeeds when supplied; uphill and unknown geometry remain blocked without a qualified pump.
- Full paid manufacturing and construction path, including a timber alternative and an imported finished-section route without manufacturing mastery.
- Daily water conservation with household fetching, finite storage, shortage, leakage and repeated-day calls.
- A damaged or obstructed line loses capacity; paid compatible repair or rodding restores only supported service.
- Rival and secondary-city operation debit their own stocks and labor; source loss and settlement relocation invalidate service appropriately.
- Full save/load continuation preserves incomplete work and installed operation; absent legacy fields remain valid and malformed line records are rejected.
- Inspector reports match physical state. Run focused water/resource, owner/save and affected construction/production checks once after the cohesive implementation. Treat unrelated baseline failures separately and disclose them.

Full treatment, wastewater networks, historical pacing, the rest of the 5,000 discoveries and their artwork remain part of the larger goal. This conveyance batch cannot stand in for completion of those requirements.


## READY for integration review

Worktree: `/Users/seanpurtill/Documents/Codex/tt-water-conveyance`, branch `codex/water-conveyance`, base `b227f9a1b99719a1ed39953ea1e1a0fee8531d02`. This is an isolated delivery, not a claim that the canonical game contains it.

Ten existing draft definitions are registered with six paid workshop recipes and physical line consumers. Source-bound gravity lines consume delivered sections and fittings, finite shared construction work, local maintenance stock and labor; ResourceSystem retains the sole Freshwater ledger. Primary and secondary controls and rival investment use the same paid installation. Intercity trade now requests bounded conduit bills and maintenance supplies, retains route/logistics gates and transit time, and debits donor stock at departure. Secondary automatic demand can request upstream manufacture at the primary owner; imported sections do not grant manufacturing knowledge. Timber manufacture is selected when ceramic manufacture is unavailable. Load assessment applies only with paid rigid bedding and an additional unit of construction work per section batch; it does not certify arbitrary overburden or traffic.

Three draft prerequisite corrections must be recorded during verified promotion: ceramic socket joining uses shared measures plus lime mortar OR clay tempering, without mandatory pipe manufacture; bedding uses drainage plus joinery OR clay tempering; fit gauges use shared measures plus clay shaping OR joinery. Preserve old predicates as reconciliation evidence. This promotes ten existing identities, adding zero to the distinct authored total.

Validation:
- Latest focused run: 26/26 cases across `test_water_conveyance_operations.gd` and `test_city_resources.gd`, no failures/errors/orphans, exit 0; `/tmp/tt-water-shipping-tests.log`. Includes paid manufacture fallback, paid assessment work, delayed intercity imported-section delivery and subsequent secondary installation, raw trade regressions, full save continuation, city stock isolation and delayed UI callback scope.
- Earlier affected regressions: 11 building-material, 12 civilian-industry, 43 SettlementModel cases and three route cases pass. Combined distinct coverage is 95 cases, with the latest 26 replacing the older operating cases rather than double-counting them.
- Graph/production closure: 661 discoveries, 443 routes, 309 recipes, 17 facilities in this worktree; `/tmp/tt-water-graph.log`. The base has 651; canonical clothing promotions are separate. Structural evidence does not prove campaign pacing.
- Normal headless boot clean; `/tmp/tt-water-normal-boot.log`. No player session launched or stopped.

Save compatibility: absent legacy water fields default to no installed lines; paid unfinished construction and operational condition persist. Human and actor validators check the same line schema and city-local records. Existing shipment serialization carries these resource names without a new format.

Integration conflicts: preserve canonical clothing and grain changes in shared GameState, SettlementModel, SaveSystem, WorldSimulation, DiscoverySystem and catalog validation. LocalTerrain change is limited to bounded source sampling and inspector controls; no terrain geometry or project settings changed. Civilian production planner is only consumed, not edited. Canonical verification and ledger promotion remain the integrator's responsibility.

Limitations: straight surveyed gravity routes only, maximum six km, four cached source candidates and eight manual lines per city; automatic investment installs one line per city. No pumps, tunnels, pressure qualification, source depletion, water disinfection or complete wastewater network. Throughput and quantities are game tuning, not engineering ratings. The full 5,000-discovery tree, campaign pacing and remaining artwork are unfinished.
