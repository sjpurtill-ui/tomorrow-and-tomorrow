# The built fabric (2026-10-03)

The user, verbatim:

> Building is still not impactful enough. Building needs to not just be a ridiculous amount of homes for people. That's absurd. People have homes over their heads. What is the quality of the homes? That's the real question. Do they have roads? Are their places beautiful? More builders, more work, more impact, more protection. ... The more building, the more stone, the more power, the more immovable a place is. Builders are critical, and they affect allure, awe, might, and productivity. The more building, the more types of building people know how to do as well, to use different types of materials to make powerful structures. And the more likely they are to succeed with great work, obviously and the more powerful that great work is likely to be.

## What was wrong (Phase 1)

A headless probe on the real engine (`tools/sim/build_probe.tscn`, the building path, 8 years) booked every builder-day to what it worked on:

| Where the builders' days went | Builder-days | Share |
|---|---|---|
| The 9 fixed civic works (the 5 reachable ones done by day 330) | 334 | 0.9% |
| New homes (only when the town is over 80% full) | 232 | 0.7% |
| Nothing measurable (repair of a town already in full repair) | 34,652 | 98.4% |

- Homes were a count. Once every person had a place, builders added nothing.
- Repair is full once 5 in 100 of the people build.
- Defences were raised by the watch alone.
- Builders added at most +0.05 to a great work's odds, and nothing to its payoff.
- Roads were drawing only.
- Timber, stone and fibre piled up unused.
- In the fast sim, the building path was dominated by the war path at year 600.

## The design

`scripts/built_fabric.gd` keeps each town's built fabric (`GameState.built_fabric`, swapped per town through `settlement_model.gd CITY_RESOURCE_DEFAULTS`) and the whole people's builders' craft (`GameState.fabric_realm`).

Every people runs the same code in its own scope. Only how many build differs.

### The builders' days

Every `TICK_DAYS` (10) a town reckons its fabric. `settlement_construction.gd process_day` calls it, so the day's cost is one comparison.

1. **Every builder works one job** (`crews`). These are the builders the town counts: a great work's crew and military works are already out (`effective_workers`). In order:
   - **homes:** every builder while some sleep without a roof; `HOMES_AHEAD` (30 in 100) while new homes go up ahead of need (`housing_work_per_day` reads this crew);
   - **civic:** `CIVIC_SHARE` (half) of the rest while a civic work is in hand (`daily_work` reads this crew);
   - **repair:** what the town's civic works need to be kept in repair, at most `REPAIR_SHARE` (5 in 100) of the people, and half that once in full repair (`settlement_model.gd _advance_city_form` reads this crew);
   - **walls:** at home, `WALL_SHARE` (40 in 100) of the rest while a stage goes up or the walls are mended after a fight;
   - **fabric:** everyone left.
2. **Their work.** Fabric builders × working pace × days × (1 + `CRAFT_WORK` a level of craft) × (1 + `KILN_BUILDING` × kiln cover).
3. **Upkeep first,** in `UPKEEP_ORDER`: homes, the walls (`WALL_UPKEEP`, 1 in 100 of the standing stage's work a year), then work buildings, roads, and fine works last.
   - Upkeep that is not done wears the account down:
     - homes fall a grade (`GRADE_WEAR`, 30 in 100 a year for huts, 3 for stone);
     - roads roughen (`ROAD_WEAR`, 8 in 100);
     - work buildings decay (`WORKS_WEAR`, 5);
     - fine works weather (`BEAUTY_WEAR`, 4).
   - **A people that stops building visibly declines,** and the screens say so.
4. **Improvements** take what is left, by `SPLIT` (homes 35, roads 15, work buildings 20, fine works 30).
   - What one account cannot use goes to the others.
   - Fine works are the sink: carved posts, plazas, painted halls, monuments.
5. **Real materials.** Every improvement takes timber, clay or stone. The town keeps back `RESERVE` (1 a person of each), plus the bills of its civic works and arms, plus the next defence stage's.
   - Builders without materials stand idle, and the screens say so.

### 1. Home quality, not home count

The share of a town's places in each grade:

| Grade | Quality | Build (builder-days a place) | Materials a place | Upkeep a year | Knowledge (any one) | Craft (from, all places at) |
|---|---|---|---|---|---|---|
| windbreaks and lean-tos | 0 | | | 0 | | |
| huts | 0.30 | 3 | timber 0.5, fibre 0.5 | 0.35 | joinery, thatched roofing | 0, 1 |
| timber houses | 0.55 | 8 | timber 2.5 | 0.6 | framed construction, timber post-beam | 1, 3 |
| mudbrick houses | 0.75 | 14 | clay 4, timber 0.5 | 0.8 | adobe walls, mould-made mudbricks | 2, 5.5 |
| stone houses | 1.0 | 30 | stone 7, clay 1 | 0.4 | dry stone walls, dressed stone, kiln-fired brick | 3, 9 |

- New places (a new batch of homes) go up as huts, or as lean-tos before huts are known.
- Places lost to fire or flood are lost from every grade alike.
- **What the homes' quality q (0..1) does** (consequence_engine.gd, crisis_system.gd):
  - the health target +`HOME_WEATHER` (0.03) × (the season's cold + ¾ of its heat) × q, the weather's toll on those who have a roof (the housing shortfall's own exposure deaths are the homes' count, untouched);
  - illness deaths × (1 − 0.2q);
  - outbreaks of sickness × e^(−0.3q);
  - fires × e^(−q);
  - health target +0.03q;
  - cohesion target +0.04q.
- **At q = 0 nothing changes:** the founding years and the 15-year truth runs are untouched by the homes.

### 2. Roads and paths

- **The road index.** Road work a person over `ROAD_FULL` (300 builder-days a person for full roads). It reaches at most:
  - 0.35 for paths;
  - 0.7 with graded roads known;
  - 1.0 with paved haul roads known.
- **Materials.** Graded and paved roads take 0.12 stone a builder-day.
- **What the index R does:**
  - the carriers' hauling target +0.10R;
  - hauls from deposits × (1 + 0.35R);
  - goods between towns, caravans and founding parties × (1 + 0.6R) speed;
  - trade reach × (1 + 0.5R), in city trade and the trade ledger;
  - townsfolk who reach a fight in time × (1 + 0.3R).
- **The map follows it.** The roads the map draws come from the index (`ROAD_DRAW`: footpath, cart track from 0.32, made road from 0.62), never better than what is known (`settlement_roads.gd`). The army's march terrain reads the same tier.

### 3. Beauty: awe and allure

- **What beauty is.** Fine-work points a person; beauty = 1 − e^(−points / `BEAUTY_SCALE` 600).
  - A builder-day of fine work is worth 1 + 0.2 for each fine-work practice known (wall painting, megaliths, terraces, relief carving, niched facades, stepped tombs and temples, palace painting, portraits).
  - Each builder-day takes 0.2 loads of stone, timber or clay.
- **At home:**
  - cohesion +0.03;
  - love of the god +0.05 (divine_regard.gd);
  - Splendor +0.40 (standing.gd), and through it pride and awe.
- **Abroad:**
  - the allure of our culture +0.50 (standing.gd), so migration in, envoys and trade;
  - other peoples' respect +0.10.

### 4. Might and immovability

- **Builders on the walls.**
  - They work beside the watch at `BUILDER_WALL_WEIGHT` (1.5) a watchman's share, × (1 + 0.05 a level of craft).
  - On stone stages (walled districts, bastions) the watch alone works at `STONE_WATCH` (0.35): stone needs builders' skill.
  - The defence ledger (`military_campaign.gd settlement_defense_daily_work`), sieges and town battles read the same numbers.
  - **The council and the screens judge the next stage with the walls crew that would go to it** (`wall_builders_ready`, recorded at each reckoning). A watchman's own rate never includes the builders, and the watch the council asks for is what remains after the builders' work (`settlement_defense_full_pace_workers`, `home_defense.gd watch_fix`).
- **The council.** Skilled builders want walls: the council weighs danger plus `WALL_WISH` (0.14 a level of craft past 2, at most 0.6).
- **Stronger walls.**
  - Walls kept by skilled builders hold × (1 + 0.02 a level of craft).
  - The home town's stone houses add +0.15 × their share to the defences and +0.10 to the stores raiders cannot reach.
  - Sieges and town battles read the snapshot's `defense_bonus`.
- **Wear.** Walls wear 3 in 100 of their integrity a year while their upkeep goes undone; the walls crew mends them after a fight (with a fifth of the watch).
- **Might** (standing.gd) gets +0.40 × the defences over the strongest works' bonus.
- **Other peoples** weigh our fighting strength × (1 + 0.8 × the defences' bonus): awe, contempt and war deterrence.

### 5. Productivity: work buildings

- **Cover.** Work buildings a person over `WORKS_FULL` (600 builder-days a person). Each builder-day takes 0.25 loads of stone, timber or clay.
- **Each kind acts once what it needs is known.** At full cover:

| Work building | Role | Full cover |
|---|---|---|
| workshops | making | goods × 1.20 |
| granaries | getting food | stored food rots × 0.75 |
| kilns (kiln control) | building | builders' work × 1.10 |
| storehouses and yards | carrying, cutting and digging | hauling +0.06, every deposit +15% |
| wells and water works (well siting) | carrying | water each carrier brings × 1.30 |

### 6. Builders' craft

- **Experience.** Every builder adds a builder-day a day. The people's experience fades e-fold over `CRAFT_YEARS` (36), a working life and a half.
- **The level.** Living experience a person over `CRAFT_PER_LEVEL` (275), up to 10. It settles at builders' share of the people × 365 × pace × 36 / 275.
- **Each level:**
  - builders work 3% faster;
  - the infrastructure line learns 4% faster;
  - the construction signal every building question reads rises 0.12 (civilization_day.gd context): **knowledge by doing**;
  - a builder on the walls works 5% more;
  - walls hold 2% better;
  - a great work's capability +0.025.
- **It gates the dwelling grades** (table above).

### 7. Great works

- **The odds** (`wonder_concept.gd assess`). Capability adds:
  - 0.025 a level of craft;
  - up to 0.05 for the crew on the work (full at 15 builders on it; a work not yet begun counts the fifth of the builders it would get);
  - 0.06 × (cover − 0.5) for the materials in store.
  - The "Builders" factor names them.
- **The roll reads the whole people's craft** even while one town's count is in scope (`craft_of`), so it uses the odds and payoff the screen states.
- **Materials.** The fabric never takes what a great work under way has still to use (`great_bills`).
- **The payoff** (`undertaking_system.gd apply_outcome`). A work that stands has its strength, rewards and renown × (1 + 0.05 a level of craft), and × 1.15 more under a gifted master builder (geniuses.gd). The work records it as `payoff`.
- **Stated plainly.** The assessment's `stated` text is shown on the great work's screen and in the order's reply, for example: "With 14 builders on the work at craft 3.0 and 400 stone in store (100 in 100 of the materials), the odds it stands are 83 in 100 (a triumph 18, flawed 12, it falls 17); if it stands, its strength, rewards and renown count x1.15 for the builders' craft and Ama, a gifted master builder."

### Costs

- **The building path leans harder:** `work_paths.gd WORK` building is Construction 22 and Extraction 8 (was 10 and 4). It keeps about 20 in 100 of the workers building, against 14 for balanced.
- **What it pays:** fewer makers, carriers, carers and watchmen. Its people are about 3% fewer than a balanced people's at year 600, with more infant deaths, a smaller field force and fewer goods a head.
- **Everything the fabric does costs** builders' hands, timber, clay and stone, and upkeep for ever after.

### Shared-file edits (minimal, marked)

| File | Edit |
|---|---|
| `game_state.gd` | two vars (`built_fabric`, `fabric_realm`) and their reset, marked `[built-fabric]` |
| `military_campaign.gd` | the builders' hands in `settlement_defense_daily_work`; walls' quality and stone in `settlement_defense_snapshot`; walls' wear, marked `[built-fabric]` |
| `discovery_system.gd` | one factor in the two leader-factor chains, marked `[built-fabric]` |
| `settlement_model.gd` | one default key; trade speed and range; convoy speed |

**Saves.** Older saves load.
- A town's fabric is made on its first day, at the grades the people could build at the craft its present builders would have given it (no sudden fall); every reader sees it from that day, and the realm hears of the town at once.
- Its roads start at the kind its map already drew for what the people know (`settlement_roads.gd known_tier`), so maps and marches lose nothing.
- The craft starts at what the present builders, read for the whole people, would have built up.

## On screen

- **The People view (building row):** "Homes 67/100, roads 43, beauty 48; craft 3.8." / "Ten more: 120 places a year to mudbrick, craft toward 4.6."
  - When too few build: "Too few to keep it all: homes fall a grade."
  - When materials are short: "Ten more: little, materials are short; more cutters and diggers."
- **The Buildings page, The Town tab:**
  - Homes by kind: one bar of the grades, and what the next grade needs.
  - The built fabric: bars for homes, roads, beauty, work buildings, walls and stone, craft and upkeep kept.
  - Falling into disrepair, when it is.
  - Where the builders' days go: upkeep, homes, roads, work buildings, fine works, walls and idle.
  - What the built fabric does, line by line with the rule it comes from.
  - What ten more builders would buy now.
- **The town page:** "Homes and streets" (quality, roads and beauty, or "falling into disrepair") and "Builders' craft" (now, and where it settles).
- **Standing:** Might's reason names "walls and stone +N"; Splendor's names "our builders' fine works (+N)".
- **The capacity history** names "How good our homes are" and "Roads and paths" in the infrastructure capacity.
- **Great works:** the odds and the payoff with the builders' numbers.

## Fast sim

`tools/sim/fabric.py` mirrors all of it (the constants are parsed from the game) with a standard great-works policy that every path runs alike. `paths.py` reports the fabric, might, awe, allure and great works, and counts might, awe and allure in its dominance check.

**Main → this branch** (`python tools/sim/paths.py`, 3 seeds, 600 years; main read with `SIM_GAME_REV=ba77e964`, where the fabric is off but the walls and the standard great works run as they did).

How to read the columns:
- **might, awe, allure:** standing's readings (might counts the watch at the ready and, on this branch, the walls).
- **defence:** the defences' bonus.
- **out/wk:** output per worker.
- **per cutter:** loads cut a day.
- **maker cap:** goods a maker could make a day.
- **homes:** the homes' quality.
- **IMR:** infant deaths per 1,000.
- **works:** great works standing.
- **renown:** their allure points.

| Path | Year | people | known | might | defence | awe | allure | out/wk | per cutter | maker cap | homes | IMR | works | renown |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| balanced | 100 | 360 → 379 | 446 → 448 | 0.19 → 0.21 | 0.04 → 0.04 | 0.22 → 0.31 | 0.27 → 0.35 | 1.84 → 2.02 | 0.53 → 0.55 | 1.384 → 1.464 | 0.00 → 0.57 | 188 → 190 | 5.0 → 5.7 | 34 → 46 |
| balanced | 300 | 1,292 → 1,279 | 760 → 761 | 0.17 → 0.26 | 0.04 → 0.14 | 0.29 → 0.40 | 0.26 → 0.38 | 1.99 → 2.00 | 0.51 → 0.55 | 1.426 → 1.561 | 0.00 → 0.67 | 198 → 198 | 18.7 → 19.7 | 153 → 186 |
| balanced | 600 | 4,297 → 4,413 | 1,130 → 1,130 | 0.17 → 0.26 | 0.04 → 0.15 | 0.28 → 0.40 | 0.26 → 0.37 | 1.98 → 1.98 | 0.51 → 0.56 | 1.434 → 1.602 | 0.00 → 0.68 | 194 → 195 | 36.7 → 39.7 | 305 → 389 |
| growth | 100 | 420 → 407 | 455 → 454 | 0.16 → 0.18 | 0.04 → 0.04 | 0.20 → 0.29 | 0.31 → 0.39 | 1.84 → 2.00 | 0.53 → 0.54 | 1.369 → 1.429 | 0.00 → 0.49 | 162 → 163 | 4.3 → 5.7 | 31 → 45 |
| growth | 300 | 1,385 → 1,385 | 763 → 763 | 0.14 → 0.23 | 0.04 → 0.13 | 0.27 → 0.37 | 0.32 → 0.42 | 1.97 → 1.97 | 0.50 → 0.53 | 1.413 → 1.518 | 0.00 → 0.62 | 173 → 172 | 18.0 → 19.7 | 150 → 182 |
| growth | 600 | 4,836 → 4,834 | 1,133 → 1,134 | 0.15 → 0.23 | 0.04 → 0.13 | 0.28 → 0.37 | 0.32 → 0.41 | 1.79 → 1.80 | 0.54 → 0.58 | 1.399 → 1.560 | 0.00 → 0.63 | 168 → 169 | 36.0 → 39.7 | 302 → 381 |
| making | 100 | 364 → 367 | 445 → 447 | 0.16 → 0.19 | 0.04 → 0.04 | 0.21 → 0.29 | 0.26 → 0.34 | 2.05 → 2.06 | 0.52 → 0.54 | 1.356 → 1.431 | 0.00 → 0.52 | 192 → 192 | 5.0 → 5.7 | 32 → 45 |
| making | 300 | 1,244 → 1,256 | 759 → 759 | 0.16 → 0.24 | 0.04 → 0.13 | 0.28 → 0.38 | 0.26 → 0.37 | 1.99 → 2.01 | 0.57 → 0.53 | 1.413 → 1.503 | 0.00 → 0.63 | 198 → 200 | 18.7 → 19.7 | 151 → 183 |
| making | 600 | 4,237 → 4,218 | 1,130 → 1,129 | 0.15 → 0.24 | 0.04 → 0.14 | 0.28 → 0.38 | 0.26 → 0.36 | 1.98 → 1.99 | 0.51 → 0.56 | 1.424 → 1.574 | 0.00 → 0.65 | 195 → 195 | 36.0 → 38.7 | 298 → 373 |
| war | 100 | 350 → 347 | 445 → 445 | 0.63 → 0.66 | 0.04 → 0.04 | 0.42 → 0.50 | 0.20 → 0.28 | 2.00 → 2.00 | 0.52 → 0.54 | 1.350 → 1.422 | 0.00 → 0.51 | 192 → 192 | 5.0 → 5.3 | 32 → 43 |
| war | 300 | 1,258 → 1,222 | 760 → 760 | 0.60 → 0.69 | 0.04 → 0.13 | 0.48 → 0.58 | 0.21 → 0.31 | 1.97 → 1.97 | 0.50 → 0.53 | 1.400 → 1.495 | 0.00 → 0.62 | 200 → 199 | 18.7 → 19.3 | 151 → 180 |
| war | 600 | 4,187 → 4,180 | 1,129 → 1,129 | 0.58 → 0.67 | 0.04 → 0.13 | 0.47 → 0.57 | 0.21 → 0.30 | 1.95 → 1.95 | 0.52 → 0.55 | 1.416 → 1.556 | 0.00 → 0.62 | 195 → 195 | 36.3 → 39.0 | 300 → 375 |
| learning | 100 | 394 → 386 | 511 → 511 | 0.16 → 0.18 | 0.04 → 0.04 | 0.24 → 0.32 | 0.29 → 0.36 | 1.85 → 2.03 | 0.55 → 0.55 | 1.331 → 1.400 | 0.00 → 0.50 | 193 → 193 | 5.0 → 5.3 | 34 → 49 |
| learning | 300 | 1,212 → 1,240 | 814 → 813 | 0.15 → 0.24 | 0.04 → 0.13 | 0.31 → 0.41 | 0.29 → 0.39 | 1.82 → 1.83 | 0.54 → 0.57 | 1.409 → 1.518 | 0.00 → 0.60 | 197 → 197 | 18.7 → 19.3 | 153 → 187 |
| learning | 600 | 4,274 → 4,326 | 1,176 → 1,176 | 0.15 → 0.23 | 0.04 → 0.13 | 0.30 → 0.39 | 0.27 → 0.37 | 1.97 → 1.99 | 0.53 → 0.57 | 1.417 → 1.551 | 0.00 → 0.61 | 195 → 196 | 36.7 → 39.3 | 305 → 386 |
| building | 100 | 366 → 376 | 445 → 447 | 0.17 → 0.24 | 0.04 → 0.15 | 0.21 → 0.36 | 0.27 → 0.39 | 1.88 → 1.89 | 0.53 → 0.55 | 1.337 → 1.484 | 0.00 → 0.70 | 192 → 197 | 4.7 → 5.7 | 30 → 50 |
| building | 300 | 1,263 → 1,234 | 759 → 759 | 0.15 → 0.46 | 0.04 → 0.49 | 0.28 → 0.52 | 0.26 → 0.40 | 2.01 → 1.87 | 0.50 → 0.58 | 1.407 → 1.602 | 0.00 → 0.81 | 200 → 202 | 18.3 → 19.3 | 149 → 195 |
| building | 600 | 4,186 → 4,317 | 1,129 → 1,129 | 0.15 → 0.44 | 0.04 → 0.50 | 0.28 → 0.50 | 0.26 → 0.39 | 1.99 → 1.99 | 0.51 → 0.58 | 1.416 → 1.659 | 0.00 → 0.84 | 195 → 200 | 35.7 → 38.7 | 297 → 411 |

**The fabric on this branch:**

| Path | Year | Builders % of workers | Craft | Homes | Stone share | Roads | Beauty | Work buildings | Defences |
|---|---|---|---|---|---|---|---|---|---|
| balanced | 300 | 14.5 | 3.6 | 0.67 | 0.10 | 0.39 | 0.53 | 0.45 | 0.14 |
| balanced | 600 | 13.9 | 3.7 | 0.68 | 0.12 | 0.43 | 0.48 | 0.54 | 0.15 |
| growth | 300 | 12.3 | 3.1 | 0.62 | 0.03 | 0.38 | 0.44 | 0.36 | 0.13 |
| growth | 600 | 12.5 | 3.2 | 0.63 | 0.03 | 0.34 | 0.41 | 0.45 | 0.13 |
| making | 300 | 12.9 | 3.2 | 0.63 | 0.05 | 0.38 | 0.46 | 0.38 | 0.13 |
| making | 600 | 12.4 | 3.5 | 0.65 | 0.07 | 0.38 | 0.44 | 0.50 | 0.14 |
| war | 300 | 12.5 | 3.1 | 0.62 | 0.03 | 0.37 | 0.44 | 0.36 | 0.13 |
| war | 600 | 11.9 | 3.3 | 0.62 | 0.04 | 0.36 | 0.42 | 0.47 | 0.13 |
| learning | 300 | 13.2 | 3.1 | 0.60 | 0.02 | 0.39 | 0.45 | 0.35 | 0.13 |
| learning | 600 | 11.9 | 3.2 | 0.61 | 0.04 | 0.38 | 0.42 | 0.45 | 0.13 |
| building | 300 | 21.9 | 5.1 | 0.81 | 0.35 | 0.46 | 0.72 | 0.77 | 0.49 |
| building | 600 | 19.8 | 5.4 | 0.84 | 0.38 | 0.62 | 0.65 | 0.89 | 0.50 |

**What it shows**

- **The building path pays off in its own measures.** Against balanced at year 600 it has:
  - might 0.44 against 0.26, and defences 0.50 against 0.15 (walled districts and a stone town);
  - awe 0.50 against 0.40, and allure 0.39 against 0.37;
  - homes 0.84 against 0.68, with 38 in 100 of its places stone against 12;
  - its cutters 4% and its makers 4% more productive;
  - great-work renown 411 against 389.
- **It is no longer dominated.** On main the extended dominance check found it dominated by balanced and by making.
- **It pays real costs:**
  - 2% fewer people than balanced at year 600, and 4% fewer at year 300;
  - infant deaths 200 against 195 (fewer carers);
  - a field force 30% smaller (fewer on the watch);
  - fewer goods a head (4.6 against 5.0).
- **It does not dominate.** War keeps far more might (0.67) and awe (0.57); growth keeps more people and allure (0.41) and fewer infant deaths.
- **Balanced peoples change little.** People and knowledge stay within seed noise of main, and infant deaths and life expectancy are unchanged.
  - Every path gains a modest fabric (homes 0.6–0.7) because about 14 in 100 of every people's workers build.
  - Those builders had nothing to do before.
- **Flags.** The suite has 27 flags here and 26 on main. This branch clears main's two "building dominated" flags. Its new flags are:
  - **The 600-year population of towns_balanced is 20,027, against the band high of 20,000.**
    - 6 seeds: 20,223 here, 19,949 on main.
    - The seed spread is about ±700, and main already sits on the band's edge.
    - Better homes add about 1%. No single fabric effect carries it: switching off the homes, the works, the beauty or the roads one at a time each leaves it within ±150.
  - Two single-sample food-share dips at year 300, on growth and building. The food share averaged over years 200–400 is 34.6 here against 35.0 on main, over 3 seeds.
  - A milestone exactly on its band's low (split_balanced alphabet at 520).
- **Calibration.**
  - The truth runs were re-recorded on this branch: seven 15-year runs, the six before plus a new `path_building` run, one engine at a time, 80–127 s each.
  - `check.py --strict` passes: 7 runs within tolerance, score 38.2, only the listed food-days gaps.
  - `path_building` at year 15, engine against surrogate: people 133 / 128, infant deaths 258 / 267, discoveries 50 / 45, cohesion 0.84 / 0.86.
