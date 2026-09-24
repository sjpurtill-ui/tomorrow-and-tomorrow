# Proposed year adjustments

Proposals only; `registry.json` is unchanged. Applied in `graph.json` as `proposed_year`. Each move shifts the item that is out of historical order, using the smallest change that makes every hard edge (`requires_all`, and the earliest member of each `requires_any` group) time-consistent. Where the years allow it, some mapper-demoted precedents are also upgraded to `requires_all` once the years allowed it.

| id | line | current → proposed | reason |
|---|---|---|---|
| `house_floor_burial` | culture | 9 → 18 | Floor burial needs durable houses (adobe walls, 18) |
| `ochre_grave_goods` | culture | 10 → 18 | Cascade: requires house_floor_burial |
| `plastered_ancestor_skulls` | culture | 16 → 18 | Cascade: requires house_floor_burial |
| `area_harvest_assessment` | institutions | 460 → 470 | Area assessment needs area_volume_rules (470) |
| `copper_outcrop_signs` | ecology | 140 → 80 | Prospecting signs precede ore assaying and smelting |
| `herd_size_limits` | ecology | 8 → 16 | Managed herd size implies taming (16) |
| `browse_line_monitoring` | ecology | 12 → 16 | Cascade: requires herd_size_limits |
| `wild_honey_smoking` | nutrition | 58 → 30 | Smoke honey-hunting is ancient; beeswax fillings at 31 |
| `healer_specialization_customs` | health | 378 → 368 | Specialist titles presuppose specialisation |
| `copper_carpentry_tools` | production | 350 → 320 | Copper chisels precede tenoned hulls (treenails 335) |
| `household_task_ledgers` | institutions | 6 → 10 | Task tallies need tallies (10) |
| `balance_beam_weights` | knowledge | 320 → 165 | Weight sets (165) are useless without a balance |
| `reed_bundle_boats` | logistics | 36 → 58 | Name requires bitumen sealing (58) |
| `hired_labor_contracts` | labor | 520 → 485 | General hire contracts precede hired carriers (485) |
| `fermentation_control` | nutrition | 116 → 60 | Vessel fermentation precedes resin-sealed wine (65) |
| `paired_ox_yoke` | logistics | 185 → 145 | Ox ard teams (145) need a yoke |
| `cored_socket_casting` | production | 540 → 450 | Socketed spearheads (450) need cored casting |
| `hard_soldering` | production | 450 → 400 | Filigree and granulation (400) need solder |

## Links promoted to `requires_all`

- `herd_size_limits` now requires `animal_taming` (managed herds imply taming).
- `tooth_drilling` now requires `wild_honey_smoking` (beeswax fillings need honey/wax harvest).
- `hive_sparing_honey_harvest` now requires `wild_honey_smoking` (registry marks sparing as follow-on to smoking).
- `healer_titles` now requires `healer_specialization_customs` (titles name specialties).
- `household_task_ledgers` now requires `tallies` (tallies are the medium).
- `reed_bundle_boats` now requires `bitumen_sealing` (boats are bitumen-sealed by definition).
- `hired_carriers` now requires `hired_labor_contracts` (carrier hire is a labor contract).
- `resin_sealed_wine` now requires `fermentation_control` (wine is a controlled vessel ferment).
- `ox_drawn_ard` now requires `paired_ox_yoke` (ox team yoked to the ard).
- `socketed_spearheads` now requires `cored_socket_casting` (socket requires a cored mould).

## Flags reviewed and left unchanged

| item | year | why |
|---|---|---|
| `burial_ground_separation` | 272 | Health chain needs 272; culture alias "cemeteries" (140) should be split out |
| `seasonal_crisis_leader` | 24 | Crisis leader fits 24; security war-leader alias belongs under kingship |
| `dream_interpretation` | 470 | Requires temple_high_steward (260); reword as recorded dream-omens or split |
| `standard_weight_sets` | 165 | Kept; balance moved instead (1 change vs 3 cascading) |
| `public_grain_weighing` | 80 | Mapped on volume measures; reword "weighed" as "measured" |
| `burial/plaster/ochre minor` | — | plastered skulls read as clay; ochre raw pigment |
| `river_craft / stone_maceheads / vermin_deterrent_placement` | — | Within-band precedent gaps; minor |
| `rural_urban_migration` | 262 | Semantic (no town threshold), not an edge conflict |
| `copper_razors / wooden_log_conduits / rammed_earth / peat_drying` | — | Look late but no edge conflict; pacing only |
| `war_chariots vs spoked_wheel_assembly` | 500 | Same year is legal; optional 485 for lag |
