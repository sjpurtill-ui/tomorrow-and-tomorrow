# Terrain and procedural-world cost profile

September 23, 2026. Worktree `C:/Users/sjpur/tt-terrain-profile`, branch `codex/terrain-cost-profile`, base `d55b339ad1023d6ef290cf5a2929f3e5579af664`. Measurement only: no gameplay, save or rendering behavior was changed.

**Question.** How much CPU goes to procedural terrain (noise height, climate, biome, geology, rivers)? Would a fixed, pre-baked world be meaningfully cheaper? A pre-baked world could use real Earth elevation stored as raster tiles.

**Short answer.**

- **Frame rate: no.** The noise-based terrain costs little per frame. Patch sampling runs under a fixed per-frame budget of 1.4 ms while the camera moves and 3 ms when it is still. A raster would not lower the frame-time cap.
- **Simulation speed: no.** Terrain queries are 3–5% of a simulated day.
- **Terrain detail latency: yes.** This is the time until full-detail ground appears after a zoom or pan. Pre-baking would make it about 4–10× shorter.
- **Load and new-world time: yes, partly.** Pre-baking would remove about 2–3 s from a 7–9 s new-world load.

Most of the cost is GDScript interpretation around the noise calls, not FastNoiseLite itself. Threading the sampler, baking a raster for the current seed, or moving the code to native code would get most of the same gain without a fixed Earth. Separately, there are several cheap hot spots that are not noise. Fixing them first would help.

## Method

- **Harness:** `tests/terrain_cost_profile.gd` and `.tscn`, with modes `micro`, `patch`, `pan`, `newworld`, `day`, `dayfresh` and `render`.
  - It refuses to run unless user data is the private `TomorrowTerrainCostTests` directory, set by an ignored `override.cfg`.
  - Every mode except `render` must run headless.
  - `patch` reuses the cold-build pattern from `tests/terrain_build_benchmark.gd`.
  - `pan` and `render` reuse the full-scene pattern from `tests/mac_performance_probe.gd`.
  - `day` uses the replay pattern from `tests/daily_cost_probe.gd`.
- **Instrumentation.** This is temporary and exists only on this branch.
  - `scripts/terrain_cost_counters.gd` holds counters, disabled by default.
  - Thin wrappers were added:
    - `PlanetEnvironment`: `world_height_at`, `profile_at`, `surface_geology_at`, `seasonality_at` and `nearest_viable_land`.
    - `local_terrain.gd`: `_height_at`, `_close_surface_height_at`, `_climate_at`, `_biome_at`, `_terrain_color_at`, `_terrain_surface_fields_at`, `_land_moisture_at`, `_river_distance_at` and `_nearest_tributary_distance_at`. Composite queries were also wrapped: `_surface_water_sources`, `_water_conveyance_sources`, `_survey_ground_at`, `_surface_material_catchments`, `_sample_civilization_geography` and `_analyze_convoy_route`.
  - The original bodies are renamed `*_impl` / `*_tcimpl`.
  - `_trace_load` now prints a millisecond timestamp.
  - Nested calls are not double counted. "Noise primitive ms" counts only outermost primitive calls. "Terrain-query union ms" is outermost across primitives and composite river/geography queries.
  - **Overhead:** a disabled wrapper adds about 0.6 µs per call (`PE.world_height_at` 2.7–2.9 µs direct vs 3.4–3.9 µs through the wrapper). Enabled counters inflate a patch build by about 30–40%. Every per-call cost and build time quoted as "uninstrumented" calls the `*_impl` bodies directly. Instrumented figures are used for **call counts and shares**.
- **Microbenchmarks.** 20,000 land points in a 600 km box around the cradle, or a planet-wide mix that is 70% ocean. Seed 873421. Each figure is ns per call, two runs.
- **Pre-baked alternatives:**
  - a 512² `PackedFloat32Array` height raster of the same box, read with GDScript bilinear and nearest lookups;
  - `Image.get_pixel` ×4;
  - a native bulk `Image.get_region` + `resize` bilinear resample;
  - a read-only dictionary of pre-derived profiles.
  - For patch builds, the "baked" sampler uses rasters holding exactly what the real sampler produced, read through GDScript bilinear callables. This is a like-for-like replacement of the four sampling callables.
- **Real play.**
  - `pan`: fresh world (seed 184271) and the real `local_terrain.tscn` `_process`. For each camera preset (Continent, Region, 50,000 ft, 10,000 ft): zoom, settle until the final-resolution patch is installed, pan for 180 frames (1/150 view width per frame), then settle again.
  - `render`: the same scenario with the real frame loop in a window, run only through `tools/run_isolated_gpu_probe.ps1` on a private desktop, 1600×900, VSync off. The runner reported `exit=0`, and no process with that PID remained afterwards.
  - `day`: a **private copy** of the current quicksave, placed in the private user-data directory as `saves/performance_snapshot.save`. The original is unmodified: the SHA-256 matched before the copy. Day 1561, 12 opponents, settled. 20 consecutive `WorldSimulation.advance_day` calls.
  - `dayfresh`: a new world (seed 184271), days 1–20, convoy not yet settled, 12 opponents.
  - `newworld`: `GameState.reset_for_new_world`, instantiating `local_terrain.tscn` (its `_ready`), and frames until the first streamed patch completes.
- **Machine:**
  - Intel i9-14900KF, 64 GB, RTX 4090 (OpenGL 3.3 Compatibility renderer, driver 610.60), Windows 11, Godot 4.7 stable mono.
  - The host was **shared**: two to four other workers' headless Godot probes ran throughout, at about 38% total CPU load.
  - Repeat runs differ by about 10–35%, so both runs are shown where they were repeated.
  - Results are single-thread GDScript timings. A Mac or a slower CPU will scale roughly proportionally.
- **Raw data:** `docs/performance/terrain-cost-profile-2026-09-23.json`, which bundles all runs. Per-run JSON is in the ignored `artifacts/terrain-cost/`.

## 1. Per-call cost (ns per call, uninstrumented, run 1 / run 2)

| Query | ns/call | Notes |
|---|---:|---|
| `FastNoiseLite.get_noise_2d`, 5 octaves (reference) | 165 / 150 | The noise itself is cheap |
| Trivial `Callable.call` (reference) | 158 / 178 | Paid by every patch-builder sample, 4× per vertex |
| `PE.world_height_at`, land | 2,721 / 2,925 | About 10 noise calls (≈1.6 µs) plus GDScript math |
| `PE.world_height_at`, planet-wide mix (70% ocean) | 1,819 / 2,092 | Ocean exits early |
| `PE.is_land` | 3,583 / 3,809 | Full height evaluation |
| `PE.surface_geology_at` | 2,069 / 2,791 | 3 noise calls plus dictionary build |
| `PE.seasonality_at` | 996 / 972 | 1 noise call |
| `PE.profile_at`, cold (cache miss) | **121,447 / 138,325** | About 82 µs is `_coastal_at` (up to 24 height probes) |
| `PE.profile_at` with observed ground supplied | **123,032 / 122,810** | Not cheaper. GDScript evaluates the default argument of `observed.get("coastal", _coastal_at(...))` eagerly, so the coast probe runs even when the caller supplied `coastal`. `_survey_ground_at` does supply it. |
| `PE.profile_at`, cached hit | 13,141 / 13,950 | 9.0–10.6 µs of this is `duplicate(true)` on return |
| `LT._height_at` (authoritative local height), land | 6,498 / 5,810 | About 12 noise calls plus river, swale and cradle-range math |
| `LT._height_at`, planet-wide mix | 2,666 / 2,875 | |
| `LT._close_surface_height_at` | 6,909 / 7,070 | |
| `LT._climate_at` | 1,940 / 2,186 | |
| `LT._terrain_color_at` (climate, biome, colour) | 7,126 / 7,379 | |
| `LT` colour + surface fields (shared climate; what a patch vertex pays) | 11,439 / 12,216 | |
| `LT._biome_at` (height included) | 12,991 / 14,097 | |
| `LT._local_drainage_distance_at` | 796 / 1,086 | No noise |
| `LT._nearest_tributary_distance_at` (chunk index) | 29,776 / 34,618 | Procedural river geometry, not noise |
| `LT._surface_water_sources` | **143,396 / 155,033** | Scans **every** tributary segment with `Geometry2D`. It does not use the existing chunk index. |
| `LT._river_distance_at` | **151,074 / 162,752** | Wraps `_surface_water_sources` |
| `LT._survey_ground_at` | 245,210 / 268,305 | Composite |
| `LT._sample_civilization_geography` (cache miss) | 1,817,725 / 1,861,600 | Composite: water conveyance routes, catchments, profile |
| **Baked:** height, nearest, `PackedFloat32Array` (GDScript) | 99 / 137 | |
| **Baked:** height, bilinear, `PackedFloat32Array` (GDScript) | 345 / 548 | **12–19× cheaper** than `LT._height_at` |
| **Baked:** height, bilinear, `Image.get_pixel` ×4 | 649 / 755 | |
| **Baked:** native `get_region` + `resize`, 385² grid | **5.1 / 5.7 per sample** | About 1,200× cheaper per sample |
| **Baked:** read-only profile dictionary lookup | 462 / 599 | Compared with 13–14 µs for a cached `profile_at` and 121–138 µs cold |
| Baking a 512² height raster with the real sampler | 1.65 s / 1.53 s | About 6 µs per cell. This is a one-time per-seed cost. |

## 2. Call volume in real play

**Per terrain patch build.** Cold, no reused samples. The call mix per vertex is fixed: 1 `_height_at`, 1 `_terrain_color_at` (which calls 1 `_climate_at`), 1 `_terrain_surface_fields_at` (reuses that climate), 1 `surface_geology_at` and 1 `seasonality_at`. Ocean vertices add `_biome_at`.

| Build | Vertices | Noise-backed calls | Real build ms (run1 / run2) |
|---|---:|---:|---:|
| Preview, any preset (129²) | 16,641 | about 100k | 281–458 / 305–402 |
| 10,000 ft final (385², 5.06 km) | 148,225 | about 890k | 4,078 / 3,559 |
| 50,000 ft final (257², 25.6 km) | 66,049 | about 396k | 2,000 / 1,590 |
| Region final (385², 292 km) | 148,225 | about 890k | 3,263 / 3,782 |
| Continent final (385², 4,988 km) | 148,225 | about 940k (+50k `_biome_at`) | 2,925 / 1,937 |
| Close detail job (112², 0.42 km; 5 heights plus colour per vertex) | 12,544 | about 100k | 571 / 401 |
| Global planet mesh at load (481×241) | 115,921 | about 790k (+95k `_biome_at`) | 2,934 / 2,128 (instrumented) |

**Per frame, during pan and zoom.** Fresh world, headless `_process`, instrumented. "Frames to final" counts zoom plus settle frames at the 3 ms idle budget; the instrumentation inflates it by roughly 1.4×.

| Preset | Frames to final detail | Height calls per refining frame | Height calls per pan frame | Refining frame: script ms (p95) | Noise ms per refining frame (share) |
|---|---:|---:|---:|---:|---:|
| Continent | 1,180 | 169 | 6 | 3.30 (3.77) | 2.13 (65%) |
| Region | 930 | 161 | 41 | 3.28 (3.62) | 2.29 (70%) |
| 50,000 ft | 2,585 | 102 | 4 | 3.40 (3.94) | 2.29 (68%) |
| 10,000 ft | 1,465 | 102 | 4 | 3.40 (3.94) | 2.29 (67%) |

While panning inside an already-installed patch, noise is 0.05–0.55 ms per frame. The new patch then refines over another 586–2,444 frames. Idle frames spend 0–0.01 ms on noise.

**Per simulated day.** 20 days each. The union covers noise primitives plus river/geography composites.

| Scenario | Mean ms/day (uninstrumented) | Terrain-query union ms/day | Share | Main callers (calls/day) |
|---|---:|---:|---:|---|
| Mature save, day 1561, 12 opponents | 62.0 (median 53.2) | 2.82 (day 1: 4.4) | **4.6%** | `_height_at` 449, `profile_at` 20 (94% cache hits), `_surface_water_sources` 12, `_river_distance_at` 5, `_sample_civilization_geography` 1 |
| Fresh world, days 1–20 | 79.8 (median 32.2) | 10.4 mean; **185.6 on day 1**, then 1.19 | 12% overall; **3.2% after day 1** | Day 1 is cold geography for 12 rivals: `_sample_civilization_geography` 124 calls, about 138 ms. Later days: `_height_at` about 1,460 |

Opponent AI, scouting and artifact sampling reach the terrain only through these cached geography, profile and height calls. Everything else in a day is simulation logic: about 95–97% of day time.

**New world and load.** Timestamped `_ready` stages. Two runs on a busy host: uninstrumented, then instrumented.

| Stage | ms | Terrain part |
|---|---:|---|
| World configuration (discovery init, rival starts, `start_world`) | 4,668 / 6,149 | About 0.7 s of profile, survey and river queries (instrumented) |
| Global planet mesh `_build_terrain` | 2,408 / 2,006 | About 65–75% sampling |
| Water and rivers (river network draped on heights) | 1,205 / 802 | Partly height sampling |
| Vegetation and resources | 186 / 135 | |
| Settlement and interface | 102 / 66 | |
| **Total `_ready`** | 6,924–8,571 uninstrumented | **Noise primitives 2.61 s; terrain-query union 2.70 s** (instrumented, of 7.18 s) |
| First streamed patch (129² preview) | 242 ms over 74 frames | 213 ms of that is noise (instrumented) |

## 3. Share of frame time (windowed, RTX 4090, 1600×900, VSync off, fresh world)

These are median values per frame. Noise figures are instrumented.

| Preset | Phase | Frame interval | Noise ms | Render CPU ms | Render GPU ms |
|---|---|---:|---:|---:|---:|
| Continent | refining (1,647 frames) | 4.06 | 1.20–2.31 (p50–p95) | 0.85 | 0.74 |
| Region | refining (1,694 frames) | 4.28 | 2.33 | 0.79 | 0.54 |
| 50,000 ft | refining (867 frames) | 4.13 | 2.20 | 0.83 | 0.46 |
| 10,000 ft | refining (1,288 frames) | 4.10 | 2.34 | 0.64 | 0.39 |
| Any preset | static, detail installed | 0.68–1.47 | 0.00 | 0.41–0.66 | 0.48–1.28 |
| Any preset | pan | 2.60–3.21 | 0.98–1.08 | 0.52–0.78 | 0.40–0.63 |

- Draw calls: about 125–135 per frame. Primitives: 0.50–0.78 million.
- The largest spike was one 186 ms frame on the continent zoom, with 184 ms in render CPU. This is a mesh upload or pipeline compile, not sampling.
- In a fresh world, refinement frames therefore split roughly as: **terrain sampling about 3 ms (about 70%; noise about 55% of the whole frame), render CPU plus GPU about 1.3 ms, everything else under 0.5 ms**.
- In a mature campaign the terrain share is smaller. The year-71 audit measured 4–7 ms ordinary callbacks and 28–45 ms map-snapshot spikes. Day-step slices add 4–14 ms of budgeted simulation per frame while time runs.

## Top five hot spots (measured)

1. **Streamed regional patch sampling.**
   - 20–27 µs per vertex, of which sampling is 88–92% of the builder (`sampling_share_real`).
   - A 385² final patch costs 1.9–4.1 s of CPU. At the 3 ms idle budget that is about 650–1,360 frames, or about 11–23 s at 60 Hz.
   - During refinement it takes about 3 ms of every frame, about 2.2 ms of it noise.
2. **New-world load.**
   - About 7–9 s of `_ready`. About 2.6–2.7 s of that is terrain queries: the 481×241 global mesh (2.0–2.9 s build, mostly sampling) and river draping.
   - About 4.7 s is world configuration, mostly not terrain.
3. **Daily simulation (not terrain).**
   - 53–62 ms per day in the mature save; terrain is only 2.8 ms of it.
   - The first day of a new world is 900–980 ms, including 186 ms of cold rival geography.
4. **River and water-source queries.**
   - `_surface_water_sources` and `_river_distance_at` take 143–163 µs per call. They linearly scan every tributary segment.
   - `_sample_civilization_geography` takes 1.8 ms per cache miss.
   - This is procedural geometry, not noise, and the fix is cheap: use the existing tributary chunk index (30 µs) or a baked distance field (under 0.5 µs).
5. **`PlanetEnvironment.profile_at`.**
   - 121–138 µs cold. Two thirds of that is `_coastal_at`, which is evaluated even when the observed ground already states `coastal`.
   - Cached hits still cost 13–14 µs because of `duplicate(true)`.
   - Low volume per day (20–48 calls), but this is the entire startup rival/geography cost.

The close detail job (0.4–0.57 s per 112² patch, 5 height evaluations per vertex) and patch commits (9–11 ms for 385², excluding GPU upload) are secondary.

## 4. Estimated savings from pre-baking

Estimates use measured per-call or per-build costs multiplied by measured call volumes.

| Area | Today (measured) | With a baked macro raster, GDScript sampling | With native bulk resample from the raster | Saved |
|---|---|---|---|---|
| 385² final patch CPU | 1.9–4.1 s | 0.51–0.99 s | about 0.21–0.41 s (the meshing floor) | 75–90% |
| Frames to full detail at the 3 ms budget | 650–1,360 | 170–330 | 70–140 | **4–10× lower refinement latency** |
| Per-frame CPU while refining | about 3 ms (fixed budget) | about 3 ms (same cap, finishes sooner) | same | **None**, unless the budget is lowered to trade latency for smoother frames |
| Per-frame CPU while static or panning | 0.0–1.1 ms noise | about 0 | about 0 | ≤1 ms per frame |
| Mature simulated day | 2.8 of 62 ms | about 0.3 ms | about 0.3 ms | **≈2.5 ms per day (about 4%)** |
| Fresh world, day 1 | 186 of 983 ms | about 20–60 ms (conveyance route surveys remain) | same | ≈125–165 ms, once |
| New world or load | about 2.7 s of 7–9 s | about 0.3 s | under 0.1 s | **≈2.4–2.7 s** |

**What does not get cheaper:**

- the GDScript normal and index loop, 2.3–2.8 µs per vertex (0.2–0.4 s per 385² patch; the "constant sampler" column);
- mesh commit (about 10 ms) and GPU upload spikes (up to 184 ms observed);
- rendering: 0.4–1.3 ms render CPU plus GPU per frame at 125–135 draw calls;
- LOD bucketing, cancellation, seam and coverage logic;
- the cached patch set (four entries, up to 600k vertices);
- more than 95% of daily simulation;
- map-snapshot and marker spikes;
- about 4.7 s of non-terrain world configuration at load.

**Data size limits what a fixed world can replace.**

- A 10,000 ft patch has about 13 m vertex spacing, and the close job about 4 m.
- One f16 channel for the whole 40,075 × 20,004 km planet would need about 1.6 GB at 1 km spacing, or about 64 MB at 5 km.
- Macro rasters can therefore replace continental and regional sampling, but close views still need procedural detail, or a streamed tile pyramid with its own I/O and decode cost.

## Recommendation

A fixed, pre-baked world, real Earth included, would **not materially improve frame rate or simulation throughput**:

- terrain is about 4% of a mature day;
- per-frame terrain work is already capped at 1.4–3 ms;
- rendering and the other simulation work remain.

It **would** materially improve two things:

- **terrain refinement latency**: about 4–10× faster full-detail ground after zoom or pan;
- **startup**: about 2.5 s saved.

The same two gains do not require giving up procedural worlds. Most of the cost is GDScript overhead around cheap noise: 165 ns per 5-octave noise call, against 6.5 µs per `_height_at`.

Suggested order:

1. **Cheap, non-noise fixes:**
   - route `_surface_water_sources` and `_river_distance_at` through the tributary chunk index;
   - avoid the eager `_coastal_at` default in `profile_at`;
   - return cached profiles without `duplicate(true)` where callers do not mutate them.
2. **Bake macro rasters per seed** (height, climate UV, geology UV, seasonality, colour) at world creation or on first load, and save them in a cache. Sample patches from these rasters and keep procedural noise for close detail. At about 6 µs per cell, a 2048² regional bake costs about 25 s on one thread, so bake it incrementally or on a worker thread.
3. **Move sampling off the main thread** (WorkerThreadPool) or into native code or the vertex shader. This keeps the procedural world and removes the per-frame budget trade-off.

Real Earth elevation adds a data pipeline and multi-GB close-scale data. It brings no CPU advantage over baking the procedural world.

## Reproduce

```sh
# ignored override.cfg in the worktree:
# [application]
# config/use_custom_user_dir=true
# config/custom_user_dir_name="TomorrowTerrainCostTests"
G=".../Godot_v4.7-stable_mono_win64_console.exe"
"$G" --headless --path C:/Users/sjpur/tt-terrain-profile res://tests/terrain_cost_profile.tscn -- --mode=micro   # or patch|pan|newworld|dayfresh
# day: copy a save to %APPDATA%/TomorrowTerrainCostTests/saves/performance_snapshot.save first
TT_COST_NOCOUNT=1 "$G" --headless ... -- --mode=day        # uninstrumented timing
"$G" --headless ... -- --mode=newworld --trace-load         # timestamped load stages
powershell -File tools/run_isolated_gpu_probe.ps1 -Godot <Godot.exe> -Project C:\Users\sjpur\tt-terrain-profile -Scene res://tests/terrain_cost_profile.tscn -LogFile <log> -UserArguments "--mode=render" -TimeoutSeconds 1200 -QuitAfterFrames 1000000
```

## Handoff notes

- **Temporary instrumentation, this branch only:**
  - `scripts/terrain_cost_counters.gd`;
  - the wrappers in `scripts/planet_environment.gd` and `scripts/local_terrain.gd`, which are shared hotspots;
  - the timestamp in `_trace_load`.
  - The wrappers add about 0.6 µs per call even when disabled. **Do not integrate them into `main`.** Only this document, the JSON data and, optionally, the probe scene are meant to be kept.
- **Save compatibility:** no save or format changes. The player quicksave was only read, and copied into private test user data.
- **Not measured:**
  - Mac or low-end GPUs;
  - a mature-campaign windowed pan (the windowed run used a fresh world);
  - GPU upload cost in headless mode;
  - threaded or native implementations (the estimates above assume the measured floors).
