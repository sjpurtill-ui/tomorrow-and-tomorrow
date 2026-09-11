# Woodland scale and readable aerial canopy

Worktree: `/Users/seanpurtill/Documents/Codex/tt-woodland-scale`  
Branch: `codex/woodland-scale`  
Base: `2f695346b9c525a2c3b5bba1cbc9ad97fb24a210`  
Owner: sole integrator. Shared file: `scripts/local_terrain.gd` terrain shader only. No other worker changes or art branches are included.

The user redirected this thread to landscape. The unfinished discovery-art branch is stopped and remains unintegrated; it is not part of this delivery.

Integrated source `0c33647568e8ba3a0868ca274460384d76618b40` by conflict-free fast-forward from the base above. All 41 canonical cases and the canonical ordinary import/normal-entry headless boot pass. Both owned overrides are removed before packaging release 2026.09.11.2. No player/editor launched or stopped.

## Visible change

At the actual 10,000-foot view, dense woodland looked like a mottled green surface. Its material blended a forest tile stretched across about 4.35 km with another squeezed into about 20 m. Since that tile contains dozens of crowns, neither scale represented plausible trees at this altitude.

The crown layer now repeats every 500 m (a secondary rotated sample every approximately 633 m), giving its illustrated crowns roughly 10–20 m dimensions. One physical crown scale remains fixed during zoom and pan. Existing mipmaps plus a 3–14 m pixel-footprint fade hand individual detail back to the broad forest surface before it becomes unresolved noise. More of the source crown-top/shadow contrast survives the biome blend. The regional and continental cover layers retain their prior appearance.

This uses the existing landscape texture and the same four forest texture samples. It adds no textures, geometry, plant records, simulation work, per-frame allocations or enlarged cache budgets. Physical woodland density, slope exclusion, harvesting/regrowth, climate, season and fog still determine where canopy appears. No changes to water, heights, resource amounts, population, travel, AI rules or save schema.

## Verification

All **41 focused worktree cases pass**, zero errors, failures, flaky cases, skipped cases or orphan nodes. Suites: canopy transition, landscape cover, seasonal landscape, surface precision, terrain LOD, landscape resource visuals, camera distance levels. Final combined log: `artifacts/woodland-scale/final-tests.log`. An earlier 38-case run accidentally omitted the camera suite through an incorrect path; the final combined run includes all seven suites. Ordinary editor import and normal-entry headless boot both exit cleanly with isolated userdata (`final-import.log`, `boot.log`).

The guarded native `woodland_scale_probe` passes before/after on real seed 873421: temperate woodland `(12000,-3800)`, tropical woodland `(400,-1000)` and treeless drylands `(6600,-3280)`. The first view measures exactly 3.048 km above focus. Temperate views cover all four actual distance presets; winter, fully harvested and unknown-ground comparisons are included. The texture remains fixed across a 64 km shader-coordinate reanchor, and repeated paused frames match exactly. Physical biome and resource dictionaries do not change.

The final treeless dryland, fully cleared woodland, unknown-terrain, regional and continental land-material images are byte-identical to their baselines. Close woodland gains visible crown detail. The initial scale-only candidate was still too flat and is retained as `temperate-first-scale-pass.png`; the final contrast revision was recaptured and inspected. Source texture, baseline and final temperate/tropical images, winter and wider distances were visually reviewed.

This new probe deliberately isolates the land material without water. Its continental image is a material comparison, not a complete coastal scene. The existing `terrain_lod_probe` supplies complete land/water and streaming verification separately. Native probes run only through the verified private `tools/macos_capture/run.py` guard and canary, Dummy audio, explicit worktree path and private TomorrowCanopyTransitionTests userdata. The runner now allowlists the new owned probe; installed Godot and normal release signing are untouched.

The complete `terrain_lod_probe` also passes and exits: all four distances refine to full visible coverage, stale work cancels, fallback stays visible, fog conceals mountains/plains/ocean identically, and terrain clips to the planet boundary. Complete close and continental captures were inspected. This run observed 27.3–30.8 ms isolated frame p95 and 10.0–18.9 s final refinement behind previews; one construction/upload step reached about 73.5 ms under concurrent headless-test load. These are observations, not a comparative FPS improvement or a claim that frame stalls are solved.

## Compatibility and limits

No save changes. Existing landscapes acquire the revised surface on loading this build. Individual trees are visual representatives; the texture does not create a new species inventory or new timber. Existing canopy imagery remains shared across climates, modulated by the existing seasonal and biome rules. This improves aerial forest readability, not complete landscape realism or mature-campaign FPS. No frame-rate improvement is claimed. Further ground, coast and regional landscape refinement remains authorized.

Keep the art task stopped. Do not launch or restart a player/editor for this integration. Remove the owned override before delivery and package the reviewed canonical result through the normal Mac launcher in build-only mode.
