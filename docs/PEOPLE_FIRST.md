# People first: every role a path (2026-10-02 overhaul)

The game is fundamentally about where the people work. Every role must be a path as consequential as learning. Computer peoples must take different paths.

The user's direction, verbatim in substance:
- The early game is boring and uniform.
- Everybody goes all in on research.
- Food stores are absurdly large.
- The military should be a share of the people.
- The economy (barter) starts in year one.
- Each role grows into a sector of the economy.

Read first: `AGENTS.md`, `docs/ADJUDICATION.md` (one ledger, stated odds, seeded rolls), `docs/STANDING_DESIGN.md` (every people follows the same rules), `docs/ECONOMY_SYSTEM.md`, `docs/BUSINESS_ARC.md` and `docs/GENERAL_CAMPAIGN_DESIGN.md`.

## The nine roles (`game_state.gd POPULATION_ROLES` ids unchanged; words in `manual_work.gd TASKS`)

| id | Player's word | What it does now (the overhaul) | Grows into (later) |
|---|---|---|---|
| Food | getting food | Fresh food each day. More fresh food means more health and more births. Fresh food spoils fast. | the food business |
| Survey | searching the land | Searched land yields more to the cutters and diggers, and searchers find new deposits. | prospecting and mining companies |
| Extraction | cutting and digging | Timber, stone, clay, ore and fibre; more where the land is searched. | extraction companies |
| Construction | building | Unchanged. | builders' firms |
| Crafting | **making** (was "making tools") | Turns what is cut, dug and carried into goods (tools, cloth, pots, weapons). Goods are the first currency. | makers' firms, then industry |
| Logistics | carrying | Services: fresh food reaches people before it spoils, and goods reach makers and markets. | the service economy |
| Knowledge | learning | Research, with **no cap on how many learn**. Learners use goods (tools, tallies, writing stuff). | |
| Administration | **keeping and caring** (was "keeping the stores") | Keepers stop stored food rotting. Carers tend newborns, the sick and mothers: fewer infant deaths, better health. **The population lever.** Its old office work (reach, records) stays. | |
| Defense | keeping watch | **The military itself.** Its share of the people is the manpower. There is no separate recruiting. | |

## Workstreams (one builder each; each owns its files)

### A. Learning without a cap (owner: `research_600_catalog.gd`, `discovery_system.gd` research capacity, `task_impact.gd` learning rows)
- `team_capacity(researchers)` is linear: every learner counts in full. Remove the RESEARCH_TEAMS=12 knee.
- Questions worked at once (team_count) grow without a cap (+4 per tenfold learners).
- On a single question, more people add a little less each (gentle, about n^0.85, never a hard cap).
- **No calendar cap on pace.** A people that presses learning may reach knowledge ahead of its age; that is a path the player chooses. If an era ceiling (`society_model.gd` ~319-324, `pace_for(design_year)`) throttles a people's own pace or the payoff of what it has learned, make it follow the people's own knowledge, not the calendar. Report what you changed.
- **Learning has costs, so it is a choice, not a default.**
  - Each learner uses goods: about 1 goods-unit per 20 learner-days (writing stuff, tools, tallies; tune it).
  - Without goods, learning slows: progress × (0.5 + 0.5 × goods cover).
  - The existing material support from making stays. Learners eat but make no food or goods.
- The People view's learning row says plainly what one more learner does now.

**A as built (PR #102).** The allocation is the budget: every unit of learning is paid for in people taken from other work, plus their food and goods.
- **Work.** `Research600.team_capacity(learners)` comes from the number of people on the research lines alone, never from the people's size. The learners work `teams_at` questions at once (+4 per tenfold, no cap), each team at people^0.85: 200 learners do 1.83 times the work of 100, 1,000 about 7.5 times the work of 100. The research_3000 parallel capacity, which multiplied research by a people's size, is gone. Diffusion stays off. The artifact, leader, figure, scholar-visit and education factors only multiply learners' work: with nobody learning, nothing is learned (fast sim: 0 discoveries in 150 years at no learners, for 120 or 2,000 people).
- **One pace constant.** `LEARNER_PACE` = 1: a founding band with its usual few learners paces BENCHMARKS_600 exactly as before. Each age's questions ask the work of the learners a people of that age usually keeps (`AGE_WORK_BY_YEAR`, by the question's own year, fitted in tools/sim from the sensible run: 1 up to year 250, 3 at year 600, 12 at 1200, 55 at 3000). A sensible people therefore paces as before, a small people with few learners falls behind, and only more learners run ahead.
- **Goods.** Learners use 1 goods-unit per 20 learner-days, read and taken through one accessor (`Research600.learning_goods`): home stores first, then the towns' stores in proportion to what each holds. Makers keep what the learners will take before the next step (`civilian_goods.gd`; a 10-day step keeps its learners covered). The goods report and screens show the learners' take. Short of goods: progress × (0.5 + 0.5 × cover).
- **The people's own age.** Learners on the lines beyond the share the age can spare (`SUSTAINABLE_SPECIALISTS`, read at the economy's real age) earn a lead over the calendar: 0.06 years a year per doubling of that share, falling back the same way below it. Questions, foundations and teams are dated from the calendar plus the lead (`DiscoverySystem.learning_year`). Effect ceilings follow min(own age, knowledge frontier). `pace_for(design_year)` is the question's own size and never reads the calendar.
- **A lead is paid for.** Goods per learner rise by the usual amount again for every 20 years ahead. The upkeep of learners past the sustainable share (work, weariness, cohesion, births, stores) rises by the usual amount again for every 300 years ahead. What the economy can spare and the artifact cap read the economy's real age, never the lead.
- **Fast sim, 3 seeds to year 600** (base = main 97a32dd2, head = this branch; learning share in brackets; writing / bronze / place value years; population at 150 / 300 / 600):

| Path | Base | Head |
|---|---|---|
| sensible (5%) | 218 / 327 / 483; 287 / 1,054 / 3,633 | 219 / 328 / 482; 288 / 1,054 / 3,634 |
| balanced (5%) | 219 / 327 / 483; 260 / 1,038 / 3,613 | 220 / 327 / 482; 259 / 1,037 / 3,612 |
| research (17.6%) | 215 / 325 / 478; 272 / 968 / 3,499 | 196 / 297 / 441; 272 / 975 / 3,508 |
| research_heavy (35%) | 215 / 326 / 480; 160 / 344 / 2,350 | 188 / 289 / 430; 158 / 319 / 1,717 |

  - **Research path (17.6%).** About 20-30 years before the band floors (215 / 320 / 470), with a lead of 33 years by 600. Its population matches its own base and stays below sensible.
  - **All-in learning (35%).** About 25-40 years before the floors, with a lead of 61 years by 600. It pays for it: 7% fewer people than its old self at 300 and 27% fewer at 600 (half of sensible's), households stripped of goods, and lower making capacity and guard than sensible (0.83 and 0.44 against 0.96 and 0.53 at 300).
- **Switching paths (3 seeds).** Growth = heavy food and keeping/caring with 2% learning.
  - **Growth, then 30% learning from year 200.** Knows 323 at the switch, catches sensible's knowledge by 300 (743 against 743) and passes it by 600 (1,148 against 1,120), with 2,791 people at 600 (sensible: 3,634). Under the old rule it never caught up (723 at 300, 1,103 at 600).
  - **35% learning, then growth from year 200.** Knows 638 at the switch with a 29-year lead, and 158 people. Its population then grows to 482 at 300, 1,527 at 400 and 3,551 at 600, nearly level with sensible. Its knowledge falls behind (985 at 600) as its few learners keep up less, and its lead falls back to the calendar.
  - **Growth only (2% learning).** Lags further than before (bronze 421, against 379 under the old rule): few learners, slow learning.

### B. Fresh food, small stores, keepers and carers (owner: `food_system.gd`, `consequence_engine.gd` food-security/health/early-life targets, `early_life_conditions.gd` care coverage, `realm_purse.gd LEVY_KEEP_DAYS`)
- **No more giant stores.**
  - Food security no longer counts store days up to 45. It counts a lean buffer: `min(1, food_days / LEAN_DAYS)` with LEAN_DAYS = 20, "enough to carry the people through a lean spell".
  - Deaths and sickness come from what is eaten (shortfall, malnutrition) and its freshness, never from the size of the store.
  - A village of 100 with 20 days in store and fresh food coming in thrives.
  - `realm_purse.LEVY_KEEP_DAYS` = LEAN_DAYS.
- **Fresh against stored.**
  - Health rises with the fresh share of what is eaten. The health target gets `FRESH_HEALTH × (fresh_share − 0.5)` (about ±0.06). Name and show it.
  - Fresh food spoils fast (as now), so a people balances bringing it in fresh against putting it by.
  - More getting food plus more carrying means more fresh food reaching mouths.
- **Carriers (services).** The carrying cover = carriers ÷ (population × 0.03), capped at 1. It cuts fresh spoilage by up to half and widens the reach of the daily harvest (fresh food arriving before it turns). Show it.
- **Keepers and carers (Administration).**
  - Keeper cover cuts stored spoilage by up to 40% (beside the Quartermaster lever).
  - Carer cover = carers ÷ (population × 0.04), capped at 1. It adds care coverage to the early-life categories (childcare, remedies, water care, wounds). That lowers infant and child deaths and maternal risk, and raises health.
  - Stay inside pre-modern benchmarks (`docs/research/BENCHMARKS_600.md`): full care without modern medicine still leaves IMR above about 150 in 1000.
  - This is the population lever: more keepers and carers, more children survive.
- Every number goes on the People view and the food/health tiles (show the engine's numbers).

#### B as built (PR #103)
All the shared numbers are in `scripts/food_care.gd`.

**Stores**
- `LEAN_DAYS` = 20. Food security counts the store up to 20 days.
- Deaths, sickness, births and life expectancy read `GameState.fed_security()`. That is food security with the store counted as full, so a small store never kills; going without food does.
- The realm's purse is set in this order:

  | `HUNGRY_DAYS` | `RELIEF_TARGET` | `LEVY_KEEP_DAYS` | `SELLER_KEEP` | `SELLER_DAYS` |
  |---|---|---|---|---|
  | 15 | 20 | 20 | 30 | 40 |

  Relief never lifts a town above what the levy leaves it, so the levy never takes relief back.

**The planners** (`government_people_system.gd`)
- They aim for `RESERVE_TARGET_DAYS` = 30 days, which is `LEAN_DAYS` × 1.5. A food wish or the growth path raises this, up to twice as much.
- Below the target they plan above the day's need. Above it they plan up to 15% below the need, until the stores come back down.
- Once the stores hold the target, they plan exactly the need.
- The era's food floor (`FOOD_FLOOR_OF_TYPICAL` 0.35, was 0.9) is only a safety net. The food alarm still adds hands when a shortfall or lean season comes.
- `RULER_RELEASE_DAYS` is 45 (was 120).

**The rulers' store gates**
- These cover founding a town, war, peace, scouting, hard drill, a great work's start, pace and extra crews, and food gifts.
- In `civilization_strategy.gd` and `civilization_controller.gd`, each gate now asks half the days it did (`STORE_GATE`).
- A founding never waits for more than full stores (30 days).
- `DEFENSE_FOOD_DAYS` is 15 and `GOODWILL_FOOD_DAYS` is 45.

**Fresh food**
- Health gets `+0.12 × (fresh share − 0.5)` above half fresh, up to +0.06.
- Below half fresh it gets `0.04 × (fresh share − 0.5)`, at most −0.02, so a town living on its grain is not ruined.

**Carriers** (3 in 100 of the people for full cover)
- Fresh spoilage is halved.
- The wild harvest reaches 25% more ground.

**Keepers and carers.** The same Administration people keep the stores, care for the people and do the office work. Each of the three counts all of them, against its own share of the people:
- Keepers: full at 2 in 100 of the people. Full cover cuts stored rot by 40%.
- Carers: full at 8 in 100 of the people, so the usual 4 in 100 give half. Full cover:
  - covers 40–60% of what missing child care, remedies, clean water and wound care would leave;
  - lifts part of the pre-modern burden: 45% for under-fives, 50% for newborns, 40% for mothers and 25% for children;
  - adds +0.03 health.
- The carers' cover builds up over about 60 days, and older saves start from none.

**A chosen path may run a little ahead of history, as learning may.** A people that leans hard into growth (keepers and carers near 8 in 100, plenty of fresh food and carrying) beats the best documented pre-modern figures by a modest margin. The extra costs real labour. A balanced people stays inside `docs/research/BENCHMARKS_600.md`.

**Infant deaths per 1,000 in the engine** (test setup: health 0.85 for the founders, 0.97 and well fed for the people with every practice):

| Carers (in 100 of the people) | 0 | 2 | 4 | 8 |
|---|---|---|---|---|
| Founders, no early practices | 317 | 290 | 264 | 214 |
| Every early practice, well fed | 225 | 207 | 189 | 152 |

**Fast sim, 2 seeds, good site, 600 years** (`tools/sim`). Paths are the leaders.py tempers, and the leader runs include daughter towns. Each cell reads main → this branch.

Food share of the workers (%) and days of food in store, at years 50 and 150:

| | Food share y50 | Food share y150 | Stores y50 | Stores y150 |
|---|---|---|---|---|
| growth (cautious-caring) | 51.5 → 36.8 | 49.8 → 40.0 | 244 → 61 | 227 → 61 |
| war (disciplined-warlike) | 54.2 → 42.8 | 52.3 → 39.5 | 243 → 38 | 232 → 41 |
| learning (open-scholarly) | 54.9 → 36.4 | 53.1 → 38.6 | 245 → 31 | 229 → 41 |
| balanced (temper) | 54.3 → 38.7 | 52.5 → 39.6 | 183 → 37 | 231 → 40 |
| balanced scenario | 54.9 → 40.4 | 53.1 → 39.8 | 183 → 34 | 229 → 44 |
| sensible scenario | 54.5 → 40.6 | 52.7 → 39.8 | 182 → 34 | 228 → 44 |

Population, infant deaths, life expectancy and growth at years 150, 300 and 600:

| | Population | Infant deaths per 1,000 | Life expectancy (years) | Growth, % per year (0–150 / 150–300 / 300–600) |
|---|---|---|---|---|
| growth | 349 / 1,900 / 29,322 → 481 / 3,255 / 30,451 | 210 / 205 / 211 → **152 / 159 / 159** | 27.6 / 28.0 / 27.4 → 31.6 / 31.1 / 31.0 | 0.71 / 1.13 / 0.91 → 0.93 / 1.27 / 0.75 |
| balanced (temper) | 212 / 989 / 26,173 → 322 / 1,686 / 28,243 | 211 / 204 / 207 → 189 / 188 / 193 | 27.5 / 28.1 / 27.9 → 29.0 / 29.2 / 28.8 | 0.38 / 1.03 / 1.09 → 0.66 / 1.10 / 0.94 |
| balanced scenario | 261 / 1,036 / 3,593 → 358 / 1,106 / 3,724 | 211 / 212 / 208 → 187 / 193 / 185 | 27.5 / 27.1 / 27.7 → 29.1 / 28.3 / 29.3 | 0.52 / 0.92 / 0.41 → 0.73 / 0.75 / 0.40 |
| sensible scenario | 288 / 1,052 / 3,612 → 372 / 1,112 / 3,744 | 210 / 212 / 208 → 187 / 193 / 184 | 27.6 / 27.1 / 27.8 → 29.1 / 28.3 / 29.3 | 0.58 / 0.86 / 0.41 → 0.75 / 0.73 / 0.40 |
| learning | 252 / 905 / 18,235 → 225 / 712 / 11,216 | 210 / 203 / 200 → 188 / 185 / 183 | 27.6 / 28.2 / 28.7 → 29.1 / 29.4 / 30.1 | 0.50 / 0.85 / 1.00 → 0.42 / 0.77 / 0.92 |

What the sims show:
- **No hunger.** No run went short of food: the lowest month's intake was 1.0, and no month fell below 0.95.
- **Growth path.** It runs about a fifth under the best historical infant deaths at year 150 (about 187) and 12% under at year 300 (180). At year 600 it matches the best (160).
- **Balanced peoples** stay at or above the best historical figure and below the typical one.
- **Learning path.** It now puts the freed food work into learning. The specialists' upkeep (`society_model.gd SPECIALIST_UPKEEP`) then lowers its births, which is learning's price.

#### Frontier growth (codex/frontier-growth)
"How am I shrinking at these numbers?" A healthy, fed founding people lost about 1.5% a year for its first decade. In the engine, a band of 120 was at 97 by year 12, and the fast sim did not see 120 again until year 38. Two things caused it.

1. **The founders were old.** A quarter of them were past 45 (18% aged 45–60, 8% older), so the first decades' deaths were mostly founders growing old.
   - Founders are now young families (`game_state.gd FOUNDING_AGE_MIX`: children 36%, 14–25 21%, 25–35 17%, 35–45 12%, 45–60 10%, older 4%). That is close to the mix a growing pre-modern people settles into.
   - Older saves keep their people as they are.
2. **Open land did nothing for births.** Now, while the whole people is under `FRONTIER_ONSET` (0.6, where crowding begins) of what one home land carries, couples set up house younger. Conception rises by up to `FRONTIER_CONCEPTION` (0.30), tapering to none as the land fills (`early_life_conditions.gd frontier_of`, `home_capacity`).
   - A new band of 120 gets +10%.
   - A people of 107 in its eighth year gets about +15%.
   - The frontier reads the home land alone, never the town count. Founding towns widens the land a people can fill (`carrying_capacity`), never the births of those already there; one people of 150 in one town or in three is equally near its frontier.

Birth-spacing customs were checked and are not the cause. They add a little maternal and newborn safety and take nothing from births.

Random afflictions (crisis outbreaks, hunger seasons, fires, drowning) are untouched. They are the setbacks against this growth.

**On screen.** Once a whole year has been counted, the People tile reads "born 4 · buried 5" (the last year, the engine's own count), amber when more are buried than born. In the first year it keeps its old note, and its card says "so far".

When the people shrank, the card says what took them:
- If deaths outside the ordinary toll cover the shortfall, it names the largest by cause (`GameState.rolling_death_causes`), for example "More are buried than born: 8 lost to fire."
  - The card always uses plain words, never the ledger's raw cause (`dwindling_cause.gd misfortune_words`). A god's order that killed reads "the god's word"; a collapse or accident at work reads "accidents at work". Other causes read "the sea", "the road", "captivity", "war" and so on. A cause with no plain word reads "8 died by misfortune".
  - Each day's deaths are booked under that day's largest cause, but the natural share of the day is kept as natural (`consequence_engine.gd`, `GameState.reclassify_death_cause`), so a long fever season does not swallow ordinary old age.
- Otherwise it explains the ordinary toll by the winter tally's rule (`dwindling_cause.gd short_reason`), for example "fevers among the old".

The note has room for about 19 letters (every top-strip value must fit at 1280 wide), so where the people live and whether all are fed are on the card's first lines; a hungry day still takes the note.

**Engine, headless, one town for these 12 years** (`tools/sim/demography_probe.tscn`):

| Seed 74119, leaders' split | Main | This branch |
|---|---|---|
| People at year 12 | 97 | 113 |
| Born / died over 12 years | 49 / 71 | 64 / 71 |
| Natural deaths | 56 | 53 |
| Misfortune deaths | 12 | 13 |

- **Seed 5150:** 108 at year 12 (63 born, 75 died, 18 of them by misfortune).
- **Without misfortune** a founding band now grows about 0.4% a year in its first decade.

**Fast sim, 2 seeds, 600 years.** People at years 10 / 100 / 300 / 600, main → this branch:

| | Main | This branch |
|---|---|---|
| balanced scenario | 107 / 205 / 1,107 / 3,726 | 123 / 338 / 1,108 / 3,726 |
| balanced temper (founds towns) | 107 / 162 / 1,347 / 27,982 | 123 / 289 / 2,658 / 28,408 |
| growth path (cautious-caring temper) | 110 / 238 / 3,059 / 30,481 | 127 / 390 / 4,914 / 30,493 |
| learning path (open-scholarly temper) | 105 / 176 / 978 / 19,409 | 121 / 289 / 1,688 / 26,972 |

- **Balanced scenario growth** (% a year, 0–10 / 0–30 / 30–100): −1.15 / −0.33 / +0.91 → +0.23 / +0.57 / +1.23.
- **Growth path** at year 300 has 1.85 times the balanced people's number. It stays under the best historical figure for a founders' society (6,000).
- **Year 600** is unchanged: crowding sets the long run.

**People-first suite after the #120 recalibration** (`tools/sim/paths.py`, 3 seeds, 1200 years), main 5d38acce → this branch:

| | Main | This branch |
|---|---|---|
| Founding years, path_balanced (people at 0 / 7.5 / 15 / 30 / 60) | 120 / 111 / 109 / 118 / 161 | 120 / 124 / 131 / 155 / 236 |
| path_growth, same years | 120 / 112 / 112 / 124 / 173 | 120 / 126 / 134 / 162 / 252 |
| path_learning, same years | 120 / 110 / 108 / 117 / 154 | 120 / 122 / 130 / 154 / 227 |
| towns_balanced / growth / learning at year 300 | 3,627 / 4,844 / 2,270 | 5,453 / 6,154 / 3,647 |
| towns_balanced / growth / learning at year 600 | 30,239 / 30,858 / 30,769 | 30,250 / 30,861 / 30,767 |

- One-town paths meet at their land's limit by year 300 (path_balanced 1,162 on both).
- The branch raises no flag that main does not: 62 flags here, 64 on main. All are the same rows, mostly the food-labor share and the towns' year-600 numbers.

**Calibration.** The engine truth runs were regenerated on this branch. With the younger founders, the two balanced seeds now disagree by more than the tolerance in two places: known practices at year 5 (26 versus 33) and discoveries by year 15 (72 versus 98). The surrogate lies between them, and `check.py` marks those rows "seed" (see docs/research/SURROGATE_SIM.md).

### C. Searching the land (owner: `resource_system.gd` survey/deposit/extraction yield, survey scripts)
- **Searched land.** Each people (each town in its own scope) keeps `survey_cover` (0..1).
  - It rises with searcher-days over the land worked: about 1 searcher per 60 people keeps it near 0.6 over a few years.
  - It sags slowly without searchers (paths overgrow, finds are forgotten): −5% a year.
- **Cutters and diggers yield** × (0.75 + 0.5 × survey_cover). An unsearched land gives three quarters; a well-searched land gives up to 1.25.
- **Finds.** Each month, a seeded roll at stated odds ∝ searchers finds a new deposit (stone, clay, ore, fibre, salt; later metals) in the land, or improves a known one. Told plainly, once per find.
- Show survey cover, its effect on cutting and digging, and the find odds where the land and work are shown.

### D. Making and goods: the first currency (owner: `civilian_goods.gd`, `economy_system.gd` stages/markets, `trade_ledger.gd`/`trade_stances.gd` barter, weapon making)
- **Makers make goods** from what is cut, dug and carried to them. Goods are counted in one unit (goods-worth), and goods have value.
- **Barter starts in year one.**
  - The first money stage is barter, named so (no longer a pre-economy "subsistence" with nothing traded).
  - Households trade goods for food and materials. Prices are kept from year one.
  - Market access grows with carriers and makers.
  - The enterprise rung "Stalls and hired workshops" (`enterprise.gd`) becomes reachable under barter once goods change hands (update its gate).
- **Goods are the first currency.**
  - With other peoples, goods buy resources, weapons and, in some cases, people. People here means families who come to work for goods, or captives ransomed; non-graphic, adults, plain words.
  - Trading goods for goods stays coarse: no fine-grained goods-for-goods market.
  - Use the trade ledger's existing barter form.
- **Weapons are always expensive.**
  - Arms are made by makers from materials, at a high maker-day and material cost per armed fighter (spears and bows early, more later).
  - They are hard to make early. They are kept in a weapons stock that the military draws on (workstream E reads it through a small API you provide: `weapons_held()`, `take_weapons(n)`).
  - Unarmed fighters fight with improvised arms.
  - Weapons can be traded for goods.
- **Productivity feeds might.** A making, carrying people grows rich in goods, buys and makes arms, and fields better-armed fighters.
- Show goods made a day, their worth, what they buy, and weapons in stock on the Wealth/Trade screens.

### E. Keeping watch is the military (owner: `military_campaign.gd` recruitment/training/manpower, `hud/war_board.gd` and military dock content, `civilization_combat.gd` ledger)
- **The keeping-watch share of the people is the military manpower.** There is no separate recruit step.
  - Remove aggregate recruits and the recruit and draft queue as the player's lever: raising the watch share raises manpower.
  - Drill happens within the watch over time; weapons come from workstream D's stock.
- **The military screen**, top to bottom:
  1. **Total manpower** (the watch: its number and the share of the people).
  2. **Home guard and defence**: an allocation (number or share) that defends home and the towns. The home general leads it.
  3. **Offensive troops**: the rest, in bands led by offensive generals (the existing general system).
  - Leave the rest of the military screen as it is.
- The defender ledger (`civilization_combat.gd`, PR #92) follows. The home guard is spread over home and the towns by population, and the townsfolk still rise when attacked. Offensive troops away do not defend.
- Computer peoples follow the same rules: their rulers set the watch share and the home/offensive split by temperament and war.

### F. Words, effects shown, and different paths for computer peoples (owner: `manual_work.gd` TASKS words, `hud/people_model.gd`, People view, `civilization_controller.gd`/`civilization_strategy.gd` allocation)
- Rename: "making tools" → **"making"**; "keeping the stores" → **"keeping and caring"** (keepers and carers). Update every place the player reads them, including court words and tests.
- **Every role shows its real effect** in the People view: what it does now, and what ten more people there would do, with the engine's numbers. Each workstream exposes a small function for its role's effect (`role_effect(role)` in its owner script), or this workstream reads the existing metrics.
- **Computer peoples take different paths.** Each ruler picks a path by temperament and situation, then lays out the work toward it:
  - growth (food, keeping and caring)
  - making and trade (making, carrying, cutting and digging)
  - war (keeping watch)
  - learning
  - building
  
  The same rules apply to all peoples; only the tendencies differ. No ruler goes all in on learning unless its temperament is scholarly. Log and test the spread of paths across a world's peoples.

## Integration rules (every builder)
- Work only in your worktree, on your `codex/<task>` branch. Never use `git stash`, never merge main yourself, never launch the player game, never remove a worktree.
- Edit files other than your own only in small, local hunks, and list them. Shared hotspots: `game_state.gd`, `consequence_engine.gd` (B owns), `military_campaign.gd` (E owns), `discovery_system.gd` (A owns), `economy_system.gd` (D owns), `world_simulation.gd`, `local_terrain.gd`, `save_system.gd`.
- Every people follows the same rules. Older saves load (sensible defaults, no sudden jumps). Numbers are shown as the engine uses them. Plain, short words.
- Run headless only, and only focused suites: `<godot> --headless --path <wt> -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/<suite>.gd -c --ignoreHeadlessMode`. Fix the tests your change breaks.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Push your branch, verify with `git ls-remote`, and open a PR whose body ends with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
