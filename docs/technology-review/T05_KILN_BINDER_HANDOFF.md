# T05 kiln and binder service handoff

**Status:** READY

**Worker:** `/Users/seanpurtill/Documents/Codex/tt-t05-kiln-binder-service`  
**Branch:** `codex/t05-kiln-binder-service`  
**Base:** `644464d61181b9cf042863bd41a71a8a8addb37d`

## Behavior

Controlled Kilns now exposes a paid Maintained Controlled Kiln installation through the existing technology-operations panel. One kiln consumes 12 Stone, 6 Clay and 2 Joined Timber Components, takes 24 Crafting worker-days to commission, and then consumes 0.5 Timber per operating day. Its finite daily firing service is shared by workshop production.

Qualified fired clay conduits consume one kiln-heat unit per batch. Quicklime consumes 1.5 units. Their old per-recipe Timber charge was removed because the operating kiln now owns and records fuel once. Existing forming, limestone, water, sand, tooling and workshop labor costs remain physical.

The kiln discovery's broad craft effects operate only while installed kiln capacity is fueled and staffed. Lime Burning effects require actual Quicklime, Slaked Lime or Building Mortar stock. Lime Mortar's passive settlement effects require a maintained lime-masonry household plot; the existing mortar stock remains the direct paid input for new construction and repair.

Rival settlement investment now commissions kiln capital before opening quicklime or fired-conduit production. If capital components are missing, the existing supply planner is used first.

## Compatibility

The installation uses the existing validated `technology_operations` ledger, so no new save schema is added. Older saves know the discovery but receive no free kiln. Existing quicklime and fired-conduit production lines remain saved; they wait for local kiln service instead of silently burning recipe-local fuel.

## Validation

- `tests/test_kiln_binder_service.gd`: **4/4**
- `tests/test_technology_operations.gd`: **16/16**
- `tests/test_building_material_operations.gd`: **11/11**
- `tests/test_water_conveyance_operations.gd`: **14/14**

All reported suites completed with zero errors, failures, flaky cases, skips or orphans. The standard headless remote-port warning is unchanged.

## Limits and next work

Technology installations currently belong to the primary-city operations ledger. Other cities can receive fired products through the established city shipment system but do not yet commission their own kiln plant. An enabled kiln maintains a daily firing service and consumes its fuel even if the day's capacity is unused; the existing Pause control prevents that expenditure on following days.

Bounded graded roads and irrigation delivery remain the final operating-network packet before hidden T05 transformation evaluation. No player game was launched from this worktree.
