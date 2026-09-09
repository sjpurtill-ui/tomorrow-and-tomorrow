# Civilization identity and diplomatic feedback checkpoint

READY after isolated validation on September 9, 2026. Base: `a31088e048c6790706139707e30e2ddcc45f0cf4`. Initial source: `6f1500b`; validation corrections are the next commit on `codex/civ-diplomacy-validation`. Integrator: this task. Validation worktree: `/Users/seanpurtill/Documents/Codex/tt-civ-diplomacy-validation`.

Changes: unique new-world civilization/city names; distinct generated flags; reported controlling-civilization names on map cards; no relocation of opponents when registering the player's home; a persistent envoy destination/schedule card with map focus; returned outcomes in a paused leader conversation; nested-modal pause ownership and blocked speed shortcuts; a session-only API connection panel and specific connection-failure explanations; shared civic/foreign personality axes and goal-driven foreign preferences.

The API panel stores the key only in the game process environment, never in a campaign or project file. The actual Mac connection remains unconfigured until the user supplies a key locally. Existing civilization and city names and recorded locations survive loading. New names are generated for new worlds; flags are deterministic by world and civilization. Optional mission destination labels preserve older mission records without a save-version bump.

Validation covers all 138 named tests in the civilization, identity, city-label, city-intelligence, civic-people, connection-settings, player-placement and diplomatic-journey suites across the full run and targeted reruns. The older military fixture assumed an undiscovered war-games course completed in one month; it now explicitly supplies the required discovery and resources and verifies a course takes multiple months. The full-run century and billion-population checks passed. Latest modal/outcome checks cover speed restoration, nested windows, speed-shortcut rejection and visible returned results.

Logs: `/tmp/tt-civ-ready-tests.log`, `/tmp/tt-civ-ready-regression.log`, `/tmp/tt-civ-modal-final-tests.log`, `/tmp/tt-civ-training-final-tests.log`, `/tmp/tt-civ-reply-tests.log`. The first full regression run includes the obsolete training-fixture failure; its replacement and the following cases pass in the targeted rerun. Do not describe that original log as an all-green run.

The headless foreign-diplomacy integration probe passes (travel, escrow, counteroffers, commitments, war, saves). The existing pronouncement HTTP contract probe passes against an isolated local mock server; that server was closed after the test. This is not a successful live OpenAI connection. Flag textures were inspected at 64×40 and 32×20 pixels. Dialog layout was checked headlessly; there is no claim of a native player-window visual audit.

Shared hotspot: `scripts/local_terrain.gd`. No other worker edited the canonical checkout. Tracked canonical main was clean at the start. No player/editor was stopped or launched; the previously launched player had exited when process state was checked.

## Excluded work

`1e918e3` on `codex/distinct-civilization-identities` is HELD in `/Users/seanpurtill/Documents/Codex/tt-civ-identities`. It contains incomplete shared-demographics / one-city-start work. Do not merge that branch tip. Opponent supplies, construction, research, recruitment and founding still require the shared actor simulation described in `CIVILIZATION_PARITY_AUDIT.md`. Full rule parity and multiplayer readiness are not delivered by this checkpoint. No artificial population slowdown is included.
