# Health dependencies: years 1200–1800

Generated with `docs/research/y1200/deps/partials/nhde.json`. It uses ids from `registry_1800.json`, the 600–1200 graph (`docs/research/y600/deps/graph_1200.json`) and the 0–600 graph only. Brackets mark a parent from another line or an earlier block: `[logistics]` is a 1200–1800 id owned by Logistics, `[ecology, 600-1200]` is a 600–1200 Ecology id, `[0-600]` is a same-line 0–600 id. An `environment` list means any one of the listed environments satisfies the gate. `requires_all` are hard prerequisites dated at or before the dependent (no edge links two items of the same year); `requires_any` groups need one member; precedents are soft influences, also dated at or before it. No year moves are proposed for this line (`partials/nhde_year_adjustments.json` is empty).

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1205 | excerpted_medical_collections | medical_encyclopedias [600-1200], excerpt_anthologies [knowledge, 600-1200] |  | epitome_digests [knowledge, 600-1200] |  |
| 1210 | palace_physician_office | town_physicians [600-1200] |  | medical_synthesis [600-1200], professional_service [institutions, 600-1200] |  |
| 1218 | ruled_hospital_staff | charity_hospitals [600-1200] |  | civic_infirmaries [600-1200], celibate_communities [demography, 600-1200] |  |
| 1260 | endowed_hospital_beds | ruled_hospital_staff |  | devotee_communities_under_rule [culture], alimentary_child_funds [demography, 600-1200] |  |
| 1275 | illustrated_herbals | materia_medica [600-1200] |  | descriptive_natural_history [knowledge, 600-1200], squared_grid_drawings [knowledge, 600-1200] |  |
| 1292 | bubo_plague_recognition | epidemic_chronicles [600-1200], prognostic_signs [600-1200] |  | pestilence_route_tracking [600-1200] |  |
| 1298 | quicklime_mass_graves | plague_burial_crews [600-1200], lime_mortar [infrastructure, 0-600] |  | bubo_plague_recognition, outbreak_burial_protocols [0-600] |  |
| 1304 | plague_bedding_burning | bubo_plague_recognition |  | sulfur_fumigation [600-1200], sickroom_fumigation [0-600] |  |
| 1315 | seaweed_goitre_remedy | materia_medica [600-1200] |  | seaweed_harvest_rotation [ecology, 600-1200] | contact_required: True |
| 1320 | road_hostel_infirmaries | charity_hospitals [600-1200], pass_hospices [logistics] |  | caravanserais [infrastructure, 600-1200] |  |
| 1324 | disease_causes_treatise | medical_synthesis [600-1200], prognostic_signs [600-1200] |  | cold_damage_treatise [600-1200] | contact_required: True |
| 1328 | medical_office_specialties | palace_physician_office, healing_schools [600-1200] |  | three_department_ministries [institutions] | contact_required: True |
| 1332 | uroscopy_flask | prognostic_signs [600-1200], glass_blowing [production, 600-1200] |  | decolorized_clear_glass [production, 600-1200] |  |
| 1338 | practitioner_compendium | medical_encyclopedias [600-1200], excerpted_medical_collections |  | surgical_instrument_kits [600-1200] |  |
| 1342 | liver_night_blindness | food_qualities_lore [nutrition, 600-1200] |  | case_records [0-600], dietary_healing_regimens [0-600] | contact_required: True |
| 1348 | household_formulary | fixed_formula_decoctions [600-1200] |  | household_remedy_kits [0-600], remedy_compendia [0-600] | contact_required: True |
| 1380 | licensed_drug_shops | root_cutter_shops [600-1200], market_wardens [institutions, 600-1200] |  | pharmacy_weights [600-1200] |  |
| 1400 | sickroom_diet_books | food_qualities_lore [nutrition, 600-1200], seasonal_regimen [600-1200] |  | dietary_healing_regimens [0-600], practitioner_compendium |  |
| 1406 | cloister_infirmary | devotee_communities_under_rule [culture], estate_sickrooms [600-1200] |  | walled_kitchen_gardens [nutrition], heated_public_baths [infrastructure, 600-1200] |  |
| 1420 | ward_hospitals | charity_hospitals [600-1200], licensed_drug_shops |  | ruled_hospital_staff, military_hospitals [600-1200], periodic_fever_classes [600-1200] |  |
| 1425 | travelling_dispensaries | licensed_drug_shops, healer_travel_circuits [600-1200] |  | road_hostel_infirmaries |  |
| 1432 | bonesetting_treatise | reduction_bench [600-1200], traction_fracture_setting [0-600] |  | squared_grid_drawings [knowledge, 600-1200] | contact_required: True |
| 1436 | hospital_formulary | ward_hospitals, materia_medica [600-1200] |  | household_formulary, pharmacy_weights [600-1200] |  |
| 1440 | sugar_syrup_remedies | remedy_vehicles [0-600] | irrigated_cane_fields [nutrition] or cane_sugar_crystals [nutrition, 600-1200] | honey_fruit_preserves [nutrition, 600-1200], hospital_formulary | contact_required: True |
| 1445 | eye_anatomy_treatise | surgical_anatomy [600-1200], nerve_tracing [600-1200] |  | cataract_couching [600-1200], geometric_optics_treatise [knowledge, 600-1200] |  |
| 1450 | physician_conduct_book | healer_conduct_oath [600-1200], authored_prose_treatises [knowledge, 600-1200] |  | palace_physician_office |  |
| 1458 | pox_measles_distinction | childhood_illness_recognition [demography, 0-600], prognostic_signs [600-1200] |  | disease_causes_treatise, clinical_observation_rounds [600-1200] |  |
| 1462 | compared_treatment_groups | clinical_observation_rounds [600-1200], case_records [0-600] |  | ward_hospitals |  |
| 1466 | physician_licensing_exam | written_office_examinations [institutions, 600-1200], healing_schools [600-1200] |  | regular_merit_examinations [institutions], physician_conduct_book |  |
| 1470 | bedside_teaching | ward_hospitals, apprentice_healer_rounds [0-600] |  | clinical_observation_rounds [600-1200] |  |
| 1478 | hospital_madness_wards | ward_hospitals, gentle_madness_care [600-1200] |  |  |  |
| 1490 | printed_state_pharmacopoeia | hospital_formulary, block_printed_books [knowledge] |  | materia_medica [600-1200], illustrated_herbals | contact_required: True |
| 1495 | graded_cautery_irons | cautery [0-600], smithing_tool_sets [production, 600-1200] |  | surgical_instrument_kits [600-1200] |  |
| 1500 | illustrated_surgery_treatise | surgical_instrument_kits [600-1200], practitioner_compendium |  | illustrated_herbals, graded_cautery_irons |  |
| 1505 | distilled_herb_waters | chemical_distillation [knowledge], materia_medica [600-1200] |  | alembic_distillation [production, 600-1200] |  |
| 1510 | drug_adulteration_tests | licensed_drug_shops |  | mineral_specific_gravity [knowledge, 600-1200], touchstone_testing [logistics, 600-1200] |  |
| 1515 | catgut_sutures | vessel_ligature [600-1200], wound_suturing [0-600] |  | cased_sausages [nutrition, 600-1200] |  |
| 1521 | canon_textbook | medical_synthesis [600-1200], practitioner_compendium |  | chapter_contents_lists [knowledge, 600-1200], syllogistic_logic [knowledge, 600-1200] |  |
| 1526 | contact_contagion | contagion_avoidance_customs [0-600], clinical_observation_rounds [600-1200] |  | canon_textbook, leper_houses [600-1200] |  |
| 1532 | hollow_needle_cataract | cataract_couching [600-1200], eye_anatomy_treatise |  | wire_drawing [production, 600-1200] |  |
| 1540 | needling_teaching_figures | needling_therapy [600-1200], lost_wax_casting [production, 0-600] |  | medical_office_specialties | contact_required: True |
| 1563 | state_drug_bureau | printed_state_pharmacopoeia, licensed_drug_shops |  | price_stabilizing_granary [institutions, 600-1200], salt_iron_monopoly [institutions, 600-1200] | contact_required: True |
| 1580 | burning_sickness_hospitals | ward_hospitals |  | rye_cultivation [nutrition, 600-1200], leper_houses [600-1200], devotee_communities_under_rule [culture] |  |
| 1588 | nursing_brotherhoods | charity_hospitals [600-1200], devotee_communities_under_rule [culture] |  | road_hostel_infirmaries, chartered_craft_associations [institutions, 600-1200] |  |
| 1605 | mercury_ointment | materia_medica [600-1200], mercury_fire_gilding [production, 600-1200] |  | contact_contagion |  |
| 1612 | household_health_verses | seasonal_regimen [600-1200], sickroom_diet_books |  | canon_textbook |  |
| 1620 | aged_almshouses | charity_hospitals [600-1200], endowed_hospital_beds |  | congregation_widow_rolls [demography, 600-1200] |  |
| 1626 | itch_mite_removal | delousing [0-600], contact_contagion |  | iron_surgical_probes [600-1200] |  |
| 1632 | town_antidotary | hospital_formulary, licensed_drug_shops |  | compound_antidotes [600-1200], craft_guilds [institutions] |  |
| 1645 | medical_faculty_licence | physician_licensing_exam, chartered_university [knowledge] |  | teaching_licence_degree [knowledge], canon_textbook |  |
| 1655 | bloodletting_calendars | venesection [600-1200], printed_almanacs [knowledge] |  | seasonal_regimen [600-1200], planispheric_astrolabe [knowledge] |  |
| 1680 | spoiled_food_condemnation | market_wardens [institutions, 600-1200], spoilage_inspection [nutrition, 0-600] |  | guild_searchers [labor] |  |
| 1690 | hospital_admission_books | ward_hospitals, case_records [0-600] |  | annual_receipt_rolls [institutions], daily_death_counts [demography, 600-1200] |  |
| 1700 | apothecary_separation | licensed_drug_shops, medical_faculty_licence |  | town_antidotary, craft_guilds [institutions] |  |
| 1703 | pulmonary_transit | vessel_distinction [600-1200], experimental_vivisection [600-1200] |  | canon_textbook |  |
| 1706 | inquest_handbook | skull_wound_grading [600-1200], wound_classification [600-1200] |  | intent_graded_homicide_law [institutions, 600-1200], presenting_jury_of_neighbours [institutions] |  |
| 1717 | blind_hospice | charity_hospitals [600-1200] |  | aged_almshouses, disability_care [0-600] |  |
| 1722 | dry_wound_dressing | wine_wound_washing [600-1200] |  | resin_wound_salves [600-1200], woven_dressings [0-600], catgut_sutures |  |
| 1735 | leper_inspection_panels | leper_houses [600-1200], contact_contagion |  | presenting_jury_of_neighbours [institutions] |  |
| 1740 | reading_spectacles | optical_lenses [knowledge] |  | decolorized_clear_glass [production, 600-1200], school_perspective_optics [knowledge] |  |
| 1745 | street_filth_ordinances | street_cleaning_wardens [600-1200], municipal_charters [institutions, 600-1200] |  | town_dung_collectors [ecology, 600-1200], revised_town_statute_books [institutions] |  |
| 1750 | court_autopsy | surgical_anatomy [600-1200], inquest_handbook |  | inquisitorial_written_procedure [institutions] |  |
| 1755 | public_theriac_compounding | compound_antidotes [600-1200], town_antidotary |  | drug_adulteration_tests |  |
| 1760 | surgeons_guild | craft_guilds [institutions], barber_bleeders [600-1200] |  | apprentice_indentures [labor], masterpiece_trial [labor] |  |
| 1765 | public_anatomy_dissection | surgical_anatomy [600-1200], chartered_university [knowledge] |  | court_autopsy, illustrated_surgery_treatise |  |
| 1772 | walled_out_slaughter | smoky_trades_zoning [ecology, 600-1200], street_filth_ordinances |  | spoiled_food_condemnation |  |
| 1782 | school_surgery_manual | illustrated_surgery_treatise, chartered_university [knowledge] |  | surgeons_guild, set_text_lectures [knowledge] |  |
| 1787 | plague_advice_tracts | bubo_plague_recognition, household_health_verses |  | vernacular_learned_writing [knowledge], printed_almanacs [knowledge] |  |
| 1790 | pestilence_health_boards | plague_bedding_burning, sworn_town_commune [institutions] |  | daily_death_counts [demography, 600-1200], pestilence_route_tracking [600-1200] |  |
| 1792 | pestilence_gate_watch | pestilence_health_boards, ward_night_watch [security] |  | quarantine_travel_restrictions [0-600], internal_passes [demography, 600-1200] |  |
| 1794 | pestilence_physicians | pestilence_health_boards, district_physicians [600-1200] |  | town_physicians [600-1200] |  |
| 1797 | arrival_isolation_period | isolation_practice [0-600], pestilence_health_boards |  | harbor_masters [logistics, 600-1200], pestilence_gate_watch |  |

## Notes

- **Texts.** `medical_encyclopedias` → `excerpted_medical_collections` → `practitioner_compendium` → `canon_textbook` (1521, also requires `medical_synthesis`). The canon is a precedent for `contact_contagion`, `household_health_verses` and `pulmonary_transit`.
- **Hospitals.** `charity_hospitals` (1195) → `ruled_hospital_staff` → `endowed_hospital_beds` → `aged_almshouses`. `charity_hospitals` + `licensed_drug_shops` → `ward_hospitals` (1420). Ward hospitals gate `hospital_formulary`, `bedside_teaching`, `hospital_madness_wards`, `burning_sickness_hospitals` and `hospital_admission_books`. `cloister_infirmary` and `nursing_brotherhoods` require culture `devotee_communities_under_rule`. `road_hostel_infirmaries` requires logistics `pass_hospices`.
- **Pharmacy.** `root_cutter_shops` + `market_wardens` → `licensed_drug_shops` (1380) → `hospital_formulary` → `town_antidotary` → `public_theriac_compounding`. `apothecary_separation` requires `medical_faculty_licence`. `distilled_herb_waters` requires knowledge `chemical_distillation`.
- **Licensing and schools.** `physician_licensing_exam` requires institutions `written_office_examinations` (600–1200). Knowledge `chartered_university` (1625) gates `medical_faculty_licence`, `public_anatomy_dissection` and `school_surgery_manual`. `surgeons_guild` requires institutions `craft_guilds` (1583).
- **Pestilence.** `epidemic_chronicles` + `prognostic_signs` → `bubo_plague_recognition` (1292). It leads to `quicklime_mass_graves`, `plague_bedding_burning`, `plague_advice_tracts` and `pestilence_health_boards` (1790, which also requires institutions `sworn_town_commune`). The boards lead to `pestilence_gate_watch` (security `ward_night_watch`), `pestilence_physicians` and `arrival_isolation_period`.
- **Eyes and lenses.** `surgical_anatomy` + `nerve_tracing` → `eye_anatomy_treatise` → `hollow_needle_cataract`. `reading_spectacles` requires knowledge `optical_lenses` (1733).
- **Regional items** carry `contact_required`: `seaweed_goitre_remedy`, `disease_causes_treatise`, `medical_office_specialties`, `liver_night_blindness`, `household_formulary`, `bonesetting_treatise`, `printed_state_pharmacopoeia`, `needling_teaching_figures` and `state_drug_bureau`. `sugar_syrup_remedies` does too, because its sugar parents are regional.
