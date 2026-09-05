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


## Geological shape pass, 2026-09-05 UTC
Replaced single-apex rock lumps with three-ring irregular bodies and flat fractured tops. Limestone and coal/graphite use a common seeded bedding direction: eight elongated low ledges plus six smaller fragments. Other hard-rock surfaces retain irregular boulder arrangements. Exposures follow actual ground height and retain existing material grain. Corrected top-face winding after the first real render exposed hollow-looking slab lighting. Final shape is capped at 2,520 vertices per occurrence, with the existing 16-occurrence view cap. No changes to resource quantities, discovery, city ownership or saves.

Inspected `limestone_ledges_iteration6.png` at 180 m camera footprint against prior `limestone_outcrop_iteration5.png`: flatter, fractured layered exposures replace isolated pointed lumps. Inspected `outcrop_aerial_iteration6.png` at 10,000 feet: rock geometry remains appropriately small, and the terrain indication carries visibility without icons. Final logs `limestone-ledges-final.log` and `outcrop-aerial.log` have no script/shader errors; existing shutdown cleanup leaks persist. 21 resource-visual and map onboarding tests passed (report_676, `outcrop-shape-tests.log`). Diff whitespace check passed.

Still stylized: ledge distribution is schematic and needs more weathering/erosion variation; broad terrain texture remains soft. Larger priorities remain continuous stone/fiber availability, natural harvesting compartments and regional river depth artifacts. Live game was not interrupted.


## Surface supplies and ocean precision pass, 2026-09-05 UTC
Stone and Fiber Plants now use the same nine-sample, 3x3 km settlement catchment mechanism as Timber. Natural biome stone/forage/woodland fields supply density and a weighted source position. Sparse stone is admitted at density 0.03; vegetation requires 0.08. Primary and secondary cities sample their own terrain and retain separate ledgers. Existing nearby sources are adopted without refilling stock or losing inventories/shipments; repeated sampling is idempotent. Fiber regrows at 0.001 original capacity per day, timber retains 0.00003, stone never regrows. Exhausted sources no longer consume extraction worker shares, but retain their stored goods and shipments. Ground Inspection reports plant fiber from the matching field. Catchment centroids are excluded from point exposure overlays, avoiding fabricated single outcrops for broad surface resources.

Resolved the black triangular regional river artifacts in the reproduced span-60 view. Diagnostic sequence: hiding river overlays did not help; disabling terrain shadows did not help; two-sided terrain did not help (reverted); flat unshaded terrain still showed the triangles. Hiding the ocean plane removed them. Subdividing the planet-wide ocean PlaneMesh into 256x256 sections removes the reproduced artifacts while preserving water. This bounds the enormous triangles implicated in GL depth precision; it adds a static 131,072 triangles. No change to hydrology, sea level, fog or resource positions. This is visual evidence for the tested cameras, not an all-platform precision guarantee.

Validation: 44 tests passed, report_678, surface-supply-tests-final.log. Includes sparse stone, source preservation/no duplication, depleted worker redistribution, stone nonrenewal, fiber renewal and secondary-city isolation. Inspected surface_supplies_final_iteration7.png at 10,000 feet with the real Ground Inspection UI; audit confirms both stone and fiber sources without point occurrences. Inspected river_ocean_sections_iteration7.png against river_flat_diagnostic.png and river_no_ocean_diagnostic.png. No script/shader errors in final render logs; known engine shutdown cleanup leaks remain. Selected-file whitespace check passed. Probe flags --surface-supplies, --hide-rivers, --no-terrain-shadows, --flat-terrain and --hide-ocean are isolated diagnostics, not live controls.

Remaining: regional river strokes/tributary joins still need natural banks and camera-local depth handling; broad terrain is still stylized. Surface stock density/yields are gameplay calibration, not geological measurements. Overlapping city catchments still need shared geographic depletion accounting before expanding their area. Fiber/stone depletion does not yet alter vegetation/rock geometry as woodland depletion does. Natural harvest compartments and trails remain next visual work. No live game or saves were interrupted.


## River margin pass, 2026-09-05 01:47 UTC heartbeat
Kept the existing authoritative river course and width envelope. Ribbon vertices now carry signed local curvature in UV2. River shading uses it to bias shallow sediment toward inner bends, with world-anchored broad and fine bank variation. Widened the transition from dark channel to muted shallow water and added an uneven edge instead of the previous near-straight cut. Bank detail fades with projected pixel footprint to avoid noisy regional strokes. No extra triangles, textures, save fields or gameplay/hydrology changes.

Reference: https://science.nasa.gov/earth/earth-observatory/meandering-in-the-amazon-84833/ supplements the original Google Earth reference set. NASA's Landsat comparison describes pale, vegetation-free sediment bars along inside bends. Used as a morphology/color principle only; no imagery imported. The current shader is a restrained approximation, not a sediment transport simulation.

Inspected riverbanks_verified_iteration8.png at a 1 km footprint: visibly irregular margins and broader shallow transitions compared with initial riverbanks_close_iteration8.png. Inspected final riverbanks_aerial_final_iteration8.png at 10,000 feet: subtle uneven edges remain legible. Inspected riverbanks_regional_final_iteration8.png at span 60: the earlier ocean black triangles remain absent; detail stays subdued. Pale bar effects are subtle at these gentle bends, not a demonstrated full point-bar landform. One earlier probe exited before screenshot (riverbanks-close-final.log); no result claimed for that attempt. Final probes launched via Start-Process with WindowStyle Hidden and completed with MAP_AUDIT output. No script/shader errors; known engine shutdown RID/ObjectDB leaks remain.

18 terrain-builder and map onboarding tests passed, report_679, riverbank-tests.log. Whitespace check passed. Aerial probes still assert actual altitude and pointer-anchored terrain picking; river sampling audit preserves authoritative centerline alignment. User game and saves were not changed.

Next: camera-local river depth and tributary join geometry; the regional tributary still reads as a thin floating stroke in places. Broad terrain softness and schematic forest/cutting footprints remain. No claim of photorealism or completion of the overall map effort.


## Isolated river worker pass, 2026-09-05 UTC
Workflow changed per user/integrator: canonical main is read-only for this worker. Worktree C:/Users/sjpur/TomorrowandTomorrow-river-depth, branch codex/river-depth, base ffefea66752e12ccd6e59ae4ecf85c829ef901b9. Integrator was notified of ownership before shared-file edits. The base already includes the prior draped tributary geometry and river depth work (terrain height texture, exact texelFetch samples and enabled depth testing); those are not new changes in this worker commit.

New behavior: tributaries begin as narrow source channels, grow smoothly to their existing width over five horizontal kilometres, and fade at the source cap rather than ending in a blunt cut. Banks and water use the same distance-based taper. Main-river width, surveyed centerlines, water-access calculations and downstream confluence widths are preserved. UV2.x remains signed curvature; UV2.y now carries source opacity. No new geometry, assets, save fields, simulation authorities or per-frame CPU work.

New audit: --tributary-index and --tributary-distance focus an isolated probe on a chosen reach. --verify-river-surface checks rendered pixels around three projected main-channel samples after accounting for the logical 1920x1080 viewport versus capture pixels. This catches missing GPU water independently of CPU centerline checks. It is deliberately a fixed, revealed clear-water fixture, not a universal image classifier.

Validation: 21 geometry, terrain-builder and map onboarding tests pass, reports/report_2 and river-worker-tests-final.log. New taper test checks horizontal distance, monotonic width growth, downstream width and invariance under resampling. Final aerial probe verifies all three channel samples and 10,000-foot altitude/pointer anchoring; artifacts/river-final.png was visually inspected. Negative control with --hide-rivers reports 0/3 and terminates with the intended failure. Inspected artifacts/tributary-headwater-final.png at one-kilometre footprint: source narrows and fades into the ground. Final render logs have no script or shader errors; existing shutdown RID/ObjectDB warnings persist. Captures/logs remain in the worktree artifacts directory, outside source commits. Whitespace check passed.

Save compatibility: rendering-only; no migration and no save writes. Player build was not launched or edited. Shared-file integration: scripts/local_terrain.gd changes are limited to _add_river_ribbon, the two tributary call sites in _build_river_network, and river shader source opacity. Other changed files are scripts/river_geometry.gd, tests/test_river_geometry.gd, tools/map_graphics_audit.gd and this record. Resolve any concurrent river hunks deliberately; do not replace the full terrain file.

Limitations/next: fixed tributary centerlines still have straight/jagged reaches and are not physically derived downhill drainage. Taper improves their source appearance only; there are no new spring landforms. The depth pixel check covers the selected camera/seed, not every renderer or geography. Larger-scale terrain softness, natural harvesting compartments and better confluence morphology remain. Integration and the player launch belong to the designated integrator.


## Rounded woodland boundaries, 2026-09-05 UTC
Worker path C:/Users/sjpur/tt-woodland-boundaries, branch codex/woodland-boundaries, base ebdc040b997540e11455ff92a27e0ba144ba88f4 (river worker integrated). Integrator notified of scope: scripts/landscape_resource_visuals.gd, its tests, and this record only. No canonical checkout edits or player launch.

The shared CPU/GPU woodland retention function now rounds the harvest footprint with a fourth-power distance and adds broad, world-anchored edge variation. Bounding rejection preserves all forest outside the original saved catchment. The center retains the same saved remaining/initial ratio, and regrowth continues to restore cover monotonically. Corners and edges retain more canopy than the prior square mask. All consumers of CUTTING_SHADER receive the same outline; ground inspection follows the matching CPU calculation. No new textures, meshes, save fields, extraction rules or quantities. Existing nearest-32-area budget remains; areas outside their saved bounds are skipped before the extra arithmetic.

Visual evidence: inspected matched artifacts/woodland-before.png and artifacts/woodland-after.png at five-kilometre footprint with the same seed, camera and 10% retained stock. The prominent lower/right square corner becomes a rounded, varied woodland margin. Inspected artifacts/woodland-aerial.png with actual UI at 10,000 feet: center remains about 2% tree cover from 23% base woodland. Existing Google Earth reference set guides continuous land-cover boundaries; this pass imports no imagery.

Validation: 30 resource-visual, landscape-resource and city-resource tests pass (reports/report_1, woodland-tests.log). Added checks for rounded corner retention, unchanged exterior, continuous transitions and monotonic regrowth across 1,600 sampled points. Render audit confirms center depletion and actual aerial altitude; no script/shader errors in final logs. Known engine shutdown cleanup warnings persist. Captures/logs remain outside source commits in artifacts.

Save compatibility: unchanged schema and stocks; visual cover is more retained near corners of existing depleted areas. This is an approximate catchment visualization, not area-conserving forestry parcels or a new geographic stock model. No stumps, trails, logging compartments or photorealistic claims. Next priorities remain local harvest detail and better geographic ownership of overlapping catchments. Shared integration conflict risk is the visual helper and this append-only record; no local_terrain.gd changes in this commit.


## Outcrop surface filtering, 2026-09-05 UTC
Worker C:/Users/sjpur/tt-rock-materials, codex/rock-materials, base 8a629a322f3b958ffcc90ce0470aaf1abeb75a2e. Integrator notified before edits. Scope is new scripts/shaders/resource_outcrop.gdshader (and UID), only the material setup at the end of _add_resource_outcrops in scripts/local_terrain.gd, and this record.

Replaced the inline rock shader with one shared shader resource. World-normal-weighted projections put weathering/grain on vertical faces as well as tops. Three detail scales fade to their average as projected pixel footprint grows. Layered stone receives restrained bedding on exposed side faces; ordinary Stone and other unlayered styles no longer receive generic horizontal bands. The first render showed etched lines across sloping tops; restricted bedding by face normal before keeping the change. No mesh, placement, quantity, discovery or save changes, and no new image textures. Existing caps (14 rocks per occurrence, 16 selected occurrences) remain.

Validation: 23 resource-visual and map onboarding tests passed (reports/report_1, rock-tests.log); final headless editor import passed without script errors. Inspected matched artifacts/rock-before.png and rock-final.png at 180 m footprint, rock-aerial.png at 10,000 feet, and rock-stone.png for the non-layered path. All final captures finish with MAP_AUDIT and no script/shader errors; known engine cleanup leaks persist. An earlier Iron Ore launch had an unquoted spaced argument and produced an invalid occurrence assertion; that isolated probe was closed and the non-layered path was checked with Stone instead. Captures and logs stay outside source commits.

The improvement is modest material detail and spatial filtering, not new geological geometry or proven elimination of all motion aliasing. Shapes remain faceted and arrangement schematic; animation/temporal shimmer was not benchmarked. Original Google Earth reference set continues to guide scale; no new external imagery was used. Save schema/stocks unchanged. Shared-file conflict risk is limited to the outcrop material setup and append-only graphics record; do not replace the full terrain script. Integration and player launch remain the integrator's responsibility.


## Resource ground staining, 2026-09-05 UTC
Worker C:/Users/sjpur/tt-resource-ground, codex/resource-ground, base d7147626642cd004c885a2cb3ab3f69c7ce92f41. Main advanced during worktree creation; the actual base was reported before editing. Integrator notified of scope. Changed only _resource_ground_indication material setup, a new scripts/shaders/resource_ground.gdshader plus UID, and this record.

Recognized occurrence ground indications now use uneven, filtered exposure patches instead of uniform translucent soil tint. Layered styles align elongated patches with the same seeded strike used by their physical outcrops; non-layered styles use isotropic mottling. The first capture was too conspicuous, so opacity was reduced to 65% of the masked input and directional stretch reduced. Vertex alpha still owns occurrence extent and discovery gating; the shader only attenuates it. Existing mesh, colors, recognized/surveyed radius, 16-occurrence cap, outcrop geometry and resource quantities are unchanged. No icons or new texture assets.

Validation: 23 resource-visual and map onboarding tests passed (ground-tests.log, reports/report_1). Final editor import clean. Inspected matched artifacts/ground-before.png and ground-final.png at 10,000 feet: the round pale haze becomes subdued, irregular exposed-ground patches. Inspected artifacts/ground-stone.png at 500 m footprint for the non-layered path. Final captures finish with MAP_AUDIT, no script/shader errors; existing engine shutdown cleanup warnings persist. Whitespace check passed. Artifacts/logs and unrelated auto-generated import metadata are excluded from the commit.

Save compatibility: no save or simulation changes. This remains an approximate indication of a known occurrence, not a surveyed vein, real erosion model or geographic extraction footprint. Reduced opacity deliberately makes the ground indication less prominent; physical rocks and Ground Inspection still provide detail. No claim of photorealism or measured motion-aliasing elimination. Original Google Earth reference set remains the scale/land-cover guide; no external imagery imported. Shared-file merge risk is limited to the named material setup; do not replace the full terrain file. Integration and player launch belong to the integrator.


## 2026-09-05: Close woodland harvest representatives

Worker: `C:/Users/sjpur/tt-harvest-detail`, branch `codex/harvest-detail`, base `eba7ec53927a8a98827b01cc6c88136624a94486`.

Added a bounded instanced mesh of half-metre cut stumps on revealed, depleted woodland. Existing city harvest footprints and biome density determine placement; seeded world cells keep surviving representatives fixed during panning and regrowth. At most 121 candidates are considered per refresh (16-metre camera cell or simulation day), with one MultiMesh and a distance/zoom fade. Detail hides above a 350-metre camera span. Bark sides and lighter cut tops replace any need for a timber icon at this close scale.

Validation: headless editor import completed without parse errors. Both `test_woodland_harvest_detail.gd` and `test_landscape_resource_visuals.gd` passed: 11 tests, no errors/failures/orphans. Coverage includes hidden/barren/uncut ground, bounded counts, stable overlapping positions, regrowth, and aerial hide/close rebuild. Isolated GPU audit `--river --river-bank=1 --span=0.06 --cut-retained=0.1 --harvest-detail --revealed` produced 26 representatives and a reviewed `artifacts/harvest-close.png`; no shader errors. Existing shutdown RID/texture leak messages remain. Probe is not the player game.

Limitations: sparse visual representatives, not one object per harvested tree or a forestry worksite simulation. Sub-metre objects are intentionally subtle and vanish at aerial scale. Ground placement follows the existing close-surface sampler and lift; steep slopes/mesh interpolation can still partially bury small details. Saves and extraction quantities are unchanged; no migration. Shared integration hunks: woodland variables and refresh only in `scripts/local_terrain.gd`, isolated audit flag, and this record. Integrator must review/cherry-pick; worker does not merge or launch canonical main.


## 2026-09-05: Ground harvest detail on rendered triangles

Worker `C:/Users/sjpur/tt-grounded-harvest`, branch `codex/grounded-harvest`, base `0350465ee8cd6a4f4588212924ac6e0c3bff1739`. Previous harvest work is integrated as ac1a3b2. Integrator notified of shared terrain scope before editing.

Corrected a remaining placement mismatch: the regional mesh has a 0.6-metre lift and alternating triangle diagonals, while the initial stumps sampled continuous micro-relief with a fixed offset. A new rendered-surface sampler follows actual triangle interpolation. Terrain retains the completed builder's CPU height array (no GPU readback); close ground uses its fixed diagonal grid, and overlapping layers choose the higher visible surface. Harvest representatives rebuild when terrain grid or close surface visibility/center changes. Stump bases embed two centimetres into the sampled surface. Positions, instance budget, depletion, discovery and zoom fade remain unchanged.

Validation: clean headless editor import; 14/14 tests across rendered-surface, harvest-detail and landscape-resource suites, zero errors/failures/orphans. New tests compare samples against Geometry3D ray intersections with actual TerrainPatchBuilder triangles on both diagonals, verify fixed-diagonal interpolation and outer bounds. Isolated GPU audits at 60-metre span produced 26 grounded representatives on regional and close-surface configurations; inspected artifacts/grounded-close.png and grounded-detail.png. Both completed MAP_AUDIT without script/shader errors; pre-existing shutdown RID/texture leaks remain. Captures/logs are not committed.

Save compatibility: no schema, simulation or extraction changes. Limitations: this grounds stump centers only; broad objects or extreme slopes can still intersect at their edges. It does not correct other vegetation/building placement. The existing sparse representative aesthetic remains, and this is not a photorealism claim. Next useful priorities are geographic woodland/worksite shapes and terrain contact for other small surface details, coordinated with their owners. Original Google Earth reference set remains the scale guide; no new imagery imported.

Shared-file risk: regional height retention, detail grid center, harvest sampling/refresh in scripts/local_terrain.gd; audit fixture and this record. No known conflicts at handoff. Integrator owns merge and canonical launch.


## 2026-09-05: Filter procedural vegetation detail during zoom

Worker C:/Users/sjpur/tt-canopy-filter, codex/canopy-filter, base 221963f63630002c2b78ab2a109446b57d164513. Prior grounding integrated as98384e3. Scope coordinated with integrator: only the procedural noise portion of _vegetation_surface_material and this record.

Crown, leaf and gap variation now measures projected pixel footprint with fragment derivatives and fades unresolved noise toward 0.5. The canopy atlas already uses mipmaps; its separate procedural modulation previously had no scale filtering. This removes one source of sub-pixel intensity variation without changing crown placement, mesh, atlas, discovery, harvest removal or LOD thresholds. Nonlinear gap/highlight thresholds are applied after the filtered noise, so distant color is an approximation rather than an exact area integral.

Validation: initial editor import clean. Existing map-onboarding and landscape-resource suites:23/23 passed, zero failures/errors/orphans. Matched isolated real-render captures at600m span, artifacts/canopy-before.png and canopy-after.png, inspected;837 of921600 pixels changed, maximum channel difference29/255. Inspected canopy-close.png at60m span. All captures completed MAP_AUDIT without script/shader errors; existing shutdown leaks persist. These are static checks, not a motion-aliasing benchmark or a measured frame-time improvement.

The effect is subtle. Captures expose more prominent existing terrain shading seams and simplistic/sparse canopy geometry; filtering does not fix either. Those deserve the next graphics investigation, particularly overlapping close/regional terrain and directional shadows. No photorealism claim. Original Google Earth references remain the visual scale guide; no external assets added. Saves and simulation unchanged. Shared-file conflict risk is restricted to the named material function; integrator owns merge and canonical launch. Generated captures/logs/import metadata excluded.


## 2026-09-05: Soften close terrain lighting seams

Worker C:/Users/sjpur/tt-terrain-seams, codex/terrain-seams, base f0b4b2bafe877050681c6b4f67991a6240abf644. Canopy filtering integrated88a3304. Scope coordinated with integrator before edits and updated after diagnosis: TerrainPatchBuilder normal stencil, _build_detail_terrain_patch normals, tests/audit and this record.

Matched600m experiments ruled out regional shadows, all sun shadows and the close ground layer as the primary source. All sampled regional/detail normals point upward. Unshaded terrain retained the feature; substituting upward normals in procedural hillshade removed it. The existing hillshade amplifies abrupt slopes/cusps in generated relief.

Regional normals now use at least a20m radius derivative baseline at close resolution, keeping the existing adjacent sample at coarse scales. Close terrain normals use the same20m authoritative relief baseline instead of independently lighting sub-metre micro-relief; a temporary per-vertex cache avoids repeated derivative samples across triangle corners. Vertices, heights, triangle indices, resource placement and saves are unchanged. Region-only smoothing initially exposed sharper close-layer shards; matching the close layer removed that mismatch.

Validation:22/22 tests passed across terrain builder, rendered surface height and map onboarding. New ridge regression checks continuous close normals while preserving vertex heights and opposing slopes. Editor import clean; final real-render probes parse and finish without script/shader errors. Reviewed artifacts/before.png, no-shadow.png, no-detail.png, sun-off.png, flat.png, unshaded.png, up-normals.png, smoothed.png and final.png. Reviewed final cached implementation at60m (close.png) and actual10,000 feet (aerial.png). Diagnostic flags retained in map_graphics_audit.gd. Existing shutdown RID/texture leaks persist. Captures/logs excluded from source.

Limitations: a partial close-view improvement. Large-scale angular ridge/cusp shapes remain apparent in the aerial view because the authoritative height field is unchanged. This deliberately softens small relief lighting and adds four height evaluations per unique close-patch vertex during its one-time build; no frame-time improvement is claimed. No photorealism claim. Original Google Earth reference set remains the scale guide; no external assets added. Next priority: investigate ridge-shape continuity without silently altering established geography/saves. Shared-file conflict risk limited to the named functions and audit; integrator owns merge and player launch.


## 2026-09-05: Cache shared close-terrain vertex samples

Worker C:/Users/sjpur/tt-detail-grid-cache, codex/detail-grid-cache, base cd09059da0d6b7d34ca82a4057fb04d1d58bd230. Terrain shading integrated0b435f3. Scope coordinated: _build_detail_terrain_patch sampling cache, isolated audit profile and this record.

The112-by112 close grid emits73,926 triangle corners but has only12,544 distinct vertices. Height and biome color were recalculated for every corner while normals alone were cached. A temporary per-build vertex cache now reuses the exact position, color and normal sample. No geometry resolution, indexing, shader, visual placement, LOD trigger, simulation or save change.

Validation:19/19 existing terrain-builder and map-onboarding tests pass, zero errors/failures/orphans. Headless import clean; isolated GPU profiling runs complete without script/shader errors. Three baseline rebuilds (including the function's vegetation rebuild) took670822/680625/755273 microseconds; optimized259567/260153/271288 microseconds. Median680625 to260153, about62% lower on this host in this fixture. This is a synchronous build-duration result, not a whole-game FPS or pan/zoom benchmark. The remaining260ms can still cause a pause.

Audit --detail-build-profile checks repeated mesh fingerprints and accepts --expect-detail-hash=2260915481 for this fixedseed fixture. Baseline/optimized serialized mesh attribute fingerprints match2260915481. Reviewed artifacts/detail-after.png; Pillow image difference between detail-before.png and detail-after.png is empty (pixel-identical). Existing shutdown RID/texture leak messages remain. Captures/logs excluded from commit.

Save compatibility:unchanged. Temporary dictionary holds12,544 vertex records only during construction; no persistent cache invalidation or new saved state. Next priority: bounded/asynchronous close mesh construction if further pause reduction is needed, with vegetation build considered separately. Existing Google Earth references continue to guide zoom/scale; this performance pass adds no imagery or photorealism claim. Shared-file conflict risk limited to named close-build function and audit block. Integrator owns merge and canonical launch.


## 2026-09-05: Direct indexed close terrain construction

Worker C:/Users/sjpur/tt-indexed-detail, codex/indexed-detail, based9485b911493d56f7e1531f11d6abdfcc630f4be. Previous cache integratedc07d2c0. Scope coordinated with integrator: close-grid helper/test, _build_detail_terrain_patch hookup, audit equivalence/profile and this record.

Close terrain now fills packed position/normal/color arrays once per vertex and creates the existing fixed-diagonal triangle indices directly. This avoids triangle-corner expansion, temporary per-vertex dictionaries and SurfaceTool deduplication. Sampling remains inline in the terrain owner; the helper only assembles the supplied grid. Geometry resolution, triangle order, attributes, materials, vegetation, triggers, simulation and save schema remain unchanged.

Validation:20/20 tests across close-grid equivalence, rendered-surface height and map onboarding; zero errors/failures/orphans. New test compares every indexed triangle corner's position, normal and color against a SurfaceTool reference. Final editor import clean. Real GPU audit compares expanded per-triangle attributes independent of vertex storage order:baseline/final fingerprint2888042706. Reviewed indexed-final.png; before/final screenshots are pixel-identical. No script/shader errors; existing exit cleanup leaks persist.

Three-sample isolated full rebuild median279999us baseline (271166/279999/325095),222875us final (207363/222875/242476), about20% lower in this fixture. An initial callback-based helper regressed to359423us and was replaced before final validation. These timings include the function's vegetation rebuild and are not whole-game frame rates. Remaining223ms is synchronous and can still cause a pause. Captures/logs stay in artifacts outside source commits.

Save compatibility:unchanged; no geography or stocks altered. Next useful performance work is splitting remaining close mesh/vegetation construction across frames with cancellation, rather than assuming this optimization removes all zoom stalls. Existing Google Earth references remain the scale guide; no imagery added or photorealism claim. Shared-file conflicts limited to the named close-build function/audit; integrator handles merge and canonical launch.
