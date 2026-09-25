# Production dependencies, years 2400–3000

Machine-readable source: `partials/pils.json`. The format follows `docs/research/deps/MAPPING_CONTRACT.md` and the 600–1200, 1200–1800 and 1800–2400 partials. Cross-line ids are marked with their line. Earlier-block ids are marked "0–600", "600–1200", "1200–1800" or "1800–2400". `Requires (any)` groups are separated by `;`. Every prerequisite and precedent is dated at or before its dependent (adjusted years from `partials/pils_year_adjustments.json`; registry years for other lines; proposed years for earlier blocks). Catalog ids keep the prerequisites written in `scripts/*.gd`, except where a catalog prerequisite is dated after its dependent; those cases are resolved by a year move inside the registry band or listed below. Years marked "was" are moved in `partials/pils_year_adjustments.json`.

Engines: `double_acting_engine` + `pressure_vessels` (1800–2400) → **`high_pressure_steam_engines`** (2410) → `steam_propulsion` (2452), `compound_steam_engines` (2540, with Knowledge's `heat_engine_cycles`) → **`steam_turbines`** (2624, with `electrical_generators`). `fuel_refining` (2557) + `heat_engine_cycles` → **`internal_combustion`** (2605) → `compression_ignition_engines` (2652) and **`powered_flight`** (2676) → `advanced_airframes` (2760) → **`jet_propulsion`** (2771). The catalog's `heat_engine_cycles` requirement of `steam_propulsion` is dropped: Carnot-cycle theory (2464) follows the first steamers. The registry link "`scheduled_river_steamers` (2419) continues `steam_propulsion` (2452)" runs backwards; it is demoted, so `scheduled_river_steamers` is a precedent of `steam_propulsion`, and the river steamer requires `trial_steam_paddle_boat` and `double_acting_engine`.

Iron and steel: `blast_furnace` + `iron_blowing_cylinders` → `hot_blast_smelting` (2475) → with `steel_refining`, **`pneumatic_steel_converter`** (2550) → **`open_hearth_steel`** (2573) → with `cryogenic_air_separation`, **`oxygen_steelmaking`** (2805) → with `green_hydrogen_electrolysis`, **`hydrogen_reduced_iron`** (2990). `electric_arc_furnaces` (2670) → `stainless_steel` (2705), `vacuum_metal_melting`, and with `continuous_metal_casting`, `scrap_steel_minimills` (2860).

Machine shop (catalog chain, re-dated inside bands): `lead_screw_cutting` (2540) → `split_feed_nuts` (2542) → `cross_slide_assembly` (2545), `tailstock_fitting` (2547), `four_jaw_chucks` → with `toolbit_heat_treatment` (2575), `centre_lathe_assembly` (2580) → `quill_feed_mechanisms` (2581) → with `drill_bit_fluting` (2576), `column_drilling_machines` (2583) → `milling_spindle_heads` (2586) and `milling_cutter_relief` (2590) → `horizontal_milling_machines` (2592) → `worm_dividing_heads` (2594) → **`basic_machine_shops`** (2595) → gauge blocks and drill jigs → **`precision_toolrooms`** (2676). The catalog's unplaced `gear_ratios` is replaced by `gear_cutting_engine` (1800–2400); `crank_linkages` by `crank_driven_sawmills` (1200–1800); `fiber_pulp_beating` by `hollander_beater` (1800–2400).

Chemistry: `coal_gas_works` (2420) → `aromatic_nitration` (2491) → with `coal_light_oil_recovery`, **`coal_tar_dyes`** (2554). `salt_cake_soda` + `coal_gas_works` → `ammonia_soda_process` (2577), which replaces the catalog's forward-dated `chloralkali_cells` and `metallurgical_mass_balances` as the caustic source of `alumina_refining` (2628) → **`aluminum_electrolysis`** (2630). `lead_acid_cells` (2647) takes `lead_chamber_acid` (1800–2400) in place of the contact process (2655). `industrial_catalyst_design` (2690) → `formaldehyde_synthesis` → **`phenolic_resin_moulding`** (2698); `iron_ammonia_catalysts` + `cryogenic_air_separation` → **`catalytic_ammonia_synthesis`** (2708) → `urea_synthesis`. Polymers run `polymer_chain_models` (2720) → `polymer_monomer_purification` (2735) → the chain and step polymerizations → **`thermoplastic_processing`** (2759) → `polymer_melt_rheology` (2760) → extrusion, moulding and foams.

Electronics: `electromagnetic_induction` (knowledge) → `electrical_generators` (2483), `electric_motors` (2492), `electromagnetic_relays` (2494) → `relay_logic` (2641) → `binary_adders` and `relay_registers`. `pn_junctions` + `semiconductor_doping` (knowledge 2802) → **`bipolar_junction_transistors`** (2803) → inverters, bistables, counters and registers; `single_crystal_growth` → `wafer_sawing` (2815) → `silicon_rectifiers` (2823) → `diode_logic`, `electronic_machine_control` (2824) → **`numerical_machine_control`** (2826) → `stored_program_control` (2838). Catalog `requires_any` members dated after the dependent (`diode_logic`, `parallel_register_banks`, `material_phase_diagrams`, `iron_ammonia_catalysts`, `electric_arc_furnaces`) are dropped from their groups. `bipolar_junction_transistors` + `wafer_sawing` → **`integrated_circuits`** (2825) → with `stored_program_control`, **`single_chip_processors`** (2853) → `deep_submicron_lithography` (2915) → **`extreme_ultraviolet_lithography`** (2972). **`industrial_robots`** moves to 2829 (after `hardwired_sequence_control`) so Labor's `automation_retraining` (2830) can require it.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions | Note |
|---|---|---|---|---|---|---|
| 2408 | **`punched_card_loom_control`** | `drawloom_pattern_control` (600–1200), `pictographic_records` (knowledge, 0–600) | - | `ribbon_engine_loom` (1800–2400), `flying_shuttles` (1800–2400) | - | Chained punched cards select the pattern threads. |
| 2410 | **`high_pressure_steam_engines`** | `double_acting_engine` (1800–2400), `pressure_vessels` (1800–2400) | - | `rotative_steam_engine` (1800–2400), `feedback_governors` (knowledge, 1800–2400) | resources_known=Coal | Strong boilers let small engines work at high steam. |
| 2413 | `continuous_paper_machine` | `wove_paper_moulds` (1800–2400), `belt_power_transmission` (1800–2400) | - | `hollander_beater` (1800–2400), `paper_sheet_pressing` (1200–1800) | - | Paper formed as an endless web on moving wire. |
| 2416 | `machine_block_line` | `precision_machinery` (infrastructure, 1800–2400), `belt_power_transmission` (1800–2400) | - | `screw_cutting_lathe` (1800–2400), `rotative_steam_engine` (1800–2400) | - | A line of special machines makes pulley blocks. |
| 2420 | `coal_gas_works` | `coke_firing` (1800–2400), `pressure_pipe_jointing` (infrastructure, 1800–2400) | - | `coal_tar_pitch` (1800–2400), `isolated_airs_chemistry` (knowledge, 1800–2400) | resources_known=Coal | Coal gas distilled in retorts and held in gasholders. |
| 2424 | **`interchangeable_component_fits`** | `dimensional_metrology` (knowledge), `workshop_standards` (knowledge, 0–600), `jig_filed_gunlocks` (1800–2400), `precision_machinery` (infrastructure, 1800–2400) | - | `screw_cutting_lathe` (1800–2400), `machine_block_line` | - | Parts made to gauges fit any machine. |
| 2440 | `iron_power_loom_sheds` | `flying_shuttles` (1800–2400), `belt_power_transmission` (1800–2400), `rotative_steam_engine` (1800–2400) | - | `mule_spinning` (1800–2400), `yarn_tension_control` (1800–2400) | - | Steam-driven iron looms fill weaving sheds. |
| 2452 | `steam_propulsion` | `precision_machinery` (infrastructure, 1800–2400), `high_pressure_steam_engines` | - | `scheduled_river_steamers` (logistics), `trial_steam_paddle_boat` (logistics, 1800–2400) | - | Engines drive paddle and screw hulls at sea. |
| 2464 | `friction_matches` | `isolated_airs_chemistry` (knowledge, 1800–2400), `oxygen_combustion_theory` (knowledge, 1800–2400) | - | `potash_saltpetre_works` (1800–2400) | resources_known=Sulfur | Chemical match heads light by friction. |
| 2467 | `plunger_pressed_glass` | `glassmaking` (0–600), `forge_welding` (600–1200), `workshop_standards` (knowledge, 0–600) | - | `cast_plate_glass` (1800–2400), `coal_fired_glass_furnace` (1800–2400) | - | Plungers press glass into iron moulds. |
| 2472 | `ring_spinning_systems` | `flyer_spinning` (1800–2400), `rotational_dynamics` (knowledge, 1800–2400) | - | `roller_water_frame` (1800–2400), `mule_spinning` (1800–2400) | - | Yarn wound continuously on a travelling ring. |
| 2475 | `hot_blast_smelting` | `blast_furnace` (1200–1800), `iron_blowing_cylinders` (1800–2400) | - | `coke_firing` (1800–2400), `refractory_furnaces` (1800–2400) | resources_known=Iron Ore | Heated blast cuts the iron furnace's fuel. |
| 2478 | `three_plate_lapping` | `standard_measures` (knowledge, 0–600), `stone_sorting` (0–600) | - | `screw_cutting_lathe` (1800–2400), `precision_machinery` (infrastructure, 1800–2400) | - | Three plates lapped together give true planes. |
| 2479 | `graphite_crucibles` | `graphite_marking` (knowledge, 1800–2400), `refractory_furnaces` (1800–2400) | - | `graphite_clay_crucibles` (1800–2400), `steel_refining` (1800–2400) | resources_known=Graphite | Clay-graphite crucibles last many meltings. |
| 2480 | `charcoal_retorts` | `charcoal` (0–600), `pressure_vessels` (1800–2400), `refractory_brick_firing` (0–600) | - | `coal_gas_works`, `turpentine_rosin_distilling` (1800–2400) | - | Closed retorts save the tars of charcoal burning. |
| 2482 | `wood_methanol_recovery` | `charcoal_retorts`, `chemical_distillation` (knowledge, 1200–1800) | - | `turpentine_rosin_distilling` (1800–2400) | - | Wood spirit and acetic acid caught from retort vapours. |
| 2483 | **`electrical_generators`** | `electromagnetic_induction` (knowledge), `precision_machinery` (infrastructure, 1800–2400) | - | `electrochemical_cells` (knowledge), `friction_electric_machine` (knowledge, 1800–2400) | - | Rotating magnets and coils make steady current. |
| 2484 | `fractional_distillation` | `chemical_distillation` (knowledge, 1200–1800), `precision_thermometry` (knowledge, 1800–2400) | - | `coal_gas_works`, `calorimetry` (knowledge, 1800–2400) | - | Columns part mixed liquids by boiling point. |
| 2485 | `water_electrolysis` | `electrochemical_cells` (knowledge), `electrical_generators`, `pressure_vessels` (1800–2400) | - | `isolated_airs_chemistry` (knowledge, 1800–2400) | - | Current splits water into hydrogen and oxygen. |
| 2486 | `gear_tooth_generation` | `gear_cutting_engine` (1800–2400), `dimensional_metrology` (knowledge) | - | `screw_cutting_lathe` (1800–2400) | - | Gear teeth cut to a true rolling curve. |
| 2488 | `straightedge_scraping` | `three_plate_lapping`, `forge_welding` (600–1200) | - | `precision_machinery` (infrastructure, 1800–2400) | - | Slides scraped straight against master straightedges. |
| 2491 | `aromatic_nitration` | `chemical_distillation` (knowledge, 1200–1800), `experimental_controls` (knowledge, 1800–2400), `coal_gas_works` | - | `coal_tar_pitch` (1800–2400), `lead_chamber_acid` (1800–2400) | - | Coal-tar benzene nitrated for dyes and explosives. |
| 2492 | **`electric_motors`** | `electromagnetic_induction` (knowledge), `precision_machinery` (infrastructure, 1800–2400) | - | `electrical_generators`, `electrochemical_cells` (knowledge) | - | Current turned back into motion. |
| 2494 | `electromagnetic_relays` | `electromagnetic_induction` (knowledge), `wire_drawing` (600–1200) | - | `electromagnet_sounders` (knowledge) | - | A weak current switches a strong one. |
| 2500 | `electroplating` | `electrochemical_cells` (knowledge), `electrical_measurement` (knowledge) | - | `fused_silver_plate` (1800–2400), `electrical_generators` | - | Current lays silver and nickel on base metal. |
| 2507 | `machine_way_scraping` | `straightedge_scraping`, `bearing_surfaces` (logistics, 0–600) | - | `precision_machinery` (infrastructure, 1800–2400) | - | Machine ways scraped to bearing marks. |
| 2508 | **`sulphur_cured_rubber`** | `sulfur_purification` (0–600), `experimental_controls` (knowledge, 1800–2400) | - | `calorimetry` (knowledge, 1800–2400), `bitumen_sealing` (infrastructure, 0–600) | resources_known=Sulfur; contact_required | Sulphur and heat cure rubber firm in heat and cold. |
| 2510 | `steam_hammer_forging` | `high_pressure_steam_engines`, `puddling_furnace` (1800–2400) | - | `iron_plate_hammer_mills` (1800–2400), `steam_propulsion` | - | Steam hammers forge shafts with a controlled blow. |
| 2523 | `sewing_machine_mechanisms` | `bone_needle_sewing` (0–600), `cam_motion_design` (1200–1800) | - | `interchangeable_component_fits`, `stocking_knitting_frame` (1800–2400) | - | Lockstitch machine with an eye-pointed needle. |
| 2525 | `cable_insulation` | `wire_drawing` (600–1200), `bitumen_sealing` (infrastructure, 0–600), `electrical_measurement` (knowledge) | - | `sulphur_cured_rubber`, `electrical_telegraphy` (knowledge) | - | Wire sheathed in gutta-percha and rubber. |
| 2530 | `leather_thickness_skiving` | `leather_goods_patterning` (0–600), `dimensional_metrology` (knowledge) | - | - | - | Leather skived to even thickness by machine. |
| 2533 | `coal_light_oil_recovery` | `coke_firing` (1800–2400), `fractional_distillation`, `coal_tar_pitch` (1800–2400) | - | `coal_gas_works` | - | Light oils and benzene recovered from coal tar. |
| 2535 | `cotter_pin_forming` | `wire_drawing` (600–1200), `forge_welding` (600–1200) | - | `slitting_mills` (1800–2400) | - | Split pins bent from half-round wire. |
| 2537 | `rivet_blank_heading` | `forge_welding` (600–1200), `standard_measures` (knowledge, 0–600) | - | `bolt_blank_forging` (1800–2400), `nut_blank_forging` (1800–2400) | - | Rivet blanks headed cold in dies. |
| 2540 | `compound_steam_engines` | `high_pressure_steam_engines`, `heat_engine_cycles` (knowledge) | - | `steam_propulsion`, `cylinder_boring` (infrastructure, 1800–2400) | - | Steam expanded twice for less coal. |
| 2540 (was 2549) | `lead_screw_cutting` | `standard_measures` (knowledge, 0–600), `steel_refining` (1800–2400), `gear_cutting_engine` (1800–2400) | - | `screw_cutting_lathe` (1800–2400) | - | Master lead screws cut and corrected. |
| 2542 (was 2551) | `split_feed_nuts` | `lead_screw_cutting`, `copper_smelting` (0–600) | - | - | - | Split nuts engage and release the lead screw. |
| 2545 | `cross_slide_assembly` | `machine_way_scraping`, `lead_screw_cutting`, `split_feed_nuts` | - | `screw_cutting_lathe` (1800–2400) | - | Cross-slides feed the tool square to the work. |
| 2547 | `tailstock_fitting` | `straightedge_scraping`, `lead_screw_cutting`, `bearing_surfaces` (logistics, 0–600) | - | `screw_cutting_lathe` (1800–2400) | - | Screw-fed tailstocks on standard lathes. |
| 2548 | `steelplate_engraving` | `burin_engraving` (knowledge, 1800–2400), `steel_refining` (1800–2400) | - | `stone_lithography` (knowledge, 1800–2400) | - | Hardened steel plates engraved for long runs. |
| 2550 | **`pneumatic_steel_converter`** | `steel_refining` (1800–2400), `hot_blast_smelting` | - | `puddling_furnace` (1800–2400), `refractory_furnaces` (1800–2400) | resources_known=Iron Ore | Air blown through molten iron makes cheap steel. |
| 2552 | `four_jaw_chucks` | `lead_screw_cutting`, `forge_welding` (600–1200) | - | - | - | Four-jaw chucks grip irregular work. |
| 2554 | **`coal_tar_dyes`** | `aromatic_nitration`, `coal_light_oil_recovery` | - | `fast_madder_red` (1800–2400), `systematic_chemical_names` (knowledge, 1800–2400) | - | The first coal-tar dye founds a dye trade. |
| 2555 | `thread_pitch_gauging` | `lead_screw_cutting`, `standard_measures` (knowledge, 0–600) | - | `screw_tap_and_die` (1800–2400) | - | Thread pitch checked with standard gauges. |
| 2556 | `lead_oxide_preparation` | `lead_smelting` (0–600), `chemical_distillation` (knowledge, 1200–1800), `experimental_controls` (knowledge, 1800–2400) | - | - | resources_known=Lead Ore | Litharge and red lead made in controlled furnaces. |
| 2556 (was 2566) | `sheet_steel_rolling` | `steel_refining` (1800–2400), `bearing_surfaces` (logistics, 0–600) | - | `grooved_bar_rolls` (1800–2400), `rolled_metal_strip` (1800–2400) | - | Sheet steel rolled thin in powered mills. |
| 2557 | **`fuel_refining`** | `fractional_distillation`, `precision_machinery` (infrastructure, 1800–2400) | - | `turpentine_rosin_distilling` (1800–2400), `coal_light_oil_recovery` | resources_known=Crude Oil | Rock oil distilled into lamp oil and fuels. |
| 2558 | `gas_composition_analysis` | `spectroscopy` (knowledge), `chemical_distillation` (knowledge, 1200–1800) | - | `coal_gas_works`, `isolated_airs_chemistry` (knowledge, 1800–2400) | - | Furnace gases analysed by absorption. |
| 2560 | `washer_punching` | `sheet_steel_rolling`, `standard_measures` (knowledge, 0–600) | - | - | - | Washers punched from sheet in one stroke. |
| 2561 | `abrasive_grinding_control` | `comparative_mineral_hardness` (ecology), `precision_machinery` (infrastructure, 1800–2400) | - | - | - | Grinding wheels graded by grit and bond. |
| 2562 | `tinplate_coating` | `sheet_steel_rolling`, `tin_smelting` (0–600) | - | `rolled_tinplate` (1800–2400) | resources_known=Tin Ore | Tin coated evenly on rolled steel sheet. |
| 2563 | `biomass_gasification` | `charcoal` (0–600), `gas_composition_analysis` | - | `coal_gas_works`, `charcoal_retorts` | - | Wood and peat turned into producer gas. |
| 2564 | `milling_table_feeds` | `cross_slide_assembly`, `machine_way_scraping` | - | - | - | Screw-fed milling tables advance the work steadily. |
| 2565 | `wood_pulp_paper` | `continuous_paper_machine`, `salt_cake_soda` (1800–2400) | - | `hollander_beater` (1800–2400) | - | Paper pulped from ground and cooked wood. |
| 2573 | **`open_hearth_steel`** | `pneumatic_steel_converter`, `refractory_furnaces` (1800–2400) | - | `coal_gas_works`, `biomass_gasification` | - | Regenerative hearth makes steel from pig and scrap. |
| 2575 (was 2600) | `toolbit_heat_treatment` | `steel_refining` (1800–2400), `charcoal` (0–600) | - | `metal_annealing_control` (1800–2400) | - | Tool bits hardened and tempered to a standard. |
| 2576 (was 2567) | `drill_bit_fluting` | `toolbit_heat_treatment`, `standard_measures` (knowledge, 0–600) | - | - | - | Twist drills milled with helical flutes. |
| 2577 | `ammonia_soda_process` | `salt_cake_soda` (1800–2400), `coal_gas_works` | - | `brine_purification` (1200–1800) | resources_known=Salt, Limestone | Soda ash made cleanly with gasworks ammonia. |
| 2580 | `centre_lathe_assembly` | `cross_slide_assembly`, `four_jaw_chucks`, `tailstock_fitting`, `toolbit_heat_treatment` | - | - | - | Standard lathes assembled from matched parts. |
| 2581 (was 2601) | `quill_feed_mechanisms` | `centre_lathe_assembly`, `bearing_surfaces` (logistics, 0–600), `lead_screw_cutting` | - | - | - | Quill feeds advance the drill spindle. |
| 2581 | `steel_wire_drawing` | `wire_drawing` (600–1200), `toolbit_heat_treatment` | - | `pneumatic_steel_converter` | - | Steel wire drawn through hard dies. |
| 2583 | `column_drilling_machines` | `quill_feed_mechanisms`, `drill_bit_fluting` | - | - | - | Column drills with powered feed. |
| 2584 (was 2582) | `nut_bore_drilling` | `nut_blank_forging` (1800–2400), `column_drilling_machines` | - | - | - | Nut bores drilled true to the thread size. |
| 2584 (was 2586) | `thread_tap_cutting` | `lead_screw_cutting`, `toolbit_heat_treatment` | - | `screw_tap_and_die` (1800–2400) | - | Taps made to cut internal threads. |
| 2585 (was 2575) | `bench_vise_screws` | `lead_screw_cutting`, `split_feed_nuts`, `column_drilling_machines` | - | - | - | Screw vices hold work at the fitter's bench. |
| 2585 | `thread_die_cutting` | `thread_tap_cutting`, `toolbit_heat_treatment` | - | `screw_tap_and_die` (1800–2400) | - | Screw threads cut with split dies. |
| 2586 (was 2593) | `milling_spindle_heads` | `centre_lathe_assembly`, `column_drilling_machines`, `gear_cutting_engine` (1800–2400) | - | - | - | Geared spindle heads on milling machines. |
| 2587 | `celluloid_moulding` | `aromatic_nitration`, `experimental_controls` (knowledge, 1800–2400) | - | `sulphur_cured_rubber` | contact_required | Nitrated cotton and camphor moulded as the first plastic. |
| 2588 | `external_thread_cutting` | `bolt_blank_forging` (1800–2400), `thread_die_cutting` | - | - | - | External threads cut to standard forms. |
| 2589 | `internal_thread_tapping` | `nut_bore_drilling`, `thread_tap_cutting` | - | - | - | Holes tapped to standard threads. |
| 2590 | `milling_cutter_relief` | `toolbit_heat_treatment`, `centre_lathe_assembly` | - | - | - | Cutters backed off for resharpening. |
| 2592 (was 2570) | `horizontal_milling_machines` | `milling_table_feeds`, `milling_spindle_heads`, `milling_cutter_relief` | - | `gear_cutting_engine` (1800–2400) | - | Arbor milling machines with a fed table. |
| 2592 | `matched_thread_inspection` | `thread_pitch_gauging`, `internal_thread_tapping` | - | `interchangeable_component_fits` | - | Threads checked with go and no-go gauges. |
| 2594 | `reamed_bore_finishing` | `column_drilling_machines`, `dimensional_metrology` (knowledge) | - | - | - | Bores reamed to a fitted size. |
| 2594 (was 2591) | `worm_dividing_heads` | `horizontal_milling_machines`, `gear_cutting_engine` (1800–2400) | - | - | - | Worm dividing heads index gears and flutes. |
| 2595 | **`basic_machine_shops`** | `centre_lathe_assembly`, `column_drilling_machines`, `bench_vise_screws` | - | `interchangeable_component_fits` | - | Lathes, drills and benches set out as one plant. |
| 2595 (was 2599) | `spring_wire_coiling` | `steel_wire_drawing`, `tailstock_fitting` | - | - | - | Spring wire coiled on powered arbors. |
| 2596 | `reciprocating_profile_slotting` | `crank_driven_sawmills` (1200–1800), `toolbit_heat_treatment` | - | - | - | Slotting machines cut keyways and profiles. |
| 2597 | `coil_spring_tempering` | `spring_wire_coiling`, `toolbit_heat_treatment` | - | - | - | Coil springs tempered to a set load. |
| 2598 | `progressive_profile_broaching` | `toolbit_heat_treatment`, `precision_machinery` (infrastructure, 1800–2400) | - | - | - | Stepped broach teeth cut a profile in one pass. |
| 2602 | `metal_spinning_forming` | `centre_lathe_assembly`, `sheet_steel_rolling` | - | - | - | Sheet spun over formers on the lathe. |
| 2604 | `glass_batch_composition_control` | `glassmaking` (0–600), `material_accounting` (knowledge, 0–600) | - | `clear_crystal_glass` (1800–2400), `systematic_chemical_names` (knowledge, 1800–2400) | - | Glass batches weighed to a set composition. |
| 2605 | **`internal_combustion`** | `fuel_refining`, `heat_engine_cycles` (knowledge), `precision_machinery` (infrastructure, 1800–2400) | - | `coal_gas_works`, `compound_steam_engines` | - | Fuel burned inside the cylinder on four strokes. |
| 2606 | `cylindrical_grinding` | `centre_lathe_assembly`, `abrasive_grinding_control` | - | - | - | Cylindrical grinding to fitted sizes. |
| 2608 | `surface_grinding` | `machine_way_scraping`, `abrasive_grinding_control` | - | - | - | Hardened flat parts surface-ground. |
| 2610 | `glass_tube_drawing` | `glass_blowing` (600–1200), `standard_measures` (knowledge, 0–600) | - | `drawn_cane_beads` (1800–2400) | - | Glass tubing drawn continuously to size. |
| 2612 | `filament_lamp_works` | `electrical_generators`, `vacuum_pumps` (knowledge, 1800–2400), `glass_tube_drawing` | - | `electroplating` | - | Carbon-filament lamps blown, pumped and sealed. |
| 2613 | `chain_power_transmission` | `forge_welding` (600–1200), `gear_cutting_engine` (1800–2400) | - | `belt_power_transmission` (1800–2400) | - | Roller chains carry power between sprockets. |
| 2614 | `shaft_alignment_methods` | `dimensional_metrology` (knowledge), `bearing_surfaces` (logistics, 0–600) | - | - | - | Shafts aligned by line, level and dial. |
| 2615 | `roll_formed_sections` | `sheet_steel_rolling`, `shaft_alignment_methods` | - | - | - | Sheet rolled into channels and sections. |
| 2616 | `rolling_element_bearings` | `dimensional_metrology` (knowledge), `hardened_edges` (600–1200) | - | `abrasive_grinding_control`, `cylindrical_grinding` | - | Ball and roller bearings ground to size. |
| 2621 | `fluid_film_bearings` | `viscous_resistance` (knowledge), `lubrication_regimes` (knowledge) | - | - | - | Oil films carry heavy shafts. |
| 2622 (was 2620) | `packed_piston_seals` | `plain_weaving` (0–600), `lubrication_regimes` (knowledge) | - | `double_acting_engine` (1800–2400) | - | Packed glands seal piston rods. |
| 2624 | **`steam_turbines`** | `electrical_generators`, `compound_steam_engines`, `heat_engine_cycles` (knowledge) | - | `rolling_element_bearings`, `fluid_film_bearings` | - | Turbines spin generators at high speed. |
| 2627 | `resistance_welding` | `electrical_measurement` (knowledge), `electrical_generators` | `forge_welding` (600–1200) | - | - | Sheet joined by resistance heating. |
| 2628 (was 2632) | `alumina_refining` | `ore_assaying` (0–600), `chemical_distillation` (knowledge, 1200–1800), `pressure_vessels` (1800–2400), `ammonia_soda_process` | - | - | resources_known=Bauxite | Bauxite digested in caustic liquor to alumina. |
| 2628 | `snap_fastener_closures` | `leather_goods_patterning` (0–600), `elastic_deformation` (knowledge, 1800–2400) | - | - | - | Snap fasteners pressed onto garments. |
| 2630 | **`aluminum_electrolysis`** | `alumina_refining`, `electrical_generators`, `electrochemical_cells` (knowledge) | - | `water_electrolysis` | resources_known=Bauxite | Aluminium won from molten salts by current. |
| 2635 | `induction_motors` | `electric_motors`, `wound_transformers` (infrastructure) | - | `electromagnetic_wave_theory` (knowledge) | - | Rotating-field motors run on alternating current. |
| 2638 | `cutting_fluid_management` | `calorimetry` (knowledge, 1800–2400), `lubrication_regimes` (knowledge) | - | - | - | Cutting fluids cool and wash the tool. |
| 2640 | `arc_welding_processes` | `electrical_measurement` (knowledge), `electrical_generators`, `forge_welding` (600–1200) | - | `resistance_welding` | - | Arc welding with carbon and metal electrodes. |
| 2641 | `relay_logic` | `electromagnetic_relays` | - | `polarized_telegraph_relays` (knowledge), `manual_switchboards` (knowledge) | - | Relay contacts wired to do logic. |
| 2645 | `chloralkali_cells` | `brine_purification` (1200–1800), `electrochemical_cells` (knowledge), `electrical_generators`, `pressure_vessels` (1800–2400) | - | `water_electrolysis` | resources_known=Salt | Brine split by current into chlorine and caustic. |
| 2646 (was 2671) | `porous_battery_separators` | `paper_making` (600–1200), `experimental_controls` (knowledge, 1800–2400) | - | - | - | Porous separators part battery plates. |
| 2647 | `hydrogen_chloride_synthesis` | `chloralkali_cells`, `pressure_vessels` (1800–2400), `chemical_distillation` (knowledge, 1200–1800) | - | - | - | Hydrogen burned in chlorine gives hydrochloric acid. |
| 2647 (was 2622) | `lead_acid_cells` | `electrochemical_cells` (knowledge), `lead_sheet_rolling` (600–1200), `lead_oxide_preparation`, `porous_battery_separators`, `lead_chamber_acid` (1800–2400) | - | `electrical_generators` | resources_known=Lead Ore | Rechargeable lead plates in acid. |
| 2650 | `regenerated_cellulose_fibre` | `celluloid_moulding`, `wood_pulp_paper` | - | `silk_throwing_mills` (1200–1800) | - | Dissolved wood cellulose spun as artificial silk. |
| 2652 | `compression_ignition_engines` | `internal_combustion`, `fuel_refining` | - | `heat_engine_cycles` (knowledge) | resources_known=Crude Oil | Compression ignites heavy oil in the cylinder. |
| 2652 (was 2656) | `sulfur_dioxide_recovery` | `sulfur_purification` (0–600), `sealed_vessels` (nutrition, 0–600) | - | `lead_chamber_acid` (1800–2400) | - | Sulphur dioxide recovered from smelter gases. |
| 2655 (was 2675) | `drill_jig_bushings` | `centre_lathe_assembly`, `column_drilling_machines` | - | - | - | Hardened bushings guide the drill. |
| 2655 | **`sulfuric_acid_production`** | `sulfur_dioxide_recovery`, `chemical_distillation` (knowledge, 1200–1800), `pressure_vessels` (1800–2400) | - | `lead_chamber_acid` (1800–2400) | resources_known=Sulfur | Contact process makes sulphuric acid on a catalyst. |
| 2658 (was 2674) | `drill_jig_layout` | `drill_jig_bushings`, `horizontal_milling_machines`, `standard_measures` (knowledge, 0–600) | - | - | - | Drill jigs laid out from datum faces. |
| 2658 | `gear_hobbing` | `gear_tooth_generation`, `milling_cutter_relief` | - | - | - | Gears cut continuously by hobbing. |
| 2659 | `carbon_resistors` | `electrical_measurement` (knowledge), `graphite_marking` (knowledge, 1800–2400) | - | - | - | Carbon resistors for measured circuits. |
| 2660 | `enzyme_catalysis` | `fermentation_control` (nutrition, 0–600), `chemical_distillation` (knowledge, 1200–1800) | - | `microbial_isolation_methods` (knowledge) | - | Enzymes used as catalysts in brewing and chemistry. |
| 2660 (was 2685) | `metallurgical_mass_balances` | `material_accounting` (knowledge, 0–600), `ore_assaying` (0–600) | - | `gas_composition_analysis` | - | Furnace charges balanced by assay and weight. |
| 2660 (was 2664) | `rivet_hole_alignment` | `sheet_steel_rolling`, `drill_jig_layout` | - | - | - | Rivet holes drifted and reamed in line. |
| 2661 | `gear_shaping_generation` | `gear_tooth_generation`, `precision_machinery` (infrastructure, 1800–2400) | - | - | - | Gears generated by a reciprocating shaper cutter. |
| 2662 | `hot_rivet_setting` | `rivet_blank_heading`, `rivet_hole_alignment` | - | `compressed_air_systems` (infrastructure) | - | Hot rivets set by pneumatic hammer. |
| 2663 | `nickel_metal_recovery` | `ore_assaying` (0–600), `metallurgical_mass_balances` | - | - | resources_known=Nickel Ore | Nickel refined from sulphide ores. |
| 2665 | `cold_rivet_setting` | `rivet_blank_heading`, `rivet_hole_alignment` | - | - | - | Small rivets set cold by press. |
| 2666 | `glass_annealing_schedules` | `glassmaking` (0–600) | - | - | - | Glass annealed on timed cooling schedules. |
| 2666 (was 2691) | `thread_rolling_die_making` | `thread_pitch_gauging`, `horizontal_milling_machines`, `toolbit_heat_treatment` | - | - | - | Hardened thread-rolling dies. |
| 2667 | `high_speed_tool_steel` | `toolbit_heat_treatment`, `metallurgical_mass_balances` | - | `graphite_crucibles` | - | Tool steel that cuts red-hot without softening. |
| 2668 | `bolt_thread_rolling` | `bolt_blank_forging` (1800–2400), `thread_rolling_die_making` | - | - | - | Bolt threads rolled instead of cut. |
| 2669 | `hydrogen_flame_glassworking` | `glass_tube_drawing`, `chemical_distillation` (knowledge, 1200–1800) | - | - | - | Glass worked in hydrogen and oxygen flames. |
| 2670 | **`electric_arc_furnaces`** | `steel_refining` (1800–2400), `electrical_generators`, `electrical_measurement` (knowledge) | - | `graphite_crucibles` | - | Electric arcs melt steel and alloys. |
| 2672 | `abrasive_belt_finishing` | `abrasive_grinding_control`, `belt_power_transmission` (1800–2400) | - | - | - | Abrasive belts finish curved parts. |
| 2673 | `gauge_block_lapping` | `three_plate_lapping`, `precision_machinery` (infrastructure, 1800–2400), `precision_thermometry` (knowledge, 1800–2400) | - | - | - | Gauge blocks lapped flat enough to wring. |
| 2676 | **`powered_flight`** | `aerodynamics` (knowledge), `structural_load_testing` (knowledge, 1800–2400), `internal_combustion` | - | `aerostat_observation` (security, 1800–2400), `wind_tunnel_testing` (knowledge) | - | Powered, controlled heavier-than-air flight. |
| 2676 | **`precision_toolrooms`** | `basic_machine_shops`, `horizontal_milling_machines`, `worm_dividing_heads`, `drill_jig_layout`, `gauge_block_lapping` | - | - | - | Toolrooms make jigs, gauges and fixtures. |
| 2677 | `cryogenic_air_separation` | `compressed_air_systems` (infrastructure), `mechanical_refrigeration` (infrastructure), `chemical_distillation` (knowledge, 1200–1800) | - | - | - | Liquefied air parted into oxygen and nitrogen. |
| 2678 | `electric_power_looms` | `flying_shuttles` (1800–2400), `crank_driven_sawmills` (1200–1800), `electric_motors` | - | `iron_power_loom_sheds` | - | Looms driven by their own motors. |
| 2679 | `electric_pulp_beating` | `hollander_beater` (1800–2400), `electric_motors`, `bearing_surfaces` (logistics, 0–600) | - | `wood_pulp_paper` | - | Pulp beaters driven by electric motors. |
| 2680 | `foil_capacitors` | `electrical_measurement` (knowledge), `paper_making` (600–1200), `wire_drawing` (600–1200) | - | `charge_storing_jar` (knowledge, 1800–2400) | - | Rolled foil capacitors. |
| 2681 | `castellated_nut_slotting` | `internal_thread_tapping`, `horizontal_milling_machines` | - | - | - | Nuts slotted for locking pins. |
| 2682 | `split_pin_locking` | `castellated_nut_slotting`, `cotter_pin_forming`, `column_drilling_machines` | - | - | - | Split pins lock nuts against vibration. |
| 2683 | `split_washer_cutting` | `coil_spring_tempering`, `washer_punching` | - | - | - | Spring washers cut from coiled wire. |
| 2684 | `metal_grain_size_measurement` | `compound_microscopy` (knowledge), `experimental_controls` (knowledge, 1800–2400) | - | `metallurgical_mass_balances` | - | Metal grain size measured under the microscope. |
| 2686 | `resistive_sensing` | `carbon_resistors`, `electrical_measurement` (knowledge) | - | - | - | Resistance thermometers and strain sensors. |
| 2687 | `rotary_swaging` | `precision_machinery` (infrastructure, 1800–2400), `toolbit_heat_treatment` | - | - | - | Rods and tubes reduced by rotary swaging. |
| 2688 | `silicon_smelting` | `electric_arc_furnaces`, `glassmaking` (0–600) | - | - | resources_known=Fine Sand | Silicon smelted in the electric furnace. |
| 2689 | `steel_normalizing_control` | `steel_refining` (1800–2400), `experimental_controls` (knowledge, 1800–2400) | - | `metal_annealing_control` (1800–2400), `metal_grain_size_measurement` | - | Steel normalised to refine its grain. |
| 2690 (was 2703) | `industrial_catalyst_design` | `experimental_controls` (knowledge, 1800–2400), `chemical_distillation` (knowledge, 1200–1800) | `enzyme_catalysis` / `sulfuric_acid_production` | - | - | Catalysts designed and tested for industry. |
| 2690 | `standard_fastener_kitting` | `matched_thread_inspection`, `washer_punching`, `split_washer_cutting` | - | - | - | Fasteners issued as counted kits. |
| 2692 | `directional_air_valves` | `pressure_pipe_jointing` (infrastructure, 1800–2400), `compressed_air_systems` (infrastructure) | - | - | - | Valves direct compressed air to actuators. |
| 2693 | `honed_bore_finishing` | `cylinder_boring` (infrastructure, 1800–2400), `abrasive_grinding_control` | - | - | - | Engine bores honed to a fine crosshatch. |
| 2693 | `pneumatic_cylinders` | `cylinder_boring` (infrastructure, 1800–2400), `packed_piston_seals`, `directional_air_valves` | - | - | - | Air cylinders move tools and clamps. |
| 2694 | `pneumatic_pressing` | `pneumatic_cylinders`, `column_buckling` (knowledge, 1800–2400), `workshop_standards` (knowledge, 0–600) | - | - | - | Pneumatic presses form and assemble parts. |
| 2695 | `textile_durability_testing` | `textile_repair_methods` (0–600), `measurement_uncertainty` (knowledge) | - | - | - | Cloth tested for abrasion and strength. |
| 2696 | `mechanical_washing_machines` | `textile_laundering_practice` (0–600), `crank_driven_sawmills` (1200–1800), `electric_motors` | - | - | - | Powered washing machines. |
| 2697 | `formaldehyde_synthesis` | `industrial_catalyst_design`, `chemical_distillation` (knowledge, 1200–1800), `experimental_controls` (knowledge, 1800–2400) | - | `wood_methanol_recovery` | - | Formaldehyde made from wood spirit on a catalyst. |
| 2698 | **`phenolic_resin_moulding`** | `formaldehyde_synthesis`, `coal_light_oil_recovery` | - | `celluloid_moulding` | - | Hard phenolic resin moulded under heat and pressure. |
| 2701 | `aromatic_amine_hydrogenation` | `industrial_catalyst_design`, `pressure_vessels` (1800–2400) | - | - | - | Aromatic amines made by hydrogenation. |
| 2704 | `iron_ammonia_catalysts` | `bloomery_smelting` (600–1200), `experimental_controls` (knowledge, 1800–2400), `chemical_distillation` (knowledge, 1200–1800), `pressure_vessels` (1800–2400), `cryogenic_air_separation` | `water_electrolysis` / `chloralkali_cells` | - | - | Promoted iron catalysts for ammonia. |
| 2705 | `stainless_steel` | `electric_arc_furnaces`, `metal_grain_size_measurement` | - | `steel_normalizing_control` | - | Chromium steels that do not rust. |
| 2706 | `material_phase_diagrams` | `crystallography` (knowledge), `precision_thermometry` (knowledge, 1800–2400) | - | `metal_grain_size_measurement` | - | Alloy phase diagrams guide heat treatment. |
| 2707 | `welding_metallurgy` | `forge_welding` (600–1200), `material_phase_diagrams` | - | `arc_welding_processes` | - | Weld metal and heated zones understood. |
| 2708 | **`catalytic_ammonia_synthesis`** | `iron_ammonia_catalysts`, `cryogenic_air_separation`, `pressure_vessels` (1800–2400) | `chloralkali_cells` / `water_electrolysis` | - | - | Ammonia fixed from air at high pressure. |
| 2710 | `hydrocarbon_steam_cracking` | `fuel_refining`, `pressure_vessels` (1800–2400), `precision_thermometry` (knowledge, 1800–2400) | - | - | resources_known=Crude Oil | Oil cracked by heat into lighter streams. |
| 2711 | `zipper_chain_closures` | `sewing_machine_mechanisms`, `dimensional_metrology` (knowledge) | - | - | - | Interlocking slide fasteners. |
| 2712 | `centrifugal_tube_casting` | `metal_casting_feed_design` (1800–2400), `precision_machinery` (infrastructure, 1800–2400) | - | - | - | Pipes cast in spinning moulds. |
| 2714 | `centerless_grinding` | `abrasive_grinding_control`, `precision_machinery` (infrastructure, 1800–2400) | - | - | - | Centreless grinding of pins and rollers. |
| 2720 | `polymer_chain_models` | `chemical_distillation` (knowledge, 1200–1800), `experimental_controls` (knowledge, 1800–2400) | - | `phenolic_resin_moulding`, `regenerated_cellulose_fibre` | - | Plastics understood as long chain molecules. |
| 2722 | `vacuum_metal_melting` | `vacuum_pumps` (knowledge, 1800–2400), `metal_casting_feed_design` (1800–2400) | - | `electric_arc_furnaces` | - | Metals melted in vacuum for purity. |
| 2724 | `garment_size_grading` | `garment_pattern_cutting` (0–600), `statistical_sampling` (knowledge) | - | - | - | Patterns graded into standard sizes. |
| 2728 | `urea_synthesis` | `pressure_vessels` (1800–2400), `chemical_distillation` (knowledge, 1200–1800), `experimental_controls` (knowledge, 1800–2400), `catalytic_ammonia_synthesis` | - | - | - | Urea made from ammonia and carbon dioxide. |
| 2730 | `cemented_carbide_tools` | `high_speed_tool_steel`, `electric_arc_furnaces` | - | `material_phase_diagrams` | - | Sintered carbide tips cut hardened steel. |
| 2735 (was 2742) | `polymer_monomer_purification` | `experimental_controls` (knowledge, 1800–2400) | `fractional_distillation` / `chemical_distillation` (knowledge, 1200–1800) | - | - | Monomers purified for polymer plants. |
| 2740 | `radical_chain_polymerization` | `polymer_monomer_purification` | - | - | - | Monomers chained by free radicals. |
| 2744 | `additive_step_polymerization` | `polymer_monomer_purification` | - | - | - | Polymers built by step addition. |
| 2746 | `brazed_joint_qualification` | `copper_casting` (0–600) | `forge_welding` (600–1200) / `experimental_controls` (knowledge, 1800–2400) | - | - | Brazed joints qualified by test. |
| 2747 | `condensative_step_polymerization` | `polymer_monomer_purification` | - | - | - | Polymers built by condensation. |
| 2748 | `polymer_solution_processing` | `polymer_chain_models`, `chemical_distillation` (knowledge, 1200–1800) | - | - | - | Polymers cast and spun from solution. |
| 2749 | `ethylene_oxide_synthesis` | `industrial_catalyst_design`, `chemical_distillation` (knowledge, 1200–1800), `experimental_controls` (knowledge, 1800–2400) | - | - | - | Ethylene oxide made by direct oxidation. |
| 2750 | `electrochemical_machining` | `electrochemical_cells` (knowledge), `precision_machinery` (infrastructure, 1800–2400) | - | - | - | Hard metals shaped by electrochemical dissolution. |
| 2751 | `residual_stress_assessment` | `stress_strain_relations` (knowledge, 1800–2400), `dimensional_metrology` (knowledge) | - | - | - | Residual stresses measured in parts. |
| 2752 | `ethylene_glycol_hydrolysis` | `chemical_distillation` (knowledge, 1200–1800), `experimental_controls` (knowledge, 1800–2400), `ethylene_oxide_synthesis` | - | - | - | Glycol made from ethylene oxide and water. |
| 2753 | `short_stroke_superfinishing` | `cylindrical_grinding`, `lubrication_regimes` (knowledge) | - | - | - | Bearing surfaces superfinished by short-stroke stones. |
| 2755 | `synthetic_rubber` | `polymer_chain_models`, `radical_chain_polymerization`, `hydrocarbon_steam_cracking` | - | `sulphur_cured_rubber` | - | Synthetic rubber made from butadiene. |
| 2758 | `induction_surface_hardening` | `electromagnetic_induction` (knowledge), `hardened_edges` (600–1200) | - | - | - | Surfaces hardened by induction heating. |
| 2759 | **`thermoplastic_processing`** | `polymer_chain_models`, `precision_thermometry` (knowledge, 1800–2400) | - | - | - | Thermoplastics melted and reshaped by machine. |
| 2760 | `advanced_airframes` | `powered_flight`, `wind_tunnel_testing` (knowledge), `structural_load_testing` (knowledge, 1800–2400) | - | `aluminum_electrolysis` | - | Stressed-skin metal airframes. |
| 2760 (was 2766) | `polymer_melt_rheology` | `thermoplastic_processing`, `viscous_resistance` (knowledge) | - | - | - | Plastic melt flow measured and predicted. |
| 2761 | `polymer_additive_formulation` | `thermoplastic_processing`, `experimental_controls` (knowledge, 1800–2400) | - | - | - | Plastics compounded with fillers and stabilisers. |
| 2762 | `polymer_film_extrusion` | `polymer_melt_rheology`, `precision_machinery` (infrastructure, 1800–2400) | - | - | - | Plastic film extruded and blown. |
| 2763 | `polymer_injection_molding` | `polymer_melt_rheology`, `precision_machinery` (infrastructure, 1800–2400) | - | - | - | Plastics injection-moulded in steel dies. |
| 2764 | **`polyamide_synthetic_fibre`** | `condensative_step_polymerization`, `polymer_solution_processing` | - | `regenerated_cellulose_fibre` | - | Synthetic fibre drawn from a polyamide melt. |
| 2765 | `binary_adders` | `relay_logic` | - | `geared_adding_machine` (knowledge, 1800–2400) | - | Binary adders built from relays. |
| 2767 | `isocyanate_synthesis` | `chemical_distillation` (knowledge, 1200–1800), `pressure_vessels` (1800–2400), `experimental_controls` (knowledge, 1800–2400) | - | - | - | Isocyanates for foams and coatings. |
| 2768 | `polymer_blow_molding` | `polymer_melt_rheology`, `compressed_air_systems` (infrastructure) | - | - | - | Hollow plastic ware blow-moulded. |
| 2769 | `relay_registers` | `relay_logic` | - | - | - | Relay registers hold binary numbers. |
| 2770 (was 2773) | `adhesive_bond_design` | `experimental_controls` (knowledge, 1800–2400) | `joinery` (infrastructure, 0–600) / `elastic_deformation` (knowledge, 1800–2400) | `phenolic_resin_moulding` | - | Structural adhesives designed for joints. |
| 2770 | `catalytic_cracking` | `fuel_refining`, `industrial_catalyst_design` | - | `hydrocarbon_steam_cracking` | - | Catalysts lift the fuel yield of crude. |
| 2771 | **`jet_propulsion`** | `advanced_airframes`, `heat_engine_cycles` (knowledge) | - | `steam_turbines`, `compression_ignition_engines` | - | Gas-turbine jet engines. |
| 2772 | `textile_waterproofing` | `plain_weaving` (0–600), `adhesive_bond_design` | - | `sulphur_cured_rubber` | - | Cloth waterproofed with synthetic coatings. |
| 2774 | `ionic_chain_polymerization` | `polymer_monomer_purification` | - | - | - | Ionic chain polymerization. |
| 2775 | `garment_seam_sealing` | `textile_waterproofing`, `sewing_machine_mechanisms` | - | - | - | Garment seams sealed against water. |
| 2776 | `polymer_foam_cell_control` | `polymer_additive_formulation`, `polymer_melt_rheology` | - | - | - | Foam cell size controlled in plastics. |
| 2777 | `polymer_molecular_weight_control` | `polymer_chain_models`, `measurement_uncertainty` (knowledge) | - | - | - | Polymer chain length controlled. |
| 2778 | `polymer_reaction_heat_management` | `calorimetry` (knowledge, 1800–2400) | `radical_chain_polymerization` / `condensative_step_polymerization` / `additive_step_polymerization` | - | - | Reaction heat managed in polymer reactors. |
| 2779 | `polymer_solvent_recovery` | `polymer_solution_processing`, `fractional_distillation` | - | - | - | Solvents recovered in polymer plants. |
| 2781 | `sinker_electrical_discharge_machining` | `electrical_measurement` (knowledge), `precision_machinery` (infrastructure, 1800–2400) | - | - | - | Hard dies sunk by electric spark. |
| 2784 (was 2787) | `chlorosilane_purification` | `silicon_smelting`, `fractional_distillation` | - | - | - | Silicon purified through chlorosilanes. |
| 2786 | `single_crystal_growth` | `crystallography` (knowledge), `chlorosilane_purification`, `precision_thermometry` (knowledge, 1800–2400) | - | - | - | Single crystals pulled from the melt. |
| 2788 | `tube_rotary_draw_bending` | `precision_machinery` (infrastructure, 1800–2400), `stress_strain_relations` (knowledge, 1800–2400) | - | - | - | Tubes bent on rotary draw benders. |
| 2790 | `nuclear_magnetic_resonance_spectroscopy` | `atomic_physics` (knowledge), `spectroscopy` (knowledge), `resonant_tuned_circuits` (knowledge), `precision_thermometry` (knowledge, 1800–2400) | - | - | - | Molecules identified by nuclear magnetic resonance. |
| 2796 | `ultrasonic_abrasive_machining` | `mechanical_oscillation` (knowledge, 1800–2400), `precision_machinery` (infrastructure, 1800–2400) | - | - | - | Brittle materials cut by ultrasonic abrasive. |
| 2798 | `polymer_thermoforming` | `thermoplastic_processing` | `vacuum_pumps` (knowledge, 1800–2400) / `compressed_air_systems` (infrastructure) / `precision_machinery` (infrastructure, 1800–2400) | - | - | Plastic sheet thermoformed. |
| 2799 | `textile_moisture_transport` | `fiber_grading` (ecology, 0–600), `experimental_controls` (knowledge, 1800–2400) | - | `polyamide_synthetic_fibre` | - | Fabrics engineered to move sweat. |
| 2800 | `continuous_metal_casting` | `steel_refining` (1800–2400), `metal_casting_feed_design` (1800–2400) | - | `open_hearth_steel` | - | Steel cast continuously into slabs and billets. |
| 2801 | `machine_tool_stiffness_assessment` | `stress_strain_relations` (knowledge, 1800–2400), `dimensional_metrology` (knowledge) | - | - | - | Machine-tool stiffness measured and improved. |
| 2802 | `ring_opening_polymerization` | `industrial_catalyst_design` | `polymer_chain_models` / `experimental_controls` (knowledge, 1800–2400) | - | - | Ring-opening polymerization. |
| 2803 | **`bipolar_junction_transistors`** | `pn_junctions` (knowledge), `semiconductor_doping` (knowledge) | - | `crystal_radio_detection` (knowledge), `single_crystal_growth` | - | Junction transistors made in quantity. |
| 2804 | `memory_address_decoding` | `relay_logic` | - | `relay_registers` | - | Memory address decoding circuits. |
| 2805 | **`oxygen_steelmaking`** | `open_hearth_steel`, `cryogenic_air_separation` | - | `pneumatic_steel_converter` | - | Pure oxygen blown on molten iron makes steel. |
| 2806 | `read_write_memory` | `memory_address_decoding`, `relay_registers` | - | - | - | Addressable read-write memory. |
| 2807 | `transistor_amplifiers` | `bipolar_junction_transistors`, `carbon_resistors`, `foil_capacitors` | - | `triode_valves` (knowledge) | - | Transistor amplifiers. |
| 2808 | `coordination_polymerization` | `industrial_catalyst_design` | `polymer_chain_models` / `experimental_controls` (knowledge, 1800–2400) | - | - | Catalysts that order polymer chains. |
| 2810 | `transistor_inverters` | `bipolar_junction_transistors`, `carbon_resistors` | - | - | - | Transistor inverters. |
| 2811 | `bistable_multivibrators` | `transistor_inverters` | - | - | - | Bistable circuits hold one bit. |
| 2812 | `binary_counters` | `bistable_multivibrators` | - | - | - | Binary counters. |
| 2812 (was 2817) | `shift_registers` | `bistable_multivibrators` | - | - | - | Shift registers. |
| 2813 | `parallel_register_banks` | `bistable_multivibrators` | - | - | - | Parallel register banks. |
| 2814 | `instruction_registers` | `shift_registers`, `binary_counters` | - | - | - | Instruction registers. |
| 2815 | `conditional_branch_circuits` | `binary_adders`, `transistor_inverters` | - | - | - | Conditional branch circuits. |
| 2815 (was 2835) | `wafer_sawing` | `single_crystal_growth`, `standard_measures` (knowledge, 0–600) | - | - | - | Silicon ingots sawn into wafers. |
| 2816 | `program_counters` | `binary_counters`, `binary_adders` | - | - | - | Program counters. |
| 2818 | `ultrasonic_metal_joining` | `mechanical_oscillation` (knowledge, 1800–2400), `precision_machinery` (infrastructure, 1800–2400) | - | - | - | Thin metals joined by ultrasonic welding. |
| 2819 | `polymer_tacticity_characterization` | `coordination_polymerization`, `spectroscopy` (knowledge) | - | - | - | Polymer tacticity characterised. |
| 2820 | `polymer_weathering_trials` | `polymer_additive_formulation`, `statistical_inference` (knowledge) | - | - | - | Plastics tested against weather. |
| 2821 | `size_exclusion_chromatography` | `polymer_solution_processing`, `glass_tube_drawing`, `optical_lenses` (knowledge, 1200–1800), `experimental_controls` (knowledge, 1800–2400), `measurement_uncertainty` (knowledge) | - | - | - | Polymers sorted by size-exclusion chromatography. |
| 2822 | `lost_foam_casting` | `polymer_foam_cell_control`, `metal_casting_feed_design` (1800–2400) | - | - | - | Metal cast into lost-foam patterns. |
| 2823 | `silicon_rectifiers` | `pn_junctions` (knowledge), `wafer_sawing` | - | - | - | Silicon rectifiers. |
| 2824 | `diode_logic` | `silicon_rectifiers`, `carbon_resistors` | - | - | - | Diode logic gates. |
| 2824 (was 2828) | `electronic_machine_control` | `transistor_amplifiers`, `resistive_sensing`, `electromagnetic_relays`, `wound_transformers` (infrastructure), `silicon_rectifiers`, `feedback_governors` (knowledge, 1800–2400) | - | - | - | Electronic machine control. |
| 2825 | **`integrated_circuits`** | `bipolar_junction_transistors`, `wafer_sawing` | - | `diode_logic` | - | Many transistors made together on one chip. |
| 2826 | **`numerical_machine_control`** | `electronic_machine_control`, `coordinate_geometry` (knowledge, 1800–2400) | - | `punched_card_tabulation` (knowledge) | - | Machine tools run from punched numerical instructions. |
| 2827 | `float_glass` | `cast_plate_glass` (1800–2400), `glass_annealing_schedules` | - | `tinplate_coating` | resources_known=Fine Sand, Tin Ore | Plate glass floated flat on molten tin. |
| 2829 | `hardwired_sequence_control` | `binary_counters`, `shift_registers`, `binary_adders`, `electronic_machine_control` | - | - | - | Hardwired sequence controllers. |
| 2829 (was 2834) | **`industrial_robots`** | `numerical_machine_control`, `hardwired_sequence_control` | - | `resistance_welding`, `pneumatic_cylinders` | - | Programmable arms weld and lift on the line. |
| 2830 | `gear_power_skiving` | `gear_tooth_generation`, `numerical_machine_control` | - | - | - | Gear power skiving. |
| 2831 | `machine_condition_monitoring` | `mechanical_oscillation` (knowledge, 1800–2400), `statistical_sampling` (knowledge) | - | - | - | Machines monitored against a condition baseline. |
| 2832 | `metal_fracture_toughness_testing` | `stress_strain_relations` (knowledge, 1800–2400) | `cyclic_fatigue` (knowledge) / `structural_load_testing` (knowledge, 1800–2400) | - | - | Metal fracture toughness tested. |
| 2833 | `solar_cell_fabrication` | `photovoltaic_conversion` (knowledge), `wafer_sawing`, `semiconductor_doping` (knowledge) | - | - | - | Silicon solar cells fabricated. |
| 2836 | `copolymer_sequence_control` | `polymer_molecular_weight_control` | `radical_chain_polymerization` / `ionic_chain_polymerization` / `coordination_polymerization` | - | - | Copolymer sequences controlled. |
| 2838 | `stored_program_control` | `read_write_memory`, `instruction_registers`, `program_counters`, `conditional_branch_circuits`, `electronic_machine_control` | - | - | - | Stored-program controllers run machines. |
| 2840 | `carbon_fibre_composites` | `radical_chain_polymerization`, `adhesive_bond_design` | - | `advanced_airframes` | - | Carbon fibre in resin gives light stiff parts. |
| 2842 | `incremental_sheet_forming` | `numerical_machine_control`, `sheet_steel_rolling` | - | - | - | Incremental sheet forming. |
| 2843 | `rotor_spinning_systems` | `drop_spindles` (0–600), `rotational_dynamics` (knowledge, 1800–2400), `electric_motors` | - | `ring_spinning_systems` | - | Open-end rotor spinning. |
| 2848 | `wire_electrical_discharge_machining` | `electrical_measurement` (knowledge), `numerical_machine_control` | - | `sinker_electrical_discharge_machining` | - | Wire spark cutting of hard dies. |
| 2850 | `abrasive_waterjet_cutting` | `pressure_vessels` (1800–2400), `numerical_machine_control` | - | - | - | Abrasive waterjet cutting. |
| 2853 | **`single_chip_processors`** | `integrated_circuits`, `stored_program_control` | - | `arithmetic_logic_units` (knowledge), `microinstruction_sequencing` (knowledge) | - | A whole processor on one chip. |
| 2860 | `scrap_steel_minimills` | `electric_arc_furnaces`, `continuous_metal_casting` | - | `open_hearth_steel` | - | Scrap-fed minimills make steel near buyers. |
| 2865 | `computer_aided_design` | `stored_program_control`, `numerical_machine_control` | - | `formula_programming_languages` (knowledge), `coordinate_geometry` (knowledge, 1800–2400) | - | Parts drawn and tested on screen first. |
| 2870 | `flexible_machining_cells` | `numerical_machine_control`, `stored_program_control` | - | `industrial_robots` | - | Machining cells switch parts without retooling. |
| 2875 | `module_encapsulation` | `solar_cell_fabrication`, `glassmaking` (0–600), `cable_insulation` | - | - | - | Solar cells sealed into weatherproof modules. |
| 2880 | `surface_mount_assembly` | `integrated_circuits`, `industrial_robots` | - | `single_chip_processors` | - | Pick-and-place machines assemble circuit boards. |
| 2885 | `additive_manufacturing` | `computer_aided_design`, `thermoplastic_processing` | - | `flexible_machining_cells` | - | Parts built layer by layer from a digital model. |
| 2890 | `statistical_quality_programs` | `statistical_sampling` (knowledge), `measurement_uncertainty` (knowledge) | - | `quality_circles` (labor), `lean_production` (labor) | - | Statistical programs drive defects toward none. |
| 2902 | **`lithium_ion_cells`** | `electrochemical_cells` (knowledge), `crystallography` (knowledge), `polymer_film_extrusion` | - | `lead_acid_cells` | - | Light rechargeable lithium-ion cells. |
| 2910 | `flat_panel_displays` | `integrated_circuits`, `float_glass` | - | `solid_state_physics` (knowledge) | - | Liquid-crystal panels made on glass sheets. |
| 2915 | `deep_submicron_lithography` | `integrated_circuits`, `single_chip_processors` | - | `computer_aided_design` | - | Chip features printed below the light's wavelength. |
| 2925 | `solid_state_lighting` | `pn_junctions` (knowledge), `single_crystal_growth` | - | `fluorescent_lighting` (infrastructure), `filament_lamp_works` | - | White light from semiconductor diodes. |
| 2930 | `selective_polymer_depolymerization` | `polymer_chain_models`, `industrial_catalyst_design` | - | `polymer_weathering_trials` | - | Plastics broken back into monomers. |
| 2938 | `machine_vision_inspection` | `single_chip_processors`, `statistical_quality_programs` | - | `industrial_robots` | - | Cameras and software inspect every part. |
| 2945 | `metal_powder_printing` | `additive_manufacturing`, `welding_metallurgy` | - | `vacuum_metal_melting` | - | Lasers fuse metal powder into parts. |
| 2950 | `wide_bandgap_power_chips` | `deep_submicron_lithography`, `single_crystal_growth` | - | `solid_state_lighting` | - | Wide-bandgap chips switch high voltage efficiently. |
| 2955 | `collaborative_robots` | `industrial_robots`, `machine_vision_inspection` | - | - | - | Light robots work beside people without cages. |
| 2965 | `plant_based_plastics` | `condensative_step_polymerization`, `enzyme_catalysis` | - | `selective_polymer_depolymerization` | - | Plastics made from plant sugars. |
| 2970 | `digital_twin_plants` | `computer_aided_design`, `machine_condition_monitoring`, `cloud_data_halls` (knowledge) | - | - | - | Whole plants mirrored by live models. |
| 2972 | **`extreme_ultraviolet_lithography`** | `deep_submicron_lithography`, `vacuum_pumps` (knowledge, 1800–2400) | - | - | - | Chips patterned with extreme ultraviolet light. |
| 2978 | `iron_phosphate_cells` | `lithium_ion_cells` | - | - | - | Cobalt-free iron-phosphate cells. |
| 2982 | `green_hydrogen_electrolysis` | `water_electrolysis` | `photovoltaic_power` (infrastructure) / `wind_turbine_farms` (infrastructure) | `chloralkali_cells` | - | Water split at scale with surplus clean power. |
| 2985 | `engineered_microbe_chemicals` | `enzyme_catalysis`, `hereditary_double_helix` (knowledge) | - | `recombinant_vaccine` (health) | - | Engineered microbes brew chemicals in tanks. |
| 2990 | **`hydrogen_reduced_iron`** | `oxygen_steelmaking`, `green_hydrogen_electrolysis` | - | `scrap_steel_minimills` | resources_known=Iron Ore | Iron ore reduced with hydrogen instead of coke. |
| 2993 | `perovskite_tandem_cells` | `solar_cell_fabrication` | - | `flat_panel_displays` | - | Tandem solar cells pass the silicon limit. |
| 2996 | `solid_state_battery_cells` | `lithium_ion_cells` | - | `iron_phosphate_cells` | - | Solid-electrolyte cells leave the pilot line. |
