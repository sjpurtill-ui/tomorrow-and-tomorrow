# Court and city evolution: combined quality pass

Status: final combined review in progress. This is worker work, not a delivered
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
  not AD dates. Construction knowledge bounds the available room family;
  equipment still requires the corresponding actual discoveries.
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
  additive wardrobe preserves the original body, morph, skeleton and animation
  bytes. It remains skinned geometry, not a cloth simulation.
- Camera framing uses the actual seated body height and protects the shoulders
  of officials at the outer chairs. Placement before the modal enters the scene
  tree uses local transforms, avoiding outside-tree transform errors.
- Speech placement protects its own speaker even when earlier dialogue occupies
  the space above. It does not move aside for a same-speaker line that is about
  to disappear. The constrained search also preserves an envoy's offered-object
  strip, remains stable when repeated, and skips searching when already clear.
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

- Latest broad court regression: **393/393**, thirty-one suites, no errors,
  failures, skips or orphans; process exit0.
  `artifacts/court-evolution-final-combined-tests.log`, report49.
  Includes presentation, wardrobe, etiquette, acting, motion, camera, staging,
  navigation, execution, gore, rendering budget and sound. This run includes the
  final four wall-bay corrections and sewn collars, and precedes the subsequent
  shadow, outline and hand/skirt-clearance follow-ups. Earlier report47 passed
  390 cases; it is retained as evidence rather than a final asset certification.
- Root raw validations after final wall bays and sewn collars: **16/16 rooms and
  7/7 wardrobe bundles**, preserving original body/face/rig bytes. Logs:
  `artifacts/court-evolution-final-rooms-raw.log` and
  `artifacts/court-evolution-final-wardrobe-raw.log`.
- The actual modern audience headless probe passes at both supported review
  sizes with an assertion that the active speech bubble clears its speaker.
  The reserved-offer regression first failed at x666 against a usable width580;
  the subsequent bounds correction is covered separately.
- The corrected offer bounds and stage behavior pass **41/41** with no errors,
  failures, skips or orphans; `artifacts/court-evolution-offer-bounds-fixed.log`,
  report51. This includes the forced crowded-offer regression and repeated
  constrained placement. Shadow worker **10/10** tests and four-chapter GPU
  comparison pass; see `COURT_SHADOW_QUALITY_HANDOFF.md`.
- Final combined city/architecture/provenance tests: **35/35**, no errors,
  failures, skips or orphans; report52,
  `artifacts/court-evolution-city-final-tests.log`. Worker before/after captures
  also cover all sixteen dates with unchanged plot/capacity/fallback counts.
  The corrected slab footprints allow the existing placement solver to fit a
  few more preindustrial visual representatives without changing capacity.
- Final architecture worker meshes: **192/192 chair arrivals/departures plus
  16/16 door-to-petitioner routes**, **15/15 imported room tests**, and all sixteen
  raw GLB validations pass. Latest bundle: 141,344 triangles, 13,599,776 bytes;
  every individual room stays below 12,000 triangles. Evidence paths and exact
  worker checkpoints are in `COURT_ARCHITECTURE_POLISH_HANDOFF.md`.
- Full sixteen-room reference GPU capture after the figure allocation repair
  completed with exit0 and no engine/script errors. Includes audience/room views
  and selected speech/chair-arrival sequences. Actual modal year3000 was also
  checked at 1920x1080 and 1280x720 with the original larger crowd, confirming no
  instance-buffer overflow. The latest combined visual checks are recorded below
  when complete; these earlier captures do not certify later asset changes.

Live narration/API, unrelated military/economic suites and the full campaign
simulation are outside these checks. The Compatibility renderer's known
depth-of-field warning is not an engine error. A preceding native GPU crash is
recorded in local evidence; successful subsequent captures do not establish its
cause. All GPU probes use the private-desktop runner with Dummy audio, one at a
time, and close afterward. No player/editor was launched or interrupted.

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
universality.

Generated imports, captures, logs and reports stay local and are excluded from
source commits. The integrator must import the new assets, reconcile current
main, rerun relevant combined tests, push and remotely verify main before
fast-forwarding the canonical checkout. A worker branch push does not deliver
the changes to the running game.
