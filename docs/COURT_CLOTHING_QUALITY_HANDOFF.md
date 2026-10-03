# Court clothing quality pass

Worker branch: `codex/court-clothing-quality`.
Worktree: `C:/Users/sjpur/.codex/worktrees/court-clothing-quality/TomorrowandTomorrow`.
Base: `a2781e2a33e9f7a68e70ee601caf464cdd14a2f6`, the combined court integration snapshot, including the unfinished clothing build `58a0912a`.

## Behavior

Skirts now use a continuous weight field across the legs, instead of switching abruptly to the nearest thigh. Shoulder mantles follow the torso and no longer pick up thigh or arm weights. Sleeve weights are averaged across both faces of the cloth shell after removing distant hand/forearm influences. Cloth above the belt stops following the thighs.

Body skin is hidden only when the covering garment follows its bones. Sleeves and legs require more agreement than the torso; proximity at rest alone no longer hides them. The audit now includes shoes and belts when finding the piece responsible for hidden skin. Its deformation and coverage thresholds are unchanged.

All seven base figures were refitted. Only garment joint/weight buffers and Body coverage channels G/B/A changed. Geometry, normals, AO R, face morphs, skeleton rests, animation bytes and GLB structure/JSON remain byte-identical to the combined baseline. The full Blender builder uses the same refinement. `tools/blender/refit_court_clothing.py` can reproduce this restricted update from pristine pre-refit assets; do not repeatedly refit its own output.

## Verification

- `python tools/blender/validate_clothing_refit.py artifacts/clothing-baseline assets/court_figures`: all seven pass. Checks normalized weights, valid joints and every byte outside the allowed buffers.
- Godot 4.7.2 headless, explicit worker path: figure look 7/7, figure gore 4/4, court acting 47/48. The one acting failure is `test_every_act_the_director_speaks_has_a_performance`: missing windup, swing, squint, tug, stir, taste, retch, hide_eyes, throw, warm_hands, cough_smoke. This branch changes neither acting metadata nor clip libraries; integrator must check the separate acting fixes.
- Full all-body audit: 9,020 samples across 128 clips for each adult body and 134 for the child. Using identical raw-GLB loading and corrected whole-outfit coverage lookup, flagged samples drop from **2,128 to 446**. The audit still exits with failure. Baseline worst sampled edge stretch was 27.36x; final worst garment sample is 3.43x (elder female overhead stretch). The child's unchanged Body mesh reaches 3.94x. No thresholds were relaxed.
- Private GPU capture runner exited 0 and closed. Inspected all seven bodies in hide/tunic/robe for kneel, cross-legged sitting and overhead stretch (nine lit sheets). Torso/limb continuity is improved; deep seated robe laps still have angular folds. This is a static skinned mesh, not simulated cloth.
- Headless asset import completes. Existing missing-UV tangent generation messages remain; the refit does not change UVs or normals.

Local, ignored evidence: `artifacts/clothing-audit-baseline-all.log`, `artifacts/clothing-audit-final2-all.log`, `artifacts/clothing-tests.log`, `artifacts/clothing-final-sheets.log`; `reports/court_acting/clothing_<clip>_<time>_<outfit>.png` for `kneel/1.5`, `sit_cross/1.6`, `stretch/1.3`.

Reproduction: run `res://tools/court_acting_audit.tscn -- all male_adult,female_adult,male_old,female_old,male_young,female_young,child <absolute-assets-directory>` with Godot headless and the explicit worktree path. The last argument uses the actual GLBs, avoiding a stale imported cache. The diagnostic companion `court_clothing_diagnose.tscn -- <body> <clip>` prints failing edge weights. For lit sheets, use `run_isolated_gpu_probe.ps1` with `court_clothing_capture.tscn` and user argument `bodies:kneel@1.5,sit_cross@1.6,stretch@1.3`.

## Integration and limits

The large rectangular patch in floor-sitting captures was the unskinned stool intersecting the actor, independently confirmed by a private before/after capture. The runtime agent owns that separate fix (`d363ce7ba1f4831c01cc2efa3431f56ed969dc2d`); it is not included here.

Remaining audit flags cluster in deep seated/kneeling poses, overhead stretch, running and child torso skinning. The review should retain those as known limits, not report a clean all-body audit. Garment geometry was intentionally preserved so this fix does not disturb faces, body identity, animation compatibility or execution assets.

Shared-file conflicts: `tools/blender/court_figures.py`, `tools/blender/cf_dress.py`, all seven `court_figure_*.glb`, and `tools/court_acting_audit.gd` (WRAPS lookup only). New refit/validation/diagnostic/capture helpers and this handoff are independent. No runtime scripts, authored clip libraries, execution selection, game state or save schemas changed. Save compatible. No canonical checkout changes or player launch; integration and player-build verification belong to the designated integrator.
