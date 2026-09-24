# Infrastructure: the first 600 years

**Scope.** The game's **Infrastructure** research line (`infrastructure` dynamic; `direction: "Infrastructure"` entries) has four channels: Housing, Construction, Public works and Resilience. It covers shelters becoming houses, storage buildings, wells, drainage, water channels and pipes, walls, mudbrick, stone building and the methods behind monumental construction. The main entries come from `settlement_fabric_knowledge.gd`, `building_material_knowledge.gd`, `earthen_building_knowledge.gd`, `water_conveyance_knowledge.gd`, the `Infrastructure` rows of `resource_knowledge_catalog.gd` and `society_knowledge_catalog.gd`, and `drainage`, `well_siting` and `joinery` in `discovery_system.gd`. The main catalog has about 81 infrastructure entries, and about 30 of them belong before year 600. The `cartwright_knowledge.gd` wheel, axle and cart entries are tagged Infrastructure, but they belong to Logistics along with roads and bridges. Granaries and food stores belong to Nutrition, sanitation practice to Health, and fortification to Security. Where the main effect of a straddling item is the building itself, it is kept here and marked **(shared: X)**.

**Historical anchor.** Game years 0–300 correspond to roughly 5000–3000 BC (longhouses, Ubaid and Uruk mudbrick, megaliths, first clay drain pipes). Years 300–600 correspond to roughly 3000–1500 BC (fired brick, dressed stone and pyramids, Indus drains, ziggurats, Minoan socketed pipes). This is the pacing curve from `codex/era-research-pacing` (`technology_eras.gd`).

**Pipes.** Clay drain pipes appear in Uruk-period towns around 3400 BC, so they are placed here around year 235. Laying pipe in a bedded, graded trench as a routine method belongs with the planned drains of 2600–2400 BC (about year 425). Tapered, socketed pipe sections come with the Minoan palaces around 2000–1800 BC (about year 510). Graded long-distance conduits and load assessment of buried pipe come after year 600.

**Research time.** Time is given in game years while a staffed Infrastructure team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** `id` = in the main catalog today. `(era)` = written on the unmerged branch `codex/era-research-pacing` (`early_practice_knowledge.gd`) and not yet in main. `NEW` = not authored yet.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`), or `≈` for an estimate from the prerequisite graph. It is `—` when the item is not in main, or when it is in main but has never been observed and cannot be estimated.

## Years 0–300 (≈ 5000–3000 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2 (0–5) | Common ground marked out for building | 1 y | 6 min | common_ground_marking (era) | — |
| 3 (0–6) | Hazard landmark memory | 1.5 y | 9 min | hazard_landmark_memory (era) | — |
| 4 (0–8) | Surface water led away from sleeping places | 2 y | 12 min | drainage | 4 |
| 6 (1–10) | House plots staked by sightline | 1.5 y | 9 min | sightline_staking (era) | — |
| 8 (2–12) | Site-clearing judgment | 1.5 y | 9 min | site_clearing_assessment (era) | — |
| 10 (3–15) | Lashed and notched pole joints | 2 y | 12 min | joinery | 8 |
| 12 (4–18) | Wells sited by seepage and plants | 3 y | 18 min | well_siting | 10 |
| 14 (5–20) | Clay-lined storage pits (shared: nutrition) | 2 y | 12 min | NEW · clay_lined_storage_pits | — |
| 15 (6–22) | High-water marks read from banks | 1.5 y | 9 min | flood_mark_reading (era) | — |
| 18 (6–25) | Hand-formed mud lumps and adobe walls | 3 y | 18 min | adobe_wall_construction | ≈20 |
| **20 (8–28)** | **Earth-fast post-and-beam longhouse** | 5 y | 30 min | framed_construction | 57 |
| 24 (10–32) | Wattle-and-daub walls | 3 y | 18 min | wattle_and_daub_walls | ≈60 |
| 26 (10–35) | Reed and straw thatch | 3 y | 18 min | thatched_roofing | ≈60 |
| 28 (12–38) | Dry-stone walls for pens and terraces | 3 y | 18 min | NEW · dry_stone_walls | — |
| 32 (15–42) | Timber- and wattle-lined well shafts | 4 y | 24 min | NEW · lined_well_shafts | — |
| 36 (18–45) | House mounds raised above flood | 3 y | 18 min | NEW · flood_house_mounds | — |
| 40 (20–50) | Stone footings under earthen walls | 3 y | 18 min | NEW · stone_wall_footings | — |
| 44 (22–55) | Flat roofs of beams, reeds and packed clay | 3 y | 18 min | NEW · flat_clay_roofs | — |
| **48 (25–65)** | **Mould-made mudbricks** | 6 y | 37 min | NEW · mould_made_mudbricks | — |
| 52 (28–70) | Lime-plastered floors and walls | 4 y | 24 min | NEW · lime_plastered_floors | — |
| 55 (30–75) | Wedges, levers and rollers for heavy stones | 3 y | 18 min | wedges_and_levers | 49 |
| 58 (32–80) | Bitumen waterproofing for floors and sills | 4 y | 24 min | bitumen_sealing | 54 |
| 65 (40–90) | Raised timber floors in storehouses (shared: nutrition) | 3 y | 18 min | NEW · raised_granaries (dup) | — |
| 72 (45–100) | Footing soil judged before building | 2 y | 12 min | footing_soil_judging (era) | — |
| 75 (48–105) | Refuge points agreed before floods | 2 y | 12 min | refuge_point_designation (era) | — |
| **80 (50–115)** | **Megaliths raised with earth ramps, levers and ropes** | 8 y | 49 min | NEW · megalith_raising | — |
| 88 (55–120) | Paths repaired each season (shared: logistics) | 2 y | 12 min | seasonal_path_maintenance (era) | — |
| **95 (60–130)** | **Tripartite central-hall house** | 6 y | 37 min | NEW · central_hall_houses | — |
| 105 (70–140) | Supply channels dug from river to settlement (shared: nutrition) | 6 y | 37 min | NEW · river_supply_channels | — |
| 115 (80–150) | Bracing inspection rounds | 2 y | 12 min | bracing_inspection_rounds (era) | — |
| 120 (85–155) | Communal upkeep scheduling | 2 y | 12 min | communal_upkeep_scheduling (era) | — |
| 122 (85–160) | Dwellings oriented to sun and wind | 3 y | 18 min | dwelling_site_orientation (era) | — |
| 125 (90–160) | Storm response drill | 2 y | 12 min | storm_response_drill (era) | — |
| **135 (95–175)** | **Earthen dykes and levees against floods** | 8 y | 49 min | NEW · flood_levees | — |
| **150 (110–190)** | **Shrine terrace of packed earth and brick** | 10 y | 61 min | NEW · shrine_terraces | — |
| 155 (115–195) | Corners squared with a cord triangle | 2 y | 12 min | corner_squaring_method (era) | — |
| 158 (118–198) | Public space allocated | 2 y | 12 min | public_space_allocation (era) | — |
| 160 (120–200) | Warning calls relayed (shared: security) | 2 y | 12 min | warning_call_relay (era) | — |
| 170 (130–210) | Storerooms with sealed doors around a court (shared: nutrition) | 5 y | 30 min | NEW · courtyard_storerooms | — |
| 180 (140–220) | Mortised post-and-beam frames cut with copper chisels | 5 y | 30 min | timber_post_beam_connections | 22 |
| **190 (150–230)** | **Buttressed and niched mudbrick façades** | 8 y | 49 min | NEW · niched_brick_facades | — |
| 200 (160–240) | Lime-plastered rainwater cisterns | 6 y | 37 min | rainwater_cisterns | 49 |
| 210 (170–250) | Stone-lined lane drains | 5 y | 30 min | NEW · stone_lined_drains | — |
| 220 (180–260) | Quarrying with wedges, pounders and fire | 5 y | 30 min | NEW · wedge_and_fire_quarrying | — |
| **235 (195–275)** | **Fired clay drain pipes** | 10 y | 61 min | clay_pipe_forming | ≈35 |
| 240 (200–280) | Courses levelled as walls rise | 2 y | 12 min | course_leveling_practice (era) | — |
| 242 (200–280) | Ground bearing assessment | 3 y | 18 min | ground_bearing_assessment (era) | — |
| 245 (205–285) | Damage surveyed after a disaster | 2 y | 12 min | post_disaster_damage_survey (era) | — |
| 248 (205–290) | Runoff grade reading | 3 y | 18 min | runoff_grade_reading (era) | — |
| 255 (215–295) | Pipe sections fired to a tested standard | 6 y | 37 min | ceramic_pipe_firing_qualification | ≈45 |
| 260 (220–300) | Multi-room courtyard houses | 5 y | 30 min | NEW · courtyard_houses | — |
| 268 (228–305) | Load path reading | 3 y | 18 min | load_path_reading (era) | — |
| 270 (230–310) | Shared work crew rotation (shared: labor) | 2 y | 12 min | shared_work_crew_rotation (era) | — |
| 275 (235–315) | Corbelled stone vaults and passages | 8 y | 49 min | NEW · corbelled_vaults | — |
| 285 (245–325) | Resources pooled after a storm | 2 y | 12 min | post_storm_resource_pooling (era) | — |
| 290 (250–330) | Rubble diversion dams and reservoirs | 8 y | 49 min | NEW · diversion_dams | — |
| **300 (260–340)** | **Mudbrick town enclosure wall (shared: security)** | 12 y | 73 min | NEW · town_enclosure_walls | — |

## Years 300–600 (≈ 3000–1500 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 315 (285–345) | Plano-convex brick laid in herringbone courses | 4 y | 24 min | NEW · herringbone_plano_convex_brick | — |
| **330 (290–370)** | **Kiln-fired bricks for wet courses** | 8 y | 49 min | NEW · kiln_fired_bricks | — |
| 340 (300–380) | Gypsum mortar for stone and brick | 5 y | 30 min | NEW · gypsum_mortar | — |
| **350 (310–390)** | **Dressed-stone masonry with copper tools** | 12 y | 73 min | NEW · dressed_stone_masonry | — |
| 360 (320–400) | Pounded-earth walls in board forms | 6 y | 37 min | rammed_earth_construction | — |
| **370 (330–410)** | **Stepped stone tomb: ramps, sledges and wetted tracks** | 15 y | 91 min | NEW · stepped_stone_tombs | — |
| 378 (340–415) | Public works priority review | 2 y | 12 min | public_works_priority_review (era) | — |
| 380 (340–420) | Structural repair triage | 2 y | 12 min | structural_repair_triage (era) | — |
| 382 (345–420) | Seasonal hazard calendar | 2 y | 12 min | seasonal_hazard_calendar (era) | — |
| **385 (345–425)** | **Lime mortar for stone and brick courses** | 8 y | 49 min | lime_mortar | 62 |
| 390 (350–430) | Well shafts lined with wedge-shaped bricks | 5 y | 30 min | NEW · wedge_brick_well_lining | — |
| 395 (355–435) | Stone-faced dam across a wadi | 10 y | 61 min | NEW · wadi_dams | — |
| 400 (360–440) | Fired roof tiles | 6 y | 37 min | fired_roof_tiles | ≈60 |
| 405 (365–445) | Upper storeys on timber joists | 5 y | 30 min | NEW · upper_storeys | — |
| 410 (370–450) | Bitumen-bedded brick for baths and drains | 4 y | 24 min | NEW · bitumen_bedded_brick | — |
| 415 (375–455) | Brick bathing platforms and a great tank (shared: health) | 8 y | 49 min | public_baths | ≈60 |
| **420 (380–460)** | **Brick-covered street drains** | 10 y | 61 min | covered_sewers | ≈150 |
| 425 (385–465) | Pipes laid in bedded, graded trenches | 5 y | 30 min | rigid_pipe_bedding | 18 |
| 430 (390–470) | Standard brick proportions (1:2:4) | 4 y | 24 min | NEW · standard_brick_proportions | — |
| 435 (395–475) | Header-and-stretcher brick bonds | 4 y | 24 min | masonry_bond_patterns | ≈65 |
| **440 (400–480)** | **Planned street grid with house blocks** | 12 y | 73 min | urban_street_plans | ≈140 |
| 445 (405–485) | Roof runoff led into drains | 4 y | 24 min | building_drainage_coordination | ≈100 |
| 450 (410–490) | Raised granary with air channels (shared: nutrition) | 6 y | 37 min | NEW · ventilated_granaries | — |
| 455 (415–495) | Pitched-brick barrel vaults without centering | 8 y | 49 min | NEW · pitched_brick_vaults | — |
| 460 (420–500) | Shaduf water lift (shared: nutrition) | 4 y | 24 min | NEW · shaduf_water_lift | — |
| 470 (430–510) | Reed-mat and cable layers in mass brick | 5 y | 30 min | NEW · reed_mat_brick_layers | — |
| **480 (440–520)** | **Stepped temple tower of solid brick** | 20 y | 2 h | NEW · stepped_temple_towers | — |
| 490 (450–530) | Drain shafts through a brick mass | 4 y | 24 min | NEW · brick_mass_drain_shafts | — |
| 500 (460–540) | Hollowed-log water channels | 3 y | 18 min | wooden_log_conduits | ≈12 |
| **510 (470–550)** | **Tapered, socketed terracotta pipes** | 8 y | 49 min | clay_pipe_socket_jointing | ≈25 |
| 520 (480–560) | Scarf joints for long timber beams | 4 y | 24 min | timber_splice_connections | ≈15 |
| 530 (490–570) | Light wells and ventilated rooms | 4 y | 24 min | NEW · light_wells | — |
| 540 (500–580) | Eaves and screens shading walls | 4 y | 24 min | building_shading_design | ≈85 |
| 550 (510–590) | Gauges for pipe socket fit | 4 y | 24 min | ceramic_pipe_fit_gauges | ≈25 |
| 560 (520–600) | Ashlar courses fitted without mortar | 8 y | 49 min | NEW · ashlar_masonry | — |
| 570 (530–610) | Mine galleries propped with timber (shared: production) | 6 y | 37 min | mine_shoring | 131 |
| 580 (540–620) | Palace drains flushed from roof cisterns | 6 y | 37 min | NEW · cistern_flushed_drains | — |
| 590 (550–630) | Rubble walls laced with timber against earthquakes | 6 y | 37 min | NEW · timber_laced_walls | — |
| 600 (560–640) | Colonnaded porticoes on stone bases | 6 y | 37 min | NEW · colonnaded_porticoes | — |

## Pacing

| Years | 0–50 | 50–100 | 100–150 | 150–200 | 200–250 | 250–300 | 300–350 | 350–400 | 400–450 | 450–500 | 500–550 | 550–600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Infrastructure advances | 19 | 9 | 6 | 7 | 8 | 8 | 3 | 9 | 10 | 6 | 5 | 6 |

The total is **96** advances: 57 in the first 300 years and 39 in the next 300. Across the four channels, one lands about every 6 years. Small siting, upkeep and hazard practices (1.5–3 years) fill the early windows. Monumental and water-works steps (8–20 years) arrive in clusters around 350–480, which is why that window is the busiest after the opening.

**Key thresholds:**
1. **Shelter to house:** post-built longhouse (20) → wattle-and-daub and thatch (24–26) → mudbrick (48) → central-hall house (95) → courtyard house (260) → upper storeys (405) → light wells (530).
2. **Earth, brick and stone:** adobe (18) → mould bricks (48) → lime plaster (52) → buttressed façades (190) → corbelled vaults (275) → fired brick (330) → dressed stone (350) → lime mortar (385) → brick bonds (435) → pitched-brick vaults (455) → ashlar (560).
3. **Water:** drainage (4) → wells (12) → lined shafts (32) → supply channels (105) → cisterns (200) → lane drains (210) → clay drain pipes (235) → dams (290) → covered street drains (420) → bedded pipe trenches (425) → socketed pipes (510).
4. **Monumental methods:** megaliths (80) → shrine terrace (150) → town wall (300) → stepped stone tomb (370) → stepped temple tower (480) → porticoes (600).

## Currently far too early (infrastructure line, main)

These are placement targets only. The "Seen" column is the earliest year observed in recorded runs, or estimated from the graph where marked ≈.

| Item | Seen | Belongs |
|---|---|---|
| rigid_pipe_bedding (only needs drainage) | 18 | 425 |
| timber_post_beam_connections | 22 | 180 |
| clay_pipe_socket_jointing / ceramic_pipe_fit_gauges (only need standard_measures) | ≈25 / ≈25 | 510 / 550 |
| masonry_arch_centering (only needs standard_measures) | ≈25 | Beyond 600 (≈ 620) |
| conduit_infiltration_testing / buried_pipe_load_assessment | ≈25 / ≈25 | Beyond 600 (≈ 2750–2800) |
| wooden_log_conduits / timber_splice_connections | ≈12 / ≈15 | 500 / 520 |
| rainwater_cisterns | 49 | 200 |
| fired_roof_tiles | ≈60 | 400 |
| lime_mortar | 62 | 385 |
| gravity_conduit_grade_control | ≈85 | Beyond 600 (≈ 780) |
| building_drainage_coordination | ≈100 | 445 |
| mine_shoring | 131 | 570 |
| mine_drainage | 135 | Beyond 600 (≈ 700) |
| urban_street_plans / covered_sewers | ≈140 / ≈150 | 440 / 420 |
| mine_airways | 147 | Beyond 600 (≈ 2290) |
| mechanical_refrigeration | 232 | Beyond 600 (≈ 2540) |

Some items are also too late. `rammed_earth_construction` requires `structural_load_testing`, which is dated to 1747 CE, but pounded-earth walls belong near year 360.
