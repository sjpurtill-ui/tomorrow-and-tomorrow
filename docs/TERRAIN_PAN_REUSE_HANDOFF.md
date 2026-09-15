# Preserve detailed terrain while panning

READY from `/Users/seanpurtill/Documents/Codex/tt-google-earth-pan-reuse`, branch
`codex/google-earth-pan-reuse`, base `075eba154dac`.

## Behavior and scope

Completed terrain patches retain immutable packed samples within the existing
four-entry / 600,000-vertex cache. Adjacent requests copy only samples at exactly
matching float32 map coordinates, including climate, geology, woodland color and
seasonal amplitude. They resample entering ground and recalculate edge normals.
Intermediate zoom grids now snap by whole mesh cells so 257/513 grids also share
observations. Coarse-to-fine refinement skips impossible sample lookups.

When the finished patch conservatively covers the camera and the next patch has
substantial overlap, it stays visible until a full-detail replacement is ready.
Other requests retain the normal preview/refinement sequence and global fallback.
Reuse rejects other seeds/provinces and missing required sample channels.

Runtime ownership: `scripts/terrain_patch_builder.gd`, `scripts/terrain_lod.gd`,
and the streaming portion of shared hotspot `scripts/local_terrain.gd`.
Tests, native capture allowlist, and benchmark scenes accompany the change.
There are no simulation or save-format changes. Sampling is evaluated at the
coordinate actually representable by the rendering mesh; authoritative terrain
functions and world geography are not replaced.

## Verification

- **25/25 GdUnit cases pass** across terrain reuse, LOD and ground fields, including
  far-world positions, intermediate zoom grids, nonmatching-grid fallback,
  missing channels, source immutability, seed exclusion, and retaining the
  displayed fine mesh. All copied mesh arrays match fresh builds exactly.
  Log: `/tmp/tt-pan-reuse-tests.log`.
- Native **terrain_pan_probe PASS** at two real locations. Each reused
  135,905 / 148,225 samples (91.69%) and produced a **pixel-identical** image to a
  fresh rebuild. Measured elapsed time inside builder slices fell from
  15,627 to 3,188 ms and from 15,106 to 3,010 ms. The original receipt names this
  field `cpu_ms`; the probe now accurately calls it `build_ms`. It excludes frame
  waits but includes possible OS preemption. This is not a full-game FPS claim.
- Native **terrain_lod_probe PASS** through all four distances and a covered
  close pan. That pan retained the fine mesh and finished in 2,957 ms; the initial
  close refinement took 12,069 ms in that run. Cancellation fallback, hidden
  mountains/plains/ocean equality, coverage and the planet edge also pass.
- Paired headless cold-build benchmark against `075eba1`: baseline 1,789.67 /
  1,787.46 ms; candidate 1,809.16 / 1,813.68 ms, about 1.3% overhead. Frozen baseline
  artifact SHA256: `4ee576a8603da15e1c7e8cd2c95e4a548415e50aa5c4da21f7a170b6ab8476c5`.
  Log: `/tmp/tt-pan-cold-benchmark.log`.

Native logs are under this worktree's `artifacts/macos-background-capture`;
matched PNGs and timing receipts are in `artifacts/terrain-pan` and
`artifacts/terrain-lod`. Native tests used the guarded background process and
private userdata and have exited. The first LOD run exceeded its old 3,000-frame
guard; that failure is retained in `terrain_lod_probe-frame-limit.log`. The check
now allows up to 180 seconds / 12,000 frames, exits cleanly on failed coverage,
and still requires complete refinement and all original geometry/fog assertions.

## Remaining limits

Cold continent and region refinement remain expensive under an active host
(59–70 seconds in the native run); the preview arrives earlier. Sample storage
adds up to roughly 29 MB behind the existing cache limit, plus the active patch
and in-progress request. No larger geometry or new shaders were introduced.
The live player was not restarted. This performance pass does not finish the
landscape goal: coherent landforms and physically plausible drainage still need
work. Inspect the existing double ridge transformation and drainage model next.
