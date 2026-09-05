# Medieval unit prototypes

Six study-selected visual prototypes with idle (2 s), walk/transport (1 s), attack
(1.75 s), and death/disabled (2.5 s) clips at 24 fps:

| Asset ID | Representation | Attack |
| --- | --- | --- |
| armored_foot | Enclosed helmet, plate armor, sword, heater shield | Windup, downward sword strike, recovery |
| pavise_crossbowman | Crossbow and tall painted pavise | Draw/release, duck behind shield, recover |
| longbowman | Longer bow stave, hood, quiver | Draw, loose, recover |
| counterweight_trebuchet | A-frame, hinged weight, sling, winch | Falling weight drives arm; stone leaves sling |
| hand_cannon_team | Short metal barrel on a wooden tiller, ignition match | Ignition gesture, flash, smoke, recoil |
| bombard | Large hooped barrel on a timber bed | Flash, smoke, barrel recoil |

These are stylized prototypes rather than exact historical reconstructions.
Human arms use baked two-bone IK. Projectile flight, powder smoke, and impacts
are visual cues; damage, ammunition, reload timing, and siege targeting remain
gameplay responsibilities. The trebuchet attack finishes in the released pose;
returning to idle resets it. Its transport clip uses a simplified wheeled carriage,
not a simulation of historical dismantling and assembly. Crew models represent
the unit and do not reproduce the full personnel requirement.

## Previews

Open `tools/medieval_units_preview.tscn` for the three infantry models. Add the user
argument `--siege` for trebuchet, hand cannon, and bombard. Use animation buttons,
slow motion, drag to orbit, and scroll to zoom.

The army-scale viewer now has a **Medieval forces** preset. All six models have
shared vertex-animation textures. Army size still changes representative counts,
not individual model scale, and is capped at 256 figures per army. Trebuchets use
9 m rank spacing. The preview increases separation between armies for larger
formation footprints.

Editable source: `art_source/medieval_units/medieval_units.blend`.
Source coordinates are meters, Z up / -Y forward; Godot export is Y up / +Z forward.
Statistics and clip durations are in `medieval_manifest.json`.

## Rebuild and verify

```text
blender --background --python tools/build_medieval_units.py
blender --background --python tools/bake_basic_unit_crowds.py -- --medieval
godot --headless --path . --editor --import
godot --headless --path . --script tools/verify_basic_units.gd
godot --headless --path . --script tools/verify_army_figures.gd
godot --headless --path . tests/warfare_map_runtime_probe.tscn
```

The checks cover imported clips, settled death holds, projectile reset, counterweight
drop, gun flash reset, crowd budgets, texture coordinates, and map regressions.
Recruitment, equipment, unlocks, and combat definitions for the new IDs remain pending.
