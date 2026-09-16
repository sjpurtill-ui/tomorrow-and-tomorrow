# Opening sustenance integration handoff

## Scope

This wave makes the first two preservation discoveries operate through finite settlement equipment. It does not add discoveries or change the 883-discovery live catalog.

## Behavior

- **Food Drying** permits Crafting workers to make **Drying Mats** from Fiber Plants. Mats wear by 1% per day and are automatically replaced toward a population-scaled target when knowledge, adoption, labor, and inputs are present.
- Fresh plants become dry staples only when Food Drying is adopted, drying mats physically exist, Logistics/Crafting capacity is available, the settlement is not traveling, and the local temperature and precipitation permit useful open-air drying. Conversion retains the existing 88% food yield.
- **Smoke Preservation** permits Crafting workers to make **Smoke Frames** from Timber and Stone. Frames wear by 0.6% per day.
- Meat and fish become preserved food only when Smoke Preservation is adopted, smoke frames physically exist, a maintained fire is live, workers are available, and additional Timber can be burned. Conversion retains the existing 82% yield and consumes 0.04 Timber per input ration.
- The existing opening-practice coverage system now scales the discoveries' passive storage effects with actual Drying Mat or Smoke Frame coverage. Knowledge remains after equipment wears out, but its operating benefit does not.
- The Knowledge Atlas uses the shared opening-practice summary to show the produced asset and current coverage.

## Causal boundaries

- Drying mats deliberately use raw Fiber Plants so Food Drying does not depend on the later Cordage or Basketry discoveries.
- Smoke frames are simple timber-and-stone supports. Their construction does not require fire; using them requires the maintained-fire system.
- No food or equipment is granted when a discovery is learned.
- No portable preservation benefit is available while traveling.
- Industrial solar dryers, curing regimens, sealed vessels, cold storage, and canning retain their later roles.

## Validation

- `test_food_preparation.gd`: 15/15 passed.
- `test_opening_craft_practice.gd`: 6/6 passed.
- `test_opening_fire_knowledge.gd`: 10/10 passed.
- The GdUnit launcher emits its existing invalid remote-debug port warning before successful test execution.

## Integration notes

- Save compatibility is unchanged: the two new equipment quantities use the already serialized `resource_stockpiles` dictionary.
- Shared files touched: `discovery_system.gd` and `food_system.gd`.
- No player build was launched from the worker checkout.
