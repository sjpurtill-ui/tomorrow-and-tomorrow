# Additive legacy garment provider

Worker `codex/court-legacy-provider`, base `1c09a4e69c6176ca39e78d4d86f114bcf55c1430`, worktree `C:/Users/sjpur/tt-court-interior-seating`.

The provider reads `assets/court_figures/legacy/court_legacy.json` and substitutes approved hide/tunic/robe mesh resources on the existing figure nodes. `LegacyBody` supplies only the relevant source coverage channels (G hide, B tunic, A robe). Missing variant, outfit or incomplete piece lists keep the complete original outfit. Redressing restores original meshes before selecting another outfit. Existing modern wardrobe and walking-clearance hooks remain intact.

Source skeleton, AnimationPlayer, body geometry/morph data and animation timing remain owned by the original figure. No extra render nodes or per-frame solver are introduced. Loaded bundles are cached by revision, content hash and target bind order, bounded to fourteen entries. Merged mesh keys include the replacement revision so an already-cached source outfit cannot hide the new geometry.

## Validation and status

Godot 4.7.2 headless import passed. Three provider regressions and two existing wardrobe tests pass: fallback completeness, original resource preservation/redressing, unchanged rig/player/animation time, bounded visible instance ownership, separate/reused merged meshes. Logs are `artifacts/court-legacy-provider-import.log` and `artifacts/court-legacy-provider-tests.log`.

This runtime checkpoint is ready for asset-worker testing. Replacement garment assets and actual deep-pose pixel acceptance are **HELD** independently; this checkpoint alone does not assert that any new garment is production-ready. No save fields or simulation state change. Shared integration files: `scripts/hud/court_wardrobe.gd` and the dressing/provider sections of `scripts/hud/court_figure_3d.gd`. No modern garment generator, imported source body or animation resource is changed. Unrelated existing import metadata, generated UID files and `tests/test_early_settlement_visual.gd` remain excluded.
