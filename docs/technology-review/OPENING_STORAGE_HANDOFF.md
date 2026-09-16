# Opening storage integration handoff

## Scope

This wave turns Tempered Clay, Sealed Vessels, and Public Stores into operating systems backed by physical stocks, construction, and labor. The live catalog remains 883 discoveries.

## Vessel chain

- **Tempered Clay** now requires Clay Shaping, Clay Testing, and Pit Firing as common foundations.
- Crafting workers consume Clay, crushed Stone, Freshwater, Timber, and a maintained fire to make **Tempered Clay Vessels**. The stock wears slowly and scales the discovery's listed effects.
- **Sealed Vessels** requires Tempered Clay and Pit Firing. Crafting workers consume a physical tempered vessel and Fiber Plants to make a **Sealed Clay Vessel**.
- Each sealed vessel adds 18 rations of protected food capacity. Its listed spoilage, health, storage, and trade effects scale with population-relative vessel coverage.
- Imported physical vessels provide their container capacity; knowing the technique without vessels supplies no effect or capacity.

## Public stores

- Public Stores knowledge unlocks a 14-day settlement construction project after Storage Pits and at 10% adoption.
- Construction requires at least 5 Construction, 6 Logistics, and 3 Administration workers and consumes one feasible local material plan: timber/clay/fiber, stone/timber/fiber, or clay/fiber.
- Completion records a `public_storehouse` with storage land use in the permanent building ledger and converts lined storage-pit fabric to the public-storehouse form during settlement synchronization.
- A completed store adds up to 120 food rations of capacity per resident. Capacity and all listed Public Stores effects scale with continuing Logistics and Administration coverage; removing either operating staff removes the added capacity.
- Economy obligation accounting uses the same operating factor, so knowledge alone cannot increase common-store fulfillment.

## Validation

- `test_opening_storage.gd`: 4/4 passed.
- `test_opening_craft_practice.gd`: 6/6 passed.
- `test_technology_requirements.gd`: 15/15 passed.
- `test_food_preparation.gd`: 15/15 passed.
- The GdUnit launcher emits its existing invalid remote-debug port warning before successful execution.

## Integration notes

- Save compatibility is unchanged. Vessel quantities use `resource_stockpiles`; the project uses existing settlement project/completion, building ledger, and plot fields.
- Shared hotspots touched: `food_system.gd` and the settlement/economy integration paths. `game_state.gd` and save schemas are unchanged.
- No player game was launched from the worker checkout.
