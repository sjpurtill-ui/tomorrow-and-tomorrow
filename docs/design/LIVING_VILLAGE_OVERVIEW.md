# Living village Overview — October 5, 2026

HELD for user review. Branch `codex/living-village-overview`, based on
`5d8994b39a43b1740ededd8b16f982bf9c3a00d2`. Worktree:
`C:/Users/sjpur/.codex/worktrees/food-folio/TomorrowandTomorrow`.

Overview replaces its representative generated painting with a SubViewport camera
in the actual map World3D. Buildings, people, paths, terrain, weather and changes
are the same rendered objects as the player's map. It frames the inhabited plots
from a fixed southerly angle. Remote fields do not force the village to become a
tiny mark; framing widens with the inhabited footprint and retains the widest
recorded view. Clicking the image or Visit returns to that place on the map.

The map renderer currently streams one detail focus. While this portrait is open,
it temporarily focuses that streamer/map camera on the village. Closing the page
or switching tabs restores the previous camera; Visit explicitly retains the new
view. Map navigation is blocked during the portrait while normal UI remains
available. The secondary viewport is 1200x540 and stops rendering when hidden.
This does not instantiate another simulation or terrain scene.

History now starts with a dated album before the existing event chronicle and
charts. The first view and subsequent yearly/building/fabric/field/population
changes are recorded **while Overview is being viewed**, once the terrain and
settlement jobs finish. There is no background capture of unseen milestones and
no reconstruction of years before the first recorded visit. This is stated on
the page. A first visit to the tested campaign begins in Year 172, not Year 1.
Comparisons use a real recorded observation at least a year earlier, with its
actual year stated, rather than claiming a nonexistent winter baseline.

The album is `GameState.settlement_portrait_history`, reset for a new world and
included in normal SaveSystem reflection. Existing saves default to an empty
album. Each town retains its first image and the latest 23; 960x432 WebP images
are capped at 600 KB each. Images and their exact dated readings travel with the
save. No separate filesystem history can leak later events into an earlier save.
The save container version is unchanged; there is one additive optional field.

## Missing buildings found during the real-map preview

The saved campaign had progressed from early houses to later architecture while
retaining its small founding plots. The placement adapter discarded inherited
sites when the form changed, then failed to fit the much larger late kit inside
those plots. The renderer consequently displayed no later houses.

The fix retains valid recorded building footprints when a completed later form
replaces an earlier one, and fits the later mesh inside its inherited footprint.
A conservative circle envelope keeps every mesh corner within that footprint at
any retained angle. It does not move a house, create a road, bypass parcel limits,
or alter population/capacity, construction completion, or the simulation recipe.
Sites outside the current parcel are not adopted. The normal renderer and the
Overview both benefit. The actual saved fixture now renders 83 building
representatives; they are not a count of simulated households or people.

## Validation and ownership

- Overview/album/camera checks: 25/25 passing (report 16), followed by an 8/8
  focused recheck of the final album/camera changes (report 17).
- Early/later architecture and placement checks: 31/31 passing (report 15).
  The upgrade regression verifies retained locations, nonmutation by the pure
  layout function, actual rendered meshes, and every mesh corner inside its site.
- Private GPU acceptance uses an isolated copy of the actual campaign; the player
  save is read only. 1600x1050 and 1024x900 captures show the real Overview; History
  verifies 874 people against the settlement model. It checks camera restoration,
  Visit, and the album through the real SaveSystem reflection/variant codec.
  Final visual probe PID 66244 exited 0 without script/engine errors.
- Local evidence: `artifacts/living-village/{overview,overview-narrow,history,visit}.png`
  and `artifacts/living-village-preview-final.log`. These are preview evidence,
  not proof of delivery into the canonical game.

Reproduce the private GPU test with `tests/living_village_preview.tscn` through
`tools/run_isolated_gpu_probe.ps1`, Dummy audio and an isolated user directory
whose name contains `acceptance`. It expects a copied `village-preview.save` in
that directory; it never writes the player's save. Normal headless GdUnit suites:
`test_village_view_record`, `test_living_village_view`, `test_own_town_page`,
`test_camera_distance_levels`, `test_early_settlement_visual`,
`test_settlement_architecture_kit`, and `test_organic_town_visual`.

Owned code: the three new village-view components, Overview folio, settlement
provider, dock block registration, focused tests, and this delivery record.
Shared integration changes: three camera-input guards in `local_terrain.gd`,
the optional album field/reset in `game_state.gd`, and inherited visual-site
handling in `early_settlement_visual.gd` / `settlement_architecture_kit.gd`.
No `save_system.gd`, project settings, simulation authority, or terrain assets
are changed. Generated imports, local saves, dependency caches and captures are
excluded. Canonical main and the player's running session are untouched.
