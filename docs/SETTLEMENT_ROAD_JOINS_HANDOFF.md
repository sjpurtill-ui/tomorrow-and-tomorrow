# Settlement road joins

Base: edbb7ca. Persistent route quads now share mitered cross-sections at bends.
The join offset is capped at twice the half-width to bound acute-corner spikes.
Collapsed consecutive points are ignored in a render-only copy. Saved routes,
movement paths, materials, surface tiers and widths are unchanged.

Tests:79 architecture cases PASS, including straight/90degree/near-reversal joins,
finite offset bound, shared actual mesh vertices, duplicates and no save mutation.
Still6vertices per rendered segment, oneexisting route batch, no extra draw calls.
Exact U-turns use the incoming normal; self-crossing routes are not remeshed as
topological road junctions by this pass.

Extended tools/road_material_probe.gd with optional --bends and --output. Captures
road-joins-before.png vs road-joins-after.png show contiguous corners across all6
surface tiers; town-road-joins.png checks actual terrain. QA captures self-quit.

Shared terrain scope: _settlement_route_join_offset and
_create_persistent_settlement_routes. No canonical edits or player launch.
