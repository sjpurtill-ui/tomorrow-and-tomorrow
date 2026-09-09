# Naval patrol movement

READY for integration from `codex/naval-patrol-movement`.

Worktree: `/Users/seanpurtill/Documents/Codex/tt-command-order-state`  
Base: `384383917f3666dfb9ec8320a6f61846a991af77`  
Source commit: the commit containing this handoff (reported by the integrator after commit).

## Behavior

Previously, a naval patrol or convoy raider reached its first operating waypoint and then stayed at that point indefinitely unless a contact appeared. The new daily movement regression reproduced twelve stationary-movement failures before the implementation (`/tmp/tt-naval-patrol-repro.log`).

Patrols and convoy raiders now choose another clear search leg automatically after arrival. The search uses the player's existing drawn main-map area. Each leg stays inside that polygon, within the home port's craft range, and within one day's sailing distance. It uses the existing land authority and sea-edge sampling. Concave boundaries are checked for segment crossings. The bounded search examines at most 64 local grid candidates once per daily update, without an AStar search or per-frame terrain scan.

Fresh hostile contact reports take precedence over searching. Patrols resume searching after reports expire; strike forces retain their separate waiting-in-port, contact pursuit and return behavior. Repair orders, transport and stand-down keep their existing priority. Fuel is still charged before movement: shortages halt the ship and resupply resumes the retained route without another player order. Status text distinguishes Patrolling, Searching for convoys and holding station when no clear search leg is found.

## Validation

All **137 tests passed**, zero errors/failures/skips/orphans, exit 0, in the explicit worktree across:

- `tests/test_joint_campaign_loop.gd`
- `tests/test_joint_operations.gd`
- `tests/test_training_strategy.gd`
- `tests/test_main_map_services.gd`
- `tests/test_command_hierarchy.gd`

Log: `/tmp/tt-naval-patrol-tests.log`.

Five added regressions cover repeated movement for early patrol craft and powered raiders; islands, concave boundaries, range and daily speed; fuel shortage/resumption and deterministic JSON save continuation; contact priority/expiry and strike-force return; and repair/stand-down priority. Existing transport delivery and conservation, carrier movement/wing range, training policy, hierarchy and separate-service UI tests also pass. No native player screenshot or live-play performance measurement is claimed.

## Compatibility and limits

No save schema, equipment, personnel, research, command hierarchy or training policy changes. Daily waypoint selection depends only on existing world seed, force ID, day and position; saved routes continue normally. Both player and rival forces use this movement path. No shared integration hotspot changed: only `scripts/joint_geography.gd`, `scripts/joint_operations.gd`, the campaign test suite and this handoff are owned.

Search remains a daily simulation, with contact checks at simulated positions. It does not add continuous detection along a day's entire path, hourly naval combat, guaranteed exhaustive region coverage, or numerical HOI4 parity. Extremely narrow or isolated areas can have no usable sampled search leg; the force holds station with an explicit status rather than crossing land or the drawn boundary. Sea sampling retains its existing two-kilometre resolution. Initial transit and contact pursuit keep the existing sea-routing rules and may leave the operating polygon in transit. Existing zero-distance stand-down arrival still follows the previous one-day route/fuel processing; this pass does not alter it.

No player or editor was launched, stopped, focused or restarted. The integrator must verify canonical main and build the standalone release before delivery. Remove only the task-owned test override after validation; preserve generated/unrelated worktree files.
