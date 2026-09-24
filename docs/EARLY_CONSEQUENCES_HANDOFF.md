# Early consequences: food, survival and growth

Worktree `C:/Users/sjpur/tt-early-consequences`, branch `codex/early-consequences`, base `72b93014`. Uncommitted when handed off; the coordinator commits.

User request: early food is too balanced and simple. Discoveries about health and food should change life expectancy much more. Wrong decisions should slow early growth.

## What the base did (findings)

- **Food** (`food_system.gd`): the food workers' output splits across gathering, hunting, fishing and (after Selective Planting) cultivation by fixed environment weights. The split never responded to how well each source was doing. Every source's "ground health" was damaged the same way, only when more than 42% of able people worked food. In practice the grounds stayed at 1.00 for a whole century. Diet quality started at ~1.0 in every scenario, because the formula saturated on any mix of plants and protein. Diet quality therefore did almost nothing.
- **Mortality** (`game_state.gd`): one fixed life table (infant hazard 0.09) scaled by health, food security and shelter. Discoveries reached it only indirectly, through `population_health`, which sat at its 0.97 cap in good play. Life expectancy was ~55 from year 0 to year 100 in every good scenario. Infant mortality was the neonatal rate only, 60/1000, and never changed.
- **Birth** (`process_reproduction_day`): `maternal_safety` and `neonatal_survival` existed but started at 0 and only reduced a small base rate. There was no cost for lacking them.
- **Decisions**: the survival safeguard (`government_people_system`) quickly restores food labor. Poor play (bad site, development focus, labor drives, no health or food research) still grew 120 → 326 in 100 years, and life expectancy fell only from 51 to 44.

## What changed

1. **`scripts/early_life_conditions.gd`** (new). Seven early protections:
   - clean water and waste
   - wound care
   - remedies
   - birth care
   - child care and weaning food
   - cooked and sorted food
   - lean-season stores

   Each removes a share of excess mortality among under-5s, children 5–14, adults, newborns and mothers. The share depends on how widely the matching discoveries are adopted: Clean-Water Practice, Wound Cleaning, Medicinal Classification, Birth Attendants, Shared Childcare, hearth roasting, food drying and smoking, Storage Pits, and so on. Later knowledge counts through the general effect channels (`water_safety`, `sanitation`, `health_protection`, `maternal_safety`, `neonatal_survival`, `nutrition_quality`, `food_storage`), so a mature society is never penalized.
   - **Diet**: diet quality averaged over 120 days raises under-5 and newborn deaths and lowers conception.
   - **Overwork**: overwork (heavy-labor share above ~74%, or a labor mobilization) lowers conception and raises pregnancy and maternal risk.
   - **Birth spacing**: infant loss above 10% shortens birth intervals, because weaning ends early. This partly replaces the loss but never cancels it.
   - **No double-counting**: where hunger or sickness already raises the condition factor, the excess is reduced.
   - **Bounds**: excess is never below the base life table. The same multipliers drive projected life expectancy, natural deaths (including their age weights), the infant-mortality indicator and births.
2. **Food** (`food_system.gd`):
   - **Renewable wild food**: gathering, game and fish each have a daily renewal around the settlement. It depends on forage, game, water and coast, grows with the square root of population (range), and its regrowth depends on ecology.
   - **Depletion**: harvesting above renewal thins the grounds, and resting them brings them back. Game is the most fragile: it renews slowest and is damaged fastest.
   - **Daily ceiling**: a day's wild harvest has a soft cap. Extra food workers get diminishing returns, and labor the land cannot absorb moves to cultivation if fields exist.
   - **Labor follows returns**: food labor drifts toward sources that are yielding well this season.
   - **New diet formula**: the diet score rewards even variety across sources, protein, fresh food and preparation knowledge, and penalizes staple-heavy grain diets. Starting diet is ~0.72.
   - **Hard winters**: seeded by world and year, more frequent in strongly seasonal climates.
3. **Indicators and UI**:
   - Infant mortality is now deaths before the first birthday per 1,000 live births (it was first-month only). The migration attraction scale was re-anchored to match.
   - The Health view has a new block, WHAT DECIDES WHO SURVIVES, with a row for diet, overwork when present, and each protection. Each row shows its coverage, what is practiced and what to learn next.
   - The life expectancy and infant mortality tooltips explain the mechanism.
   - Food sources show ground health and "taking more than renews".
4. **Save compatibility**:
   - `GameState.early_care_blend` is 0 in a save written before this change and rises to 1 over two game years. Every new rule, food included, is interpolated by it, so a loaded population is not killed off at once.
   - New worlds (day < 30) apply the rules at once.
   - `early_care` and `early_care_blend` are ordinary reflected GameState fields, so they save and load automatically.
5. **Measurement**:
   - `tests/early_consequences_probe.tscn` runs disposable actors through the real daily pipeline (`civilization_day.gd`). Scenarios: `sensible`, `poor`, `focused`, `scholars`, `ai` (the ordinary rival controller), and `town` (2,400 people with established practices).
   - `--legacy` replays the old rules through the same harness. The rules are held at blend 0, the same state an old save starts from.
   - Command: `Godot --headless --path <worktree> res://tests/early_consequences_probe.tscn -- --years=100 --scenarios=sensible[,poor,...] [--legacy]`. Each 100-year run takes about 8–10 minutes.

## Before / after (seed 74119, 120 founders, 100 years)

Each cell is population / life expectancy at birth / infant deaths per 1,000 births.

| Scenario | Rules | Year 1 | Year 10 | Year 25 | Year 50 | Year 100 | Food security events (100 y) |
|---|---|---|---|---|---|---|---|
| (a) sensible | before | 120 / 55.8 / 61 | 142 / 54.6 / 62 | 195 / 55.2 / 61 | 365 / 55.0 / 60 | 1372 / 54.7 / 59 | none; game grounds 1.00 |
| (a) sensible | after | 120 / 39.4 / 193 | 130 / 38.1 / 193 | 161 / 39.8 / 181 | 283 / 47.3 / 131 | 949 / 47.2 / 120 | none; game grounds 0.81 |
| (b) poor | before | 120 / 51.2 / 68 | 130 / 45.9 / 86 | 144 / 43.5 / 94 | 184 / 44.0 / 89 | 326 / 43.7 / 88 | none |
| (b) poor | after | 119 / 36.4 / 206 | 111 / 34.8 / 215 | 106 / 34.6 / 217 | 97 / 35.1 / 216 | 81 / 35.0 / 208 | 648 short days in 92 episodes; hunger deaths on 724 days; lowest 80; game grounds 0.78 |
| (c) health+food emphasis | before | 120 / 55.8 / 61 | 142 / 54.6 / 62 | 195 / 54.6 / 63 | 360 / 54.2 / 61 | 1334 / 54.7 / 59 | none |
| (c) health+food emphasis | after | 120 / 39.4 / 193 | 130 / 38.1 / 193 | 162 / 40.5 / 174 | 246 / 43.6 / 144 | 725 / 47.4 / 121 | none |
| (c′) same + research focus and targeted care practices | before | 120 / 55.5 / 61 | 141 / 53.4 / 67 | 190 / 53.0 / 66 | 345 / 55.3 / 60 | 1312 / 54.7 / 59 | none |
| (c′) same + research focus and targeted care practices | after | 120 / 39.2 / 193 | 130 / 40.8 / 174 | 160 / 42.9 / 146 | 245 / 48.6 / 122 | 838 / 49.9 / 106 | none |
| AI rival controller | before | 120 / 55.6 / 61 | 142 / 55.5 / 61 | 195 / 55.7 / 61 | 359 / 51.4 / 73 | 1256 / 46.6 / 91 | none |
| AI rival controller | after | 120 / 38.4 / 194 | 128 / 42.2 / 176 | 169 / 44.9 / 155 | 293 / 41.5 / 170 | 929 / 39.9 / 173 | none |

The grown town is a mid-game scale check (2,400 people, 14 practices known). Cells are population / life expectancy / infant mortality:

| Scenario | Rules | Year 1 | Year 5 | Year 10 | Year 20 |
|---|---|---|---|---|---|
| Grown town | before | 2400 / 55.7 / 58 | 2609 / 54.7 / 58 | 2915 / 55.9 / 58 | 3733 / 56.0 / 58 |
| Grown town | after | 2387 / 52.3 / 79 | 2581 / 52.9 / 71 | 2874 / 54.6 / 68 | 3647 / 55.4 / 65 |

What the scenarios mean:

- **(a) sensible**: good site, delegated labor, broad research (health 3, nutrition 3, demography 2).
- **(b) poor**: poor site (scarce forage, game and water, variable rain), manual "development" focus, repeated foraging drives and labor mobilization, and zero health, nutrition, demography and ecology research.
- **(c)**: health 6, nutrition 6, demography 4, the rest reduced.
- **(c′)**: (c) plus the "research" settlement focus (more Knowledge labor) and investigations pointed at the early care practices.

Reading:

- **Early life expectancy**: founding life expectancy is now ~39 with ~190 infant deaths per 1,000, and ~35 / 210 on a bad site. That is prehistoric-plausible; the base had 55 / 60. The "town" check shows that established practices bring a society back to the old ~55.
- **(a) sensible**: a slow start while care practices are missing, then steady growth, with 8× population by year 100 (1.2× by year 25). Life expectancy rises 39 → 47 as practices arrive; the health chart marks each rise.
- **(b) poor**: a slow decline, 120 → 81 over a century. There are 92 separate shortage episodes, each recovered by the survival safeguard. There is no single-mistake collapse; the population never falls below 80. Before this change the same play still tripled the population.
- **(c′) research-led care**: clearly better life expectancy (49.9 vs 47.2) and infant mortality (106 vs 120) than (a). It is ahead of (a) on life expectancy from year 10.
- **Growth in (c) and (c′)**: final population is below (a) (725–838 vs 949). In this harness a narrow emphasis gave up the production and infrastructure discoveries that let (a) build large stores around year 30. There is also a pacing effect: plain (c) found **fewer** health discoveries by year 100 than (a) (4 vs 5), so emphasis weight alone does not buy health discoveries. Only (c′), with targeted investigations, reached 7. The brief's aim that (c) also out-grows (a) is therefore **not met**. That outcome is decided in discovery pacing (`discovery_system.gd`), which is outside this task.
- **AI parity**: rivals run the same code, so they carry the same rules. The rival controller rarely researches birth care (1 health discovery by year 100), so its life expectancy stays near 40 and it ends slightly behind (a).

## Tests

gdUnit, run sequentially against the worktree:

- **New suite**: `test_early_life_conditions` 11/11 passes. It covers:
  - excess mortality without practices
  - monotone gains per practice
  - later knowledge through effect channels
  - thin diet
  - overwork
  - replacement fertility bounds
  - two-year save blend
  - immediate application in a new world
  - care-adjusted natural deaths and age weights
  - birth care
  - UI explanation rows
- **Pass**:
  - `test_game_state_demographics` 18
  - `test_civilization_indicators` 3
  - `test_food_pools` 9
  - `test_food_preparation` 16
  - `test_food_water_knowledge` 10
  - `test_founding_site_subsistence` 4
  - `test_founding_knowledge` 4
  - `test_founding_water_guidance` 17
  - `test_founding_convoy_travel` 6
  - `test_opening_water_health` 4
  - `test_opening_storage` 4
  - `test_opening_storage_survival` 3
  - `test_population_read_stability` 2
  - `test_monthly_population_scope` 2
  - `test_selected_food_processing` 13
  - `test_civilian_care` 17
  - `test_society_exchange` 32
  - `test_city_intelligence` 19
  - `test_campaign_save_continuation` 5
  - `test_research_foundations` 5
  - `test_civilization_system` 69
- **Failures that also occur at base `72b93014`** (checked in an unmodified worktree where noted):
  - `test_civilization_owned_simulation::test_same_orders_and_daily_inputs_produce_identical_owned_state` (known)
  - `test_government_people_system::test_deceased_roster_does_not_exhaust_future_government_successors` (known)
  - `test_coastal_water::test_water_created_after_patch_uses_existing_bed_and_fog_registry` (verified at base)
  - `test_opening_opportunities::test_root_questions_need_distinct_lived_evidence` (verified at base)

## Limitations and follow-ups

- **Research emphasis vs discoveries**: a larger health or nutrition weight did not produce more health discoveries by year 100 than a balanced one in this harness (see (c)). Discovery pacing should be reviewed before promising the player that health research reliably outruns balanced play.
- **Missing early practices**: most items in `docs/research/*_600_YEARS.md` do not exist yet: swaddling, cord care, weaning foods, splints, milk, fish weirs and so on. The care categories already list several of their planned IDs (`labor_position_customs`, `cord_afterbirth_handling`, `weaning_food_softening`, `infant_swaddling_practice`, `splint_and_bracing_technique`, `dietary_healing_regimens`), so these practices will count automatically once `codex/era-research-pacing` adds them.
- **No direct food-source choice**: the player does not directly choose between foraging, hunting and fishing. Labor follows returns automatically, so tradeoffs show up as depletion, diet, seasons and settlement focus.
- **Probe coverage**: the probe uses one seed and a controlled site profile. The results are behavioral evidence, not a full biome sample.
- **Save blending**: the two-year blend is covered by the unit test. A real old save was not loaded in this pass.
- **Shared-file edits** (small and delimited):
  - `game_state.gd`: two fields, cohort hazard helper, reproduction multipliers.
  - `consequence_engine.gd`: one delimited block plus four context keys.
  - No edits to `discovery_system.gd` or `local_terrain.gd`.

## Post-merge note (after merging main 4d5c5e36)

- The fertility check in `tests/responsive_decree_probe.gd` ("fertility rose in only 3 of 4 seeds") was not the new conception rules hiding the order: the early-care conception factor multiplies alongside the order's `conception_support`. The probe runs only the consequence engine, so nothing reassigns labor. In that world, the new wild-food limits leave a fixed 25% of 600 people on dry ground short of food within about 150 days. The resulting birth crisis cut conceptions to about 1 a year in both arms, leaving the comparison to integer noise. The probe now holds food steady, as it already held water steady: it keeps its full ration store in reach. The order again raises conceptions and births in all four seeds (+4 to +4.5% net surviving births).
- `test_civilization_system` passes 69/69 in two sequential runs on the merged tree. The reported failure at lines 823–828 did not reproduce. That test needs at least four civilizations at contact level 2, which these changes do not touch. It may be sensitive to shared global state when suites run concurrently.
