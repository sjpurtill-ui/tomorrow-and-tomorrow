# Scout expedition planning and truthful duration cards

Base: `ce45a15ea09e9973091c956e5222ed53ca30e2f3`.
Worktree: `/Users/seanpurtill/Documents/Codex/tt-scout-route-planning`.
Branch: `codex/scout-route-planning`. Primary agent is the designated integrator.

## Behavior

Automatic-heading exploration and recruitment now obtain a terrain-checked route in the quote, before departure is enabled. Departure uses that same deterministic proposal and rechecks its physical route before spending. Automatic selection searches the full compass and permits nearby surveys down to a four-kilometre candidate radius; a long allowance no longer requires a route at least 30% of theoretical range. Explicit headings retain their ordered sector. A blocked preview explains the reason before any people or food depart.

Duration cards show the actual planned outward route and heading, state that surveying and return travel are included, and describe dangers as unknown. The theoretical maximum is retained internally as a travel budget, rather than displayed as promised reach. Patrol exposure remains the existing planning estimate; it is no longer presented as a general safety rating. Changing target or heading clears obsolete dispatch errors. No speed, provisions, casualty or return-time balancing was changed.

Open route planning tests simple paths first and bounds coastline detour attempts to eight. A 32-entry route-only cache avoids terrain searches on repeated toolbar refreshes. World, day, origin, range, mission identity, heading, watercraft and geography-authority changes invalidate the corresponding proposal. Resource and personnel availability are recalculated; cached routes are copied and validated at departure. Nothing is revealed before a party's physical return.

Owned files: `scripts/civilization_system.gd`, `scripts/local_terrain.gd`, `tests/test_scout_route_planning.gd`, two existing test fixtures, and this handoff. Shared hotspots were edited narrowly; no terrain generation, civic labor, direct army controls or save schema changes. Existing missions keep their recorded routes, supplies and dates. Planning cache is transient and not saved.

## Validation

**60 focused worktree tests pass**, zero errors, failures or orphans (`/tmp/tt-scout-planning-focused.log`). Eight new cases cover opposite-direction access, island/local surveys for all durations, stable quotes and exact departure routes, blocked previews with no spending, explicit heading preservation, card content, generated home terrain, and route-cache invalidation with current supply checks. Existing scout/route/return cases from `test_civilization_system.gd`, map onboarding, rumor network, expedition findings and return-speed suites also pass.

The generated-terrain case uses world seed `1090456577` from the running game's log, without loading its campaign or instantiating a scene. All four options found valid routes; first calculation took about 424 ms total on this Mac. Repeated unchanged quotes reuse routes. This validates generated geography with fixture capabilities, not every current player resource/research value or native UI interaction.

A broader civilization run exposed an existing peace-incident fixture failure (expected one incident, got zero), reproduced independently against unchanged canonical base `ce45a15` in `/tmp/tt-scout-peace-baseline.log`. That test and the incident system are unchanged. The unrelated century simulation was stopped in its owned headless process; no full civilization-suite pass is claimed. Two obsolete fixture assumptions were corrected: settled-map help uses the already-integrated city/dismissal wording, and mobilization records are checked for conservation rather than assuming only four categories before naval/air crews existed. The full run's initial new cache fixture failed because replenishing its legacy Food field did not replenish typed food stores; the final fixture restores authoritative stores and passes.

No graphical probe, player/editor interruption or remote push. Temporary test files and userdata overrides are removed after testing. Canonical integration/validation is recorded separately.
