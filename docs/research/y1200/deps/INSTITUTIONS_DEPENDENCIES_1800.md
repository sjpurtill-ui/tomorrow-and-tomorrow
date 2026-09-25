# Institutions dependencies, years 1200–1800

Machine-readable source: `partials/kicl.json` (knowledge, institutions, culture, labor). Contract: the 600–1200 mapping (`docs/research/y600/deps/partials/kicl.json`, merged by `tools/research/merge_graph_1200.py`). Prerequisites may be 0–600, 600–1200 or 1200–1800 ids in any line, dated at or before the dependent. Any-sets are separated by ` / ` within brackets. Year adjustments are in `partials/kicl_year_adjustments.json`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1205 | `regional_vicariates` | `rotated_appointed_prefects`, `provincial_governors` |  | `divided_provincial_powers`, `civil_military_separation` |  |
| 1212 | `bound_estate_tenants` | `land_bound_tenancy`, `head_land_tax_units` |  | `sharecropping_tenancy` |  |
| 1220 | `register_of_dignities` | `nine_rank_official_grading`, `official_mandate_registers` |  | `palace_department_registers`, `civil_military_separation` |  |
| 1235 | `ranked_priestly_hierarchy` | `temple_estates`, `congregation_hall_temples` |  | `regional_vicariates`, `provincial_governors`, `shrine_arbitration_courts` |  |
| 1238 | `promulgated_edict_code` | `compiled_rescript_code` |  | `written_law_code`, `public_law_stele`, `register_of_dignities` |  |
| 1250 | `town_protector_office` | `town_advocate_for_poor` |  | `commoners_veto_tribunes`, `provincial_town_councils` |  |
| 1262 | `written_customary_codes` | `customary_law`, `written_law_code` |  | `promulgated_edict_code`, `federate_settlement` |  |
| 1266 | `priest_overseer_town_leadership` | `ranked_priestly_hierarchy` |  | `town_protector_office`, `village_self_rule_after_collapse`, `town_to_estate_drift` |  |
| 1270 | `personal_law_by_people` | `written_customary_codes` |  | `foreigners_court`, `settler_estate_shares` |  |
| 1278 | `jurist_digest_codification` | `binding_jurist_opinions`, `promulgated_edict_code` |  | `legal_jurisconsults`, `collated_critical_editions` |  |
| 1282 | `official_law_primer` | `jurist_digest_codification` |  | `seven_arts_manuals`, `state_official_academy` |  |
| 1290 | `district_counts` | `provincial_governors`, `regional_vicariates` |  | `personal_law_by_people`, `warrior_acclamation_assembly` |  |
| 1300 | `household_great_offices` | `palace_department_registers`, `register_of_dignities` |  | `throne_room_protocol`, `district_counts` |  |
| 1302 | `ordeal_by_the_god` | `ranked_priestly_hierarchy`, `sworn_trial_testimony` |  | `formal_oath_taking`, `written_customary_codes` |  |
| 1310 | `three_department_ministries` | `divided_provincial_powers`, `register_of_dignities` |  | `palace_department_registers`, `nine_rank_official_grading` |  |
| 1315 | `equal_field_allotment` | `graded_land_tax`, `household_tax_registers` |  | `triennial_household_registers`, `measured_plot_allotment` |  |
| 1320 | `regular_merit_examinations` | `written_office_examinations`, `three_department_ministries` |  | `state_official_academy`, `merit_recommendation` |  |
| 1322 | `military_frontier_provinces` | `provincial_governors`, `permanent_frontier_fortresses` |  | `military_district_settlement`, `civil_military_separation`, `regional_vicariates` |  |
| 1325 | `witnessed_land_charters` | `witnessed_land_sales`, `parchment_record_preparation` |  | `property_registers`, `oath_witness_registers` |  |
| 1330 | `impeaching_censorate` | `three_department_ministries`, `extortion_court` |  | `licensed_court_critics`, `circuit_inspectors` |  |
| 1336 | `palace_mayor_regency` | `household_great_offices` |  | `veiled_monarchy_offices`, `shared_co_rulers` |  |
| 1362 | `homage_commendation` | `vassal_loyalty_oaths`, `patron_protection` |  | `landowner_patronage_tenancy`, `formal_oath_taking` |  |
| 1375 | `hereditary_military_governors` | `military_frontier_provinces`, `dynastic_succession` |  | `palace_mayor_regency` |  |
| 1392 | `twice_yearly_coin_tax` | `annual_tax_budget`, `equal_field_allotment` |  | `small_change_coins`, `household_tax_registers` |  |
| 1395 | `palace_school_for_officials` | `state_official_academy`, `household_great_offices` |  | `seven_arts_manuals`, `retreat_copying_rooms` |  |
| 1398 | `spring_magnate_assembly` | `noble_council`, `district_counts` |  | `warrior_acclamation_assembly`, `household_great_offices` |  |
| 1399 | `compulsory_tithe` | `ranked_priestly_hierarchy`, `area_harvest_assessment` |  | `first_fruits_offering`, `temple_estates` |  |
| 1402 | `paired_royal_envoys` | `circuit_inspectors`, `district_counts` |  | `spring_magnate_assembly`, `mounted_messengers` |  |
| 1405 | `numbered_article_decrees` | `promulgated_edict_code`, `spring_magnate_assembly` |  | `paired_royal_envoys`, `small_letter_book_hand` |  |
| 1407 | `overlord_crowned_by_high_priest` | `priestly_anointing`, `ranked_priestly_hierarchy` |  | `ceremonial_investiture` |  |
| 1420 | `seigneurial_immunity_courts` | `district_counts`, `witnessed_land_charters` |  | `homage_commendation`, `landowner_patronage_tenancy` |  |
| 1426 | `manor_court_customals` | `seigneurial_immunity_courts`, `written_customary_codes` |  | `estate_survey_books`, `week_work_service` |  |
| 1432 | `fief_tenure_for_service` | `homage_commendation`, `service_land_grants` |  | `mounted_retinue_summons`, `land_for_service_tenure` |  |
| 1440 | `hereditary_fief_succession` | `fief_tenure_for_service`, `dynastic_succession` |  | `hereditary_military_governors`, `blood_heir_rule` |  |
| 1446 | `frontier_march_lords` | `fief_tenure_for_service`, `military_frontier_provinces` |  | `permanent_frontier_fortresses`, `castle_guard_rotations` |  |
| 1456 | `shire_reeve_courts` | `district_counts`, `regional_arbitration_circuits` |  | `free_adult_assembly`, `paired_royal_envoys`, `numbered_article_decrees` |  |
| 1459 | `prefect_guild_rulebook` | `chartered_craft_associations`, `market_wardens` |  | `licensed_guilds`, `city_supply_corporations` |  |
| 1470 | `itinerant_royal_court` | `household_great_offices`, `spring_magnate_assembly` |  | `estate_carrying_services`, `seigneurial_immunity_courts` |  |
| 1482 | `smallholder_protection_laws` | `promulgated_edict_code`, `bound_estate_tenants` |  | `debt_release_edicts`, `soldier_farmer_holdings` |  |
| 1496 | `raider_tribute_land_tax` | `hearth_tax_counts`, `shire_reeve_courts` |  | `treaty_border_levies`, `graded_land_tax` |  |
| 1500 | `castellan_local_lordship` | `motte_and_bailey`, `seigneurial_immunity_courts` |  | `hereditary_fief_succession`, `river_toll_stations` |  |
| 1505 | `sealed_royal_writs` | `shire_reeve_courts`, `numbered_article_decrees` |  | `small_letter_book_hand`, `standard_royal_letters` |  |
| 1510 | `holy_truce_days` | `ranked_priestly_hierarchy`, `castellan_local_lordship` |  | `holy_servants_feast_year`, `holy_relic_shrines` |  |
| 1512 | `anonymous_copied_exam_scripts` | `regular_merit_examinations` |  | `printed_standard_classics`, `scribal_copying_tests` |  |
| 1522 | `treasury_paper_notes` | `remittance_certificates`, `printing_process` |  | `paper_making`, `public_credit`, `district_royal_banks` |  |
| 1540 | `mutual_surety_tithings` | `shire_reeve_courts` |  | `bail_guarantors`, `gangs_of_ten`, `ward_residence_lists` |  |
| 1545 | `merchant_guild_monopoly` | `licensed_merchant_houses`, `market_wardens` |  | `prefect_guild_rulebook`, `seasonal_beach_emporia`, `municipal_charters` |  |
| 1550 | `closed_college_election` | `ranked_priestly_hierarchy`, `overlord_crowned_by_high_priest` |  | `majority_vote_assembly` |  |
| 1560 | `royal_chancery_office` | `sealed_royal_writs`, `formal_archives` |  | `small_letter_book_hand`, `diplomatic_letter_formulary`, `household_great_offices` |  |
| 1575 | `sworn_town_commune` | `merchant_guild_monopoly`, `formal_oath_taking` |  | `town_identity`, `mutual_surety_tithings`, `municipal_charters` |  |
| 1578 | `counting_table_audit` | `counting_board_abacus`, `shire_reeve_courts` |  | `end_of_term_audits`, `sealed_royal_writs`, `digit_column_counting_board` |  |
| 1583 | `craft_guilds` | `prefect_guild_rulebook`, `sworn_town_commune` |  | `apprentice_indentures`, `craft_quarter_streets`, `licensed_guilds` |  |
| 1584 | `elected_town_consuls` | `sworn_town_commune`, `annual_elected_magistrates` |  | `majority_vote_assembly` |  |
| 1585 | `great_hall_of_justice` | `royal_appeal_court`, `household_great_offices` |  | `long_span_timber_halls`, `shire_reeve_courts` |  |
| 1590 | `priestly_investiture_settlement` | `closed_college_election`, `fief_tenure_for_service` |  | `overlord_crowned_by_high_priest`, `sealed_royal_writs` |  |
| 1600 | `chief_justiciar_viceroy` | `royal_chancery_office`, `household_great_offices` |  | `palace_mayor_regency`, `counting_table_audit` |  |
| 1602 | `glossator_law_schools` | `jurist_digest_codification`, `great_house_schools` |  | `contrary_authorities_method`, `official_law_primer` |  |
| 1605 | `chartered_town_liberties` | `municipal_charters`, `sworn_town_commune` |  | `witnessed_land_charters`, `elected_town_consuls` |  |
| 1608 | `annual_receipt_rolls` | `counting_table_audit`, `parchment_record_preparation` |  | `provincial_accounts`, `royal_chancery_office` |  |
| 1612 | `public_notaries` | `glossator_law_schools`, `sealed_family_contracts` |  | `notarized_work_contracts`, `witnessed_land_charters` |  |
| 1617 | `sacred_law_concordance` | `glossator_law_schools`, `contrary_authorities_method` |  | `ranked_priestly_hierarchy`, `priestly_investiture_settlement` |  |
| 1628 | `fair_merchant_courts` | `guarded_trade_fairs`, `merchant_guild_monopoly` |  | `foreigners_court`, `merchant_safe_conducts` |  |
| 1638 | `royal_justice_circuits` | `regional_arbitration_circuits`, `sealed_royal_writs` |  | `paired_royal_envoys`, `chief_justiciar_viceroy`, `annual_receipt_rolls` |  |
| 1640 | `presenting_jury_of_neighbours` | `royal_justice_circuits`, `mutual_surety_tithings` |  | `sworn_trial_testimony`, `shire_reeve_courts` |  |
| 1650 | `hired_outside_magistrate` | `elected_town_consuls`, `glossator_law_schools` |  | `term_limit_laws`, `public_notaries` |  |
| 1656 | `writ_forms_of_action` | `sealed_royal_writs`, `royal_chancery_office` |  | `royal_justice_circuits`, `written_court_procedure` |  |
| 1660 | `salaried_royal_bailiffs` | `annual_receipt_rolls`, `royal_chancery_office` |  | `professional_service`, `service_money_commutation` |  |
| 1662 | `estates_assembly` | `spring_magnate_assembly`, `chartered_town_liberties` |  | `sworn_town_commune`, `chief_justiciar_viceroy` |  |
| 1666 | `chancery_enrolment_rolls` | `royal_chancery_office`, `annual_receipt_rolls` |  | `cross_referenced_archives`, `petition_registers` |  |
| 1675 | `fixed_capital_archives` | `chancery_enrolment_rolls`, `great_hall_of_justice` |  | `itinerant_royal_court`, `formal_archives`, `counting_table_audit` |  |
| 1679 | `ordeal_abolition` | `ordeal_by_the_god`, `presenting_jury_of_neighbours` |  | `sacred_law_concordance`, `glossator_law_schools` |  |
| 1680 | `great_liberties_charter` | `royal_covenant_charter`, `estates_assembly` |  | `chartered_town_liberties`, `hereditary_fief_succession` |  |
| 1681 | `great_priestly_council_decrees` | `sacred_law_concordance`, `closed_college_election` |  | `priestly_investiture_settlement`, `estates_assembly` |  |
| 1686 | `petty_trial_jury` | `presenting_jury_of_neighbours`, `ordeal_abolition` |  | `citizen_jury_courts` |  |
| 1688 | `inquisitorial_written_procedure` | `ordeal_abolition`, `glossator_law_schools` |  | `written_court_procedure`, `public_notaries`, `sacred_law_concordance` |  |
| 1702 | `revised_town_statute_books` | `chartered_town_liberties`, `elected_town_consuls` |  | `prefect_guild_rulebook`, `public_notaries`, `paper_working_copies` |  |
| 1708 | `permanent_high_court` | `fixed_capital_archives`, `writ_forms_of_action` |  | `royal_appeal_court`, `great_hall_of_justice` |  |
| 1710 | `sworn_royal_council` | `noble_council`, `fixed_capital_archives` |  | `professional_service`, `glossator_law_schools`, `chartered_university` |  |
| 1718 | `funded_public_debt_shares` | `public_credit`, `chartered_town_liberties` |  | `treasury_paper_notes`, `bills_of_exchange`, `elected_town_consuls` |  |
| 1720 | `revised_realm_law_code` | `promulgated_edict_code`, `glossator_law_schools` |  | `written_customary_codes`, `great_liberties_charter`, `hard_word_glossaries` |  |
| 1722 | `chartered_town_league` | `chartered_town_liberties`, `league_common_treasury` |  | `merchant_guild_monopoly`, `federal_proportional_league`, `sworn_town_commune` |  |
| 1730 | `branch_banking_houses` | `bills_of_exchange`, `licensed_merchant_houses` |  | `salaried_trade_factors`, `deposit_transfer_orders`, `merchant_digit_reckoning` |  |
| 1748 | `consented_taxation` | `estates_assembly`, `great_liberties_charter` |  | `assembly_petition_rights` |  |
| 1750 | `closed_hereditary_council` | `elected_town_consuls`, `noble_lineage_rolls` |  | `chartered_town_liberties`, `hired_outside_magistrate` |  |
| 1752 | `privy_seal_office` | `royal_chancery_office`, `chancery_enrolment_rolls` |  | `sworn_royal_council` |  |
| 1757 | `coronation_oath_to_realm` | `coronation_regalia_rite`, `great_liberties_charter` |  | `overlord_crowned_by_high_priest` |  |
| 1762 | `fixed_court_of_accounts` | `counting_table_audit`, `fixed_capital_archives` |  | `annual_receipt_rolls` |  |
| 1765 | `rank_sumptuary_laws` | `rank_dress_styles`, `numbered_article_decrees` |  | `heraldic_arms`, `knightly_conduct_code`, `chartered_town_liberties` |  |
| 1770 | `double_entry_ledgers` | `merchant_digit_reckoning`, `branch_banking_houses` |  | `paper_working_copies`, `merchant_letter_accounts`, `written_decimal_fractions` |  |
| 1774 | `scrutiny_lot_elections` | `elected_town_consuls`, `lot_chosen_council` |  | `closed_hereditary_council`, `craft_guilds` |  |
| 1776 | `keepers_of_the_peace` | `shire_reeve_courts`, `royal_justice_circuits` |  | `hue_and_cry`, `presenting_jury_of_neighbours`, `petty_trial_jury` |  |
| 1797 | `elector_college_charter` | `warrior_acclamation_assembly`, `closed_college_election` |  | `estates_assembly`, `coronation_oath_to_realm`, `great_liberties_charter` |  |

## Cross-line prerequisites assumed from other 1200–1800 lines

These ids are mapped by other partials in parallel; the edge assumes they keep their registry year.

- `remittance_certificates` (logistics 1330) → `treasury_paper_notes`
- `hearth_tax_counts` (demography 1430) → `raider_tribute_land_tax`
- `motte_and_bailey` (security 1478) → `castellan_local_lordship`
- `guarded_trade_fairs` (logistics 1580) → `fair_merchant_courts`
- `bills_of_exchange` (logistics 1650) → `branch_banking_houses`
- `noble_lineage_rolls` (demography 1652) → `closed_hereditary_council`

## Year adjustments

None.
