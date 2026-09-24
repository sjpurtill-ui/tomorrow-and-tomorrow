# Production dependencies

Machine-readable source: `docs/research/deps/production.json`. Format per `MAPPING_CONTRACT.md`. Year flags: `production_FLAGS.md`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1 | `raw_material_prestaging` — Raw stock set out before a work session | — | — | — | — |
| 2 | `stone_sorting` — Stone chosen by fracture, grain and ring | — | — | quarry_reading | — |
| 3 | `edge_testing_by_feel` — Edges tested by feel | — | — | stone_sorting | — |
| 4 | `controlled_flaking` — Pressure-flaked blades and points | — | — | stone_sorting, edge_testing_by_feel | — |
| 5 | `edge_resharpening_rounds` — Resharpening rounds for blades and scrapers | — | — | controlled_flaking | — |
| 6 | `cordage` — Two-ply twisted cordage | fiber_grading | — | — | — |
| 7 | `hafted_tools` — Hafting with sinew, pitch and cord | controlled_flaking, cordage | — | hafted_weapons | — |
| 8 | `basketry` — Coiled and twined basketry | fiber_grading | — | cordage | — |
| 9 | `notched_measuring_rods` — Notched measuring rods | counting_words | — | tallies | — |
| 10 | `hide_smoke_curing` — Hides scraped, stretched and smoke-cured | controlled_flaking | any of smoking, ember_tending | — | — |
| 11 | `batch_task_grouping` — Craft tasks grouped into batches | raw_material_prestaging | — | task_sequencing_habits | — |
| 12 | `clay_testing` — Clay tested by wetting, rolling and drying | stone_sorting | — | — | resources_known=Clay |
| 13 | `clay_shaping` — Hand-built pots: coil, pinch and slab | clay_testing | — | — | resources_known=Clay |
| 14 | `woven_carriers` — Woven carriers, mats and fish traps | basketry | — | — | — |
| 15 | `bone_needle_sewing` — Bone awls and eyed needles for sewn hides | hide_smoke_curing, cordage | — | — | — |
| 16 | `ground_stone_axes` — Ground and polished stone axes and adzes | stone_sorting, hafted_tools | — | food_pounding_mortars | — |
| 18 | `mineral_pigment_preparation` — Ochre and mineral pigments ground and bound | food_pounding_mortars | — | ochre_grave_goods | — |
| 20 | `pit_firing` — Open pit and bonfire firing of pots | clay_shaping, hearth_heat_retention | — | ember_tending, hearth_roasting_control | — |
| 22 | `clay_tempering` — Sand, shell and chaff tempering | clay_testing, pit_firing | — | — | — |
| 24 | `grog_preparation` — Crushed-sherd grog | clay_tempering | — | — | — |
| 26 | `timber_seasoning` — Timber barked, stacked and seasoned | timber_grading, ground_stone_axes | — | — | — |
| 28 | `bow_drill_drive` — Bow drill for beads, wood and stone | cordage | — | friction_fire_ignition, controlled_flaking | — |
| 30 | `fiber_retting` — Flax retted in ponds | fiber_grading | — | cordage, seed_selection | — |
| 32 | `drop_spindles` — Spliced fiber spun on whorled spindles | cordage, fiber_retting | — | bow_drill_drive | — |
| 34 | `grip_wrapping_practice` — Grips wrapped on tool handles | hafted_tools | — | hide_smoke_curing | — |
| 36 | `charcoal` — Charcoal burned in covered stacks | earth_oven_cooking | — | pit_firing | — |
| 38 | `paired_measure_checking` — Two keepers check each measure | notched_measuring_rods | — | witnessed_agreement_customs, knot_tally_cross_check | — |
| 40 | `warp_weighted_looms` — Warp-weighted loom | drop_spindles, framed_construction | — | clay_shaping | — |
| 44 | `plain_weaving` — Plain-weave linen cloth | warp_weighted_looms, fiber_retting | — | — | — |
| 48 | `burnished_slipped_wares` — Burnished and slip-coated wares | pit_firing | — | mineral_pigment_preparation | — |
| 50 | `lime_burning` — Lime burned for plaster and whitewash | pit_firing | — | charcoal | resources_known=Limestone |
| 53 | `scrap_reclamation_habits` — Offcuts and broken tools reclaimed | edge_resharpening_rounds, batch_task_grouping | — | — | — |
| 56 | `workshop_space_sharing` — Work floors shared between households | batch_task_grouping, part_time_specialists | — | — | — |
| 60 | `kiln_control` — Two-chamber updraft kiln | pit_firing, adobe_wall_construction | — | charcoal, lime_burning | — |
| 64 | `painted_pottery` — Painted wares with fired mineral paints | kiln_control, mineral_pigment_preparation | — | — | — |
| 68 | `native_copper_working` — Native copper cold-hammered and annealed | hearth_heat_retention, ground_stone_axes | — | mineral_pigment_preparation | resources_known=Copper |
| 72 | `reference_vessel_sets` — Reference vessel sets | standard_measures, kiln_control | — | paired_measure_checking | — |
| 75 | `tournette` — Tournette: slow turntable for finishing pots | clay_shaping, kiln_control | — | bow_drill_drive | — |
| 78 | `horizontal_ground_loom` — Horizontal ground loom | plain_weaving | — | — | — |
| 80 | `stone_grain_judging` — Stone judged by grain before quarrying | stone_sorting, quarry_reading | — | ground_stone_axes | — |
| 85 | `ore_assaying` — Ore trials: roasting and colour tests on green stones | native_copper_working, kiln_control | — | mineral_pigment_preparation, copper_outcrop_signs | — |
| 90 | `copper_smelting` — Copper smelted in crucibles with blowpipes | ore_assaying, kiln_control, charcoal | — | — | resources_known=Copper |
| 95 | `haft_fit_checking` — Haft fit checked before use | hafted_tools, timber_seasoning | — | edge_testing_by_feel | — |
| 100 | `hide_tanning` — Hides tanned with oak bark and galls | hide_smoke_curing | — | tannery_waste_channeling | environment=woodland |
| 105 | `copper_casting` — Open-mould casting of flat axes | copper_smelting | — | clay_shaping | resources_known=Copper |
| 115 | `fire_setting_mining` — Fire-setting and stone mauls at copper workings | ore_assaying, ground_stone_axes | — | copper_outcrop_signs | — |
| 120 | `assistant_task_offloading` — Assistants take over simple craft steps | batch_task_grouping, household_craft_learning | — | part_time_specialists | — |
| 125 | `handle_balance_testing` — Handle balance testing | haft_fit_checking | — | — | — |
| 130 | `textile_dye_extraction` — Plant dyes for yarn: madder, weld, woad | plain_weaving, pit_firing | — | mineral_pigment_preparation, herbal_classification | — |
| 140 | `lead_smelting` — Lead smelted from galena | ore_assaying, kiln_control | — | copper_smelting | resources_known=Lead |
| 150 | `seed_oil_pressing` — Seed and olive oil pressed for lamps and leather | food_pounding_mortars | — | fruit_pulp_screening, woven_carriers | — |
| 160 | `reduction_firing` — Controlled reduction firing: black-topped wares | kiln_control, burnished_slipped_wares | — | — | — |
| 165 | `standard_weight_sets` — Matched weighing stones | standard_measures, public_grain_weighing | — | stone_sorting | — |
| 170 | `wool_spinning` — Wool spun from wool-bearing sheep | drop_spindles, animal_taming | — | breeding_stock_sparing | — |
| 175 | `arsenical_copper` — Arsenical copper from mixed ores | copper_smelting | — | copper_casting | resources_known=Copper |
| 180 | `output_quality_sorting` — Output sorted by quality grade | batch_task_grouping, full_time_specialists | — | — | — |
| 183 | `measure_drift_checking` — Measures checked for drift | paired_measure_checking, standard_weight_sets | — | — | — |
| 188 | `template_based_sizing` — Template-based sizing | notched_measuring_rods, reference_vessel_sets | — | output_quality_sorting | — |
| 195 | `lost_wax_casting` — Lost-wax casting | copper_casting, wild_honey_smoking | — | clay_tempering | — |
| 198 | `comparative_tool_trials` — Comparative tool trials | handle_balance_testing, output_quality_sorting | — | — | — |
| 205 | `sheet_copper_riveting` — Sheet copper hammered and riveted | copper_smelting | — | bow_drill_drive, native_copper_working | — |
| 210 | `clay_feel_judging` — Clay judged by feel | clay_testing | — | mentored_task_learning | — |
| 225 | `faience` — Faience: glazed quartz paste | kiln_control, copper_smelting | — | lime_burning | — |
| 230 | `wheel_thrown_pottery` — Fast wheel-thrown pottery | tournette, full_time_specialists | — | clay_levigation | — |
| 235 | `mould_made_bowls` — Mould-made ration bowls in mass batches | kiln_control, fixed_worker_rations | — | clay_shaping | — |
| 245 | `tube_drilled_stone_vessels` — Stone vessels bored with tube drill and sand | bow_drill_drive, stone_grain_judging | any of sheet_copper_riveting, copper_casting | — | — |
| 250 | `silver_cupellation` — Silver parted from lead by cupellation | lead_smelting | — | ore_assaying | resources_known=Lead |
| 255 | `craft_order_queuing` — Craft orders queued by due date | full_time_specialists | any of knotted_record_systems, clay_counting_tokens, token_envelopes | — | — |
| 260 | `bivalve_moulds` — Two-piece moulds for shaft-hole axes | copper_casting, stone_grain_judging | — | lost_wax_casting | — |
| 265 | `meteoric_iron_working` — Meteoric iron cold-worked into beads | native_copper_working | — | sheet_copper_riveting | resources_known=Meteoric iron |
| 270 | `task_matched_tool_selection` — Tool matched to task | comparative_tool_trials | — | — | — |
| 275 | `standard_unit_naming` — Standard unit names | standard_weight_sets, reference_vessel_sets | — | — | — |
| 285 | `lampblack_capture` — Lampblack gathered for ink and paint | seed_oil_pressing | — | mineral_pigment_preparation | — |
| 295 | `clay_levigation` — Fine clays settled in water tanks | clay_feel_judging | — | lime_plastered_floors | — |
| 310 | `temple_workshops` — Temple workshops under an overseer | full_time_specialists, temple_common_storehouse | — | craft_quarters, temple_high_steward | — |
| 320 | `seasonal_craft_scheduling` — Craft work scheduled by season | seasonal_work_round, craft_order_queuing | — | — | — |
| 330 | `tin_smelting` — Tin smelted from cassiterite | copper_smelting | — | — | resources_known=Tin |
| 340 | `graded_tool_retirement` — Tools retired by wear grade | scrap_reclamation_habits, comparative_tool_trials | — | — | — |
| 350 | `copper_carpentry_tools` — Copper saws, chisels and drills for stone and wood | copper_casting, arsenical_copper | — | sheet_copper_riveting | — |
| 360 | `bronze_alloying` — Tin bronze by set proportion | tin_smelting | — | arsenical_copper | — |
| 365 | `garment_pattern_cutting` — Garments and hides cut to templates | template_based_sizing, plain_weaving | — | bone_needle_sewing | — |
| 370 | `cross_settlement_measure_agreement` — Measures agreed between settlements | standard_unit_naming | — | intervillage_tribute_reconciliation, proclaimed_standard_weights | min_settlements=2 |
| 375 | `leather_goods_patterning` — Leather goods cut to pattern: bags, straps, sandals | hide_tanning, garment_pattern_cutting | — | — | — |
| 380 | `closed_moulds` — Closed stone and clay moulds | bivalve_moulds | — | lost_wax_casting | — |
| 390 | `wool_felting_fulling` — Wool felted and fulled | wool_spinning, plain_weaving | — | — | — |
| 400 | `goldsmith_filigree` — Gold and silver sheet, filigree and granulation | sheet_copper_riveting, silver_cupellation | — | hard_soldering | resources_known=Gold |
| 410 | `bronze_work_hardening` — Bronze edges work-hardened by hammering | bronze_alloying | — | — | — |
| 420 | `pot_bellows` — Pot bellows at the smelting hearth | copper_smelting, hide_tanning | — | — | — |
| 425 | `fiber_combing` — Wool combed for even yarn | wool_spinning | — | — | — |
| 430 | `twill_weave_structures` — Twill weaves | plain_weaving | — | fiber_combing, horizontal_ground_loom | — |
| 440 | `glassmaking` — Glass beads from fritted sand and plant ash | faience | — | lime_burning, pot_bellows | — |
| 450 | `hard_soldering` — Hard solders: gold-copper and silver-copper | goldsmith_filigree | — | pot_bellows | — |
| 460 | `palace_weaving_houses` — Palace weaving houses with rationed weavers | temple_workshops, fixed_worker_rations | — | twill_weave_structures | institutions_min=0.6 |
| 470 | `weighed_alloy_recipes` — Alloy recipes by weighed parts | bronze_alloying, balance_beam_weights | — | — | — |
| 480 | `raised_bronze_vessels` — Bronze vessels raised from sheet | bronze_work_hardening | — | sheet_copper_riveting | — |
| 490 | `peat_drying` — Peat cut and dried as fuel | fuelwood_rotation | — | dung_cake_fuel | — |
| 500 | `standard_ingots` — Standard ingots for exchange | copper_casting, standard_weight_sets | — | weighed_alloy_recipes, down_the_line_exchange | — |
| 510 | `sulfur_purification` — Sulfur gathered and purified | ore_assaying | — | sickroom_fumigation | resources_known=Sulfur |
| 520 | `shaft_furnaces` — Shaft furnaces with clay tuyères | pot_bellows | — | refractory_body_trials | — |
| 530 | `alum_mordant_dyeing` — Mordant dyeing with alum | textile_dye_extraction | — | — | resources_known=Alum |
| 540 | `cored_socket_casting` — Cored castings for socketed tools | closed_moulds | — | socketed_spearheads | — |
| 555 | `ceramic_glaze_formulation` — Glazed pottery | glassmaking | — | faience, wheel_thrown_pottery | — |
| 565 | `refractory_body_trials` — Refractory clay bodies tested | clay_levigation, shaft_furnaces | — | — | — |
| 570 | `ceramic_crucibles` — Refractory crucibles | refractory_body_trials | — | — | — |
| 580 | `crucible_glass_melting` — Glass melted in crucibles | ceramic_crucibles, glassmaking | — | — | — |
| 590 | `core_formed_glass` — Core-formed glass vessels | crucible_glass_melting | — | — | — |
| 595 | `tapestry_weaving` — Tapestry weave on the upright loom | plain_weaving, textile_dye_extraction | — | twill_weave_structures, alum_mordant_dyeing | — |
| 600 | `refractory_brick_firing` — Fired refractory bricks for furnace linings | refractory_body_trials, kiln_fired_bricks | — | — | — |
