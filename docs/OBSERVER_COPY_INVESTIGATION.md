# Observer-copy investigation

Status: HELD — no runtime candidate proposed for integration. The bounded measurement is complete; the existing implementation is retained. Canonical main remains `2f695346b9c525a2c3b5bba1cbc9ad97fb24a210`, release 2026.09.11.1.

Worktree: `/Users/seanpurtill/Documents/Codex/tt-observer-copy`; branch `codex/observer-copy`; base `2f695346b9c525a2c3b5bba1cbc9ad97fb24a210`. Owned scope was observer-view copying in `scripts/world_simulation.gd` and its private measurement harness. No runtime file was edited. This documentation-only branch is not a new player build.

## Result

The actual day-11238 campaign supplies 144 observer/source pairs across all twelve opponents, including their views of the human civilization. Ten refresh-equivalent passes compare four copying approaches. Each result is compared with the current helper on those actual inputs; all comparison results match. These are headless copy timings, excluding relation normalization, troop views and the rest of the daily simulation.

| Approach | Mean milliseconds per 144 views |
| --- | ---: |
| Existing per-field reuse of equal private values | 7.2273 |
| Native deep duplicate followed by removal of the observer relation | 18.7976 |
| Native shallow duplicate, then existing nested-value logic | 7.1546 |
| Shallow duplicate with mutable field names prepared in advance | 6.4197 |

Replacing the helper with a native deep duplicate would substantially increase copying cost. The shallow variant offers no meaningful measured gain. Preparing mutable field names outside the timed loop saves approximately 0.81 ms per refresh before preparation cost, or at most about 1.6 ms across two daily refreshes. This does not justify additional transient-cache plumbing at this point. No implementation was committed or integrated, and no performance improvement is claimed.

A separate unchanged-code replay completes the same 24 daily steps for all twelve opponents, averaging 230.537 ms per day. Host load differs from the prior release's 213.524 ms sample; these runs do not establish a regression. Save state, population rules, research gates, private intelligence and all opponent turns are unchanged. There is no new rendered FPS measurement.

## Evidence and isolation

Ignored `artifacts/observer-copy/` contains the self-contained `probe.gd`/`probe.tscn`, `baseline.log`, `copy-options.log` and clean `import.log`. The probe is adapted from the integrated `daily_cost_probe.gd`, with a strict private `TomorrowObserverCopyTests` userdata guard. `-- --copy-only` performs only the measured copying and equality checks, then exits. The baseline invocation additionally advances and saves the ordinary 24-day replay.

Exact worktree command:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-observer-copy res://artifacts/observer-copy/probe.tscn -- --copy-only
```

The explicitly copied fixture is `/Users/seanpurtill/Library/Application Support/TomorrowObserverCopyTests/saves/performance_snapshot.save`, copied from the earlier private DailyCostTests fixture. No player userdata is read or modified. Both probe runs exit zero, and the owned override is removed after use. No player/editor was opened, stopped or restarted. Other worktrees are untouched; no merge or package is needed for this documentation-only investigation.

Future performance work should measure another material contributor or a complete rendered frame. Do not repeat the native deep-copy experiment or introduce shared mutable observer data. Keep complete-state comparison, all twelve opponents and the existing private-copy ownership semantics when testing a new candidate.
