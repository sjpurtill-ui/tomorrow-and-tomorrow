# Carrier wing map positions

Base 15c2c27; worktree /Users/seanpurtill/Documents/Codex/tt-main-map-services, branch codex/main-map-services. Primary agent owns the overlay and tests and acts as integrator.

READY: deck-wing markers, click targets and displayed route origins use the authoritative force_position resolver instead of the wing's stale stored position. Wings track a moving carrier without mutating save data, and use independent positions again after detachment. No new UI, simulation authority, or save fields.

Validation: 34 tests pass across main-map services and joint campaign loop, zero errors/failures/orphans. New behavior test checks that the old location cannot select the wing, the carrier location does select it, carrier movement updates the marker and detachment restores independent positioning without altering the stored position. Log /tmp/tt-carrier-markers.log. The test fixture initially omitted display names; corrected before the passing run. No shared-file conflicts. Player/editor not touched; live pointer validation and next normal launch remain separate from headless evidence.
