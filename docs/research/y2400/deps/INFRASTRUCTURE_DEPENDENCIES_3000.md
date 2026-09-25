# Infrastructure dependencies, years 2400–3000

Machine-readable source: `partials/pils.json`. The format follows `docs/research/deps/MAPPING_CONTRACT.md` and the 600–1200, 1200–1800 and 1800–2400 partials. Cross-line ids are marked with their line. Earlier-block ids are marked "0–600", "600–1200", "1200–1800" or "1800–2400". `Requires (any)` groups are separated by `;`. Every prerequisite and precedent is dated at or before its dependent (adjusted years from `partials/pils_year_adjustments.json`; registry years for other lines; proposed years for earlier blocks). Catalog ids keep the prerequisites written in `scripts/*.gd`, except where a catalog prerequisite is dated after its dependent; those cases are resolved by a year move inside the registry band or listed below. Years marked "was" are moved in `partials/pils_year_adjustments.json`.

Water and sewers: `steam_waterworks` + `pressure_pipe_jointing` (1800–2400) → `steam_pumped_waterworks` (2418) → `water_towers`, `hydraulic_power_mains`. `vaulted_brick_sewers` → `egg_shaped_sewers` (2505) → with Health's `sanitary_town_survey`, **`intercepting_sewers`** (2550) → with `microbial_growth_measurement`, `activated_sludge_treatment` (2704) → `nutrient_removal_treatment` (2862).

Light and power: Production's `coal_gas_works` → **`gas_lit_streets`** (2422) → with `filament_lamp_works`, `electric_street_lighting` (2615). `electrical_generators` + `compound_steam_engines` → **`central_power_stations`** (2619); `wound_transformers` (2628) → **`alternating_current_grids`** (2645) → `rural_electrification`, `electrified_main_lines` (logistics), `hydroelectric_stations` → **`concrete_arch_dams`** (2715) → **`river_basin_works`** (2752). Knowledge's `nuclear_fission` → **`reactor_engineering`** (2780) → **`nuclear_power_stations`** (2812) → `small_modular_reactors` (2995). Production's `module_encapsulation` → **`photovoltaic_power`** (2875); with `lithium_ion_cells`, **`grid_scale_batteries`** (2968).

Structures: `puddling_furnace` + `structural_load_testing` → `iron_roof_trusses` (2430) → market halls and **`prefabricated_iron_glass_halls`** (2533). `structural_steel` moves to 2625 so the catalog chain `structural_steel` → **`reinforced_concrete`** (2627) holds; with `safety_lifts`, **`skeleton_frame_towers`** (2640) → `framed_tube_supertall` (2848). `reinforced_concrete` + `steel_wire_drawing` → **`prestressed_concrete`** (2765) → `cable_stayed_bridges`. Bridges run `cast_iron_arch_bridge` → **`chain_suspension_bridges`** (2455) → with `steel_wire_drawing`, **`wire_cable_suspension_bridges`** (2622); `riveted_box_girder_bridges` → with converter steel, **`steel_long_span_bridges`** (2586).

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions | Note |
|---|---|---|---|---|---|---|
| 2410 | `back_to_back_terraces` | `speculative_terrace_rows` (1800–2400) | - | `house_pattern_books` (1800–2400), `iron_framed_fireproof_mill` (1800–2400) | - | Cheap terraces house mill hands in haste. |
| 2418 | `steam_pumped_waterworks` | `steam_waterworks` (1800–2400), `pressure_pipe_jointing` (1800–2400) | - | `cast_iron_water_mains` (1800–2400), `rotative_steam_engine` (production, 1800–2400) | - | Steam pumps lift town water into reservoirs. |
| 2422 | **`gas_lit_streets`** | `coal_gas_works` (production), `cast_iron_water_mains` (1800–2400) | - | `street_lantern_lighting` (1800–2400) | - | Gas lamps fed by mains light the streets. |
| 2430 | `iron_roof_trusses` | `puddling_furnace` (production, 1800–2400), `structural_load_testing` (knowledge, 1800–2400) | - | `iron_framed_fireproof_mill` (1800–2400), `grooved_bar_rolls` (production, 1800–2400) | - | Iron trusses span wide sheds and markets. |
| 2450 | `iron_roofed_market_halls` | `iron_roof_trusses`, `cast_plate_glass` (production, 1800–2400) | - | `merchants_exchange_hall` (1800–2400) | - | Market halls roofed in iron and glass. |
| 2455 | **`chain_suspension_bridges`** | `cast_iron_arch_bridge` (1800–2400), `puddling_furnace` (production, 1800–2400) | - | `structural_load_testing` (knowledge, 1800–2400) | - | Wrought-iron chains hang wide river spans. |
| 2464 | **`portland_cement_clinker`** | `refractory_furnaces` (production, 1800–2400), `clay_testing` (production, 0–600), `material_accounting` (knowledge, 0–600), `concrete_mix_design` (1800–2400) | - | - | resources_known=Limestone, Clay | Clinker burned hot from lime and clay. |
| 2465 | `cast_iron_street_fronts` | `iron_roof_trusses`, `sand_flask_casting` (production, 1800–2400) | - | - | - | Cast-iron fronts for shops and warehouses. |
| 2467 | **`tunnelling_shield`** | `canal_tunnels` (1800–2400), `cylinder_boring` (1800–2400) | - | `bridge_pier_caissons` (1800–2400) | - | A shield drives tunnels through soft ground. |
| 2485 | `light_stud_frame_houses` | `crank_driven_sawmills` (production, 1200–1800), `slitting_mills` (production, 1800–2400) | - | `nailer_workshops` (production, 1200–1800), `braced_timber_cage_walls` (1800–2400) | - | Houses nailed together from sawn studs. |
| 2495 | `brick_arch_viaducts` | `public_steam_railway` (logistics), `elliptical_arch_bridges` (1800–2400) | - | `canal_river_aqueducts` (1800–2400) | - | Many-arched brick viaducts carry level lines. |
| 2498 | `model_worker_dwellings` | `back_to_back_terraces`, `s_trap_water_closets` (1800–2400) | - | `steam_pumped_waterworks` | - | Model dwellings with water and privies on each stair. |
| 2505 | `egg_shaped_sewers` | `vaulted_brick_sewers` (1800–2400) | - | `culverted_town_streams` (1800–2400), `flow_continuity` (knowledge, 1800–2400) | - | Egg-shaped sewers scoured by their own flow. |
| 2530 | `riveted_box_girder_bridges` | `puddling_furnace` (production, 1800–2400), `grooved_bar_rolls` (production, 1800–2400), `structural_load_testing` (knowledge, 1800–2400) | - | `chain_suspension_bridges`, `public_steam_railway` (logistics) | - | Riveted iron box girders carry heavy loads. |
| 2533 | **`prefabricated_iron_glass_halls`** | `iron_roofed_market_halls`, `interchangeable_component_fits` (production) | - | `cast_plate_glass` (production, 1800–2400) | - | Halls built from standard iron and glass parts. |
| 2534 | `timber_lateral_bracing` | `framed_construction` (0–600) | `structural_load_testing` (knowledge, 1800–2400) / `experimental_controls` (knowledge, 1800–2400) | `light_stud_frame_houses` | - | Timber frames braced against wind and sway. |
| 2535 | `compressed_air_systems` | `pressure_vessels` (production, 1800–2400), `electric_motors` (production) | - | `high_pressure_steam_engines` (production) | - | Compressors feed air mains to works and tunnels. |
| 2536 | `mechanical_refrigeration` | `heat_engine_cycles` (knowledge), `pressure_vessels` (production, 1800–2400), `electric_motors` (production) | - | - | - | Compression machines chill cold stores. |
| 2539 | **`safety_lifts`** | `compound_pulleys` (600–1200), `mechanical_oscillation` (knowledge, 1800–2400) | - | `reversing_gear_hoists` (1800–2400) | - | Passenger lifts with safety catches. |
| 2545 | `rolled_iron_floor_beams` | `iron_framed_fireproof_mill` (1800–2400), `grooved_bar_rolls` (production, 1800–2400) | - | `iron_roof_trusses` | - | Rolled iron beams carry fireproof floors. |
| 2548 | `radiator_central_heating` | `narrow_throat_fireplace` (1800–2400), `pressure_pipe_jointing` (1800–2400) | - | `heated_orangeries` (1800–2400), `iron_flue_stoves` (1800–2400) | - | Radiators heat whole buildings. |
| 2550 | **`intercepting_sewers`** | `egg_shaped_sewers`, `sanitary_town_survey` (health) | - | `central_board_of_health` (health) | - | Intercepting sewers carry waste far downstream. |
| 2558 | **`boulevard_reconstruction`** | `cut_through_avenues` (1800–2400), `egg_shaped_sewers`, `gas_lit_streets` | - | `building_line_regulation` (1800–2400) | - | Boulevards cut through old quarters with services beneath. |
| 2560 | `sewer_rodding_service` | `covered_sewers` (0–600) | `joinery` (0–600) / `wire_drawing` (production, 600–1200) | - | - | Rodding crews clear blocked sewers. |
| 2570 | `pneumatic_caissons` | `bridge_pier_caissons` (1800–2400), `compressed_air_systems` | - | - | - | Compressed-air caissons sink deep bridge piers. |
| 2578 | `rock_drill_tunnelling` | `compressed_air_systems`, `powder_rock_blasting` (production, 1800–2400) | - | `tunnelling_shield` | - | Air-driven rock drills bore mountain tunnels. |
| 2586 | **`steel_long_span_bridges`** | `riveted_box_girder_bridges`, `pneumatic_steel_converter` (production) | - | `pneumatic_caissons` | - | Steel arches, trusses and cantilevers of long span. |
| 2588 | `asphalt_street_paving` | `toll_paved_streets` (1200–1800), `bitumen_sealing` (0–600) | - | `layered_stone_road_beds` (1800–2400), `road_rolling_maintenance` (1800–2400) | resources_known=Bitumen | Hot asphalt laid over concrete streets. |
| 2590 | `building_codes` | `building_line_regulation` (1800–2400), `sanitary_town_survey` (health) | - | `model_worker_dwellings` | - | Codes set walls, stairs, light and air. |
| 2595 | `hydraulic_power_mains` | `pressure_pipe_jointing` (1800–2400), `steam_pumped_waterworks` | - | `safety_lifts` | - | Pressure mains drive cranes, lifts and dock gates. |
| 2598 | `water_towers` | `steam_pumped_waterworks`, `water_tower_cisterns` (1800–2400) | - | - | - | Towers hold pressure for upper storeys and hydrants. |
| 2600 | `piped_hot_water_bathrooms` | `s_trap_water_closets` (1800–2400), `radiator_central_heating` | - | `steam_pumped_waterworks` | - | Piped hot water and bathrooms in ordinary houses. |
| 2610 | `hollow_tile_fireproof_floors` | `rolled_iron_floor_beams` | - | `iron_framed_fireproof_mill` (1800–2400) | - | Hollow clay tile floors resist fire. |
| 2615 | `electric_street_lighting` | `gas_lit_streets`, `filament_lamp_works` (production), `electrical_generators` (production) | - | - | - | Arc and filament lamps light streets and halls. |
| 2619 | **`central_power_stations`** | `electrical_generators` (production), `compound_steam_engines` (production) | - | `filament_lamp_works` (production) | resources_known=Coal | Central stations supply a district by wire. |
| 2620 | `refuse_destructors` | `sanitary_town_survey` (health), `refractory_furnaces` (production, 1800–2400) | - | - | - | Town refuse collected and burned in destructors. |
| 2622 | **`wire_cable_suspension_bridges`** | `chain_suspension_bridges`, `steel_wire_drawing` (production) | - | `steel_long_span_bridges` | - | Spun steel-wire cables hang very long spans. |
| 2625 (was 2632) | **`structural_steel`** | `blast_furnace` (production, 1200–1800), `precision_machinery` (1800–2400), `pneumatic_steel_converter` (production) | - | `rolled_iron_floor_beams` | - | Steel skeletons carry walls and floors. |
| 2627 | **`reinforced_concrete`** | `structural_steel`, `lime_mortar` (0–600), `portland_cement_clinker` | - | `concrete_formwork_systems` (1800–2400) | - | Steel rods cast in concrete. |
| 2628 | `wound_transformers` | `electromagnetic_induction` (knowledge), `cable_insulation` (production) | - | - | - | Transformers step voltage up and down. |
| 2635 | `plate_glass_shopfronts` | `cast_plate_glass` (production, 1800–2400), `cast_iron_street_fronts` | - | - | - | Plate-glass shopfronts line the streets. |
| 2640 | **`skeleton_frame_towers`** | `structural_steel`, `safety_lifts` | - | `hollow_tile_fireproof_floors` | - | Tall towers on steel skeletons with lifts. |
| 2642 | `street_utility_ducts` | `central_power_stations`, `telephone_circuits` (knowledge) | - | `boulevard_reconstruction` | - | Power and telephone wires ducted under streets. |
| 2645 | **`alternating_current_grids`** | `wound_transformers`, `central_power_stations` | - | `induction_motors` (production) | - | High-voltage alternating current between towns. |
| 2650 | `mountain_gravity_aqueducts` | `long_distance_conduits` (1200–1800), `portland_cement_clinker` | - | `rock_drill_tunnelling` | - | Long gravity aqueducts bring mountain water. |
| 2655 | **`hydroelectric_stations`** | `electrical_generators` (production), `tested_waterwheel_efficiency` (production, 1800–2400) | - | `alternating_current_grids`, `central_power_stations` | environment=river | Stations at falls and weirs generate power. |
| 2667 | `battery_bank_wiring` | `lead_acid_cells` (production), `cable_insulation` (production), `standard_measures` (knowledge, 0–600) | - | - | - | Battery rooms steady station supply. |
| 2668 | `concrete_compaction_practice` | `concrete_mix_design` (1800–2400) | `concrete_formwork_systems` (1800–2400) / `experimental_controls` (knowledge, 1800–2400) | - | - | Concrete compacted by rodding and vibration. |
| 2672 | `concrete_curing_control` | `concrete_mix_design` (1800–2400) | - | `portland_cement_clinker` | - | Concrete kept wet for a set time. |
| 2675 | `refrigerated_air_conditioning` | `mechanical_refrigeration`, `electric_motors` (production) | - | `humidity_measurement` (nutrition) | - | Refrigerating plant cools and dries rooms. |
| 2682 | `steel_sheet_pile_cofferdams` | `sheet_steel_rolling` (production), `roll_formed_sections` (production) | - | `bridge_pier_caissons` (1800–2400) | - | Driven steel sheet piles make quick cofferdams. |
| 2690 | `reinforced_concrete_bridges` | `reinforced_concrete` | - | `steel_long_span_bridges` | - | Reinforced concrete arch and beam bridges. |
| 2704 | `activated_sludge_treatment` | `intercepting_sewers`, `microbial_growth_measurement` (knowledge) | - | `compressed_air_systems` | - | Aerated sludge cleans sewage before release. |
| 2709 | `zoning_ordinances` | `building_codes` | - | - | - | Zoning separates homes, works and shops. |
| 2715 | **`concrete_arch_dams`** | `hydroelectric_stations`, `portland_cement_clinker` | - | `reinforced_concrete` | environment=river | Concrete dams store whole valleys. |
| 2720 | `shallow_foundation_assessment` | `soil_assays` (ecology), `structural_load_testing` (knowledge, 1800–2400) | - | - | - | Footings sized from tested soil bearing. |
| 2721 | `charge_regulation` | `battery_bank_wiring`, `resistive_sensing` (production), `electromagnetic_relays` (production) | - | - | - | Regulators charge station batteries automatically. |
| 2725 | **`public_housing_estates`** | `building_codes`, `model_worker_dwellings` | - | `municipal_utilities` (institutions) | - | Towns build rented estates for working families. |
| 2728 | `water_cement_ratio_design` | `concrete_mix_design` (1800–2400), `portland_cement_clinker` | - | `concrete_compaction_practice` | - | Concrete proportioned by water-cement ratio. |
| 2740 | `thin_concrete_shell_roofs` | `reinforced_concrete`, `water_cement_ratio_design` | - | - | - | Thin concrete shells roof halls and hangars. |
| 2745 | **`rural_electrification`** | `alternating_current_grids`, `hydroelectric_stations` | - | - | - | Power lines reach every village and farm. |
| 2746 | `buried_pipe_load_assessment` | `rigid_pipe_bedding` (0–600), `standard_measures` (knowledge, 0–600) | - | - | - | Buried pipes designed for soil and traffic loads. |
| 2748 | `foundation_settlement_monitoring` | `geometric_survey` (knowledge, 0–600), `shallow_foundation_assessment` | - | - | - | Foundation settlement measured over years. |
| 2752 | **`river_basin_works`** | `concrete_arch_dams`, `alternating_current_grids` | - | `canal_locks` (1200–1800) | environment=river | A basin authority builds dams, locks and stations. |
| 2765 | **`prestressed_concrete`** | `reinforced_concrete`, `steel_wire_drawing` (production) | - | `water_cement_ratio_design` | - | Tendons tensioned before loading. |
| 2770 | `pumped_storage_hydro` | `hydroelectric_stations`, `alternating_current_grids` | - | `concrete_arch_dams` | - | Water pumped up at night, released at the peak. |
| 2773 | `building_wind_load_assessment` | `aerodynamics` (knowledge), `structural_load_testing` (knowledge, 1800–2400) | - | - | - | Tall buildings designed for measured wind. |
| 2774 | `engineered_wood_lamination` | `adhesive_bond_design` (production), `timber_grading` (ecology, 0–600) | - | - | - | Glued laminated timber beams and arches. |
| 2780 | **`reactor_engineering`** | `nuclear_fission` (knowledge), `neutron_moderation` (knowledge), `pressure_vessels` (production, 1800–2400), `electrical_generators` (production) | - | - | resources_known=Uranium Ore | Controlled reactors with cooling and containment. |
| 2785 | `fluorescent_lighting` | `electric_street_lighting`, `glass_tube_drawing` (production) | - | - | - | Fluorescent tubes light offices and works. |
| 2790 | `welded_steel_frames` | `structural_steel`, `arc_welding_processes` (production), `welding_metallurgy` (production) | - | - | - | Welded frames replace site riveting. |
| 2798 | `climbing_tower_cranes` | `skeleton_frame_towers`, `electric_motors` (production) | - | `welded_steel_frames` | - | Tower cranes climb with the frame. |
| 2800 | `building_capillary_breaks` | `masonry_moisture_management` (600–1200) | - | - | - | Damp-proof courses break capillary rise. |
| 2801 | `conduit_infiltration_testing` | `standard_measures` (knowledge, 0–600) | `clay_pipe_socket_jointing` (0–600) / `wooden_log_conduits` (0–600) / `pressure_pipe_jointing` (1800–2400) | - | - | Sewers tested for infiltration. |
| 2802 | `timber_moisture_movement_design` | `timber_seasoning` (production, 0–600) | `masonry_moisture_management` (600–1200) / `experimental_controls` (knowledge, 1800–2400) | - | - | Timber designed for moisture movement. |
| 2803 | `slipformed_concrete_cores` | `reinforced_concrete`, `concrete_curing_control` | - | - | - | Cores and silos slip-formed without stopping. |
| 2805 | `curtain_wall_systems` | `structural_steel`, `reinforced_concrete`, `standard_measures` (knowledge, 0–600) | - | `plate_glass_shopfronts` | - | Glass walls hung on the frame. |
| 2812 | **`nuclear_power_stations`** | `reactor_engineering`, `alternating_current_grids` | - | - | resources_known=Uranium Ore | Nuclear stations feed the grid. |
| 2815 | `cable_stayed_bridges` | `prestressed_concrete`, `wire_cable_suspension_bridges` | - | `welded_steel_frames` | - | Decks hung straight from towers. |
| 2826 | `rainscreen_wall_assemblies` | `building_drainage_coordination` (0–600), `building_wind_load_assessment` | - | - | - | Rainscreen walls vented behind the cladding. |
| 2830 | `precast_panel_housing` | `reinforced_concrete`, `public_housing_estates` | - | `climbing_tower_cranes` | - | Blocks assembled from factory-cast panels. |
| 2832 | `seawater_desalination` | `fractional_distillation` (production), `polymer_film_extrusion` (production) | - | - | environment=coast | Plants make fresh water from the sea. |
| 2836 | `tunnel_boring_machines` | `tunnelling_shield`, `cemented_carbide_tools` (production) | - | `rock_drill_tunnelling` | - | Rotary machines cut whole tunnel bores. |
| 2845 | `direct_current_links` | `alternating_current_grids`, `silicon_rectifiers` (production) | - | - | - | DC links carry power under seas. |
| 2848 | `framed_tube_supertall` | `skeleton_frame_towers`, `building_wind_load_assessment` | - | `welded_steel_frames` | - | Framed-tube towers pass a hundred storeys. |
| 2850 | `cable_net_membrane_roofs` | `steel_wire_drawing` (production), `polymer_additive_formulation` (production) | - | `thin_concrete_shell_roofs` | - | Cable nets and membranes span stadiums. |
| 2855 | `ductile_seismic_codes` | `building_codes`, `earthquake_magnitude_scale` (ecology) | - | `welded_steel_frames` | - | Codes require ductile frames and tied walls. |
| 2860 | `seismic_base_isolation` | `ductile_seismic_codes`, `synthetic_rubber` (production) | - | - | - | Isolating bearings let buildings ride out quakes. |
| 2862 | `nutrient_removal_treatment` | `activated_sludge_treatment` | - | `environment_protection_agency` (ecology) | - | Sewage works strip nitrogen and phosphorus. |
| 2870 | `trenchless_pipe_relining` | `conduit_infiltration_testing`, `thermoplastic_processing` (production) | - | - | - | Old sewers relined without digging. |
| 2875 | **`photovoltaic_power`** | `module_encapsulation` (production), `electrical_measurement` (knowledge) | - | - | - | Solar plants of installed modules feed the grid. |
| 2878 | `wind_turbine_farms` | `alternating_current_grids`, `aerodynamics` (knowledge) | - | `carbon_fibre_composites` (production), `fantail_windmills` (production, 1800–2400) | - | Large wind turbines feed the grid. |
| 2882 | `storm_surge_barriers` | `river_basin_works`, `steel_sheet_pile_cofferdams` | - | `drained_lake_polders` (1800–2400) | environment=coast | Movable barriers close estuaries in floods. |
| 2890 | `building_management_systems` | `stored_program_control` (production), `refrigerated_air_conditioning` | - | `desk_computers` (knowledge) | - | Computers run heat, light and air. |
| 2895 | `accessible_building_rules` | `building_codes` | - | `civil_rights_law` (institutions) | - | Ramps, lifts and wide doors required. |
| 2900 | `low_energy_building_codes` | `building_codes`, `rainscreen_wall_assemblies` | - | `environment_protection_agency` (ecology) | - | Energy codes and very low-energy houses. |
| 2905 | `combined_cycle_stations` | `jet_propulsion` (production), `steam_turbines` (production), `alternating_current_grids` | - | - | - | Gas burned twice over for power. |
| 2930 | `acoustic_leak_detection` | `water_towers`, `single_chip_processors` (production) | - | `conduit_infiltration_testing` | - | Acoustic sensors listen for leaking mains. |
| 2935 | `green_cool_roofs` | `low_energy_building_codes` | - | `building_capillary_breaks` | - | Planted and reflective roofs cool districts. |
| 2945 | `smart_grid_metering` | `alternating_current_grids`, `internetworking_protocols` (knowledge) | - | `building_management_systems` | - | Smart meters balance the grid minute by minute. |
| 2955 | `rooftop_solar_home_batteries` | `photovoltaic_power`, `lithium_ion_cells` (production) | - | - | - | Rooftop solar and home batteries. |
| 2960 | `offshore_wind_farms` | `wind_turbine_farms`, `direct_current_links` | - | - | environment=coast | Wind farms on fixed and floating foundations. |
| 2962 | `mass_timber_towers` | `engineered_wood_lamination`, `timber_moisture_movement_design` | - | - | - | Towers of cross-laminated timber. |
| 2968 | **`grid_scale_batteries`** | `battery_bank_wiring`, `lithium_ion_cells` (production) | - | `smart_grid_metering` | - | Battery plants store surplus power. |
| 2975 | `sponge_districts` | `green_cool_roofs`, `climate_adaptation_plans` (ecology) | - | - | - | Parks and permeable paving soak up cloudbursts. |
| 2980 | `heat_pump_district_networks` | `radiator_central_heating`, `mechanical_refrigeration` | - | `low_energy_building_codes` | - | Heat pumps and district heat replace fuel burning. |
| 2985 | `printed_concrete_houses` | `additive_manufacturing` (production), `water_cement_ratio_design` | - | - | - | Gantry machines print houses in concrete. |
| 2988 | `near_zero_energy_retrofits` | `low_energy_building_codes`, `heat_pump_district_networks` | - | - | - | Old buildings retrofitted to near-zero energy. |
| 2990 | `low_carbon_cement` | `portland_cement_clinker` | - | `carbon_emission_market` (ecology) | - | Cement burned with less carbon, the rest captured. |
| 2995 | `small_modular_reactors` | `nuclear_power_stations` | - | `flexible_machining_cells` (production) | resources_known=Uranium Ore | Small factory-built reactors near towns. |
