# Demography dependencies

Generated with `docs/research/deps/demography.json`. It uses registry ids only. Cross-line ids show their line in brackets. An `environment` list means any one of the listed environments satisfies the gate. In the table, the ids in one `requires_any` group are separated by ` / `, and separate groups are separated by `;`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2 | lactational_spacing_awareness |  |  |  |  |
| 3 | labor_position_customs |  |  |  |  |
| 3 | named_descent_lines |  |  | genealogical_recitation [culture] |  |
| 4 | fever_watch_customs |  |  | sickness_pattern_memory [health] |  |
| 4 | sleeping_area_rotation |  |  | hearth_heat_retention [nutrition] |  |
| 5 | infant_swaddling_practice |  |  | cordage [production] |  |
| 6 | birth_spacing_customs | lactational_spacing_awareness |  |  |  |
| 7 | postpartum_seclusion_care | labor_position_customs |  |  |  |
| 10 | infant_carrying_slings | cordage [production] |  | infant_swaddling_practice |  |
| 12 | shared_childcare | household_task_division [labor] |  | shared_hearth_gatherings [culture] |  |
| 14 | extended_family_room_division | sleeping_area_rotation |  | framed_construction [infrastructure] |  |
| 16 | lineage_exogamy | named_descent_lines |  |  |  |
| 20 | mouths_against_store | tallies [knowledge] |  | food_drying [nutrition], counting_words [knowledge] |  |
| 24 | patrilocal_residence | lineage_exogamy |  |  |  |
| 28 | kin_care_widows_orphans | named_descent_lines, shared_childcare |  |  |  |
| 37 | maternal_recovery | postpartum_seclusion_care, dietary_healing_regimens [health] |  |  |  |
| 42 | household_space_planning | extended_family_room_division | adobe_wall_construction [infrastructure] / framed_construction [infrastructure] |  |  |
| 50 | village_marriage_alliances | lineage_exogamy |  | reciprocal_gift_exchange [culture] | min_settlements: 2 |
| 55 | elder_care_by_children | kin_care_widows_orphans, patrilocal_residence |  |  |  |
| 60 | winter_herder_return | animal_taming [nutrition] |  | transhumance [ecology] |  |
| 65 | bride_wealth_gifts | village_marriage_alliances, animal_taming [nutrition] |  |  |  |
| 70 | captive_adoption | named_descent_lines, kin_care_widows_orphans |  | ambush_raids [security] |  |
| 82 | daughter_hamlets | mouths_against_store, lineage_land_tenure [institutions] |  |  |  |
| 88 | lean_year_dispersal | village_marriage_alliances |  | mouths_against_store |  |
| 90 | infant_feeding_schedules | birth_spacing_customs |  |  |  |
| 91 | seasonal_conception_timing | birth_spacing_customs, crop_calendars [nutrition] |  | mouths_against_store |  |
| 92 | cord_afterbirth_handling | birth_attendants [health] |  | cordage [production] |  |
| 93 | room_allocation_by_size | household_space_planning |  | harvest_headcount |  |
| 100 | harvest_headcount | mouths_against_store, cooperative_harvest_gatherings [culture] |  |  |  |
| 104 | new_household_plots | lineage_land_tenure [institutions], field_boundary_markers [institutions] |  |  |  |
| 112 | newcomer_host_season | captive_adoption, guest_host_reciprocity [logistics] |  |  |  |
| 118 | weaning_food_softening | infant_feeding_schedules, food_pounding_mortars [nutrition] |  | pulse_splitting [nutrition] |  |
| 120 | interval_weaning_practice | weaning_food_softening |  | cereal_dehulling [nutrition], food_steaming_vessels [nutrition] |  |
| 122 | breech_repositioning_technique | cord_afterbirth_handling |  |  |  |
| 124 | seasonal_sleeping_arrangements | room_allocation_by_size |  | sleeping_area_rotation |  |
| 132 | newcomer_intermarriage | newcomer_host_season, lineage_exogamy |  |  |  |
| 140 | satellite_hamlets | daughter_hamlets, new_household_plots |  |  | min_settlements: 3 |
| 148 | hearth_hazard_proofing | shared_childcare |  | tool_hazard_awareness [health] |  |
| 150 | sibling_age_gap_norms | birth_spacing_customs, interval_weaning_practice |  |  |  |
| 152 | obstructed_labor_recognition | breech_repositioning_technique |  |  |  |
| 154 | seasonal_storage_sleeping_swap | seasonal_sleeping_arrangements |  | root_cellars [nutrition] |  |
| 162 | famine_refugee_hosting | lean_year_dispersal, newcomer_host_season |  |  | min_settlements: 2 |
| 170 | hearth_counts | harvest_headcount | clay_counting_tokens [knowledge] / knotted_record_systems [knowledge] |  |  |
| 182 | carrying_capacity_awareness | hearth_counts, soil_exhaustion_recognition [nutrition] |  | plot_yield_memory [nutrition] |  |
| 200 | kin_wards | named_descent_lines, new_household_plots |  | public_space_allocation [infrastructure] |  |
| 222 | childhood_illness_recognition | fever_watch_customs, symptom_triage_customs [health] |  | sickness_pattern_memory [health] |  |
| 224 | kin_fostering_networks | lean_year_dispersal, interval_weaning_practice |  | kin_care_widows_orphans |  |
| 226 | hemorrhage_control_herbs | herbal_classification [health], obstructed_labor_recognition |  |  |  |
| 228 | multigenerational_household_norms | elder_care_by_children, room_allocation_by_size |  |  |  |
| 250 | protective_birth_amulets | birth_attendants [health], ancestor_figurines [culture] |  | stamp_seals [knowledge] |  |
| 262 | rural_urban_migration | satellite_hamlets, tributary_villages [institutions] |  | full_time_specialists [labor], craft_quarters [labor] | min_settlements: 3 |
| 268 | childhood_growth_milestones | childhood_illness_recognition |  | solar_year_reckoning [knowledge] |  |
| 270 | grandmaternal_birth_counsel | seasonal_conception_timing, multigenerational_household_norms |  |  |  |
| 272 | trained_midwife_referral | obstructed_labor_recognition, hemorrhage_control_herbs |  | apprentice_healer_rounds [health] |  |
| 274 | elder_quarters_customs | multigenerational_household_norms |  |  |  |
| 345 | people_herd_counts | census_rolls [institutions] |  | harvest_headcount |  |
| 355 | patron_protection | newcomer_host_season, hereditary_chiefly_rank [institutions] |  | famine_refugee_hosting |  |
| 378 | communal_child_supervision_rotas | shared_childcare, kin_wards |  | labor_rotations [labor] |  |
| 380 | marriage_age_norms | coming_of_age_rites [culture], sibling_age_gap_norms |  | solar_year_reckoning [knowledge] |  |
| 382 | household_partition_customs | multigenerational_household_norms, customary_inheritance_shares [institutions] |  |  |  |
| 400 | midwife_apprenticeship_lines | trained_midwife_referral, mentored_task_learning [labor] |  | apprentice_healer_rounds [health] |  |
| 420 | recorded_dowry | bride_wealth_gifts, clay_record_tablets [knowledge] |  | sealed_tablet_contracts [knowledge] |  |
| 440 | household_vital_lists | census_rolls [institutions], clay_record_tablets [knowledge] |  | people_herd_counts |  |
| 452 | birth_stool_bricks | midwife_apprenticeship_lines, mould_made_mudbricks [infrastructure] |  |  |  |
| 462 | ward_residence_lists | kin_wards, household_vital_lists |  |  |  |
| 472 | partible_inheritance | customary_inheritance_shares [institutions], household_partition_customs |  | witnessed_land_sales [institutions] |  |
| 480 | named_year_ages | household_vital_lists, formal_chronicle_keeping [knowledge] |  |  |  |
| 490 | fraternal_joint_estates | partible_inheritance |  |  |  |
| 530 | belonging_oaths | patron_protection, formal_oath_taking [institutions] |  |  |  |
| 540 | wet_nurse_contracts | sealed_tablet_contracts [knowledge], infant_feeding_schedules |  | sealed_family_contracts [institutions] |  |
| 548 | divorce_settlements | recorded_dowry, sealed_family_contracts [institutions] |  |  |  |
| 556 | widow_portion_law | partible_inheritance, written_law_code [institutions] |  | divorce_settlements |  |
| 562 | contraceptive_pessaries | birth_spacing_customs, hive_beekeeping [nutrition], midwife_apprenticeship_lines |  | womens_ailment_texts [health] |  |
| 568 | three_year_nursing | sibling_age_gap_norms, interval_weaning_practice |  | wet_nurse_contracts |  |
| 578 | levirate_marriage | patrilocal_residence, partible_inheritance |  | widow_portion_law |  |
| 590 | frontier_settler_grants | service_land_grants [institutions], new_household_plots |  | border_fortress_chains [security] |  |
