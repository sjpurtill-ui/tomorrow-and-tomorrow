# Court walking direction — October 4, 2026

Integrator worktree: `C:/Users/sjpur/.codex/worktrees/court-walk-facing/TomorrowandTomorrow`.
Branch: `codex/court-walk-facing`. Base: `d7d4850c`.
Source checkpoint: `385c3806`.
Combined code integration: `c893daf7`, merging canonical/origin main
`be9bc80b` (the completed Wealth delivery) without conflicts.

## Behavior and scope

The base `walk_in` and `walk_out` clips played their foot cycle backward:
low feet swept forward relative to the body while bent knees recovered backward.
The stage's facing and travel direction were already correct. Reverse the
authored cycle clock and the matching baked animation samples in all seven
top-level court figure GLBs. Forward travel now opposes the planted foot's motion.

Every existing pose is retained, including arm/clothing clearance. Binary audit
against the base revision confirms that only these two clips' LINEAR output
samples changed: headers, JSON, timestamps, STEP tracks, geometry, native MPFB
heads, morphs, skeleton, clothing and all other clips retain identical bytes.
Legacy and era wardrobe bundles carry no walk animations and need no update.

`tools/blender/correct_court_walk_cycles.py --source-ref d7d4850c` reproduces
the baked correction. It verifies the exported timestamps are symmetric and
STEP tracks constant, refuses unrelated asset changes, and supports safely
rerunning against that same original revision. Fresh exports use the corrected
phase in `cf_anim.py`.

## Validation

- Final clean headless editor import: exit 0, no engine or script errors.
  The first cold import reported unavailable fonts before creating its caches;
  those errors did not recur after imports completed.
- New imported-animation checks cover seven bodies, both walks, five builds,
  and both ankles/toes: 280 body/clip/build/bone combinations. During contact
  (within two scaled centimetres of each bone's lowest point), all sampled
  foot motion opposes travel. Reference-body toe and all-build ankle slip
  remain below half the travel speed. Nonuniform build scaling and toe rocking
  are explicitly separated in the calibration check.
- Final combined regression: 119/119 cases across gait, motion, walk-clearance,
  stage, presence and acting; no errors, failures, skips or orphans.
  Evidence: `artifacts/walk-combined.log`, `reports/report_3/results.xml`.
  Command: Godot `--headless --path <worktree> --script
  res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/test_court_walk_gait.gd
  -a res://tests/test_court_motion.gd -a res://tests/test_court_walk_clearance.gd
  -a res://tests/test_court_stage.gd -a res://tests/test_court_presence.gd
  -a res://tests/test_court_acting.gd -c --ignoreHeadlessMode`.
- Private GPU `tests/court_motion_capture.tscn` passed in court tiers 0 and 1,
  covering entry, answering while walking, and departure. Captured entrance
  frames were reviewed. Probe PID 38396 exited 0 on a private desktop with
  Dummy audio; no engine/script errors. Compatibility rendering emitted its
  existing depth-of-field warning. Evidence: `artifacts/walk-gpu.log` and
  `reports/court_motion/` (local only).
- Independent raw-GLB forward kinematics and exact binary reconstruction
  confirmed the correction across all seven assets.

## Compatibility and limits

No simulation, adjudication, population, save schema, or state-authority changes.
Existing saves remain compatible. This fixes backward gait playback; the
existing poses have some foot sliding and asymmetric weight distribution and
are not a new foot-locking/IK system. Special acted walks are unchanged in this
delivery. No shared simulation hotspots were edited.

The running canonical player (PID 41320 at start) was left untouched. Changes
load on its next normal launch through `tools/launch_game.ps1`. Imports, capture
frames, test reports and isolated userdata are excluded from commits.
