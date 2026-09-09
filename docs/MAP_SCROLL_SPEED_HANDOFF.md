# Adjustable map scrolling

READY from `codex/map-scroll-sensitivity` in `/Users/seanpurtill/Documents/Codex/tt-command-order-state`, based on `9d5966b7e1c54b510672dfcf2c687e980cd686c3`. Ownership: trackpad pan and menu insertion in `scripts/local_terrain.gd`, `scripts/display_preferences.gd`, focused input/preferences/layout checks and Mac navigation documentation.

Two-finger map panning defaults to four times its previous pace. Menu → Map Controls → Map scroll speed offers 0.5×–12× in 0.5× steps, a live numeric readout and Default button (4×). It is near the top of the menu and applies on the next pan event. The preference persists in the existing machine-local display.cfg under camera/map_scroll_speed. Existing display/audio preferences are retained; older settings receive the faster default. Invalid/nonfinite values fall back and numeric values are bounded. Four zoom levels, arrow zoom and scrolling inside panels are unchanged. Keyboard navigation is blocked behind the open settings menu so slider adjustments cannot also pan the background.

Worktree validation, explicit path and isolated test userdata:

- gdUnit `test_map_scroll_preferences`, `test_camera_distance_levels`, `test_map_panel_dismissal`: **9 tests**, zero errors/failures/skips/orphans, exit 0. Covers live movement ratio from the real slider, persisted/reopened values, Default, legacy display/audio retention, bounds, invalid values and settings keyboard isolation. `/tmp/tt-scroll-sensitivity-tests.log`.
- `res://tests/trackpad_zoom_probe.tscn`: **49 checks**, zero failures, exit 0; default speed at all four distances plus input/GUI propagation. The lightweight fixture now uses the real planetary bounds so Continent movement is not incorrectly clipped by its former 100 km test world. `/tmp/tt-scroll-sensitivity-input.log`.
- `res://tests/mac_display_probe.tscn`: **77 checks**, zero failures, exit 0. Real main-map/menu layout at 1280×720 and 1440×900, interface scale 100–175%; slider visible on menu opening, existing display/audio/save/quit checks. `/tmp/tt-scroll-sensitivity-display.log`.
- `git diff --check` passes; owned override removed.

No campaign save format or simulation changes. No shared-file conflicts at handoff; local_terrain.gd remains a shared hotspot. Synthetic/headless checks establish behavior/layout, not subjective trackpad feel. The current player remains untouched and needs the updated standalone release on next launch. Canonical verification is recorded separately in INTEGRATION_STATUS.md.
