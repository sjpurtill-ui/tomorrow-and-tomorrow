# Court motion — branch handoff, October 3, 2026

Branch: `codex/court-motion`. Base: `df2c25260ea96d856c6aa9ef9426f5dd5d2008c3`.
Worktree: `C:/Users/sjpur/.codex/worktrees/court-motion/TomorrowandTomorrow`.

This is a worker delivery for the court-wiring builder to combine with the
concurrent executions work. Do not deliver it independently to main. The user
requested a branch-only push; the canonical checkout and player were untouched.

## Behavior

- Body-facing tweens take the shortest turn across the angle seam.
- Walking starts and stops gently. Translation and both authored gait layers
  use the same speed curve, including routes whose duration is capped.
- Steering looks ahead by a fixed distance and responds to elapsed time rather
  than a fixed blend per frame. Old facing tweens cannot fight walking.
- Storming, led and backward walks survive the fallback walk animation;
  stale reactions still fade, and speech does not replace the walking legs.
- Speaking, listening and looking up during an entrance preserve the gait.
- Dismissal during an entrance leaves from the current feet, including a small
  positional offset, rather than teleporting to the assigned mark. A delayed
  dismissal rests until the exit starts.

## Owned files and merge seams

- `scripts/hud/court_stage.gd`: Figure walking, arrival interaction guards and
  route start. `plan_walk` and `_route` accept an optional start position.
- `scripts/hud/court_figure_3d.gd`: shortest facing tween, `locomotion_rate` and
  `set_locomotion_rate`; playing a new clip restores normal animation speed.
- `scripts/hud/court_acting.gd`: preserve walk layers, protect them from speech,
  apply the figure's rate only to walking layers. Includes worker
  `105269a90ab07f92e82408b9c93b77d32a13e811`, with a test type annotation fixed here.
- New `scripts/hud/court_motion.gd`: shared distance/velocity curve.
- `tests/test_court_motion.gd`, `tests/test_court_acting.gd`,
  `tests/test_court_set_stage.gd`, and `tests/court_motion_capture.{gd,tscn}`.

Expect conflicts in the stage and acting files when combining executions. Keep
the execution builder's outcome handling and clothing work. This branch changes
no models, outfits, animation assets, adjudication, simulation or save schema.
Existing saves remain compatible.

## Validation

Godot 4.7.2, explicit worktree path, offline fixtures:

- Six headless suites: motion, acting, set-stage, stage, listening and director;
  **143 tests passed**, zero errors, failures, skips or orphans.
- Motion and set-stage rerun after the final delayed-dismissal adjustment:
  **22 tests passed**, zero errors, failures, skips or orphans.
- Private GPU `court_stage_clip.tscn` and `court_motion_capture.tscn` passed.
  Frame sequences reviewed for fire-circle and longhouse entrances/exits;
  the diagnostic capture also frames the doorway and feet. All private probes
  exited 0. No player/editor was launched or interrupted.
- Fresh worktree import needs a second import after initial resource creation;
  the subsequent import passed without script errors. The renderer reports the
  existing depth-of-field compatibility warning during court captures.

Local evidence (excluded from commits): `artifacts/court-tests-final.log`,
`artifacts/court-interruption-final.log`, `artifacts/court-motion-wide-gpu.log`,
`artifacts/court-motion-contact.png`, and `reports/court_motion/` frame sequences.

Run the court suites and the clothing check again after merging with executions.
This validation does not include that concurrent branch. The flat painted
fallback and small ambient nudges retain their existing motion; this delivery
focuses on the modelled court's entrance/exit gait and turning.
