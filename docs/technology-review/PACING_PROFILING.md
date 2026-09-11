# Optional pacing stage measurements

The pacing harness accepts `--profile` and writes schema 8 reports with `profiling_enabled` and a `timings` dictionary. The ordinary simulation takes the same steps in the same order. A new optional final dictionary argument on `CivilizationDay.advance` collects timings only when nonempty; existing callers continue using an empty default, with no clock reads or saved state.

Example, from the implementation worktree:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-technology-implementation -s res://tools/audit_history_pacing.gd -- --days=365 --wall-seconds=60 --profile --out=/tmp/tt-profile-year.json
```

Each timed group reports calls and accumulated microseconds. Groups are controller, context, operations, discovery, resources, consequences, civics, economy, government, construction, secondary settlements, city trade, primary settlement morphology, progression, military-and-travel, and convoy. They include intervening bookkeeping and local-population wrappers. Operations includes initial allocation synchronization; consequences includes the second synchronization. Schema 8 separates secondary-city resource processing, intercity trade and primary monthly morphology. Older reports combine these as settlements. These are daily execution intervals, not isolated benchmarks of the named functions. The home-unavailable early return is not covered.

## Initial controlled comparison

Both runs completed 365 days from the same seed against the 377-discovery catalog. Initial/final snapshots, annual snapshots, discovery events and final bottleneck dictionaries are exactly equal with profiling on and off. All fourteen groups have 365 nonnegative samples. The unprofiled report has an empty timings dictionary. Evidence is archived in [one-year-stage-timing.json](pacing/one-year-stage-timing.json).

In this sample, settlements consumed 24.2% of measured stage time, consequences 18.7%, discovery 18.0%, and resource processing 9.6%. These measurements are affected by the concurrently running long diagnostic and local scheduling. The first year has only 121 people at its endpoint and no discoveries completed, so it cannot establish late-game scaling. No performance improvement is claimed.

Next use: profile longer runs once the existing 250-year-target process terminates, compare stage shares at larger populations and knowledge catalogs, and optimize only measured costs while retaining deterministic behavior. The active process loaded older scripts and is not instrumented by this change. Neither this first-year comparison nor partial output from that process verifies the required 2,500–3,000-year progression.

No save format or player UI change. Integration conflicts: `scripts/civilization_day.gd` and `tools/audit_history_pacing.gd`. Changes remain isolated pending the designated integrator.


## Annual intervals and morphology counts

Schema 7 adds `timing_intervals`: non-overlapping intervals ending at each simulated year and at the final partial year. Each contains from/to days, elapsed wall microseconds and per-stage call/time deltas. Interval sums exactly reproduce cumulative stage totals. Annual progress output includes the just-completed interval, so a live process can be inspected without pretending its target has completed. Disabled profiling produces no intervals. Annual/final snapshots also record the actual settlement plot count and plot-history record count, separate from founding projects.

A matched 400-day profiled/control pair completed with identical initial/final/annual snapshots, discoveries and bottleneck dictionaries. Intervals are exactly days 0–365 and 365–400; all fourteen stage sums equal the final totals, each with 400 samples. Evidence: [stage-interval-verification.json](pacing/stage-interval-verification.json). The endpoint has 19 settlement plots and 41 plot-history records. This checks instrumentation semantics, not full-history performance.


## Secondary settlement cost attribution

Schema 8 replaces the combined settlements interval with three intervals, bringing the total to sixteen. It also records settlement counts in snapshots and owned-city population/plot/last-resource-day summaries in final bottlenecks. The diagnostic observes state without changing it.

A paired 400-day comparison against the 383-discovery catalog completed with exactly equal initial/final/annual snapshots, discovery events and bottlenecks. Each of sixteen groups has 400 calls; annual/partial interval sums match cumulative totals. The control collects no timings. Archive: [secondary-settlement-stage-timing.json](pacing/secondary-settlement-stage-timing.json).

Measured shares in that run: secondary settlements 22.845%, city trade 1.547%, primary morphology 0.699%. The endpoint has two settlements: the primary contains about 81.03 people and 19 plots; the secondary about 40.70 people and 13 plots, last processed on day 400. Secondary processing executes resources, consequences/demographics, economy, construction and morphology for its own population and stocks. It must not be removed as though it were duplicate primary-city work.

This changes the next optimization target from primary morphology to identifying repeated computations within the full secondary-city day. The running 250-year-target process loaded the earlier fourteen-group implementation; its combined settlement measurements cannot be retroactively separated. No performance improvement or late-game scaling result is claimed from this attribution pass.

## Terminal result: profiled 250-year target, 377-discovery build

The process launched at `49fe572` and tracked as session 29066 exited successfully after its one-hour wall budget. It simulated **53,896 days / 147.6603 years**, discovered **150 technologies**, and ended with population **4,441**. Its requested 91,250-day / 250-year target was **not reached**. Archive: [profiled-wall-limited-147-years.json](pacing/profiled-wall-limited-147-years.json). Every timing interval is contiguous, and interval call/time sums exactly reproduce cumulative totals.

| Completed annual interval | Population | Known discoveries | Primary plots | Combined settlement ms/day |
| --- | ---: | ---: | ---: | ---: |
| Year 1 | 121 | 0 | 19 | 2.774 |
| Year 50 | 318 | 42 | 24 | 17.493 |
| Year 100 | 1,126 | 92 | 38 | 65.510 |
| Year 147 | 4,353 | 149 | 85 | 142.036 |

Combined settlements account for 74.94% of cumulative measured stage time. This is the principal measured scaling problem in this run, not proof that primary morphology alone is responsible. Schema 7 did not count all cities or separate secondary processing, trade and primary morphology. Population growth, city proliferation and their internal operations remain confounded.

Endpoint food is 93.47 days, intake ratio 0.97923, army delivery ratio 0.89242. Stone 112.71, Timber 181.87, Clay 72.28, Fiber Plants 510.77. There were 87 primary plots and 578 primary plot-history records. The five founding projects are not a total building count. This run predates glassworking, electronics, digital logic, AI civilian/acquisition decisions, survey-pass reuse and monthly-scope optimization. It is not a controlled speed comparison with another build, and no millennial or full-world acceptance follows from it.

A replacement diagnostic was launched from `6bc29be` with the current 400-discovery catalog and schema 8: session **95746**, target 91,250 days, wall limit 3,600 seconds, `/tmp/tt-current-400catalog-250-profile.json` and `.log`. It includes sixteen timing groups and city counts. It is a new live run, not a completed result. The previous handle 29066 is terminal and must not be restarted or described as still running.

## Secondary-city internal stages

Schema 9 adds a separate `secondary_timings` dictionary and annual `secondary_stages` deltas. The original sixteen outer stages remain unchanged. Seven inner stages measure resource-scope entry, resources, consequences, economy, construction, morphology and resource-scope exit. **These are nested inside `secondary_settlements`; do not add them to the outer total.** Their counts are processed city-days rather than national days. Resource-metric snapshot copying is included with construction; population scopes remain inside each operation. Context generation, city lookup and surrounding loop/bookkeeping remain in the outer interval. The home-unavailable recovery branch remains outside the normal profiling flow.

A 400-day three-way comparison (schema-8 baseline, schema-9 profile, schema-9 control) matches every recorded gameplay field. Profiling-disabled dictionaries/intervals are empty. All inner and outer annual deltas reconcile exactly to cumulative totals, and inner time remains within its enclosing interval. Each inner stage recorded 280 processed secondary-city days. Archive: [secondary-city-detail-timing.json](pacing/secondary-city-detail-timing.json).

This early sample attributes 53.70% of detailed secondary time to consequences, 23.77% to resources, 13.79% to economy, 3.36% to construction/snapshot copying, 0.62% to morphology and 4.76% to resource-scope entry/exit. These are diagnostic observations, not a general speed benchmark or mature-city attribution. They make repeated consequence/demographic work the next inspection target. No simulation behavior or save schema changed.

The live 400-discovery session 95746 loaded schema 8 before this change. Its observed year-73 interval has six settlements, 11.691 seconds of secondary processing, 1.302 seconds of city trade and 0.023 seconds of primary morphology. That process cannot acquire this finer breakdown retroactively and must not be restarted while still live.

## Interrupted run and consequence snapshot

After the environment interruption, session 95746 returned an unknown-process result, no matching diagnostic Godot process was running, and its temporary log/report were unavailable. The preceding live statements describe earlier observations only. There is no recovered terminal report, verified exit code, or completed 250-year result. No long diagnostic remains running from that session.

On base `472d611`, consequence processing now takes a shallow previous-day metric snapshot. Previous-day formulas and trend subtraction read scalar values; nested food forecasts and mortality breakdowns need no recursive copy. The top-level snapshot still preserves scalar values across intervening metric writes. The same-seed 400-day runs match every recorded gameplay field. All 49 regression cases passed (19 owned civilizations, 12 city resources, 18 demographics), with zero errors/failures/skips/orphans or script errors. This is allocation reduction, **not a measured speedup**: secondary consequences measured 578,416 versus 581,639 microseconds and candidate execution overlapped regression testing. Archive: [consequence-snapshot-comparison.json](pacing/consequence-snapshot-comparison.json). Save fields and gameplay formulas are unchanged.

## Skip unavailable refrigeration in forecasts

Base `acccfc6`: each 90-day food forecast now resolves whether cooling is available once. Without current service (including traveling and secondary-city scope), all future projected days necessarily use the existing no-cooling factor. The calculation mutates projected food only; it cannot commission equipment or replenish actual fuel. When cooling exists, the previous per-offset fuel and perishable-stock calculations remain unchanged.

Sequential same-seed 400-day reports match every recorded gameplay field. Total wall time in this local sample was 4.686 versus 4.526 seconds; secondary consequences were 549,768 versus 502,423 microseconds over 280 calls, and primary consequences 892,080 versus 790,922 microseconds over 400 calls. This is a small early diagnostic, not a mature-city speed guarantee or millennial acceptance. Evidence: [no-cooling-forecast-comparison.json](pacing/no-cooling-forecast-comparison.json).
