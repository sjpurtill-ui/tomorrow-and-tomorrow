# Early settlement service-ground blending

Worker: `C:/Users/sjpur/tt-army-map-readability`, branch `codex/service-ground-blending`, base `555b395cba19affbc9b2c94f07caebcaf7f3965f`.

Water-carrying and waste service parcels now feather into the surrounding terrain. The founding carried-water point uses earth coloring and a small irregular worn patch rather than a conspicuous circular pond. Other water forms retain their existing central water feature. Refuse ground uses an irregular feathered mark instead of a perfect disc.

Scope: graphics in `scripts/local_terrain.gd` and architecture regression tests only. No changes to plot records, simulation, saves, menus, or player launch.

Verification: all 82 settlement visual architecture cases passed. New actual emitted-mesh assertions verify feathered parcel and feature alpha, bounded irregular feature geometry, and earth-toned carried-water ground. Hidden, self-closing GPU capture inspected: `artifacts/settlement-service-ground.png`, early population 120, growth zero, zoom 0.4. Existing shutdown texture/RID leak diagnostics remain; no shader failure observed.

Shared-file integration: local_terrain.gd only, localized `_settlement_plot_color` and `_create_plot_fabric` hunks. Preserve other terrain workers' edits. Generated imports and UIDs were left untouched and unstaged.
