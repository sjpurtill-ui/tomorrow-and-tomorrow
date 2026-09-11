# Canopy transition — ready for integration

Integration receipt: source `14eb89050a60d835cb320d2decb56f9091a6e3e4` is now integrated into canonical Mac main by fast-forward from the base below. All 41 canonical focused cases and the isolated normal-entry headless boot pass. Both owned overrides are removed. Release target: `2026.09.10.5`. See `INTEGRATION_STATUS.md`; the worktree delivery and native evidence below remain the reviewed source record.

Worktree: `/Users/seanpurtill/Documents/Codex/tt-canopy-transition`
Branch: `codex/canopy-transition`
Base: `940d5a2ad848d9f45b8d98825cd5219a3eda83e9`
Owner: sole integrator. Scope: close vegetation shaders/LOD, LandscapeCover helpers, focused/native probes, and the task-owned Mac capture harness. Shared file: `scripts/local_terrain.gd`. No simulation, era-skin mockup or subject-art worktree changes.

## Behavior and cause

The original native baseline showed a square of near-black canopy pinpricks at the actual 10,000 ft distance on a wide viewport. The same altitude on a standard viewport hid that detail entirely. Fading the crown texture before a fixed alpha-scissor threshold retained opaque remnants; a minimum opacity and unfaded scrub/forest floor exposed the square sampling boundary.

Crowns, scrub and forest floor now share a continuous opacity derived from the larger physical view dimension. The four actual distance presets use the existing biome-driven terrain cover; closer manual views retain individual plants. A radial 130–235 m feather hides the rectangular sampling edge without changing candidate cells, geometry budgets, transforms or resource amounts. The opaque alpha-scissor remnants and minimum-opacity floor are removed. Unchanged zoom does not resubmit material uniforms.

Drawing and deferred construction share the same aspect-aware strength. Initial hidden views do not build plants. Settled visible close views construct them once; subsequent zoom retains identities. Upkeep retains the physical-clearance cache. Actual clearance changes wait while foliage is hidden and apply upon visible return. Camera gestures still defer construction until input settles.

## Source validation

READY: all **41 headless cases** pass, zero errors/failures/skips/orphans, across canopy transition, landscape cover, seasonal landscape, camera distances, surface precision, terrain LOD and landscape resource visuals. Final log: ignored `artifacts/canopy-transition/native-verified-source-tests.log`. The prior six canopy cases also passed alone; the earlier combined 27-case run passed before native verification.

The six canopy cases cover four actual altitudes at four viewport aspects, uniform gradual fade for all three vegetation kinds, identity retention, boundary updates, deferred first construction, camera-motion suppression, physical-clearance versus upkeep caching, and portrait visibility beyond the old ground cutoff. Population and deposit records remain unchanged.

`tests/canopy_compile_check.tscn` verifies both updated native scripts with actual project autoloads. Earlier direct `--check-only --script` attempts lacked GameState and emitted errors despite exit 0; they are not successful validation. Initial fixture issues with the marker type and input cooldown were corrected before the final source run.

## Native verification

All three native Compatibility probes pass and exit. Their complete logs and injection preflight are retained in ignored `artifacts/macos-background-capture/`. No player or editor process was present at the start, none was stopped, and no player game was launched.

- `canopy_transition_probe`: twelve actual captures at real seeded temperate woodland `(12000,-3800)`, tropical woodland `(400,-1000)` and drylands `(6600,-3280)`, seed 873421. Both 1280×720 and 960×720 cameras are measured at 3.048 km / 10,000 ft. The closer 0.72/0.30 km camera-span diagnostics are explicitly separate. Paused pixels, physical first construction, subsequent identities, all four preset returns and fog hiding pass. The finite rectangle and opaque pinpricks are absent from the actual-altitude after captures. Near-black pixels (all RGB channels below 40) decrease from 334 to 0 at the temperate site and 196 to 0 at the tropical site; drylands remain 0. At the close diagnostics, the same 3,245/1,600/27 plant representatives remain respectively. These are visual representatives, not resource counts.
- `seasonal_landscape_probe`: all six real climate sites pass, including reversed hemisphere seasons, fixed drylands/tropical/barren appearance, paused pixel equality and fog concealment. The close woodland diagnostic explicitly constructs deferred plants, requires a nonempty result and retains identities through both seasons. Actual-altitude foliage is intentionally deferred; its zero initial representative count is not confused with missing terrain cover. Seasonal ground and close crown pairs were inspected.
- `terrain_lod_probe`: all four distances refine to complete coverage; fallback, cancellation, unknown mountains/plains/ocean equality and physical planet-edge clipping pass. Captures at close, region, continent and the planet boundary were inspected. At 1080×720, isolated frame p95 was 29.9–30.8 ms; full refinement took 9.6–17.5 seconds behind existing previews. Construction slices reached 7.2 ms and uploads 17.4 ms in this run. These are test-scene measurements, not a populated-campaign FPS claim or a before/after performance benchmark.

Representative before/after canopy, close detail, dryland, seasonal and four-distance images were inspected from the actual Godot output. Rendering costs remain bounded by the existing geometry/streaming budgets. Existing tree artwork is retained; this delivery does not claim complete landscape beauty, new species, snow, or a full-world canopy clipmap.

## Repeatable Mac captures

`tools/macos_capture/run.py` compiles the durable task-owned guard and canary into ignored artifacts and copies only the installed Godot executable into a private `GodotCanopyProbe`. It re-signs that copy ad hoc; the installed hardened Godot.app and normal releases remain untouched. The preflight checks that the canary cannot become visible, key, main or active, that activation policy stays prohibited, and that the same guard loads into the actual private Godot executable. Only then may an allowlisted native probe run with Dummy audio, private userdata and suppressed AppKit window/activation calls. A file lock prevents concurrent replacement of the owned executable; completed probe PASS markers and error logs are checked.

Run from the explicit task worktree with the owned `TomorrowCanopyTransitionTests` override: `python3 tools/macos_capture/run.py canopy_transition_probe`, then `seasonal_landscape_probe` and `terrain_lod_probe`. The override is removed before delivery; recreate only its three reviewed application settings for another isolated run. Tools, tests, captures and the private executable are excluded by the existing release export preset.

## Integration and limits

Original held `88e8054` rebased conflict-free as `d0fbc9dbe820dada755e290531650bdca2bd7bfd`; semantic guard/cache reconciliation is `e56f5356fde135b8bca6c67e4fe0f87453d1323f`, followed by the project compile check at `d899d0319b4c941c264d8d4505582414c8c2cb53`. The final native-evidence/harness commit completes the worktree delivery. Integrate into main only after reviewing the combined diff, run canonical focused checks, then package with the normal Mac launcher in build-only mode. Do not silently launch a player session.

Save compatibility and physical geography are unchanged. No population, resource, travel, research, AI-parity or calendar rules change. Do not claim that the earlier mature-campaign frame stalls are solved. The landscape remains an ongoing iteration. The ancient-first evolving UI skin remains a separate delivered mockup pending user feedback; the subject-specific art worktree remains unfinished.
