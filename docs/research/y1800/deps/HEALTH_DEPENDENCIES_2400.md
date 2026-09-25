# Health dependencies: years 1800–2400

Generated from `docs/research/y1800/deps/partials/nhde.json`. It uses ids from `registry_2400.json`, the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), the 600–1200 graph (`docs/research/y600/deps/graph_1200.json`), the 0–600 graph and the game's baked blocks only. Brackets mark a parent from another line or an earlier block: `[logistics]` is a 1800–2400 id owned by Logistics, `[ecology, 1200-1800]` is a 1200–1800 Ecology id, `[0-600]` is a same-line 0–600 id. An `environment` list means any one of the listed environments satisfies the gate. `requires_all` are hard prerequisites dated at or before the dependent (no edge links two 1800–2400 items of the same year); `requires_any` groups need one member; precedents are soft influences, also dated at or before it. `contact_required` is reserved in this block for items that need ocean contact through Logistics `transoceanic_contact_voyages` (1912), directly or through a contact-gated parent. (regional) items are gated by `environment` or inherit a regional parent from 1200–1800, which already carries `contact_required`. No year moves are proposed for this line (`partials/nhde_year_adjustments.json` is empty).

**86 entries, 146 hard edges, 154 precedent edges, 0 requires_any groups.**

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1812 | council_plague_treatises | plague_advice_tracts [1200-1800] |  | pestilence_physicians [1200-1800], pestilence_health_boards [1200-1800] |  |
| 1822 | forty_day_quarantine | arrival_isolation_period [1200-1800] |  | pestilence_gate_watch [1200-1800], pestilence_health_boards [1200-1800] |  |
| 1832 | health_passes | forty_day_quarantine, pestilence_gate_watch [1200-1800] |  | internal_passes [demography, 600-1200], sealed_travel_passes [institutions, 0-600] |  |
| 1845 | quarantine_island_station | forty_day_quarantine |  | leper_inspection_panels [1200-1800], ward_hospitals [1200-1800] | environment: coast, river |
| 1858 | leper_house_conversion | leper_inspection_panels [1200-1800] |  | quarantine_island_station, pestilence_health_boards [1200-1800] |  |
| 1866 | pestilence_market_seals | spoiled_food_condemnation [1200-1800], pestilence_health_boards [1200-1800] |  | plague_bedding_burning [1200-1800] |  |
| 1875 | concave_spectacles | reading_spectacles [1200-1800], optical_lenses [knowledge, 1200-1800] |  | spun_crown_panes [production, 1200-1800] |  |
| 1884 | incurables_hospital | nursing_brotherhoods [1200-1800], ward_hospitals [1200-1800] |  | endowed_hospital_beds [1200-1800] |  |
| 1893 | printed_plague_regimens | council_plague_treatises, town_printing_houses [knowledge] |  | printed_broadsides [knowledge] |  |
| 1898 | printed_dissection_manual | public_anatomy_dissection [1200-1800], screw_press_printing [knowledge] |  | illustrated_surgery_treatise [1200-1800] |  |
| 1904 | sweating_fever_record | epidemic_chronicles [600-1200] |  | pestilence_physicians [1200-1800], disease_causes_treatise [1200-1800] |  |
| 1906 | standing_health_magistracy | pestilence_health_boards [1200-1800] |  | council_plague_treatises, forty_day_quarantine, specialized_royal_councils [institutions] |  |
| 1912 | field_surgery_handbook | school_surgery_manual [1200-1800], town_printing_houses [knowledge] |  | hand_gun_tubes [security], dry_wound_dressing [1200-1800] |  |
| 1916 | great_pox_recognition | mercury_ointment [1200-1800], transoceanic_contact_voyages [logistics] |  | contact_contagion [1200-1800], itch_mite_removal [1200-1800] | contact_required: True |
| 1921 | ship_bills_of_health | health_passes, forty_day_quarantine |  | merchant_bale_marks [logistics, 1200-1800], quarantine_island_station |  |
| 1928 | bathhouse_closures | great_pox_recognition |  | domed_steam_baths [infrastructure, 1200-1800], street_filth_ordinances [1200-1800] | contact_required: True |
| 1932 | college_of_physicians | medical_faculty_licence [1200-1800], physician_licensing_exam [1200-1800] |  | standing_health_magistracy, craft_guilds [institutions, 1200-1800] |  |
| 1936 | guaiac_pox_remedy | great_pox_recognition |  | fixed_formula_decoctions [600-1200] | contact_required: True |
| 1942 | from_life_printed_herbals | illustrated_herbals [1200-1800], hand_relief_printing [knowledge] |  | burin_engraving [knowledge], printed_state_pharmacopoeia [1200-1800] |  |
| 1948 | gentle_gunshot_dressing | dry_wound_dressing [1200-1800], field_surgery_handbook |  | powder_artillery [security], matchlock_drill [security] |  |
| 1952 | dissection_anatomy_atlas | public_anatomy_dissection [1200-1800], printed_dissection_manual |  | burin_engraving [knowledge], single_point_perspective_painting [culture], mirror_grid_perspective [knowledge] |  |
| 1954 | faculty_physic_garden | from_life_printed_herbals, walled_kitchen_gardens [nutrition, 1200-1800] |  | foreign_plant_gardens [ecology, 600-1200], medical_faculty_licence [1200-1800] |  |
| 1956 | contagion_seeds_treatise | contact_contagion [1200-1800], council_plague_treatises |  | great_pox_recognition, plague_advice_tracts [1200-1800] |  |
| 1959 | spotted_fever_distinction | contagion_seeds_treatise |  | pox_measles_distinction [1200-1800], sweating_fever_record |  |
| 1962 | printed_city_pharmacopoeia | town_antidotary [1200-1800], town_printing_houses [knowledge] |  | printed_state_pharmacopoeia [1200-1800], hospital_formulary [1200-1800] |  |
| 1966 | chemical_medicine_school | distilled_herb_waters [1200-1800], mineral_acid_distillation [knowledge, 1200-1800] |  | chemical_distillation [knowledge, 1200-1800], mercury_ointment [1200-1800] |  |
| 1970 | amputation_ligature | catgut_sutures [1200-1800], gentle_gunshot_dressing |  | graded_cautery_irons [1200-1800] |  |
| 1974 | jointed_artificial_limbs | amputation_ligature |  | mainspring_fusee_clocks [production], articulated_plate_armor [security] |  |
| 1983 | army_field_hospitals | military_hospitals [600-1200], field_surgery_handbook |  | pike_and_shot_regiment [security], wheeled_siege_train [security] |  |
| 1990 | corpse_searchers | health_office_death_registers [demography], standing_health_magistracy |  | inquest_handbook [1200-1800] |  |
| 1995 | tiered_anatomy_theatre | dissection_anatomy_atlas |  | public_playhouses [culture], ruler_founded_universities [knowledge] |  |
| 1998 | arm_flap_nose_repair | skin_flap_repair [600-1200], dissection_anatomy_atlas |  | catgut_sutures [1200-1800] |  |
| 2002 | folk_variolation | pox_measles_distinction [1200-1800] |  | childhood_disease_book [demography, 1200-1800], contact_contagion [1200-1800] |  |
| 2006 | lemon_juice_scurvy | citrus_orchards [nutrition, 1200-1800], ocean_victualling [logistics] |  | sickroom_diet_books [1200-1800] |  |
| 2016 | shut_up_plague_houses | standing_health_magistracy, parish_constables [security] |  | plague_bedding_burning [1200-1800], corpse_searchers |  |
| 2030 | sea_surgeons_chest | field_surgery_handbook, ocean_victualling [logistics] |  | lemon_juice_scurvy, travelling_dispensaries [1200-1800] |  |
| 2036 | chartered_apothecary_company | apothecary_separation [1200-1800], printed_city_pharmacopoeia |  | craft_guilds [institutions, 1200-1800], chemical_medicine_school |  |
| 2056 | blood_circulation | pulmonary_transit [1200-1800], dissection_anatomy_atlas |  | experimental_vivisection [600-1200], inductive_method_program [knowledge], measured_kinematics [knowledge] |  |
| 2066 | charity_nursing_sisters | nursing_brotherhoods [1200-1800] |  | incurables_hospital, parish_poor_law [labor] |  |
| 2074 | university_clinical_wards | bedside_teaching [1200-1800], ward_hospitals [1200-1800] |  | tiered_anatomy_theatre, college_of_physicians |  |
| 2080 | cinchona_fever_bark | transoceanic_contact_voyages [logistics] |  | marsh_fever_drainage [600-1200], periodic_fever_classes [600-1200], compared_treatment_groups [1200-1800] | contact_required: True |
| 2112 | general_confinement_hospital | ward_hospitals [1200-1800], correction_workhouses [labor] |  | aged_almshouses [1200-1800], parish_poor_law [labor], hospital_madness_wards [1200-1800] |  |
| 2120 | opium_tincture | measured_poppy_draughts [600-1200], distilled_spirits [nutrition, 1200-1800] |  | chemical_medicine_school |  |
| 2124 | capillary_observation | blood_circulation, two_lens_tube_microscope [knowledge] |  | lens_centering [knowledge] |  |
| 2136 | transfusion_ban | blood_circulation |  | chartered_experimental_society [knowledge] |  |
| 2140 | invalid_soldiers_hospital | army_field_hospitals, crown_standing_army [security] |  | general_confinement_hospital |  |
| 2146 | epidemic_season_records | case_records [0-600], epidemic_chronicles [600-1200] |  | weekly_mortality_bills [demography], daily_weather_diaries [ecology, 1200-1800] |  |
| 2152 | ergot_cause_identified | burning_sickness_hospitals [1200-1800], rye_cultivation [nutrition, 600-1200] |  | epidemic_season_records, compared_treatment_groups [1200-1800] |  |
| 2158 | regimental_surgeons | army_field_hospitals, crown_standing_army [security] |  | invalid_soldiers_hospital, regimental_uniforms [security] |  |
| 2166 | state_medical_collegium | college_of_physicians, chartered_apothecary_company |  | standing_health_magistracy, war_ministry_bureaus [institutions], sworn_town_midwives [demography, 1200-1800] |  |
| 2172 | ipecac_flux_remedy | transoceanic_contact_voyages [logistics] |  | cinchona_fever_bark | contact_required: True |
| 2176 | medical_case_journals | experimental_protocol_publication [knowledge] |  | printed_weekly_news [knowledge], case_records [0-600] |  |
| 2182 | spa_town_physicians | mineral_spring_bathing [600-1200] |  | college_of_physicians, passenger_coach [logistics] |  |
| 2200 | trade_diseases_treatise | case_records [0-600], medical_case_journals |  | mining_ordinances [labor], mercury_amalgam_poisoning [ecology] |  |
| 2214 | pulse_watch | mainspring_fusee_clocks [production], timed_pulse [600-1200] |  | pendulum_regulated_clock [knowledge], medical_case_journals |  |
| 2236 | screw_tourniquet | amputation_ligature, screw_tap_and_die [production] |  | regimental_surgeons |  |
| 2240 | frontier_sanitary_cordon | pestilence_gate_watch [1200-1800], quarantine_island_station |  | fortress_frontier_belt [security], health_passes |  |
| 2244 | variolation_trials | folk_variolation, compared_treatment_groups [1200-1800] |  | chartered_experimental_society [knowledge], medical_case_journals |  |
| 2250 | subscription_hospitals | ward_hospitals [1200-1800], joint_stock_company [institutions] |  | general_confinement_hospital, university_clinical_wards |  |
| 2254 | lateral_lithotomy | bladder_stone_cutting [600-1200], dissection_anatomy_atlas |  | tiered_anatomy_theatre |  |
| 2258 | dental_surgery | gold_band_dentures [600-1200], tooth_drilling [0-600] |  | surgeons_guild [1200-1800], screw_cutting_lathe [production] |  |
| 2268 | anatomical_wax_models | tiered_anatomy_theatre, lost_wax_casting [production, 0-600] |  | ancestor_wax_masks [culture, 600-1200] |  |
| 2272 | maize_skin_sickness | maize_field_crop [nutrition] |  | epidemic_season_records, case_records [0-600] | contact_required: True |
| 2284 | ventilator_bellows | wooden_tub_bellows [production] |  | mine_airways [infrastructure], air_spring_law [knowledge] |  |
| 2288 | surgeons_college | surgeons_guild [1200-1800], college_of_physicians |  | university_clinical_wards |  |
| 2292 | smallpox_hospital | variolation_trials, ward_hospitals [1200-1800] |  | subscription_hospitals |  |
| 2296 | scurvy_controlled_trial | compared_treatment_groups [1200-1800], lemon_juice_scurvy |  | sea_surgeons_chest, experimental_controls [knowledge] |  |
| 2298 | cataract_extraction | hollow_needle_cataract [1200-1800], eye_anatomy_treatise [1200-1800] |  | surgeons_college |  |
| 2302 | preventive_inoculation | variolation_trials, experimental_controls [knowledge] |  | smallpox_hospital, medical_case_journals, weekly_mortality_bills [demography] |  |
| 2306 | gastric_digestion_experiments | experimental_controls [knowledge] |  | blood_circulation, chartered_experimental_society [knowledge], steam_bone_digester [nutrition] |  |
| 2312 | bedside_thermometer | pulse_watch, precision_thermometry [knowledge] |  | university_clinical_wards |  |
| 2322 | chest_percussion | university_clinical_wards, court_autopsy [1200-1800] |  | pulse_watch |  |
| 2326 | organ_seat_pathology | court_autopsy [1200-1800], university_clinical_wards |  | medical_case_journals, chest_percussion, anatomical_wax_models |  |
| 2330 | deaf_sign_school | printed_alphabet_primers [knowledge] |  | standard_tongue_dictionary [knowledge], compulsory_parish_schooling [knowledge] |  |
| 2334 | mass_shallow_inoculation | preventive_inoculation |  | annual_soul_lists [demography], smallpox_hospital |  |
| 2342 | drowning_rescue_societies | subscription_hospitals |  | air_spring_law [knowledge], fraternal_lodges [culture] |  |
| 2348 | outpatient_dispensaries | subscription_hospitals, chartered_apothecary_company |  | travelling_dispensaries [1200-1800] |  |
| 2356 | prison_hygiene_reform | ventilator_bellows, spotted_fever_distinction |  | penal_reform_no_torture [institutions], correction_workhouses [labor] |  |
| 2360 | medical_police_code | state_medical_collegium, police_ordinance_science [institutions] |  | cameral_science_chairs [institutions] |  |
| 2366 | blind_reading_school | blind_hospice [1200-1800], metal_type_casting [knowledge] |  | deaf_sign_school |  |
| 2370 | foxglove_dropsy | compared_treatment_groups [1200-1800], from_life_printed_herbals |  | medical_case_journals, experimental_controls [knowledge] |  |
| 2376 | town_fever_houses | smallpox_hospital, spotted_fever_distinction |  | subscription_hospitals, outpatient_dispensaries |  |
| 2382 | moral_treatment_asylums | hospital_madness_wards [1200-1800] |  | general_confinement_hospital, subscription_hospitals |  |
| 2384 | litter_bearer_drill | army_field_hospitals, printed_drill_manual [security] |  | regimental_surgeons |  |
| 2390 | fleet_citrus_ration | scurvy_controlled_trial, navy_board [security] |  | victualling_yards [logistics] |  |
| 2394 | cowpox_vaccination | preventive_inoculation |  | mass_shallow_inoculation, inoculation_mortality_reckoning [demography], veterinary_schools [ecology] |  |

## Notes

- **Pestilence.** `arrival_isolation_period` → `forty_day_quarantine` → `health_passes`, `quarantine_island_station` (coast or river) and `ship_bills_of_health`. `pestilence_health_boards` → `standing_health_magistracy` → `corpse_searchers` (with Demography `health_office_death_registers`) and `shut_up_plague_houses` (Security `parish_constables`). `frontier_sanitary_cordon` needs `pestilence_gate_watch` and the island station.
- **Smallpox.** `pox_measles_distinction` (1200–1800) → `folk_variolation` (2002) → `variolation_trials` (2244, with `compared_treatment_groups`) → `smallpox_hospital` (2292) and `preventive_inoculation` (2302) → `mass_shallow_inoculation` (2334) → `cowpox_vaccination` (2394). `preventive_inoculation` requires `variolation_trials` and Knowledge `experimental_controls` (2294), and does **not** require `contagion_mapping`. Ecology `veterinary_schools` and Demography `inoculation_mortality_reckoning` are precedents of cowpox.
- **Anatomy and physiology.** `public_anatomy_dissection` → `printed_dissection_manual` (Knowledge `screw_press_printing`) → `dissection_anatomy_atlas` → `tiered_anatomy_theatre` → `anatomical_wax_models`. The atlas and `pulmonary_transit` → `blood_circulation` → `capillary_observation` (Knowledge `two_lens_tube_microscope`) and `transfusion_ban`. `organ_seat_pathology` needs `court_autopsy` and `university_clinical_wards`.
- **Surgery.** `school_surgery_manual` → `field_surgery_handbook` → `gentle_gunshot_dressing` → `amputation_ligature` → `jointed_artificial_limbs` and `screw_tourniquet` (Production `screw_tap_and_die`). `army_field_hospitals` → `regimental_surgeons` (Security `crown_standing_army`) and `litter_bearer_drill` (Security `printed_drill_manual`).
- **Drugs.** Contact-gated: `great_pox_recognition` → `guaiac_pox_remedy` and `bathhouse_closures`; `cinchona_fever_bark`, `ipecac_flux_remedy`, and `maize_skin_sickness` (Nutrition `maize_field_crop`). `town_antidotary` → `printed_city_pharmacopoeia` → `chartered_apothecary_company`. `opium_tincture` needs Nutrition `distilled_spirits`.
- **Hospitals and licensing.** `medical_faculty_licence` + `physician_licensing_exam` → `college_of_physicians` → `state_medical_collegium` → `medical_police_code` (with Institutions `police_ordinance_science`). `general_confinement_hospital` needs Labor `correction_workhouses`; `subscription_hospitals` needs Institutions `joint_stock_company`; dispensaries, fever houses and drowning rescue build on the subscription hospitals.
- **Scurvy.** Nutrition `citrus_orchards` + Logistics `ocean_victualling` → `lemon_juice_scurvy` → `scurvy_controlled_trial` → `fleet_citrus_ration` (Security `navy_board`).
- **Clinical measurement.** `timed_pulse` (600–1200) + Production `mainspring_fusee_clocks` → `pulse_watch` → `bedside_thermometer` (Knowledge `precision_thermometry`).

## Cross-line parents in 1800–2400 (mapped by other agents)

- **Culture:** `fraternal_lodges` (2234), `public_playhouses` (1980), `single_point_perspective_painting` (1854)
- **Demography:** `annual_soul_lists` (2028), `health_office_death_registers` (1877), `inoculation_mortality_reckoning` (2320), `weekly_mortality_bills` (2008)
- **Ecology:** `mercury_amalgam_poisoning` (1966), `veterinary_schools` (2332)
- **Infrastructure:** `mine_airways` (1925)
- **Institutions:** `cameral_science_chairs` (2254), `joint_stock_company` (2000), `penal_reform_no_torture` (2328), `police_ordinance_science` (2260), `specialized_royal_councils` (1900), `war_ministry_bureaus` (2140)
- **Knowledge:** `air_spring_law` (2124), `burin_engraving` (1858), `chartered_experimental_society` (2120), `compulsory_parish_schooling` (2038), `experimental_controls` (2294), `experimental_protocol_publication` (2130), `hand_relief_printing` (1871), `inductive_method_program` (2040), `lens_centering` (2022), `measured_kinematics` (2008), `metal_type_casting` (1875), `mirror_grid_perspective` (1846), `pendulum_regulated_clock` (2112), `precision_thermometry` (2228), `printed_alphabet_primers` (1942), `printed_broadsides` (1890), `printed_weekly_news` (2010), `ruler_founded_universities` (1821), `screw_press_printing` (1867), `standard_tongue_dictionary` (2310), `town_printing_houses` (1892), `two_lens_tube_microscope` (1993)
- **Labor:** `correction_workhouses` (1961), `mining_ordinances` (1846), `parish_poor_law` (2002)
- **Logistics:** `ocean_victualling` (1908), `passenger_coach` (1878), `transoceanic_contact_voyages` (1912), `victualling_yards` (2050)
- **Nutrition:** `maize_field_crop` (1970), `steam_bone_digester` (2158)
- **Production:** `mainspring_fusee_clocks` (1858), `screw_cutting_lathe` (1975), `screw_tap_and_die` (1890), `wooden_tub_bellows` (2032)
- **Security:** `articulated_plate_armor` (1856), `crown_standing_army` (2100), `fortress_frontier_belt` (2160), `hand_gun_tubes` (1822), `matchlock_drill` (1920), `navy_board` (1965), `parish_constables` (1826), `pike_and_shot_regiment` (1946), `powder_artillery` (1848), `printed_drill_manual` (2014), `regimental_uniforms` (2108), `wheeled_siege_train` (1902)
