# Trackpad pan and arrow-key distance

READY for integration from `codex/trackpad-pan-arrow-zoom` in `/Users/seanpurtill/Documents/Codex/tt-command-order-state`, based on `154d2c5e4b7260e8fef1d6a0746c84704298ff77`. Only the main-map input/help portions of `scripts/local_terrain.gd`, the existing trackpad event probe and Mac navigation documentation are owned.

Two-finger pan events move both screen axes, relative to camera rotation, at a view-scaled speed. Fractional movement is preserved. Neither pan nor magnification changes distance. Up/Down selects the adjacent one of the four existing distances, centered on the view, using the existing smooth transition and burst throttle. Key repeat is ignored for arrows. Per-frame movement no longer polls Up/Down. Main-map arrow shortcuts work after toolbar focus, while text entry, hovered panel controls and existing decision/menu guards keep their input. Mouse wheel, +/- and middle-drag/WASD alternatives remain.

Validation in the explicit worktree, with a temporary isolated userdata override:

- `Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-command-order-state res://tests/trackpad_zoom_probe.tscn`: **49 checks, zero failures**, normal exit. Real viewport event dispatch tests rotated/diagonal/fractional panning, all four scales, unchanged altitude, accidental pinch, arrow direction and boundaries, key repeat, separate keyboard movement, toolbar focus, panel scrolling, text entry and modal protection. `/tmp/tt-trackpad-pan-probe.log`.
- gdUnit suites `test_camera_distance_levels`, `test_map_onboarding_ui`, `test_map_panel_dismissal`, `test_main_map_services`: **27 tests, zero errors/failures/skips/orphans**, exit 0. Physical altitude, smooth transitions, map dismissal, settlement placement and separate-service map input remain valid. `/tmp/tt-trackpad-pan-tests.log`.
- `git diff --check` passes. Owned override removed before commit/export.

No simulation or save schema changes. No shared-file conflict at handoff; `local_terrain.gd` is a shared integration hotspot. Pan direction uses Godot's native scroll-direction deltas ([macOS implementation](https://github.com/godotengine/godot/blob/master/platform/macos/godot_content_view.mm)). Hardware feel is not established by synthetic events; native trackpad verification awaits the next player launch. The current standalone release is not interrupted and cannot receive source changes live. Build/integration verification belongs in INTEGRATION_STATUS.md.
