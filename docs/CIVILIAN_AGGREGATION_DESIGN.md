# Civilian Goods and population-driven cities: design

Status: **proposal for review**, not yet implemented. The branch is `codex/civilian-aggregation`, based on `codex/throughput` at d1fa4ed.

## Why

The simulation tracks every civilian object: woven containers, cordage bundles, drying mats, 602 civilian industry outputs, and up to 2,048 individual building plots per city with repair bills and retrofits. A player never manages any of that, and it costs time every simulated day.

Profiled in the real game scene (year-71 fixture), these parts take about a quarter of each simulated day:

| Share of day | System |
|---|---|
| ~8% | Building-material planning (fabric targets, recommendations) |
| ~8% | Settlement fabric operations (repair bills, retrofit choice, record validation) |
| ~6% | Household crafts |
| ~4% | Civilian investment and production planners |
| ~2–3% | Persistent civilian production lines |

They also cause the 50–200 ms hitches on rival review days. Beyond that direct cost, the economy, storage-loss and material-flow loops run once per good type, so every good we remove makes those loops cheaper as well.

Decided with the user:
- Only civilian goods are aggregated. Military equipment stays granular, and raw materials stay.
- Ordinary buildings follow population, era and adopted techniques. Landmarks and special infrastructure stay individual.

## 1. Civilian Goods

### What stays separate
- **Raw materials:** Food, Freshwater, Timber, Stone, Clay, Fiber Plants, Salt, Medicinal Plants, the ores, Coal, Peat, Bitumen, Crude Oil, Sulfur, Nitrates, Coin, and the other extracted resources.
- **Food processing:** batches, grain, canning, preparation and selected foods. Their granularity drives food outcomes and is out of scope here. They could be a later phase.
- **Military equipment:** weapons, armor, shields, ammunition, military consumables, Transport Carts, and ship parts.
  - Their recipes are **flattened**: each military item consumes raw materials, plus Civilian Goods for general fittings, plus labor, and is gated by the same discoveries.
  - The civilian intermediate chains that feed them today (Woven Cloth → Padded Armor, Wheel Pairs → Transport Carts, Rope Coils → ships) are removed.
  - This resolves the main risk the inventory found: military bills of materials depend on civilian intermediates.

### The one stock
Each city keeps one `Civilian Goods` stock, measured in goods-units.

**Production.** Once a day, Crafting workers make goods:
- The rate is workers × base rate × technique output multiplier × tools factor.
- Each unit consumes a generic raw-material basket that shifts with the era. It starts as timber, fiber, clay and stone, and moves toward ores, fuel and glass inputs as industry discoveries are adopted.
- Output is limited by which raw materials are available. There are no recipes, no lines, and no retooling.

**Wear.** Goods decay slowly, as households use them up.

**Target stock.** Each person should hold a target amount of goods, and that target rises with era. The ratio of stock to target is the city's **goods coverage**, from 0 to 1.

**Outside production.** Plants from technology operations add Civilian Goods output instead of named products. Water works, rail and docks draw Civilian Goods for construction and maintenance instead of named parts.

### Discoveries as technique objects
The discoveries behind former products stay in the research chain with their art: basketry (woven containers), cordage, flaking, hafting, pottery and firing, joinery, weaving, glassmaking, the textile and machine-tool lines, and so on. Each one becomes a **technique**:

- **Effects.** A technique keeps its existing effect values: tool_quality, craft_output, storage, food_spoilage, construction_rate, haul_capacity and the rest, from `society_model.gd:74-98` and `resource_knowledge_catalog.gd:66-76`.
- **Phase-in.** Adoption is the adoption period. It already grows monthly through teaching, practice and attention (`society_model.gd:131-152`).
- **Physical grounding.** A technique's effect = adoption × effect × **goods coverage**. Knowing how to weave baskets helps only as far as households actually hold the goods.
  - This replaces the per-product stock factor, `Craft.factor(id)`, at `society_model.gd:208`.
- **Production techniques** also raise the Civilian Goods output multiplier and move the raw-material basket.

### What reads goods coverage
Each direct read of a named stock becomes a read of coverage or adoption:

| Today | Becomes |
|---|---|
| Sealed Clay Vessels add food storage (`food_system.gd:476`) | Storage techniques × coverage add food capacity |
| Drying Mats and Smoke Frames set drying and smoking throughput (`food_system.gd:399,408`) | Food-drying and smoking technique adoption × coverage |
| Joined Timber Components are an input to Framed Hall, the kiln and cisterns | Civilian Goods cost |
| Clothing lots (`household_clothing.gd`) cut exposure | Clothing coverage = goods coverage × adopted textile techniques |
| Study media, lab goods and instruments | Civilian Goods cost, plus technique gates. The research-speed effects stay attached to adoption. |
| Economy `BASE_VALUES` | Civilian Goods gets one trade value, so it can be exported or imported |

Clothing lot management (`household_clothing.gd`, with its lots, washing and wear) is removed. Cold and weather exposure then reads clothing coverage.

### What gets removed
- **Crafts and production lines:**
  - `opening_craft_practice.gd`: PRODUCTS, recipes, targets, daily craft.
  - The civilian rows in `civilian_industry.gd` (military rows move to the flattened military recipes).
  - Civilian jobs in `persistent_production` and the civilian side of `equipment_queue`.
- **Planners:** the civilian branch of `civilian_production_planner`, and the civilian investment chain entries that only buy parts. Military and cart planning keep a slimmed recipe walk over flattened recipes. `ai_workshop_turnover` and `workshop_steward` shrink to military lines only.
- **Detailed industry:** the specialized workshop chains that only make civilian intermediates, such as casting, induction, pattern, weld, vacuum and slitting, where they don't feed military items. The technique discoveries and their effects remain.

### UI
- **Production dock:** the CIVILIAN tab becomes one **Civilian Goods** panel. It shows the stock, daily output, wear, coverage, the raw-material basket, and the list of adopted techniques with adoption bars and research art.
- **MILITARY tab:** unchanged.
- **Household crafts rows:** replaced by that same panel.

## 2. Population-driven cities

### What stays individual
- Undertakings and wonders.
- Water conveyance lines and water/waste works.
- Naval docks, rail freight and communications links.
- Civilian care, which is already aggregate.
- Settlement defense.
- The seven early **civic milestones**: Hearth Circle, Lean-to Shelters, Storage Pits, Public Stores, Open Work Area, Framed Hall and Gathering Yard. They become city-wide milestones rather than buildings, stay in `settlement_completed`, and keep their existing effects. About 20 files read these names, and they are cheap.

### City capacities replace plots
Each city holds a few scalar **built capacities**:
- housing (people);
- storage, by store type: yard, dry, covered, sealed, secure;
- workshop (effective work places);
- civic.

Plus two city-wide values:
- **fabric tier:** era of construction, reached through the existing `_supported_fabric_tier` rules (age, labor and building-technique adoption);
- **condition:** 0–1.

How they behave:
- **Growth.** Construction labor adds capacity toward targets set by population and era. Each addition costs raw materials plus Civilian Goods, in era-weighted amounts that follow the existing `building_material_operations` profiles, which become techniques.
- **One housing model.** `housing_capacity` stays the authority. Plot `resident_capacity` goes away.
- **Decay.** Condition decays slowly and maintenance restores it, drawing from the same pool. No per-building repair bills.
- **Damage.** Combat, siege and joint-strike damage (`civilization_combat.gd:128`, `joint_effects.gd:64`, `military_campaign.gd:3388`) lower condition and remove a share of capacity. Siege recovery copies capacities instead of a plot layout.
- **What readers switch to:**
  - workshop and storage functions (`consequence_engine.gd:685-696`), storage capacities (`resource_system.gd:887-905`) and workplace condition (`persistent_production.gd:262`) read capacities × condition;
  - territory size (`civilization_system.gd:4762`) reads population and fabric tier;
  - undertaking siting reads the city's generated footprint radius.
- **Building-specific discoveries.** The effects of lime mortar and framed construction come from adoption × condition, not from the best plot of one form (`opening_craft_practice.gd:81-114`).

### Removed
- Settlement plots, nuclei, routes and plot history, together with their growth, occupancy, retrofit and repair machinery. That covers most of `SettlementModel` morphology growth, `settlement_fabric_operations`, `settlement_fabric_inspection` and `settlement_fabric_response`.
- `building_material_investment`, and the fabric sections of `local_material_reserves`.
- `building_ledger` becomes a short history of milestones and capacity growth.

### Visuals from population
A city's look is generated deterministically from:
- its seed, position and terrain;
- population, which sets the footprint radius and building count;
- fabric tier and classification, which set architecture family, density, storeys and street pattern;
- condition, which sets damage and dereliction;
- its landmarks, which are placed individually.

The template is `foreign_settlement_visual.gd:22-63`: it computes `sqrt(pop)*1.6` buildings, lays out procedural courtyards and draws them with the organic kit. The existing kits, `early_settlement_visual`, `organic_town_visual` and `settlement_architecture_kit`, render the result.

Growth must look continuous. Building *i* keeps its place as population rises, and rings extend outward. Visuals rebuild when population crosses a step or the tier or condition changes, instead of on `morphology_revision`.

The map lens reports city capacities and techniques, not a single plot.

### UI
- **Construction dock:** PROJECTS shows civic milestones, capacities under construction (housing, storage, workshops) and infrastructure. COMPLETED and HISTORY show milestones, landmarks and capacity growth.
- **Settlement dock:** the building summary becomes the capacities.

## 3. Saves

The format changes. The development campaign is disposable, but a one-time load migration keeps the current test save and the year-71 performance fixture usable:
- Every civilian manufactured stock converts to Civilian Goods by a fixed value table. Military items are kept.
- Plots sum into capacities: residents → housing, storage plots → storage by type, workshop plots → workshop. Mean condition becomes city condition, and the highest `fabric_generation` becomes the tier.
- Civilian production jobs are dropped and their reserved inputs refunded. Clothing lots convert to Civilian Goods.

Because the day itself changes, bit-identical comparison against old saves no longer applies. Validation becomes outcome comparison, as for the rival spans: population, food, health, knowledge, discoveries and military strength over 150 days, before and after. The new model should reproduce the macro trajectories without matching the old micro-simulation exactly.

## 4. Phases

Each phase is one coherent, tested and pushed checkpoint.

1. **Civilian Goods core.** The stock, production, wear and coverage; techniques drive effects; food storage, drying and clothing read coverage. Household crafts and clothing lots are removed. Migration for stocks.
2. **Civilian industry and planners.** Flatten military recipes. Remove the civilian lines, the civilian planner branch and the part-buying investment planners. Plants, water, rail and docks use Civilian Goods costs. Build the production-dock Civilian Goods panel.
3. **City capacities.** Capacities, condition and fabric tier replace plots in the simulation, including damage and siege recovery. Remove the fabric operations and building-material planning. Migration for plots.
4. **Population-driven visuals.** A generator for the player's cities and rivals' cities, continuous growth, landmark placement, lens and UI.
5. **Cleanup.** Remove dead code and art hooks for removed products (their technique art stays in research). Update tests. Re-profile and record the throughput.

Integration hotspots (per AGENTS.md): `game_state.gd`, `save_system.gd`, `local_terrain.gd`, `discovery_system.gd` and `military_campaign.gd` all change. GovernmentPeopleSystem ownership of officials and labor is unchanged.

## 5. Open questions

1. **Goods feel.** Should a well-supplied city hold about 1× its target (a steady state), and should shortages show on the civilization overview as a "Civilian Goods" KPI? Proposed: yes to both.
2. **Research lab goods** (NMR, SEC, microscopy supplies). Proposed: fold them into Civilian Goods cost, plus the instrument technique. The alternative is keeping those few chains granular as part of research.
3. **Food processing.** Proposed: keep it granular for now, and review it after phase 5 using the new profile.
