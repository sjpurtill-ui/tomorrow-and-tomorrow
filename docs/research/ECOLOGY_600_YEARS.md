# Ecology: the first 600 years

**Scope.** The game's **Ecology** research line (`ecology` dynamic; `direction: "Nature"` or `"ecology"` entries) has four channels: Land health, Natural recovery, Pollution control and Resource sustainability. It covers knowledge of land and resources, fire management, the care of woods and coppices, soil and regrowth, the ecology of irrigation (salt, waterlogging, silt), grazing management, the care of wildlife and fisheries, and seasonal observation of nature. The main catalog has 24 Nature/ecology entries. Only 5 belong before year 600: `seasonal_patterns`, `timber_grading`, `fiber_grading` and `quarry_reading` are listed here, and `animal_taming` is listed under Nutrition (herds as food). The rest are geoscience and assaying (streak tests, stratigraphy, kriging) that belong after year 2000. The era branch adds 32 ecology practices, and all of them are placed here. Crop yield, fallow, manuring, irrigation schedules and storage stay with Nutrition. Wells, drainage and flood marks stay with Infrastructure. Star calendars stay with Knowledge.

**Historical anchor.** Game years 0–300 correspond to roughly 5000–3000 BC (late Neolithic: swidden, burning, herding, coppice and woodland care). Years 300–600 correspond to roughly 3000–1500 BC (early Bronze Age: salinized irrigation, marsh and canal ecology, managed pasture and timber reserves). This is the pacing curve from `codex/era-research-pacing` (`technology_eras.gd`).

**Research time.** Time is given in game years while a staffed Ecology team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** `id` = in the main catalog today. `(era)` = written on the unmerged branch `codex/era-research-pacing` (`early_practice_knowledge.gd`) and not yet in main. `NEW` = not authored yet. "(shared: X)" marks an item that straddles into vertical X but is listed here because its main effect is ecology.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). It is `—` when the item is not in main, and `n/s` when it is in main but was not reached in any recorded run.

## Years 0–300 (≈ 5000–3000 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2 (0–6) | Seasonal round: plants and animals return on cycles | 1.5 y | 9 min | seasonal_patterns | 3 |
| 3 (0–7) | Timber grading: which woods split, bend or last | 1.5 y | 9 min | timber_grading | 12 |
| 4 (0–8) | Fiber grading | 1.5 y | 9 min | fiber_grading | 14 |
| 5 (1–9) | Reading the quarry face | 2 y | 12 min | quarry_reading | 41 |
| 6 (1–11) | Bare streambanks wash away | 1.5 y | 9 min | streambank_vegetation_watch (era) | — |
| 8 (3–13) | Herd size kept within the browse | 2 y | 12 min | herd_size_limits (era) | — |
| 9 (3–15) | Fallow thickets regrow | 1.5 y | 9 min | fallow_thicket_regrowth (era) | — |
| 10 (4–16) | Middens kept away from water | 1.5 y | 9 min | midden_siting_away_from_water (era) | — |
| 11 (5–17) | Topsoil depth read with a digging stick | 2 y | 12 min | topsoil_depth_reading (era) | — |
| 12 (5–19) | Browse-line watching | 2 y | 12 min | browse_line_monitoring (era) | — |
| 13 (6–20) | Burn-scar regrowth tracked | 2 y | 12 min | burn_scar_regrowth_tracking (era) | — |
| 14 (7–21) | Cookfire smoke vented | 1.5 y | 9 min | cookfire_smoke_venting_habit (era) | — |
| 18 (10–26) | Flowering and bird-return signs for seasonal moves | 2 y | 12 min | NEW · phenology_signs | — |
| 20 (11–29) | Controlled burning of undergrowth for forage and game | 3 y | 18 min | NEW · controlled_undergrowth_burning | — |
| 24 (14–34) | Fish-run and spawning season calendar | 3 y | 18 min | NEW · spawning_calendar | — |
| 28 (17–39) | Firebreaks cleared around camps and fields | 3 y | 18 min | NEW · firebreaks | — |
| 30 (18–42) | Indicator plants for good and poor ground | 3 y | 18 min | NEW · indicator_plants | — |
| 35 (21–49) | Breeding females and young spared in the hunt | 3 y | 18 min | NEW · breeding_stock_sparing | — |
| 40 (25–55) | Swidden cycle: clear, crop, leave to regrow | 4 y | 24 min | NEW · swidden_cycle | — |
| 45 (29–61) | Pollarded trees cut for leaf fodder | 4 y | 24 min | NEW · leaf_fodder_pollarding | — |
| 50 (30–70) | Wild-hive honey taken without killing the colony | 3 y | 18 min | NEW · hive_sparing_honey_harvest | — |
| 55 (35–75) | Drought signs: failing springs and early-drying pools | 3 y | 18 min | NEW · drought_signs | — |
| 60 (40–80) | Transhumance: herds moved to summer pasture | 5 y | 30 min | NEW · transhumance | — |
| 65 (45–85) | Shellfish beds left to recover | 3 y | 18 min | NEW · shellfish_bed_recovery | — |
| 75 (50–100) | Workshops placed downwind | 3 y | 18 min | downwind_workshop_placement (era) | — |
| 78 (50–105) | Gullies on cleared slopes watched and avoided | 3 y | 18 min | slope_erosion_watch (era) | — |
| 80 (55–105) | Spawning grounds avoided | 3 y | 18 min | spawning_ground_avoidance (era) | — |
| 85 (55–115) | Frost pockets and sun slopes read | 3 y | 18 min | NEW · frost_pocket_reading | — |
| 90 (60–120) | Locust and pest-swarm watch | 4 y | 24 min | NEW · pest_swarm_watch | — |
| 100 (65–135) | Sacred groves and springs left uncut (shared: culture) | 4 y | 24 min | NEW · sacred_grove_protection | — |
| 105 (70–140) | Terraces laid along the contour | 5 y | 30 min | contour_terrace_reading (era) | — |
| 108 (75–145) | Seasonal hunting closures | 4 y | 24 min | seasonal_hunting_closures (era) | — |
| 110 (75–145) | Only deadwood gathered for fuel | 3 y | 18 min | selective_deadwood_gathering (era) | — |
| 112 (75–150) | Tannery waste channeled away | 4 y | 24 min | tannery_waste_channeling (era) | — |
| 120 (80–160) | Seed scattered back after gathering | 3 y | 18 min | seed_scatter_after_gathering (era) | — |
| 130 (90–170) | Reed beds cut in rotation | 4 y | 24 min | NEW · reed_bed_rotation | — |
| 140 (100–180) | Green-stained rock as a sign of copper (shared: production) | 5 y | 30 min | NEW · copper_outcrop_signs | — |
| **150 (110–190)** | **Communal catch limits** | 5 y | 30 min | communal_catch_limits (era) | — |
| 152 (110–190) | Refuse pits used in rotation | 3 y | 18 min | refuse_pit_rotation (era) | — |
| 155 (115–195) | Windbreak hedgerows left standing | 4 y | 24 min | windbreak_hedgerow_siting (era) | — |
| 158 (120–200) | Root stock left in the ground | 3 y | 18 min | root_stock_preservation (era) | — |
| 170 (130–210) | Flood-silt ground chosen for fields | 5 y | 30 min | NEW · flood_silt_fields | — |
| 180 (140–220) | Wood-pasture: grazing under thinned trees | 5 y | 30 min | NEW · wood_pasture | — |
| **195 (155–235)** | **Coppice cut for straight regrowth** | 8 y | 49 min | coppice_regrowth_cutting (era) | — |
| 198 (160–240) | Dye-vat runoff kept from streams | 4 y | 24 min | dye_vat_runoff_control (era) | — |
| 200 (160–240) | Saplings protected from browsing | 4 y | 24 min | sapling_protection_customs (era) | — |
| 210 (170–250) | Trampled pasture marked for recovery | 4 y | 24 min | grazing_ground_recovery_marking (era) | — |
| 220 (180–260) | Dung-cake fuel where wood grows scarce (shared: production) | 4 y | 24 min | NEW · dung_cake_fuel | — |
| 225 (185–265) | Replanting after clearance | 6 y | 37 min | replanting_after_clearance (era) | — |
| **228 (190–270)** | **Grazing rotation customs** | 6 y | 37 min | grazing_rotation_customs (era) | — |
| 232 (190–270) | Timber stands held in reserve | 6 y | 37 min | timber_stand_reserves (era) | — |
| 238 (200–280) | Kiln smoke vented away from homes | 4 y | 24 min | kiln_smoke_venting_customs (era) | — |
| 250 (210–290) | Waterlogged ground recognized on over-watered plots | 5 y | 30 min | NEW · waterlogging_recognition | — |
| 265 (225–305) | Tree belts along stream and canal banks | 6 y | 37 min | NEW · riparian_tree_belts | — |
| 275 (235–315) | Fuelwood gathered in rotation around the settlement | 5 y | 30 min | NEW · fuelwood_rotation | — |
| 280 (240–320) | Spring heads fenced from trampling herds | 4 y | 24 min | NEW · spring_head_fencing | — |
| 290 (250–330) | Named soil kinds: heavy, light, sandy, salty | 6 y | 37 min | NEW · named_soil_kinds | — |

## Years 300–600 (≈ 3000–1500 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| **305 (265–345)** | **Salt crust recognized on irrigated fields** | 8 y | 49 min | NEW · salinity_recognition | — |
| 312 (270–350) | Shifting riverbanks watched before siting fields | 5 y | 30 min | NEW · riverbank_shift_watch | — |
| 320 (280–360) | Salted fields leached with fresh water and rested | 10 y | 61 min | NEW · salt_leaching_fallow | — |
| 330 (290–370) | Wetland edges kept for fish, fowl and reeds | 5 y | 30 min | NEW · wetland_margin_reserves | — |
| 340 (300–380) | Stubble grazed after harvest, herds kept off before (shared: nutrition) | 5 y | 30 min | NEW · stubble_grazing | — |
| 350 (310–390) | Spent clay and stone pits turned into ponds | 4 y | 24 min | NEW · pit_pond_reclamation | — |
| 360 (320–400) | Recovery zones set aside | 6 y | 37 min | recovery_zone_designation (era) | — |
| 362 (320–400) | Watershed boundaries marked | 6 y | 37 min | watershed_boundary_marking (era) | — |
| **365 (325–405)** | **Resource-use quotas** | 8 y | 49 min | resource_use_quotas (era) | — |
| 368 (330–410) | Workshop effluent kept separate | 5 y | 30 min | workshop_effluent_separation (era) | — |
| 385 (345–425) | Distant forests known as reserves of long timber | 6 y | 37 min | NEW · distant_timber_reserves | — |
| 395 (355–435) | Fish ponds stocked in canals and basins | 6 y | 37 min | NEW · stocked_fish_ponds (dup) | — |
| 415 (375–455) | Barley favored on saltier ground (shared: nutrition) | 6 y | 37 min | NEW · salt_tolerant_barley | — |
| 420 (380–460) | Hive keeping in clay-pipe hives (shared: nutrition) | 6 y | 37 min | NEW · hive_beekeeping (dup) | — |
| **430 (390–470)** | **Fields rested between water turns to lower the water table** | 10 y | 61 min | NEW · water_table_fallow | — |
| 440 (400–480) | Silt clearance timed to low water, spoil kept off fields (shared: infrastructure) | 6 y | 37 min | NEW · timed_silt_clearance | — |
| 450 (410–490) | Layered shade gardens under palms and fruit trees (shared: nutrition) | 8 y | 49 min | NEW · layered_shade_gardens | — |
| 460 (420–500) | Herd counts matched to pasture by season | 6 y | 37 min | NEW · seasonal_herd_matching | — |
| 470 (430–510) | Blown sand and dune spread watched at the desert edge | 5 y | 30 min | NEW · dune_spread_watch | — |
| 480 (440–520) | Bare hills recognized as a cause of fast floods | 8 y | 49 min | NEW · deforestation_flood_link | — |
| 490 (450–530) | Goat and sheep mix matched to browse and grass | 5 y | 30 min | NEW · mixed_flock_balance | — |
| 500 (460–540) | Fishing-season closures sworn between villages | 6 y | 37 min | NEW · sworn_fishing_closures | — |
| 510 (470–550) | Weirs opened on set days for the fish run | 5 y | 30 min | NEW · fish_run_weir_opening | — |
| 515 (475–555) | Cats encouraged around stores and fields against vermin | 5 y | 30 min | NEW · vermin_control_cats | — |
| 520 (480–560) | Woodland boundaries shared between villages (shared: institutions) | 6 y | 37 min | NEW · shared_woodland_boundaries | — |
| 530 (490–570) | Mine and smelting spoil kept from streams (shared: production) | 6 y | 37 min | NEW · mine_spoil_containment | — |
| 540 (500–580) | Grass burning timed to spare young growth | 5 y | 30 min | NEW · timed_grass_burning | — |
| 550 (510–590) | Charcoal woods cut in long rotation for smelting | 8 y | 49 min | NEW · coppiced_charcoal_woods | — |
| **560 (520–600)** | **Written farmer's almanac of seasons and pests (shared: knowledge)** | 10 y | 61 min | NEW · farmers_almanac | — |
| 575 (535–615) | Planted poplar and tamarisk groves for timber | 8 y | 49 min | NEW · planted_timber_groves | — |
| 590 (550–630) | Grazing rights sworn between herders and farmers | 6 y | 37 min | NEW · sworn_grazing_rights | — |
| 600 (560–640) | Protected woods for temple and palace building timber | 8 y | 49 min | NEW · protected_temple_woods | — |

## Pacing

| Years | 0–50 | 50–100 | 100–150 | 150–200 | 200–250 | 250–300 | 300–350 | 350–400 | 400–450 | 450–500 | 500–550 | 550–600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ecology advances | 20 | 9 | 8 | 8 | 7 | 5 | 5 | 7 | 4 | 5 | 6 | 5 |

The total is **89** advances: 57 in the first 300 years and 32 in the next 300. Across the four channels, one lands about every 6–7 years. The first 50 years are dense because foragers and early farmers already read seasons, stone, wood and herds closely. Later items are slower (5–10 years), because they come from damage that only shows after generations of clearing, grazing and irrigation.

**Key thresholds:**
1. **Fire and woodland:** controlled burning (20) → firebreaks (28) → swidden cycle (40) → pollarding (45) → deadwood-only fuel (110) → coppice (195) → timber reserves (232) → fuelwood rotation (275) → charcoal woods (550) → protected building timber (600).
2. **Land and water:** topsoil reading (11) → slope gullies (78) → contour terraces (105) → flood-silt fields (170) → waterlogging (250) → salt crust (305) → leaching salted fields (320) → drainage fallow (430) → bare hills cause floods (480).
3. **Herds and pasture:** herd limits (8) → transhumance (60) → wood-pasture (180) → pasture recovery (210) → grazing rotation (228) → stubble grazing (340) → herd counts matched to pasture (460) → grazing rights (590).
4. **Wildlife and fisheries:** spawning calendar (24) → sparing breeding game (35) → spawning grounds (80) → hunting closures (108) → catch limits (150) → fish ponds (395) → sworn fishing closures (500) → open weirs for the run (510).
5. **Pollution:** middens (10) → downwind workshops (75) → tannery waste (112) → refuse pits (152) → dye runoff (198) → kiln smoke (238) → effluent separation (368) → mine spoil (530).

## Currently too early (ecology line, main)

These are placement targets only. The "Seen" column is the earliest year observed in recorded runs. "Belongs" converts the `technology_eras.gd` date to a game year, or uses the placement above.

| Item | Seen | Belongs |
|---|---|---|
| mineral_streak_tests | 35 | Beyond 600 (≈ 2400) |
| comparative_mineral_hardness | 48 | Beyond 600 (≈ 2430) |
| mineral_cleavage | 56 | Beyond 600 (≈ 2360) |
| relative_stratigraphy | 79 | Beyond 600 (≈ 2140) |
| geologic_cross_sections | 108 | Beyond 600 (≈ 2440) |
| systematic_channel_sampling | 121 | Beyond 600 (≈ 2670) |
| coal_grading | 122 | Beyond 600 (≈ 2200) |
| mineral_specific_gravity | 139 | Beyond 600 (≈ 920) |
| sediment_provenance | 142 | Beyond 600 (≈ 2430) |
| lithologic_correlation | 177 | Beyond 600 (≈ 2440) |
| geochemical_baselines | 201 | Beyond 600 (≈ 2840) |

Going the other way, `quarry_reading` (seen 41) arrives later than its place at year 5.
