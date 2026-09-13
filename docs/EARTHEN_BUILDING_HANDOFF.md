# Earthen building methods

Worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/earthen-building-processes`, base `b75d93696f2f480406757a40dd68a1df5bc4eabf`. Integrator owns new EarthenBuildingKnowledge, additive CivilianIndustry and Discovery registration, two BuildingMaterialOperations profiles and their tests. No SettlementModel, terrain, GameState or SaveSystem edits.

Two existing authored identities retain their original predicates: adobe_wall_construction and wattle_and_daub_walls. Three finite workshop recipes prepare mold-ready Adobe Mix, Earthen Daub and Wattle Lattices from real earth, sand, reinforcement, water, wood and work. The resulting stock is not usable housing by itself.

The existing settlement growth owner pays each profile's local materials, roof protection and construction. Adobe projects mold and dry units at the site before wall assembly; worker input cannot skip that calendar stage. Wattle projects apply infill to a paid timber lattice, then dry before occupancy. The existing plot curing fields record 28 and14 suitable drying days respectively. The existing monthly owner samples this city's seasonal temperature and precipitation, caps any gap at30 elapsed days, and grants no repeated same-day drying. Cold or very wet conditions produce no drying; favorable conditions approach one suitable day per elapsed day. These coefficients are game abstractions, not construction schedules. Adobe walls receive no assembly progress while units are wet. Infill stays under construction until dry.

The existing housing capacity, allocation, maintenance and save authorities remain unchanged. Earthen weathering responds to local precipitation; repairs consume compatible local mix and available builder work. Roof material and initial protective fabric are included in the paid profile. No per-brick actors or duplicate building records are created. Visual material proportions use the existing architecture pipeline; no terrain visuals are changed.

References: [National Park Service adobe bricks](https://www.nps.gov/tuma/learn/historyculture/adobe-bricks.htm), [NPS adobe rain testing](https://home.nps.gov/articles/sodn_adobe_test_walls.htm), and [SPAB infill panels](https://www.spab.org.uk/advice/infill-panels). They support the distinction between unit drying and applied infill, and the importance of moisture protection and compatible repairs.

Limitations: climate is sampled at the existing monthly building step, not reconstructed as daily rain history. Mix and wall geometry are compatible aggregate classes, not engineering analysis of arbitrary soil or loads. Routine small repairs retain the existing aggregate maintenance rate rather than a new repair-drying queue. Detailed roof runoff, dynamic drying shrinkage, new standalone illustrations and full historical pacing remain outstanding.

Save compatibility: existing optional building-material profiles and curing fields are reused. Legacy plots are unchanged. New earthen completion markers require sufficient recorded drying and consistent dates. Whole actor save/load preserves partially dried units and subsequent assembly; human and secondary-city records use the same validation path.

Initial acceptance:9 new cases and11 existing building-material cases pass. Initial test setup failures were corrected (typed settlement array, full city identity and actor recreation after world reset). A malformed completion-marker test verifies the new narrow validation. Combined textile/city/owned-world checks and canonical acceptance pending.

## Canonical acceptance

INTEGRATED at `2d0048225faccc4fc1f7563a510e74c8c6565aa9`. All110 combined worktree cases and61 canonical cases pass. Canonical suites: earthen9, textile12, clothing27, city13. Clean graph716/498 routes/365 recipes/18 facilities, exact716-definition snapshot and15 catalog-tool tests pass. Logs `/tmp/tt-earthen-textile-results.json`, `/tmp/tt-earthen-textile-canonical-canonical-results.json`. Headless boot reaches the direction screen with exit-time resource cleanup warnings; full pacing and new subject art remain outstanding. No player launch/package rebuild.
