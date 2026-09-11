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
