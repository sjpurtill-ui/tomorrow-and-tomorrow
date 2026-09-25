# Knowledge dependencies: years 2400–3000

Machine-readable source: `partials/kicl.json` (knowledge, institutions, culture, labor). Contract: the 600–1200 mapping (`docs/research/y600/deps/partials/kicl.json`, merged by `tools/research/merge_graph_1200.py`) and its 1200–1800 and 1800–2400 successors. Ids come from `registry_3000.json`, `registry_2400.json` with the 1800–2400 partials, the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), and the game's baked 0–600 and 600–1200 blocks. Prerequisites may be ids of any earlier block in any line, or 2400–3000 ids, and every prerequisite and precedent is dated at or before its dependent (registry target years after the year adjustments; earlier blocks at their baked or graph years). Brackets mark a parent from another line or an earlier block: `[production]` is a 2400–3000 id owned by Production, `[ecology, 1800-2400]` is a 1800–2400 Ecology id, `[1200-1800]` is a same-line 1200–1800 id. `contact_required` marks items that need ocean contact, directly or through a contact-gated hard parent. Chains are modern (AD 1800–2030). No year moves are proposed for this line.

**138 entries, 242 hard edges, 262 precedent edges, 0 requires_any groups.** Coast-gated: `undersea_telegraph_cable`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2400 | `electrochemical_cells` | `charge_storing_jar` [1800-2400], `zinc_retort_distillation` [production, 1800-2400] |  | `friction_electric_machine` [1800-2400], `lightning_electricity_trial` [1800-2400], `torsion_balance_force_law` [1800-2400], `isolated_airs_chemistry` [1800-2400] |  |
| 2400 | `statistical_inference` | `probability_theory` [1800-2400] |  | `mortality_bill_arithmetic` [demography, 1800-2400], `register_life_table` [demography, 1800-2400], `birth_multiplier_estimates` [demography, 1800-2400] |  |
| 2408 | `atomic_combining_weights` | `systematic_chemical_names` [1800-2400], `oxygen_combustion_theory` [1800-2400] |  | `isolated_airs_chemistry` [1800-2400], `calorimetry` [1800-2400] |  |
| 2413 | `optical_telegraphy` | `shutter_signal_frames` [1800-2400] |  | `two_lens_telescope` [1800-2400], `numbered_signal_flags` [security, 1800-2400], `military_telegraph_lines` [security, 1800-2400] |  |
| 2416 | `least_squares_estimation` | `statistical_inference`, `differential_calculus` [1800-2400] |  | `decimal_earth_measures` [1800-2400], `comet_return_prediction` [1800-2400] |  |
| 2424 | `dimensional_metrology` | `decimal_earth_measures` [1800-2400], `precision_machinery` [infrastructure, 1800-2400] |  | `screw_cutting_lathe` [production, 1800-2400], `precision_thermometry` [1800-2400] |  |
| 2424 | `measurement_uncertainty` | `statistical_inference` |  | `least_squares_estimation`, `decimal_earth_measures` [1800-2400] |  |
| 2427 | `research_university` | `chartered_university` [1200-1800], `salaried_science_academy` [1800-2400] |  | `state_polytechnic_school` [1800-2400], `laboratory_notebooks` [1800-2400], `ruler_founded_universities` [1800-2400], `mining_engineering_academies` [1800-2400] |  |
| 2437 | `cylinder_press_printing` | `screw_press_printing` [1800-2400], `rotative_steam_engine` [production, 1800-2400] |  | `continuous_paper_machine` [production], `metal_type_casting` [1800-2400], `daily_printed_newspaper` [1800-2400] |  |
| 2453 | `electrical_measurement` | `electrochemical_cells` |  | `torsion_balance_force_law` [1800-2400], `earth_magnet_treatise` [1800-2400] |  |
| 2459 | `dimensional_analysis` | `differential_equations` [1800-2400] |  | `decimal_earth_measures` [1800-2400], `dimensional_metrology` |  |
| 2459 | `harmonic_analysis` | `differential_equations` [1800-2400], `integral_calculus` [1800-2400] |  | `mechanical_oscillation` [1800-2400], `calorimetry` [1800-2400] |  |
| 2459 | `viscous_resistance` | `flow_continuity` [1800-2400], `differential_equations` [1800-2400] |  | `friction_measurement` [1800-2400] |  |
| 2464 | `heat_engine_cycles` | `calorimetry` [1800-2400], `separate_condenser_engine` [production, 1800-2400] |  | `high_pressure_steam_engines` [production], `precision_thermometry` [1800-2400], `air_spring_law` [1800-2400] |  |
| 2469 | `mechanical_work_energy` | `momentum_balance` [1800-2400], `friction_measurement` [1800-2400] |  | `tested_waterwheel_efficiency` [production, 1800-2400], `heat_engine_cycles`, `rotational_dynamics` [1800-2400] |  |
| 2480 | `compound_microscopy` | `two_lens_tube_microscope` [1800-2400], `eyepiece_design` [1800-2400], `lead_crystal_glass` [production, 1800-2400] |  | `lens_centering` [1800-2400], `experimental_optics` [1800-2400], `animalcule_microscope` [1800-2400] |  |
| 2480 | `fine_focus_stages` | `compound_microscopy` |  | `screw_cutting_lathe` [production, 1800-2400], `precision_machinery` [infrastructure, 1800-2400] |  |
| 2480 | `illumination_apertures` | `compound_microscopy` |  | `experimental_optics` [1800-2400] |  |
| 2480 | `microbial_observation` | `compound_microscopy`, `animalcule_microscope` [1800-2400] |  | `microscope_drawing_atlas` [1800-2400], `specimen_slide_mounting` |  |
| 2480 | `microscopic_cell_observation` | `compound_microscopy` |  | `capillary_observation` [health, 1800-2400], `specimen_slide_mounting`, `microscope_drawing_atlas` [1800-2400] |  |
| 2480 | `specimen_slide_mounting` | `compound_microscopy` |  | `cast_plate_glass` [production, 1800-2400], `microscope_drawing_atlas` [1800-2400] |  |
| 2483 | `electromagnetic_induction` | `electrochemical_cells`, `electrical_measurement` |  | `earth_magnet_treatise` [1800-2400], `torsion_balance_force_law` [1800-2400] |  |
| 2493 | `electromagnet_sounders` | `electrochemical_cells`, `electrical_measurement` |  | `electromagnetic_induction`, `earth_magnet_treatise` [1800-2400] |  |
| 2499 | `timed_signal_sequences` | `electromagnet_sounders` |  | `optical_telegraphy`, `numbered_signal_flags` [security, 1800-2400] |  |
| 2504 | `cell_theory` | `microscopic_cell_observation`, `compound_microscopy` |  | `biological_classification` [ecology, 1800-2400], `comparative_anatomy` [ecology, 1800-2400], `developmental_stage_series` [ecology] |  |
| 2504 | `electrical_telegraphy` | `electromagnet_sounders`, `timed_signal_sequences` |  | `optical_telegraphy`, `public_steam_railway` [logistics], `intercity_passenger_railway` [logistics], `electromagnetic_relays` [production] |  |
| 2504 | `fixed_light_images` | `darkened_room_optics` [1200-1800], `fused_silver_plate` [production, 1800-2400] |  | `systematic_chemical_names` [1800-2400], `experimental_optics` [1800-2400], `stone_lithography` [1800-2400] |  |
| 2504 | `tissue_histology` | `microscopic_cell_observation`, `specimen_slide_mounting` |  | `cell_theory`, `organ_seat_pathology` [health, 1800-2400] |  |
| 2517 | `telegraph_keys` | `electrical_telegraphy` |  | `timed_signal_sequences` |  |
| 2523 | `line_insulators` | `electrical_telegraphy` |  | `bone_ash_porcelain` [production, 1800-2400], `plunger_pressed_glass` [production] |  |
| 2525 | `energy_conservation_law` | `mechanical_work_energy`, `heat_engine_cycles` |  | `calorimetry` [1800-2400], `electromagnetic_induction`, `electrochemical_cells` |  |
| 2528 | `telegraph_return_circuits` | `electrical_telegraphy` |  | `line_insulators`, `electrical_measurement` |  |
| 2533 | `entropy_second_law` | `heat_engine_cycles`, `energy_conservation_law` |  | `calorimetry` [1800-2400] |  |
| 2533 | `polarized_telegraph_relays` | `electrical_telegraphy`, `electromagnetic_relays` [production] |  | `telegraph_return_circuits` |  |
| 2555 | `biological_staining` | `tissue_histology`, `coal_tar_dyes` [production] |  | `specimen_slide_mounting` |  |
| 2555 | `matrix_algebra` | `symbolic_algebra` [1800-2400] |  | `coordinate_geometry` [1800-2400], `least_squares_estimation` |  |
| 2557 | `descent_by_selection` | `biological_classification` [ecology, 1800-2400], `deep_time_geology` [ecology, 1800-2400] |  | `comparative_anatomy` [ecology, 1800-2400], `extinction_recognized` [ecology, 1800-2400], `population_pressure_treatise` [demography, 1800-2400], `developmental_stage_series` [ecology], `pedigree_stock_breeding` [nutrition, 1800-2400] |  |
| 2557 | `spectroscopy` | `experimental_optics` [1800-2400], `atomic_combining_weights` |  | `eyepiece_design` [1800-2400], `water_sphere_rainbow_test` [1200-1800], `gas_lit_streets` [infrastructure] |  |
| 2560 | `cyclic_fatigue` | `stress_strain_relations` [1800-2400], `structural_load_testing` [1800-2400] |  | `public_steam_railway` [logistics], `chain_suspension_bridges` [infrastructure] |  |
| 2571 | `electromagnetic_wave_theory` | `electromagnetic_induction`, `differential_equations` [1800-2400] |  | `light_speed_from_eclipses` [1800-2400], `harmonic_analysis`, `energy_conservation_law` |  |
| 2576 | `undersea_telegraph_cable` | `electrical_telegraphy`, `cable_insulation` [production] |  | `iron_hulled_steamers` [logistics], `telegraph_return_circuits` | environment=coast |
| 2584 | `periodic_element_table` | `atomic_combining_weights`, `spectroscopy` |  | `systematic_chemical_names` [1800-2400], `research_university` |  |
| 2587 | `cell_division_observation` | `cell_theory`, `biological_staining` |  | `compound_microscopy` |  |
| 2587 | `compulsory_elementary_schooling` | `compulsory_parish_schooling` [1800-2400], `public_instruction_ministry` [institutions] |  | `half_time_schooling` [labor], `national_tongue_revival` [culture], `manhood_suffrage` [institutions] |  |
| 2587 | `punched_message_tape` | `electrical_telegraphy`, `punched_card_loom_control` [production] |  | `timed_signal_sequences` |  |
| 2595 | `photoconductivity` | `electrical_measurement` |  | `undersea_telegraph_cable`, `fixed_light_images` |  |
| 2597 | `duplex_telegraphy` | `electrical_telegraphy`, `polarized_telegraph_relays` |  | `telegraph_return_circuits` |  |
| 2603 | `acoustic_diaphragms` | `electromagnetic_induction` |  | `harmonic_analysis` |  |
| 2603 | `electromagnetic_earpieces` | `electromagnetic_induction`, `acoustic_diaphragms` |  | `electromagnet_sounders` |  |
| 2603 | `industrial_research_laboratory` | `research_university`, `examined_patent_office` [institutions] |  | `coal_tar_dyes` [production], `electrical_generators` [production] |  |
| 2603 | `instrument_sterilization` | `microbial_observation` |  | `antiseptic_surgery` [health], `food_retorts` [nutrition], `gentle_heat_treatment` [nutrition] |  |
| 2603 | `microbial_isolation_methods` | `microbial_observation`, `biological_staining` |  | `gentle_heat_treatment` [nutrition], `fermentation_starter_cultures` [nutrition], `cell_theory` |  |
| 2605 | `telephone_circuits` | `electromagnetic_earpieces`, `acoustic_diaphragms`, `electrical_telegraphy` |  | `harmonic_analysis` |  |
| 2608 | `carbon_microphones` | `telephone_circuits` |  | `acoustic_diaphragms` |  |
| 2608 | `manual_switchboards` | `telephone_circuits` |  | `electromagnetic_relays` [production] |  |
| 2613 | `aseptic_laboratory_practice` | `microbial_isolation_methods`, `instrument_sterilization` |  | `antiseptic_surgery` [health] |  |
| 2613 | `vector_analysis` | `matrix_algebra` |  | `electromagnetic_wave_theory`, `coordinate_geometry` [1800-2400] |  |
| 2616 | `balanced_conductor_pairs` | `telephone_circuits` |  | `telegraph_return_circuits` |  |
| 2621 | `lubrication_regimes` | `viscous_resistance` |  | `friction_measurement` [1800-2400], `fuel_refining` [production] |  |
| 2640 | `punched_card_tabulation` | `punched_card_loom_control` [production], `electromagnetic_relays` [production] |  | `nominal_realm_census` [demography, 1800-2400], `household_schedule_census` [demography], `punched_message_tape` |  |
| 2659 | `electron_physics` | `electromagnetic_wave_theory`, `glass_tube_drawing` [production] |  | `vacuum_pumps` [1800-2400], `spectroscopy`, `filament_lamp_works` [production] |  |
| 2659 | `radiation_measurement` | `electron_physics`, `electrical_measurement` |  | `photoconductivity`, `fixed_light_images`, `bone_shadow_imaging` [health] |  |
| 2659 | `thermionic_emission` | `filament_lamp_works` [production], `electron_physics` |  | `vacuum_pumps` [1800-2400] |  |
| 2664 | `inductive_line_loading` | `telephone_circuits`, `electromagnetic_wave_theory` |  | `balanced_conductor_pairs` |  |
| 2664 | `radio_telegraphy` | `electromagnetic_wave_theory`, `electrical_telegraphy` |  | `electrical_generators` [production], `undersea_telegraph_cable` |  |
| 2667 | `aerodynamics` | `viscous_resistance`, `flow_continuity` [1800-2400] |  | `aerostat_observation` [security, 1800-2400] |  |
| 2667 | `energy_quanta` | `entropy_second_law`, `electromagnetic_wave_theory` |  | `spectroscopy`, `filament_lamp_works` [production] |  |
| 2667 | `microbial_growth_measurement` | `microbial_isolation_methods` |  | `aseptic_laboratory_practice` |  |
| 2667 | `refereed_journals` | `experimental_protocol_publication` [1800-2400], `research_university` |  | `chartered_experimental_society` [1800-2400] |  |
| 2667 | `resonant_tuned_circuits` | `electromagnetic_wave_theory` |  | `charge_storing_jar` [1800-2400], `radio_telegraphy`, `harmonic_analysis` |  |
| 2667 | `statistical_sampling` | `statistical_inference` |  | `household_poverty_surveys` [demography], `measurement_uncertainty` |  |
| 2667 | `variable_air_capacitors` | `resonant_tuned_circuits` |  | `charge_storing_jar` [1800-2400] |  |
| 2667 | `wind_tunnel_testing` | `aerodynamics` |  | `dimensional_analysis` |  |
| 2677 | `crystal_radio_detection` | `radio_telegraphy`, `resonant_tuned_circuits` |  | `photoconductivity`, `electromagnetic_earpieces` |  |
| 2677 | `vacuum_diodes` | `thermionic_emission` |  | `filament_lamp_works` [production], `radio_telegraphy` |  |
| 2680 | `relative_spacetime` | `electromagnetic_wave_theory`, `vector_analysis` |  | `light_speed_from_eclipses` [1800-2400], `energy_quanta` |  |
| 2683 | `automatic_telegraphy` | `punched_message_tape`, `duplex_telegraphy` |  | `timed_signal_sequences` |  |
| 2683 | `teleprinter_mechanisms` | `punched_message_tape`, `telegraph_keys` |  | `automatic_telegraphy` |  |
| 2683 | `triode_valves` | `vacuum_diodes` |  | `resonant_tuned_circuits` |  |
| 2685 | `cell_culture_methods` | `aseptic_laboratory_practice`, `cell_theory` |  | `microbial_growth_measurement` |  |
| 2688 | `tuned_radio_reception` | `radio_telegraphy`, `resonant_tuned_circuits`, `variable_air_capacitors` |  | `crystal_radio_detection` |  |
| 2696 | `atomic_physics` | `electron_physics`, `radiation_measurement` |  | `periodic_element_table`, `energy_quanta` |  |
| 2699 | `amplitude_modulation` | `triode_valves`, `telephone_circuits` |  | `radio_telegraphy`, `carbon_microphones` |  |
| 2699 | `crystallography` | `radiation_measurement` |  | `bone_shadow_imaging` [health], `mineral_cleavage` [ecology, 1800-2400], `atomic_physics` |  |
| 2699 | `feedback_radio_oscillators` | `triode_valves`, `resonant_tuned_circuits` |  | `feedback_governors` [1800-2400] |  |
| 2707 | `telephone_repeaters` | `triode_valves`, `telephone_circuits` |  | `inductive_line_loading`, `balanced_conductor_pairs` |  |
| 2715 | `frequency_conversion` | `triode_valves`, `feedback_radio_oscillators` |  | `tuned_radio_reception` |  |
| 2720 | `aerial_matching` | `radio_telegraphy`, `resonant_tuned_circuits` |  | `feedback_radio_oscillators` |  |
| 2720 | `superheterodyne_reception` | `frequency_conversion`, `tuned_radio_reception` |  | `amplitude_modulation` |  |
| 2723 | `frequency_stabilization` | `feedback_radio_oscillators`, `crystallography` |  | `tuned_radio_reception` |  |
| 2733 | `quantum_mechanics` | `atomic_physics`, `energy_quanta` |  | `relative_spacetime`, `matrix_algebra`, `spectroscopy` |  |
| 2741 | `signal_sampling` | `harmonic_analysis`, `amplitude_modulation` |  | `telephone_repeaters`, `teleprinter_mechanisms` |  |
| 2747 | `band_theory` | `quantum_mechanics`, `crystallography` |  | `photoconductivity` |  |
| 2747 | `solid_state_physics` | `quantum_mechanics`, `crystallography` |  | `band_theory`, `crystal_radio_detection` |  |
| 2755 | `frequency_modulation` | `feedback_radio_oscillators`, `superheterodyne_reception` |  | `frequency_stabilization` |  |
| 2763 | `computability_theory` | `syllogistic_logic` [600-1200], `symbolic_algebra` [1800-2400] |  | `geared_adding_machine` [1800-2400], `punched_card_tabulation`, `relay_logic` [production] |  |
| 2768 | `neutron_moderation` | `nuclear_fission` |  | `water_electrolysis` [production], `cryogenic_air_separation` [production] |  |
| 2768 | `nuclear_fission` | `atomic_physics`, `quantum_mechanics`, `radiation_measurement` |  | `periodic_element_table` |  |
| 2773 | `constrained_optimization` | `matrix_algebra` |  | `national_income_accounts` [institutions], `central_five_year_plan` [institutions], `statistical_sampling` |  |
| 2779 | `state_great_laboratories` | `industrial_research_laboratory`, `research_university` |  | `nuclear_fission`, `war_economy_boards` [institutions] |  |
| 2784 | `universal_secondary_schooling` | `compulsory_elementary_schooling` |  | `child_labor_prohibition` [labor], `examined_trade_apprenticeships` [labor] |  |
| 2795 | `information_theory` | `signal_sampling`, `probability_theory` [1800-2400] |  | `entropy_second_law`, `computability_theory`, `telephone_repeaters` |  |
| 2800 | `live_cell_time_lapse` | `cell_culture_methods`, `moving_pictures` [culture] |  | `cell_division_observation` |  |
| 2802 | `pn_junctions` | `semiconductor_doping` |  | `band_theory`, `crystal_radio_detection` |  |
| 2802 | `semiconductor_doping` | `band_theory`, `single_crystal_growth` [production] |  | `crystal_radio_detection`, `chlorosilane_purification` [production] |  |
| 2808 | `hereditary_double_helix` | `crystallography`, `heredity_experiments` [nutrition] |  | `cell_division_observation`, `quantum_mechanics` |  |
| 2810 | `photovoltaic_conversion` | `pn_junctions` |  | `photoconductivity` |  |
| 2812 | `microinstruction_sequencing` | `computability_theory`, `binary_adders` [production] |  | `relay_registers` [production], `punched_card_tabulation` |  |
| 2812 | `pulse_code_modulation` | `signal_sampling`, `information_theory` |  | `automatic_telegraphy` |  |
| 2818 | `formula_programming_languages` | `computability_theory`, `read_write_memory` [production] |  | `microinstruction_sequencing` |  |
| 2825 | `arithmetic_logic_units` | `binary_adders` [production], `microinstruction_sequencing` |  | `bipolar_junction_transistors` [production] |  |
| 2825 | `automatic_repeat_request` | `error_detection_codes`, `message_framing` |  | `automatic_telegraphy` |  |
| 2825 | `data_modems` | `telephone_repeaters`, `signal_sampling` |  | `error_detection_codes`, `pulse_code_modulation`, `transistor_amplifiers` [production] |  |
| 2825 | `diode_control_stores` | `microinstruction_sequencing`, `diode_logic` [production] |  | `silicon_rectifiers` [production] |  |
| 2825 | `error_detection_codes` | `information_theory` |  | `punched_message_tape` |  |
| 2825 | `message_framing` | `error_detection_codes` |  | `teleprinter_mechanisms` |  |
| 2830 | `relay_satellites` | `orbital_satellite_launch` [logistics], `transistor_amplifiers` [production] |  | `frequency_modulation`, `television_broadcasting` [culture], `photovoltaic_conversion` |  |
| 2832 | `mass_higher_education` | `universal_secondary_schooling`, `research_university` |  | `state_great_laboratories` |  |
| 2838 | `microprogrammed_machine_control` | `microinstruction_sequencing`, `diode_control_stores` |  | `stored_program_control` [production] |  |
| 2848 | `packet_routers` | `packet_switching` |  | `stored_program_control` [production] |  |
| 2848 | `packet_switching` | `message_framing`, `automatic_repeat_request`, `data_modems` |  | `information_theory`, `store_forward_archives` |  |
| 2848 | `store_forward_archives` | `message_framing` |  | `automatic_telegraphy`, `read_write_memory` [production] |  |
| 2850 | `relational_databases` | `formula_programming_languages`, `read_write_memory` [production] |  | `punched_card_tabulation`, `syllogistic_logic` [600-1200] |  |
| 2865 | `public_key_ciphers` | `information_theory`, `number_theory_treatise` [600-1200] |  | `machine_cryptanalysis` [security], `rotor_cipher_machines` [security], `letter_frequency_codebreaking` [1200-1800] |  |
| 2868 | `desk_computers` | `single_chip_processors` [production], `formula_programming_languages` |  | `relational_databases`, `microprogrammed_machine_control` |  |
| 2882 | `cellular_telephony` | `frequency_modulation`, `single_chip_processors` [production] |  | `manual_switchboards`, `radio_patrol_emergency_line` [security], `stored_program_control` [production] |  |
| 2882 | `internetworking_protocols` | `packet_switching`, `packet_routers` |  | `desk_computers` |  |
| 2902 | `world_hypertext_web` | `internetworking_protocols`, `desk_computers` |  | `relational_databases`, `refereed_journals` |  |
| 2912 | `exoplanet_detection` | `spectroscopy`, `universal_gravitation` [1800-2400] |  | `desk_computers` |  |
| 2920 | `ranked_search_indexes` | `world_hypertext_web`, `relational_databases` |  | `matrix_algebra` |  |
| 2928 | `volunteer_open_encyclopedia` | `world_hypertext_web` |  | `reasoned_trades_encyclopedia` [1800-2400] |  |
| 2940 | `cloud_data_halls` | `internetworking_protocols`, `world_hypertext_web` |  | `relational_databases`, `deep_submicron_lithography` [production] |  |
| 2942 | `pocket_networked_computers` | `cellular_telephony`, `internetworking_protocols`, `lithium_ion_cells` [production], `flat_panel_displays` [production] |  | `open_satellite_positioning` [logistics] |  |
| 2955 | `deep_learning_networks` | `cloud_data_halls`, `constrained_optimization` |  | `machine_vision_inspection` [production], `ranked_search_indexes`, `statistical_inference` |  |
| 2962 | `gravitational_wave_detection` | `relative_spacetime` |  | `signal_sampling`, `cloud_data_halls` |  |
| 2975 | `large_language_models` | `deep_learning_networks`, `cloud_data_halls` |  | `volunteer_open_encyclopedia`, `information_theory` |  |
| 2988 | `error_corrected_quantum_processors` | `quantum_mechanics`, `error_detection_codes`, `deep_submicron_lithography` [production] |  | `cryogenic_air_separation` [production], `public_key_ciphers` |  |
| 2998 | `automated_discovery_labs` | `large_language_models` |  | `collaborative_robots` [production], `digital_twin_plants` [production], `state_great_laboratories` |  |

## Cross-line prerequisites assumed from other 2400–3000 lines

Hard parents owned by lines outside knowledge, institutions, culture and labor, mapped in parallel by other agents:

- `punched_card_loom_control` (production 2408) → `punched_card_tabulation`
- `punched_card_loom_control` (production 2408) → `punched_message_tape`
- `electromagnetic_relays` (production 2494) → `polarized_telegraph_relays`
- `electromagnetic_relays` (production 2494) → `punched_card_tabulation`
- `cable_insulation` (production 2525) → `undersea_telegraph_cable`
- `coal_tar_dyes` (production 2554) → `biological_staining`
- `glass_tube_drawing` (production 2610) → `electron_physics`
- `filament_lamp_works` (production 2612) → `thermionic_emission`
- `heredity_experiments` (nutrition 2680) → `hereditary_double_helix`
- `binary_adders` (production 2765) → `arithmetic_logic_units`
- `binary_adders` (production 2765) → `microinstruction_sequencing`
- `single_crystal_growth` (production 2786) → `semiconductor_doping`
- `read_write_memory` (production 2806) → `formula_programming_languages`
- `read_write_memory` (production 2806) → `relational_databases`
- `transistor_amplifiers` (production 2807) → `relay_satellites`
- `orbital_satellite_launch` (logistics 2817) → `relay_satellites`
- `diode_logic` (production 2824) → `diode_control_stores`
- `single_chip_processors` (production 2853) → `cellular_telephony`
- `single_chip_processors` (production 2853) → `desk_computers`
- `lithium_ion_cells` (production 2902) → `pocket_networked_computers`
- `flat_panel_displays` (production 2910) → `pocket_networked_computers`
- `deep_submicron_lithography` (production 2915) → `error_corrected_quantum_processors`

## Prerequisites from the other kicl lines

- `public_instruction_ministry` (institutions 2480) → `compulsory_elementary_schooling`
- `examined_patent_office` (institutions 2496) → `industrial_research_laboratory`
- `moving_pictures` (culture 2653) → `live_cell_time_lapse`

## Year adjustments

None.

## Weapons of mass destruction

`nuclear_fission` and `neutron_moderation` are research only. They are parents of Production reactors and Security fission weapons. No Knowledge item grants weapon use. The effects pass must make any use of fission, gas, germ or thermonuclear weapons, or intercontinental missiles, the ruler's spoken decision, never a general's own authority.
