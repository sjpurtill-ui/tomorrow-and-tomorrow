# Continuous map graphics iteration

User authorization: continually improve all map graphics toward Google Earth style expansion, exploration visibility, continuous zoom, believable terrain at roughly 10,000 feet above ground, and stronger units/war graphics. Hourly heartbeat `iterate-earthlike-map-graphics` is ACTIVE on this task. Continue concrete visual passes; do not treat this first pass as completion.

## Workspace and operating rules
Actual running game project: `C:/Users/sjpur/TomorrowandTomorrow` (different from task cwd under OneDrive). Preserve extensive existing uncommitted gameplay work. Never kill or restart the user's live game or overwrite their save slots. Isolated render probes can exit themselves. Use UTF-8 explicitly when editing with Python on Windows. No subagent authorization. No commits requested for this task.

## Reference study
- https://earth.google.com/web
- https://mapsplatform.google.com/maps-products/earth/capabilities/
- Google Earth reference image (Tyrol): https://miro.medium.com/v2/resize%3Afit%3A4184/1%2A3uDMtJ2MTDcL88WNi88_rQ.png
- Google Earth rural hills: https://telluridecoffeeroasters.net/wp-content/uploads/2024/10/Ethiopia_Guji_Shakiso_Natural_2_snapshot_01-15-2025_09_55_41.jpg
References guide terrain shape, realistic scale, land-cover boundaries, aerial texture hierarchy, shadows, and clarity. Google imagery has not been imported as game assets. Current rendering remains procedural and is not yet photorealistic.

## First pass, 2026-09-04
- Seamless world now uses a 35-degree perspective camera. `camera.size` remains the focus-plane footprint used by existing LOD/navigation. Camera distance derives from that footprint.
- F7 and the toolbar 10,000 FT button descend to an actual terrain-relative altitude, solved against terrain beneath the camera. Scale tooltip reports feet above ground.
- Adaptive near plane fixed severe continental land/ocean depth striping found during real render checks. Close rendering retains fine depth precision.
- Terrain shader now uses local forest stands/clearings and crown-scale variation rather than uniform forest coverage. Ordinary resource-emphasized rivers are less neon.
- Military counters no longer have a 60-metre minimum scale. Perspective labels use sharper font atlases at restrained screen sizes; duplicate strength labels hide when full labels already show the same count. Marker glow reduced.
- Other fixed-size map labels are normalized for the perspective camera.

## Repeatable visual evidence
`tools/map_graphics_audit.gd/.tscn` loads the real terrain, fixes seed 864209, pauses simulation, waits actual rendered frames, verifies ground picking and zoom anchoring, and captures. Optional --aerial asserts altitude within one foot. --war adds one aggregate player formation. --revealed replaces only probe shader masks so continental geography can be inspected without changing gameplay fog. --show-hud retains real toolbar.

Example command:
`Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --resolution 1600x1000 tools/map_graphics_audit.tscn -- --aerial --war --show-hud --output=res://map_war_aerial_iteration1.png`

Images in project root: map_aerial_baseline.png, map_aerial_iteration1.png, map_war_aerial_iteration1.png, map_continental_revealed.png. First `map_aerial_before.png` is an INVALID blank capture from old force_draw harness; do not use it as visual evidence. Existing capture-isolation harness can save before 3D resources render. Use the new audit's real frame waits.

Validation: 36 map onboarding / warfare presentation tests passed after final label and counter adjustments (report_666, map-graphics-tests-final.log). Aerial, fogged continental, fully revealed continental and military captures were inspected. Baseline renderer shutdown emits known RID/ObjectDB cleanup warnings; no shader errors in captures. Latest near-plane correction removed shoreline striping. The fully revealed continental capture was re-inspected. Final aerial military capture includes the real HUD and 10,000 FT button; name/count no longer cover the role glyph. Final render also verifies altitude and pointer-anchored zoom.

## Next priorities
1. Rivers are still geometric ribbons with sharp, long straight segments. Build a bounded camera-local water/shore mesh sampled from the authoritative river course; remove floating/depth-disabled water at close range. Match hydrology used by settlement/scout access. Do not create visual rivers detached from gameplay geography.
2. Actual detailed vegetation/canopy silhouette, varied rock/soil materials, relief, atmospheric distance and exposure; compare same-seed same-view before/after at 10,000 feet and multiple biomes, mountains and coastlines. Current improved mottled surface is still too uniform and soft.
3. Civilization growth: visible geographic settlement expansion, agricultural parcels/roads tied to simulation and realistic scale. Inspect late-stage cities and secondary cities. Preserve local-city ownership.
4. More natural military field presence (bounded camp/formation detail and terrain-following routes), battle/contact effects, readable selected/unselected/stale enemy intelligence. Do not add per-soldier simulation or reveal unknown contacts.
5. Exploration-mask resolution and smooth visibility boundaries at settlement/region/continent scales. Preserve authoritative discovery limits.
6. Frame-time measurements while zooming/panning across terrain LOD boundaries, not just screenshot load times. Rework synchronous high-resolution patch rebuilds if they hitch.

Check failures rather than claiming "great" from unit tests. Every follow-up should inspect real images and record remaining shortcomings.

## Navigation pass, 2026-09-04
User requested faster, less choppy seamless zoom and rotation/north-up. Implemented cumulative 1.4x wheel targets (1.8x with Shift) with exponential interpolation in log scale and pointer anchoring. Q/E continuously rotate; Shift-middle drag rotates/tilts; N and the clickable NORTH compass smoothly reset yaw to PI/2 (negative world Z projects upward). F7 cancels pending wheel zoom before its altitude solve. Text entry does not trigger continuous navigation.

New `scripts/terrain_patch_builder.gd` builds vertices/colors/normals/indices in ~2.5ms main-thread slices, avoiding thread-unsafe world reads. Regional spans use stable 1.5x buckets. The previous patch remains visible during generation; completed arrays commit once and reuse the terrain material. Close vegetation/settlement detail rebuilds and resource overlay buckets wait for camera motion to settle. Additional heavy detail rebuild paths still warrant profiling in dense late-game cities.

Validation: `test_terrain_patch_builder.gd` plus map onboarding: 18 tests passed, report_667. New `tests/camera_navigation_probe.gd/.tscn` verifies accumulation, no input-frame jump, monotonic/no-overshoot smoothing, geographic pointer anchoring, four different north resets, faster Shift mode and visible-patch retention. Actual rendered profile (`--profile`, 1280x720, paused founding scene): median 19.999ms, p95 20.177ms, max 20.320ms across 120 zooming frames. Last generation slice max 2.854ms, mesh commit 11.828ms. This is a local scene measurement, not a guarantee for every save.

Inspected `map_navigation_iteration2.png`: full HUD and military marker at 10,000 feet; detail retained without holes/seams. Audit now explicitly advances/waits for incremental terrain jobs before screenshot, since it pauses normal scene processing. Existing engine shutdown RID/ObjectDB warnings persist. User's live game is undisturbed and needs save/relaunch to load this code.


## River and land-resource passes, 2026-09-04
User redirected the ongoing graphics work toward resources: forest should be a real timber-bearing area, and map resources should not be icons. Blender military asset work was explicitly moved to another session; do not delegate or implement it here.

River changes: main-river rendering samples the authoritative `_world_river_x` every 250 m over its actual 1,520 km reach (6,080 segments), instead of sampling the planet and obtaining multi-km chords. Width variation is anchored in world coordinates. Water has subdued, nonperiodic variation and feathered shallows/banks. River meshes do not cast shadows or write depth. Camera-local depth-tested water is STILL outstanding. Regional render at span 60 shows dark triangular artifacts near the channel; shadow and depth-write experiments did not resolve them. Do not claim the regional defect fixed. Coarse globe shadow experiment was reverted.

Resource changes: removed all billboard resource icons, count badges, labels and ring batches from the live resource overlay. Surface resources read through terrain shading; recognized nonsurface occurrences use a bounded maximum of 16 irregular terrain-draped indication patches. These are approximate indications, not surveyed deposit boundaries; unknown occurrences remain hidden. Resource-mode toolbar tooltip explains land-cover colors. Clicking charted ground now opens Ground Inspection (the previous Lens was only constructed in capture mode, so ordinary clicks silently had no report). Reports describe actual tree cover, exposed stone, soil and forage independently of deposit records; unknown ground remains gated. The extra duplicate lens selection ring is removed.

Woodland authority: CPU biome density now carries stand variation; terrain vertex alpha carries that same density to the forest shader. Grass greenness no longer independently fabricates forest texture. Close canopy probability also respects this woodland field. This changes apparent vegetation where the previous shader exaggerated it. Timber gains one terrain-sampled 3x3 km local catchment per settlement, independent of random deposit placement. Nearby existing timber records are adopted while preserving remaining stock, source inventory and shipments. Cutting and carrying retain existing labor/tool/logistics constraints. Local standing growth regrows slowly at source, bounded by original capacity; sampling itself never refills or duplicates a source. City resource scoping remains intact.

Validation: 53 resource, city, onboarding and warfare-presentation tests passed (report_673, `land-resource-tests-final.log`). New `tests/test_landscape_resources.gd` covers availability without a random occurrence, no duplication/refill, legacy inventory/shipments, treeless ground, no workers, and bounded idle regrowth. Added secondary-city catchment isolation test. Actual rendered audit verifies no Sprite3D resource icons, matching CPU/vertex woodland density, visible ground report, correct altitude and pointer-anchored picking. Inspected `map_land_resources_iteration4.png` (earlier grassland capture) and final `map_woodland_resources_iteration4.png` (riverbank, latest UI). `tools/map_graphics_audit.gd` now accepts --river, --river-z, --river-bank and --resources. Probe-only reveal mask is applied after terrain streaming; simulated travel for resource inspection is confined to the probe.

Final capture command:
`Godot_v4.7.2-stable_win64_console.exe --path . --audio-driver Dummy --resolution 1600x1000 tools/map_graphics_audit.tscn -- --river --river-bank=1 --aerial --resources --show-hud --revealed --output=res://map_woodland_resources_iteration4.png`

Remaining resource work: forest cutting/depletion does not yet change the rendered canopy; surface stone/fiber still use legacy occurrence extraction rather than area catchments; soil/game simulation should be audited for the same map agreement. Nonsurface indications need material-specific physical outcrops and works instead of generic earth coloration. Larger/overlapping city catchments need shared geographic depletion accounting before expansion beyond the local 3x3 km footprint. Do not claim the whole resource economy redesigned. Preserve saves and do not restart the user's game.


## Visible harvest and outcrop pass, 2026-09-04
Added `scripts/landscape_resource_visuals.gd`: saved woodland remaining/initial stock drives geographically bounded canopy retention. The 32 nearest depleted catchments from primary and secondary-city ledgers are sent to terrain/vegetation shaders; updates occur on day or camera-region changes. Ground inspection uses the matching CPU retention calculation. Terrain, close atlas crowns, scattered landscape trees and legacy forest-patch trees now share the cutting uniforms. Whole crowns disappear deterministically rather than being clipped into partial leaves; regrowth restores them in the same stable order. Materials are tracked with weak references. Catchment generation still reads natural biome capacity, avoiding recursive reductions in capacity from harvesting.

Known resource indications now have material-specific surfaces: pale limestone/sand, iron-stained red-brown ground, subdued copper-stained rock, dark coal/graphite, earth clay, and soft peat. Hard-rock indications add up to 14 terrain-following faceted exposures per selected occurrence, with procedural grain/weathering. Clay, peat, plants and deep aquifers do not fabricate boulders. Stone participates in these physical exposures. Existing 16-occurrence view cap and recognized/revealed gating remain; no billboard icons return.

Validation: 58 tests passed (report_675, `depletion-tests-final.log`), including five new tests for local cutting, regrowth, multiple city footprints, nonwoodland/full-growth exclusion, nearest-area cap and distinct surface styles. Render probes use synthetic isolated stock fixtures via --cut-retained; no player saves are read or altered. Inspected matched `woodland_uncut_iteration5.png` / `woodland_cut_iteration5.png` at 10,000 feet: 23% base tree cover becomes 2% at 10% standing timber, with exterior woodland retained. Inspected final `limestone_outcrop_iteration5.png` at 180 m camera footprint: physical rock faces, grain and no icons. Final render `limestone-outcrop-verified.log` has no script/shader errors; familiar engine cleanup leaks remain.

Commands: add `--cut-retained=1` or `--cut-retained=0.1` to the riverbank aerial resource probe for matched harvest evidence. `--span=0.18 --outcrop --rock=Limestone --resources --show-hud --revealed --cut-retained=0.1` checks close rock/canopy shaders (omit --aerial).

Remaining: cutting footprints still use the aggregate square catchment with feathered edges, not explicit trails/stumps or logging compartments. Outcrops remain low-poly and need better geological shape diversity; do not describe them as photorealistic. The visual cap is 32 nearest depleted areas, not unlimited global depletion rendering. Overlapping catchment stock ownership, continuous stone/fiber extraction and regional river artifacts remain unresolved priorities from the previous pass. Live game was not interrupted.
