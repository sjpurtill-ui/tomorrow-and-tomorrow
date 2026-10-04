# Court and city evolution: combined quality pass

Status: READY for the designated integrator. This is worker work, not a delivered
player build. Branch `codex/court-evolution-polish`, worktree
`C:/Users/sjpur/.codex/worktrees/court-motion/TomorrowandTomorrow`.
Base `ad0c8220e8716a6a96ba76b24b36f0e550799b2b` combines the earlier interiors
checkpoint `b0ee8709b8a731c2c786421f1fc715c12b26aa0d` with integrated main
`17f1524c3e7b6d0a02c1ef3690d72a4e7e5b7454`.
During final review the worker branch also merged current integrated main
`ec537b74fa82253806dc3cb5ee2ce9bd718ba81d` without conflicts (worker merge
`e5c5a8b8`). This brings in the intervening standing/covert work; the canonical
checkout was not changed by this task.

This branch includes the preceding court era presentation, wardrobe and interior
deliveries. Review it as a combined change against current main; do not apply the
same earlier worker commits again. Historical handoffs describe their own tested
checkpoints; the evidence below concerns this subsequent quality pass.

## Player-visible behavior

- Sixteen authored court designs cover elapsed years 0 through 3000, changing
  every 200 years. Ancient courtyards, colonnades and record rooms lead into timber
  and stone medieval great halls, a chancery, secretariat, cabinet, ministerial
  and industrial offices, and twentieth-century/contemporary conference rooms.
  These are game-year milestones following the existing nonlinear chronology,
  not AD dates. Known construction or established civic institutions bound the
  available room family; equipment still requires the corresponding actual
  discoveries. Societies that lack a later room family renew their supported
  layout through entrance/service-side and modest width variation.
- The second architecture pass replaces repeated large windows and empty rear
  walls with distinct openings, structural bays, work areas and record storage.
  Indoor hearths have stone bases. Desks, tables and chairs retain navigable
  approaches and exits. Displays do not obscure the faces across a meeting table.
  Cornices, wall plaques, paneling and windows no longer intersect in the four
  rooms flagged during actual rendering. All sixteen complete mark dictionaries
  remain identical to the previous interior baseline.
- Civic etiquette and textile capabilities are separate. Administrative knowledge
  alone does not create woven clothes, fitted cuts or dyes. Formal officers and
  visitors can wear different supported clothes; business coats have stable
  individual variation. Foreign visitors retain their own society's presentation.
  Identity, face, rig, age, sex and civic ownership remain unchanged.
- Later garments have continuous shoulder/neck boundaries, joined cuffs and side
  seams, fitted belts and stronger waist anchoring during seated movement. The
  lapels, cravats and ties now follow the actual jacket surface and weights;
  sparse floating panels were replaced after their intersections were rendered.
  Only those sixty attachments changed in that follow-up, preserving every
  other mesh in the seven additive bundles.
  The additive wardrobe preserves the original body, morph, skeleton and animation
  bytes. It remains skinned geometry, not a cloth simulation.
- All seven bodies now have additive hide, tunic and robe replacements. Joined
  sleeves, matched inner facings, separately weighted leg panels, fitted waists
  and sewn cape shoulders remove the torn sleeve/hem and shoulder overlap cases
  found in deep poses. Original lengths and fullness remain; the rejected
  narrower skirt is excluded. The provider reuses existing nodes and safely
  restores original resources when redressing or when a bundle is unavailable.
- The final actual-court close-up exposed missing shoulders when the stage
  omitted an optional hide cape. Hide skin coverage now follows only the
  always-present wrap and shoes. All seven bundles preserve every geometry,
  rig, morph and other color-channel value; only the hide coverage mask changes.
  Both cape-less rendering modes and cape redressing have regression coverage.
- Ordinary standing and cross-legged sitting have fitted arm keys for each body.
  Hands move beside the knees during descent, then settle near/on the lap.
  The source clips, timing, root, legs, head, walking resources, kneeling,
  prop-specific gestures and execution performances remain unchanged. Brief
  shallow cloth contact is retained where lifting hands farther looks unnatural.
- Camera framing uses the actual seated body height and protects the shoulders
  of officials at the outer chairs. Placement before the modal enters the scene
  tree uses local transforms, avoiding outside-tree transform errors.
- Speech placement protects its own speaker even when earlier dialogue occupies
  the space above. It does not move aside for a same-speaker line that is about
  to disappear. The constrained search also preserves an envoy's offered-object
  strip, remains stable when repeated, and skips searching when already clear.
  Above-head placement also clears seated listeners behind the speaker. The
  actual modern modal exposed that case, which now has a failing-before,
  passing-after regression and actual-modal assertions for every cast face.
- Administrative rooms use three bounded adult support extras. Existing named
  officials and petitioners are preserved; background extras cannot claim the
  officials' authored chairs. Indoor ambient acting no longer stamps against the
  cold, warms hands or swats summer flies in enclosed offices.
- A real modern audience exposed shader-instance exhaustion. Hidden original
  garment parts no longer retain render allocations after merged meshes own the
  visible figure. Shader-backed meshes fall from 24 to 6 per merged business
  figure, without increasing renderer limits or replacing the acting library.
- Court-only shadow cascades now retain detail behind a seated speaker at both
  quality levels. Straight window-sill edge error fell from 6.40px RMS to 0.82px
  high / 0.76px low in the same-camera comparison, with retained contrast. The
  outdoor camp and medieval/modern wider views were also reviewed. This costs
  four/two shadow passes instead of two/one; the automatic downgrade remains.
- Figure outlines retain their original screen-space width but sit behind the
  painted surface at concave folds. This removes false black chest/armpit slits
  without thinning shoulder silhouettes, adding materials or altering meshes.
- Walking upper arms are fitted and sampled across all seven clothing styles
  and all seven bodies.
  Each player owns two fitted walking clips; redressing updates only upper-arm
  rotation keys in place. Timing, speed, pause/queue state, root and lower-body
  motion remain unchanged. Final calibration retains the full validated skirt
  geometry; a narrower-skirt candidate was rejected after seated pixel review.
- City population thresholds no longer shrink the visible settlement extent.
  Supported parcels beyond the detailed geometry budget can retain bounded roof
  proxies, subject to full-footprint road, parcel, land, slope and overlap checks.
  Modern architecture closes all eight building families with flat/parapet roofs;
  a separate normal-based ink outline prevents thin roof undersides blackening
  their tops. See `CITY_EVOLUTION_VISUAL_QA.md` for precise scope and evidence.
- Roof materials also follow recorded construction. Stone walls alone no longer
  produce fired tiles, and building age alone no longer produces chimneys. Old
  records use conservative fallbacks; supported tiles and installed chimneys
  remain available. No construction records or capabilities are granted.

The retained execution set is unchanged: club, fire, dogs and beheading. Previous
shortest-turn, foot-speed and storm-out corrections remain in the branch. This
pass does not introduce a new execution method or alter the adjudication ledger.

## What the progression review establishes

`tests/court_eval/progression_fixture.gd` builds a deterministic reference from
live catalogue dates and completed prerequisite chains. Its sixteen snapshots
exercise the same knowledge-driven room, dress and etiquette policies. It never
grants discoveries to a campaign. Captures are explicitly diagnostic worlds.

This establishes that supported presentation can evolve through the intended
periods. It does **not** establish that every economic campaign reaches those
discoveries on that schedule, that every culture follows one architectural
history, or that a complete 3000-year simulation has been played and reviewed.
The city fixture is prepared visual history with live conversion/rendering, not
demographic simulation. City art has broader building families; the sixteen
distinct 200-year room designs are a court feature, not sixteen city styles.

## Verification at the combined checkpoint

The baseline implementation at `12cd0f90` passes **409/409 court tests across
35 suites**, with no errors, failures, skips or orphans; exit 0, report 59,
`artifacts/court-evolution-release-tests.log`. This includes the final seven-body
legacy assets and ordinary-pose profiles, latest main, room/etiquette policies,
actual-mesh routes, camera/speech, acting, motion, rendering budget, sound and the
retained execution set. The sixteen-room renderer completed 96 frames (private
PID 38632, exit 0), but its close-up review exposed an optional-cape masking bug:
cape-less early characters lost visible shoulder skin. The new regression at
`a65c0af2` reproduces 14 failures across seven bodies and both rendering modes
(report 60, Godot exit 100, `artifacts/court-cape-baseline-tests.log`). Asset fix
`28fa5d27` (worker source `8a2e8284`) makes that regression pass. Its fresh raw
validation is 7/7 and its headless import exits 0 without engine/script errors
(`artifacts/court-cape-fixed-raw.log`, `court-cape-fixed-import.log`). Full
combined validation at `28fa5d27` now passes **411/411 court tests across 36
suites**, with zero errors, failures, skips or orphans (Godot exit 0, report 61,
3m 38s, `artifacts/court-evolution-final-cape-tests.log`). An independent focused
cape/provider/pose/render-budget run passes 14/14 across four suites.

The final renderer run at `9686151c` (same implementation as `28fa5d27`, plus the
regression handoff) passes all 16 chapters and refreshes all 96 frames. Private
PID 65268 exits 0 without engine/script errors:
`artifacts/court-evolution-final-cape-gpu-3.log`. The early cape-less speaker now
has continuous shoulders in the actual court close-up; the early cast with
worn capes and the medieval close-up are also visually accepted. The final room
comparison is `reports/court_evolution_reference/room-contact-sheet.png`.
Before/after detail is retained as `cape-omission-before.png` and
`cape-omission-after.png` in that same folder.

The final optional-cape asset review captures 32 images across all seven bodies,
cape on/off, standing/seated speech, full kneeling and cross-legged sitting,
at front and side angles. Corrected private probes 50972 and 61680 exit 0 without
engine/script errors. Root reviewed 16 full-resolution images (eight per
cohort), covering every body, pose and cape state: continuous exposed shoulders,
with no new skin-through-cape blocker in those samples. Evidence is in the asset
worktree's `reports/legacy_optional_cape/{adults,young}` and
`artifacts/legacy-optional-cape-adults.log`,
`artifacts/legacy-optional-cape-young-final.log`. These snapshots verify the mask
change; final fitted-arm acceptance remains the separate combined pose evidence
below. The first probe, PID 14780, had a fixture-only `person_name` assignment
error; it was closed, the local fixture corrected to the actual metadata API,
and none of that failed run was accepted. The earlier HELD mask-checkpoint
caveat is superseded by these pixels and the passing combined runtime suite.

- The seven final legacy bundles pass raw body/face/rig preservation checks and
  complete 21-outfit validation: `artifacts/court-legacy-final-raw.log`. Final
  Godot import exits 0 without engine/script errors:
  `artifacts/court-legacy-final-import.log`. Original later-wardrobe front-layer
  validation is also 7/7 (`court-evolution-final-front-layers-raw.log`); unchanged
  final room geometry is 16/16 (`court-evolution-final-rooms-raw.log`).
- New legacy walking geometry has a fresh **1,344 sampled poses with zero
  hand/cloth crossings**. The earlier 3,136-pose result included the unchanged
  later wardrobe and original legacy meshes; it is not substituted for the fresh
  replacement-asset result. Source walking tests preserve clip time, rate,
  pause/queue state and non-arm tracks.
- Ordinary-pose review captured **428 frames across all seven bodies and seven
  outfits**. Independent targeted review inspected 25 final full-resolution
  samples covering every body and outfit, descent, held poses and recovery.
  The primary CPU audit finds **zero bare-body crossings in 2,016 poses**.
  Cloth edge/rest contacts remain **380/2,016**; these are documented rather than
  called collision-free. A second ambient identity adds 336 samples, with only
  two submillimetre held knee-rest contacts and none while standing/descending.
- Asset review separately captured 456 full-family/protected-pose frames and 24
  final hide-underarm seam checks. Bound kneeling and selected adult execution
  poses are included. Faces, rigs, source animations and source-body bytes remain
  exact. Evidence and accepted/rejected scope are in
  `COURT_LEGACY_CLOTH_HANDOFF.md`, `COURT_POSE_CLEARANCE_HANDOFF.md` and
  `COURT_LEGACY_MOTION_DIAGNOSTIC.md`.
- Final city/architecture/provenance tests pass **35/35**, report 52,
  `artifacts/court-evolution-city-final-tests.log`. The final roof provenance
  swatch is visually accepted, private PID 51960 exit 0/no errors. This exercises
  timber, slab, fired tile and recorded installed chimney variants.
- Actual imported room routes pass **192 chair arrivals/departures and 16
  door-to-petitioner routes**; all 16 mark dictionaries are preserved. Rooms total
  141,344 triangles/13,599,776 bytes, each below 12,000 triangles. See
  `COURT_ARCHITECTURE_POLISH_HANDOFF.md` for the exact geometry checkpoint.
- The speech/listener regression fails before the correction and passes after.
  Its 60-case stage/speech run and actual modern modal at 1920x1080/1280x720 pass;
  private PID 7212 exited 0. Final actual-modal checks at years 1600 and 3000 also
  pass at both resolutions against `12cd0f90`, with faces and framing visually
  accepted: private PIDs 57488 and 71936, exit 0. Logs are
  `artifacts/court-evolution-release-modal-1600-2.log` and
  `artifacts/court-evolution-release-modal-3000.log`.

The small tunic walking-only checkpoint `1f58e1f0` remains excluded; the complete
additive legacy replacement supersedes it. Earlier narrowed-skirt candidates,
body-hiding experiments and cape-lining experiments are excluded. Historical
handoffs retain their earlier counts; the combined 411-case run above supersedes
those earlier court-suite checkpoints.

Live narration/API, unrelated military/economic suites and the full campaign
simulation are outside these checks. The Compatibility renderer's known
depth-of-field warning is not an engine error. A preceding native GPU crash is
recorded in local evidence. Final capture startup attempts PIDs 18384, 80356,
71044 and 40272 also exited with native code 3221226505 before logging OpenGL initialization;
their bounded retries completed successfully. Those successes do not establish
the failures' cause. All GPU probes use the private-desktop runner with Dummy
audio, one at a time, and close afterward. No player or interactive editor was
launched or interrupted.

## Integration and limits

Save compatible: no save schema, population ledger, discovery grant, government
authority or consequence calculation changes. Existing saves derive visuals from
their elapsed time and known practices. Actor counts remain bounded.

Shared integration files include `scripts/local_terrain.gd` (only the extent and
bounded fallback geometry paths), court stage/set/camera/director/figure scripts,
presentation policy, civic-stage presentation, audience modal, acting, execution
staging, paths, sound and the court/architecture shaders. Preserve newer main
changes when resolving these files. `project.godot`, game state, discovery system,
military campaign and save-system implementations are unchanged by this branch.

The strict wardrobe motion audit still reports deep-pose cloth deformation;
neither its thresholds nor failures are hidden. Geometry topology changes also
change which edges the sampled audit sees, so flag-count changes alone are not a
quality guarantee. Final counts and pixel review belong with the final wardrobe
checkpoint. This pass makes no claim of perfect simulated cloth or historical
universality. Angular lower robe folds and small gold cape attachment tabs
remain visible parts of the stylized garments. Sampled motion checks do not
cover every continuous frame or procedural mood combination.

Generated imports, captures, logs and reports stay local and are excluded from
source commits. The integrator must import the new assets, reconcile current
main, rerun relevant combined tests, push and remotely verify main before
fast-forwarding the canonical checkout. A worker branch push does not deliver
the changes to the running game.
