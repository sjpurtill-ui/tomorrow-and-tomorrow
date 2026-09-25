# Knowledge dependencies: years 1800–2400

Machine-readable source: `partials/kicl.json` (knowledge, institutions, culture, labor). Contract: the 600–1200 and 1200–1800 mappings (`docs/research/y600/deps/partials/kicl.json`, `docs/research/y1200/deps/partials/kicl.json`, merged by `tools/research/merge_graph_1200.py` and `merge_graph_1800.py`). Ids come from `registry_2400.json`, the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), the 600–1200 graph, the 0–600 graph and the game's baked blocks. Prerequisites may be ids of any earlier block in any line, or 1800–2400 ids, and every prerequisite and precedent is dated at or before its dependent (registry target years; earlier blocks at their baked years). Brackets mark a parent from another line or an earlier block: `[production]` is a 1800–2400 id owned by Production, `[ecology, 1200-1800]` is a 1200–1800 Ecology id, `[0-600]` is a same-line 0–600 id. `contact_required` marks items that need ocean contact, directly or through a contact-gated hard parent. No year moves are proposed for this line.

**110 entries, 196 hard edges, 238 precedent edges, 0 requires_any groups.**

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1803 | `fractional_ratio_powers` | `polynomial_term_algebra` [1200-1800] |  | `written_decimal_fractions` [1200-1800], `restoration_balancing_algebra` [1200-1800], `mean_speed_rule` [1200-1800] |  |
| 1814 | `turning_earth_argument` | `sky_model_doubts` [1200-1800] |  | `impetus_theory` [1200-1800], `mean_speed_rule` [1200-1800] |  |
| 1821 | `ruler_founded_universities` | `chartered_university` [1200-1800] |  | `teaching_licence_degree` [1200-1800], `endowed_student_colleges` [1200-1800], `royal_house_of_learning` [1200-1800] |  |
| 1842 | `graticule_world_maps` | `coordinate_gazetteer_maps` [600-1200], `scaled_grid_mapping` [600-1200] |  | `rival_tongue_translation_school` [1200-1800], `world_maps` [600-1200], `sacred_world_maps` [culture, 1200-1800] |  |
| 1846 | `mirror_grid_perspective` | `school_perspective_optics` [1200-1800] |  | `naturalistic_fresco_cycles` [culture, 1200-1800], `geometric_optics_treatise` [600-1200], `lead_backed_glass_mirrors` [production, 600-1200] |  |
| 1852 | `old_tongue_grammar_schools` | `great_house_schools` [1200-1800], `court_learning_revival` [culture, 1200-1800] |  | `old_text_recovery` [culture, 1200-1800], `reckoning_schools` [1200-1800], `civic_humanism` [culture] |  |
| 1858 | `burin_engraving` | `niello_inlay` [production, 1200-1800], `die_struck_coinage` [production, 600-1200] |  | `goldsmith_filigree` [production, 0-600], `relief_block_cutting` [1200-1800] |  |
| 1860 | `copperplate_preparation` | `burin_engraving`, `raised_bronze_vessels` [production, 0-600] |  | `brass_battery_works` [production] |  |
| 1864 | `remeasured_star_catalogue` | `fixed_instrument_observatory` [1200-1800] |  | `illustrated_star_atlas` [1200-1800], `observed_table_revision` [1200-1800] |  |
| 1867 | `philological_forgery_critique` | `old_text_recovery` [culture, 1200-1800], `hard_word_glossaries` [1200-1800] |  | `civic_humanism` [culture], `collated_critical_editions` [600-1200] |  |
| 1867 | `screw_press_printing` | `printing_process` [1200-1800], `mechanical_screw_presses` [production, 600-1200] |  | `paper_stamping_mills` [production, 1200-1800], `block_printed_books` [1200-1800] |  |
| 1868 | `oil_based_printing_inks` | `printing_process` [1200-1800], `oil_varnish_paints` [production, 1200-1800] |  | `lampblack_capture` [production, 0-600], `oil_glaze_painting` [culture] |  |
| 1871 | `hand_relief_printing` | `screw_press_printing`, `oil_based_printing_inks` |  | `movable_type_composition` [1200-1800] |  |
| 1875 | `metal_type_casting` | `movable_type_composition` [1200-1800], `die_struck_coinage` [production, 600-1200] |  | `pewter_alloy_standards` [production], `wooden_movable_type` [1200-1800] |  |
| 1879 | `printed_scripture_folio` | `metal_type_casting`, `hand_relief_printing` |  | `block_printed_books` [1200-1800], `canonized_sacred_sayings` [culture, 600-1200], `paper_stamping_mills` [production, 1200-1800] |  |
| 1890 | `printed_broadsides` | `hand_relief_printing`, `metal_type_casting` |  | `printed_almanacs` [1200-1800], `printed_scripture_folio` |  |
| 1892 | `town_printing_houses` | `metal_type_casting`, `screw_press_printing`, `paper_stamping_mills` [production, 1200-1800] |  | `printed_scripture_folio`, `printed_broadsides` |  |
| 1895 | `printed_ephemerides` | `observed_table_revision` [1200-1800], `town_printing_houses` |  | `printed_almanacs` [1200-1800], `remeasured_star_catalogue` |  |
| 1898 | `printed_engraved_maps` | `burin_engraving`, `copperplate_preparation` |  | `graticule_world_maps`, `town_printing_houses` |  |
| 1912 | `printed_arithmetic_summa` | `double_entry_ledgers` [institutions, 1200-1800], `town_printing_houses` |  | `merchant_digit_reckoning` [1200-1800], `reckoning_schools` [1200-1800], `digit_reckoning_handbook` [1200-1800] |  |
| 1917 | `drypoint_printmaking` | `burin_engraving`, `copperplate_preparation` |  | `printed_engraved_maps` |  |
| 1942 | `instrument_maker_workshops` | `universal_astrolabe_plate` [1200-1800], `burin_engraving` |  | `cementation_brass` [production, 600-1200], `brass_battery_works` [production], `mariners_quadrant` [logistics] |  |
| 1942 | `printed_alphabet_primers` | `town_printing_houses`, `letter_schools_for_citizens` [600-1200] |  | `guild_letter_schools` [labor, 1200-1800], `printed_broadsides` |  |
| 1944 | `triangulation_survey` | `horary_quadrant` [1200-1800], `half_chord_sine_tables` [1200-1800] |  | `dioptra_survey` [600-1200], `graticule_world_maps`, `instrument_maker_workshops` |  |
| 1952 | `sun_centred_system` | `turning_earth_argument`, `remeasured_star_catalogue` |  | `observed_table_revision` [1200-1800], `printed_ephemerides` |  |
| 1954 | `polynomial_equations` | `geometric_cubic_solutions` [1200-1800], `polynomial_term_algebra` [1200-1800] |  | `printed_arithmetic_summa`, `stepwise_high_root_extraction` [1200-1800] |  |
| 1964 | `arithmetic_operation_signs` | `printed_arithmetic_summa` |  | `syncopated_algebra` [600-1200], `polynomial_equations` |  |
| 1967 | `merchant_newsletters` | `letter_writing_art` [1200-1800], `bills_of_exchange` [logistics, 1200-1800] |  | `public_letter_post` [logistics], `branch_banking_houses` [institutions, 1200-1800], `scholarly_question_letters` [1200-1800] |  |
| 1971 | `graphite_marking` | `commonplace_books` [1200-1800] |  | `paper_working_copies` [1200-1800] |  |
| 1977 | `complex_numbers` | `polynomial_equations` |  | `zero_negative_rules` [1200-1800], `arithmetic_operation_signs` |  |
| 1978 | `new_star_parallax_test` | `guest_star_records` [1200-1800], `remeasured_star_catalogue` |  | `turning_earth_argument`, `sky_model_doubts` [1200-1800] |  |
| 1980 | `precision_naked_eye_observatory` | `remeasured_star_catalogue`, `instrument_maker_workshops` |  | `new_star_parallax_test`, `fixed_instrument_observatory` [1200-1800] |  |
| 1985 | `reformed_solar_calendar` | `moving_feast_reckoning` [1200-1800], `printed_ephemerides` |  | `leap_year_solar_calendar` [600-1200], `sun_centred_system` |  |
| 1992 | `symbolic_algebra` | `polynomial_term_algebra` [1200-1800], `arithmetic_operation_signs` |  | `polynomial_equations`, `complex_numbers` |  |
| 1993 | `two_lens_tube_microscope` | `optical_lenses` [1200-1800] |  | `reading_spectacles` [health, 1200-1800], `concave_spectacles` [health], `instrument_maker_workshops` |  |
| 1999 | `graded_class_colleges` | `endowed_student_colleges` [1200-1800], `old_tongue_grammar_schools` |  | `printed_alphabet_primers`, `ruler_founded_universities` |  |
| 2000 | `rolling_intaglio_printing` | `copperplate_preparation`, `burin_engraving` |  | `screw_press_printing`, `drypoint_printmaking`, `rolled_metal_strip` [production] |  |
| 2002 | `earth_magnet_treatise` | `lodestone_pole_experiments` [1200-1800], `magnetic_declination_note` [1200-1800] |  | `experimental_science_program` [1200-1800], `gimballed_compass` [logistics], `town_printing_houses` |  |
| 2008 | `measured_kinematics` | `mean_speed_rule` [1200-1800], `impetus_theory` [1200-1800] |  | `experimental_science_program` [1200-1800], `science_of_weights` [1200-1800] |  |
| 2010 | `printed_weekly_news` | `merchant_newsletters`, `town_printing_houses` |  | `printed_broadsides`, `public_letter_post` [logistics] |  |
| 2016 | `two_lens_telescope` | `optical_lenses` [1200-1800], `concave_spectacles` [health] |  | `reading_spectacles` [health, 1200-1800], `two_lens_tube_microscope`, `instrument_maker_workshops` |  |
| 2018 | `elliptical_planet_orbits` | `sun_centred_system`, `precision_naked_eye_observatory` |  | `earth_magnet_treatise`, `observed_table_revision` [1200-1800] |  |
| 2020 | `telescopic_sky_discoveries` | `two_lens_telescope` |  | `sun_centred_system`, `printed_ephemerides` |  |
| 2022 | `lens_centering` | `optical_lenses` [1200-1800], `two_lens_telescope` |  | `lathe_ground_cast_glass` [production, 600-1200], `instrument_maker_workshops` |  |
| 2028 | `logarithms` | `written_decimal_fractions` [1200-1800], `half_chord_sine_tables` [1200-1800] |  | `printed_arithmetic_summa`, `symbolic_algebra`, `printed_ephemerides` |  |
| 2034 | `decimal_log_tables` | `logarithms`, `town_printing_houses` |  | `written_decimal_fractions` [1200-1800] |  |
| 2038 | `compulsory_parish_schooling` | `printed_alphabet_primers` |  | `vernacular_scripture` [culture], `graded_class_colleges`, `reckoning_schools` [1200-1800] |  |
| 2040 | `inductive_method_program` | `experimental_science_program` [1200-1800] |  | `observation_notebooks` [1200-1800], `earth_magnet_treatise`, `commonplace_books` [1200-1800] |  |
| 2044 | `logarithmic_slide_rule` | `logarithms`, `navigators_log_scale` [logistics] |  | `instrument_maker_workshops`, `decimal_log_tables` |  |
| 2074 | `coordinate_geometry` | `symbolic_algebra` |  | `quality_graphs` [1200-1800], `geometric_cubic_solutions` [1200-1800], `axiomatic_geometry_compendium` [600-1200] |  |
| 2080 | `systematic_doubt_method` | `scholastic_question_method` [1200-1800] |  | `personal_essays` [culture], `inductive_method_program`, `coordinate_geometry` |  |
| 2084 | `geared_adding_machine` | `mainspring_fusee_clocks` [production], `digit_column_counting_board` [1200-1800] |  | `logarithms`, `verge_escapement_clock` [1200-1800] |  |
| 2084 | `mezzotint_printmaking` | `rolling_intaglio_printing`, `copperplate_preparation` |  | `drypoint_printmaking`, `chiaroscuro_painting` [culture] |  |
| 2086 | `mercury_barometer` | `hydrostatic_pressure` [600-1200], `glass_blowing` [production, 600-1200] |  | `street_suction_pumps` [infrastructure], `mercury_tin_mirrors` [production], `measured_kinematics` |  |
| 2100 | `vacuum_pumps` | `mercury_barometer`, `piston_force_pumps` [infrastructure, 600-1200] |  | `street_suction_pumps` [infrastructure], `inductive_method_program` |  |
| 2108 | `probability_theory` | `symbolic_algebra`, `binomial_coefficient_triangle` [1200-1800] |  | `printed_playing_cards` [culture, 1200-1800], `arithmetic_operation_signs` |  |
| 2108 | `vacuum_experiments` | `vacuum_pumps`, `mercury_barometer` |  | `inductive_method_program` |  |
| 2112 | `pendulum_regulated_clock` | `verge_escapement_clock` [1200-1800], `measured_kinematics` |  | `mainspring_fusee_clocks` [production], `instrument_maker_workshops` |  |
| 2120 | `chartered_experimental_society` | `inductive_method_program` |  | `scholarly_question_letters` [1200-1800], `vacuum_experiments`, `royal_house_of_learning` [1200-1800] |  |
| 2120 | `mechanical_oscillation` | `measured_kinematics`, `pendulum_regulated_clock` |  | `string_ratio_harmonics` [600-1200] |  |
| 2124 | `air_spring_law` | `vacuum_pumps`, `vacuum_experiments` |  | `mercury_barometer`, `chartered_experimental_society` |  |
| 2126 | `laboratory_notebooks` | `observation_notebooks` [1200-1800], `inductive_method_program` |  | `chartered_experimental_society`, `graphite_marking`, `commonplace_books` [1200-1800] |  |
| 2130 | `experimental_protocol_publication` | `chartered_experimental_society`, `town_printing_houses` |  | `laboratory_notebooks`, `printed_weekly_news` |  |
| 2130 | `microscope_drawing_atlas` | `two_lens_tube_microscope`, `rolling_intaglio_printing` |  | `lens_centering`, `chartered_experimental_society` |  |
| 2132 | `salaried_science_academy` | `chartered_experimental_society` |  | `royal_house_of_learning` [1200-1800], `tongue_purity_academy` [culture] |  |
| 2138 | `numerical_root_finding` | `symbolic_algebra`, `polynomial_equations` |  | `stepwise_high_root_extraction` [1200-1800], `decimal_log_tables` |  |
| 2140 | `differential_calculus` | `coordinate_geometry`, `measured_kinematics` |  | `symbolic_algebra`, `quality_graphs` [1200-1800], `mean_speed_rule` [1200-1800] |  |
| 2140 | `experimental_optics` | `water_sphere_rainbow_test` [1200-1800], `clear_crystal_glass` [production] |  | `lens_centering`, `chartered_experimental_society`, `experimental_protocol_publication` |  |
| 2144 | `mirror_telescope` | `two_lens_telescope`, `experimental_optics` |  | `lead_backed_glass_mirrors` [production, 600-1200], `lens_centering` |  |
| 2150 | `integral_calculus` | `differential_calculus` |  | `numerical_root_finding`, `coordinate_geometry` |  |
| 2150 | `realm_longitude_observatory` | `pendulum_regulated_clock`, `telescopic_sky_discoveries` |  | `salaried_science_academy`, `precision_naked_eye_observatory`, `latitude_sailing` [logistics] |  |
| 2152 | `elastic_deformation` | `mainspring_fusee_clocks` [production], `experimental_protocol_publication` |  | `air_spring_law` |  |
| 2152 | `light_speed_from_eclipses` | `telescopic_sky_discoveries`, `pendulum_regulated_clock`, `realm_longitude_observatory` |  | `printed_ephemerides` |  |
| 2154 | `animalcule_microscope` | `lens_centering` |  | `microscope_drawing_atlas`, `experimental_protocol_publication`, `glass_blowing` [production, 600-1200] |  |
| 2156 | `eyepiece_design` | `two_lens_telescope`, `lens_centering` |  | `experimental_optics` |  |
| 2160 | `stress_strain_relations` | `elastic_deformation` |  | `science_of_weights` [1200-1800], `differential_calculus` |  |
| 2172 | `inertial_motion` | `measured_kinematics`, `impetus_theory` [1200-1800] |  | `systematic_doubt_method`, `differential_calculus` |  |
| 2174 | `universal_gravitation` | `elliptical_planet_orbits`, `inertial_motion`, `differential_calculus` |  | `pendulum_regulated_clock`, `telescopic_sky_discoveries`, `integral_calculus` |  |
| 2176 | `momentum_balance` | `inertial_motion` |  | `chartered_experimental_society`, `universal_gravitation` |  |
| 2180 | `differential_equations` | `differential_calculus`, `integral_calculus` |  | `universal_gravitation` |  |
| 2198 | `friction_measurement` | `inertial_motion`, `science_of_weights` [1200-1800] |  | `salaried_science_academy` |  |
| 2204 | `daily_printed_newspaper` | `printed_weekly_news` |  | `public_letter_post` [logistics], `coffeehouse_public_talk` [culture], `press_licence_lapse` [institutions] |  |
| 2210 | `comet_return_prediction` | `universal_gravitation`, `observed_table_revision` [1200-1800] |  | `printed_ephemerides`, `realm_longitude_observatory` |  |
| 2216 | `friction_electric_machine` | `earth_magnet_treatise`, `chartered_experimental_society` |  | `vacuum_experiments`, `glass_blowing` [production, 600-1200] |  |
| 2228 | `precision_thermometry` | `instrument_maker_workshops`, `mercury_barometer` |  | `salaried_science_academy`, `air_spring_law` |  |
| 2238 | `public_experiment_lectures` | `chartered_experimental_society`, `vacuum_pumps` |  | `coffeehouse_public_talk` [culture], `friction_electric_machine` |  |
| 2258 | `structural_load_testing` | `stress_strain_relations` |  | `elastic_deformation`, `salaried_science_academy` |  |
| 2262 | `subscription_libraries` | `public_libraries` [culture, 600-1200], `town_printing_houses` |  | `coffeehouse_public_talk` [culture], `periodical_essay_sheets` [culture] |  |
| 2276 | `flow_continuity` | `hydrostatic_pressure` [600-1200], `differential_calculus` |  | `integral_calculus`, `momentum_balance` |  |
| 2286 | `numerical_integration` | `integral_calculus`, `decimal_log_tables` |  | `differential_equations`, `comet_return_prediction` |  |
| 2288 | `column_buckling` | `stress_strain_relations`, `differential_equations` |  | `structural_load_testing` |  |
| 2290 | `charge_storing_jar` | `friction_electric_machine` |  | `public_experiment_lectures`, `glass_blowing` [production, 600-1200] |  |
| 2294 | `experimental_controls` | `inductive_method_program`, `laboratory_notebooks` |  | `probability_theory`, `experimental_protocol_publication` |  |
| 2302 | `reasoned_trades_encyclopedia` | `word_origin_encyclopedia` [1200-1800], `rolling_intaglio_printing` |  | `salaried_science_academy`, `subscription_libraries`, `systematic_doubt_method` |  |
| 2304 | `lightning_electricity_trial` | `charge_storing_jar` |  | `friction_electric_machine`, `experimental_protocol_publication` |  |
| 2310 | `standard_tongue_dictionary` | `hard_word_glossaries` [1200-1800], `tongue_purity_academy` [culture] |  | `town_printing_houses`, `reasoned_trades_encyclopedia` |  |
| 2322 | `coordinated_transit_expeditions` | `realm_longitude_observatory`, `eyepiece_design` |  | `universal_gravitation`, `salaried_science_academy`, `pendulum_regulated_clock` |  |
| 2330 | `mining_engineering_academies` | `salaried_science_academy`, `mining_ordinances` [labor] |  | `cameral_science_chairs` [institutions], `structural_load_testing`, `powder_rock_blasting` [production] |  |
| 2330 | `rotational_dynamics` | `momentum_balance`, `differential_equations` |  | `universal_gravitation` |  |
| 2344 | `isolated_airs_chemistry` | `air_spring_law`, `mineral_acid_distillation` [1200-1800] |  | `experimental_controls`, `precision_thermometry`, `chemical_medicine_school` [health] |  |
| 2360 | `calorimetry` | `precision_thermometry` |  | `isolated_airs_chemistry`, `experimental_controls` |  |
| 2360 | `flywheel_smoothing` | `rotational_dynamics` |  | `atmospheric_beam_engine` [production] |  |
| 2366 | `oxygen_combustion_theory` | `isolated_airs_chemistry`, `calorimetry` |  | `precision_thermometry`, `experimental_controls` |  |
| 2370 | `torsion_balance_force_law` | `charge_storing_jar`, `universal_gravitation` |  | `elastic_deformation`, `instrument_maker_workshops` |  |
| 2374 | `systematic_chemical_names` | `oxygen_combustion_theory` |  | `biological_classification` [ecology], `standard_tongue_dictionary` |  |
| 2376 | `feedback_governors` | `rotative_steam_engine` [production], `rotational_dynamics` |  | `flywheel_smoothing`, `fantail_windmills` [production] |  |
| 2382 | `decimal_earth_measures` | `triangulation_survey`, `meridian_shadow_stations` [1200-1800] |  | `coordinated_transit_expeditions`, `decimal_log_tables`, `coastal_hydrographic_survey` [logistics] |  |
| 2388 | `shutter_signal_frames` | `two_lens_telescope`, `timed_beacon_code` [1200-1800] |  | `numbered_signal_flags` [security], `pendulum_regulated_clock` |  |
| 2388 | `state_polytechnic_school` | `mining_engineering_academies`, `salaried_science_academy` |  | `bridge_road_engineering_school` [infrastructure], `artillery_academy` [security] |  |
| 2392 | `stone_lithography` | `screw_press_printing`, `oil_based_printing_inks` |  | `rolling_intaglio_printing`, `mezzotint_printmaking` |  |

## Cross-line prerequisites assumed from other 1800–2400 lines

These ids are mapped by other partials in parallel; each edge assumes the parent keeps its registry year. Hard edges only; precedents are listed in the table.

- `mainspring_fusee_clocks` (production 1858) → `elastic_deformation`
- `mainspring_fusee_clocks` (production 1858) → `geared_adding_machine`
- `concave_spectacles` (health 1875) → `two_lens_telescope`
- `clear_crystal_glass` (production 1878) → `experimental_optics`
- `navigators_log_scale` (logistics 2042) → `logarithmic_slide_rule`
- `rotative_steam_engine` (production 2364) → `feedback_governors`

## Prerequisites from the other kicl lines

- `mining_ordinances` (labor 1846) → `mining_engineering_academies`
- `tongue_purity_academy` (culture 2070) → `standard_tongue_dictionary`

## Year adjustments

None.
