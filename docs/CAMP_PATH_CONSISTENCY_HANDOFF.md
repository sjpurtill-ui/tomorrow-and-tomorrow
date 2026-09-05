# Camp path contrast consistency

Worker: `C:/Users/sjpur/tt-army-map-readability`, branch `codex/camp-path-consistency`, base `9e96c5786dcb909f4f1c3c959311f06dc170d8f4`.

Founding paths now retain the same base contrast regardless of the camera zoom when the route mesh was built. Previously crossing 0.42 could leave different baked vertex alpha depending on approach direction or rebuild timing. Existing close contrast is retained; road materials still handle screen-space detail.

Tests: regression on actual emitted vertex colors at zoom 0.20, 0.42, 0.43 and 1.0 produced two failures before the fix. All 83 settlement visual architecture tests pass after the fix. No geometry, path width, route data, simulation, UI or save changes.

Shared-file hunk: `_create_persistent_settlement_routes` in `scripts/local_terrain.gd`, plus its architecture test. No conflicts anticipated with service-ground pass already integrated into this base. Generated imports remain unstaged.

User requests stopping graphics iteration after this pass and launching the newest canonical game. Integrator must review, integrate, verify combined main and launch through the authoritative launcher. Worker did not launch a preview or modify the playable checkout.
