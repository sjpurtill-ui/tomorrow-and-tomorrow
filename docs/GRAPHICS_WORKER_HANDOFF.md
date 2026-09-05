# Ongoing gameplay graphics work

Worktree: C:/Users/sjpur/tt-gameplay-graphics
Branch: codex/gameplay-graphics
Base: ffefea66752e12ccd6e59ae4ecf85c829ef901b9

## Pass 1: army formation spacing

Owned file: scripts/army_figure_formation.gd.
Each unit group has its own spacing and centered ranks. Siege equipment no
longer spreads all the infantry apart. Light troops have deterministic loose
files. Figure-budget changes now invalidate cached layouts correctly.

Validation: headless editor import and battle_graphics_probe passed (combat
invariance, metadata, casualty animation state, reset, retreat, pause, save and
192 representative cap). Visual capture review remains pending; these checks
do not establish aesthetic quality. Saves and combat state are unchanged.

Integration hotspot: army_figure_formation.gd layout/configuration. No main
merge or player launch. Integrator should assess formation framing at both map
and battle scales before integration, especially deep mixed siege columns.

## Next passes

Pass 3: restored authoritative occupied plot fabric at close aerial zoom. The
old photographic district clipmap remains retired. Its obsolete suppression
flag was still removing every built plot at LOD 0, leaving a village nearly
empty. Roof opacity now follows the live shader's aerial LOD instead of baking
a 73% opacity drop into vertices above 0.42 km.

Capture validation now waits for real frames and completes terrain streaming
before saving. Previously screenshots could contain an empty map or a small
detail patch floating in black, which hid the actual rendering problem.

Validation: 71 settlement visual architecture tests passed, including bounded
mesh counts at both close/aggregate LOD and identical roof vertex colors on
either side of the old opacity threshold. Inspected village-fabric.png and
village-readable.png at 0.5 km in artifacts. The latter has visible occupied
roof fabric without the retired district photo tiles. Capture shutdown still
reports pre-existing texture/RID leak warnings; no claim of leak resolution.
Town-scale visual review continues. Shared hotspot: local_terrain.gd; integrate
these hunks selectively with other renderer workers. No saves or menus changed.

Pass 2: rendered and inspected the mixed infantry/skirmisher/cavalry/siege
formation using tools/formation_graphics_capture.gd. The isolated OpenGL capture
auto-exits and is not the playable game. Screenshot:
artifacts/formation-review.png (local artifact, not committed).
Centered incomplete ranks after inspection. Compact infantry and separated
mounted/support groups are visible in the capture. This covers one mixed force;
extreme siege compositions and live terrain framing still need review.

Capture and compare mixed-unit formations and inspect camera framing. Then
audit settlement silhouettes at supported Google Earth map distances: favor
period-appropriate roof/ground colors, coherent expansion, fields and paths;
avoid pasted photographic tiles and oversized individual buildings. Preserve
the existing menu UI. Read current AGENTS.md and WORKER_HANDOFF.md each cycle,
check integration state, and keep changes in this worktree. Commit bounded
milestones and document actual visual verification and known limitations.
