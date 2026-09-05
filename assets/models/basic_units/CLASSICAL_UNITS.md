# Classical unit prototypes

Six study-selected animated GLBs: pike phalanx, legionary infantry, war elephant,
battering ram, siege tower, and trireme. Each has idle (2 s), walk/row (1 s),
attack (1.75 s), and death/disabled (2.5 s) clips at 24 fps.

- Pike infantry lower a long pike and thrust; legionaries brace a tall shield and
  stab with a short sword. Arms use baked two-bone IK.
- The elephant has articulated legs, head, trunk, tusks, and a rider platform.
  Its attack raises the trunk and drives the head; death buckles and falls sideways.
- The covered ram pulls back and strikes. Its walking clip turns the wheels.
- The siege tower lowers a boarding ramp. The disabled clip breaks its upper
  structure and displaces a wheel.
- The trireme has a bronze ram, furled sail, and three banks of representative
  oars on each side, each rotating at its own pivot. Walk means rowing; attack is
  a short ramming surge. Disabled lists and sinks below the waterline.

These are stylized visual prototypes. The pike asset is one representative soldier;
phalanx formation tactics are not implemented by the mesh. Siege assets include a
representative operator rather than the full crew. The trireme uses 96 visible
representative oars, not a reconstruction of a particular historical vessel.
Animations do not calculate hits, wall damage, ship collisions, or casualties.

## Previews

Open `tools/classical_units_preview.tscn` for infantry and elephant. Launch with
user argument `--siege` for the ram and tower, or `--naval` for the trireme on water.
The preview has orbit, zoom, animation buttons, and slow motion.

The army-scale viewer has **Classical land forces**, with shared vertex-animation
textures for the five land types. The trireme is kept out of land formations;
fleet movement, fleet aggregation, and naval gameplay integration remain pending.
Land crowds remain capped at 256 representatives per army, with 6 m spacing for
the large classical units and extended pikes.

Editable source: `art_source/classical_units/classical_units.blend`.
Dimensions use meters; Blender Z up / -Y forward exports to Godot Y up / +Z forward.
The trireme is approximately 31 m long including its ram, requiring its own camera.
The waterline is Z=0 in Blender. Naval disabled poses intentionally go below it.

## Rebuild and verify

```text
blender --background --python tools/build_classical_units.py
blender --background --python tools/bake_basic_unit_crowds.py -- --classical
godot --headless --path . --editor --import
godot --headless --path . --script tools/verify_basic_units.gd
godot --headless --path . --script tools/verify_army_figures.gd
godot --headless --path . tests/warfare_map_runtime_probe.tscn
```

Recruitment, unlocks, equipment, and combat definitions for these new IDs remain
pending. The live combat roster still uses its existing broad types.
