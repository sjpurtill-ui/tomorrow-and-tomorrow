# Founding forces — first Blender unit pack

Three original faceted models based on the game's military roster and existing
`combat_levy.svg`, `combat_spear.svg`, and `combat_archer.svg` icons:

| Game unit ID | Equipment | Triangles |
| --- | --- | ---: |
| `levy` | Improvised stone club, brown tunic | 1,996 |
| `line_infantry` | Spear, red round shield, simple armor | 2,274 |
| `skirmisher` | Bow, nocked arrow, quiver, green tunic | 2,422 |

## Inspect and edit

Open `art_source/basic_units/basic_units.blend` in Blender. It includes three
editable meshes, 16-bone melee skeletons, an 18-bone archer skeleton, named NLA
tracks, and a lit presentation scene.
The rigs start in idle. To inspect another NLA clip, clear the active action and
unmute that track (mute the other tracks). Geometry uses rigid skin weights for a
faceted miniature style; this is a first asset pass, not a realistic character rig.

Run `tools/basic_units_preview.tscn` in Godot (F6) to inspect the imported assets.
Buttons play idle, walk, attack, and death; drag to orbit and scroll to zoom.
Attack and death play once; press a button again to replay. Idle and walk loop.
Slow Motion plays at 35% speed for inspecting the strike and collapse.

## Import contract

Each GLB includes its own mesh, materials, skeleton, and AnimationPlayer.
Units are approximately 1.8 metres tall, rooted at their feet, with +Y up and
+Z forward in Godot. The spear reaches 2.42 metres. Blender source uses Z up
and -Y forward. Apply placement to an enclosing Node3D when instancing a unit.

Clips are `idle` (2 s), `walk` (1 s), `attack` (1.75 s), and `death` (2.5 s), baked
at 24 fps. Locomotion is in place; move the enclosing node separately. Set
`Animation.loop_mode = Animation.LOOP_LINEAR` on idle and walk, as the preview
does. Attacks use weapon-specific anticipation, impact/release, and recovery:
a club overhead swing, guarded spear lunge, and bow draw/aim/release. The bowstring
deforms and a presentation arrow travels forward, then hides before the next
nocked arrow appears. This visual arrow does not implement gameplay hit detection.
Death uses recoil, knee buckling, hip/shoulder impact, and a final held pose.
Limb IK is baked into the skeleton; there are no runtime IK dependencies.
The `team_color` material is the small chest tab and can be overridden per faction.

These assets also power the shared-animation army figure renderer. At close city
zoom, nearby player armies display capped representative formations sized by
strength and composition. Main battle attack/death events are not connected yet.
See `docs/ARMY_FIGURE_SCALE.md` and run `tools/army_scale_preview.tscn` to compare
army sizes. Personnel counts remain authoritative numeric aggregates.

## Rebuild and verify

From the project root:

```text
blender --background --python tools/build_basic_units.py
godot --headless --path . --editor --import
godot --headless --path . --script tools/verify_basic_units.gd
```

Combat choreography lives in `tools/basic_unit_motion.py`. Run Blender with
`--background --python tools/audit_basic_unit_motion.py` after a build to render
six representative motion beats and record ground bounds for review.

The build uses no external assets or Python packages. `art_source/.gdignore`
keeps the Blender presentation scene out of Godot's import pipeline; only the
three GLB exports are runtime assets. `manifest.json` records budgets and clips.
The verification loads all three through Godot and checks all twelve clips change
the imported skeleton's pose. Blender and Godot preview PNGs are in `art_source/basic_units`.
