# Campaign scaling — second bounded pass

Base `e341b8eb`; worker `/Users/seanpurtill/.codex/worktrees/campaign-performance`, branch `codex/campaign-scaling`.

## Measured result

The same twelve-opponent, day-11238 campaign was replayed for 24 days against the first-pass baseline and this change, without profiling wrappers. Mean CPU per world day fell from **256.32 ms to 236.07 ms (7.9%)**; median from **237.23 ms to 214.87 ms**; p95 from **334.96 ms to 306.43 ms**. First-day warmup remains expensive (648.84 → 624.33 ms). Relative to the first pass's original 281.60 ms measurement, the two passes reduce mean CPU by about 16%. Runs vary with host load. This is not rendered FPS or a year-3000 guarantee.

## Causes and changes

The deeper profile measured 32,314 research eligibility checks in 24 days. Each boolean query used to construct copied descriptive route records, missing-foundation lists and imported route labels before selecting a route. The new boolean path checks the same common AND/OR requirements, local/alternative routes, experimental support threshold and score floor directly. Detailed descriptions and selected-route scoring remain available unchanged when requested. Imports and fieldwork keep the same foundations and route-ID behavior. No persistent eligibility cache is introduced, so new knowledge, evidence and context apply immediately.

The material-flow loop made 15,230 requests for constant material definitions. Those definitions are now immutable constants rather than a newly built dictionary of all resource types on each request. The public accessor still returns an independent copy.

Food spoilage and forecasts requested preservation factors separately for each food category, repeatedly traversing all known discoveries. They now compute all categories in one pass, reading current knowledge/adoption/staffing each time. Consumption, diets, weather, crop nutrients, spoilage, refrigeration and forecasts keep their existing rules.

## Scaling check

`tools/component_scaling_probe.gd` compares the old scalar and new bulk preservation paths using synthetic known-entry sets from 32 to all 5,491 catalog entries. The latter includes retired legacy records and is a lookup stress test, not a naturally reached campaign or a count of playable new discoveries. At 5,491 entries, the five-category query fell from **30.41 ms to 2.23 ms (13.6× faster)**. At 32 entries it fell from 175.9 µs to 17.08 µs. All compared category results match exactly. These component timings must not be represented as whole-game speedups.

## Validation and compatibility

Thirty-three focused cases pass across `test_scaling_predicates.gd`, `test_technology_requirements.gd`, and `test_simulation_performance.gd`, with zero failures/errors/skips/orphans. The new suite compares the boolean path against the original descriptive route oracle across the authored technology catalog, common missing foundations, empty OR groups, experimental support boundaries, imported evidence and negative score floors. Bulk preservation is checked against the scalar implementation across adoption, staffing, travel and settlement states; public material copies remain independent.

The 24-day replay compares the entire saved simulation state, including observer projections, RNG, research, stocks, populations, policies and full owning-city food forecasts. Only the wall-clock save timestamp is removed. No simulation differences were found. No save schema/migration changes, omitted days, reduced AI cadence or gameplay simplifications were introduced. Benchmark shutdown reports the same existing two-object/one-resource warning; focused suites have no orphans.

The campaign probe now requires an explicit `--allow-observer-summary` flag to exempt the first pass's deliberate projection change. Default comparisons are strict apart from the timestamp. Use the private userdata/fixture procedure in `CAMPAIGN_COST.md`; remove the temporary override before packaging. Raw measurements are in `campaign-scaling-2026-09-20.json`.

## Remaining limit

The original year-100 campaign remains unavailable. This pass removes costs that grow with knowledge and resource processing, but a complete world day is still synchronous and more settlements still increase daily work. No late-game throughput guarantee or player restart is implied.
