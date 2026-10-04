# City evolution presentation pass

Worker branch: `codex/city-evolution-quality`, based on `17f1524c3e7b6d0a02c1ef3690d72a4e7e5b7454`.
Worktree: `C:/Users/sjpur/tt-court-interior-seating`. This is an isolated development checkout, not the player build.

## Changes and evidence

- Modern versions of all eight architecture types now close each volume with a flat roof and parapet. Courtyard wings, service buildings and civic volumes no longer inherit pitched medieval roofs. Setbacks use the last two recorded floors rather than adding floors. Industrial and modern windows have wider openings and mullions; earlier masonry dimensions remain unchanged.
- Architecture uses one cached ink material with a separate surface-normal outline. The legacy radial outline lifted the underside of thin roof slabs through their top faces. At identical camera, mesh and pixel size, the corrected GPU swatch reads roof luminance **0.6087**, versus **0.0674** for the old pass. Existing early-kit materials retain the previous outline. Pixel width, hearth and animation clock updates reach the new cached material; cloud/wind registration uses the existing weak-reference registry.
- Supported plot IDs beyond the detailed kit's 128-ID budget retain ground, boundaries and bounded aggregate roof geometry. They previously disappeared entirely. New fallback placement requires recorded active frontage, checks the whole conservative roof envelope against the parcel and street envelopes, samples land and grade at the center/corners, and rejects overlap with earlier masses. Four bounded position/scale candidates can fit a generic mass inside a smaller legal parcel. A supported parcel rejected by the detailed solver **inside** the budget remains rejected; the existing no-frontage/no-fit regression still passes. Legacy fallback callers do not enable the new placement mode.
- Population-derived land-cover radius interpolates density continuously between the existing class reference densities. Previously, for example, 399 residents gave about 0.504 km while the 400-person classification reduced the radius to 0.412 km. All six thresholds are now continuous and nondecreasing. Actual built-plot extent remains a floor, and the existing 340 km cap remains.

Shared hotspot `scripts/local_terrain.gd` is limited to `_settlement_stage_visual_layout`, the paired ground/fallback predicates in `_create_plot_fabric`, and the optional validation argument/block in `_append_satellite_roof_fabric`. No simulation, population, discovery, project setting, terrain generation, or save schema is changed.

## Reproduction

Godot 4.7.2, explicit worktree path:

```powershell
& (Get-Command Godot_v4.7.2-stable_win64_console.exe).Source --headless --path C:/Users/sjpur/tt-court-interior-seating -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/test_city_evolution_visual.gd -a res://tests/test_settlement_architecture_kit.gd -a res://tests/test_early_settlement_visual.gd -c --ignoreHeadlessMode

& tools/run_isolated_gpu_probe.ps1 -Godot (Get-Command Godot_v4.7.2-stable_win64_console.exe).Source -Project C:/Users/sjpur/tt-court-interior-seating -Scene res://tools/city_evolution_visual_audit.tscn -LogFile C:/Users/sjpur/tt-court-interior-seating/artifacts/city-evolution-gpu.log -UserArguments '--out=res://artifacts/city-evolution' -TimeoutSeconds 240
```

The private renderer supports `--roof-only` for the brief paired roof assertion. Never use this test scene as the current game.

The focused three-suite run passed **29/29**, with no errors, failures or orphans; log `artifacts/city-evolution-focused-tests.log`. The existing broader terrain architecture suite passed all **83** cases, but its log prints outside-tree transform errors in the contact-marker path, so that run is not presented as a clean engine diagnostic (`artifacts/city-evolution-final-tests.log`). The city changes do not touch that path or suppress the diagnostic.

The private GPU run produced all **16** frames at years 0–3000 in 200-year steps. Images and metrics are under `artifacts/city-evolution-verified/`; same-camera baseline images are under `artifacts/city-evolution-baseline-ground/`. The separate corrected swatch/log are under `artifacts/city-evolution-roof-final/` and `artifacts/city-evolution-roof-final.log`. Its process exited 0 on a private desktop, with no engine/script errors. Captures stay outside source control.

These are **prepared visual-history records**, not a 3,000-year economic or demographic campaign. The fixture adopts only construction discoveries whose live catalogue dates permit them, then uses the live fabric conversion and actual terrain/building renderer. Sparse persistent IDs exercise the detail limit; some older fabric remains among newer buildings. Capacity rises from 64 to 3,512 without rendering changing population or capacity ledgers. The live catalogue yields generation 0 at year 0, 9 at year 200, 10 at years 400–2400, and 12 at years 2600–3000. The 200-year interval does not capture the short intermediate industrial window; industrial geometry is separately covered by the existing architecture-kit tests.

At year 3000, the baseline had 113 detailed instances and zero fallback roof vertices. The final scene has 140 detailed instances and 60 safely placed aggregate roof vertices across the two over-budget parcels. Detailed instances remain below the existing 512 limit. The numerical extent tests cover population growth separately from this fixed-camera parcel fixture.

## Limits and integration

Foreign settlement intelligence does not currently provide verified building-era fields. This change does not invent a foreign era from hidden knowledge or elapsed time. Over-budget roof proxies remain aggregate map symbols rather than full-height authored buildings. No claim is made that this fixture validates every terrain seed or full campaign economic pacing.

Save compatibility is unchanged. Integrate the worker commit deliberately, preserving concurrent `local_terrain.gd` edits, and rerun focused tests against the combined checkout before claiming player delivery.
