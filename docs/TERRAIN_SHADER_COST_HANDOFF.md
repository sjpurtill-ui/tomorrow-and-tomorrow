# Terrain shading cost

Worktree: `/Users/seanpurtill/Documents/Codex/tt-terrain-shader-cost`  
Branch: `codex/terrain-shader-cost`  
Base: `ef3eb8701ddc7bce05648da0268731440162aa29`  
Owner: sole integrator. Shared runtime file: `scripts/local_terrain.gd`, terrain shader only. Also owns the paired native probe/scene, baseline extractor and its private capture-runner registration. No other worker or art changes are included.

## Behavior

The terrain shader previously evaluated its entire surface even when fog concealed it completely. It also calculated fine soil/clearing noise at distant views where that detail had exactly zero influence. The shader now tests existing fog visibility first and skips hidden surface work; it evaluates the close-detail block only while its existing weight is positive. The visible calculations and the unlit unknown-ground color are retained.

This keeps the integrated woodland crown scale, physical terrain, moisture, geology, season, clearing/regrowth, coordinate precision, four camera distances and fog boundaries. It introduces no assets, textures, geometry, larger caches, simulation changes or save migration. Existing saves use the revised shader when loaded in the updated build.

## Verification

All 41 worktree cases pass across canopy transition, landscape cover, seasonal landscape, surface precision, terrain LOD, landscape resource visuals and camera distances: zero errors/failures/flaky cases/skips/orphans. The final ordinary editor import and normal-entry headless boot are clean. Logs: `artifacts/terrain-shader-cost/tests.log`, `final-import.log` and `boot.log`.

The guarded native `terrain_shader_cost_probe` compares the exact shader extracted from the base revision against the production candidate. Baseline SHA256: `7a1c2d6ac82f8147ed98f552e88d8518b28ec6dd14f24f97a248a92c4592450e`. Missing baselines fail rather than silently comparing the candidate to itself. Both shaders render the same flat geometry, actual camera presets, controlled climate and known/hidden/edge fog masks. Additional comparisons use real heights, climate, normals and geology at temperate woodland `(12000,-3800)`, dryland `(6600,-3280)` and coast `(10496.72,2000)` on seed 873421.

All appearance checks pass. Fully hidden views are byte-identical. Visible comparisons are either identical or differ by one 8-bit channel value in at most 9 of 921,600 pixels (under 0.001%); these are the observed final-color rounding differences, not a claim of universal byte identity. The probe permits at most one code value in under 0.005% of visible pixels and requires exact hidden pixels. Woodland, dryland, coast/fog-edge and complete close/continental captures were visually inspected.

The complete `terrain_lod_probe` also passes all four distances, progressive coverage, fallback during cancellation, concealed mountains/plains/ocean and physical planet clipping. This separate probe includes water; the paired shader comparison deliberately isolates land material. Both native probes use the private background guard and canary, Dummy audio, explicit worktree path and private userdata. Both exited; no player/editor was opened or stopped.

## Measured cost and limits

The isolated 1280×720 native comparison runs baseline/candidate/candidate/baseline, with 20 warmup and 64 timed frames per pass, uncapped and with VSync disabled only in the private probe. Timing precedes image readback. The values below average the two median frame intervals for each variant; they are render-loop measurements, **not populated-campaign FPS or GPU timer measurements**. The Compatibility GPU timer returned only zero samples and is unavailable here. An unrelated headless technology audit was running and was left alone; host load varies.

| View | Baseline ms | Candidate ms | Reduction |
| --- | ---: | ---: | ---: |
| Known, 10,000 ft | 7.870 | 7.260 | 7.8% |
| Known, 50,000 ft | 8.179 | 5.418 | 33.8% |
| Known, Region | 8.159 | 5.679 | 30.4% |
| Known, Continent | 7.850 | 5.193 | 33.8% |
| Hidden, 10,000 ft | 7.943 | 0.750 | 90.6% |
| Hidden, 50,000 ft | 8.262 | 1.137 | 86.2% |
| Hidden, Region | 8.195 | 1.142 | 86.1% |
| Hidden, Continent | 7.807 | 0.947 | 87.9% |
| Fog edge, 10,000 ft | 8.074 | 4.777 | 40.8% |
| Fog edge, Continent | 7.798 | 3.252 | 58.3% |

Raw records: `artifacts/terrain-shader-cost/measurements.json`, `summary.json`, and `artifacts/macos-background-capture/terrain_shader_cost_probe.log`. The complete LOD run observed frame p95 of 22.2–29.0 ms, final refinement in 8.9–14.0 seconds behind progressive previews and a maximum mesh upload of 24.9 ms. Those figures are not a paired whole-game performance claim. This change does not resolve synchronous simulation-day stalls, terrain generation latency, coarse distant shore sampling or the broader landscape redesign.

Reproduce the native comparison from this worktree with an owned `TomorrowCanopyTransitionTests`/Dummy-audio override:

```sh
python3 tools/prepare_terrain_shader_baseline.py ef3eb8701ddc7bce05648da0268731440162aa29
python3 tools/macos_capture/run.py terrain_shader_cost_probe
python3 tools/macos_capture/run.py terrain_lod_probe
```

Keep probes private and remove the owned override before delivery. An initial fresh recovery-mode import crashed during a font import; the retry and final ordinary import are clean. The discarded first experiment used a shader-fragment return unsupported by Godot, and the first appearance assertion was too strict for final 8-bit rounding. Historical failed logs are retained separately; final records above identify the corrected implementation and checks.

## Integration

READY after worktree validation. Review the small shared-shader diff, integrate this source alone, run combined canonical checks, remove test overrides and package with the normal Mac launcher in build-only mode. Do not restart a player/editor. Old discovery/portrait/window-art work remains stopped and unintegrated. No save schema or player/opponent rule changes; no shared-file conflicts against the stated base.
