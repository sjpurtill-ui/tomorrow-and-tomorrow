# Mature-campaign research cost

Status: READY for sole-integrator review. Worktree `/Users/seanpurtill/Documents/Codex/tt-daily-cost`, branch `codex/daily-cost`, base `61da5e4310c4154fa7d80a915c69c2bf86602b66`. Source hash is supplied in the integration record after committing this task.

## Behavior and cause

When an investigation runs out of eligible questions, its researchers can move only within the society's chosen research domain. The old daily redistribution pass nevertheless ranked candidates in every other domain, then discarded those results. A local set now restricts that ranking to domains with stranded researchers. There is no persistent cache, altered research scoring, random draw, population adjustment, reduced AI frequency or skipped simulation day. All twelve opponents and the human civilization retain the same rules.

Runtime scope is five added lines in `scripts/discovery_system.gd`, a shared integration hotspot. The other owned files are the two-case research regression suite, the headless daily-cost probe/scene and this handoff. Temporary timing instrumentation was isolated in this worktree and removed completely before validation. Other worktrees and their pending changes are untouched.

## Measured evidence

A private copy of the real day-11238 campaign (twelve opponents, player population 571) was replayed for 24 ordinary days using `WorldSimulation.advance_day`, the actual main terrain's discovery context and local construction callback. Every opponent's completed day is asserted on every step. Complete saved outcomes match across all payload fields except the wall-clock save timestamp. This includes the actual world, populations, research, intelligence, stores, military, RNG and owner-specific state; comparison does not filter out gameplay differences.

| Headless daily CPU | Original | Restricted domain search |
| --- | ---: | ---: |
| Mean | 254.625 ms | 207.886 ms |
| Median | 247.698 ms | 200.111 ms |
| 95th percentile | 300.338 ms | 275.786 ms |
| Maximum | 382.355 ms | 284.034 ms |

Mean time fell about 18% in this local sample. Host load varies, so this is not a promised speedup. Temporary profiling had attributed about 31.6 ms per world day to redistribution, mostly candidate ranking. These are headless daily CPU measurements, not rendered frame rates. Synchronous daily stalls, loading cost, broader landscape work and full campaign performance remain unresolved.

All **69 cases pass** across five suites, with zero errors, failures, flaky cases, skips or orphans (56.387 seconds): `test_research_redistribution.gd`, `test_discovery_projects.gd`, `test_simulation_performance.gd`, `test_civilization_owned_simulation.gd` and `test_society_exchange.gd`. New cases cover simultaneous exhausted domains, retained unrelated emphasis, conservation, unchanged RNG, waiting through an evidence drought, and later prerequisite/day gates waking the work. Existing suites include material gates, identical human/AI daily rules, full owner save restoration and RNG continuation.

Evidence in ignored `artifacts/daily-cost/`: `baseline.log`, `optimized.log`, `tests.log`, `profile-detail.log`, `fixture.txt`. Final asset import completed cleanly after an initial private import crashed; adding `.gdignore` to temporary source backups and re-importing succeeded. The clean baseline and optimized processes exited zero. No player/editor was launched or stopped.

## Reproduction and private data

Use a test-only `override.cfg` selecting `config/use_custom_user_dir=true` and `config/custom_user_dir_name="TomorrowDailyCostTests"`. The probe refuses ordinary userdata and any non-headless renderer. This Mac resolves that directory to `/Users/seanpurtill/Library/Application Support/TomorrowDailyCostTests`, directly under Application Support.

Place an explicitly copied campaign at `saves/performance_snapshot.save` in that private directory. The measured fixture SHA-256 is `70b7e3005f27f5d2ee61bc47da9090f9c1de3cf50b6e1d3dd5a3dc49d73ac75e`; its original private CityReportTests snapshot is unchanged. Campaign data and captures are not committed.

Run the probe first against the original code without the optimization, then against the changed code with `-- --compare-baseline`:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-daily-cost res://tests/daily_cost_probe.tscn
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-daily-cost res://tests/daily_cost_probe.tscn -- --compare-baseline
```

These write only `daily_cost_baseline.save` and `daily_cost_optimized.save` in that private test directory. Remove the owned override before packaging. No save schema or migration changes are needed. Existing research allocations and investigations continue normally. Canonical integration, combined checks and the normal build-only package must be verified before marking this READY work INTEGRATED; a running game does not receive these scripts automatically.
