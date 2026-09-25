# Health dependencies: years 2400–3000

Generated from `docs/research/y2400/deps/partials/nhde.json`. It uses ids from `registry_3000.json`, the 1800–2400 registry (`docs/research/y1800/registry_2400.json`, with the dependencies in `docs/research/y1800/deps/partials/`, since `graph_2400.json` is not yet merged), the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), the 600–1200 graph and block, the 0–600 graph and block only. Brackets mark a parent from another line or an earlier block: `[logistics]` is a 2400–3000 id owned by Logistics, `[ecology, 1800-2400]` is a 1800–2400 Ecology id, `[1800-2400]` is a same-line 1800–2400 id. `requires_all` are hard prerequisites; a `requires_any` group needs one member; precedents are soft influences. Every parent is dated at or before its dependent, after the year moves in `partials/nhde_year_adjustments.json`, and no edge links two 2400–3000 items of the same year. The Year column shows the adjusted year. `environment` lists mean any one listed environment satisfies the gate. `contact_required` marks items that inherit the ocean-contact gate from a contact-gated parent (new-world crops, cinchona).

**126 entries, 217 hard edges, 198 precedent edges, 2 requires_any groups.**

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2408 | vaccine_carrier_voyage | cowpox_vaccination [1800-2400], transoceanic_contact_voyages [logistics, 1800-2400] |  | foundling_nurse_inspection [demography, 1800-2400], ocean_victualling [logistics, 1800-2400] | contact_required: True |
| 2411 | slow_sand_filtration | water_settling_basins [0-600], experimental_controls [knowledge, 1800-2400] | one of: lime_mortar [infrastructure, 0-600], sealed_vessels [nutrition, 0-600] | clean_water [0-600], steam_waterworks [infrastructure, 1800-2400] |  |
| 2416 | isolated_poppy_alkaloid | measured_poppy_draughts [600-1200], systematic_chemical_names [knowledge, 1800-2400] |  | opium_tincture [1800-2400], atomic_combining_weights [knowledge] |  |
| 2416 | public_vaccine_stations | cowpox_vaccination [1800-2400] |  | outpatient_dispensaries [1800-2400], mass_shallow_inoculation [1800-2400] |  |
| 2424 | planned_abdominal_operation | organ_seat_pathology [1800-2400], surgeons_college [1800-2400] |  | lateral_lithotomy [1800-2400], screw_tourniquet [1800-2400] |  |
| 2443 | chest_listening_tube | chest_percussion [1800-2400] |  | organ_seat_pathology [1800-2400], university_clinical_wards [1800-2400] |  |
| 2448 | human_blood_transfusion | blood_circulation [1800-2400], surgeons_college [1800-2400] |  | transfusion_ban [1800-2400], planned_abdominal_operation |  |
| 2453 | fever_bark_alkaloid | cinchona_fever_bark [1800-2400], isolated_poppy_alkaloid |  | foxglove_dropsy [1800-2400], fleet_citrus_ration [1800-2400] | contact_required: True |
| 2453 | iodine_goitre_treatment | seaweed_goitre_remedy [1200-1800], systematic_chemical_names [knowledge, 1800-2400] |  | atomic_combining_weights [knowledge] |  |
| 2459 | national_pharmacopoeia | printed_state_pharmacopoeia [1200-1800] |  | isolated_poppy_alkaloid, state_medical_collegium [1800-2400] |  |
| 2467 | croup_tracheotomy | surgeons_college [1800-2400] |  | planned_abdominal_operation, chest_listening_tube |  |
| 2467 | hospital_medical_schools | bedside_teaching [1200-1800], university_clinical_wards [1800-2400] |  | chest_listening_tube, anatomical_wax_models [1800-2400] |  |
| 2485 | epidemic_house_visiting | pestilence_health_boards [1200-1800], medical_police_code [1800-2400] |  | town_fever_houses [1800-2400] |  |
| 2485 | intravenous_saline | human_blood_transfusion, systematic_chemical_names [knowledge, 1800-2400] |  | medical_police_code [1800-2400], transfusion_ban [1800-2400] |  |
| 2488 | anatomy_body_supply_law | public_anatomy_dissection [1200-1800] |  | hospital_medical_schools |  |
| 2493 | numerical_treatment_method | organ_seat_pathology [1800-2400], scurvy_controlled_trial [1800-2400] |  | statistical_inference [knowledge], hospital_admission_books [1200-1800] |  |
| 2507 | dental_surgery_licence | dental_surgery [1800-2400] |  | surgeons_college [1800-2400], medical_faculty_licence [1200-1800] |  |
| 2512 | sanitary_town_survey | civil_vital_registration [demography, 1800-2400], numerical_treatment_method |  | cause_of_death_tables [demography], back_to_back_terraces [infrastructure], medical_police_code [1800-2400] |  |
| 2523 | ether_anaesthesia | mineral_acid_distillation [knowledge, 1200-1800], surgeons_college [1800-2400] |  | isolated_airs_chemistry [knowledge, 1800-2400], planned_abdominal_operation, dental_surgery_licence |  |
| 2525 | chlorine_handwashing | lying_in_hospital [demography, 1800-2400], chlorine_bleaching [production, 1800-2400] |  | numerical_treatment_method, childbed_death_counts [demography, 1800-2400] |  |
| 2525 | chloroform_anaesthesia | ether_anaesthesia |  | chlorine_bleaching [production, 1800-2400] |  |
| 2528 | central_board_of_health | pestilence_health_boards [1200-1800], sanitary_town_survey |  | single_minister_departments [institutions], poor_law_boards [institutions] |  |
| 2533 | water_service_inspections | case_records [0-600], standard_measures [knowledge, 0-600] | one of: protected_wellheads [0-600], rainwater_cisterns [infrastructure, 0-600] | slow_sand_filtration, steam_pumped_waterworks [infrastructure] |  |
| 2541 | compulsory_infant_vaccination | cowpox_vaccination [1800-2400], public_vaccine_stations, civil_vital_registration [demography, 1800-2400] |  | preventive_inoculation [1800-2400], vaccination_mortality_tables [demography] |  |
| 2541 | hypodermic_syringe | isolated_poppy_alkaloid |  | intravenous_saline, plunger_pressed_glass [production] |  |
| 2544 | contagion_mapping | cause_of_death_tables [demography], sanitary_town_survey |  | house_numbering [infrastructure, 1800-2400], regional_maps [knowledge, 0-600] |  |
| 2544 | nursing_care_organization | clinical_observation_rounds [600-1200], crew_handoffs [labor, 0-600] |  | charity_nursing_sisters [1800-2400], army_field_hospitals [1800-2400], subscription_hospitals [1800-2400] |  |
| 2547 | medical_officer_of_health | central_board_of_health |  | contagion_mapping, cause_of_death_tables [demography] |  |
| 2555 | cellular_pathology | cell_theory [knowledge], organ_seat_pathology [1800-2400] |  | compound_microscopy [knowledge], tissue_histology [knowledge] |  |
| 2555 | medical_practitioner_register | medical_faculty_licence [1200-1800] |  | hospital_medical_schools, surgeons_college [1800-2400] |  |
| 2557 | district_visiting_nurses | nursing_care_organization |  | charity_nursing_sisters [1800-2400], outpatient_dispensaries [1800-2400] |  |
| 2560 | casualty_collection_posts | litter_bearer_drill [1800-2400] |  | army_field_hospitals [1800-2400] |  |
| 2560 | field_aid_stations | battlefield_medicine [600-1200], army_field_hospitals [1800-2400] |  | litter_bearer_drill [1800-2400], field_surgery_handbook [1800-2400] |  |
| 2560 | nurse_training_school | nursing_care_organization |  | hospital_medical_schools |  |
| 2563 (was 2560) | casualty_transfer_records | casualty_collection_posts, hospital_admission_books [1200-1800] |  | field_aid_stations |  |
| 2563 (was 2560) | triage_registers | field_aid_stations, case_records [0-600] |  | casualty_collection_posts |  |
| 2571 | evacuation_relays | casualty_transfer_records, public_steam_railway [logistics] |  | railway_mobilization [security], triage_registers |  |
| 2571 | neutral_wounded_convention | field_aid_stations, great_realm_conference [institutions] |  | field_army_war_rules [security], nursing_care_organization |  |
| 2573 | pavilion_ward_hospitals | nursing_care_organization, sanitary_town_survey |  | ventilator_bellows [1800-2400], iron_roof_trusses [infrastructure] |  |
| 2579 | antiseptic_surgery | coal_light_oil_recovery [production], microbial_observation [knowledge] |  | gentle_heat_treatment [nutrition], ether_anaesthesia, nursing_care_organization |  |
| 2608 | germ_theory_of_disease | microbial_isolation_methods [knowledge] |  | gentle_heat_treatment [nutrition], contagion_mapping, cellular_pathology |  |
| 2613 | isolation_fever_hospitals | town_fever_houses [1800-2400] |  | germ_theory_of_disease, pavilion_ward_hospitals, smallpox_hospital [1800-2400] |  |
| 2619 | consumption_germ_identified | germ_theory_of_disease, biological_staining [knowledge] |  | cellular_pathology |  |
| 2621 | worker_sickness_insurance | registered_friendly_societies [labor, 1800-2400], medical_practitioner_register |  | mortality_table_insurance [demography], employer_liability_law [labor] |  |
| 2624 | local_anaesthesia | hypodermic_syringe, isolated_poppy_alkaloid |  | ether_anaesthesia |  |
| 2627 | attenuated_laboratory_vaccine | compulsory_infant_vaccination, germ_theory_of_disease |  | microbial_isolation_methods [knowledge] |  |
| 2629 | aseptic_operating_room | antiseptic_surgery, instrument_sterilization [knowledge] |  | aseptic_laboratory_practice [knowledge], germ_theory_of_disease |  |
| 2635 | consumption_sanatoria | consumption_germ_identified |  | spa_town_physicians [1800-2400], isolation_fever_hospitals |  |
| 2637 | disease_notification_law | medical_officer_of_health, germ_theory_of_disease |  | isolation_fever_hospitals |  |
| 2643 | diphtheria_antitoxin | attenuated_laboratory_vaccine, hypodermic_syringe |  | croup_tracheotomy, microbial_isolation_methods [knowledge] |  |
| 2648 | port_sanitary_inspection | arrival_isolation_period [1200-1800], germ_theory_of_disease |  | disease_notification_law, isolation_fever_hospitals |  |
| 2648 | shared_death_cause_list | cause_of_death_tables [demography], inter_realm_statistical_congress [demography] |  | germ_theory_of_disease |  |
| 2653 | bone_shadow_imaging | electromagnetic_induction [knowledge], fixed_light_images [knowledge] |  | glass_tube_drawing [production], vacuum_pumps [knowledge, 1800-2400] |  |
| 2659 | enteric_fever_vaccine | attenuated_laboratory_vaccine |  | diphtheria_antitoxin, field_aid_stations |  |
| 2659 | mosquito_fever_vector | germ_theory_of_disease, biological_staining [knowledge] |  | marsh_fever_drainage [600-1200] |  |
| 2664 | synthetic_willow_analgesic | coal_tar_dyes [production], coal_light_oil_recovery [production] |  | isolated_poppy_alkaloid |  |
| 2669 | blood_group_typing | human_blood_transfusion, diphtheria_antitoxin |  | cellular_pathology |  |
| 2669 | mosquito_control_brigades | mosquito_fever_vector |  | marsh_fever_drainage [600-1200], coal_light_oil_recovery [production] |  |
| 2672 | talking_cure | moral_treatment_asylums [1800-2400] |  | hospital_madness_wards [1200-1800] |  |
| 2680 | radium_tumour_therapy | radiation_measurement [knowledge], bone_shadow_imaging |  | cellular_pathology |  |
| 2685 | school_medical_inspection | compulsory_elementary_schooling [knowledge], medical_officer_of_health |  | school_meals [nutrition] |  |
| 2688 | water_chlorination | slow_sand_filtration, chloralkali_cells [production] |  | germ_theory_of_disease, water_service_inspections |  |
| 2691 | targeted_arsenical_drug | coal_tar_dyes [production], germ_theory_of_disease |  | biological_staining [knowledge] |  |
| 2693 | laboratory_medical_schools | hospital_medical_schools, germ_theory_of_disease |  | research_university [knowledge], industrial_research_laboratory [knowledge] |  |
| 2696 | drug_label_purity_law | apothecary_separation [1200-1800], national_pharmacopoeia |  | food_adulteration_law [nutrition] |  |
| 2704 | medical_resupply_packing | field_aid_stations |  | national_pharmacopoeia, evacuation_relays, antiseptic_surgery |  |
| 2712 | convalescent_duty_reviews | casualty_transfer_records |  | medical_resupply_packing, nursing_care_organization |  |
| 2712 | reconstructive_surgery | aseptic_operating_room, arm_flap_nose_repair [1800-2400] |  | bone_shadow_imaging |  |
| 2712 | stored_citrated_blood | blood_group_typing, mechanical_refrigeration [infrastructure] |  | field_aid_stations |  |
| 2715 | pandemic_closure_orders | disease_notification_law |  | port_sanitary_inspection |  |
| 2725 | consumption_vaccine | consumption_germ_identified, attenuated_laboratory_vaccine |  | consumption_sanatoria |  |
| 2725 | insulin_therapy | hypodermic_syringe, laboratory_medical_schools |  | enzyme_catalysis [production] |  |
| 2744 | hospital_prepayment_plans | worker_sickness_insurance |  | subscription_hospitals [1800-2400] |  |
| 2752 | cancer_registries | radium_tumour_therapy, cause_of_death_tables [demography] |  | aseptic_operating_room |  |
| 2760 | sulfa_drugs | targeted_arsenical_drug, coal_tar_dyes [production] |  | aromatic_amine_hydrogenation [production] |  |
| 2765 | blood_bank | stored_citrated_blood |  | hospital_prepayment_plans |  |
| 2781 | mould_broth_antibiotic | microbial_isolation_methods [knowledge], fermentation_starter_cultures [nutrition] |  | sulfa_drugs, microbial_growth_measurement [knowledge] |  |
| 2784 | consumption_antibiotic | mould_broth_antibiotic, consumption_germ_identified |  | consumption_vaccine |  |
| 2787 | water_fluoridation | water_chlorination |  | dental_surgery_licence |  |
| 2790 (was 2787) | residual_house_spraying | synthetic_crop_insecticide [nutrition], mosquito_control_brigades |  | mosquito_fever_vector |  |
| 2792 | artificial_kidney_dialysis | intravenous_saline, regenerated_cellulose_fibre [production] |  | blood_group_typing |  |
| 2795 | inter_realm_health_council | world_assembly_of_realms [institutions], shared_death_cause_list |  | neutral_wounded_convention, port_sanitary_inspection |  |
| 2795 | national_health_service | worker_sickness_insurance, welfare_state [institutions] |  | hospital_prepayment_plans |  |
| 2795 | randomised_controlled_trial | numerical_treatment_method, statistical_sampling [knowledge] |  | consumption_antibiotic |  |
| 2800 | tobacco_cancer_evidence | cancer_registries, statistical_sampling [knowledge] |  | randomised_controlled_trial |  |
| 2805 | antipsychotic_drugs | moral_treatment_asylums [1800-2400], aromatic_amine_hydrogenation [production] |  | talking_cure, sulfa_drugs |  |
| 2805 | combination_consumption_therapy | consumption_antibiotic, randomised_controlled_trial |  | consumption_sanatoria, consumption_vaccine |  |
| 2808 | heart_lung_machine | blood_bank, aseptic_operating_room |  | artificial_kidney_dialysis |  |
| 2808 | intensive_care_units | nursing_care_organization, blood_bank |  | ventilator_bellows [1800-2400], transistor_amplifiers [production] |  |
| 2810 | organ_transplant | artificial_kidney_dialysis, aseptic_operating_room |  | blood_group_typing |  |
| 2812 | paralysis_virus_vaccine | cell_culture_methods [knowledge], attenuated_laboratory_vaccine |  | randomised_controlled_trial |  |
| 2825 | cardiac_resuscitation | intensive_care_units, electrical_measurement [knowledge] |  | transistor_amplifiers [production] |  |
| 2830 | drug_efficacy_approval | drug_label_purity_law, randomised_controlled_trial |  | national_pharmacopoeia, sulfa_drugs |  |
| 2832 | community_mental_health | antipsychotic_drugs |  | national_health_service |  |
| 2832 | measles_vaccine | paralysis_virus_vaccine |  | cell_culture_methods [knowledge] |  |
| 2835 | tobacco_control_laws | tobacco_cancer_evidence |  | drug_label_purity_law |  |
| 2842 | hospice_care | district_visiting_nurses |  | cancer_registries, isolated_poppy_alkaloid |  |
| 2845 | oral_rehydration_salts | intravenous_saline, randomised_controlled_trial |  | inter_realm_health_council |  |
| 2852 | body_slice_scanner | bone_shadow_imaging, stored_program_control [production] |  | radiation_measurement [knowledge] |  |
| 2860 | expanded_immunisation_program | measles_vaccine, compulsory_infant_vaccination |  | inter_realm_health_council |  |
| 2870 | primary_health_care | district_visiting_nurses, inter_realm_health_council |  | oral_rehydration_salts |  |
| 2872 | smallpox_eradication | cowpox_vaccination [1800-2400], inter_realm_health_council |  | expanded_immunisation_program, disease_notification_law |  |
| 2875 | magnetic_resonance_imaging | nuclear_magnetic_resonance_spectroscopy [production], body_slice_scanner |  | radiation_measurement [knowledge], stored_program_control [production] |  |
| 2888 | immune_virus_blood_test | blood_bank, cell_culture_methods [knowledge] |  | blood_group_typing, inter_realm_health_council |  |
| 2890 | recombinant_vaccine | hereditary_double_helix [knowledge], fermentation_starter_cultures [nutrition] |  | cell_culture_methods [knowledge], enzyme_catalysis [production] |  |
| 2892 | cholesterol_lowering_drugs | randomised_controlled_trial, mould_broth_antibiotic |  | tobacco_cancer_evidence, national_dietary_goals [nutrition] |  |
| 2905 | systematic_review_medicine | randomised_controlled_trial |  | desk_computers [knowledge] |  |
| 2910 | insecticide_bed_nets | residual_house_spraying, polyamide_synthetic_fibre [production] |  | mosquito_control_brigades, primary_health_care |  |
| 2915 | combination_antiviral_therapy | immune_virus_blood_test, drug_efficacy_approval |  | combination_consumption_therapy |  |
| 2918 | monoclonal_antibody_drugs | cell_culture_methods [knowledge], recombinant_vaccine |  | blood_group_typing |  |
| 2925 | antibiotic_stewardship | mould_broth_antibiotic, inter_realm_health_council |  | combination_consumption_therapy |  |
| 2928 | artemisinin_combination_therapy | randomised_controlled_trial, fever_bark_alkaloid |  | residual_house_spraying |  |
| 2932 | human_genome_reading | hereditary_double_helix [knowledge], desk_computers [knowledge] |  | relational_databases [knowledge], heredity_experiments [nutrition] |  |
| 2932 | tobacco_control_treaty | tobacco_control_laws, inter_realm_health_council |  | systematic_review_medicine |  |
| 2938 | inter_realm_health_rules | inter_realm_health_council |  | pandemic_closure_orders, port_sanitary_inspection |  |
| 2945 | electronic_health_records | relational_databases [knowledge], national_health_service |  | world_hypertext_web [knowledge] |  |
| 2960 | immune_checkpoint_therapy | monoclonal_antibody_drugs |  | cancer_registries |  |
| 2968 | engineered_immune_cell_therapy | human_genome_reading, cell_culture_methods [knowledge] |  | immune_checkpoint_therapy, monoclonal_antibody_drugs |  |
| 2975 | messenger_molecule_vaccine | recombinant_vaccine, human_genome_reading |  | monoclonal_antibody_drugs, pandemic_closure_orders |  |
| 2975 | pandemic_test_trace_orders | pandemic_closure_orders |  | pocket_networked_computers [knowledge], inter_realm_health_rules |  |
| 2978 | malaria_vaccine | recombinant_vaccine |  | artemisinin_combination_therapy |  |
| 2982 | gene_edited_blood_cure | human_genome_reading, engineered_immune_cell_therapy |  | blood_bank, gene_edited_crops [nutrition] |  |
| 2988 | machine_read_diagnostics | deep_learning_networks [knowledge], body_slice_scanner |  | electronic_health_records |  |
| 2992 | gut_hormone_drugs | insulin_therapy, recombinant_vaccine |  | drug_efficacy_approval |  |
| 2995 | genome_guided_prescribing | human_genome_reading |  | electronic_health_records |  |
| 3000 | broad_virus_family_vaccines | messenger_molecule_vaccine |  | inter_realm_health_rules |  |

## Notes

- **Catalog gates.** `slow_sand_filtration`, `water_service_inspections` and `nursing_care_organization` keep their declared gates and any-groups. `contagion_mapping` and the seven field-medicine ids have no entry in `*_knowledge.gd`. Their gates here come from the chains in the list.
- **Year moves (inside their bands).** `casualty_transfer_records` and `triage_registers` 2560 → 2563, after the collection posts and aid stations (2560). `residual_house_spraying` 2787 → 2790, after Nutrition `synthetic_crop_insecticide` (2787).
- **Vaccines.** `cowpox_vaccination` → carrier voyage (`contact_required`) and public stations → compulsory infant vaccination (with Demography's `civil_vital_registration`) → the laboratory-weakened vaccine (with germ theory) → diphtheria antitoxin → the typhoid and consumption vaccines. Cell-culture vaccines (paralysis, then measles) need Knowledge `cell_culture_methods`. The recombinant vaccine needs `hereditary_double_helix` and fermentation starters. The messenger-molecule vaccine needs it and the read genome.
- **Public health.** The sanitary survey (with Demography's registration) → the central board → the medical officer → notification law → pandemic orders → test, trace and lockdown. Chlorination needs Production `chloralkali_cells`. The inter-realm council needs Institutions `world_assembly_of_realms`.
- **Surgery.** Ether needs Knowledge `mineral_acid_distillation`. Antiseptic surgery needs Production `coal_light_oil_recovery` (carbolic) and Knowledge `microbial_observation`. The aseptic room needs Knowledge `instrument_sterilization`. Bone-shadow imaging needs Knowledge `electromagnetic_induction` and `fixed_light_images`, because no discharge-tube row exists before 2653. The body-slice scanner needs Production `stored_program_control`. Magnetic resonance needs Production `nuclear_magnetic_resonance_spectroscopy`.
- **Drugs.** Alkaloids need `systematic_chemical_names`. The synthetic analgesic, arsenical and sulfa drugs need Production `coal_tar_dyes`. The mould-broth antibiotic needs Knowledge `microbial_isolation_methods` and Nutrition `fermentation_starter_cultures`. `fever_bark_alkaloid` inherits `contact_required` from `cinchona_fever_bark`, and `artemisinin_combination_therapy` inherits it from `fever_bark_alkaloid`.
- **Field medicine (shared: Security).** `battlefield_medicine`, `army_field_hospitals` and `litter_bearer_drill` → posts and aid stations (2560) → transfer records and triage (2563) → evacuation relays (with Logistics `public_steam_railway`) → packed resupply and convalescent reviews. These change what generals can sustain. No health item gives any unit or general a new weapon.
- **Evidence.** The numerical method → the randomised trial (with Knowledge `statistical_sampling`) → tobacco evidence, efficacy approval, combination therapy, oral rehydration and pooled reviews.

## Cross-line parents in 2400–3000

Nutrition, Health, Demography and Ecology are mapped in this partial. The other lines are mapped by other agents.

- **Demography:** `cause_of_death_tables` (2504), `inter_realm_statistical_congress` (2541), `mortality_table_insurance` (2467), `vaccination_mortality_tables` (2416)
- **Infrastructure:** `back_to_back_terraces` (2410), `iron_roof_trusses` (2430), `mechanical_refrigeration` (2536), `steam_pumped_waterworks` (2418)
- **Institutions:** `great_realm_conference` (2440), `poor_law_boards` (2491), `single_minister_departments` (2427), `welfare_state` (2789), `world_assembly_of_realms` (2787)
- **Knowledge:** `aseptic_laboratory_practice` (2613), `atomic_combining_weights` (2408), `biological_staining` (2555), `cell_culture_methods` (2685), `cell_theory` (2504), `compound_microscopy` (2480), `compulsory_elementary_schooling` (2587), `deep_learning_networks` (2955), `desk_computers` (2868), `electrical_measurement` (2453), `electromagnetic_induction` (2483), `fixed_light_images` (2504), `hereditary_double_helix` (2808), `industrial_research_laboratory` (2603), `instrument_sterilization` (2603), `microbial_growth_measurement` (2667), `microbial_isolation_methods` (2603), `microbial_observation` (2480), `pocket_networked_computers` (2942), `radiation_measurement` (2659), `relational_databases` (2850), `research_university` (2427), `statistical_inference` (2400), `statistical_sampling` (2667), `tissue_histology` (2504), `world_hypertext_web` (2902)
- **Labor:** `employer_liability_law` (2613)
- **Logistics:** `public_steam_railway` (2467)
- **Nutrition:** `fermentation_starter_cultures` (2552), `food_adulteration_law` (2600), `gene_edited_crops` (2970), `gentle_heat_treatment` (2571), `heredity_experiments` (2683), `national_dietary_goals` (2868), `school_meals` (2683), `synthetic_crop_insecticide` (2787)
- **Production:** `aromatic_amine_hydrogenation` (2701), `chloralkali_cells` (2645), `coal_light_oil_recovery` (2533), `coal_tar_dyes` (2554), `enzyme_catalysis` (2660), `glass_tube_drawing` (2610), `nuclear_magnetic_resonance_spectroscopy` (2790), `plunger_pressed_glass` (2467), `polyamide_synthetic_fibre` (2764), `regenerated_cellulose_fibre` (2650), `stored_program_control` (2838), `transistor_amplifiers` (2807)
- **Security:** `field_army_war_rules` (2569), `railway_mobilization` (2557)
