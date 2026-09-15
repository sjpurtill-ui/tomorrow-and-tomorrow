# Dryland aerial surface detail

READY from `/Users/seanpurtill/Documents/Codex/tt-google-earth-dryland-detail`,
branch `codex/google-earth-dryland-detail`, base `5c676ceee42bfa8119476b15dbec7bb982eb231d`.

## Behavior

Close dry ground retains its source scrub/soil contrast instead of receiving a
constant 62% flat soil wash. Climate and geology still govern the distant palette;
the soil overlay fades to 16% when its local features resolve. The existing
semiarid texture uses a 500 m footprint and the aerial canopy visibility threshold,
replacing the previous 15 m footprint that mipmapped its shrubs into noise.
The same two samples are rotated and smoothly warped to reduce repetition.

Owned runtime files: `scripts/local_terrain.gd` and
`scripts/ground_surface.gdshaderinc`. No geometry, resource, simulation or save
changes. `local_terrain.gd` is a shared integration hotspot; review its small
material-only diff before integrating.

## Evidence

- Ground fields and surface precision: 12/12 GdUnit cases pass, zero errors,
  failures, skipped cases or orphans (`/tmp/tt-dryland-tests.log`).
- Isolated native `ground_surface_probe`: PASS. Four real biome locations,
  geological controls, concealed geology, and all four production camera levels.
- Matched prior captures in `tt-google-earth-landcover-edges/artifacts/ground-surfaces`
  show Region and Continent pixel-identical, woodland pixel-identical, and wet
  grassland with only negligible shader rounding. Close steppe luminance spread
  rises from 0.02266 to 0.03890. This is supporting contrast evidence, not an
  overall realism score. Reviewed captures are in this worktree's
  `artifacts/ground-surfaces`.
- Isolated native `terrain_lod_probe`: PASS, including streamed coverage at all
  four distances, cancellation fallback, hidden land/ocean equality and world edge.
  Log: `artifacts/macos-background-capture/terrain_lod_probe.log`.
- Both graphical probes exited. Tests used private userdata and the guarded
  background capture runner. No player launch or live-session replacement.

## Limits and follow-up

The shader adds no texture reads or geometry. A larger physical image footprint
uses more detailed mip levels, so this is not a measured frame-rate improvement.
Streaming p95 during this run was about 21–24 ms with the player's game also live;
that is not an isolated comparison against an earlier build.

This improves a still-procedural landscape; it does not achieve Google Earth
fidelity. Broad plains still lack coherent geomorphological detail. Future work
should investigate actual terrain forms and drainage continuity, rather than
repeatedly raising surface contrast to compensate for missing landforms.
