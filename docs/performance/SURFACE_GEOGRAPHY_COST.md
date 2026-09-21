# Surface-material geography cost

September 20, 2026. Worker `codex/daily-simulation-speed`, base `20033bcc`.

Resource-front searches requested a narrow surface-material report, but cache misses still built full civilization geography: water-source scans, climate profiles and terrain context. A separate bounded 512-entry cache now samples only authored surface catchments. Full geography reports reuse those catchments. Keys include world seed and origin; callers receive independent deep copies. Current stocks, depletion, regrowth and search eligibility are not cached or changed. Cache data is node-local and not serialized.

## Validation

- 16/16 focused tests pass, zero errors, failures, skips or orphans: `test_surface_geography_cost.gd` and `test_simulation_performance.gd`.
- Same private year-31 fixture (day 11238), twelve opponents, 24 simulated days, actual terrain provider, sequential baseline and changed runs.
- Mean CPU per world day: **246.780 → 223.002 ms (9.6% reduction)**. Median: **229.887 → 219.440 ms (4.5%)**. First-day cold cost: 649.732 → 334.909 ms. Much of the average gain is cold-cache work; excluding the first day means are about 229.26 → 218.14 ms (4.9%).
- Full saved simulation matches, excluding only save timestamp. Raw samples: `SURFACE_GEOGRAPHY_COST.json`.

No save-schema change, simulation simplification or player restart. One timing pair is evidence for this workload, not a guarantee of year-100 or year-3000 throughput. The earlier chart/research pass's timing increase is not separately resolved by this comparison. Remaining profile costs include daily food projections, pairwise observer views and growing settlement counts.

## Integration handoff

Owned files: `scripts/local_terrain.gd`, the new focused test and these measurement documents. The terrain file is a shared hotspot; apply the narrow commit, preserving other terrain work. Save-compatible; no release packaging. Canonical integration and validation are recorded separately.
