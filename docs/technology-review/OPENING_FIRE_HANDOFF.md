# Opening fire chronology handoff

Branch `codex/opening-fire-wave`, worktree
`/Users/seanpurtill/Documents/Codex/tt-opening-fire-wave`, base
`0cc3f138c2e289f92b03970d34a63f36c2db2b90`.

## Delivered checkpoint

The five accepted D05 fire drafts are live discoveries: Ember Tending, Friction
Fire Ignition, Percussion Fire Ignition, Hearth Heat Retention, and Fuel Air
Drying. Ember tending is the opening anchor; deliberate ignition follows it.
Percussion ignition additionally rests on Stone Sorting. The discoveries describe
knowledge and operating conditions without granting fuel, stock, or a free
aggregate output bonus; the first maintained fire is the physical source that
supplied Ember Tending's evidence.

Hearth Heat Retention is now the common causal foundation for Hearth Roasting
Control and Charcoal Production. Smoke Preservation and Pit Firing retain two
valid learning branches, but neither drying practice nor charcoal can bypass the
controlled-hearth foundation. The live authored catalog rises from 878 to 883
discoveries.

Each settlement now keeps a bounded physical fire record. The first accepted
Ember Tending practice begins from the found or transferred fire used to establish
the knowledge. Daily tending consumes stored Timber; an unfueled ember bed weakens
and can die. Friction ignition consumes Timber, while percussion ignition consumes
Timber and Stone. A failed percussion attempt returns the unlit tinder allocation.
Cooking and smoking require a live fire as well as their own operating inputs.
The Food & Water report shows ember strength, source, status, and maintenance fuel.

## Verification

- `test_opening_fire_knowledge.gd`: 10/10 cases pass, including physical fuel,
  extinction, two ignition outcomes, and reflected save-state continuation.
- `test_food_preparation.gd`, `test_society_exchange.gd`, and
  `test_technology_requirements.gd`: 61/61 cases pass.
- `test_civilization_owned_simulation.gd`: 19/19 cases pass with the additive
  reflected state, owner isolation, validation, and continuation paths.
- `audit_technology_graph.gd`: 883 live discoveries, 669 explicit routes, zero
  graph errors, and zero blocked production products or plants.
- `git diff --check` passes.

These are focused causal and regression checks. No long pacing simulation or full
test sweep was run.

## Compatibility and limits

The additive `fire_practice` save dictionary is reflected for the player and every
owned civilization and localized with secondary-city resource state. Older saves
without it receive an empty default; saves that already know a downstream fire
practice receive one initial continuity migration so existing cooking does not
silently break. Existing cooking and smoking continue to consume their separate
real Timber inputs. Dedicated tending labor, weather sensitivity, and fire danger
remain later operating depth.

Shared hotspots are the fire-catalog registration and three repaired base
definitions in `scripts/discovery_system.gd`, plus the additive state/reset field
in `scripts/game_state.gd` and validation in `scripts/save_system.gd`. No military,
GovernmentPeople, terrain, project setting, or player-launch ownership changed.
