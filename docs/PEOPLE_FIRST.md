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

**A recalibrated (2026-10-02, the learning pace).** The user's new game learned about 20 ways a year from its founding. That came from 7 learners (10.6%) under the leaders' old split, which #116 now caps (a balanced split puts 3.5% on learning, the learning path 15%).
- **Per learner, the engine was unchanged.** A fresh good village with learners held at 3 learned 110 ways by year 16 on main, against 106 on the engine before the learning overhaul (97a32dd2). With 7 learners: 206 against 203.
  - Only when goods ran out was main slower. On a poor site, 7 learners learned 88 by year 16 against 165, because goods cover halves learning.
- **What changed.**
  - **The founding ages' questions ask more work.** `PACE_BY_YEAR` is 4.2 at year 0 (was 7.0) and 3.9 at 60, back to full pace by 150, with years 200 and later unchanged.
  - **The age can spare more learners at its founding:** 6.5% (`SUSTAINABLE_SPECIALISTS`, was 4%). A balanced people, capped at 3.5% on learning, now banks no lead. The lead stays 0.06 years a year per doubling: at 0.03 the fast sim's learning path fell within 3% of balanced knowledge at 600 and counted as dominated.
- **Engine (truth probe, a fresh world, seed 74119, with #116's caps).** Known by year 16, including the 10 a people starts with:

| Path | Main | Recalibrated |
|---|---|---|
| balanced | 86 | 54 |
| growth | 95 | 59 |
| making | 84 | 53 |
| war | 86 | 54 |
| building | 84 | 53 |
| learning | 223 | 190 |

  - The learning path learns about 3.5 times a balanced people. It keeps 4 times the learners (8 against 2 at year 16), and every learner counts.
- **Fast sim (leaders' tempers, 3 seeds; main / recalibrated).** Ways learned by year 16, then pit firing, copper, writing, bronze and place value years, then population at 150 / 300 / 600:

| Temper | Main | Recalibrated |
|---|---|---|
| balanced | 50; 65 / 129 / 221 / 328 / 473; 262 / 1,380 / 28,128 | 30; 103 / 188 / 238 / 334 / 476; 199 / 921 / 25,399 |
| open-scholarly (learning) | 180; 17 / 54 / 189 / 295 / 429; 266 / 998 / 20,659 | 126; 18 / 60 / 199 / 308 / 445; 274 / 1,058 / 21,989 |

  - Writing, bronze and place value hold their bands. Pit firing and copper come later, and the first centuries grow more slowly. The fast sim's early research runs about 1.5 times slower than the engine's (balanced: 50 against 76 learned by year 16 on main), so it shows the early cost larger than the game will.

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
