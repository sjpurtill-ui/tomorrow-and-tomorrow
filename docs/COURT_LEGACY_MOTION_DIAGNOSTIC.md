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

No GPU process, simulation state, source body/rig or animation edits. Save
compatibility unchanged. New diagnostic files only; no shared production conflict.
