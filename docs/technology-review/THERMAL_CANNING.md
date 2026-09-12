# Physical canning and preserved provisions

Seven authored discoveries connect metallurgy, container manufacture, sealing, retorts and measured processing to a staffed cannery. Each uses explicit AND prerequisites and a local route, with no calendar gate or global preservation bonus.

| Discovery | Foundations | Actual capability |
| --- | --- | --- |
| Tin Smelting | Ore assaying, charcoal | 2 Tin Ore + 1 Charcoal → 1 Refined Tin, 3 work days |
| Sheet Steel Rolling | Steel refining, bearing surfaces | 1 Steel → 1 Steel Sheets, 3 days |
| Tinplate Coating | Sheet steel rolling, tin smelting | 1 Steel Sheets + 0.1 Refined Tin → 1 Tinplate, 3 days |
| Can Body Forming | Tinplate coating, standard measures | 1 Tinplate → 1 Food Can Sets, 2 days |
| Double Seaming | Can body forming, bearing surfaces | 2 Steel + 1 Shaft Bearings → 1 Seaming Heads, 4 days |
| Food Retorts | Pressure vessels, precision thermometry | 2 Pressure Vessels + 2 Wrought Iron → 1 Food Retorts, 5 days |
| Thermal Process Validation | Food retorts, double seaming, experimental controls | Commission and operate a cannery |

Each recipe additionally pays physical workshop tooling recorded in civilian_industry.gd. Can sets represent empty bodies and ends; filling and closing happen at the cannery, not during empty-container manufacture. Sealing compounds, coatings, closures and processing conditions are abstracted rather than individually simulated.

A cannery costs 1 Food Retorts, 1 Seaming Heads and 2 Wrought Iron, plus 16 commissioning worker-days. It reserves up to two assigned Crafting workers. At full condition, one operating day consumes 0.2 Food Can Sets, 0.2 Coal and 0.5 Freshwater to provide capacity for 10 food units. Missing materials, staff or settlement availability constrain ordinary operations. This is fuel-fired equipment; it needs no electric service. Counts, days and quantities are provisional game batches, not physical industrial measurements.

The ordinary food day uses only current-day capacity after existing preservation and before spoilage and consumption. It preserves Fish, Fresh meat, then Fresh plants, converting each unit to 0.90 Preserved food. It limits input to the amount above three days of current demand, conservatively retaining that reserve after processing loss. Capacity is debited, preventing repeated calls from reusing it. Traveling, secondary-settlement scope and stale ledgers cannot consume home capacity. Dry staples and existing preserved food are never reprocessed. Preserved output enters the existing edible food/provision pool and remains subject to its normal losses.

Daily operation now limits prepared capacity to the currently available perishable surplus above the three-day reserve. Cans, fuel, water and operator time scale with that amount; zero eligible stock leaves the cannery idle without consuming those supplies. This review occurs before the food-day harvest and existing drying/smoking: later stock changes can still leave some prepared capacity unused, and newly harvested food cannot expand capacity until the next daily review. [Autonomous cannery investment](AI_CANNERY_INVESTMENT.md) now evaluates visible surplus and supply before commissioning. Existing operating-input supply planning can maintain consumables for an installed plant. Long-term economic desirability, campaign provisioning improvement and forecast treatment remain unverified.

Historical/process basis: [FAO canning principles](https://www.fao.org/4/R6918E/R6918E02.htm) distinguish process validation from simply heating a sealed container; [FAO equipment descriptions](https://www.fao.org/4/R6918E/R6918E06.htm) describe sealing machinery and retorts. The [National Park Service history](https://www.nps.gov/articles/000/why-no-cans.htm) discusses the move from glass to metal containers. These sources support the distinct capabilities, not this game's quantities. No literal food-safety instructions, temperature schedule, contamination model or guarantee of sterility is encoded.

Save compatibility: no new top-level fields. Existing generic stocks, food stocks and operating records hold new components and the plant. Validation accepts the new Food Can Sets input and bounded food_preservation service (maximum 10,000 across 1,000 plants); the conservative worker-record ceiling rises to 24,000. Older saves remain loadable and gain no manufactured stocks or installations. Downgrading to an older build after installing a new plant is not supported by its older validator.

Focused verification covers real component manufacture and paid commissioning, finite food conversion and loss, daily capacity consumption, fuel/cans/water/staff interruption, reserve/travel/secondary/stale guards, ordinary food-day integration and owned save continuity. Structural graph closure remains distinct from campaign acceptance.
