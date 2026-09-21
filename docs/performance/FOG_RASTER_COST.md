# Fog corridor raster cost

Base `d4ba4fae`; worktree `/Users/seanpurtill/.codex/worktrees/campaign-performance`; branch `codex/fog-redraw-cost`. Only the renderer's segment-paint loop changes.

A new scouting chart triggers a full explored-mask repaint. The old segment painter tested every pixel in each trail segment's axis-aligned bounding rectangle. Long diagonal routes therefore tested a large area of unrelated pixels even though the revealed corridor is narrow. More retained routes multiplied this work.

The loop now clips each row to a conservative horizontal interval around the portion of the segment that can touch that row. A one-pixel guard covers floating-point endpoint rounding, and the interval stays inside the original image/segment bounds. Every retained pixel uses the original closest-point distance, smoothing and maximum-reveal blend. Horizontal/degenerate segments retain the full original horizontal bounds. Existing circles, mask resolution, fog semantics and shader behavior are unchanged.

## Measurements

Headless `tools/fog_raster_cost_probe.tscn` uses the actual planetary dimensions and 1024×512 L8 mask. The reference implementation is retained in `tests/fog_painter_reference.gd` solely as a numerical oracle. Each image is checked byte-for-byte.

| Corridor | Before | After |
| --- | ---: | ---: |
| Long diagonal | 28.149 ms | 0.924 ms |
| Regional diagonal | 1.138 ms | 0.224 ms |
| Long horizontal | 0.452 ms | 0.419 ms |

These are individual synthetic paint calls, not total fog-redraw time, sustained FPS or whole-campaign throughput. A large number of segments still increases repaint cost; this change removes the empty bounding-rectangle work rather than making repaint complexity independent of chart size. Wide corridors have less unnecessary area to eliminate.

## Validation

Six focused cases pass across test_fog_raster_cost.gd and test_accumulated_history_cost.gd with zero errors, failures, skips or orphans. Numerical coverage includes 49 fixed/seeded-random corridor cases at 128×64, plus overlapping corridors and an existing disc at the real mask resolution. Cases include horizontal, vertical, reversed, zero-length, tiny-radius, wide-radius, near-horizontal, off-map and clipped trails. The existing fog-refresh tests verify unchanged revisions, live origins, forced refresh and trail/circle dispatch.

The first probe configuration used the uninitialized terrain node's local 100 km defaults. It was corrected to the same PLANET_WIDTH_KM/PLANET_DEPTH_KM used by normal planetary terrain setup; only the corrected results are reported above. No player/editor was launched or restarted. No save changes or simulation formulas changed. Since this is a pure pixel-loop change with an exact image oracle, another 24-day simulation replay was unnecessary. The previous pass's daily-tick timing increase remains unresolved; this renderer result does not explain it or establish an overall daily simulation speedup.
