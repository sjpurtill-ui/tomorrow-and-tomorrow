# Year-71 performance audit — September 22, 2026

**Three days/second: NOT achieved. Year-3000 performance: NOT certified.**

This checkpoint diagnoses the supplied campaign, fixes avoidable work, and leaves repeatable probes. It does not replace the simulation scheduler. Base `26bb67e`; worktree `C:/Users/sjpur/tt-overview-history`. The canonical player checkout is `C:/Users/sjpur/TomorrowandTomorrow`.

## Fixed workload and results

The copied quicksave begins at day 25836.015 (year 71), player population 408, five player settlements, twelve opponents, and **68 settlements across the world**. It is 145,467,593 bytes. The original save and running player process were not modified. Eight daily steps were replayed in separate headless processes; all saved simulation state matches exactly, excluding only wall-clock save timestamp.

| Measurement | Before | After | Interpretation |
|---|---:|---:|---|
| Windows process CPU, eight simulation days | 13.984 s | 13.531 s | 3.24% less CPU in this pair |
| Mean elapsed time per day | 1,771 ms | 1,702 ms | 3.87% less wall time in this pair |
| Mean after first cold day | 1,663 ms | 1,603 ms | Still much slower than 333 ms/day |
| Ordinary 90-day food projection, 40 matched cases | 6,896 µs | 4,358 µs | 36.8% less time for this component only |

Earlier diagnostic whole-day runs varied roughly twofold (including an original-code run averaging 877 ms/day). Those runs are not evidence of a reliable large whole-game gain. The final pair also records process CPU independently of elapsed time; hardware frequency/background activity can still affect it. Do not advertise 40% or 2× overall improvement.

Small-town construction remains expensive: individual full fabric builds ranged around 0.35–0.83 seconds across runs. The sample cache reduces redundant queries, but total build timing does not establish a reliable speedup. **The stronger change is avoiding camera-triggered small-town rebuilds entirely.**

The paused map probe invokes the real terrain scene's frame callback for 36 scripted camera changes. Ordinary callbacks took approximately 4–7 ms; periodic snapshot work caused 28–45 ms spikes. It measures CPU callbacks, not rendered FPS, GPU time, input latency, or a long pan across several terrain patches. Main-thread terrain/LOD work totalled 163 ms, periodic marker/network work 191 ms, masks/vegetation 17 ms, HUD work below 1 ms across those frames.

## Where the time goes

Instrumented eight-day diagnostic means below are from an earlier approximately 1.73 s/day run, not the final CPU pair. Nested categories overlap; do not add every row together.

| System | Approximate milliseconds/day | Scope |
|---|---:|---|
| All rival advancement | 1,484 | Includes rival phases, views and projections |
| Rival secondary-settlement phases | ~598 | Most of the 635 ms total secondary work |
| Player daily phases | 145 | Includes its four secondary settlements |
| All primary resource passes | 211 | Thirteen civilizations |
| Military and travel | 118 | Thirteen civilizations |
| World projections, two passes | 116 | Full world summaries rebuilt twice |
| Discovery + progression | 171 | Two distinct phases across civilizations |
| Observer views, two passes | 73 | Each observer gets private foreign views |
| City trade | 79 | Includes local transport work |
| Government | 50 | Includes monthly work in sampled dates |
| Actual morphology simulation | <1 | The renderer's build cost is separate |
| Joint contact + exchange finalization | ~1.3 | Not a priority in this fixture |

A deeper two-day sample found secondary settlement costs in food/consequences, resources and economy; entering/exiting the local-city scope was a small fraction. Do not replace city ownership/scoping on the assumption it dominates.

Food details include harvesting, processing, consumption and a fresh 90-day outlook for each city. Forecasts drive famine warnings and leader decisions, so blindly dropping them or updating them only when a screen opens changes gameplay. The ordinary forecast kernel now does less work with the exact same arithmetic order; specialized cooling/nutrient/botany forecasts remain unchanged.

## Delivered changes

- Small, compact settlements (at most 96 plots and 128 routes, with bounded spatial extent) keep the same full-fabric detail choice across camera distance and panning. Large or dispersed places retain existing culling/detail limits. Growth, damage and appearance changes still invalidate their visuals. This is not yet per-neighborhood rebuilding.
- One fabric build shares exact terrain-height and land tests across reused vertices. Heights use unrounded floating-point keys; the cache dies at the end of the build, so it cannot leak across worlds or terrain changes.
- A resource pass resolves identical access labor/knowledge inputs once for its surveyed deposits. Nothing persists across city scopes or days.
- Public settlement-network snapshots omit the unused duplicate `resource_metrics` report. Detailed city queries and saved local reports remain available.
- The ordinary food forecast uses a fixed numeric kernel rather than repeated dynamic-array writes. Forty varied scenarios match the original exactly, including intermediate forecasts, shortages and ending stocks.
- Optional daily/actor/secondary/resource/food/frame timings and a fixed-fixture replay allow future work to be measured instead of guessed. Detailed tracing is off during normal gameplay.

No simulation cadence, yields, AI rules, scout knowledge, populations, production or save schema is changed. No player launch/restart was performed.

## Remaining work, in priority order

1. **Separate simulation work from input/render time.** `LocalTerrain.advance_world_time` synchronously calls `WorldSimulation.advance_day`, which advances all rivals, every local economy, projections, the player and shared outcomes before returning. The current navigation clock hold only postpones starting a new day; it cannot interrupt an already-running day. A safe next implementation needs bounded phase/settlement jobs with coherent day commits, queued player commands, and a save/load contract for unfinished work. Do not put the current globally scoped Nodes on arbitrary worker threads: `WorldSimulation._active` is shared and explicitly synchronous.
2. **Reduce per-city repetition and projection duplication.** Forecasting and local resource/food processing scale with city count. Projects and observers are rebuilt twice per world day. Use changed-owner/read-model invalidation and phase-local common inputs, preserving inter-civilization ordering and same-day trade/combat behavior. Eight-day equivalence is the initial gate, followed by a targeted month boundary; it is not a guarantee for new systems.
3. **Eliminate remaining map reconstruction spikes.** Scout corridors recreate meshes on each 8% zoom bucket; settlement borders/markers refresh on view buckets and every secondary city's resource revision. Move purely visual scaling to retained materials/transforms and distinguish economic revisions from actual boundary/geometry changes. Town growth/damage still rebuilds a whole batch. Terrain patch commits, fog redraws and water meshes require their own long-route/GPU measurements; the short paused CPU probe does not certify those.
4. **Separate historical records from hot simulation indexes.** Government caps the living roster, while deceased officials remain in `people` and several queries scan it. Preserve biographies but index active people/IDs. At year 71 the largest roster is only 84 including history; this is a future growth risk, not the measured dominant cost. Chart records cap at 1,024 with up to 128 points per trail: bounded does not mean cheap to redraw or copy. Existing spatial/fog caches must keep their revision semantics.
5. **Measure persistence and memory separately.** The fixture is already 145 MB. Large local ledgers plus validation/copying can cause load/save spikes. The headless process briefly reached about 3.4 GB during a diagnostic, including test overhead; that is not a player-runtime memory measurement. Inventory snapshot duplication before altering format or discarding history.
6. **Prove the long game with bounded structural stress cases.** The settlement cap is 256 per civilization: 3,328 cities with the current thirteen civilizations, versus 68 now. The rival cap is 36. Neither bound establishes acceptable cost. Stress city count, completed knowledge, archived officials, exploration, trade routes and battle damage independently before an expensive centuries-long replay.

Proposed acceptance budgets: ordinary map CPU under 8 ms, no recurring callback over 16 ms; scheduled simulation chunks around 4 ms; total daily work comfortably below 333 ms (preferably 200 ms to leave rendering headroom). These are targets, not achieved results.

## Validation and reproduction

14 distinct focused tests passed (report 198); the forecast equivalence case was expanded from 20 to 40 scenarios and passed again (report 199). Exact-sample reuse, small-versus-dispersed town bounds, existing surface search and observer summary behavior, terrain patch reuse, plus full saved-state equivalence on the eight-day fixture were checked.

Copy an explicitly chosen save to ignored `artifacts/year71_fixture.save`. Run `res://tests/year71_performance_probe.tscn` headless with `--year71-profile`; `--after` compares the complete saved outcome with the baseline. `--detail` runs only two days with deeper counters. `--map-profile` runs a paused headless frame-callback probe. Ordinary player save slots are never written. Windows process CPU comes from two hidden, noninteractive process-time reads around simulation; other platforms do not supply that measurement.

The before/after reports are ignored local artifacts; compact timing data and inventory are in `YEAR71_AUDIT.json`. No private saves, images or generated import files belong in the commit. Graphical follow-up probes must use the private-desktop launcher, never the user's live game.
