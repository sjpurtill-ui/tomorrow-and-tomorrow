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

1. **Free builders.** These are the builders the town counts: a great work's crew and military works are already out (`effective_workers`).
   - Their days are halved while a civic work or new homes go up.
   - While a defence stage rises at home, `WALL_SHARE` (40 in 100) of them work on the walls.
2. **Their work.** Builders × working pace × days × (1 + `CRAFT_WORK` a level of craft) × (1 + `KILN_BUILDING` × kiln cover).
3. **Upkeep first,** in `UPKEEP_ORDER`: homes, then work buildings, roads, and fine works last.
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
  - deaths of exposure × (1 − 0.5q);
  - illness deaths × (1 − 0.2q);
  - outbreaks of sickness × e^(−0.4q);
  - fires × e^(−q);
  - health target +0.04q;
  - cohesion target +0.05q.
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
  - The defence ledger (`military_campaign.gd settlement_defense_daily_work`), the people's council (which now counts the builders' work in its days), sieges and town battles read the same numbers.
- **The council.** Skilled builders want walls: the council weighs danger plus `WALL_WISH` (0.14 a level of craft past 2, at most 0.6).
- **Stronger walls.**
  - Walls kept by skilled builders hold × (1 + 0.02 a level of craft).
  - The home town's stone houses add +0.15 × their share to the defences and +0.10 to the stores raiders cannot reach.
  - Sieges and town battles read the snapshot's `defense_bonus`.
- **Wear.** Walls wear 3 in 100 of their integrity a year unless kept (`WALL_KEEPERS`, 2 in 100 of the people building).
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
  - up to 0.05 for the crews at work (full at 40 builders);
  - 0.06 × (cover − 0.5) for the materials in store.
  - The "Builders" factor names them.
- **The payoff** (`undertaking_system.gd apply_outcome`). A work that stands has its strength, rewards and renown × (1 + 0.05 a level of craft), and × 1.15 more under a gifted master builder (geniuses.gd). The work records it as `payoff`.
- **Stated plainly.** The assessment's `stated` text is shown on the great work's screen and in the order's reply, for example: "With 14 builders at craft 3.0 and 400 stone in store (100 in 100 of the materials), the odds it stands are 83 in 100 (a triumph 18, flawed 12, it falls 17); if it stands, its strength, rewards and renown count x1.15 for the builders' craft and Ama, a gifted master builder."

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

**Saves.** Older saves load. A town's fabric is made on its first reckoning, at the grades the people could build at the craft its present builders would have given it (no sudden fall). The craft starts at what the present builders would have built up.

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

`tools/sim/fabric.py` mirrors all of it (the constants are parsed from the game) with a standard great-works policy that every path runs alike. `paths.py` reports the fabric, might, awe, allure and great works, and counts might, awe and allure in its dominance check. The tables are in the PR.
