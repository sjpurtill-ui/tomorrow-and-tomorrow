# Food storage and usable reserves

October 18 review: adding repeatable storage exposed excessively durable early mixed food reserves. The top bar also called stock / daily consumption “days” without allowing for future rot. More buildings remain possible and paid for; no stock cap or inventory deletion is introduced.

## Shared rules

Every owner uses FoodSystem and StorageWorks through WorldSimulation. Player and opponent construction use the same materials, builder-work, capacity and overflow rules. Stored food's aggregate base daily loss changes from 0.001 to 0.003. Existing adopted preservation practices, actual containers, granaries, cooling and keeper labor still improve outcomes. Fresh food retains its 0.04 base. These are gameplay calibrations, not measured universal shelf lives.

Both pools now multiply losses by `clamp(2^((temperature - 15)/20) * lerp(0.8, 1.4, precipitation), 0.4, 2.5)`. Temperature uses the owner's local seasonal environment. Precipitation is a coarse dampness proxy, not a measured moisture percentage inside a store. Existing cooling service remains conditional on actual operations. Empty additional storage changes room only, not the spoilage rate.

Two keepers per hundred people cover the ordinary 30-rations-per-person buffer. Beyond that, required keeper work grows with stored rations: `0.02 * max(population, stored_rations / 30)`, with the existing one-effective-worker minimum. Full coverage still reduces stored loss by 40%; there is no automatic labor reassignment. The role preview and food explanation use the same workload. The stock-sensitive cache refreshes after a stock change, not only when population changes.

## What the headline means

The top bar and Food-screen reserve headline now estimate how long current food can feed current demand **if no food arrives**, at today's storage conditions. Fresh food is eaten first; the stored pool continues to deteriorate meanwhile. A closed-form decay/consumption calculation avoids a daily simulation in UI refreshes. It is a constant-conditions estimate, not a forecast of weather, staffing, future preservation or harvests.

The hover card states those assumptions and shows measured losses, including overflow. The detail view retains gross ration-equivalent days. The legacy `food_days` metric remains stock / demand because existing stock-taking, diplomatic conversions and planner gates use that unit; `food_reserve_days` is a separate field, computed for every actor. No amount of food or military provisions is silently reinterpreted as the new estimate. Legacy multi-town headline estimates are demand-weighted local reserve durations; they do not imply instant transport.

## Evidence and boundaries

FAO's [bulk storage guidance](https://www.fao.org/4/t1838e/t1838e19.htm) distinguishes well-dried, pest-free grain that can last years from grain at risk in warm, damp conditions. Its [storage fundamentals](https://www.fao.org/4/x5065e/x5065E04.htm) explain temperature, moisture, respiration and pests. The [National Center for Home Food Preservation](https://nchfp.uga.edu/how/dry/general-information-drying/packaging-and-storing-dried-foods/) gives 4–12 months for properly packaged dried foods, varying by food and temperature. These sources support separating room from preservation and including climate; they do not supply the game's coefficients.

This remains an aggregate fresh/stored model. Individual grain, dried meat and canned batches and their ages are not tracked. A 500-day gross reserve is possible; better preservation can make long reserves sensible. Opponents retain their existing bounded multi-day scheduler: old-stock decay compounds over the whole interval, while production/consumption remain interval approximations. Identical daily inputs and construction costs are tested directly across player and opponent scopes.

The user's October 18 quicksave was read only in an isolated headless process. It has the shared world enabled and 12 opponents. At day 21,644, it held 84,107 stored rations against daily demand 294.76: 285.34 gross days. Previously measured stored loss was 19.58/day (about 0.0002324 of the pool). Revised current loss is 70.53/day and estimated usable cover is 255.72 days. The saved file and running game were not modified. This snapshot is not a claim about a newer live 500-day display.

Save schemas and existing inventories remain compatible. Balance changes apply on subsequent simulation steps after restarting the updated build. Multi-generation population/AI outcomes have not been rebalanced or certified in this focused pass.
