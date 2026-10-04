# Legacy tunic walking-panel checkpoint

Worker: `codex/court-walking-cloth-clearance`, worktree
`C:/Users/sjpur/.codex/worktrees/court-chapter-policy-tests/TomorrowandTomorrow`.
Follow-up to `6cba27612075fba538528740762b0bba94a3bc57`; integrator owns main.

The adult male and female tunics showed small skin patches through the lower
front during a stride. CPU projection traced the actual visible patches to
2.6–3.1 mm of penetration. The repair gives the existing tunic front panel up to
8 mm of smooth, body-scaled ease. The hem, back, waist, sleeves and collar
fall outside the adjusted region. Both shell layers move together.

The helper copies the packed position buffer and bounds only. It retains every
original normal, tangent, index, skin weight, color mask and morph exactly, and
never modifies an imported mesh. It is cached (maximum 14 entries) and reused on
redress. All seven shipped tunics use uncompressed float position buffers; an
unsupported future compressed mesh is left unchanged instead of reinterpreted.
There are no asset, source animation, rig, walking-speed or simulation changes.
Save compatibility is unchanged.

A permanent body-mask expansion was tried and rejected: deep kneeling can move
the cloth away from those thighs. None of that prototype ships. The entire body
mesh and original conservative coverage are unchanged by this checkpoint.

Validation:
- Four focused suites, 14/14 passing, no errors or orphans:
  `artifacts/tunic-fit-final-tests.log` (report 25).
- The exact visual-region ray regression reproduces 17 male and 26 female
  original skin protrusions; the fitted panel covers all 43 without erasing skin.
- All seven bodies, both walking clips, 32 phases: 448/448 hand/cloth samples clear.
  `artifacts/tunic-fit-hands.log`.
- 18 normal-ink private GPU views, PID59724 exited0 with no engine errors:
  `artifacts/tunic-fit-final-visual.log`.
  `reports/court_tunic_coverage/tunic_walk_out_0_-20.png` shows the corrected spots;
  `tunic_walk_in_70.png` retains clear hands; `tunic_sit_70.png`,
  `tunic_kneel_70.png` and `tunic_sit_cross_70.png` retain exposed legs.

Limits: this is a narrow walking-panel correction. The expanded deep-pose views
also expose substantial inherited legacy garment deformation/skin breakthroughs,
including sleeves and folded skirts. These remain separate unfinished quality
work. This checkpoint does not establish that all court animation or cloth is
visually complete. It neither changes nor relaxes the strict deformation audit.

Shared-file integration: five added lines in Figure3D `_dress`, plus the private
pose probe's optional `legacy-coverage` matrix. The new helper and test are
independent. No overlap with additive wardrobe/lapel assets or shaders. Generated
imports, captures, caches and the rejected mask experiment are excluded.

