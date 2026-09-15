# Mountain structure at playable distances

Worktree: `/Users/seanpurtill/Documents/Codex/tt-google-earth-ridge-structure`
Branch: `codex/google-earth-ridge-structure`
Base: `dee9c117f8dfdd6a7408fac5e77f1dac1998fe1d`

## Change

The existing mountain envelope varies mainly over tens to hundreds of kilometres.
Paired plain-material captures confirmed that its relief is nearly flat across a
4–12 km camera footprint. The new shared `terrain_mountain_relief.gd` adds seeded,
weighted, five-octave ridges within that envelope. This changes actual sampled
heights and normals, not painted shadow lines. Local terrain and the planet's
environmental counterpart use the same detail model. The pre-existing local
cradle range also receives detail. Existing broader differences between those
two authorities are not eliminated by this pass.

The model fades from zero at 350 m of mountain uplift to full strength at 2.8 km.
Its theoretical height adjustment is bounded to -180 m / +620 m. Another smooth
weight suppresses changes below 200 m absolute ground height and reaches full
strength at 800 m. Ocean generation and the subsequent authored floodplain
blend retain their prior ordering. No additional textures, draw calls, mesh
vertices, persistent caches, or save fields are added.

## Verification

- Headless import passed. 34/34 GdUnit cases pass, without errors, failures,
  skips, flaky cases or orphans: mountain relief, terrain LOD, patch builder,
  sample reuse and planet environment. Log: `/tmp/tt-ridge-tests.log`.
- Eight new cases cover lowland identity, bounds, seed determinism and variation,
  continuous foothill fade, distant-coordinate continuity, physical terrain
  participation, sampled ocean/coast preservation, and identical detail in both
  geographic consumers where their uplift envelopes coincide.
- Guarded native `terrain_ridge_probe` passes 16 visual assertions across two
  seeds, three view widths and paired actual/neutral materials. Captures and
  measurements are in `artifacts/terrain-ridges/detail/` and
  `artifacts/macos-background-capture/terrain_ridge_probe.log`. At 4 and 12 km,
  plain-material luminance variation exceeds twice baseline in all four pairs.
  This is evidence of visible relief, not a sufficient realism score.
- The capture explicitly rebinds the actual material before every textured view.
  An earlier harness iteration accidentally retained the plain material on later
  widths; those images were superseded and do not establish textured appearance.
- Final guarded native `terrain_lod_probe` passes all four distances, retained
  detail during pans, >130,000 reused samples, cancelled-job fallback, identical
  fog pixels and the physical world edge. It exited normally. This run was slow:
  final refinement took 10.1 / 84.8 / 142.4 / 101.5 seconds from continent to
  closest view; a covered pan took 22.7 seconds. Frame p95 ranged 20.0–31.4 ms.
  The maximum recorded slice reached 296 ms. These are worse preparation times
  than prior-turn receipts; host scheduling/rendering versus code effects have
  not been conclusively separated. This is a functional pass, not a latency pass.
- Paired headless height-only benchmark: 66,049 samples per run, three pairs
  at each of two sites. Median baseline/detail: 213.935/230.207 ms at
  (2000,-1000), 227.873/242.265 ms at (55,0), approximately +7.6% / +6.3%.
  Log: `/tmp/tt-ridge-benchmark.log`. Both arms include the new call wrapper;
  this isolates noise cost and slightly understates total pre-pass overhead.
  Native mesh-build timings also include frame waits and host load. No FPS gain
  or overall rendering-performance claim follows from these measurements.
- A follow-up paired **complete** headless 385-square mesh build, using every
  production callback including seasonality, measured baseline 1850.556/1843.669
  ms and detailed 1879.056/1899.687 ms, about +2.3% on average. This shows the
  new sample computation does not explain the much larger native elapsed-time
  difference by itself, but does not isolate GPU or scheduling effects.
  Receipt: `/tmp/tt-ridge-full-benchmark.log`.

## Rejected alternative and remaining limits

FastNoiseLite already folds individual octaves when producing ridged noise:
https://github.com/Auburn/FastNoiseLite/blob/master/Cpp/FastNoiseLite.h
The existing broad mountain formula folds that signal again. A monotonic
replacement, `pow(clamp(noise * .5 + .5, 0, 1), 2.35)`, was compared to the old
fold in two seeded regions. It substantially moves broad uplift but does not
solve the absence of kilometre-scale structure. That replacement is not shipped.
The initial comparison PNGs remain in `artifacts/terrain-ridges/`.

The delivered ridges are procedural terrain, not simulated erosion or connected
downhill hydrology. Palette uniformity, physically coherent drainage and distant
mesh sampling remain incomplete relative to the Google Earth-like objective.
Native close views still expose some narrow crest/mesh artifacts; this pass does
not claim final visual quality. The user asked to stop after this pass, so no
follow-up terrain pass is authorized by this handoff.

## Compatibility and integration

No save schema change. Existing world X/Z positions and seeds are retained, but
mountain elevations and therefore local slopes/climate samples change on reload.
Normal terrain, settlement, route and marker reconstruction samples current
ground height. Arbitrary old campaigns with stored environmental observations
are not exhaustively revalidated; this is not an exact-geography save guarantee.
The currently running player and its editor are left untouched.

Shared-file changes are small additions in `local_terrain.gd` and
`planet_environment.gd`; no government, population, labor, or campaign systems
were changed. Only the integrator may label the pass part of canonical main and
build it. A new package does not update an already-running player.
