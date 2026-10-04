# Court facial richness — October 4, 2026

Worktree: `C:/Users/sjpur/.codex/worktrees/court-face-richness/TomorrowandTomorrow`.
Branch: `codex/court-face-richness`. Integrated-main base: `dd4bd733089665172db55cad57bb37e586b55a9f`.
Runtime delivery: `4e98252b132c607f4e23fbbb0c89c7489dd94c6e`, including `6254b1aa` and the normals worker `34a81041c849998141546a7f946a69d69f5c6f29` (cherry-picked as `937017c5`).

## Player-visible changes

- Skin responds continuously to court light instead of flattening into four bands. Shallow cheek, lid and lip relief, lower frontal emission, softer lip/fold paint, and finer face outlines preserve the existing illustrated style.
- The merged court eyes have shaded whites, iris fibres and a dark outer rim, smaller highlights, and warmer lid lines. Per-eye UVs follow existing gaze/blink morphs. No additional draw surfaces or textures are needed.
- Brow decals have a small clearance from the skin, carried through expressions, closing the triangular gaps visible in close-ups. Freckles have varied positions and sizes; face paint is masked away from the back of the head.
- Merging retains authored expression normals and identity normal changes at stationary vertices. Smiling, talking and worried faces therefore keep their changing surface lighting.
- Reusing a figure after a body-variant change safely rebinds its freed acting controller. The unmerged fallback explicitly draws pupils and glints after their irises.

## Validation

Godot 4.7.2, headless with Dummy audio, isolated test user directory:

- `artifacts/face-tests-final.log`: 102/102 across nine suites (face normals, eye surfaces, figure looks, acting, render budget, wardrobe, presence, camera composition and figure gore), zero errors/failures/skips/orphans.
- `artifacts/face-fallback-tests.log`: 9/9 after the final fallback layer fix; 103 distinct cases across both runs. The normal regression was also run against original code in the worker fixture and failed as expected.
- A warm editor import exits cleanly with no script/engine errors (`artifacts/face-import-warm-stdout.log`). The first cold import reported unavailable pre-import fonts and the known untextured mesh tangent diagnostics; the warm import cleared them.

All graphical captures use `tools/run_isolated_gpu_probe.ps1`, an explicit worktree path, private desktop and Dummy audio. Normal final captures (`face-final.log`), 21 controlled expression/gaze captures over three sitters (`face-expressions-final.log`), and the unmerged equivalent (`face-unmerged-final.log`) exit 0 without script or engine errors. Eighteen-person sheets cover adult/young/old men and women, two children, and three skin ranges. Close-ups and the expression images were visually inspected. Compatibility-renderer depth-of-field warnings are pre-existing. The first expression run exposed the freed-controller bug and timed out; it is retained as failure evidence, not a passing result.

Generated images/logs stay in ignored `artifacts/` and `reports/`. The before/after comparison is also saved in this chat's visualization directory. Captures are isolated render checks, not the current player session.

The existing unlit figure capture also exits 0 (`artifacts/face-toon.log`, two scenes), exercising the shared face include in the toon shader. Its older test UI produces anchor-layout warnings; no script/engine errors, and the rendered hall image was reviewed.

## Compatibility and limits

No GLB, rig, animation clip, outfit, person identity, simulation, population, government, military, adjudication ledger or save-schema changes. Existing saves remain compatible. The new iris detail/brow clearance belongs to the normal merged court path; unmerged fallback retains simpler eyes but their layers are now reliable. Original stylized head proportions and some narrow nose-outline artifacts remain; this is a rendering and expression pass, not a full model replacement or a complete campaign replay. Clothing and performance bounds are covered by existing suites; no GPU frame-rate claim is made.

Only the listed task sources, tests and integration documents are committed. Import churn, generated UIDs, captures, test override and unrelated files are excluded. Neither the player nor an editor was stopped or restarted. A running canonical game retains its loaded scripts until the next normal launch.
