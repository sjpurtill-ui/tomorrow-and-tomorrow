# Opening fire chronology handoff

Branch `codex/opening-fire-wave`, worktree
`/Users/seanpurtill/Documents/Codex/tt-opening-fire-wave`, base
`0cc3f138c2e289f92b03970d34a63f36c2db2b90`.

## Delivered checkpoint

The five accepted D05 fire drafts are live discoveries: Ember Tending, Friction
Fire Ignition, Percussion Fire Ignition, Hearth Heat Retention, and Fuel Air
Drying. Ember tending is the opening anchor; deliberate ignition follows it.
Percussion ignition additionally rests on Stone Sorting. The discoveries describe
knowledge and operating conditions without granting fuel, fire, stock, or a free
aggregate output bonus.

Hearth Heat Retention is now the common causal foundation for Hearth Roasting
Control and Charcoal Production. Smoke Preservation and Pit Firing retain two
valid learning branches, but neither drying practice nor charcoal can bypass the
controlled-hearth foundation. The live authored catalog rises from 878 to 883
discoveries.

## Verification

- `test_opening_fire_knowledge.gd`: 5/5 cases pass.
- `test_food_preparation.gd`, `test_society_exchange.gd`, and
  `test_technology_requirements.gd`: 61/61 cases pass.
- `audit_technology_graph.gd`: 883 live discoveries, 669 explicit routes, zero
  graph errors, and zero blocked production products or plants.
- `git diff --check` passes.

These are focused causal and regression checks. No long pacing simulation or full
test sweep was run.

## Compatibility and limits

No save schema changes are present in this checkpoint. Existing saves that already
know a downstream discovery keep it and can operate it; new research must satisfy
the repaired foundations. Existing cooking and smoking continue to consume real
Timber. Persistent ember continuity, tending labor, ignition attempts, weather,
and fire danger remain the next operating slice; this checkpoint establishes the
knowledge graph they will consume.

The only shared hotspot change is the fire-catalog registration and three repaired
base definitions in `scripts/discovery_system.gd`. No military, GovernmentPeople,
terrain, project setting, or player-launch ownership changed.
