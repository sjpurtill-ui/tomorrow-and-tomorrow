# Early historical units

Six study-selected visual prototypes: slinger, javelin skirmisher, crossbow infantry,
chariot archer, horse archer, and camel cavalry. Each GLB contains a skeleton and
idle (2 s), walk (1 s), attack (1.75 s), and death/disabled (2.5 s) clips at 24 fps.
The source uses meters, Blender Z up and -Y forward; exported Godot assets face +Z.

The slinger winds up and releases a stone; javelin troops throw from an overhead
windup; crossbow and bow units draw and release a projectile. Arm motion uses baked
two-bone IK. Mounted figures have articulated animal legs. The camel uses a lateral
gait, and the chariot uses a single draft horse with turning wheels. Death clips
stagger, collapse or disable, then hold. The chariot disabled animation leaves the
horse standing and damages the cart; it represents a disabled unit.

These are stylized prototypes rather than finished historical reconstructions.
Released projectiles are short visual cues, not gameplay hit detection. Reloads
are abbreviated. Recruitment, unlocks, equipment consumption, and combat balance
for the six new IDs still need integration. They are available in asset previews
and the historical army-scale preset; existing gameplay units retain their IDs.

## Preview

- Open `tools/historical_units_preview.tscn` for the three foot units.
- Add the user argument `--mounted` for chariot, horse archer, and camel cavalry.
- Open `tools/army_scale_preview.tscn` and select **Early historical forces**.
- Use Idle, Walk, Attack, Death, slow motion, orbit, and zoom to inspect animations.

Editable source: `art_source/historical_units/historical_units.blend`.
Contact sheet: `art_source/historical_units/historical_units_preview.png`.
Asset statistics: `historical_manifest.json`.

## Rebuild

```text
blender --background --python tools/build_historical_units.py
blender --background --python tools/bake_basic_unit_crowds.py -- --historical
godot --headless --path . --editor --import
godot --headless --path . --script tools/verify_basic_units.gd
godot --headless --path . --script tools/verify_army_figures.gd
```

Crowds share meshes and baked vertex-animation textures. Figure counts remain
capped at 256 per army. Mounted formations use wider ranks; chariots use 5 m
spacing. With the medieval batch, the mixed preview supports twenty-six land types.
