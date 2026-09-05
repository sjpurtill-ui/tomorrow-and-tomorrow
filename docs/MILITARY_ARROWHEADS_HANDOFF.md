# Real military arrowheads

Base:fdb43dc. Godot runtime confirmed CylinderMesh.radial_segments=3 is clamped to4,
so the intended arrows were diamonds. Replace the two front wings and moving-army
heading symbol with an explicit24vertex triangular prism. Flat cap/side normals
avoid rounded shading. No added nodes, draw calls, new images or simulation changes.

Front wings face+X/-X toward contact; heading geometry faces local-Z and consumes
the existing heading yaw. Tests verify all4cardinal destinations, upward/downward
cap normals,24vertex budget and opposing front directions. Warfare runtimeprobe
and26presentation tests PASS. Existing headless shutdown RID warnings remain.

Captures front-real-arrowheads.png compared with front-layer-after.png show actual
triangles instead of diamonds; army-direction-arrowheads.png checks rotated terrain.
Temporary cylinder diagnostic removed. No saves/UI/mechanics/launch changes.

Shared terrain scope:new _warfare_arrowhead_mesh, heading mesh creation and front
wing mesh creation. Integrate after battle-front layering.
