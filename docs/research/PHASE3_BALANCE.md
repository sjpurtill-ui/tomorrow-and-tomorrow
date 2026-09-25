# Phase 3: era-anchored balance for the 600-year research layer

Branch `codex/research-600`. The historical targets are in `BENCHMARKS_600.md` (machine-readable: `benchmarks_600.json`).

User direction: "Progression needs to match the year benchmarks in realistic historical human terms. We can't create superhumans just because we progressed so early." Also:

- Lines must be consequential.
- Life expectancy should respond strongly to health and food discoveries.
- Bad choices slow early growth.
- Play may run ahead of history within a reasonable deviation, but every lead must cost something elsewhere.

## Mechanisms

### Era ceilings (`scripts/society_model.gd`, delimited "research_600 era ceilings" block)

- **What is clamped.** Every effect total is clamped to `era_ceiling_for(key, era)` instead of the flat modern `EFFECT_LIMITS`.
- **Beneficial side only.** Only the beneficial side is limited. `LOWER_IS_BETTER` lists the keys whose improvement is negative. Costs keep the modern bound, so trade-offs always bite.
- **Size at year 600.** `ERA_CEILING_600` gives each key's size at year 600 (1500 BCE). Examples: health protection .22, craft output .45, state capacity .45. Unlisted keys use half their modern limit.
- **Rise curves.** The ceiling rises with the era along one of three curves:
  - `TECH_RISE` for technical and organizational keys: 25% of the year-600 value open at year 0.
  - `ERA_RISE` for the rest: 45% open at year 0.
  - `EARLY_MATURE_RISE` for forager knowledge and fertility customs: 85% open at year 0.
  - After year 600 the ceiling closes on the modern limit, which it reaches at game year 2800 (1950 CE).
- **The society's era.** It is the earlier of the elapsed calendar and the knowledge frontier. The frontier is the 95th percentile of the known discoveries' design years. Poor researchers therefore get lower ceilings.
- **Who shares the ceiling:**
  - discoveries (`SocietyModel`);
  - capability-scale effects (`ProgressionSystem._rebuild_effects`), whose sum with discoveries never exceeds the ceiling;
  - projected rivals (`ProgressionSystem.rival_effect`);
  - artifact research and culture bonuses (`ArtifactCollection.bonus`, capped at the era's knowledge-rate ceiling: about 7% at year 0, 17% at 300, 30% at 600);
  - owned AI seats, which run the same `SocietyModel`.
- **Adoption pace.** Practices now spread over years to decades (`ADOPTION_PACE` 0.12). An actively used practice reaches about 90% of households in about three years. Before, it took weeks.

### Carrying capacity (`scripts/early_life_conditions.gd`, "research_600 carrying capacity")

- **Capacity.** `carrying_capacity(state, discovery)` is the people the settled land can carry with the era's methods:
  - `TERRITORY_CAPACITY` per settlement: 320 at year 0, 420 at 100, 650 at 200, 880 at 300 and 2,600 at 600.
  - Daughter settlements add territory as `1 + 1.6·√(n−1)`.
  - Improved by era-capped cultivation, soil, food-output and storage knowledge.
  - Lowered by worn-out wild grounds.
- **Crowding.** Above 60% of capacity, a crowded society marries later (conception × `1 − 1.2·crowding`) and dies a little more (mortality × `1 + 0.3·crowding`). Growth settles near capacity and then follows it as methods, fields and daughter settlements extend it.
- **Spare land.** A remnant below 30% of the founding territory's capacity (under 96 people) finds land plentiful, and couples marry earlier (`SPARE_LAND_CONCEPTION` 2.0): about +30% to conception at 50 people, up to +60% for a handful. A thinned-out band recovers instead of dying out. The test uses the founding territory, not later capacity, so a large society that grows slowly (for example one neglecting care) gets no extra births.
- **Remnant health.** Crowd diseases need numbers, so the same remnant also sheds part of the era's excess mortality burden (`SPARE_LAND_HEALTH` 1.0): about −18% of the excess at 37 people, up to −30% for a handful.
- **Chronic hunger.** Chronic food shortfall lowers conception through `sqrt(food)` (`GameState._conception_condition_factor`, one delimited line), and famine still cuts it hard.

### Food labor floor (`scripts/government_people_system.gd`, `_apply_food_labor_floor`)

- **Floor.** Planned labor keeps at least the benchmark's typical share of labor time on food: 62% at year 0, 60% at 100, 56% at 300 and 52% at 600. That time covers getting, grinding, cooking and storing food.
- **Surplus.** The surplus fills the stores. The old share of about 35% implied modern farm productivity.
- **Food and labor focus.** A food- or labor-focused society needs up to a quarter less.
- **Care focus.** A care-focused society needs up to 12% more, because it keeps more dependents alive.
- **Labor-claiming decrees.** Decrees that claim labor raise the share needed.

### Care decrees (`scripts/government_policy_catalog.gd`, `EarlyLifeConditions.DECREE_COVER`)

Each care decree covers part of a missing care practice while it runs:

| Decree | Coverage while it runs | Other effect |
|---|---|---|
| Water security (`water_security`) | about 16% of the clean-water category | none |
| Care rotation (`care_rotation`) | about 20% of the remedies and child-care categories | newborn survival +0.054 |
| Expanded watch (`expanded_watch`) | about 13% of the wound and injury category | none |

Their labor cost is unchanged. Before this, all three were no-ops once health and labor sat at their caps.

### Specialization (`scripts/society_model.gd`, `SPECIALIZATION_HEADROOM`)

- **Focus.** A line's focus is its share of research emphasis above an even spread, from 0 (an even spread) to 1 (all emphasis on that line).
- **Stronger practices.** The benefits of a focused line's practices count up to 35% more.
- **Higher ceiling.** That line's channels may pass the common era ceiling by the same share. `EFFECT_LINE` maps each effect key to the line that carries most of its content.
- **Cost.** Every other line is researched less. Every other line's benefits are also counted, capped and carried out (`SocietyModel.practiced`, which early care reads) up to 35% less (`SPECIALIZATION_NEGLECT`), so a focus pays for as long as it lasts.

### Research is never free

`SocietyModel._apply_specialist_upkeep` handles specialists beyond what the era's surplus could keep:

- **Sustainable share.** About 4% of workers can be full-time specialists at year 0, 7% at 300 and 10% at 600.
- **Costs of the excess.** Specialists above that share add `labor_demand` (×1.4) and `fatigue` (×0.6), and cost `cohesion` (×1.0), `conception_support` (×1.0) and `food_storage` (×0.6).
- **Existing labor costs.** The research settlement focus already takes those workers from building, crafting, extraction, logistics and defense. The survival guard still protects food.

### Pre-modern mortality burden (`scripts/early_life_conditions.gd`)

- **Why.** In good conditions the baseline life table is close to a modern one. A fully cared-for society therefore reached life expectancy 55 and infant mortality 50 by year 100.
- **The burden.** `ERA_BURDEN` multiplies each age band's hazard:
  - under 5 ×4.4
  - ages 5–14 ×5.0
  - ages 15–44 ×4.5
  - age 45 and over ×2.3
  - newborn deaths +1.1 on the care factor
  - maternal deaths +1.6 on the care factor (both are additive, not compounding)
- **What lifts it.** Only general health knowledge lifts the burden, through its era-capped channels (`burden_relief`). Before the modern era the relief is small.
- **Missing practices.** A missing care practice adds its excess on top, weighted by `EXCESS_WEIGHT`. Life expectancy still responds strongly to care discoveries: about 24 at founding, rising to about 30 once they are adopted.
- **Overlap with bad conditions.** Hunger and sickness already raise the condition factor. They absorb up to 65% of the burden (`BURDEN_OVERLAP_FLOOR` 0.35), so the same deaths are not counted twice.
- **Fertility.** `PREMODERN_FECUNDITY_KNEE` and `_SLOPE` compress how much a good diet lifts conception above 0.8. After an infant's death the next birth comes sooner: `INFANT_LOSS_REPLACEMENT` 1.3 (it was 2.6). A well-fed crude birth rate therefore stays near 44–48 per 1,000.
- **Save compatibility.** Old saves blend in through `early_care_blend`.
- **Other readers.** The neonatal and maternal factors are used by `consequence_engine.gd` (one delimited line) and `civilization_indicators.gd`.

### Pacing (`scripts/research_600_catalog.gd`, `scripts/discovery_system.gd`)

- **`PACE_BY_YEAR`.** The pace factor depends on the item's design year: 7.0 at year 0, 5.5 at 100, 2.4 at 200, 1.0 at 300, 0.7 at 450 and 0.65 at 600.
  - A founding band has few observers per line. A Bronze Age society has many researchers behind each line.
  - The curve was fitted with `tools/sim` so milestones land inside their bands.
- **Staffing return** (`_research_600_return_waiting_attention`):
  - Once a month, a line of a staffed domain that has open work but nobody on it takes one observer back.
  - The observer comes from the domain's most crowded line, and only if that line has two or more.
  - Before, observers who left a closed line never came back.
- **Foundation work** (`_research_600_foundation_*`):
  - When a staffed domain has no open question of its own, its observers investigate an open prerequisite, from any line, of one of the domain's era-open questions.
  - They follow prerequisites down to the first ones that can be researched now.
  - Before, emphasis on a single line starved on cross-line foundations. The design has 534 of them.

### Design amendments (`tools/research/design_amendments_600.json`, applied by `build_research_600.py`)

- **Adopted.** 22 in-window catalog entries the design never listed are adopted as registry items (`status: adopted`) with years, bands, foundations and pace, following the PHASE2 proposals. Examples: sealed vessels 50, salt working 150, wheel hub boring 220, sail seaming 280, rope rigging 350, bearing surfaces 495, ocean sailing 560.
- **Re-dated.** 16 entries stay outside the registry but are re-dated:
  - iron smelting, assaying, forge welding and charge control: 660
  - professional corps, galleys and naval arsenals: 660
  - axle sleeves: 670
  - amphibious operations and written natural history: 700
  - rotary milling: 800
  - germination trials: 900
  - paper pulp: 1080
  - slip casting: 2300
- **General rule.** Any entry dated after the window never opens inside it. The old 0.9 margin opened year-660 iron at 594.
- **Precedents added:** sealed vessels → hermetic grain storage; salt working → salting fish and meat; felloe jointing → spoke tenon cutting.

### Joint rebalance (`tools/research/rebalance_effects_600.py`)

- **Method.** All twelve lines are budgeted together, one effect channel at a time.
  - Items are grouped into 50-year blocks by design year.
  - A block's beneficial values share one scale. The scale makes the full-knowledge total follow the era ceiling, is never above 1, and keeps at least 5% of each value.
  - Within a block, the Phase 2 relative weights are unchanged.
  - Costs are never scaled.
- **Result.** 2,579 values on 1,095 items were scaled.
- **Idempotent.** The pre-balance values are kept under `balance_600.source` in each effects file, so a re-run gives the same result.
- **Logs.** `docs/research/balance_600_changes.tsv` lists every value. `balance_600_blocks.tsv` lists every block scale.

### Art

- **Aliases.** Three alias tiles are now wired:
  - guest-right → `guest_host_reciprocity`
  - cemeteries → `burial_ground_separation`
  - "the god's house raised on a platform" → `shrine_terraces`
- **Milestone tiles.** The nine milestone tiles of `02_08_26 PM.png` now point to discoveries that had no painting yet:
  - coastal navigation → `pilots_sea_lanes`
  - irrigation canals → `river_supply_channels`
  - traction and plow → `ox_drawn_ard`
  - wheeled transport → `cart_bed_framing`
  - large-scale storage → `central_storehouses`
  - woven textiles → `warp_weighted_looms`
  - standardized bricks → `mould_made_mudbricks`
  - weights and measures → `standard_weight_sets`
  - administration and tax → `grain_levy_accounting`
- **Cropping.** Tiles are cropped the same way as before: the painting box, an 11 px deckle inset, a 4:3 centre crop, then 512×384. They carry no caption.

<!-- RESULTS -->
