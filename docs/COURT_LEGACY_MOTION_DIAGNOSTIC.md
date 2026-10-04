# Independent legacy-motion diagnostic

Branch `codex/court-legacy-motion-audit`, base `1c09a4e69c6176ca39e78d4d86f114bcf55c1430`.
No production scripts or assets change. The earlier tunic8mm checkpoint1f58 is
not part of this branch; replacement garments can supersede it.

Headless exporter:

```
Godot --headless --path <explicit worktree> res://tools/court_legacy_motion_audit.tscn -- --bodies=male_adult,female_old --outfits=hide,tunic,robe --label=prototype
python tools/blender/diagnose_court_legacy_motion.py reports/court_legacy_motion/prototype.jsonl --coverage
```

Use all seven body names for final coverage. Reports stay ignored. The exporter
uses the real Figure/Acting/Skeleton pipeline and currently loaded garment
provider. It records all garment vertices/triangles at seven times through
walking, sitting, kneeling, cross-legged sitting, and release back to walking.
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

No GPU process, simulation state, source body/rig or animation edits. Save
compatibility unchanged. New diagnostic files only; no shared production conflict.
