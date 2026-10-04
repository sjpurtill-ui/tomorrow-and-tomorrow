# Court nose and ear anatomy — October 4, 2026

Worktree: `C:/Users/sjpur/.codex/worktrees/court-face-richness/TomorrowandTomorrow`.
Branch: `codex/court-face-richness`. Source baseline: integrated main `304ad0cb68ad21f036a9ec792f15df275e70c544` (includes the decree popup).

## Behavior

The previous rendering pass left a nearly submerged, heavily decimated nose and solid ellipsoid ears. This pass changes the actual skinned geometry: a projecting nasal bridge, rounded tip, alar wings and shallow paired underside recesses; an ear rim, recessed bowl, forked inner ridge, tragus and soft lobe. The first over-projected nose was rejected in visual review and reduced before delivery. Expanded ink is suppressed around internal nasal folds to avoid black seams.

All seven body variants are updated in all three sources: original Body, early-outfit LegacyBody and era-outfit WardrobeBody (21 GLBs). Local conforming subdivision follows the original smooth surface, carrying skin weights, face identities and all expression targets. Smoothing tapers below the separate brow decals to retain their clearance. Normals are rebuilt in the affected area for the base and each target. Original body positions and morphs outside the facial envelope remain exact; rigs, clips, garments and their metadata/accessors are preserved. The exporter applies the same refinement after a fresh export, before wardrobe tools copy the body.

`tools/blender/refine_court_anatomy.py --source-ref 304ad0cb` reproduces the current exports from pristine Git blobs. It rejects already-refined inputs rather than accumulating the sculpt repeatedly. Output replacement is atomic. `court_ear_anatomy.py` is a pure NumPy helper from worker commit `5ad130f9` (integrated as `8af16cdc`); the independent asset validator is worker `bf4cc331` (integrated as `cbef40a7`).

## Validation

- `artifacts/anatomy-tests-accepted.log`: 103/103 tests in nine court suites, zero errors/failures/skips/orphans. Includes expressions/acting, look identities, eyes, normal morphs, wardrobes, camera, presence, render slots and gore compatibility.
- `artifacts/anatomy-ink-tests.log`: 9/9 eye/render-budget checks after adding the skin-only outline material key.
- `python tools/blender/test_court_ear_anatomy.py`: 8/8 tests; finite-difference deformation checks retain positive Jacobians.
- `artifacts/anatomy-validation.log`: 21/21 assets pass against `304ad0cb`, plus seven exact cross-bundle head comparisons. Original binary prefix, original accessor/view dictionaries and nonbody JSON match. Finite attributes, target lengths, skin weights, indices, bounded triangles and original positions/morphs outside the face pass. No new boundary or nonmanifold edges; old variants retain their pre-existing nine-edge seams. Simultaneous negative nose/bridge identity weights retain measurable nasal projection. The validator rejects seven deliberately corrupted controls.
- Private GPU probes use `tools/run_isolated_gpu_probe.ps1`, Dummy audio and explicit worktree path. The eighteen-person sheet covers ages, sexes and skin ranges. Three close-up sitters have front, 45-degree and both profile captures; merged expressions cover rest, smile, worry, speech, gaze and blink (`artifacts/anatomy-accepted.log`). Fallback captures also pass (`artifacts/anatomy-unmerged.log`, before the final brow-clearance taper). Captures are isolated render checks, not the live player. Existing Compatibility depth-of-field warnings remain; final probes have no script/engine errors and exit normally.
- Source diff whitespace check and Python compilation pass.

## Limits and integration

The body rises from about 8,000 to 25,808–28,077 triangles, concentrated around these features. Existing merged draw-slot limits still pass; this is not an FPS benchmark. Existing hair, mouth/chin proportions and broader illustrated style remain. Some narrow shadow/contour marks remain at certain angles. No simulation, adjudication ledger, population, official/leader ownership, save format, or animation clip changes. Existing saves retain their appearance identities and remain compatible.

Only task source, validator/tests, these 21 geometry assets and delivery records are committed. Captures, import churn, generated UIDs, Python caches and test settings stay local and excluded. The canonical player/editor are not restarted or stopped. Integration must push and verify origin/main before fast-forwarding canonical main; the new assets load on the player's next normal launch.
