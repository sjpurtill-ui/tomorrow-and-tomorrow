# Mature-campaign performance

Worktree: `/Users/seanpurtill/Documents/Codex/tt-year20-performance`
Branch: `codex/year20-performance`
Base: `418869c8e7a1efe362c0c878f1c705c223c428cd`
Integrator: primary agent. No concurrent workers or player/editor interruption.

## Cause and changes

A copy of the reported campaign, day 6531 with 12 opponents, reproduced approximately 0.87–1.11 seconds of ordinary daily CPU work before rendering. World projections repeatedly copied each city's entire historical ledgers; every opponent then received another copy. Secondary city ledger revisions also rebuilt unchanged building meshes. The calendar used Godot's frame delta, which can be capped during long frames, further understating elapsed wall time.

- Public city/map projections omit detailed historical ledgers; detailed reports retain an explicit full snapshot. Observer state remains independently mutable.
- Reuse secondary city meshes and resource ground overlays until their visual inputs change. Damage, location, detail level, fog and forced refresh remain invalidation inputs.
- Reuse deterministic geographical samples, seeded claim shapes and overlapping food-forecast climate calculations. Current stocks, consumption, births/deaths, daily research and all civilization turns still run.
- Avoid repeated government roster synchronization and ledger swaps within a single delegation pass. Read-only identity/architecture summaries reuse only their actual values/institution inputs.
- Research checks whether a channel has eligible work without needlessly ranking all alternatives when deciding whether attention is stranded.
- Count monotonic wall time for the ordinary calendar; pause/speed changes discard old catch-up debt. Bound work to one calendar day per frame and two seconds of debt; suspend gaps over ten seconds do not simulate offline time. The general-led campaign commitment clock is unchanged.
- Omit the regenerable 4,805-entry catalogue index from every civilization's save. Preserve RNG state and ignore freed UI objects safely. An older null civilization-direction section is repaired explicitly and reopens the missing choice.

## Measurements and limits

Godot 4.7.2, this Mac, copied real campaign; no opponent count/population/AI frequency reduction. Ordinary direct daily CPU is now about 0.30–0.31 seconds; the measured monthly turn was about 0.50 seconds. A release-template test advances 89.97 days in 30.01 seconds (2.998 days/second) without rendering. With the map rendered, it advances 87.02 days in 30.14 seconds (2.887 days/second). This is a major improvement, **not a guarantee of steady 3 days/second or smooth frame rate** on larger campaigns: synchronous daily work still creates frame stalls. The rendered benchmark produced 111 frames in 30 seconds. Further scheduling work remains worthwhile.

The opt-in probe suppresses deliberate discovery-announcement pauses only under `--uninterrupted`, counting the one actual discovery during the benchmark. Normal game announcements and research remain unchanged. A five-second paused warm-up precedes measurement. The rendered probe captured the actual map and closed itself. It was an isolated test app, not the player build.

The copied save round-trip shrinks to 62,735,809 bytes, saving in about 0.69 seconds. Measured reload remains about 12.3 seconds; no loading-speed claim. The original quicksave was not modified.

A twelve-day before/after comparison covers all 13 civilizations' populations, cohorts, full city ledgers, inventories, discoveries/progress, discovery RNG and military export. Everything matches except ten cohort values differing by at most approximately 1.4e-14 from removal of redundant normalization. No population totals, city state or subsequent gameplay outcomes differ. Exact save/load continuity passes.

## Verification

All 60 worktree regression cases pass (41 performance/secondary-city/ownership cases and 19 societal-value/research cases), with zero errors, failures, skips or orphans. Canonical integration is recorded in `INTEGRATION_STATUS.md` after its checks. Worktree evidence: `/tmp/tt-year20-tests-final.log`, `/tmp/tt-year20-outcome-final.log`, `/tmp/tt-year20-save-roundtrip.log`, `/tmp/tt-year20-rendered.log`. Benchmark artifacts and private save copies are excluded from source/export. New tests cover calendar debt/pause, observer isolation, lightweight city snapshots, save cache/RNG boundaries, freed UI state, social summaries, claim geometry, current-food forecast invalidation, research gates and retained secondary meshes.

## Reproduction

`tests/year20_performance_probe.tscn` requires a private `TomorrowYear20PerformanceTests` user-data directory and `saves/performance_snapshot.save`; it exits with an error otherwise. Never point it at normal player user data. Set an isolated local override for this worktree only, then invoke Godot with its absolute `--path` and this test scene. Default mode runs twelve daily turns; `--save-roundtrip` verifies a separate slot; `--paced --uninterrupted` measures wall-clock throughput. `--capture` also saves `user://performance-map.png` in a graphical probe. Tests and their saves are not bundled in the normal release. Release benchmarks used a temporary test main scene and private data name baked into an isolated app, with project settings restored immediately after export.

## Save compatibility and integration

Save version remains 1. Existing campaigns keep their rules, world, cities and inventories. Deterministic caches rebuild; old redundant catalogue data is accepted and ignored. An old missing direction is disclosed, not silently invented. Shared hotspots: `local_terrain.gd`, `discovery_system.gd`, `save_system.gd`; integrate deliberately before other changes to those files. No art-worktree changes are included. Do not launch a player game as part of this handoff.
