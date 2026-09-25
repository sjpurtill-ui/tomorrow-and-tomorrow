# Knowledge dependencies, years 1200–1800

Machine-readable source: `partials/kicl.json` (knowledge, institutions, culture, labor). Contract: the 600–1200 mapping (`docs/research/y600/deps/partials/kicl.json`, merged by `tools/research/merge_graph_1200.py`). Prerequisites may be 0–600, 600–1200 or 1200–1800 ids in any line, dated at or before the dependent. Any-sets are separated by ` / ` within brackets. Year adjustments are in `partials/kicl_year_adjustments.json`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1206 | `rounded_book_hand` | `parchment_record_preparation`, `bookbinding_assemblies` |  | `cursive_document_hand`, `checked_master_copies`, `canonized_sacred_sayings` |  |
| 1212 | `devised_script_for_new_tongue` | `adapted_alphabet_borrowing`, `full_vowel_alphabet` |  | `translation_bureaus`, `written_grammar`, `canonized_sacred_sayings` | contact_required=yes |
| 1222 | `itinerary_strip_maps` | `regional_maps`, `road_itineraries` |  | `strip_route_maps`, `distance_milestones`, `coordinate_gazetteer_maps` |  |
| 1227 | `seven_arts_manuals` | `liberal_curriculum`, `epitome_digests` |  | `encyclopedic_compendia`, `salaried_public_teachers`, `rhetoric_handbooks` |  |
| 1240 | `moving_feast_reckoning` | `nineteen_year_cycle`, `leap_year_solar_calendar` |  | `calendar_feast_days`, `weekly_rest_day` |  |
| 1252 | `hard_word_glossaries` | `thematic_word_lists`, `written_grammar` |  | `bilingual_sign_lists`, `scholarly_commentaries`, `rounded_book_hand` |  |
| 1267 | `nine_digits_and_zero` | `place_value`, `counting_rod_decimals` |  | `counting_board_abacus`, `number_theory_treatise` |  |
| 1270 | `half_chord_sine_tables` | `trigonometry` |  | `sky_tables_compendium`, `polygon_circle_estimation`, `nine_digits_and_zero` |  |
| 1278 | `sacred_epoch_year_count` | `founding_era_annals`, `moving_feast_reckoning` |  | `eponym_year_lists`, `providential_world_history` |  |
| 1286 | `retreat_copying_rooms` | `devotee_communities_under_rule`, `rounded_book_hand` |  | `public_libraries`, `checked_master_copies`, `bookbinding_assemblies` |  |
| 1300 | `school_logic_primers` | `syllogistic_logic`, `seven_arts_manuals` |  | `translation_bureaus`, `scholarly_commentaries` |  |
| 1313 | `rhyme_sound_dictionary` | `hard_word_glossaries`, `phonetic_notation` |  | `written_grammar`, `learned_allusive_poetry` |  |
| 1326 | `zero_negative_rules` | `red_black_rod_negatives`, `nine_digits_and_zero` |  | `syncopated_algebra` |  |
| 1328 | `word_origin_encyclopedia` | `encyclopedic_compendia`, `hard_word_glossaries` |  | `seven_arts_manuals`, `author_subject_catalogues` |  |
| 1340 | `planispheric_astrolabe` | `armillary_sphere`, `star_position_catalogue` |  | `half_chord_sine_tables`, `straightedge_compass`, `cementation_brass` |  |
| 1355 | `relief_block_cutting` | `textile_printing` |  | `cylinder_seals`, `inlay_carving`, `lampblack_capture` |  |
| 1360 | `printing_process` | `relief_block_cutting`, `paper_making` |  | `lampblack_capture`, `retreat_copying_rooms`, `canonized_sacred_sayings` |  |
| 1362 | `word_spacing` | `rounded_book_hand`, `reading_marks` |  | `hard_word_glossaries`, `chapter_contents_lists` |  |
| 1371 | `meridian_shadow_stations` | `earth_circumference_measure`, `seasonal_hour_sundial` |  | `latitude_zones`, `half_chord_sine_tables` |  |
| 1372 | `waterwheel_escapement_globe` | `geared_sky_calculator`, `water_mills` |  | `armillary_sphere`, `outflow_water_clock`, `cog_and_lantern_gearing` |  |
| 1375 | `lunar_tide_reckoning` | `tide_reckoning`, `sky_tables_compendium` |  | `written_sailing_directions` |  |
| 1397 | `small_letter_book_hand` | `rounded_book_hand`, `cursive_document_hand` |  | `word_spacing`, `retreat_copying_rooms` |  |
| 1407 | `chemical_distillation` | `alembic_distillation`, `glass_blowing` |  | `ceramic_crucibles`, `written_craft_recipes` |  |
| 1418 | `digit_reckoning_handbook` | `nine_digits_and_zero`, `zero_negative_rules` |  | `counting_board_abacus`, `worked_problem_tablets` |  |
| 1419 | `restoration_balancing_algebra` | `syncopated_algebra`, `zero_negative_rules` |  | `digit_reckoning_handbook`, `demonstrated_geometry` |  |
| 1422 | `royal_house_of_learning` | `translation_bureaus`, `public_libraries` |  | `court_learning_revival`, `endowed_scholar_house`, `retreat_copying_rooms` |  |
| 1425 | `fixed_instrument_observatory` | `royal_house_of_learning`, `armillary_sphere` |  | `planispheric_astrolabe`, `meridian_shadow_stations`, `star_position_catalogue` |  |
| 1430 | `letter_frequency_codebreaking` | `letter_substitution_cipher`, `hard_word_glossaries` |  | `royal_house_of_learning`, `rhyme_sound_dictionary`, `combinatorics` |  |
| 1432 | `timed_beacon_code` | `realm_beacon_chain`, `outflow_water_clock` |  | `prearranged_beacon_chains`, `torch_alphabet_signals`, `agreed_signal_codes` |  |
| 1441 | `block_printed_books` | `printing_process`, `paper_sheet_pressing` |  | `bookbinding_assemblies`, `tablet_colophons`, `retreat_copying_rooms` |  |
| 1444 | `printed_almanacs` | `printing_process`, `star_weather_almanac` |  | `moving_feast_reckoning`, `farmers_almanac`, `block_printed_books` |  |
| 1453 | `observed_table_revision` | `sky_tables_compendium`, `fixed_instrument_observatory` |  | `half_chord_sine_tables`, `astronomical_diaries` |  |
| 1456 | `horary_quadrant` | `dioptra_survey`, `half_chord_sine_tables` |  | `planispheric_astrolabe`, `seasonal_hour_sundial` |  |
| 1465 | `printed_standard_classics` | `block_printed_books`, `collated_critical_editions` |  | `regular_merit_examinations`, `checked_master_copies` |  |
| 1472 | `scholarly_question_letters` | `royal_house_of_learning` |  | `published_letter_collections`, `fee_kept_post_stations`, `diplomatic_letter_formulary` | contact_required=yes |
| 1478 | `written_decimal_fractions` | `digit_reckoning_handbook`, `counting_rod_decimals` |  | `restoration_balancing_algebra`, `fractional_quantities` |  |
| 1483 | `illustrated_star_atlas` | `star_position_catalogue`, `observed_table_revision` |  | `named_star_figures`, `interlace_illuminated_books` |  |
| 1490 | `digit_column_counting_board` | `counting_board_abacus`, `nine_digits_and_zero` |  | `digit_reckoning_handbook` |  |
| 1494 | `great_house_schools` | `seven_arts_manuals`, `retreat_copying_rooms` |  | `palace_school_for_officials`, `court_learning_revival`, `small_letter_book_hand` |  |
| 1500 | `polynomial_term_algebra` | `restoration_balancing_algebra`, `written_decimal_fractions` |  | `number_theory_treatise`, `zero_negative_rules` |  |
| 1518 | `darkened_room_optics` | `geometric_optics_treatise`, `royal_house_of_learning` |  | `fixed_instrument_observatory`, `lathe_ground_cast_glass` |  |
| 1522 | `sky_model_doubts` | `sky_tables_compendium`, `observed_table_revision` |  | `fixed_instrument_observatory`, `scholarly_question_letters` |  |
| 1533 | `movable_type_composition` | `printing_process`, `industrial_pottery_kilns` |  | `block_printed_books`, `printed_standard_classics`, `rhyme_sound_dictionary` |  |
| 1545 | `guest_star_records` | `sky_watch_reports`, `observed_table_revision` |  | `illustrated_star_atlas`, `fixed_instrument_observatory` |  |
| 1546 | `binomial_coefficient_triangle` | `polynomial_term_algebra`, `combinatorics` |  | `digit_column_counting_board` |  |
| 1550 | `universal_astrolabe_plate` | `planispheric_astrolabe`, `half_chord_sine_tables` |  | `horary_quadrant`, `fixed_instrument_observatory`, `latitude_zones` |  |
| 1558 | `geometric_cubic_solutions` | `polynomial_term_algebra`, `axiomatic_geometry_compendium` |  | `binomial_coefficient_triangle`, `exhaustion_area_method` |  |
| 1567 | `letter_writing_art` | `rhetoric_handbooks`, `diplomatic_letter_formulary` |  | `small_letter_book_hand`, `great_house_schools`, `sealed_royal_writs` |  |
| 1573 | `astronomical_clock_tower` | `waterwheel_escapement_globe`, `public_clock_tower` |  | `cog_and_lantern_gearing`, `brick_stair_towers`, `fixed_instrument_observatory` |  |
| 1575 | `observation_notebooks` | `descriptive_natural_history`, `great_house_schools` |  | `paper_sheet_pressing`, `sky_model_doubts`, `guest_star_records` |  |
| 1600 | `contrary_authorities_method` | `school_logic_primers`, `great_house_schools` |  | `collated_critical_editions`, `scholarly_commentaries`, `sky_model_doubts` |  |
| 1612 | `magnetic_declination_note` | `floating_needle_compass` |  | `observation_notebooks`, `meridian_shadow_stations` |  |
| 1612 | `paper_working_copies` | `paper_making`, `paper_sheet_pressing` |  | `iron_gall_ink`, `wax_writing_boards` |  |
| 1622 | `collected_sentences_textbook` | `excerpt_anthologies`, `contrary_authorities_method` |  | `great_house_schools`, `scholarly_commentaries` |  |
| 1625 | `chartered_university` | `great_house_schools`, `craft_guilds` |  | `glossator_law_schools`, `sworn_town_commune`, `contrary_authorities_method`, `chartered_town_liberties` |  |
| 1630 | `rival_tongue_translation_school` | `translation_bureaus`, `great_house_schools` |  | `royal_house_of_learning`, `hard_word_glossaries`, `chartered_university` | contact_required=yes |
| 1640 | `teaching_licence_degree` | `chartered_university` |  | `certified_craft_competence`, `glossator_law_schools`, `ranked_priestly_hierarchy` |  |
| 1650 | `scholastic_question_method` | `contrary_authorities_method`, `chartered_university` |  | `collected_sentences_textbook`, `school_logic_primers`, `rival_tongue_translation_school` |  |
| 1655 | `set_text_lectures` | `chartered_university`, `collected_sentences_textbook` |  | `scholarly_commentaries`, `teaching_licence_degree` |  |
| 1668 | `merchant_digit_reckoning` | `nine_digits_and_zero`, `digit_reckoning_handbook` |  | `written_decimal_fractions`, `rival_tongue_translation_school`, `merchant_guild_monopoly`, `bills_of_exchange` |  |
| 1672 | `automata_machine_book` | `mechanical_treatises`, `rival_tongue_translation_school` |  | `cam_motion_design`, `piston_force_pumps`, `waterwheel_escapement_globe` |  |
| 1690 | `science_of_weights` | `lever_moments`, `rival_tongue_translation_school` |  | `scholastic_question_method`, `centers_of_mass` |  |
| 1692 | `alphabetical_concordance` | `abecedary_letter_order`, `paper_working_copies` |  | `chapter_contents_lists`, `author_subject_catalogues`, `set_text_lectures` |  |
| 1700 | `endowed_student_colleges` | `endowed_scholar_house`, `chartered_university` |  | `teaching_licence_degree` |  |
| 1706 | `district_rain_gauges` | `flood_height_gauges`, `graduated_measuring_rods` |  | `star_weather_almanac`, `snowpack_flow_forecast`, `paired_royal_envoys` |  |
| 1707 | `stepwise_high_root_extraction` | `polynomial_term_algebra`, `binomial_coefficient_triangle` |  | `counting_board_abacus`, `geometric_cubic_solutions` |  |
| 1708 | `rented_exemplar_copying` | `chartered_university`, `paper_working_copies` |  | `checked_master_copies`, `set_text_lectures`, `craft_guilds` |  |
| 1718 | `experimental_science_program` | `darkened_room_optics`, `scholastic_question_method` |  | `observation_notebooks`, `science_of_weights`, `rival_tongue_translation_school` |  |
| 1724 | `lodestone_pole_experiments` | `magnetic_declination_note`, `experimental_science_program` |  | `floating_needle_compass` |  |
| 1725 | `royal_sky_tables_commission` | `observed_table_revision`, `royal_house_of_learning` |  | `rival_tongue_translation_school`, `universal_astrolabe_plate`, `sky_model_doubts` |  |
| 1728 | `school_perspective_optics` | `darkened_room_optics`, `set_text_lectures` |  | `experimental_science_program`, `geometric_optics_treatise` |  |
| 1733 | `optical_lenses` | `decolorized_clear_glass`, `gem_cutting_wheel`, `darkened_room_optics` |  | `school_perspective_optics`, `lathe_ground_cast_glass` |  |
| 1735 | `reckoning_schools` | `merchant_digit_reckoning`, `great_house_schools` |  | `letter_writing_art`, `merchant_guild_monopoly`, `chartered_university` |  |
| 1737 | `verge_escapement_clock` | `astronomical_clock_tower`, `cog_and_lantern_gearing` |  | `waterwheel_escapement_globe`, `pit_cast_bells` |  |
| 1742 | `foliated_running_heads` | `alphabetical_concordance`, `paper_working_copies` |  | `chapter_contents_lists`, `rented_exemplar_copying` |  |
| 1746 | `wooden_movable_type` | `movable_type_composition`, `rhyme_sound_dictionary` |  | `block_printed_books`, `printed_standard_classics` |  |
| 1752 | `mineral_acid_distillation` | `chemical_distillation`, `alum_works` |  | `salt_cementation_parting`, `sulfur_purification`, `glass_blowing` |  |
| 1753 | `water_sphere_rainbow_test` | `experimental_science_program`, `school_perspective_optics` |  | `glass_blowing`, `optical_lenses` |  |
| 1760 | `vernacular_learned_writing` | `chartered_university`, `hard_word_glossaries` |  | `vernacular_allegory_epic`, `courtly_love_lyric`, `devotional_songs_common_tongue` |  |
| 1775 | `striking_equal_hour_clock` | `verge_escapement_clock`, `pit_cast_bells` |  | `astronomical_clock_tower`, `communal_bell_hours`, `work_bell_hours` |  |
| 1778 | `mean_speed_rule` | `science_of_weights`, `scholastic_question_method` |  | `experimental_science_program`, `polynomial_term_algebra` |  |
| 1784 | `commonplace_books` | `paper_working_copies`, `observation_notebooks` |  | `foliated_running_heads`, `alphabetical_concordance`, `paper_stamping_mills` |  |
| 1788 | `impetus_theory` | `science_of_weights`, `scholastic_question_method` |  | `mean_speed_rule`, `counterweight_engines` |  |
| 1792 | `quality_graphs` | `mean_speed_rule`, `coordinate_gazetteer_maps` |  | `impetus_theory`, `scaled_grid_mapping` |  |

## Cross-line prerequisites assumed from other 1200–1800 lines

These ids are mapped by other partials in parallel; the edge assumes they keep their registry year.

- `textile_printing` (production 1320) → `relief_block_cutting`
- `cog_and_lantern_gearing` (production 1370) → `verge_escapement_clock`
- `realm_beacon_chain` (security 1420) → `timed_beacon_code`
- `paper_sheet_pressing` (production 1422) → `block_printed_books`
- `paper_sheet_pressing` (production 1422) → `paper_working_copies`
- `pit_cast_bells` (production 1448) → `striking_equal_hour_clock`
- `floating_needle_compass` (logistics 1600) → `magnetic_declination_note`
- `alum_works` (production 1648) → `mineral_acid_distillation`

## Year adjustments

None.
