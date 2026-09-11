# Optional pacing stage measurements

The pacing harness accepts `--profile` and writes schema 6 reports with `profiling_enabled` and a `timings` dictionary. The ordinary simulation takes the same steps in the same order. A new optional final dictionary argument on `CivilizationDay.advance` collects timings only when nonempty; existing callers continue using an empty default, with no clock reads or saved state.

Example, from the implementation worktree:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-technology-implementation -s res://tools/audit_history_pacing.gd -- --days=365 --wall-seconds=60 --profile --out=/tmp/tt-profile-year.json
```

Each timed group reports calls and accumulated microseconds. Groups are controller, context, operations, discovery, resources, consequences, civics, economy, government, construction, settlements, progression, military-and-travel, and convoy. They include intervening bookkeeping and local-population wrappers. Operations includes initial allocation synchronization; consequences includes the second synchronization. Settlements combines secondary-city resource processing, trade and monthly morphology. These are daily execution intervals, not isolated benchmarks of the named functions. The home-unavailable early return is not covered.

## Initial controlled comparison

Both runs completed 365 days from the same seed against the 377-discovery catalog. Initial/final snapshots, annual snapshots, discovery events and final bottleneck dictionaries are exactly equal with profiling on and off. All fourteen groups have 365 nonnegative samples. The unprofiled report has an empty timings dictionary. Evidence is archived in [one-year-stage-timing.json](pacing/one-year-stage-timing.json).

In this sample, settlements consumed 24.2% of measured stage time, consequences 18.7%, discovery 18.0%, and resource processing 9.6%. These measurements are affected by the concurrently running long diagnostic and local scheduling. The first year has only 121 people at its endpoint and no discoveries completed, so it cannot establish late-game scaling. No performance improvement is claimed.

Next use: profile longer runs once the existing 250-year-target process terminates, compare stage shares at larger populations and knowledge catalogs, and optimize only measured costs while retaining deterministic behavior. The active process loaded older scripts and is not instrumented by this change. Neither this first-year comparison nor partial output from that process verifies the required 2,500–3,000-year progression.

No save format or player UI change. Integration conflicts: `scripts/civilization_day.gd` and `tools/audit_history_pacing.gd`. Changes remain isolated pending the designated integrator.
