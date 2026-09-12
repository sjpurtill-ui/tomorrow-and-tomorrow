# Reuse fixed survey inputs within each city-day

From base `d34336c`, the resource pass now calculates effective survey workers, the survey policy factor, ecology/production research focus and the survey-speed knowledge effect once when it first encounters eligible recognition or surveying work. Previously it repeated workforce/modifier evaluation for every such deposit and repeated survey-speed lookup for every recognized occurrence.

The cached dictionary exists only inside one `_process_local_day` call. The next city or day recalculates it from the current local population, allocations, policy and knowledge. If no occurrence needs recognition or surveying, the values are never calculated. Family literacy remains evaluated per occurrence because gaining practice from one deposit can affect a later deposit in the same pass. Resource-specific geoscience factors, recognition gates, iteration order, random draws, transitions and extraction behavior remain unchanged.

This removes repeated invariant evaluation in primary and secondary resource processing. It does not remove the secondary city's independent demographic/economic/resource day. The earlier attribution identified that full secondary-city day as the largest settlement interval, not primary morphology.

## Evidence and limits

The candidate completed the same 400-day scenario as the committed pre-change report. Initial/final/annual snapshots, discoveries and final bottleneck dictionaries are exactly equal, including both settlements' recorded populations, plot counts and resource-processing dates. Archive: [survey-pass-comparison.json](pacing/survey-pass-comparison.json), referencing the earlier [baseline](pacing/secondary-settlement-stage-timing.json).

The code reduces survey workforce/modifier evaluations from one per eligible occurrence to at most one per local pass. Overall wall-time improvement is not established: the sample is short and runs alongside other work. This is not full-state equivalence across every scenario, large-world performance acceptance or 2,500–3,000-year viability.

All 52 relevant cases pass: 9 resource recognition, 12 geoscience, 12 city resources and 19 owned simulation, with zero errors, failures, skips or orphans.

No save schema, stored resources, gameplay coefficients or player interface changed. Integration conflict: `scripts/resource_system.gd`. The active long diagnostic loaded older code and cannot validate this optimization. Canonical integration remains pending.
