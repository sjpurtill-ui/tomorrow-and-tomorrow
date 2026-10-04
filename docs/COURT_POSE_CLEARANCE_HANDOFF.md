# Ordinary pose arm clearance

Worker branch `codex/court-pose-clearance`, checkout `C:/Users/sjpur/tt-court-interior-seating`, initial base `31df94aabd35d4d337d0e554e960027634e4a29f`. Provider source is already delivered separately. This branch also contains held garment and independent diagnostic cherry-picks for calibration; select owned source commits individually during integration.

## Calibration checkpoint: HELD

`court_pose_clearance.gd` fits only `stand`, `sit_cross` and its ordinary held `stance_cross`, using cached copies of their original upper-arm rotation keys. Figure's owned stand resource is updated without changing the player clock or pause; Acting selects a fitted resource when it creates those layers. All other clips retain their original sampling source. No post-pose offset, per-frame collision solver, altered lower body/head/root, regenerated source animation, execution or kneeling correction is introduced. Existing walking fitting stays independent.

Default profiles are intentionally empty until body/cloth contact calibration and private rendered transitions pass. Diagnostic fixtures can set `Pose.overrides` before setup: each variant maps clip names to degrees, an array of `[seconds,degrees]` pairs, or an `L`/`R` dictionary of either form. Values are sampled at existing key times. Cache capacity is ninety-six profiles.

Three headless regressions pass: source and every non-arm track remain exact, including key times/transitions; cross-sit uses the fitted actor source while kneeling, executions and prop stances retain original animations; redressing preserves player time, pause, rate and walking resources. Godot's deep Animation duplication quantized raw glTF key times through packed float arrays, so the helper explicitly restores original times/values/transitions before fitting arms. Log: `artifacts/court-pose-clearance-tests.log`.

No player-visible clearance is claimed by this scaffold checkpoint. Minimum profiles, all-body tests, natural arm/palm appearance and complete onset/release pixel acceptance remain required. Save state and source asset bytes are unchanged. Shared files are one `_dress` call in `court_figure_3d.gd` and the per-layer animation selection in `court_acting.gd`.
