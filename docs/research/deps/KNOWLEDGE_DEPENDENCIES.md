# Knowledge dependencies

Machine-readable source: `knowledge.json`. Contract: `MAPPING_CONTRACT.md`. Any-sets are separated by ` / ` within brackets.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2 | `route_memory` |  |  |  |  |
| 3 | `relay_call_stations` |  |  | `watch_rotation` |  |
| 5 | `counting_words` |  |  | `route_memory` |  |
| 6 | `weather_sign_reading` | `seasonal_patterns` |  |  |  |
| 8 | `novice_task_shadowing` |  | [`paired_task_assignment` / `household_task_division`] |  |  |
| 10 | `tallies` | `counting_words` |  |  |  |
| 12 | `distance_call_signals` | `relay_call_stations` |  | `alarm_relay_signals` |  |
| 15 | `cairn_sightline_marking` | `route_memory` | [`sightline_staking` / `trail_waymarking`] | `landmark_route_naming` |  |
| 18 | `watch_duty_rotation` | `watch_rotation` |  | `labor_rotations` |  |
| 22 | `moon_counting` | `counting_words`, `tallies` |  | `weather_sign_reading` |  |
| 25 | `knot_tally_cross_check` | `tallies` |  | `witnessed_agreement_customs`, `household_councils` |  |
| 30 | `repeated_recitation_training` | `novice_task_shadowing` |  | `oral_epics` |  |
| 35 | `childrens_question_circles` | `curious_questioning_custom` |  | `shared_hearth_gatherings` |  |
| 40 | `solstice_horizon_markers` | `moon_counting` | [`cairn_sightline_marking` / `sightline_staking`] | `seasonal_patterns` |  |
| 45 | `standard_measures` | `counting_words` |  | `notched_measuring_rods`, `paired_measure_checking` |  |
| 50 | `mnemonic_verse_encoding` | `repeated_recitation_training` |  | `oral_epics`, `genealogical_recitation` |  |
| 55 | `owner_marks` |  | [`clay_shaping` / `woven_carriers`] | `kin_body_ornament`, `trade_partner_tokens`, `lineage_land_tenure` |  |
| 60 | `paced_distance_counting` | `standard_measures` |  | `route_memory`, `tallies` |  |
| 65 | `landmark_triangulation` | `cairn_sightline_marking` |  | `solstice_horizon_markers` |  |
| 70 | `clay_counting_tokens` | `tallies`, `clay_shaping` |  | `pit_firing`, `owner_marks`, `seasonal_tribute_counts` | resources_known=Clay |
| 80 | `specialist_task_assignment` | `part_time_specialists` |  | `skill_recognition` |  |
| 85 | `drum_relay_signals` | `distance_call_signals` |  | `bone_flutes_drums` |  |
| 90 | `focused_error_review` | `specialist_task_assignment` |  | `kiln_control`, `scrap_reclamation_habits` |  |
| 100 | `stamp_seals` | `owner_marks` | [`ground_stone_axes` / `bow_drill_drive`] | `clay_counting_tokens` |  |
| 105 | `material_accounting` | `clay_counting_tokens`, `public_stores` |  | `seasonal_tribute_counts` |  |
| 115 | `paired_record_witnessing` | `material_accounting` |  | `knot_tally_cross_check`, `witnessed_agreement_customs` |  |
| 120 | `solar_year_reckoning` | `moon_counting`, `solstice_horizon_markers` |  | `crop_calendars` |  |
| 130 | `fire_smoke_signaling` | `distance_call_signals` |  | `cairn_sightline_marking`, `hilltop_refuges`, `drum_relay_signals` |  |
| 140 | `cross_bearing_confirmation` | `landmark_triangulation` |  | `paced_distance_counting` |  |
| 145 | `knotted_record_systems` | `tallies`, `cordage` |  | `knot_tally_cross_check`, `mnemonic_verse_encoding` |  |
| 150 | `marked_storage_registers` | `material_accounting`, `stamp_seals` |  |  |  |
| 160 | `token_envelopes` | `clay_counting_tokens`, `stamp_seals` |  | `paired_record_witnessing`, `pit_firing` | resources_known=Clay |
| 170 | `rotating_inspection_duty` | `watch_duty_rotation` | [`marked_storage_registers` / `rotating_stewardship`] |  |  |
| 180 | `star_rise_markers` | `solar_year_reckoning` |  | `named_star_figures`, `wayfinding_stars` |  |
| 190 | `standardized_gesture_code` | `boundary_exchange_sites` |  | `counting_words`, `barter_equivalence_custom` | contact_required=yes |
| 200 | `boundary_sighting_marks` | `cross_bearing_confirmation`, `field_boundary_markers` |  | `boundary_marker_surveys` |  |
| 210 | `problem_council_sessions` | `focused_error_review` |  | `elder_consultation_rites`, `full_time_specialists` |  |
| 220 | `tens_sixties_bundling` | `clay_counting_tokens` |  | `knotted_record_systems`, `standard_measures`, `material_accounting` |  |
| 225 | `impressed_number_tablets` | `token_envelopes`, `tens_sixties_bundling` |  |  | resources_known=Clay |
| 230 | `seasonal_news_gathering` |  | [`traveling_storyteller_exchange` / `trade_partner_memory` / `down_the_line_exchange`] | `mnemonic_verse_encoding`, `council_messenger_duty` |  |
| 240 | `rod_and_cord_leveling` | `standard_measures`, `cordage` | [`flood_levees` / `river_supply_channels`] | `notched_measuring_rods`, `corner_squaring_method` |  |
| 245 | `attention_priority_signals` | `task_captains` | [`owner_marks` / `shared_work_signals`] | `craft_order_queuing` |  |
| 255 | `pictographic_records` | `impressed_number_tablets` | [`temple_common_storehouse` / `grain_levy_accounting`] | `owner_marks`, `stamp_seals`, `shrine_wall_painting` | institutions_min=0.3 |
| 260 | `cylinder_seals` | `stamp_seals` | [`bow_drill_drive` / `tube_drilled_stone_vessels`] | `pictographic_records` |  |
| 270 | `clay_record_tablets` | `pictographic_records` |  | `clay_levigation` | resources_known=Clay |
| 280 | `standard_sign_lists` | `clay_record_tablets` |  | `repeated_recitation_training` |  |
| 290 | `scribal_apprenticeship` | `standard_sign_lists` |  | `mentored_task_learning` |  |
| 300 | `agreed_signal_codes` |  | [`fire_smoke_signaling` / `drum_relay_signals`] | `standardized_gesture_code`, `signal_command_drill` |  |
| 310 | `archive_shelving_order` | `clay_record_tablets` |  | `standard_sign_lists`, `courtyard_storerooms`, `marked_storage_registers` |  |
| 320 | `balance_beam_weights` | `standard_weight_sets` |  | `standard_measures`, `public_grain_weighing` |  |
| 330 | `messenger_relay_stations` | `runner_relays_between_work_sites` |  | `graded_roads`, `paramount_chiefdom` | min_settlements=3 |
| 340 | `sealed_tablet_contracts` | `clay_record_tablets`, `cylinder_seals` |  | `witnessed_agreement_customs`, `formal_oath_taking` |  |
| 350 | `dedicated_apprentice_observation` | `mentored_task_learning` |  | `scribal_apprenticeship`, `journeyman_placement` |  |
| 360 | `phonetic_notation` | `standard_sign_lists` |  | `genealogical_recitation`, `theophoric_names` |  |
| 370 | `plumb_line_sighting` | `rod_and_cord_leveling` |  | `corner_squaring_method`, `dressed_stone_masonry` |  |
| 380 | `star_rising_civil_year` | `star_rise_markers`, `clay_record_tablets` |  | `flood_mark_reading` |  |
| 390 | `written_lore_tablets` | `phonetic_notation` |  | `oral_epics`, `mnemonic_verse_encoding` |  |
| 395 | `written_apprentice_instructions` | `phonetic_notation`, `dedicated_apprentice_observation` |  |  |  |
| 400 | `workshop_standards` | `output_quality_sorting` | [`clay_record_tablets` / `stamp_seals`] | `temple_workshops`, `template_based_sizing`, `focused_error_review` |  |
| 405 | `formal_archives` | `archive_shelving_order` | [`temple_high_steward` / `kingship`] |  | institutions_min=0.4 |
| 410 | `cross_referenced_archives` | `formal_archives` |  | `standard_sign_lists` |  |
| 415 | `formal_chronicle_keeping` | `phonetic_notation` | [`kingship` / `temple_high_steward`] | `disaster_memory_markers`, `genealogical_recitation`, `solar_year_reckoning` |  |
| 420 | `public_schools` | `scribal_apprenticeship`, `formal_archives` |  | `repeated_recitation_training` | institutions_min=0.4 |
| 425 | `sealed_tablet_letters` | `sealed_tablet_contracts`, `phonetic_notation` |  | `messenger_relay_stations` |  |
| 430 | `intercalated_calendar` | `solar_year_reckoning`, `clay_record_tablets` |  | `star_rising_civil_year`, `grain_levy_accounting` |  |
| 440 | `bilingual_sign_lists` | `standard_sign_lists`, `phonetic_notation` |  | `trade_colonies` | contact_required=yes |
| 445 | `sworn_interpreters` | `formal_oath_taking` | [`bilingual_sign_lists` / `trade_colonies`] |  | contact_required=yes |
| 450 | `geometric_survey` | `rod_and_cord_leveling`, `boundary_marker_surveys` |  | `corner_squaring_method` |  |
| 460 | `water_trough_leveling` | `rod_and_cord_leveling` |  | `plumb_line_sighting` |  |
| 465 | `scribal_specialties` | `public_schools` |  | `geometric_survey`, `sealed_tablet_letters`, `grain_levy_accounting` |  |
| 470 | `area_volume_rules` | `geometric_survey`, `tens_sixties_bundling` |  | `grain_levy_accounting` |  |
| 475 | `sightline_corridor_marking` | `boundary_sighting_marks` | [`fire_smoke_signaling` / `gate_watchtowers`] | `agreed_signal_codes` |  |
| 480 | `star_hour_tables` | `star_rising_civil_year` |  | `watch_duty_rotation`, `formal_archives` |  |
| 485 | `reciprocal_tables` | `tens_sixties_bundling`, `public_schools` |  | `area_volume_rules` |  |
| 490 | `tablet_colophons` | `formal_archives`, `phonetic_notation` |  | `formal_chronicle_keeping` |  |
| 500 | `scribal_copying_tests` | `public_schools` |  | `workshop_standards`, `written_apprentice_instructions` |  |
| 510 | `place_value` | `reciprocal_tables` |  | `area_volume_rules` |  |
| 520 | `fractional_quantities` | `reciprocal_tables` |  | `balance_beam_weights`, `area_volume_rules` |  |
| 530 | `worked_problem_tablets` | `area_volume_rules`, `scribal_copying_tests` |  | `place_value` |  |
| 540 | `regional_maps` | `geometric_survey`, `clay_record_tablets` |  | `cross_bearing_confirmation`, `boundary_sighting_marks`, `urban_street_plans` |  |
| 545 | `square_root_tables` | `place_value` |  | `area_volume_rules` |  |
| 550 | `prearranged_beacon_chains` | `agreed_signal_codes`, `sightline_corridor_marking` |  | `border_fortress_chains` |  |
| 560 | `consonantal_alphabet` | `phonetic_notation` | [`bilingual_sign_lists` / `sworn_interpreters`] |  | contact_required=yes |
| 570 | `dated_omen_records` | `formal_chronicle_keeping` |  | `offering_omens`, `star_hour_tables`, `named_star_figures` |  |
| 580 | `shadow_clock` | `solar_year_reckoning`, `plumb_line_sighting` |  | `star_hour_tables` |  |
| 590 | `outflow_water_clock` | `star_hour_tables`, `fractional_quantities` |  | `shadow_clock`, `wheel_thrown_pottery` |  |
| 600 | `checked_master_copies` | `tablet_colophons`, `scribal_copying_tests` |  |  |  |
