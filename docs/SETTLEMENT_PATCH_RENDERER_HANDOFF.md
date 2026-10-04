# Retained settlement patches

Worker checkout: `C:/Users/sjpur/.codex/worktrees/settlement-patches/TomorrowandTomorrow`.
Branch: `codex/settlement-patches`; base: `bdacd023ee3af689039ca07d1f95e649edafece5`.

The home settlement now keeps its `PersistentSettlementMorphology` root. Fixed
256-metre world cells, split by persistent sixteen-ID groups, retain their plot
meshes until their actual appearance changes. Routes, bounded common props, and
strategic/defense surfaces have independent keys. Replacement geometry is built
before its previous root is detached. A 64-entry hidden-patch cache retains
recently visited geometry; obsolete pending requests are replaced or cancelled.

At most two builders run per frame with a cooperative 2-ms camera-motion / 4-ms
stationary time allowance. This is **not a hard frame-time guarantee**: an
individual existing geometry builder cannot be preempted. Layout, common props,
strategic surfaces, and ground painting remain bounded shared work. The ground
tile worker preserves its separate public `build_if_home`/`serve` API; this worker
requests painting from the complete recorded plan, never from each patch.

Placement cache identity excludes economics, occupancy and weathering. Reused
plans bind current plot condition/damage without changing saved building sites.
Kit quarters keep their local ground treatment and props when the settlement
passes the old whole-town organic budget. The existing 512 detailed representative
/ first-128-plot placement limit remains; later supported plots retain their
existing placement-checked fallback roofs. No new simulation population cap or
new town is introduced.

Queued work checks its world, city, morphology, knowledge, society and age revision
before reading existing map helpers. Changed source state requests a new plan;
old installed geometry remains while layout priming finishes. Detail/density
eligibility is captured at request time, so an intervening zoom cannot stamp the
old request's signature onto a different thinning choice. Nested material/LOD
updates recurse through patch wrappers. Camera revisits can reuse retained roots.

`LocalTerrain.settlement_patch_stats()` exposes pending/installed/build/reuse
counts, hidden cache size/limit, last slice/job counts, largest individual job,
layout build count, and each patch root's node ID/signature/visibility. These
counters are transient and are not save data. No performance claim should be
inferred from a successful functional test.

Focused validation covers localized replacement, old geometry held until swap,
latest-request coalescing, a bounded hidden cache and exact revisit reuse, placement
versus appearance invalidation, unchanged saved sites after damage, stale-source
queue rejection, calendar-independent kit geometry, and a real field-mesh rebuild
that retains its untouched neighbor. Existing early/organic kit, year-71 surface,
city-evolution and architecture suites are included in the worker acceptance run.
The geometry-only architecture fixture suppresses live frame/city-card callbacks;
its detached labels are intentionally not a live UI fixture.

Validated with Godot 4.7.2 headless on 2026-10-04: all 117 existing cases passed
(15 early, 9 organic, 2 year-71, 8 city-evolution, 83 architecture). The same
run found a typed-array error in one new test fixture; after correcting that
fixture, the focused 9-case suite passed separately with zero errors, failures,
skips or orphans. Both final logs were checked for engine/script errors. Logs
are local ignored artifacts (`patch-tests-release2.log` and
`patch-tests-guard-fixed.log`), not portable performance measurements.

Save format and population/government/ledger authorities are unchanged. Existing
saved visual sites continue through the same explicit remember-layout path.
Shared integration hotspot: `scripts/local_terrain.gd`. New helpers and tests are
task-owned; generated imports, private test settings, logs and captures are excluded.
No canonical game/editor process is launched or stopped. The integrator must run
combined growth/ground acceptance and graphical validation before player delivery.
