# Invisible spatial hierarchy: measured experiment

**READY as an experiment/report. NOT a production grid migration.**

Worker: `C:/Users/sjpur/tt-spatial-benchmark`, `codex/spatial-benchmark`.
Base: `f985d165a6179c0bcc7b9328a3f177f60295814e`.
No production scripts, autoloads, saves, player campaign, or camera were changed.

## Decision

The idea is promising **as a sparse, local hierarchy**, not as a planet-wide
fine grid. Keep continuous authoritative movement and render shapes. Use a
disposable spatial lookup for nearby candidates, separate visibility/knowledge
filtering, coarse offscreen simulation, and bounded local route planning.

Recommend a follow-up implementation proposal with **25m planning cells in
roughly2km active-front windows**, **10m contact patches around400m across**,
and **100–250m aggregate control neighborhoods**. These are measured starting
points, not universal historical/geometric requirements. Ten metres is the
finest resolution tested; it is practical for bounded local use, not all fronts
replanning synchronously. Finer than10m was not tested.

**Do not merge this prototype into the simulation.** Cross-window portals,
actual city obstacle extraction, dynamic ownership rules, collision clearance,
event scheduling and production save migration need an informed follow-up.
The authorized benchmark is complete without those invasive changes.

## Test plan and comparability

| Concern | Test and coverage | What it does not prove |
|---|---|---|
| Proximity/control | Spatial hash versus exact continuous-distance scan, moving384 aggregates, conserved38,400 represented personnel;120 samples/configuration | Political ownership or combat resolution |
| Fine routing | Godot AStarGrid2D, same family used by current scout routing;1/4/12 local fronts at10/25/50/100/250m;120 requests/front | Current armies already avoid buildings—they do not |
| Worst case | Enclosed unreachable goal;16 repeated all-front batches | Adversarial whole-world route search |
| Geometry |5m subsegment sampling against independent synthetic building test for the first route on each front | Every possible route, clearance, rotated/non-grid real city layouts |
| Memory/save | Engine tracked allocation deltas, compressed route JSON size/time | Full process working set, VRAM or whole-campaign saves |
| Offscreen continuity | Actual23-rival system advanced900days with no rendering/public contacts; constant-rate projection compared with daily stepping | Prototype event queue for wars, border crossings or changed orders |
| Runtime rendering | Actual current local_terrain scene, smooth repeated pan/zoom, sparse lookup and bounded representative MultiMesh markers; both mode orders | Animated soldiers, mature megacity art, or integrated urban combat |
| Naturalness | Captured synthetic street/path comparison with no visible planning-cell lines | Organic political-border rendering or locomotion animation |

Machine: Intel Core i9-14900KF,24cores/32logical processors; RTX4090,
Godot4.7.2, current OpenGL Compatibility renderer. GPU window1280x720,
normal1920x1080 content scale. Tests ran offscreen/hidden with Dummy audio and
master mute. A player game could remain running, so these are same-machine
development measurements, not controlled hardware certification. Percentiles
are empirical:120 path samples for one front, up to1440 for12;16 failed-search
batches mean their p99 is effectively the maximum. GPU360frames/mode after
120warmup frames, mode order repeated in reverse; captures occur after timing.

## Current baseline is not tile movement

`military_campaign.gd::_process_field_army_movement_day` advances continuous
positions between strategic endpoints and computes physical supply/speed.
Its field-army count is bounded to12. Scout routing uses a bounded AStarGrid2D
and compresses results into world waypoints. Regions provide ownership and
objectives, not a universal walkable tile map. This experiment adds obstacle
constraints that current straight-line army movement does not have; it cannot
honestly claim a speedup over equivalent existing obstacle-aware army routing.

The actual current movement method was also timed for120 updates of1/4/12
moving armies, with1,000 personnel each: p99 was0.031/0.083/0.205ms. Positions
actually advanced. This inexpensive baseline performs no building-aware path
search. New local planning should be paid only when routes change, not added
to every ordinary movement update.

## Sparse broad-phase measurements

World workloads:1,000/10,000/100,000 positional aggregate entities spread over
a20,000km square, with384 moving local groups. These are **not citizens** and
are far more entities than the current bounded army system. Empty space has
no allocated cells. Query radius250m, index buckets100/250/1,000m.

Representative100k/250m run: about47ms initial index build,23.1MB tracked
allocation; proximity p99 approximately0.02ms versus2.46ms for a linear scan.
Local384 movement updates were below0.5ms p99; rebuilding their250m control
occupancy was about0.08ms p99. Exact candidate sets matched after movement,
and occupancy summed to the original personnel count. The whole index build
must not happen every frame. Indexes are caches, not another position authority.

## Urban routing: final CPU run

Each active window covers2km by2km with20m streets,80m blocks, a curved avenue
and sparser suburbs. This is synthetic, mostly aligned geometry; real street
widths/rotation can demand finer sampling or a navigation graph.

| Cell size |12 fronts: build | Tracked memory | One route p99 |12 successful replans p99 |12 unreachable replans p99 |
|---|---:|---:|---:|---:|---:|
|10m |152ms |33.2MB |0.90ms |7.64ms |54.63ms |
|25m |28.65ms |5.92MB |0.07ms |0.90ms |5.06ms |
|50m |9.28ms |1.35MB |0.04ms |0.30ms |1.45ms |
|100m |1.22ms |0.47MB |0.01ms |0.10ms |0.65ms |
|250m |0.33ms |0.11MB |0.01ms |0.07ms |0.21ms |

Repeated exploratory runs varied:10m builds152–180ms and failed batches55–68ms;
25m builds29–36ms and failed batches4.4–6ms. Failed-route handling and cold
activation are more important than attractive average successful-search times.

The100m and250m routes crossed unsampled buildings (2,424 and852 sampled
crossing points across12 checked routes). Zero were found in those particular
10/25/50m routes; this is not a proof that50m can resolve arbitrary20m streets.
The route picture shows why coarser navigation is not a free performance win.

An allocation-only hybrid of twelve25m/2km windows plus twelve10m/400m contact
patches used98,904cells and7.27MB, versus484,812cells/33.2MB for full10m windows.
Its cold build was44ms in the final run: still not a single-frame operation.
**Cross-level path stitching was not implemented or benchmarked.**

Compressed first-route payloads across12fronts were about4.2KB at10m and1.7KB
at25m, with JSON serialization below0.2ms. Persist route/control changes and
seed/version references, not the disposable full AStar grid. Rebuild latency
after loading must still be budgeted.

## Rendering versus simulation

Actual map renderer, repeated0.6↔4.0 camera zoom and pan,100k synthetic indexed
world entities,8,192 near candidates. Half are unknown and never drawn. Marker
geometry is a low-poly representative, not a skinned military unit. Physics,
city obstacles and combat are not attached to those markers.

Reverse-order GPU results (ms):

| Mode | Visible max | Frame p50 | p95 | p99 | Cull/upload p99 |
|---|---:|---:|---:|---:|---:|
| Current map baseline |0 |20.58 |29.53 |33.50 |0.01 |
| Mixed index,192 eligible markers |192 |25.36 |38.70 |42.96 |2.32 |
| Mixed index,4,096 markers |4,096 |28.74 |40.82 |43.77 |3.52 |
|192 markers +one25m replan every6frames |192 |23.06 |33.49 |38.29 |2.24 |
| Separate known-only index,192 markers |192 |20.16 |31.11 |34.49 |0.42 |

The first mode order had baseline p99 37.13ms and mixed192-marker p99 37.74ms;
cache state and runtime variation matter. The isolated cull/upload timings are
more stable evidence than attributing every whole-frame difference to indexing.
Drawing4,096 representatives is not a recommended count; it is a stress case.
The existing renderer alone already has substantial frame cost. A fine grid
does not make that cost disappear. Grid cells were never rendered.

A separate known-only rendering lookup avoids scanning thousands of nearby
unknown entities. It must be refreshed from the existing knowledge authority,
not used to hide entities from the simulation or reveal them on proximity alone.

## Offscreen activity and numerical limits

The **actual current**23-rival simulation advanced900days with zero public
contacts while the player aggregate was one billion. Hidden state changed;
monthly advance p50 67ms/p95 86ms/max99ms in the final run. Export was12ms and
294,451bytes. This is existing monthly work, not a new per-frame grid cost, and
rendering culling does not remove it. No extra rival civilizations were invented
for this actual-system test; the100k spatial workload is separate.

A narrowly scoped constant-rate offscreen experiment compared thirty daily
steps with timestamp projection when384 groups enter the active area. For100k
groups, stepping cost roughly245ms total; promotion cost roughly0.02ms. Supplies
agreed and float32 repeated-position drift was0.20m. This shows the opportunity,
**not an implemented interaction scheduler**: arrivals, contact, starvation,
crossing active boundaries and changed orders need scheduled events and rebasing.
You cannot simply stop updating unseen participants in wars.

World-coordinate precision matters: at20,000km, a requested1m Vector2 offset
became1.953125m; near the local origin it remained approximately1m. Tactical
windows need local-origin coordinates plus stable world references. A universal
10m grid does not cure float32 world-position precision.

Mathematical projection, not measured allocation: the game's40,075×20,004km
rectangle would contain about8trillion10m cells. A single4-byte field would
already require roughly32TB. Sparse active allocation is non-negotiable.

## Recommendation and next decision

1. Keep the production movement/world systems for this release. Include this
   report/probes as experimental evidence only.
2. If authorized next, first build a visibility-safe broad-phase cache and a
   bounded asynchronous/sliced local planner with cancellation, request budgets,
   unreachable-path backoff, cached routes and promotion/demotion events.
3. Use25m as the initial local planning experiment and10m only for compact
   contacts requiring it.100–250m is suitable for presence/control aggregation,
   not sufficient building-level navigation.
4. Preserve continuous steering and externally organic boundaries; derive them
   from authoritative occupancy/terrain, not visible square ownership tiles.
   This prototype does not implement that border or steering system.
5. Before production migration, test rotated/irregular cities, actual terrain
   obstacles, twelve simultaneous sieges, dense moving obstacles, save/reload
   during activation, enemy arrival from offscreen, and lower-end hardware.

## Reproduction and delivery

After a headless import, run `tests/spatial_cpu_probe.tscn` with `--headless
--audio-driver Dummy`. Run `tests/spatial_gpu_probe.tscn` hidden with
`--audio-driver Dummy`, then again with `-- --reverse`. Run the separate
`tests/spatial_route_visual_probe.tscn` for the route picture. GPU probes mute
the master bus as a second safeguard and quit; verify their process exits.
All owned GPU processes were checked/closed; player/editor were untouched.
Final GPU shutdown emitted existing ObjectDB/resource diagnostics, not a new
script error. CPU assertions reported no failures.

The direct production-movement baseline is `-s tests/spatial_army_baseline_probe.gd`
with headless/Dummy flags. It uses a disposable in-memory military fixture.

Raw results are in `docs/benchmarks/spatial-*.json`. Visual captures remain in
the worker's `artifacts/` folder. Tests are not connected to project autoloads,
menus or production saves. No migration, relaunch or new gameplay feature is
claimed by this handoff. No shared-file integration conflicts.
