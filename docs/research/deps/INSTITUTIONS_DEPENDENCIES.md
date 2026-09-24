# Institutions dependencies

Machine-readable source: `institutions.json`. Contract: `MAPPING_CONTRACT.md`. Any-sets are separated by ` / ` within brackets.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2 | `seasonal_duty_rosters` |  |  | `labor_rotations` |  |
| 3 | `council_messenger_duty` |  |  | `relay_call_stations` |  |
| 4 | `dissenting_voice_custom` |  |  | `shared_hearth_gatherings` |  |
| 5 | `leader_gift_redistribution` |  |  |  |  |
| 6 | `household_task_ledgers` | `household_task_division` | [`counting_words`] | `tallies` |  |
| 7 | `witnessed_agreement_customs` | `shared_hearth_gatherings` |  | `council_messenger_duty` |  |
| 8 | `elder_consultation_rites` | `shared_hearth_gatherings` |  | `genealogical_recitation`, `oral_epics` |  |
| 10 | `household_councils` | `council_messenger_duty`, `elder_consultation_rites` |  | `dissenting_voice_custom` |  |
| 12 | `elder_council_assent` | `household_councils` |  | `dissenting_voice_custom` |  |
| 14 | `seasonal_tribute_counts` | `leader_gift_redistribution`, `counting_words` |  | `household_task_ledgers`, `tallies` |  |
| 16 | `consensus_amendment_custom` | `elder_council_assent` |  | `dissenting_voice_custom` |  |
| 18 | `lineage_land_tenure` | `named_descent_lines`, `common_ground_marking` |  | `genealogical_recitation` |  |
| 20 | `blood_price` | `witnessed_agreement_customs`, `elder_council_assent` |  | `reciprocal_gift_exchange` |  |
| 24 | `seasonal_crisis_leader` | `household_councils` | [`emergency_food_caching` / `raid_scouting`] | `elder_council_assent` |  |
| 28 | `petition_speakers` | `hearth_shrine_offerings`, `household_councils` |  |  |  |
| 30 | `banishment_sentence` | `elder_council_assent` |  | `blood_price` |  |
| 35 | `customary_law` | `blood_price` |  | `banishment_sentence`, `mnemonic_verse_encoding`, `genealogical_recitation` |  |
| 40 | `public_stores` | `clay_lined_storage_pits`, `leader_gift_redistribution` |  | `watch_rotation`, `seasonal_tribute_counts` |  |
| 45 | `household_mediators` | `customary_law` |  |  |  |
| 55 | `exculpatory_oath` | `hearth_shrine_offerings`, `customary_law` |  | `witnessed_agreement_customs` |  |
| 60 | `customary_inheritance_shares` | `lineage_land_tenure`, `customary_law` |  |  |  |
| 65 | `field_boundary_markers` | `lineage_land_tenure` | [`dry_stone_walls` / `drainage`] | `common_ground_marking` |  |
| 70 | `labor_debt_tallies` | `tallies` | [`work_party_feasts` / `household_task_ledgers`] |  |  |
| 75 | `leader_feast_obligations` | `leader_gift_redistribution`, `public_stores` |  | `work_party_feasts` |  |
| 80 | `public_grain_weighing` | `public_stores` | [`standard_measures` / `reference_vessel_sets`] |  |  |
| 85 | `harvest_offering_shares` | `first_fruits_offering` |  | `seasonal_tribute_counts` |  |
| 90 | `public_praise_assemblies` | `household_councils` |  | `skill_recognition` |  |
| 95 | `trial_custom_periods` | `consensus_amendment_custom` |  | `moon_counting` |  |
| 100 | `boundary_oath_rituals` | `field_boundary_markers`, `exculpatory_oath` |  |  |  |
| 105 | `rotating_stewardship` | `public_stores`, `seasonal_duty_rosters` |  |  |  |
| 110 | `probationary_appointment_custom` | `trial_custom_periods` | [`rotating_stewardship` / `seasonal_crisis_leader`] |  |  |
| 115 | `temple_common_storehouse` | `first_shrine_house`, `public_stores` |  | `harvest_offering_shares` | institutions_min=0.2 |
| 120 | `boundary_marker_surveys` | `field_boundary_markers`, `paced_distance_counting` |  | `boundary_oath_rituals` |  |
| 125 | `public_dispute_airing` | `household_mediators` |  | `public_praise_assemblies` |  |
| 130 | `offering_keepers` | `temple_common_storehouse` |  | `rotating_stewardship` |  |
| 135 | `intervillage_tribute_reconciliation` | `seasonal_tribute_counts`, `knot_tally_cross_check` |  | `daughter_hamlets` | min_settlements=2 |
| 140 | `paramount_chiefdom` | `seasonal_crisis_leader`, `leader_feast_obligations` | [`daughter_hamlets` / `joint_hamlet_defense_pacts`] |  | min_settlements=3 |
| 145 | `mediated_restitution_custom` | `household_mediators` |  | `public_dispute_airing` |  |
| 150 | `shared_labor_registers` | `labor_debt_tallies` | [`material_accounting` / `knotted_record_systems`] |  |  |
| 152 | `sunset_rule_custom` | `trial_custom_periods` |  |  |  |
| 154 | `rotating_speaker_order` | `elder_council_assent` |  | `dissenting_voice_custom`, `public_dispute_airing` |  |
| 157 | `standing_arbiter_appointment` | `mediated_restitution_custom`, `probationary_appointment_custom` |  |  |  |
| 165 | `seal_breaking_rights` | `stamp_seals`, `rotating_stewardship` |  | `marked_storage_registers`, `offering_keepers` |  |
| 170 | `temple_ration_issue` | `offering_keepers` | [`standard_measures` / `reference_vessel_sets`] | `shrine_work_obligations` |  |
| 180 | `work_gang_overseers` | `task_captains`, `great_work_parties` |  | `paramount_chiefdom` |  |
| 190 | `hereditary_chiefly_rank` | `paramount_chiefdom` |  | `genealogical_recitation`, `customary_inheritance_shares` |  |
| 200 | `free_adult_assembly` | `household_councils`, `public_dispute_airing` |  | `rotating_speaker_order` |  |
| 210 | `grain_levy_accounting` | `material_accounting` | [`temple_common_storehouse` / `paramount_chiefdom`] | `marked_storage_registers` |  |
| 215 | `tributary_villages` | `paramount_chiefdom`, `intervillage_tribute_reconciliation` |  |  | min_settlements=3 |
| 225 | `public_grievance_hearings` | `public_dispute_airing`, `standing_arbiter_appointment` |  |  |  |
| 240 | `regional_arbitration_circuits` | `standing_arbiter_appointment` |  | `tributary_villages` | min_settlements=3 |
| 245 | `formal_oath_taking` | `exculpatory_oath`, `first_shrine_house` |  |  |  |
| 255 | `council_reformation_practice` | `consensus_amendment_custom`, `sunset_rule_custom` |  | `free_adult_assembly` |  |
| 260 | `temple_high_steward` | `offering_keepers`, `grain_levy_accounting` |  | `work_gang_overseers` | institutions_min=0.3 |
| 265 | `cross_household_grain_audits` | `knot_tally_cross_check`, `grain_levy_accounting` |  |  |  |
| 268 | `oath_witness_registers` | `formal_oath_taking`, `paired_record_witnessing` | [`impressed_number_tablets` / `knotted_record_systems`] |  |  |
| 272 | `regional_levy_coordination` | `grain_levy_accounting`, `tributary_villages` |  |  |  |
| 280 | `worker_ration_lists` | `temple_ration_issue` | [`clay_record_tablets` / `impressed_number_tablets`] | `fixed_worker_rations` |  |
| 285 | `appeal_reopening_custom` | `public_grievance_hearings` |  | `regional_arbitration_circuits` |  |
| 288 | `succession_naming_rites` | `hereditary_chiefly_rank` |  | `genealogical_recitation` |  |
| 295 | `census_rolls` | `clay_record_tablets`, `hearth_counts` |  | `harvest_headcount` |  |
| 300 | `public_levies` | `regional_levy_coordination` |  | `work_gang_overseers` |  |
| 310 | `titled_estate_overseers` | `temple_high_steward`, `work_gang_overseers` |  |  |  |
| 320 | `witnessed_land_sales` | `boundary_marker_surveys`, `witnessed_agreement_customs` |  | `sealed_tablet_contracts`, `customary_inheritance_shares` |  |
| 330 | `fixed_interest_loans` | `clay_record_tablets` | [`balance_beam_weights` / `silver_cupellation`] | `temple_common_storehouse`, `labor_debt_tallies` |  |
| 345 | `separate_temple_palace_stores` | `temple_high_steward`, `hereditary_chiefly_rank` |  |  |  |
| 355 | `cross_settlement_registries` | `census_rolls` |  | `messenger_relay_stations`, `archive_shelving_order` | min_settlements=3 |
| 365 | `kingship` | `hereditary_chiefly_rank` | [`household_muster` / `combined_drill_musters`] | `separate_temple_palace_stores`, `seasonal_crisis_leader` | min_settlements=4; institutions_min=0.4 |
| 375 | `ceremonial_investiture` | `formal_oath_taking`, `titled_estate_overseers` |  | `kingship` |  |
| 378 | `assembly_petition_rights` | `free_adult_assembly`, `petition_speakers` |  |  |  |
| 385 | `provincial_governors` | `kingship`, `tributary_villages` |  |  |  |
| 390 | `public_heralds` | `council_messenger_duty` | [`kingship` / `free_adult_assembly`] | `town_identity` |  |
| 400 | `codified_tribute_schedules` | `tributary_villages`, `clay_record_tablets` | [`solar_year_reckoning` / `star_rising_civil_year`] | `intercalated_calendar` |  |
| 405 | `specialized_courts` | `public_grievance_hearings`, `appeal_reopening_custom` |  | `regional_arbitration_circuits` | institutions_min=0.5 |
| 410 | `boundary_treaties` | `boundary_oath_rituals`, `formal_oath_taking` |  | `boundary_marker_surveys` | min_settlements=2 |
| 415 | `dynastic_succession` | `kingship`, `succession_naming_rites` |  |  |  |
| 420 | `precedent_review_councils` | `customary_law`, `formal_archives` |  | `specialized_courts` |  |
| 425 | `proclaimed_standard_weights` | `balance_beam_weights`, `public_heralds` |  |  |  |
| 430 | `debt_release_edicts` | `fixed_interest_loans`, `kingship` |  | `public_heralds` |  |
| 440 | `foreign_treaties` | `boundary_treaties`, `kingship` |  | `sworn_interpreters`, `envoy_reception`, `sealed_tablet_letters` | contact_required=yes |
| 445 | `sealed_travel_passes` | `cylinder_seals`, `messenger_relay_stations` |  | `sealed_tablet_letters`, `road_stations` |  |
| 455 | `temple_estates` | `temple_high_steward`, `titled_estate_overseers` |  |  |  |
| 460 | `area_harvest_assessment` | `geometric_survey`, `grain_levy_accounting` | [`area_volume_rules`] |  |  |
| 465 | `royal_inscriptions` | `kingship`, `phonetic_notation` | [`stone_relief_carving` / `dressed_stone_masonry`] |  |  |
| 480 | `written_law_code` | `precedent_review_councils`, `kingship`, `phonetic_notation` |  | `debt_release_edicts`, `specialized_courts` | institutions_min=0.5 |
| 485 | `sworn_judges` | `specialized_courts`, `ceremonial_investiture` |  |  |  |
| 490 | `sworn_trial_testimony` | `specialized_courts`, `oath_witness_registers` |  | `written_law_code` |  |
| 500 | `provincial_accounts` | `provincial_governors`, `formal_archives` |  | `messenger_relay_stations` |  |
| 510 | `sealed_family_contracts` | `sealed_tablet_contracts`, `customary_inheritance_shares` |  | `recorded_dowry`, `captive_adoption` |  |
| 515 | `caravan_tolls` | `donkey_caravans`, `codified_tribute_schedules` |  | `border_fortress_chains` |  |
| 525 | `property_registers` | `witnessed_land_sales`, `formal_archives` |  | `geometric_survey`, `regional_maps` |  |
| 530 | `town_mayors` | `provincial_governors` |  | `elder_council_assent`, `town_identity` |  |
| 535 | `royal_appeal_court` | `specialized_courts`, `provincial_governors` |  | `appeal_reopening_custom` |  |
| 540 | `price_wage_schedules` | `proclaimed_standard_weights`, `hired_labor_contracts` |  | `written_law_code` |  |
| 545 | `licensed_merchant_houses` | `sealed_travel_passes`, `foreign_treaties` | [`merchant_quarters_abroad` / `trade_colonies`] |  | contact_required=yes |
| 550 | `public_law_stele` | `written_law_code`, `royal_inscriptions` |  |  |  |
| 555 | `service_land_grants` | `property_registers` | [`standing_paid_company` / `palace_guard`] | `titled_estate_overseers` |  |
| 560 | `jurisdiction_boundaries` | `provincial_governors`, `specialized_courts` |  | `regional_maps`, `boundary_treaties` |  |
| 570 | `workshop_quotas` | `temple_workshops`, `workshop_standards` | [`daily_task_norms` / `brick_quotas`] | `provincial_accounts` |  |
| 580 | `circuit_inspectors` | `provincial_accounts` |  | `rotating_inspection_duty`, `regional_arbitration_circuits` |  |
| 590 | `standard_royal_letters` | `sealed_tablet_letters`, `provincial_governors` |  | `scribal_specialties` |  |
| 600 | `service_land_registers` | `service_land_grants`, `census_rolls` |  | `cross_settlement_registries` |  |
