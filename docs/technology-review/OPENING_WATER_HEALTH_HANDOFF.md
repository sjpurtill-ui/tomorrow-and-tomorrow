# Opening water and health integration handoff

## Scope

This wave makes Wound Cleaning and Clean-Water Practice daily local services backed by the same finite freshwater flow used for drinking. The live catalog remains 883 discoveries.

## Operating model

- Drinking remains the first claim on water at one unit per resident per day.
- At full adoption, Wound Cleaning requests an additional 0.015 units per resident and Clean-Water Practice requests 0.05 units per resident. Partial adoption requests the proportional amount.
- Water collection, conveyance, storage, and consumption use one conserved stock. Practice water is allocated only after drinking; shortage can reduce or eliminate operating coverage without erasing knowledge.
- Each settlement records its own daily practice demand, water used, and coverage. The discoveries' health, disease, maternal, neonatal, and labor effects scale with adoption and that local coverage.
- Discovery descriptions expose the physical contract and current operating coverage. Learning either practice without supplying its water grants no passive benefit.

## Compatibility

- Existing `required_today` and `intake_ratio` retain their drinking-water meanings. `consumed_today` remains total physical water consumed, preserving the existing collection = consumption + storage accounting contract.
- Settlements without either practice keep their prior water demand and behavior.
- No save schema changed. New metrics are fields in the existing open water-metrics and history dictionaries; older saves begin with zero operating coverage until the next resource-flow day.
- Later clinical care remains separate and unchanged.

## Validation

- `test_opening_water_health.gd`: 4/4 passed.
- `test_water_conveyance_operations.gd`: 14/14 passed, including stock conservation, secondary-city isolation, and save restoration.
- The GdUnit launcher emits its existing invalid remote-debug port warning before successful execution.

## Integration notes

- Shared hotspots touched: `resource_system.gd` and `discovery_system.gd`.
- No player game was launched from the worker checkout.
