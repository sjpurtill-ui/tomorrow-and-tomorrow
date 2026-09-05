# Road material readability

Base e5ff49d990bd81d6c5af0fd2fd9b5c13b2c6f0ff; branch codex/road-material-readability.

Persistent saved routes now use a dedicated fabric kind (8), preserving their authored surface color while retaining photographic luminance texture. Yard rendering is unchanged. Main approaches no longer reset their material RGB after the surface-tier palette is applied. Existing widths, alpha, topology, movement, and saves are unchanged.

76 settlement/material tests pass. Added regression creates actual routes and checks material kind, unchanged six-vertex segment budget, color distinction and existing opacity range. Inspected town-roads-before.png versus town-roads-after.png, plus road-materials.png showing all six surface tiers.

New self-terminating tools/road_material_probe.gd flattens only the QA strip geometry for material comparison; production geometry is untouched. Existing capture shutdown resource warnings persist. No player game launched.

Shared overlap: _commit_settlement_surface route-kind assignment; _settlement_fabric_material kind8 branch; _create_persistent_settlement_routes removes one RGB reset. Existing test file plus probe. Scope coordinated with integrator.
