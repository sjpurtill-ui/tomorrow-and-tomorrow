# Demography dependencies: years 600–1200

Generated with `docs/research/y600/deps/partials/nhde.json`. It uses ids from `registry_1200.json` and the 0–600 graph only. Cross-line ids show their line in brackets; `0-600` marks a cross-block id. An `environment` list means any one of the listed environments satisfies the gate. `requires_all` are hard prerequisites dated at or before the dependent; precedents are soft influences, also dated at or before it. No year moves are proposed for this line.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 604 | levy_age_rolls | census_rolls [institutions, 0-600], named_year_ages |  | household_muster [security, 0-600] |  |
| 610 | eldest_double_share | partible_inheritance |  | sealed_family_contracts [institutions, 0-600] |  |
| 618 | overseas_colony_founding | daughter_hamlets, island_hopping_sailing [logistics, 0-600] |  | trade_colonies [logistics, 0-600] | environment: coast |
| 624 | intertown_marriage_rights | village_marriage_alliances, foreign_treaties [institutions, 0-600] |  |  |  |
| 630 | resident_alien_status | patron_protection, cross_settlement_registries [institutions, 0-600] |  | merchant_quarters_abroad [logistics, 0-600] |  |
| 636 | foundling_rescue | kin_fostering_networks |  | captive_adoption |  |
| 642 | heir_adoption | sealed_family_contracts [institutions, 0-600] |  | kin_fostering_networks, captive_adoption |  |
| 648 | heiress_marriage_rule | partible_inheritance |  | levirate_marriage |  |
| 654 | dowry_as_inheritance | recorded_dowry, partible_inheritance |  |  |  |
| 660 | age_class_enrollment | named_year_ages |  | levy_age_rolls, formation_drill [security, 0-600] |  |
| 668 | forced_resettlement | provincial_governors [institutions, 0-600], census_rolls [institutions, 0-600] |  | tributary_villages [institutions, 0-600] |  |
| 676 | planned_colony_lots | overseas_colony_founding, geometric_survey [knowledge, 0-600] |  | measured_plot_allotment [labor, 0-600] |  |
| 684 | single_wife_households | marriage_age_norms |  | sealed_family_contracts [institutions, 0-600] |  |
| 692 | kin_birth_registration | household_vital_lists |  | naming_day_rites [culture, 0-600] |  |
| 700 | double_descent_citizenship | belonging_oaths, kin_birth_registration |  | single_wife_households, town_identity [culture, 0-600] |  |
| 708 | unfree_headcount | census_rolls [institutions, 0-600] |  | captive_adoption |  |
| 716 | military_settler_colonies | frontier_settler_grants, professional_corps [security] |  |  |  |
| 724 | epitaph_age_records | named_year_ages, royal_inscriptions [institutions, 0-600] |  |  |  |
| 732 | household_tax_registers | ward_residence_lists, formal_archives [knowledge, 0-600] |  | public_levies [institutions, 0-600] |  |
| 740 | twin_birth_customs | birth_attendants [health, 0-600] |  | naming_day_rites [culture, 0-600] |  |
| 748 | mourning_limits | written_law_code [institutions, 0-600] |  | royal_mourning [culture, 0-600] |  |
| 756 | widow_remarriage_custom | widow_portion_law |  | levirate_marriage |  |
| 764 | refugee_land_settlement | famine_refugee_hosting, service_land_grants [institutions, 0-600] |  |  |  |
| 772 | town_consolidation | town_identity [culture, 0-600], satellite_hamlets |  | shrine_league_confederation [institutions] |  |
| 788 | majority_enrollment | age_class_enrollment |  | kin_birth_registration |  |
| 796 | family_size_counsel | carrying_capacity_awareness, birth_spacing_customs |  | overseas_colony_founding |  |
| 804 | property_class_census | household_tax_registers, property_class_franchise [institutions] |  | census_rolls [institutions, 0-600] |  |
| 812 | contraceptive_herbs | contraceptive_pessaries |  | remedy_compendia [health, 0-600] |  |
| 820 | craftsman_naturalization | resident_alien_status |  | itinerant_craft_hire [labor] |  |
| 828 | written_wills | sealed_family_contracts [institutions, 0-600], partible_inheritance |  | witnessed_land_sales [institutions, 0-600] |  |
| 836 | orphan_guardianship | kin_care_widows_orphans, sworn_judges [institutions, 0-600] |  | annual_elected_magistrates [institutions] |  |
| 844 | harvest_labor_migration | hired_harvest_hands [labor, 0-600] |  | rural_urban_migration |  |
| 852 | freed_person_status | unfree_headcount |  | debt_release_edicts [institutions, 0-600], debt_bondage_ban [institutions] |  |
| 860 | colony_kin_ties | overseas_colony_founding |  | shrine_festival_games [culture] |  |
| 868 | offering_birth_counts | kin_birth_registration |  | temple_estates [institutions, 0-600] |  |
| 876 | trained_midwives | midwife_apprenticeship_lines, trained_midwife_referral |  | healing_schools [health] |  |
| 884 | war_orphan_upkeep | orphan_guardianship |  | paid_civic_duty [institutions], public_funeral_orations [culture] |  |
| 890 | veteran_land_allotments | military_settler_colonies |  | professional_corps [security] |  |
| 897 | birth_declaration_deadline | kin_birth_registration, formal_archives [knowledge, 0-600] |  | annual_elected_magistrates [institutions] |  |
| 905 | mixed_foundation_towns | planned_colony_lots, resident_alien_status |  | standard_lot_grid_towns [infrastructure] |  |
| 912 | fetal_position_knowledge | breech_repositioning_technique, surgical_anatomy [health] |  |  |  |
| 920 | midwifery_manuals | trained_midwives, fetal_position_knowledge, authored_prose_treatises [knowledge] |  |  |  |
| 928 | birthing_chair | birth_stool_bricks |  | trained_midwives |  |
| 936 | periodic_citizen_census | property_class_census |  | people_herd_counts, end_of_term_audits [institutions] |  |
| 944 | hired_child_minders | shared_childcare |  | wet_nurse_contracts |  |
| 952 | adult_succession_adoption | heir_adoption |  | written_wills |  |
| 960 | triennial_household_registers | household_tax_registers |  | periodic_citizen_census |  |
| 968 | city_grain_migration | town_grain_dole [nutrition], rural_urban_migration |  |  |  |
| 976 | feeding_horns | infant_feeding_schedules, milking [nutrition, 0-600] |  | weaning_food_softening |  |
| 984 | tenement_crowding | upper_storeys [infrastructure, 0-600] |  | city_grain_migration |  |
| 992 | garrison_farm_colonies | military_settler_colonies |  | veteran_land_allotments |  |
| 1000 | postmortem_cesarean | fetal_position_knowledge, surgical_anatomy [health] |  |  |  |
| 1008 | nursing_mother_diet | maternal_recovery, seasonal_regimen [health] |  |  |  |
| 1016 | service_membership | citizenship_extension [institutions] |  | contracted_mercenary_captains [security], allied_contingents [security, 0-600] |  |
| 1024 | fertile_day_counting | seasonal_conception_timing, intercalated_calendar [knowledge, 0-600] |  | contraceptive_herbs |  |
| 1033 | marriage_incentive_laws | periodic_citizen_census |  | family_size_counsel, magistrate_edict_law [institutions] |  |
| 1042 | registered_marriage | sealed_family_contracts [institutions, 0-600], birth_declaration_deadline |  | marriage_incentive_laws |  |
| 1050 | alimentary_child_funds | war_orphan_upkeep, public_credit [institutions] |  | town_grain_dole [nutrition] |  |
| 1060 | deserted_land_grants | refugee_land_settlement, property_registers [institutions, 0-600] |  |  |  |
| 1070 | daily_death_counts | epidemic_chronicles [health] |  | household_tax_registers |  |
| 1080 | childless_estate_escheat | written_wills |  | heir_adoption, league_common_treasury [institutions] |  |
| 1090 | wet_nurse_licensing | wet_nurse_contracts, market_wardens [institutions] |  |  |  |
| 1100 | post_plague_resettlement | deserted_land_grants, daily_death_counts |  |  |  |
| 1110 | congregation_widow_rolls | kin_care_widows_orphans |  | crossroads_shrine_clubs [culture], alimentary_child_funds |  |
| 1120 | internal_passes | sealed_travel_passes [institutions, 0-600], household_tax_registers |  | state_post_passes [logistics] |  |
| 1140 | annuity_life_tables | epitaph_age_records, periodic_citizen_census |  | daily_death_counts, risk_pools [institutions] |  |
| 1160 | head_land_tax_units | periodic_citizen_census, graded_land_tax [institutions] |  |  |  |
| 1170 | celibate_communities | contemplative_ascent_schools [culture] |  | philosophy_school_communities [culture] |  |
| 1192 | federate_settlement | treaty_border_levies [security], deserted_land_grants |  | refugee_land_settlement |  |

## Notes

- **Registers.** `census_rolls`, `ward_residence_lists` and `formal_archives` (0–600) → `household_tax_registers` (732) → `property_class_census` (804, also requires institutions `property_class_franchise`) → `periodic_citizen_census` (936). That census gates marriage incentives, life tables and `head_land_tax_units` (with institutions `graded_land_tax`).
- **Settlement chain.** `frontier_settler_grants` → `military_settler_colonies` → `veteran_land_allotments`, `garrison_farm_colonies`. `refugee_land_settlement` → `deserted_land_grants` → `post_plague_resettlement`. `federate_settlement` requires security `treaty_border_levies`.
- **Birth and midwifery.** `trained_midwives` (876) → `midwifery_manuals` (920). `fetal_position_knowledge` and `postmortem_cesarean` require health `surgical_anatomy` (893).
- **Cross-line anchors.** `city_grain_migration` requires nutrition `town_grain_dole`. `alimentary_child_funds` requires institutions `public_credit` (1000). `celibate_communities` requires culture `contemplative_ascent_schools` (1150). `service_membership` requires institutions `citizenship_extension`.
- `tenement_crowding` (984) requires 0–600 `upper_storeys`. Infrastructure `tenement_blocks` (1030) comes after it, so it is not a prerequisite.
