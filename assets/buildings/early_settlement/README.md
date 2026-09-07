# Early settlement assets

Eleven original, locally authored GLBs; metres, ground origin, vertex colours,
rough material, no downloaded textures or runtime image/model calls.
Rebuild with Blender 4.5:

```
Blender --background --python tools/build_early_settlement_kit.py
```

`asset-review.png` and `cultural-studies.png` are **offline Blender renders of the
authored meshes**, not screenshots of the player game.

Eight assets are connected to the early settlement renderer: carried ridge and
round shelters, rooted lean-to, round household, earthen household, rubble
household, raised store, covered workshop. Existing organic town houses and market
hall remain available for recorded compatible permanent timber construction.
The compact kit fits inside the shared placement solver's smallest reserved roof
envelope. Every runtime instance uses uniform scale .001 in kilometre terrain.

Three assets are authored studies, **not runtime unlocks**: crafted_household,
open_common_hall, enclosed_authority_hall. The halls have equal craft/material
quality and different access/enclosure. They are larger than the small-house
placement envelope and must never be inserted into that solver as small houses.
They need correctly sized public-building parcels and recorded construction-era
culture/patronage before integration. There is no assumption that centralized or
open politics is intrinsically more beautiful.

All export dimensions and mesh counts are in `manifest.json`. Its dimensions use
Blender's Z-up coordinates; GLB imports use Godot's Y-up coordinates.
