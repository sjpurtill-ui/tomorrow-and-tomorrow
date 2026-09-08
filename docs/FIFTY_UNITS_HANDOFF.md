# Joint military operations and settlement architecture

Status: INTEGRATED through `f996fa6`, with player integration fixes `2b2e3ea` and `f66bfcb`; version 2026.09.07.1 relaunched in canonical player PID 60507. Worktree `/Users/seanpurtill/Documents/Codex/tt-fifty-units`, branch `codex/fifty-units`, base `da9f91718a182230c3ebb5286ed8556dd8bb6829`. Replaces the held `33ab016` checkpoint.

## Playable changes

- Exactly 50 neutral land archetypes, plus 21 naval and 16 air types. Separate progression maps expose their equipment, research prerequisites, training and roles.
- Naval & Air Command opens from Military. Build city-funded bases, start researched production, reserve real equipment and crews, commission/train, split/combine, group task forces, rebase, and ferry compatible wings to carrier decks.
- Draw named air/sea polygon boundaries directly on the operations map. Save, select, assign and delete unused areas. Range coverage and overlapping control use those boundaries. No player operating-area grid.
- Naval routes check actual land/water connectivity. Transport withdraws city food, carries armies and cargo, returns to base, and exposes cargo to raiders and escorts. Invasions require preparation/control and hand landed troops into the existing general-led city campaign.
- Fuel, repair, base capacity, training and weather affect readiness. Patrol/contact/strike response, interception, screening and submarine detection produce bounded aggregate combat losses. CAS, reconnaissance, bombing, logistics disruption and air supply affect actual campaign records.
- Rival base construction, research-gated industrial orders, crews, training, operating missions and losses use the joint loop. Joint crews are removed from rival available land manpower. Rival industry/fuel remains the civilization's aggregate military stockpile model.
- Existing production pauses visibly when its required service base becomes unavailable.
- Twenty-four cached detailed building families cover masonry, industrial and modern terraces, courtyards, corners, villas, arcades, public halls, workshops and warehouses. They reuse saved plot/road/water placement, bounded batches, wear and damage.
- Structural steel, reinforced concrete, safety lifts and curtain walls have named research. Completed upgrades pay industrial materials and gain supported storeys. Old plots keep their family and modern neighborhood views retain inherited masonry districts.

## Verification

Worktree Godot 4.7.2 headless: 120 tests across 11 suites passed before final battle refinements; the expanded joint loop passes 16 tests and city intelligence passes 14 tests. The intelligence raid fixture now specifies viable military strength, fixing its documented baseline failure while retaining the unknown-target and stale-intelligence assertions. Final canonical combined total: 139 tests passed; all 30 joint campaign/city-intelligence tests passed again after the final integration fixes. Live keyboard opening/closing, home-city marker, separated labels and researched production choices were inspected.

The real current campaign was saved through its game UI and loaded into isolated test userdata: day 25512, population 777. Joint state validated; the original save was not modified by the compatibility check. Existing saves without joint state initialize empty joint forces. Polygon and transport payload corruption is rejected before joint-state mutation.

## Scope and limits

This is a playable implementation, not verified numerical equivalence with Hearts of Iron IV. Operational updates use this game's daily clock; fleets/wings are aggregate craft counts. Combat screening, detection and missions are simplified compared with HOI4's complete ship-component, doctrine, engagement and aircraft-stat model. Rival overseas invasions and rival supply convoys are not implemented; rival fleets and aircraft conduct combat/control missions. Land campaigns retain the established general-led interface.

Detailed architectural representatives are bounded to the shared inherited plot budget; larger city fabric continues through existing aggregate district rendering. Mesh/placement tests establish geometry and continuity, not a claim of completed visual art review at every era/altitude. Current campaign technology is retained, so it does not immediately acquire modern buildings or aircraft.

## Integration ownership

Shared changes: `civilization_system.gd`, `city_intelligence.gd`, `combat_simulator.gd`, `discovery_system.gd`, `early_settlement_visual.gd`, `food_system.gd`, `game_state.gd`, `local_terrain.gd`, `military_campaign.gd`, `persistent_production.gd`, `planet_environment.gd`, `resource_system.gd`, `settlement_model.gd`. Canonical main had only integration-record additions beyond this branch base. No archived checkout or other worker files were copied. No player game has been launched from this worktree.
