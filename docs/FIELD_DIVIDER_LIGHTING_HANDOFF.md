# Field-divider lighting

Base: 221963f. Only the cross-divider triangle order in _append_field_rows changes.
The divider basis is opposite the crop-course basis; reusing its index order made
divider normals point down. A diagnostic found 78 downward normals among 780
vertices in a smallholder field. Crop beds themselves already faced up.

Reversed only divider winding. Positions, UVs, colors, alpha, field geometry count,
simulation and saves are unchanged. Added generated-mesh normal tests for three
field patterns at three bearings. Settlement architecture and texture suites:
78 tests, no errors/failures. Actual terrain capture artifacts/field-dividers-lit.png
is visually subtle at 0.7 km, as expected for narrow field dividers; this is a
lighting correctness fix, not a redesign or claim to solve all field aliasing.

Shared file: scripts/local_terrain.gd, end of _append_field_rows. No canonical edits
or player launch. Temporary diagnostic was removed after permanent regression.
