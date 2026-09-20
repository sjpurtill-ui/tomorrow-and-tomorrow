# Campaign performance — first bounded pass

Base: `67d5d47c`. Worker: `/Users/seanpurtill/.codex/worktrees/campaign-performance`, branch `codex/campaign-performance`.

## Result

A 24-day replay of the available day-11238 campaign, with twelve opponents, reduced mean world-day CPU from **281.60 ms to 253.99 ms (9.8%)**, median from **258.75 ms to 231.58 ms**, and p95 from **359.40 ms to 338.63 ms**. Both final measurements exclude temporary profiling instrumentation. The first day includes cache warmup. These are headless CPU costs, not rendered frame rates or a year-3000 guarantee. The current quicksave was day zero; the reported year-100 campaign was not available in the inspected save locations.

The initial phase profile found consequences (~42 ms/day), resources (~40 ms), discovery (~32 ms), and secondary settlement work (~31 ms) among the largest daily blocks. Deeper instrumentation attributed ~42 ms/day to food, including ~21 ms/day to forecasts; these food timings overlap primary consequences and secondary settlement timings and must not be added to them.

## Changes

- World observer projections carry only the three city metrics actually read by city intelligence: material capacity, logistics and food days. Detailed food demand, forecasts and all other metrics remain in the owning city's state, UI snapshots and save. This avoids repeatedly copying detailed private city metrics between civilization views.
- Surface-resource searches request catchments without copying the full climate/water report. Authored-terrain search results, including unsuccessful searches, have a bounded 256-entry cache per resource system. The key includes seed, origin, resource, searched radius, previously opened fronts and the terrain provider. Changing the geographic provider invalidates its specialized provider; dynamic/generic providers retain the uncached path. Live stock, depletion and renewal are unchanged. Search caches are excluded from saves and reset with the world.
- Food forecasts skip botany lookups when no applicable ledger exists and resolve the site once per forecast. Daily consumption, nutrition, spoilage, local storage, crop nutrients, military provisions, weather and 30/90-day forecasts retain their existing rules.

## Validation

Seventeen focused cases pass across `test_campaign_performance.gd` and `test_simulation_performance.gd`, with no failures, errors, skips or orphan nodes. New checks cover cached success/failure, used-front and logistics invalidation, provider changes, cache bounds/reset/save exclusion, and preservation of full private city metrics.

The 24-day optimized replay matches the baseline saved simulation state, including all owning-civilization food forecasts, stocks, populations, research, missions, RNG and policies. Comparison exempts only the wall-clock save timestamp and the deliberately narrowed `strategic_regions[*].local_metrics` projection; its three retained values are checked against the original. No broader population or food fields are filtered. Every opponent's daily completion is checked. Both benchmark versions exited successfully but reported the same existing two-object/one-resource shutdown warning; the focused suites have no orphan nodes.

## Reproduce

Use an isolated worktree and a temporary `override.cfg` containing:

```ini
[application]
config/use_custom_user_dir=true
config/custom_user_dir_name="TomorrowCampaignPerformanceTests"
```

Copy the chosen campaign into that private userdata directory as `saves/performance_snapshot.save`. The probe refuses ordinary userdata and graphical rendering. Run `res://tools/campaign_performance_probe.tscn` headlessly at the baseline, then at the optimized revision with `-- --compare-baseline --allow-observer-summary` (the extra flag permits this pass’s deliberate observer-projection change). It writes only private `daily_cost_baseline.save` and `daily_cost_optimized.save`. Remove the override before packaging or launching. Results are in `campaign-cost-2026-09-20.json`; private campaign saves are not committed.

## Remaining limit

This is a first improvement, not sufficient evidence that a developed 3,000-year world meets the speed target. Daily work still scales with simulated settlements; the main thread still executes a complete world day synchronously. A later mature checkpoint is needed to identify the next scaling bottleneck. No food-system simplification, reduced AI frequency, skipped days or threaded-state rewrite was introduced.
