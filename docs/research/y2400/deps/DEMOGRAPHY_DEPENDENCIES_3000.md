# Demography dependencies: years 2400–3000

Generated from `docs/research/y2400/deps/partials/nhde.json`. It uses ids from `registry_3000.json`, the 1800–2400 registry (`docs/research/y1800/registry_2400.json`, with the dependencies in `docs/research/y1800/deps/partials/`, since `graph_2400.json` is not yet merged), the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), the 600–1200 graph and block, the 0–600 graph and block only. Brackets mark a parent from another line or an earlier block: `[logistics]` is a 2400–3000 id owned by Logistics, `[ecology, 1800-2400]` is a 1800–2400 Ecology id, `[1800-2400]` is a same-line 1800–2400 id. `requires_all` are hard prerequisites; a `requires_any` group needs one member; precedents are soft influences. Every parent is dated at or before its dependent, after the year moves in `partials/nhde_year_adjustments.json`, and no edge links two 2400–3000 items of the same year. The Year column shows the adjusted year. `environment` lists mean any one listed environment satisfies the gate. `contact_required` marks items that inherit the ocean-contact gate from a contact-gated parent (new-world crops, cinchona).

**100 entries, 149 hard edges, 158 precedent edges, 0 requires_any groups.**

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2414 (was 2411) | equal_partible_inheritance | universal_civil_code [institutions] |  | separate_wife_property [1800-2400], strict_family_settlement [1800-2400] |  |
| 2416 | vaccination_mortality_tables | inoculation_mortality_reckoning [1800-2400], cowpox_vaccination [health, 1800-2400] |  | civil_vital_registration [1800-2400] |  |
| 2432 | soldier_family_allowances | class_year_conscription [security] |  | war_orphan_upkeep [600-1200], soldier_marriage_limits [1800-2400] |  |
| 2440 | war_dependants_pensions | war_orphan_upkeep [600-1200], soldier_family_allowances |  | military_pension_treasury [institutions, 600-1200], actuarial_widows_fund [1800-2400] |  |
| 2453 | assisted_emigration | emigrant_recruiting_agents [1800-2400], parish_poor_law [labor, 1800-2400] |  | overseas_settler_colonies [1800-2400], population_pressure_treatise [1800-2400] |  |
| 2459 | age_specific_fertility_rates | population_tables_office [1800-2400] |  | civil_vital_registration [1800-2400], statistical_inference [knowledge] |  |
| 2467 | mortality_table_insurance | age_priced_life_annuities [1200-1800], life_expectancy_tables [1800-2400] |  | actuarial_widows_fund [1800-2400], tontine_annuities [1800-2400] |  |
| 2480 | state_statistical_office | population_tables_office [1800-2400] |  | age_specific_fertility_rates, single_minister_departments [institutions] |  |
| 2496 | colony_land_sale_scheme | colonist_recruiting_agents [1200-1800], assisted_emigration |  | cadastral_tax_survey [institutions, 1800-2400], headright_land_grants [1800-2400] |  |
| 2504 | cause_of_death_tables | civil_vital_registration [1800-2400], infant_death_causes [1800-2400] |  | state_statistical_office, weekly_mortality_bills [1800-2400] |  |
| 2509 | household_schedule_census | decennial_apportionment_census [1800-2400], state_statistical_office |  | house_numbering [infrastructure, 1800-2400], nominal_realm_census [1800-2400] |  |
| 2515 | national_life_tables | life_expectancy_tables [1800-2400], cause_of_death_tables, household_schedule_census |  | register_life_table [1800-2400] |  |
| 2517 | working_mothers_creches | shared_childcare [0-600] |  | mill_hand_workforce [labor, 1800-2400], factory_villages [labor, 1800-2400] |  |
| 2525 | emigrant_passenger_law | ship_passenger_lists [1800-2400], assisted_emigration |  | emigrant_port_licences [1800-2400] |  |
| 2533 | steamship_mass_emigration | ocean_steamship_line [logistics], assisted_emigration |  | emigrant_passenger_law, screw_propeller_ships [logistics] |  |
| 2536 | district_mortality_comparison | national_life_tables |  | sanitary_town_survey [health] |  |
| 2539 | childrens_hospitals | subscription_hospitals [health, 1800-2400] |  | infant_death_causes [1800-2400], hospital_medical_schools [health] |  |
| 2541 | inter_realm_statistical_congress | state_statistical_office |  | great_realm_conference [institutions], household_schedule_census |  |
| 2547 | rubber_sheaths | sulphur_cured_rubber [production], marital_birth_limitation [1800-2400] |  | population_pressure_treatise [1800-2400] |  |
| 2552 | civil_marriage_registrar | registered_marriage [600-1200], civil_vital_registration [1800-2400] |  | universal_civil_code [institutions], civil_divorce [1800-2400] |  |
| 2560 | orphan_boarding_out | orphan_chambers [1200-1800] |  | foundling_nurse_inspection [1800-2400], poor_law_boards [institutions] |  |
| 2565 | homestead_land_grants | headright_land_grants [1800-2400], colony_land_sale_scheme |  | cadastral_tax_survey [institutions, 1800-2400], general_land_code [institutions, 1800-2400] |  |
| 2579 | manufactured_infant_food | feeding_horns [600-1200], condensed_milk [nutrition] |  | wet_nurse_bureau [1800-2400] |  |
| 2587 | residence_naturalisation | craftsman_naturalization [600-1200] |  | steamship_mass_emigration, universal_civil_code [institutions] |  |
| 2595 | family_limitation | marital_birth_limitation [1800-2400], rubber_sheaths |  | population_pressure_treatise [1800-2400] |  |
| 2597 | population_pyramid_charts | household_schedule_census |  | national_life_tables |  |
| 2608 | premature_infant_incubator | childrens_hospitals, radiator_central_heating [infrastructure] |  | precision_thermometry [knowledge, 1800-2400] |  |
| 2613 | antiseptic_maternity_wards | lying_in_hospital [1800-2400], antiseptic_surgery [health] |  | chlorine_handwashing [health] |  |
| 2619 | sutured_surgical_birth | postmortem_cesarean [600-1200], ether_anaesthesia [health], antiseptic_surgery [health] |  | living_mother_caesarean [1800-2400] |  |
| 2627 | raised_consent_age | minimum_marriage_ages [1200-1800] |  | clandestine_marriage_ban [1800-2400], penitentiary_sentences [institutions] |  |
| 2629 | settlement_houses | poor_law_boards [institutions], research_university [knowledge] |  | district_visiting_nurses [health] |  |
| 2637 | household_poverty_surveys | household_schedule_census, settlement_houses |  | labor_statistics_bureau [labor] |  |
| 2643 | room_overcrowding_census | household_schedule_census |  | household_poverty_surveys, building_codes [infrastructure] |  |
| 2645 | immigration_inspection_station | steamship_mass_emigration, residence_naturalisation |  | quarantine_island_station [health, 1800-2400], isolation_fever_hospitals [health] |  |
| 2651 | infant_milk_depots | nursing_mother_diet [600-1200], bottled_town_milk [nutrition] |  | infant_death_causes [1800-2400], manufactured_infant_food |  |
| 2667 | child_growth_records | infant_milk_depots, standard_measures [knowledge, 0-600] |  | population_pyramid_charts, census_age_recording [1800-2400] |  |
| 2667 | infant_mortality_index | cause_of_death_tables, infant_death_causes [1800-2400] |  | district_mortality_comparison |  |
| 2672 | registered_midwives | sworn_town_midwives [1200-1800], medical_practitioner_register [health] |  | manikin_midwife_schools [1800-2400] |  |
| 2680 | newborn_health_visitors | district_visiting_nurses [health], infant_milk_depots |  | infant_mortality_index |  |
| 2688 | child_protection_law | orphan_guardianship [600-1200] |  | juvenile_courts [institutions], settlement_houses |  |
| 2693 | antenatal_clinics | registered_midwives |  | infant_milk_depots |  |
| 2696 | maternity_benefit | worker_sickness_insurance [health] |  | antenatal_clinics |  |
| 2699 | childrens_welfare_bureau | infant_mortality_index, child_protection_law |  | child_growth_records |  |
| 2709 | birth_control_clinics | family_limitation |  | antenatal_clinics, rubber_sheaths |  |
| 2723 | origin_immigration_quotas | immigration_inspection_station, frontier_passport_control [institutions] |  | residence_naturalisation, steamship_mass_emigration |  |
| 2728 | treaty_population_exchange | league_of_realms [institutions] |  | household_schedule_census |  |
| 2733 | widows_orphans_insurance | old_age_pensions [institutions] |  | war_dependants_pensions, mortality_table_insurance |  |
| 2736 | court_adoption_orders | heir_adoption [600-1200] |  | orphan_boarding_out, child_protection_law |  |
| 2744 | demographic_transition_theory | national_life_tables, family_limitation |  | population_pyramid_charts |  |
| 2752 | maternal_death_inquiries | antenatal_clinics |  | cause_of_death_tables |  |
| 2757 | pronatalist_bonuses | marriage_incentive_laws [600-1200] |  | demographic_transition_theory, large_family_tax_relief [1800-2400] |  |
| 2763 | obstetric_flying_squads | stored_citrated_blood [health], series_built_motor_car [logistics] |  | registered_midwives |  |
| 2771 | child_evacuation_schemes | civil_air_defence [security] |  | railway_mobilization [security] |  |
| 2773 | cohort_population_projection | national_life_tables, demographic_transition_theory |  | population_pyramid_charts, statistical_sampling [knowledge] |  |
| 2787 | displaced_persons_camps | treaty_population_exchange |  | refugee_land_settlement [600-1200] |  |
| 2787 | universal_family_allowances | widows_orphans_insurance, maternity_benefit |  | pronatalist_bonuses |  |
| 2789 | birth_cohort_study | cohort_population_projection, child_growth_records |  | infant_mortality_index, punched_card_tabulation [knowledge] |  |
| 2802 | refugee_convention | refugee_land_settlement [600-1200], displaced_persons_camps |  | universal_rights_declaration [institutions] |  |
| 2805 | hospital_birth_norm | antenatal_clinics, national_health_service [health] |  | sulfa_drugs [health] |  |
| 2812 | guest_worker_programmes | origin_immigration_quotas |  | indentured_contract_migration [labor], residence_naturalisation |  |
| 2820 | household_residence_permits | internal_passes [600-1200], household_schedule_census |  | one_party_state [institutions], room_overcrowding_census |  |
| 2825 | oral_contraceptive_pill | birth_control_clinics, randomised_controlled_trial [health] |  | family_limitation, insulin_therapy [health] |  |
| 2825 | retirement_communities | old_age_pensions [institutions] |  | negotiated_occupational_pensions [labor] |  |
| 2828 | newborn_blood_screening | hospital_birth_norm |  | hereditary_double_helix [knowledge] |  |
| 2830 | family_planning_fieldwork | oral_contraceptive_pill |  | birth_control_clinics, demographic_transition_theory |  |
| 2838 | neonatal_intensive_care | premature_infant_incubator, intensive_care_units [health] |  | newborn_health_visitors, blood_bank [health] |  |
| 2840 | rh_disease_prevention | blood_group_typing [health], antenatal_clinics |  | stored_citrated_blood [health], hospital_birth_norm |  |
| 2842 | points_based_immigration | origin_immigration_quotas |  | guest_worker_programmes |  |
| 2845 | continuous_population_register | civil_vital_registration [1800-2400], punched_card_tabulation [knowledge] |  | household_residence_permits |  |
| 2845 | small_family_campaigns | family_planning_fieldwork |  | demographic_transition_theory, television_broadcasting [culture] |  |
| 2848 | no_fault_divorce | civil_divorce_courts [institutions] |  | civil_marriage_registrar, married_women_property [institutions] |  |
| 2850 | equal_birth_status | legitimation_by_marriage [1200-1800] |  | civil_rights_law [institutions] |  |
| 2855 | prenatal_ultrasound | antenatal_clinics, underwater_sound_ranging [security] |  | radio_detection_ranging [security], newborn_blood_screening |  |
| 2858 | legal_pregnancy_termination | birth_control_clinics, aseptic_operating_room [health] |  | family_planning_fieldwork, maternal_death_inquiries |  |
| 2860 | inter_realm_population_conference | inter_realm_statistical_congress, world_assembly_of_realms [institutions] |  | demographic_transition_theory, cohort_population_projection |  |
| 2860 | paid_parental_leave | maternity_benefit |  | universal_family_allowances, equal_pay_law [labor] |  |
| 2870 | in_vitro_fertilisation | cell_culture_methods [knowledge], oral_contraceptive_pill |  | prenatal_ultrasound |  |
| 2870 | skin_to_skin_newborn_care | neonatal_intensive_care |  | newborn_health_visitors, maternal_nursing_campaign [1800-2400] |  |
| 2872 | state_birth_quotas | household_residence_permits, family_planning_fieldwork |  | small_family_campaigns, cohort_population_projection |  |
| 2878 | register_based_census | continuous_population_register |  | relational_databases [knowledge] |  |
| 2885 | fertility_sample_surveys | statistical_sampling [knowledge], age_specific_fertility_rates |  | family_planning_fieldwork, household_poverty_surveys |  |
| 2888 | long_acting_contraception | oral_contraceptive_pill |  | family_planning_fieldwork |  |
| 2888 | surrogacy_contracts | in_vitro_fertilisation |  | court_adoption_orders |  |
| 2898 | registered_partnerships | civil_marriage_registrar |  | no_fault_divorce |  |
| 2900 | preimplantation_testing | in_vitro_fertilisation |  | newborn_blood_screening |  |
| 2910 | sex_selection_ban | prenatal_ultrasound |  | birth_sex_ratio [1800-2400], state_birth_quotas |  |
| 2912 | long_term_care_insurance | old_age_pensions [institutions] |  | national_health_service [health] |  |
| 2922 | emergency_contraception | oral_contraceptive_pill |  | legal_pregnancy_termination, long_acting_contraception |  |
| 2925 | dual_citizenship | residence_naturalisation |  | points_based_immigration, origin_immigration_quotas |  |
| 2938 | dementia_care_units | long_term_care_insurance |  | retirement_communities, community_mental_health [health] |  |
| 2942 | mobile_remittances | cellular_telephony [knowledge] |  | data_modems [knowledge], steamship_mass_emigration |  |
| 2945 | indexed_pension_age | old_age_pensions [institutions] |  | national_life_tables |  |
| 2955 | egg_freezing | in_vitro_fertilisation |  | artificial_cattle_insemination [nutrition], preimplantation_testing |  |
| 2960 | mobile_birth_registration | continuous_population_register, cellular_telephony [knowledge] |  | register_based_census, pocket_networked_computers [knowledge] |  |
| 2962 | genetic_ancestry_testing | human_genome_reading [health] |  | lineage_genealogy_books [1800-2400], preimplantation_testing |  |
| 2975 | excess_death_tracking | cause_of_death_tables |  | pandemic_closure_orders [health], register_based_census, shared_death_cause_list [health] |  |
| 2978 | remote_worker_visas | networked_telework [labor] |  | points_based_immigration |  |
| 2980 | low_fertility_family_package | pronatalist_bonuses |  | paid_parental_leave |  |
| 2990 | climate_managed_resettlement | climate_adaptation_plans [ecology] |  | homestead_land_grants, treaty_population_exchange |  |
| 2998 | artificial_womb_support | neonatal_intensive_care |  | skin_to_skin_newborn_care, in_vitro_fertilisation |  |

## Notes

- **Year move.** `equal_partible_inheritance` 2411 → 2414. It continues Institutions `universal_civil_code`, which is also at 2411.
- **Counting people.** `population_tables_office` → the statistical office → the household-schedule census → national life tables (with the cause-of-death tables) → pyramids, district comparison, the transition theory and cohort projections. The continuous register needs Knowledge `punched_card_tabulation`. The register-based census follows it.
- **Childbirth.** `lying_in_hospital` + Health `antiseptic_surgery` → antiseptic maternity wards. The sutured surgical birth needs `postmortem_cesarean`, Health ether and antisepsis. Infant milk depots need Nutrition `bottled_town_milk`. Registered midwives need Health `medical_practitioner_register`. Hospital birth needs Health `national_health_service`. Neonatal intensive care needs Health `intensive_care_units`. Obstetric flying squads need Health `stored_citrated_blood` and Logistics `series_built_motor_car`, because the blood bank (2765) comes after them.
- **Fertility choice.** Rubber sheaths need Production `sulphur_cured_rubber`. The pill needs birth-control clinics and Health's randomised trial. In-vitro fertilisation needs Knowledge `cell_culture_methods` and the pill (hormone control). Ultrasound needs Security `underwater_sound_ranging`.
- **Migration.** Assisted emigration needs Labor `parish_poor_law`. Steamship emigration needs Logistics `ocean_steamship_line`. Quotas need Institutions `frontier_passport_control`. The population exchange needs Institutions `league_of_realms`. Mobile remittances need Knowledge `cellular_telephony`.
- **Coercive items.** `household_residence_permits` and `state_birth_quotas` are ordinary research gates. Their costs to trust and to the age balance belong to the effects pass.

## Cross-line parents in 2400–3000

Nutrition, Health, Demography and Ecology are mapped in this partial. The other lines are mapped by other agents.

- **Culture:** `television_broadcasting` (2763)
- **Ecology:** `climate_adaptation_plans` (2950)
- **Health:** `antiseptic_surgery` (2579), `aseptic_operating_room` (2629), `blood_bank` (2765), `blood_group_typing` (2669), `chlorine_handwashing` (2525), `community_mental_health` (2832), `district_visiting_nurses` (2557), `ether_anaesthesia` (2523), `hospital_medical_schools` (2467), `human_genome_reading` (2932), `insulin_therapy` (2725), `intensive_care_units` (2808), `isolation_fever_hospitals` (2613), `medical_practitioner_register` (2555), `national_health_service` (2795), `pandemic_closure_orders` (2715), `randomised_controlled_trial` (2795), `sanitary_town_survey` (2512), `shared_death_cause_list` (2648), `stored_citrated_blood` (2712), `sulfa_drugs` (2760), `worker_sickness_insurance` (2621)
- **Infrastructure:** `building_codes` (2590), `radiator_central_heating` (2548)
- **Institutions:** `civil_divorce_courts` (2552), `civil_rights_law` (2835), `frontier_passport_control` (2707), `great_realm_conference` (2440), `juvenile_courts` (2664), `league_of_realms` (2717), `married_women_property` (2619), `old_age_pensions` (2637), `one_party_state` (2712), `penitentiary_sentences` (2453), `poor_law_boards` (2491), `single_minister_departments` (2427), `universal_civil_code` (2411), `universal_rights_declaration` (2795), `world_assembly_of_realms` (2787)
- **Knowledge:** `cell_culture_methods` (2685), `cellular_telephony` (2882), `data_modems` (2825), `hereditary_double_helix` (2808), `pocket_networked_computers` (2942), `punched_card_tabulation` (2640), `relational_databases` (2850), `research_university` (2427), `statistical_inference` (2400), `statistical_sampling` (2667)
- **Labor:** `equal_pay_law` (2835), `indentured_contract_migration` (2500), `labor_statistics_bureau` (2605), `negotiated_occupational_pensions` (2810), `networked_telework` (2915)
- **Logistics:** `ocean_steamship_line` (2501), `screw_propeller_ships` (2509), `series_built_motor_car` (2688)
- **Nutrition:** `artificial_cattle_insemination` (2792), `bottled_town_milk` (2640), `condensed_milk` (2549)
- **Production:** `sulphur_cured_rubber` (2508)
- **Security:** `civil_air_defence` (2767), `class_year_conscription` (2411), `radio_detection_ranging` (2764), `railway_mobilization` (2557), `underwater_sound_ranging` (2716)
