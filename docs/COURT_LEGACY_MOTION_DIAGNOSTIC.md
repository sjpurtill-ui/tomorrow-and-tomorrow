# Independent legacy-motion diagnostic

Branch `codex/court-legacy-motion-audit`, base `1c09a4e69c6176ca39e78d4d86f114bcf55c1430`.
No production scripts or assets change. The earlier tunic8mm checkpoint1f58 is
not part of this branch; replacement garments can supersede it.

Headless exporter:

```
Godot --headless --path <explicit worktree> res://tools/court_legacy_motion_audit.tscn -- --bodies=male_adult,female_old --outfits=hide,tunic,robe --label=prototype
python tools/blender/diagnose_court_legacy_motion.py reports/court_legacy_motion/prototype.jsonl --coverage --hands
```

Use all seven body names for final coverage. Reports stay ignored. The exporter
uses the real Figure/Acting/Skeleton pipeline and currently loaded garment
provider. It records all garment vertices/triangles at seven times through
standing, standing speech, walking, sitting, kneeling, cross-legged sitting, and
release back to walking. `--clips=stand,stand_talk` can isolate idle hand fit.
The release cases deliberately stress the normal acting fade rather than
pretending the garment only needs to fit a held final pose.

The analyzer measures every unique cloth edge, distinguishing large extension
(>40mm, >2.6x on rest edges>4mm) from tiny clipped triangles. It also checks
newly hidden skin plus a bounded sample of retained hidden skin from two viewing
angles: the original full body must be visible from that direction and actual
cloth must lie between it and the camera. Open vents therefore require visible
skin, not expanded masks. A report is diagnostic evidence requiring pixel review,
not proof that every flagged sample is a player-visible hole or that every
unflagged garment is beautiful. The cameras are representative, not exhaustive.
The optional hand check intersects every hand triangle against the lower garment
surface in both directions. It excludes the intentional wrist/cuff join and
reports actual crossings separately from cloth strain. It does not certify
clearance of an entirely enclosed hand; pixel review remains necessary.
Body position matching catches accidentally replaced geometry; the provider and
asset preservation tests remain responsible for all attributes, morphs and rig.

Validation: Python ray/vent/edge controls3/3; Godot parser success; original
baseline210poses and49transition-control poses exported/analyzed with no engine
errors. Original baseline on male adult/female old: kneeling robe-body edges
extend~139mm, robe trim~130mm; older female tunic body~87mm, trim~93mm. Hide's
largest~157mm extension is its soft cape, which needs visual classification;
its wrap reaches~68mm during cross-sitting. Hidden-skin cover diagnostics also
flag the inherited deep poses and their recovery. These are baseline findings,
not failures introduced by replacement assets.

Corrected two-body prototype `9d36fa9a` is held, not accepted: 98 deep/recovery
samples show old-female crossed-leg panel edges extending up to57mm and male
kneeling waist edges up to51mm. The separate 128-pose walking clearance check
finds no crossings, while the new idle check reproduces crossings in all14
standing samples across the two bodies (standing speech has none). This is why
walking alone cannot certify a replacement garment. Original all-body baseline
contains1,029 poses. Generated evidence stays in ignored reports and artifacts.

`--bare-hands` additionally compares those hand triangles with the unchanged
body's hip/leg triangles at the same poses. This isolates an inherited pose
intrusion from garment fit. At seven samples each through stand and cross-sit,
the old-female body has crossings in7/7 and7/7; the male adult in2/7 and6/7.
At cross-sit0.633s there are41male and119old-female crossings. These are actual
segment/triangle crossings, excluding tangency, not a distance threshold.
Narrowing a garment inside the bare thigh cannot provide an acceptable remedy.
Source body positions are still exact; provider preservation tests establish
unchanged weights/rig/morphs. No pose or production changes are made here.

For independent pose calibration, `--samples=24` covers each complete base loop
or at least 1.6 seconds of an acting transition. `--profiles=res://artifacts/profiles.json`
loads named maps of `CourtPoseClearance.overrides`, before creating each figure.
For example, `{"trial":{"female_old":{"stand":6,"sit_cross":[[0,6],[0.65,12],[1.6,4]]}}}`.
Each profile gets its own suffixed report, and the override is cleared afterward.
Include `stance_cross` when checking the separate held crossed-leg idle clip.
This fixture consumes the runtime helper; it does not modify shared clips or
carry a competing implementation of the arm correction.

No GPU process, simulation state, source body/rig or animation edits. Save
compatibility unchanged. New diagnostic files only; no shared production conflict.

Dense samples now omit repeated 30 Hz poses (64 requested samples over a 1.6 s
transition produce 49 distinct records). Release warm-up uses the actual clip
duration, including the full 2.5 s kneel. Invalid profile JSON exits with an
error instead of leaving an idle fixture. Negative flex trials also print the
minimum anatomical elbow bend at the exact source keys; ext12's two prototype
bodies remain more than 6 degrees short of straight.

The ray diagnostic uses conservative perspective bounds to omit triangles that
cannot meet the requested rays. A deterministic random control compares this
optimization with the original complete triangle scan, including cameras inside
the geometry and triangles crossing the camera plane. Python controls: 4/4.

The two-body ext12 candidate removes sampled bare-body hand crossings. Older
female cloth still crosses the inner hand edge briefly during descent, around
0.73–0.97 s. Independent front/side renders show the wrist, palm and fingers
remaining visible; this is a substantial improvement over forearm burial, not a
zero-collision claim. Local six-direction interior sampling estimates typical
overlap of 3–6 mm and a sampled maximum near 13 mm, falling below 2.4 mm at 0.93 s
and 0.2 mm at 0.97 s. Keep visual acceptance separate from numerical counts.
Expanded replacement meshes require fresh walking and ordinary-pose checks;
earlier walking counts against the inherited legacy meshes do not certify them.

Pose calibration now gives each figure the stable identity
`legacy_motion_<variant>` before Acting binds, and recreates the ordinary acting
state before each clip. Auto node names otherwise change breathing/weight-shift
seeds when a body list changes; earlier results are real samples but were not
strict angle-only comparisons. A live order-control export reversed both the
body and clip lists: all eight shared poses had exactly equal body and cloth
vertices. `--identity=legacy_motion_alternate` requests a second deterministic
ambient identity for the final variation check.

`--times=0.8,8.7` requests exact diagnostic moments (rounded to the 30 Hz step).
Any authored Acting clip can be inspected, including protected execution poses,
without fitting or changing that clip. One such sample traced the gold-looking
male-old shoulder oval in the block pose to `tunic_trim`, with the original skin
behind it; it was not a skin breakthrough. The seven-body replacement walking
sweep on asset checkpoint63140339 completed all1,344 samples with zero crossings.
