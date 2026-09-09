# Readable city cards on the world map

READY from `codex/city-label-layout`, base `1de8c8a57bc36bb42bc43fa795542c61e9dbea9e`, worktree `/Users/seanpurtill/Documents/Codex/tt-command-order-state`. The canonical integration entry records the source commit after merge.

Owned files: `scripts/hud/city_labels.gd`, city annotation registration and picking in `scripts/local_terrain.gd`, `tests/test_city_label_layout.gd`, `tests/test_foreign_city_map_labels.gd`, shared format expectations in `tests/test_secondary_city_design.gd`, and this document. `local_terrain.gd` is a shared hotspot; no concurrent edits or conflicts were present.

All registered owned and reported city names now share one screen-space layout. Compact dark cards retain the name's casing, civilization-colored name and accent, flag, and population or dated estimate on a separate line. Known/unknown report data uses the existing city authority. Cards avoid each other and city pins, with leader lines back to their real map locations. Name wrapping preserves full multiword names. Valid offsets persist during small pans; unchanged frames reuse layout. City labels render beneath the HUD, and the old billboard text/flags no longer duplicate them.

Visible cards select the displayed city, including an owned card over a military marker. Physical city pin/building selection remains available. Foreign cards open the existing inline intelligence summary; owned cards open the city's existing management context. Four distance levels and input for map pan/zoom are retained. Unoccupied added cities correctly use the player's flag/color even when their occupation field is empty.

Finite screens cannot fit unlimited cards: excess entries remain in a clearly counted, scrollable city list with full names, population, flags and direct city actions. Close, Escape or an unhandled map click dismisses that list. This does not add knowledge of undiscovered cities or change the existing marker inventory/LOD budgets. Extremely long single-word names can use the list rather than being clipped into overlapping map cards.

Validation against this explicit worktree with isolated userdata `TomorrowCityLabelLayoutTests`:

- **23 tests pass**, zero errors/failures/skips/orphans, exit 0, across city label layout, foreign map labels, map-panel dismissal, camera distance levels and secondary city design. `/tmp/tt-city-label-layout-tests.log`.
- Six new behavioral cases cover a four-city collision, small-pan stability, resize/70-city overflow conservation, full-name wrapping, dense-list flags/actions/dismissal, and shared owned/foreign layout with the actual map click path selecting a city over an army marker. Existing all-altitude picking, reported population privacy, controller flags, local city simulation and zoom tests pass.
- The complete map/display/menu headless probe passes **77 checks**, zero failures, exit 0. `/tmp/tt-city-label-full-map.log`.
- A diagram using the layout algorithm and synthetic clustered positions was inspected at `/tmp/tt-city-card-layout-checked.svg.png`. It verifies card composition/spacing; it is explicitly not a native game screenshot. Native inspection remains pending a normal updated launch.
- `git diff --check` passes; the owned test override is removed before commit.

No simulation/save schema changes. Player PID 15785 remains the standalone source `705e015b8b5d`; no editor/player has been stopped or replaced. The updated code requires a new standalone build and a user-requested relaunch to reach that session.
