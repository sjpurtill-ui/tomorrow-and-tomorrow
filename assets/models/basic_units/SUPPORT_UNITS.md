# Reinforcements: cavalry, siege engineers, field artillery

Original Blender models matching the next three existing military roster IDs.
These are presentation assets; they do not unlock technology or create equipment.

| ID | Visual representation | Triangles | Bones |
| --- | --- | ---: | ---: |
| `cavalry` | Mounted lancer, saddle, reins, faction pennon | 2,922 | 19 |
| `siege_engineer` | Wheeled ballista, torsion cords, winch, bolt, operator | 2,446 | 16 |
| `field_artillery` | Wheeled cannon, recoil barrel, muzzle flash, ammunition chest, operator | 2,864 | 12 |

Each GLB includes idle (2 s), walk (1 s), attack (1.75 s), and death (2.5 s),
baked at 24 fps. Motion is in place. Walk is mounted locomotion for cavalry and
transport/wheel rotation for the equipment. The horse has articulated lower legs;
the lancer lowers the weapon during attack. Ballista attack draws the arms and
cords, turns the winch, and releases a bolt. Cannon attack includes barrel recoil,
brief muzzle flash, and crew reaction. Death leaves a held fallen/disabled pose;
crew arms settle and the equipment loses a wheel. These remain stylized first
passes, not physical simulations of riding, towing, or machine destruction.

Open `art_source/support_units/support_units.blend` to edit the models. Run
`tools/support_units_preview.tscn` in Godot (F6) to inspect them, including slow
motion. `tools/army_scale_preview.tscn` now offers Founding forces,
Reinforcements, and Mixed army rosters. Support assets use wider formation spacing.
The main close-map renderer recognizes the three new IDs in real army composition.
Each crewed piece represents aggregate personnel/equipment, not one weapon for
every soldier in the simulation.

Rebuild from the project root:

```text
blender --background --python tools/build_support_units.py
blender --background --python tools/bake_basic_unit_crowds.py -- --support
godot --headless --path . --editor --import
godot --headless --path . --script tools/verify_basic_units.gd
godot --headless --path . --script tools/verify_army_figures.gd
```

The support builder reuses the first pack's geometry helpers and material palette.
It writes separate Blender source and exports into the shared unit asset folder.
GPU crowd data is baked separately for each pack, so adding these does not replace
the first three models. Shader bounds include the tall lance, falling rider, and
released bolts. All per-figure work remains in the GPU renderer, with a shared
256-instance budget per visible army across all six types.
