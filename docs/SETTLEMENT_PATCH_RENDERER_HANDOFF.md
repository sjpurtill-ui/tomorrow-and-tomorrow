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
individual existing geometry builder cannot be preempted. Common props,
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

## Growth hitch follow-up

The acceptance stress test exposed two separate growth costs: completed layout
searches repeated for unchanged parcels, and the first fallback parcel loaded
unrelated strategic texture sheets. Placement now advances one changed parcel
per refresh, reserving all saved sites, and publishes a complete plan only when
that request is ready. A parcel beyond the inherited kit's budget does not run
that solver. One immutable plot snapshot is shared by the request's builders;
remembering a site never first copies the discarded full plot record.

Geometry LOD now follows camera scale. The old 96-parcel threshold changed LOD
for every inherited quarter as the 97th parcel appeared. The retained patch
manager provides stable camera behavior without that count-dependent switch.
Inherited routes, props whose inputs are unchanged, and undefended village
stage roots also survive crossing the 128-parcel kit budget. Defense continues
to use its own authoritative snapshot. Strategic town/city rendering remains.

Common ground and roof atlases load with the map script; only strategic fabric
materials bind strategic sheets. This moves common asset startup cost out of
the first growth job without reducing texture quality. Ground painting reuses
the exact completed request plan.

Diagnostics now include per-key build durations, the slowest job key, signature
components, layout pending/step counts, maximum layout-step duration, and
vegetation/request/ground refresh costs. The isolated prepared-history probe
passed 145/145 checks through generations 0–12/year 3000. In the final measured
headless run before the last ground-plan reuse, 96→128 and 128→129 each replaced
zero old plot roots; a single repair replaced one. The largest geometry job was
about 17 ms, and the largest placement step about 16.5 ms. These are worker
headless observations, not a GPU frame-time claim or a full simulation benchmark.
The approximately 52 ms ground request measured on integration base 2750f788 is
owned by the separately advancing ground worker. Combined GPU validation is
still required. Initial synchronous loading and strategic texture first use
remain outside a hard per-frame time guarantee.

Final worker regression after the ground-plan reuse and village-stage continuity
changes: 129/129 cases passed across the patch, early/organic, year-71,
city-evolution and architecture suites, with no script/shader/engine errors in
`artifacts/patch-tests-incremental-final.log`. All save/site identity tests pass;
there is no save schema change.
