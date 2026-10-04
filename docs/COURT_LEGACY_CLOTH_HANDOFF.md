# Additive legacy cloth repair

Status: **Asset repair ready for combined validation**; overall court release
remains HELD for the separate all-seven ordinary-pose hand fit and integration.
It is not delivered to the player.
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
- All-seven family/protected-pose sweep: `reports/legacy_all_v12_adult/` and
  `reports/legacy_all_v12_young/`, 228 views each (PIDs59968/11816, exit0,
  zero engine/script errors). Includes standing, kneel/cross-sit transitions,
  both-knee `kneel_bound` through2.4s, club/block victim clips, three dog clips
  and fire's `struggle_bundle`. Execution victim samples use adult bodies only.
  These are sampled garment reviews without props/gore or full scene staging.
  Reviewed protected poses preserve continuous sleeves, waist and leg coverage.
- Material-ID diagnostic confirmed the small old-male upper-back oval is gold
  neckline trim, not skin; an independent projected-mesh trace confirmed the
  same triangle. No tunic change was made for it.
- The sweep found an old-female hide underarm opening during club victim5.6s.
  The follow-up includes the torso-side upper-armpit triangles that the original
  arm-influence cutoff excluded. Body coverage and every other mesh primitive
  remain exact against63140339 for all seven bodies. Raw complete invariants
  pass7/7. Logs: `artifacts/legacy-hide-seam-v13-{raw,invariants}.log`.
- Hide follow-up: `reports/legacy_hide_seam_v13_{adult,young}/`, 24 private views
  total, PIDs15980/24264 exit0 without errors; standing, kneel, cross-sit,
  bound-kneel and protected club/block poses. Independent peer review confirms
  the specific underarm gap is closed without visible silhouette inflation.

Outstanding combined acceptance: the separate all-seven runtime arm-fitting
profile and its ordinary-pose transition matrix. Independent walking diagnostics
reported0 hand crossings in1,344 replacement-legacy samples; the hide seam
follow-up leaves that lower hand-contact geometry exact. Source
bare poses already cross hands through thighs; narrowing the garments cannot
solve that. The runtime worker owns the bounded cached fit and its acceptance.
Asset-only captures still show those known unfitted contacts. Raw strain/coverage
counts are diagnostics, not a visual pass. Angular lower robe folds and short
gold cape-attachment tabs remain stylized mesh limitations. Full staged execution
and continuous playback acceptance belong to the combined build. Generated
imports, diagnostic files and captures stay local.

Optional-cape coverage follow-up: branch `codex/court-hide-optional-cape`, base
`1c7d7cc0`, same isolated asset worktree. The actual-scene speech close-up found
missing shoulders when CourtStage intentionally omitted `hide_cape`. The hide
body mask had incorrectly included that optional layer. It now masks only the
always-present wrap and footwear; cape-on uses real underlying shoulder skin.
All seven bundles pass raw invariants and the new anatomical shoulder assertion
fails against the previous bundle. Exact comparison to base proves every mesh
attribute, index, morph, rig and non-hide body channel unchanged. Only 327–486
hide-mask vertices per body are restored. Logs:
`artifacts/legacy-optional-cape-{before,raw,invariants}.log`.

This checkpoint is HELD for cape-on/off GPU review and combined runtime tests;
no player-build delivery is claimed. Existing motion/contact geometry evidence
remains applicable because garment geometry and animation data are exact.
