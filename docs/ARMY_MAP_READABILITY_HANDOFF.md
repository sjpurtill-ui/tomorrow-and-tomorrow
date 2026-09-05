# Army map readability pass

Base: `2ae6ee69dfe6792a15638cbf50ff34e6c20eb131`.
Branch: `codex/army-map-readability`.

- Close army meshes now receive the same reported records and selected army ID as map counters. Zooming no longer substitutes live coordinates/status for a runner report.
- Removed the extra formation label and implementation-facing representative-figure count. Existing counter labels and soldier totals remain authoritative.
- No simulation, menu, save, or combat changes.

Verification: warfare_map_runtime_probe passes, including last-known location, reported strength, stationary animation, no authoritative-state mutation, and no duplicate label. GdUnit map-presentation and formation-layout suites pass. Render inspected: artifacts/army-labels-clean.png, compared with the previous worker's armies-map-0.7.png.

Limitations: counters retain existing screen-edge/overlap behavior. Existing runner reports do not snapshot full equipment composition; this patch aligns supplied visual records, not the underlying report schema. Existing Godot resource-leak warnings occur at test shutdown. No player game launched.

Shared-file overlap: only `_refresh_player_field_army_markers` and `_refresh_close_army_figures` in scripts/local_terrain.gd; reserved with integrator. Tests extend tests/warfare_map_runtime_probe.gd. Generated imports/captures are excluded.
