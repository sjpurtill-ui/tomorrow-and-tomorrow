# Closest counter scale

Branch `codex/closest-counter-scale`, base `35ee0b0`.

The renderer no longer overrides the presentation's 0.0005 minimum scale with
0.001. At the permitted 0.035 km camera size this removes about 79% excess size;
at 0.05 km it removes 25% excess size. Normal map scales are unchanged.

Runtime regression tested player and foreign counters at 0.035, 0.05, 0.1 and 8 km,
including stable compact-count text scale. Before correction: four scale failures.
After correction: WARFARE_MAP_RUNTIME_PROBE PASS. Existing shutdown resource
warnings remain. No save, simulation, camera-limit or menu changes.

Shared file: local_terrain.gd, one renderer scale expression and its comment.
