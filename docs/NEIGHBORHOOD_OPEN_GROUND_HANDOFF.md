# Neighborhood open-ground dressing

Base:0c3a2b9. Shader-only dressing of the existing unoccupied-block garden area:
world-anchored canopy mottling, restrained worn access on a seeded subset, stronger
but earth-compatible vegetation tone. Pixel-footprint filtering averages small
details at distance. No new park/tree entities, mesh, texture or simulation change.

Condition guard limits dressing to intact states0–5. Existing roof masks, layouts,
condition mapping, damage scars and destruction record remain unchanged. Comparing
the damaged and destroyed panel interiors in neighborhood-conditions.png against
neighborhood-open-ground-final.png returned exactly0 changedpixels in each.
79 architecturetests PASS, including shaderguard/filter assertions and existing
condition semantics. The test sheet is the actual production shader, not concept art.

tools/aerial_neighborhood_probe.gd now accepts optional sanitized --output filename.
No canonical edits/player launch. Shared local_terrain.gd scope: garden_tone block
within _settlement_fabric_material kind5 only. Save-compatible.
