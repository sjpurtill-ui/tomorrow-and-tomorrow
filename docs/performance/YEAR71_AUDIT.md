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

## Follow-up: scheduled world days (codex/day-jobs)

Remaining-work item 1 is partly addressed. A world day is now an ordered queue of
steps (`scripts/day_job.gd`): rival views, each rival's 15 phases plus one step per
secondary town, the human owner's phases, then per-civilization projections,
per-observer views, contact and exchange. The terrain frame loop runs 8 ms of steps per
frame (14 ms at 1+ day/s, 4 ms while the camera moves). Calendar time accrues up to the next
boundary while a day computes. The day's HUD/advisor/history commit runs once when the last
step finishes. `WorldSimulation.advance_day` runs the same steps synchronously.
Saves and loads call `flush_day()` first, so no partial day is ever saved and the
save format is unchanged. Validating another save preserves the day in progress.

Year-71 fixture, eight days, one step per call: saved state identical to the
synchronous baseline. 2,776 steps: median 2.0 ms, p95 11.3 ms, p99 21.2 ms, max
162 ms (a one-off rival `resources` step). 57 steps exceed 16 ms, 10 exceed 33 ms.

Real terrain frames at speed 5, four days: synchronous 24 frames in 5.2 s with
day frames of 1.1–1.6 s; scheduled 295 frames in 6.2 s, median 18.9 ms, p95 31 ms, max
130 ms, maximum while panning 39 ms. Throughput fell from about 0.77 to 0.65 days/s
because simulation now shares frames with rendering; total daily CPU is unchanged.

Limits: steps are atomic, so the slowest phases (rival `resources`, `controller`,
`world`, `progression`, `military_and_travel`) still reach 25–160 ms. Player commands
issued between steps take effect from the next phase rather than being queued to a
day boundary. Rival projections refresh civilization by civilization over a few
frames. `scheduled_world_days_enabled=false` on the terrain restores the old
whole-day frame. Probe: `--year71-profile --stepped` and `--frame-profile [--synchronous]`.

### Follow-up checkpoints on codex/day-jobs

Each keeps the eight-day year-71 saved state identical to the baseline (stepped and synchronous).
"Warm" means after the first, cold day after load. Timings vary with other load on this
machine; another headless worker ran throughout.

| Commit | Change | Measured effect |
|---|---|---|
| 8dc4f9d | AI order selection, each civilian investment planner and each expansion site are separate steps | slowest warm step 136 → 52 ms; p99 13.9 → 10.6 ms |
| 08012d8 | Owned-world civilization work and weekly scout route quotes split; review/civilian/expansion/scouting follow-up steps queued only when due | warm steps per 7 days 10,332 → 4,293; slowest warm step ~40 ms |
| 74ad73f | Charted area cached by fog revision; nation-wide territory inputs computed once per network snapshot | projection steps 806 → 301 ms per 8 days; no warm step > 33 ms |
| e4b3504 | Exact shared terrain samples for territory fills, borders and scout corridors | paused map snapshot work 148 → 123 ms per 36 frames |
| 2fdc67d | Settlement network refresh runs half a period after marker refreshes (both still 10 Hz) | refresh-frame peaks 26–30 → 15–19 ms |

Checked and not changed: observer views (~31 ms/day; exact reuse is complicated by
per-observer controller localization), material flow (per-deposit work, no repeated
nation-wide inputs), progression's domain limits (cold-cache cost on the first day
after load only). Two-day `--detail` runs include that cold day; use eight-day `--stepped`
runs for steady-state conclusions.

Still open: total daily CPU is about 1.0–1.4 s. Roughly 450–500 ms of it is secondary
settlements (consequences/food ~190, resources ~115, economy ~70 ms), spread across many
small subsystems per city. Pan/zoom still rebuilds border and corridor meshes by view
bucket. Width is baked into geometry, so retained geometry needs a shader or transform
change with graphical verification.

## Multi-day steps for calm rivals (day_span.gd)

Exact optimizations stopped paying off at about 0.6 s of simulation per warm year-71 day (about 1.2 days/s at top speed). Most of that time goes to rivals: roughly 85%.

Rivals that are **calm** now advance their whole calendar every third day and cover the elapsed interval in one step. Calm means:

- at peace, with no active engagement;
- stationary field armies;
- not traveling, with no settlement convoy;
- at least 30 days of food in the capital and in every town;
- drinking-water intake of at least 98%.

Each calm rival runs on its own phase day, so the load stays even. Monthly strategy reviews keep their exact day. The human civilization, and any rival that is not calm, still runs daily.

How the daily systems handle a K-day step:

- **Scaled flows:** labor and need scale by K, including extraction, hauling, survey clues, construction, carrying capacity, discovery progress and clerical work.
- **Converted rates:** per-day smoothing and per-day chances use `1-(1-r)^K`.
- **Food:** one pass with K days of labor and need. Stored food spoils for K days; each arriving harvest spoils for one.
- **Kept daily inside the span:**
  - reproduction;
  - undertaking upkeep;
  - the economy;
  - military days, which are nonlinear.
- **Unchanged:** systems already driven by elapsed dates, such as operations, craft decay, government months, civic due dates and trade arrivals.

`WorldSimulation.span_limit = 1` restores strictly daily rivals. The year-71 probe uses 1 by default, and `--span=3` opts in.

Validation:
- At span 1 the saved state is identical to the pre-change baseline, and the gdUnit day-job and map suites pass.
- Interleaved `artifacts/span_ab.ps1` runs of span 1 against span 3 used the same code, with 150 days on the year-71 fixture.
- **CPU:** 140 s at span 1 against 76–92 s at span 3, a 35–45% reduction.
- **Rival outcomes after 150 days (span 3 against span 1):**
  - population, knowledge, discoveries, health and cities within 0.1%;
  - food stores within 0.3%, except civ_08 at −2.3% (a single-city rival);
  - one rival has 5% fewer home troops.

Remaining work toward 3 days/s: the economy and military still run K times per step, and the rival views and projections still run daily.
