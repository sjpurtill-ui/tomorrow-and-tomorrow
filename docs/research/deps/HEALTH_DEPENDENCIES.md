# Health dependencies

Generated with `docs/research/deps/health.json`. It uses registry ids only. Cross-line ids show their line in brackets. An `environment` list means any one of the listed environments satisfies the gate. In the table, the ids in one `requires_any` group are separated by ` / `, and separate groups are separated by `;`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2 | wound_cleaning |  |  |  |  |
| 3 | sickness_pattern_memory |  |  | seasonal_patterns [ecology] |  |
| 4 | symptom_sharing_customs |  |  | shared_hearth_gatherings [culture] |  |
| 4 | tool_hazard_awareness |  |  | controlled_flaking [production] |  |
| 5 | turbidity_judging |  |  |  |  |
| 6 | delousing | controlled_flaking [production] |  |  |  |
| 8 | herbal_classification | edible_resource_recognition [nutrition] |  |  |  |
| 9 | contagion_avoidance_customs | sickness_pattern_memory, symptom_sharing_customs |  |  |  |
| 10 | splint_and_bracing_technique | cordage [production] |  | wound_cleaning |  |
| 11 | dietary_healing_regimens | herbal_classification |  |  |  |
| 12 | birth_attendants | labor_position_customs [demography], postpartum_seclusion_care [demography] |  |  |  |
| 13 | household_water_boiling | turbidity_judging | basketry [production] / clay_shaping [production] |  |  |
| 14 | snakebite_treatment | wound_cleaning, herbal_classification |  | cordage [production] |  |
| 16 | joint_reduction | splint_and_bracing_technique |  |  |  |
| 18 | clean_water | turbidity_judging | well_siting [infrastructure] / household_water_boiling | animal_taming [nutrition] |  |
| 20 | wound_packing | wound_cleaning, herbal_classification |  |  |  |
| 22 | poultices | herbal_classification, food_pounding_mortars [nutrition] |  |  |  |
| 25 | sweat_baths | hearth_heat_retention [nutrition], framed_construction [infrastructure] |  |  |  |
| 28 | purges_emetics | herbal_classification, dietary_healing_regimens |  |  |  |
| 31 | tooth_drilling | bow_drill_drive [production] |  | wild_honey_smoking [nutrition] |  |
| 34 | boil_lancing | controlled_flaking [production], wound_cleaning |  |  |  |
| 38 | disability_care | kin_care_widows_orphans [demography] |  | splint_and_bracing_technique |  |
| 45 | poppy_analgesia | herbal_classification |  | seed_selection [nutrition] |  |
| 50 | refuse_removal | midden_siting_away_from_water [ecology] |  | sickness_pattern_memory, drainage [infrastructure] |  |
| 55 | trepanation | boil_lancing, wound_packing |  |  |  |
| 62 | crutches | disability_care, splint_and_bracing_technique |  |  |  |
| 66 | heatstroke_care | midday_heat_rest [labor], dietary_healing_regimens |  |  |  |
| 72 | honey_wound_dressing | wild_honey_smoking [nutrition], wound_packing |  |  |  |
| 80 | sickroom_fumigation | contagion_avoidance_customs, herbal_classification | smoking [nutrition] / sweat_baths |  |  |
| 88 | shared_vessel_avoidance | contagion_avoidance_customs |  | pit_firing [production] |  |
| 91 | household_remedy_kits | poultices, purges_emetics |  | pit_firing [production] |  |
| 94 | load_carrying_posture | load_backframes [logistics] |  | carried_load_balancing [logistics], rotating_heavy_tasks [labor] |  |
| 97 | water_source_rotation | clean_water, well_siting [infrastructure] |  |  |  |
| 102 | kohl_eye_paint | mineral_pigment_preparation [production] |  | ore_assaying [production] |  |
| 110 | bracket_fungus_vermifuge | herbal_classification, purges_emetics |  |  |  |
| 117 | sickroom_isolation_practice | sickroom_fumigation, household_space_planning [demography] |  | central_hall_houses [infrastructure] |  |
| 120 | symptom_triage_customs | symptom_sharing_customs, household_remedy_kits |  |  |  |
| 123 | workplace_hazard_awareness | tool_hazard_awareness, kiln_control [production] |  |  |  |
| 126 | greywater_diversion_practice | drainage [infrastructure], refuse_removal |  |  |  |
| 135 | head_shaving_lice | delousing |  | native_copper_working [production] |  |
| 147 | sickbed_distance_norms | sickroom_isolation_practice |  |  |  |
| 150 | recovery_diet_customs | dietary_healing_regimens, mixed_grain_legume_meals [nutrition] |  | maternal_recovery [demography] |  |
| 153 | fire_tending_safeguards | ember_tending [nutrition], hearth_hazard_proofing [demography] |  |  |  |
| 156 | water_container_cleaning_customs | clean_water, pit_firing [production] |  | shared_vessel_avoidance |  |
| 165 | skin_oiling | seed_oil_pressing [production] |  |  |  |
| 175 | traction_fracture_setting | splint_and_bracing_technique, joint_reduction |  | cordage [production] |  |
| 182 | castor_oil_remedies | seed_oil_pressing [production], purges_emetics |  |  |  |
| 190 | healing_chants | household_remedy_kits |  | praise_songs [culture], mnemonic_verse_encoding [knowledge] |  |
| 198 | river_bathing | clean_water |  |  | environment: river |
| 210 | seasonal_well_flushing | lined_well_shafts [infrastructure], water_source_rotation |  |  |  |
| 222 | outbreak_burial_protocols | contagion_avoidance_customs, sickbed_distance_norms |  | mourning_days [culture] |  |
| 226 | burn_treatment_protocols | fire_tending_safeguards, poultices |  |  |  |
| 229 | convalescent_care_rotations | recovery_diet_customs, labor_rotations [labor] |  |  |  |
| 245 | fly_protection | water_container_cleaning_customs, refuse_removal |  | kohl_eye_paint |  |
| 268 | apprentice_healer_rounds | symptom_triage_customs, mentored_task_learning [labor] |  | part_time_specialists [labor] |  |
| 272 | burial_ground_separation | outbreak_burial_protocols |  | memorial_cairn_marking [culture], house_floor_burial [culture] |  |
| 275 | occupational_rest_customs | workplace_hazard_awareness, recovery_days_after_heavy_tasks [labor] |  | festival_rest_days [labor] |  |
| 278 | communal_washing_rotas | river_bathing, labor_rotations [labor] |  |  |  |
| 292 | wound_suturing | bone_needle_sewing [production], wound_packing |  | drop_spindles [production] |  |
| 302 | latrine_siting | greywater_diversion_practice, refuse_pit_rotation [ecology] |  | runoff_grade_reading [infrastructure] |  |
| 308 | water_settling_basins | household_water_boiling | mould_made_mudbricks [infrastructure] / lime_plastered_floors [infrastructure] / bitumen_sealing [infrastructure] |  |  |
| 313 | isolation_practice | sickroom_isolation_practice, outbreak_burial_protocols |  |  |  |
| 318 | woven_dressings | plain_weaving [production], wound_packing |  | fiber_retting [production] |  |
| 325 | protected_wellheads | lined_well_shafts [infrastructure], seasonal_well_flushing |  |  |  |
| 335 | separate_clean_water_storage | water_container_cleaning_customs, water_settling_basins |  |  |  |
| 345 | ash_fat_soap | skin_oiling, communal_washing_rotas |  | lime_burning [production] |  |
| 355 | copper_razors | head_shaving_lice | copper_casting [production] / native_copper_working [production] |  |  |
| 368 | healer_titles | apprentice_healer_rounds |  | healer_specialization_customs, full_time_specialists [labor] |  |
| 378 | healer_specialization_customs | apprentice_healer_rounds, full_time_specialists [labor] |  |  |  |
| 381 | protective_gear_customs | workplace_hazard_awareness | hide_tanning [production] / plain_weaving [production] |  |  |
| 384 | sanitation_inspection_customs | latrine_siting, protected_wellheads, rotating_inspection_duty [knowledge] |  |  |  |
| 387 | quarantine_travel_restrictions | isolation_practice |  | seasonal_news_gathering [knowledge] |  |
| 400 | embalming_anatomy | chamber_tombs [culture], salting_fish_meat [nutrition] |  | trepanation | environment: dry |
| 410 | public_baths | river_bathing, stone_lined_drains [infrastructure] | kiln_fired_bricks [infrastructure] / bitumen_sealing [infrastructure] |  |  |
| 420 | linen_board_splints | splint_and_bracing_technique, woven_dressings |  |  |  |
| 428 | remedy_vehicles | household_remedy_kits, barley_beer [nutrition] |  | hive_beekeeping [nutrition] |  |
| 438 | mineral_eye_salves | kohl_eye_paint | copper_smelting [production] / lead_smelting [production] |  |  |
| 446 | wired_teeth | tooth_drilling, goldsmith_filigree [production] |  |  |  |
| 470 | willow_myrtle_remedies | household_remedy_kits |  | healer_specialization_customs |  |
| 482 | remedy_tablets | written_lore_tablets [knowledge], healer_titles |  |  |  |
| 495 | case_records | remedy_tablets |  |  |  |
| 515 | skin_disease_exclusion | isolation_practice |  | written_law_code [institutions] |  |
| 530 | mad_dog_liability | written_law_code [institutions] |  | blood_price [institutions] |  |
| 540 | womens_ailment_texts | remedy_tablets, midwife_apprenticeship_lines [demography] |  |  |  |
| 550 | healer_fee_law | written_law_code [institutions], healer_titles |  |  |  |
| 565 | injury_manual | case_records, traction_fracture_setting |  |  |  |
| 576 | cautery | bow_drill_drive [production], boil_lancing |  | injury_manual |  |
| 585 | pulse_taking | case_records |  | embalming_anatomy |  |
| 595 | remedy_compendia | remedy_tablets, case_records, formal_archives [knowledge] |  |  |  |
