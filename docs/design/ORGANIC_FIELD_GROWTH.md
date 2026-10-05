# Organic field growth

Validated runtime and capture harness: `e80985d81dbde13d14b02e9f52d1eea4a470d504`.
Worker source: `eba1a2a69412055884d3988dbc0275df9520857d`.

Fields formerly grew beside previous holdings along a common soil bearing.
Four-corner strips and area-equivalent-circle spacing produced long chains and
could allow the actual polygons to overlap. Growth now samples asymmetric local
patches and nearby gaps, rewards infill, and charges for distance from the town
and patch. Cut corners, taper and occasional bent edges vary parcel outlines.
Actual polygon intersection and boundary clearance prevent overlaps; terrain
samples cover edges and interiors as well as the center. The seeded generator,
72-field bound, discovery gates and food-labor authority remain intact.

## Existing settlements

Optional `field_geometry_version=2` lives in existing plot dictionaries; no
top-level save-schema change is needed. On a morphology update with real terrain
callbacks, the model stages a complete correction for compatible legacy
`hand_cultivated_clearance` fields. It retains IDs, seeds, area, crop and seasonal
state, workers, condition and history. Only polygon/centroid/version and dedicated
field-track points change. It runs before the idle-month gate, including when
the town already has enough fields. Later growth does not move corrected fields.

Archaeological, manually authored and unsupported oversized fields remain.
Shared or unchanged access paths pin dependent fields transitively. If a complete
terrain-valid layout cannot be found, no partial correction is committed; retry
is throttled by month and morphology revision. This is deliberately conservative:
not every old rectangle is promised to move.

## Acceptance

- 78/78 tests pass across `test_organic_field_growth`, `test_settlement_model`,
  `test_settlement_ground_tiles` and `test_settlement_grounds`, with no errors,
  failures, skips or orphans. Combined runtime: 15 seconds.
- New tests cover three-seed compactness/infill, exact polygon nonintersection,
  deterministic geometry, terrain edges/interior lakes/cliffs, fixed old holdings,
  legacy state/area/route preservation, idle-cap migration, atomic failure,
  fresh-callback retry throttling, route pinning and the 72-field limit.
- Private GPU probes use the actual map renderer. The saved checkpoint had three
  fields: one corrected in 9.719 ms, two remained pinned, and total cultivated
  area stayed exactly 0.14883044534277 ha. Comparing all nongeometry properties
  found no changed farm metadata. Before/after captures cover 0.8 and 2.4 km.
- A fresh terrain fixture generated all 24 requested fields in 268.854 ms and
  rendered at 0.4 and 0.8 km. Visual review shows grouped, varied parcels rather
  than the former narrow chain. Woodland obscures some parcels in this seed;
  forest-canopy clearing is not changed by this work.
- An additional open-terrain fixture used the saved checkpoint plus 24 new
  fields (27 total). All 24 generated in 317.478 ms; 0.4 and 0.8 km captures
  show several adjacent groups, varied broad parcels and the two retained
  narrow path-anchored holdings. All four successful GPU probes exited normally
  with no engine/script errors; the player's existing process was untouched.

Reproduce with `tests/map_art_capture.tscn` through
`tools/run_isolated_gpu_probe.ps1` on a private desktop with Dummy audio. Use a
private `override.cfg` user directory, optionally containing a copy of a save:

```
--saved --repair-fields --topdown --sizes=0.8,2.4 --sky=clear --hide-ui
--fields=24 --topdown --sizes=0.4,0.8 --sky=clear --hide-ui
--saved --repair-fields --fields=24 --topdown --sizes=0.4,0.8 --sky=clear --hide-ui
```

The capture does not write saves. Generated captures, logs, imports, reports and
the private user-directory override are excluded from commits. Validation left
the player process undisturbed; that session subsequently exited independently.
The canonical launcher loads the update, and resumed simulation applies the
integrated correction where eligible.
