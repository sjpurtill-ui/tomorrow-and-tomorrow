# Civilization parity audit — September 9, 2026

The design requirement is one ruleset for every civilization. A human or AI controller chooses actions; ownership does not grant different costs, knowledge, population rules, or access to technology. Future multiplayer should replace a controller, not replace the simulation. Networking is outside the current scope.

## Confirmed causes of the crowded opening

- `CivilizationSystem.reset_for_new_world` creates five populated strategic districts per opponent, although `settlement_count` begins at one. `CityIntelligence.sites` renders all five as cities. Those places were pre-created, not built during the first ten years.
- `register_player_origin` previously moved three opponents to connected land 96–224 km from the player's chosen origin. The placement fix removes that relocation. Seeded opponent homes remain independent of player placement.
- `ProgressionSystem.advance_rival` raises settlement count from a population formula. No founding party, route, material bill, arrival, or local city economy backs that increase.
- Rival demographic and economic development use monthly aggregate formulas. Player food, water, construction, reproduction, and labor use daily local systems.

These are implementation differences, not an unavoidable balance problem. Population caps, growth penalties, delayed spawning, or player-centered exclusion rings are not the solution.

## Interface and placement checkpoint

New worlds receive unique civilization names and individual city names from a 64-civilization / 320-city catalog. Flags combine twelve color palettes, eight patterns, and twelve emblems. Existing names remain intact; foreign map cards identify the reported controlling civilization separately.

Envoy dispatch now retains a destination and schedule card with map focus. A returned delegation opens a paused conversation. Nested connection settings preserve the previous simulation speed. The connection panel accepts a key for this process only and distinguishes missing local configuration from remote request failures. No real API connection has been verified: the user's credentials were configured only on Windows.

Foreign leaders use the same five personality axes as civic officials. Their stated priorities respond to survival and war and influence strategy selection and negotiations. This does not establish shared civilization simulation.

## Simulation refactor — HELD, not delivered

Development remains in `/Users/seanpurtill/Documents/Codex/tt-civ-identities`, branch `codex/distinct-civilization-identities`, held commit `1e918e3`. Do not merge that branch tip as part of the interface checkpoint.

The isolated work extracts the player's daily demographic step for independent civilization state, retains pregnancy and mortality accumulators, gives new opponents the same founding population and age distribution, and separates actual settlements from unpopulated strategic territory. Identical demographic inputs produce identical results across two simulated years; independent state and save continuation have dedicated tests.

It is not ready to replace the opponent simulation. Its food, health, shelter, and exceptional mortality inputs still come from an adapter over the old aggregate economy. Opponents also lack a real founding action. Enabling one-city starts while leaving expansion unimplemented would make the game less complete. Do not describe this as full parity, a balanced 2,500-year game, or multiplayer readiness.

## Required next work

1. Give each civilization explicit owned state for cities, stores, workers, knowledge, equipment, leaders, and information. Keep the current player-facing state as an adapter while moving systems to explicit ownership. Preserve GovernmentPeopleSystem's ownership of civic officials and daily city labor.
2. Run the same resource, water, food, construction, demographic, and discovery functions for each owner. Remove monthly opponent capability gains only as their real replacements become operational.
3. Route founding through shared validation and costs: a known viable destination, a traveled route, a conserved founding population, portable materials, food, travel time, and a completed city with its own local simulation.
4. Let AI controllers issue those same orders. Priorities and personality may change decisions; they must not grant free stores, troops, technology, or settlements.
5. Replace aggregate military production and force projections with the shared equipment, recruitment, training, supply, and combat ledgers. Maintain separate land, air, and naval mechanics with leaders executing objectives.
6. Test identical starting states plus identical orders for equal outcomes, conserved resources/population, information boundaries, save continuation, and controller replacement. Keep deterministic order validation and authoritative time suitable for a future networked host. Add networking later.
