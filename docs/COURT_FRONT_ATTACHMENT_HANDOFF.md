# Court front attachment repair

Worker branch: `codex/court-lapel-seams`, in
`C:/Users/sjpur/.codex/worktrees/court-chapter-assets/TomorrowandTomorrow`.
Base: root `560762be`, plus walking correction `6cba2761` cherry-picked as
`b104a7f5`. The integrator already has that dependency; apply only this repair.
This worktree and its private diagnostic renders are not the player build.

The formal walking capture exposed real coat intersections: green coat faces
cut through gold lapels, and a coarse white cravat crossed its curved shirt.
The same four-corner construction affected court coats and business ties.
These front attachments now clip their outlines through the actual curved
garment surface, inheriting interpolated source skin weights. Lapels sit 9 mm
outside the jacket, neckwear 13 mm, scaled with body height. They retain their
existing shape, material and age policy; children still have no tie or cravat.

Only 60 lapel/cravat/tie meshes across the seven additive wardrobe bundles have
changed. Attribute and index comparison against `b104a7f5` confirms every other
mesh is identical, including shirts, sewn collars, cuffs, belts, trousers,
shoes and full skirts. All seven original figure GLBs remain byte-identical.
The original body, face morphs, bind poses and animation data are preserved.

Validation:

- Raw wardrobe and new front-layer checks pass all seven bodies. The check
  samples triangle interiors as well as vertices: every old bundle fails it
  with 9–24 mm coat/lapel intersections, while the repaired layers retain at
  least 6.5–8.6 mm jacket clearance. It also rejects detached floating facings.
  `artifacts/lapel-seams-raw.log` and `lapel-seams-invariants.log`.
- Imported wardrobe and walking resource-preservation tests pass **7/7**,
  with no errors, failures, skips or orphans; exit 0.
  `artifacts/lapel-seams-tests.log`, report6.
- A private GPU probe produced **30 views**, covering courtcoat/formal/business
  walking, seated speech and standing speech from front and side, with all
  seven body variants represented. The original failing formal walk pose now
  has continuous lapels and chest fabric. PID28640 exited 0; no engine/script
  errors. `reports/lapel_seams/`, `artifacts/lapel-seams-gpu.log`.
  An independent reviewer inspected all 30 images and found no remaining front
  intersections, detached pale strips, neckwear punctures or new seam openings.
- The existing strict motion audit remains a **diagnostic failure**:
  **267/1,344** samples exceed its unchanged relative-stretch threshold;
  worst **4.81x**, coverage gap **0.000 m**, exit 1. The worst edge is the
  unchanged female-young courtcoat skirt while kneeling (16.51 mm to 79.37 mm).
  All reported worst-mesh names are unchanged skirts, trousers, jackets or
  cuffs; none names these attachments. This is not a claim that all cloth
  deformation passes. `artifacts/lapel-seams-motion.log`.

No runtime, source animation, simulation or save-schema change is part of this
repair. Existing saves are compatible. The front-facing patches are fitted
skinned surfaces, not simulated cloth. The tested poses and camera angles do
not prove all possible deformations perfect. The separate legacy-tunic body
coverage work is outside this asset repair. Generated captures, probe scripts,
imports and logs remain local. Final combined imports, runtime checks and main
delivery remain the integrator's responsibility.
