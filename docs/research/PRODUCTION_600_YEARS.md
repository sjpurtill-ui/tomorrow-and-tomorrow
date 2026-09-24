# Production: the first 600 years

**Scope.** The game's **Production** research line (`production` dynamic; `direction: "Materials"` entries, which `DiscoverySystem._classify_discovery` maps to `production`) has four channels: Material supply, Tool quality, Craft capacity and Standardization. It covers stone tools, fiber and cordage, basketry, hide and leather, woodworking, pottery and kilns, spinning and looms, dyes, early metallurgy (native copper → smelted copper → arsenical copper → tin bronze) and the organization of workshops. The clothing (`clothing_knowledge.gd`), textile, leather, colorant, refractory-ceramic and glass catalogs are all `Materials`, so they belong here. The main catalog has about 313 production entries, but only about 47 of them belong before year 600. The rest (bloomery iron, spinning wheels, machine tools, polymers and so on) belong centuries later. Food processing (milling, oil for food, fermentation) belongs to Nutrition. Carriers, carts and wheels belong to Logistics. Building materials that are laid up in a structure (mudbrick, mortar, roof tiles) belong to Infrastructure. The lime, bitumen and charcoal that feed those crafts stay here. Items that straddle two lines are marked **(shared: X)**.

**Historical anchor.** Game years 0–300 correspond to roughly 5000–3000 BC (late Neolithic and Chalcolithic: Halaf, Ubaid, Uruk, Naqada, Varna). Years 300–600 correspond to roughly 3000–1500 BC (Early to Middle Bronze Age: Early Dynastic Sumer, Old Kingdom Egypt, Indus cities, Ur III, Old Babylonian, Minoan palaces). This is the pacing curve from `codex/era-research-pacing` (`technology_eras.gd`).

**Research time.** Time is given in game years while a staffed Production team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** `id` = in the main catalog today. `(era)` = written on the unmerged branch `codex/era-research-pacing` (`early_practice_knowledge.gd`) and not yet in main. `NEW` = not authored yet.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`), or `≈` for an estimate from the prerequisite graph. It is `—` when the item is not in main, or when it is in main but has never been observed and cannot be estimated.

## Years 0–300 (≈ 5000–3000 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1 (0–4) | Raw stock set out before a work session | 1 y | 6 min | raw_material_prestaging (era) | — |
| 2 (0–5) | Stone chosen by fracture, grain and ring | 1.5 y | 9 min | stone_sorting | 26 |
| 3 (0–6) | Edges tested by feel | 1 y | 6 min | edge_testing_by_feel (era) | — |
| 4 (0–8) | Pressure-flaked blades and points | 2 y | 12 min | controlled_flaking | 28 |
| 5 (1–10) | Resharpening rounds for blades and scrapers | 1.5 y | 9 min | edge_resharpening_rounds (era) | — |
| 6 (2–10) | Two-ply twisted cordage | 2 y | 12 min | cordage | 35 |
| 7 (2–12) | Hafting with sinew, pitch and cord | 2 y | 12 min | hafted_tools | 38 |
| 8 (3–12) | Coiled and twined basketry | 2 y | 12 min | basketry | 16 |
| 9 (3–14) | Notched measuring rods (shared: knowledge) | 1.5 y | 9 min | notched_measuring_rods (era) | — |
| 10 (4–15) | Hides scraped, stretched and smoke-cured | 2 y | 12 min | NEW · hide_smoke_curing | — |
| 11 (4–16) | Craft tasks grouped into batches | 1.5 y | 9 min | batch_task_grouping (era) | — |
| 12 (5–18) | Clay tested by wetting, rolling and drying | 2 y | 12 min | clay_testing | 18 |
| 13 (5–20) | Hand-built pots: coil, pinch and slab | 3 y | 18 min | clay_shaping | 13 |
| 14 (6–20) | Woven carriers, mats and fish traps | 2 y | 12 min | woven_carriers | 127 |
| 15 (6–22) | Bone awls and eyed needles for sewn hides | 2 y | 12 min | bone_needle_sewing | ≈40 |
| 16 (6–22) | Ground and polished stone axes and adzes | 3 y | 18 min | NEW · ground_stone_axes | — |
| 18 (8–25) | Ochre and mineral pigments ground and bound | 2 y | 12 min | mineral_pigment_preparation | ≈20 |
| 20 (10–28) | Open pit and bonfire firing of pots | 3 y | 18 min | pit_firing | 24 |
| 22 (12–30) | Sand, shell and chaff tempering | 3 y | 18 min | clay_tempering | 32 |
| 24 (12–32) | Crushed-sherd grog | 2 y | 12 min | grog_preparation | ≈30 |
| 26 (14–35) | Timber barked, stacked and seasoned | 3 y | 18 min | timber_seasoning | 30 |
| 28 (15–38) | Bow drill for beads, wood and stone | 3 y | 18 min | bow_drill_drive | ≈40 |
| 30 (16–40) | Flax retted in ponds | 3 y | 18 min | fiber_retting | 74 |
| 32 (18–42) | Spliced fiber spun on whorled spindles | 3 y | 18 min | drop_spindles | 59 |
| 34 (18–45) | Grips wrapped on tool handles | 1.5 y | 9 min | grip_wrapping_practice (era) | — |
| 36 (20–48) | Charcoal burned in covered stacks | 4 y | 24 min | charcoal | 6 |
| 38 (20–50) | Two keepers check each measure (shared: knowledge) | 1.5 y | 9 min | paired_measure_checking (era) | — |
| **40 (22–55)** | **Warp-weighted loom** | 5 y | 30 min | warp_weighted_looms | 63 |
| 44 (25–60) | Plain-weave linen cloth | 4 y | 24 min | plain_weaving | 66 |
| 48 (28–65) | Burnished and slip-coated wares | 3 y | 18 min | NEW · burnished_slipped_wares | — |
| 50 (30–70) | Lime burned for plaster and whitewash | 5 y | 30 min | lime_burning | 60 |
| 53 (32–75) | Offcuts and broken tools reclaimed | 2 y | 12 min | scrap_reclamation_habits (era) | — |
| 56 (35–80) | Work floors shared between households | 2 y | 12 min | workshop_space_sharing (era) | — |
| **60 (38–85)** | **Two-chamber updraft kiln** | 8 y | 49 min | kiln_control | 40 |
| 64 (40–90) | Painted wares with fired mineral paints | 4 y | 24 min | NEW · painted_pottery | — |
| 68 (45–95) | Native copper cold-hammered and annealed | 5 y | 30 min | NEW · native_copper_working | — |
| 72 (48–100) | Reference vessel sets (shared: knowledge) | 2 y | 12 min | reference_vessel_sets (era) | — |
| 75 (50–105) | Tournette: slow turntable for finishing pots | 5 y | 30 min | NEW · tournette | — |
| 78 (52–108) | Horizontal ground loom | 4 y | 24 min | NEW · horizontal_ground_loom | — |
| 80 (55–110) | Stone judged by grain before quarrying | 2 y | 12 min | stone_grain_judging (era) | — |
| 85 (58–115) | Ore trials: roasting and colour tests on green stones | 6 y | 37 min | ore_assaying | 50 |
| **90 (60–125)** | **Copper smelted in crucibles with blowpipes** | 12 y | 73 min | copper_smelting | 97 |
| 95 (65–130) | Haft fit checked before use | 2 y | 12 min | haft_fit_checking (era) | — |
| 100 (70–135) | Hides tanned with oak bark and galls | 5 y | 30 min | hide_tanning | ≈75 |
| **105 (75–140)** | **Open-mould casting of flat axes** | 10 y | 61 min | copper_casting | 99 |
| 115 (80–150) | Fire-setting and stone mauls at copper workings | 5 y | 30 min | NEW · fire_setting_mining | — |
| 120 (85–155) | Assistants take over simple craft steps | 2 y | 12 min | assistant_task_offloading (era) | — |
| 125 (90–160) | Handle balance testing | 2 y | 12 min | handle_balance_testing (era) | — |
| 130 (95–165) | Plant dyes for yarn: madder, weld, woad | 4 y | 24 min | textile_dye_extraction | ≈30 |
| 140 (100–175) | Lead smelted from galena | 6 y | 37 min | lead_smelting | ≈55 |
| 150 (110–185) | Seed and olive oil pressed for lamps and leather (shared: nutrition) | 4 y | 24 min | seed_oil_pressing | 50 |
| 160 (120–195) | Controlled reduction firing: black-topped wares | 5 y | 30 min | NEW · reduction_firing | — |
| 165 (125–200) | Matched weighing stones (shared: knowledge) | 3 y | 18 min | standard_weight_sets (era) | — |
| 170 (130–205) | Wool spun from wool-bearing sheep | 5 y | 30 min | NEW · wool_spinning | — |
| **175 (135–215)** | **Arsenical copper from mixed ores** | 10 y | 61 min | NEW · arsenical_copper | — |
| 180 (140–215) | Output sorted by quality grade | 2 y | 12 min | output_quality_sorting (era) | — |
| 183 (145–220) | Measures checked for drift | 2 y | 12 min | measure_drift_checking (era) | — |
| 188 (150–225) | Template-based sizing | 3 y | 18 min | template_based_sizing (era) | — |
| **195 (155–235)** | **Lost-wax casting** | 10 y | 61 min | NEW · lost_wax_casting | — |
| 198 (160–235) | Comparative tool trials | 2 y | 12 min | comparative_tool_trials (era) | — |
| 205 (165–245) | Sheet copper hammered and riveted | 4 y | 24 min | NEW · sheet_copper_riveting | — |
| 210 (170–250) | Clay judged by feel | 2 y | 12 min | clay_feel_judging (era) | — |
| **225 (185–260)** | **Faience: glazed quartz paste** | 10 y | 61 min | NEW · faience | — |
| **230 (190–270)** | **Fast wheel-thrown pottery** | 12 y | 73 min | NEW · wheel_thrown_pottery | — |
| 235 (195–275) | Mould-made ration bowls in mass batches | 5 y | 30 min | NEW · mould_made_bowls | — |
| 245 (205–285) | Stone vessels bored with tube drill and sand | 6 y | 37 min | NEW · tube_drilled_stone_vessels | — |
| 250 (210–290) | Silver parted from lead by cupellation | 8 y | 49 min | silver_cupellation | ≈60 |
| 255 (215–295) | Craft orders queued by due date | 2 y | 12 min | craft_order_queuing (era) | — |
| 260 (220–300) | Two-piece moulds for shaft-hole axes | 6 y | 37 min | NEW · bivalve_moulds | — |
| 265 (225–305) | Meteoric iron cold-worked into beads | 4 y | 24 min | NEW · meteoric_iron_working | — |
| 270 (230–310) | Tool matched to task | 2 y | 12 min | task_matched_tool_selection (era) | — |
| 275 (235–315) | Standard unit names (shared: knowledge) | 3 y | 18 min | standard_unit_naming (era) | — |
| 285 (245–325) | Lampblack gathered for ink and paint | 3 y | 18 min | lampblack_capture | 28 |
| 295 (255–335) | Fine clays settled in water tanks | 4 y | 24 min | clay_levigation | ≈25 |

## Years 300–600 (≈ 3000–1500 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 310 (280–340) | Temple workshops under an overseer (shared: labor) | 6 y | 37 min | NEW · temple_workshops | — |
| 320 (290–350) | Craft work scheduled by season | 3 y | 18 min | seasonal_craft_scheduling (era) | — |
| 330 (300–360) | Tin smelted from cassiterite | 8 y | 49 min | tin_smelting | ≈55 |
| 340 (310–370) | Tools retired by wear grade | 2 y | 12 min | graded_tool_retirement (era) | — |
| 350 (320–380) | Copper saws, chisels and drills for stone and wood | 6 y | 37 min | NEW · copper_carpentry_tools | — |
| **360 (320–400)** | **Tin bronze by set proportion** | 15 y | 91 min | bronze_alloying | ≈100 |
| 365 (325–405) | Garments and hides cut to templates | 5 y | 30 min | garment_pattern_cutting | ≈45 |
| 370 (330–410) | Measures agreed between settlements (shared: knowledge) | 4 y | 24 min | cross_settlement_measure_agreement (era) | — |
| 375 (335–415) | Leather goods cut to pattern: bags, straps, sandals | 4 y | 24 min | leather_goods_patterning | ≈80 |
| 380 (340–420) | Closed stone and clay moulds | 6 y | 37 min | NEW · closed_moulds | — |
| 390 (350–430) | Wool felted and fulled | 4 y | 24 min | NEW · wool_felting_fulling | — |
| **400 (360–440)** | **Gold and silver sheet, filigree and granulation** | 8 y | 49 min | NEW · goldsmith_filigree | — |
| 410 (370–450) | Bronze edges work-hardened by hammering | 4 y | 24 min | NEW · bronze_work_hardening | — |
| **420 (380–460)** | **Pot bellows at the smelting hearth** | 8 y | 49 min | NEW · pot_bellows | — |
| 425 (385–465) | Wool combed for even yarn | 4 y | 24 min | fiber_combing | 85 |
| 430 (390–470) | Twill weaves | 6 y | 37 min | twill_weave_structures | ≈70 |
| **440 (400–480)** | **Glass beads from fritted sand and plant ash** | 12 y | 73 min | glassmaking | 104 |
| 450 (410–490) | Hard solders: gold-copper and silver-copper | 5 y | 30 min | NEW · hard_soldering | — |
| 460 (420–500) | Palace weaving houses with rationed weavers (shared: labor) | 6 y | 37 min | NEW · palace_weaving_houses | — |
| 470 (430–510) | Alloy recipes by weighed parts (shared: knowledge) | 5 y | 30 min | NEW · weighed_alloy_recipes | — |
| 480 (440–520) | Bronze vessels raised from sheet | 5 y | 30 min | NEW · raised_bronze_vessels | — |
| 490 (450–530) | Peat cut and dried as fuel (shared: ecology) | 3 y | 18 min | peat_drying | ≈10 |
| 500 (460–540) | Standard ingots for exchange (shared: logistics) | 5 y | 30 min | NEW · standard_ingots | — |
| 510 (470–550) | Sulfur gathered and purified | 5 y | 30 min | sulfur_purification | 111 |
| **520 (480–560)** | **Shaft furnaces with clay tuyères** | 10 y | 61 min | NEW · shaft_furnaces | — |
| 530 (490–570) | Mordant dyeing with alum | 8 y | 49 min | NEW · alum_mordant_dyeing | — |
| 540 (500–580) | Cored castings for socketed tools | 6 y | 37 min | NEW · cored_socket_casting | — |
| **555 (515–595)** | **Glazed pottery** | 8 y | 49 min | ceramic_glaze_formulation | ≈105 |
| 565 (525–605) | Refractory clay bodies tested | 5 y | 30 min | refractory_body_trials | — |
| 570 (530–610) | Refractory crucibles | 6 y | 37 min | ceramic_crucibles | — |
| 580 (540–620) | Glass melted in crucibles | 8 y | 49 min | crucible_glass_melting | — |
| **590 (550–640)** | **Core-formed glass vessels** | 12 y | 73 min | core_formed_glass | 152 |
| 595 (555–640) | Tapestry weave on the upright loom | 6 y | 37 min | NEW · tapestry_weaving | — |
| 600 (560–640) | Fired refractory bricks for furnace linings | 6 y | 37 min | refractory_brick_firing | — |

## Pacing

| Years | 0–50 | 50–100 | 100–150 | 150–200 | 200–250 | 250–300 | 300–350 | 350–400 | 400–450 | 450–500 | 500–550 | 550–600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Production advances | 30 | 13 | 7 | 10 | 6 | 8 | 4 | 7 | 6 | 5 | 5 | 7 |

The total is **108** advances: 74 in the first 300 years and 34 in the next 300. Across the four channels, one lands about every 5–6 years. The first 50 years are crowded with 1–3-year practices (flaking, cordage, clay, spindles), so every channel has work of its age from the start. Metallurgy and kiln steps take 8–15 years each, so the count per window falls after year 100 while each step matters more.

**Key thresholds:**
1. **Stone and wood:** flaked blades (4) → hafting (7) → polished axes (16) → bow drill (28) → copper saws and chisels (350).
2. **Fiber and cloth:** cordage (6) → basketry (8) → spindles (32) → warp-weighted loom (40) → linen (44) → ground loom (78) → wool (170) → felting (390) → twill (430) → alum mordants (530) → tapestry (595).
3. **Clay and fire:** hand-built pots (13) → pit firing (20) → tempering (22) → updraft kiln (60) → tournette (75) → reduction firing (160) → faience (225) → fast wheel (230) → glass beads (440) → glazed pottery (555) → core-formed glass (590).
4. **Metal:** native copper (68) → ore trials (85) → smelting (90) → open moulds (105) → lead (140) → arsenical copper (175) → lost wax (195) → silver cupellation (250) → tin (330) → tin bronze (360) → bellows (420) → shaft furnaces (520). Iron smelting stays beyond 600.
5. **Workshops:** batching (11) → shared floors (56) → assistants (120) → quality grades (180) → temple workshops (310) → palace weaving houses (460).

## Currently far too early (production line, main)

These are placement targets only. The "Seen" column is the earliest year observed in recorded runs, or estimated from the graph where marked ≈.

| Item | Seen | Belongs |
|---|---|---|
| chemical_distillation | 57 | Beyond 600 (≈ 1400) |
| oil_based_printing_inks | 54 | Beyond 600 (≈ 1870) |
| iron_assaying / bloomery_smelting / forge_welding | 75 / 101 / 108 | Beyond 600 (≈ 660) |
| flying_shuttles | 82 | Beyond 600 (≈ 2270) |
| textile_rag_pulping | 95 | Beyond 600 (≈ 1080) |
| spinning_wheels | 99 | Beyond 600 (≈ 1500) |
| brine_purification | 100 | Beyond 600 (≈ 1400) |
| glassmaking | 104 | 440 |
| wire_drawing / hardened_edges | 115 / 129 | Beyond 600 (≈ 700) |
| multi_spindle_spinning / mule_spinning | 116 / 193 | Beyond 600 (≈ 2330–2360) |
| pressure_vessels | 118 | Beyond 600 (≈ 2400) |
| copperplate_preparation | 134 | Beyond 600 (≈ 1860) |
| glass_blowing / mold_blown_glass | 142 / 150 | Beyond 600 (≈ 1010) |
| core_formed_glass | 152 | 590 |
| flyer_spinning | 189 | Beyond 600 (≈ 1940) |
| coke_firing / refractory_furnaces / blast_furnace | 207 / 209 / 213 | Beyond 600 (≈ 1790–2220) |
| steel_refining, electrical and electronic entries | 203–234 | Beyond 600 (≈ 2480–2790) |
| ceramic_slip_casting (slip poured into absorbent moulds) | ≈30 | Beyond 600. This is an 18th-century CE method, but the era branch also dates it to 3000 BC. |

Some items are also too late. `woven_carriers` is first seen at 127 but belongs near 14, and `hide_tanning` has never been observed.
