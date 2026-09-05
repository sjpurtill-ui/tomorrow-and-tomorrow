# Route direction arrowheads

Branch `codex/route-direction-arrowheads`, base `39ceb3c`.

Army march arrows and scout route pennants now use actual triangular prisms.
Their former CylinderMesh radial_segments=3 was clamped by Godot to four sides.
Existing route placement, counts, scale, visibility and intelligence semantics
are unchanged: scout corridors remain plans, not live trackers.

Validation: warfare runtime probe PASS both headless and hidden graphical runs.
Both actual route constructors checked for 24-vertex meshes/five local arrows.
All four cardinal directions verified using stored MultiMesh transforms in the
graphical run. Dummy headless rendering returns identity MultiMesh transforms,
so direction assertions deliberately run only with a real display backend.

Hidden self-quitting `tools/route_direction_probe.gd` capture inspected:
`artifacts/route-directions.png`. Arrows point correctly; existing route ribbons
still overdraw their centers. That separate layering defect is a follow-up, not
claimed fixed here. Existing shutdown resource warnings remain.

No simulation, saves, menus or troop geometry changes. Shared local_terrain.gd
changes only replace the two route arrow mesh constructors.
