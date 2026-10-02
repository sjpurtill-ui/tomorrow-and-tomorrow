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
