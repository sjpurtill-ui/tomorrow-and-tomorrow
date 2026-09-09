# Owned civilization simulation

Worktree: `/Users/seanpurtill/Documents/Codex/tt-full-civilization-parity`  
Branch: `codex/full-civilization-parity`  
Base: `ad90266903bf51ff1e56b9d2a206014fbab689ff`  
Integrator: the primary task; no concurrent workers or delegated agents.

## Behavior

New games default to **12 opponents**, as approved. The world menu offers 6, 12, 24 and 36 for the next new world. Changing this preference does not add or remove civilizations in the current campaign.

Every new civilization starts with the same 120-person population, age distribution, portable stores, knowledge and unbuilt settlement state. Human and opponent seats use the same seeded geographic viability search. Moving the human starting party does not move opponents. No player-centered proximity ring, population cap, growth penalty, free technology, synthetic military production, or prebuilt five-city opening is used in owned worlds.

`WorldSimulation` resolves mutable state to independent instances of the existing systems. The human remains the ordinary autoload owner; other civilizations have their own stores, local city economies, demographics, pregnancy/mortality accumulators, labor, officials, people direction, research, diplomacy, information, military and random generators. `CivilizationDay` calls the same daily functions for every owner. `SettlementConstruction` extracts the existing construction rule, with terrain callbacks retained for visible building events. GovernmentPeopleSystem still owns civic officials and daily local labor; HistoricalFigures owns exceptional contributors and field generals.

The controller chooses ordinary validated orders: ambition, movement, founding, scouting, diplomatic travel, funded additional settlements, recruitment, equipment lines, training policies, military bases, crews and command objectives. It cannot assign arbitrary simulation properties through its command interface. Existing general-led Army, Navy and Air systems execute those orders. Information books remain owner-specific. Map/diplomacy records project actual cities and forces rather than generating them.

Cross-civilization effects now reach the real owners: bilateral trades debit both inventories; gifts and aid deliver food/materials; finite geography reserves are shared by location; renewable surface growth is applied once per day; scout interception affects the real mission; land battle results update both populations/formations; air/naval contacts apply real hardware and crew losses; bombing damages actual buildings and bases. Occupation uses actual local cities and detached holding troops. Food relief and tribute transfer actual stores. Siege views reach both parties and restrict the affected city's food access. Treaty relief commits actual trained formations and carried food, travels, and returns without adding replacement troops.

## Validation

- 19 ownership tests passed, including direct human/owned daily equality, two-owner 90-day equality, exact save continuation, real founding, bilateral stock conservation, shared resource depletion/renewal, siege views, battle reservation, actual losses, actual air contacts with colliding local IDs, and trained allied relief.
- All **318 tests across 21 suites pass**, zero errors/failures/skips/orphans (`/tmp/tt-parity-final-tests2.log`), including occupation of the actual local city and conservation of detached holding troops. The final normal opening scene starts and shuts down cleanly (`/tmp/tt-parity-normal-main2.log`).
- Real terrain, 12 opponents, 365 daily steps: no world validation errors; every starting party within six kilometers of surface water. Final opponent populations 111–123; 1–2 funded cities per opponent. Average headless daily step approximately 389 ms on this Mac during development. This is a measured CPU scenario, not a frame-rate guarantee.
- Real terrain, 36 opponents: water access verified at all starts. This remains a larger-world option, not the default.
- 72 forecast comparisons against the base commit's calculation matched exactly. Optimization removes repeated environmental/weather calculations and derives the 30-day horizon during the 90-day pass; it does not alter food or demographic parameters.
- Normal main scene booted headlessly. No test scene was presented as the player game and no live game/editor was stopped.
- Shared-rule dependency inspection covered 75 scripts; no remaining mutable references to the human autoloads were found in that dependency set. UI code continues to use the human owner.

Reproducible world check:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-full-civilization-parity res://tests/owned_world_geography_probe.tscn -- --opponents=12 --days=365
```

Use isolated test userdata, as described by the worker workflow. Tests and observations must not be advertised as a running release.

## Saves and limits

New saves use a binary `TTWORLD2` body to preserve numeric precision, vectors, dictionary keys and random-generator state. The reader retains support for older text saves. Owned-state and human-system validation runs before resetting the live world. Failed nested imports restore the previous actor register. Private observations, rumors, chronicles, relationships, in-flight orders and training status survive saves.

A legacy campaign retains its original opponent model and populations; it is never silently replaced with newly spawned 120-person opponents. Loading one explicitly reports that a new world is required for equal civilization starts and the owned simulation.

This implements shared rules and ownership, not network transport. The scope deliberately excludes multiplayer networking and does not establish balance over an entire 2,500-year campaign. The first controller is a deterministic heuristic; better decisions and performance improvements can be developed without granting separate mechanics. Large worlds and late-game city counts need further profiling. A native-window usability assessment is not replaced by the headless checks.

The older held demographics adapter in `tt-civ-identities` / `1e918e3` was not merged. Shared-file changes in this task include `project.godot`, `local_terrain.gd`, `game_state.gd`, `discovery_system.gd`, `military_campaign.gd` and `save_system.gd`; integration must preserve the canonical base and unrelated files.
