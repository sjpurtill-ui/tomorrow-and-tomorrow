# Opening durable construction integration handoff

## Scope

This wave closes the T04 Framed Construction operating gap. The discovery still follows the reviewed branch rule requiring both Joinery and Timber Seasoning, but knowledge alone no longer grants settlement-wide housing, construction, or resilience effects. The live catalog remains 883 discoveries.

## Physical construction path

- Framed Construction permits a Framed Hall only after Lean-to Shelters and an Open Work Area exist.
- The project requires Construction, Crafting, and Logistics labor and consumes a real stock of Joined Timber Components plus structural timber, roofing fiber, and clay infill.
- Fiber-heavy and stone-infill material routes remain available, but every route requires fitted joined components and timber framing.
- Completion records a paid `timber_frame_hall` building event and converts the inherited communal hearth plot in place. The plot keeps its persistent geometry and enters the existing condition, damage, repair, and history systems.

## Operating effects

- Framed Construction's housing output, construction rate, and disaster resilience scale with the best maintained local Framed Hall and population-relative effective Construction staffing.
- Knowledge without a completed hall has zero operating effect.
- A damaged hall provides proportionally reduced effects. A vacant, ruined, reclaimed, or unfinished hall provides none.
- Withdrawing Construction staff suspends the effects while retaining the discovery and physical building.
- The discovery panel explains the material project and reports current local operating coverage.

## Compatibility and limits

- Existing saves remain structurally compatible because the project uses the existing `settlement_projects`, `settlement_completed`, `building_ledger`, and persistent plot records.
- Saves that already know Framed Construction retain the knowledge, but must complete and staff a Framed Hall before its passive bonuses resume.
- This wave establishes one settlement-scale demonstration hall. Later building-envelope discoveries such as thatching, wattle-and-daub, tiles, bracing, and trusses remain separate reviewed waves rather than being bundled into the frame itself.

## Validation

- `test_opening_framed_construction.gd`: 5/5 passed.
- `test_opening_storage.gd`: 4/4 passed.
- `test_settlement_model.gd`: 43/43 passed.
- The GdUnit launcher emits its existing invalid remote-debug port warning before successful execution.

## Integration notes

- Shared hotspots touched: `discovery_system.gd` and `settlement_model.gd`.
- No player game was launched from the worker checkout.
