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

Capture and compare mixed-unit formations and inspect camera framing. Then
audit settlement silhouettes at supported Google Earth map distances: favor
period-appropriate roof/ground colors, coherent expansion, fields and paths;
avoid pasted photographic tiles and oversized individual buildings. Preserve
the existing menu UI. Read current AGENTS.md and WORKER_HANDOFF.md each cycle,
check integration state, and keep changes in this worktree. Commit bounded
milestones and document actual visual verification and known limitations.
