# Organic town components

Source: the user-accepted `organic_towns.blend` study, Organic river market.
Four 24 m² houses and one 120 m² hall were exported as reusable components in the
originating design task. See manifest.json for dimensions, provenance and counts.

house_small.glb is a 12 m² derivative of house_medium.glb, shortened horizontally
by sqrt(0.5) while keeping full height. Rebuild with Blender in background:

`Blender --background --python tools/build_organic_small_house.py`

Metre geometry, glTF Y up and front +Z, origin at ground level. Runtime scale must
be 0.001 because the map's world unit is one kilometre. Vertex colors contain the
wall/roof/frame palette; procedural Blender noise has not been baked to textures.
The shared Godot material uses vertex colors. Scene imports generate LODs and
shadow meshes; retain the original mesh resource for identity-transform imports.
