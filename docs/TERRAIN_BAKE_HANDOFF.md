# Terrain query fixes and per-world macro bake — September 23

Worker `C:/Users/sjpur/tt-terrain-bake`, branch `codex/terrain-bake`, base
`d55b339a` (main). Follows `docs/TERRAIN_COST_PROFILE.md` on
`codex/terrain-cost-profile` (203277ca). None of that branch's counting
instrumentation is included; the harness here times the real functions.

## What changed

**Cheap fixes (exact, always on)**

- `local_terrain.gd` `_surface_water_sources` now walks each tributary through the
  existing 16-segment chunk index (per-course chunk ranges added to
  `_index_tributary_chunks`). Culling keeps a 10 m allowance for float32 bounds;
  the chosen point and distance are the same as the former full scan.
- `_river_distance_at` no longer builds every source record. It returns exactly
  `min(distance_km)` over `_surface_water_sources(origin)`: main river and
  drainage first, then tributary courses nearest-bounds-first, stopping once no
  course can beat the best valid (above-sea) source.
- `PlanetEnvironment.profile_at` resolves observed `height`, `coastal`, `biome`,
  `woodland` and `fertility` lazily (`Dictionary.get` evaluated the 24-probe
  coast check and planet height even when supplied).
- Unobserved profiles are cached as deeply read-only dictionaries and returned
  shared; no `duplicate(true)` per call. Audited callers only read them;
  `settlement_model` already duplicates before storing. One test that edited a
  returned profile now edits a copy (`tests/test_planet_environment.gd`).
  Observed-ground profiles stay fresh and writable.

**Macro bake (per world seed)**

- `scripts/terrain_macro_bake.gd`: one lattice raster built on a single
  background WorkerThreadPool thread, band by band, deterministic, cancellable,
  cached compressed in `user://terrain_macro/` (key: kind, seed, generator
  fingerprint from exact probe samples, lattice geometry). Two render files and
  four land-mask files are kept; older ones are pruned.
- Planet land mask (`planet_environment.gd`, bottom section): 3840×1920 cells
  (10.4 km). Each cell is classified from its four exact corner heights as
  certainly land (>0.015), certainly sea (<0) or uncertain, with margin
  `0.8 + 0.75 × (corner range)`. `is_land` and `profile_at`'s coast probes use
  certain cells and fall back to the exact noise height otherwise. Heights,
  climate, geology and resources are never served from the raster, so every
  profile value is bit-identical and independent of when the bake finished.
- Render rasters (`scripts/terrain_macro_render.gd`, owned by LocalTerrain):
  level 0 covers the planet on 1921×961 nodes (20.9 km); level 1 is a
  1153×1153 window at 7.0 km (~8,000 km wide) centred on a 2,000 km grid near the
  settlement/start site, re-centred (and cached, six windows kept) when a
  continental patch falls outside it. A continental job still sampling noise when
  a fitting raster lands restarts on the raster. Each node stores the patch builder's exact
  sample (height f32, seasonality f32, colour and surface fields as the RGBA8 the
  vertex format keeps). `TerrainPatchBuilder` filters bilinearly from the finest
  ready level whose cell is no larger than the patch's vertex spacing and which
  contains the whole patch. Region scale and closer (≤2,217 km spans at 385
  vertices) always use the procedural sampler, so close terrain is unchanged.
  Raster samples are tagged and never reused as exact samples.
- LocalTerrain edits are marked `codex/terrain-bake`: one member, bind in
  `_ready`, one `tick` line in `_process`, the raster assignment after the patch
  job is created, `_exit_tree` cancel, and the river/chunk functions.
- Bakes start 1.5 s after the world scene starts processing (unit tests that
  never process frames never bake), one at a time: planet render level, land
  mask, regional level. Until a level is ready, everything uses noise.

**Why not more threads, and why climate is not rasterized.** In the editor build
the player uses, GDScript object calls validate through ObjectDB's global lock.
Measured: 32 sampling threads were no faster than one, and the main thread's
GDScript cost rose ~10× with nine bake threads, +20–37% with one busy thread and
+12% with one thread at 50% duty (shipped default). A parallel global-mesh build
was tried, produced identical meshes, and gave no speedup, so it was removed.
A GDScript bilinear lookup costs about as much as one FastNoiseLite call, so
rasterizing individual climate/geology channels in `profile_at` would not be
faster and would make gameplay values depend on bake timing.

## Visual QA (merged tree, RTX 4090 via tools/run_isolated_gpu_probe.ps1)

`tests/terrain_bake_capture.tscn` (fog lifted for QA), same camera, raster vs noise,
PNGs in `reports/terrain-bake/` (not committed). Continent view at the start and over a
coast: 0.4–0.6% of pixels differ by more than 24/255 (mean 0.6–0.7/255), all along
shorelines: the raster coast is slightly smoother, some one-vertex islets and inlet
steps are missing. No seams inside patches. 2,217 km and 50,000 ft views are
pixel-identical (procedural in both). Zoom-out popping (83 km global mesh →
detailed patch) is pre-existing and shorter with rasters (~110 frames vs ~500).
Cold bake during idle play: 48,708 frames, p99 1.6 ms, max 3.5 ms, none >33 ms;
after bake p99 1.6 ms, max 4.0 ms: no visible hitch. The level-1 window was widened
and grid-snapped after QA showed the old 5,343 km window re-baking on every
continental pan; figures below predate that (2,217 km finals are now procedural).

## Before / after (paired runs, same host minutes apart)

Headless, Godot 4.7 editor binary, i9-14900KF, host shared with other workers
(±10–35% run-to-run). Harness `tests/terrain_bake_profile.tscn` (modes `micro`,
`patch`, `pan`, `newworld`, `dayfresh`, `equiv`, `contention`). "After, noise"
= fixes only; "after, baked" = land mask ready.

| Query (ns/call) | Before | After, noise | After, baked |
|---|---:|---:|---:|
| `LT._river_distance_at` | 119,251 | 14,307 | 21,603 |
| `LT._surface_water_sources` (6 km) | 74,558 | 26,108 | 24,433 |
| `LT._surface_water_sources` (no limit) | 133,989 | 115,897 | (same code) |
| `LT._survey_ground_at` | 219,380 | 120,125 | 109,485 |
| `LT._sample_civilization_geography` (miss) | 1,631,650 | 1,100,875 | 855,725 |
| `PE.profile_at` cold | 110,654 | 87,456 | 40,587 |
| `PE.profile_at` cached hit | 9,342 | 2,522 | 1,731 |
| `PE.profile_at` with observed height+coast | 79,928 | 22,639 | 18,962 |
| `PE._coastal_at` | 66,090 | 70,648 | 17,968 |
| `PE.is_land` (land) | 3,022 | 1,933 | 916 |
| `PE.is_land` (planet mix, 70% ocean) | 2,007 | 1,424 | 1,655 |
| `PE.nearest_viable_land` (ocean start, cold) | 654,030 | 889,615 | 532,045 |

The last two rows are noisy; ocean points already exit early, so the mask gains
little there. The mask answers 62% of random planet queries (certain sea 62% of
cells, certain land 10%, uncertain 29%).

| Patch build, CPU ms (real sampler vs raster) | Before | After |
|---|---:|---:|
| 10,000 ft / 50,000 ft / Region final | 2,269 / 777 / 3,538 | unchanged (procedural) |
| Continent preview 129² (4,988 km) | 323 | 39 |
| Continent final 385² (4,988 km) | 2,858 | 357 |
| 2,217 km / 3,325 km final | 2,975 / 2,645 | 370 / 340 |
| 11,223 km final (game's continent view) | 2,084 | 358 |
| 438–1,478 km and 7,482 km finals | 2,170–3,360 | unchanged (no fitting level) |
| Global planet mesh at load (481×241) | 1,516 | 1,697 (unchanged; variance) |

| Time to full detail, real `_process` (frames / CPU ms / headless wall) | Before | After |
|---|---:|---:|
| Continent zoom | 764 / 2,433 / 12.7 s | **161 / 440 / 2.7 s** |
| Continent after 180-frame pan | 596 frames | **105 frames** |
| 10,000 ft, 50,000 ft, Region | 862, 1,415, 674 | 861, 1,470, 814 (procedural; variance) |

| Load and days | Before | After |
|---|---:|---:|
| New world `_ready` | 8,874 ms | 7,965 ms (river/profile fixes in world configuration) |
| First streamed patch | 58 frames | 58 frames |
| Fresh world day 1 (12 rivals, cold geography) | 1,440 ms | 1,212 ms |
| Fresh world days 2–20, mean | 58.8 ms | 58.8 ms |

Terrain was ~3–5% of a later day in the cost profile; the fixes did not move
that measurably. Day 1 drops ~16% (rival geography, water sources).

| Bake | Cold (50% duty) | Warm (cache) |
|---|---:|---:|
| Planet render level 0 | 38–43 s | 65–80 ms |
| Land mask | 23 s | 8–16 ms |
| Regional level 1 | 26–30 s | ~40 ms |
| Main-thread GDScript cost while baking | +12% (was +37% at 100% duty) | none |
| Memory / disk per world | 54 MB RAM | 19.6 + 12.0 + 0.3 MB |

## Determinism and equivalence

- Cheap fixes: river distance, nearest tributary, all water sources (6 km and
  unlimited), four profile variants (cold, hit, two observed), nearest viable
  land and `is_land` on 3,000/600/1,200/120/300 points produce a SHA-256 digest
  identical to the base commit (`10a246dd…`). With the land mask ready the same
  outputs are identical to the noise path.
- Land mask vs exact heights: 0 flips in 1,000,000 + 400,000 random samples
  (half planet-wide, half within 4,000 km of the cradle) for both the land and
  sea-level thresholds. Calibration on four seeds: exact height strayed at most
  0.36 km outside the corner range in flat cells; margin is ≥2.2× that.
- AI placement: `CivilizationStart.candidate` for 120 seat/seed combinations is
  identical with and without the mask; `is_land` at all 120 sites matches the
  exact predicate. Founding-site advice, settlement surface checks and
  `_scout_land_at` use LocalTerrain's exact height and never read either raster.
- Raster nodes vs the exact sampler: height error ≤2.3e-7 km (float32), colour
  ≤1/512 (RGBA8). `vertex_sample` equals the patch builder chain bit for bit
  (unit test).
- Raster-built vs procedural patches at the same vertices (visual only):

| Patch | Height RMS | p99 | 5×5 low-pass RMS / max | Colour RMS | Shore-vertex flips |
|---|---:|---:|---:|---:|---:|
| Continent final 4,988 km (L1) | 86 m | 323 m | 17 / 236 m | 0.015 | 0.32% |
| 2,217 km final (L1) | 114 m | 377 m | 24 / 216 m | 0.014 | 0.23% |
| 11,223 km final (L0) | 143 m | 530 m | 28 / 423 m | 0.022 | 0.77% |

  Maximum single-vertex differences (3–6 km) are sharp peaks that the procedural
  mesh point-samples between 13–29 km vertices; both depictions alias sub-cell
  relief. The filtered planet shape agrees within tens of metres.

## Tests

- New `tests/test_terrain_bake.gd` (8 cases): chunked sources equal the old full
  scan (oracle copied verbatim); river distance equals the minimum valid source
  including submerged tributaries; observed ground skips height/coast probes;
  cached profiles shared and deeply read-only; land-mask cells certain and
  `is_land` exact on a real equatorial band; raster patch path, tagging and
  no-reuse; `vertex_sample` equals the builder chain; binding and level choice.
- gdUnit, 26 terrain/river/planet/founding/water/landscape suites, 173 cases:
  all pass except `test_coastal_water` (Object `in` error) and
  `test_polymer_processing` (catalog key order), which fail identically on the
  base commit. After the fixes, a 7-suite rerun (46 cases, including the new
  suite and `test_planet_environment`) passes cleanly.
- The whole `tests/` directory in one process (2,245 cases) produces many
  unrelated cross-suite failures (for example 392 "Nonexistent 'String'
  constructor" errors). It is not a clean baseline. It is still useful for one
  check: no "read-only" dictionary error occurs anywhere, and no error
  backtrace points into the touched scripts.
- `founding_clarity_probe` (headless) prints the same 86 lines as on the base
  commit. Those lines include MISMATCH lines that already exist on base.
  Capture probes (ground/LOD/precision/seasonal) need a window. They were not
  run on the GPU.
- Harness modes `equiv` and `contention` can be rerun as regression checks.
  `tests/terrain_bake_calibration.tscn` re-measures the land-mask margin.
  The harness needs an ignored `override.cfg` that sets
  `config/custom_user_dir_name="TomorrowTerrainBakeTests"`.

## Limitations

- Only continental views benefit; Region scale and closer still sample
  procedurally at the same per-frame budget. New-world load and the global mesh
  are unchanged apart from the query fixes (threading cannot help in the editor
  build).
- The first session in a new world spends ~95 s of one background thread
  (+12% main-thread GDScript cost) before all rasters exist; the continental
  raster is ready after ~40 s. Cached worlds are ready in ~0.2 s. Visual patches
  built before a level is ready stay procedural until rebuilt.
- The land-mask margin is empirical (0 flips in 1.4 M samples, 4 seeds), not a
  proof. Raising `MACRO_MARGIN` trades speed for headroom; the cache key
  includes the margin.
- Cached profile dictionaries are read-only: a future caller that edits one gets
  a runtime error and must duplicate first.
- Not measured: windowed GPU runs, Mac, a mature campaign pan. No GPU captures
  were taken; equivalence is numeric.

Save compatibility: no save or format change. Caches live only in
`user://terrain_macro/`; nothing generated is committed. Shared hotspot touched:
`local_terrain.gd` (delimited edits above). Also `planet_environment.gd` and
`terrain_patch_builder.gd`.
