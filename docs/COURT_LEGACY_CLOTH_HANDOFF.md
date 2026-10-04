# Additive legacy cloth repair

Status: **HELD all-seven motion checkpoint**, pending complete motion, hand-fit
and selected execution-pose acceptance. It is not delivered to the player.
Branch `codex/court-legacy-cloth`, base `1c09a4e6`, worktree
`C:/Users/sjpur/.codex/worktrees/court-chapter-assets/TomorrowandTomorrow`.

All seven body variants now contain tunic, hide and robe. Upper shells share
the original body's topology and skin field. Skirts use independent same-leg
panels, inner facings within the original hem, smooth waist anchors and a gold
hem partition on the same grid. Lower front/back vent corners turn inward near
the knee, avoiding the broad shin-driven rim that previously protruded as a
pointed ribbon. The accepted two-body hip/thigh contact envelope is unchanged.
The other five variants use the same construction. Original animation bytes,
clip timing and real kneeling are preserved.

Hide retains its asymmetric wrap, ragged hem vocabulary, fur cape, cord and
foot wraps. Robe retains its original full length, lower mantle drape, sash
and shoes. The upper cape/mantle facets that intersected the supported shoulder
surface are removed; the matched shoulder cap joins to the retained lower
boundary with short sewn strips. Original lower triangles and all their vertex
attributes remain exact, including trim. The small visible gold cape tabs are
a deliberate stylized attachment, independently reviewed as connected cloth.
The head/neck exclusion prevents face overlays. Fastenings and footwear remain
exact. The earlier overlapping lining, unsupported cropped cape and reweighted
open-shoulder experiments were rejected.

The additive files preserve every source body attribute, morph, skeleton and
bind without rewriting source figures or modern wardrobe. `LegacyBody` changes
only the replaced outfits' coverage channels (G hide, B tunic, A robe), for
regions backed by actual garment mesh; visible lower legs remain. The manifest
lists exact source part names/material slots; missing or incomplete outfits
fall back as a whole. Provider dependency: `3b2b8f02` (local cherry-pick
`1192e389`). No simulation or save fields change.

Current evidence:

- All seven bundles / 21 outfits pass `validate_court_legacy_clothing.py
  --complete`: body/face/rig exact, original lower cape triangles and data exact,
  no face/neck influence in shoulder caps, valid indices and normalized weights.
  Log: `artifacts/legacy-all-seven-v12-raw.log`.
- Fresh all-seven import succeeded. Provider and modern wardrobe suites pass
  5/5, zero errors, failures, skipped cases or orphans; process exit 0.
  Log: `artifacts/legacy-all-seven-v12-tests.log`.
- Current cape gate: `reports/legacy_cape_v12/ink/`, 12 private GPU views of
  standing, full 2.5-second kneel and full 1.6-second cross-sit, both yaws,
  male adult and old female. PID33556 exited 0, zero engine/script errors.
  Independent reviewer accepted the clean shoulders and connected junction.
- Earlier two-body three-family transition evidence remains in
  `reports/legacy_candidate_v9/`: 186 views, including walking, full endpoints
  and release. The shoulder replacement supersedes that version's speckles;
  tunic and lower garment geometry remain unchanged.
- Raw equality against `890ed589` confirms all tunic surfaces, hide wrap,
  robe body/trim and all LegacyBody attributes remain exact for the two original
  calibration bodies. Source figures, modern wardrobe and animation libraries
  have no diff from base.

Outstanding acceptance: all-seven transition and walking matrices, bound-kneel
and selected victim poses, and the separate runtime arm-fitting profile. Source
bare poses already cross hands through thighs; narrowing the garments cannot
solve that. The runtime worker owns the bounded cached fit and its acceptance.
Asset-only captures still show those known contacts. Raw strain/coverage counts
are diagnostics, not a visual pass. Angular lower robe folds remain a stylized
mesh limitation. Generated imports, diagnostic files and captures stay local.
