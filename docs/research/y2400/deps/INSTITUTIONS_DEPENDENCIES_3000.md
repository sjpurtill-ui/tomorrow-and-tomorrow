# Institutions dependencies: years 2400–3000

Machine-readable source: `partials/kicl.json` (knowledge, institutions, culture, labor). Contract: the 600–1200 mapping (`docs/research/y600/deps/partials/kicl.json`, merged by `tools/research/merge_graph_1200.py`) and its 1200–1800 and 1800–2400 successors. Ids come from `registry_3000.json`, `registry_2400.json` with the 1800–2400 partials, the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), and the game's baked 0–600 and 600–1200 blocks. Prerequisites may be ids of any earlier block in any line, or 2400–3000 ids, and every prerequisite and precedent is dated at or before its dependent (registry target years after the year adjustments; earlier blocks at their baked or graph years). Brackets mark a parent from another line or an earlier block: `[production]` is a 2400–3000 id owned by Production, `[ecology, 1800-2400]` is a 1800–2400 Ecology id, `[1200-1800]` is a same-line 1200–1800 id. `contact_required` marks items that need ocean contact, directly or through a contact-gated hard parent. Chains are modern (AD 1800–2030). No year moves are proposed for this line.

**100 entries, 173 hard edges, 186 precedent edges, 0 requires_any groups.** Contact-gated: `dependencies_ministry`, `dependency_self_rule`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2403 | `appointed_department_prefects` | `uniform_departments` [1800-2400] |  | `provincial_intendants` [1800-2400], `cameral_service_examinations` [1800-2400] |  |
| 2405 | `civil_merit_order` | `chivalric_orders_insignia` [culture, 1200-1800], `abolition_of_estate_privileges` [1800-2400] |  | `table_of_service_ranks` [1800-2400] |  |
| 2411 | `universal_civil_code` | `compiled_civil_code` [1800-2400], `abolition_of_estate_privileges` [1800-2400] |  | `general_land_code` [1800-2400], `declaration_of_rights` [1800-2400] |  |
| 2416 | `administrative_courts` | `uniform_departments` [1800-2400], `compiled_civil_code` [1800-2400] |  | `justice_ombudsman` [1800-2400], `separation_of_powers` [1800-2400], `universal_civil_code` |  |
| 2419 | `commercial_code` | `universal_civil_code` |  | `joint_stock_company` [1800-2400], `endorsed_bills` [logistics, 1800-2400], `fair_merchant_courts` [1200-1800] |  |
| 2424 | `assembly_ombudsman` | `justice_ombudsman` [1800-2400] |  | `single_national_assembly` [1800-2400], `separation_of_powers` [1800-2400] |  |
| 2427 | `single_minister_departments` | `three_department_ministries` [1200-1800] |  | `secretaries_of_state` [1800-2400], `cabinet_first_minister` [1800-2400], `governing_senate_colleges` [1800-2400], `ministry_office_block` [infrastructure, 1800-2400] |  |
| 2437 | `granted_constitution` | `great_liberties_charter` [1200-1800], `written_frame_of_government` [1800-2400] |  | `federal_written_constitution` [1800-2400], `declaration_of_rights` [1800-2400], `realm_bill_of_rights` [1800-2400], `conditional_crown_settlement` [1800-2400] |  |
| 2440 | `great_realm_conference` | `sovereign_realms_congress` [1800-2400], `resident_ambassadors` [1800-2400] |  | `balance_of_power_league` [1800-2400], `law_of_war_and_peace` [1800-2400] |  |
| 2443 | `annual_budget_vote` | `consented_taxation` [1200-1800], `appropriated_annual_budget` [1800-2400] |  | `single_national_assembly` [1800-2400], `fixed_court_of_accounts` [1200-1800] |  |
| 2453 | `penitentiary_sentences` | `penal_reform_no_torture` [1800-2400] |  | `prison_hygiene_reform` [health, 1800-2400], `correction_workhouses` [labor, 1800-2400], `convict_transportation` [demography, 1800-2400] |  |
| 2480 | `public_instruction_ministry` | `single_minister_departments`, `compulsory_parish_schooling` [knowledge, 1800-2400] |  | `state_polytechnic_school` [knowledge, 1800-2400], `research_university` [knowledge] |  |
| 2485 | `householder_franchise` | `single_national_assembly` [1800-2400] |  | `fixed_term_estates` [1800-2400], `estates_parties` [1800-2400], `granted_constitution`, `decennial_apportionment_census` [demography, 1800-2400] |  |
| 2491 | `customs_union` | `great_realm_conference`, `free_grain_trade_doctrine` [1800-2400] |  | `customs_frontier_patrols` [security, 1800-2400], `realm_union_treaty` [1800-2400], `bonded_warehouses` [logistics, 1800-2400] |  |
| 2491 | `poor_law_boards` | `workhouse_test` [labor, 1800-2400], `compulsory_poor_rate` [labor, 1800-2400] |  | `single_minister_departments`, `parish_poor_law` [labor, 1800-2400] |  |
| 2496 | `examined_patent_office` | `invention_patent_statute` [1800-2400], `single_minister_departments` |  | `precision_machinery` [infrastructure, 1800-2400] |  |
| 2509 | `responsible_ministry` | `cabinet_first_minister` [1800-2400], `householder_franchise` |  | `granted_constitution`, `estates_parties` [1800-2400] |  |
| 2517 | `central_note_monopoly` | `chartered_central_bank` [1800-2400] |  | `treasury_paper_notes` [1200-1800], `city_exchange_bank` [1800-2400] |  |
| 2520 | `bankruptcy_discharge` | `commercial_code` |  | `creditor_debt_house` [1800-2400], `joint_stock_company` [1800-2400] |  |
| 2523 | `grain_tariff_repeal` | `free_grain_trade_doctrine` [1800-2400] |  | `customs_union`, `free_grain_trade_edict` [nutrition, 1800-2400], `householder_franchise` |  |
| 2528 | `manhood_suffrage` | `householder_franchise` |  | `decennial_apportionment_census` [demography, 1800-2400], `penny_daily_press` [culture] |  |
| 2533 | `mass_political_parties` | `estates_parties` [1800-2400], `householder_franchise` |  | `penny_daily_press` [culture], `reading_circles` [culture] |  |
| 2536 | `ruler_plebiscite` | `granted_constitution`, `manhood_suffrage` |  | `emergency_safety_committee` [1800-2400] |  |
| 2541 | `competitive_civil_service` | `cameral_service_examinations` [1800-2400], `research_university` [knowledge] |  | `single_minister_departments`, `regular_merit_examinations` [1200-1800] |  |
| 2547 | `limited_liability_registration` | `joint_stock_company` [1800-2400], `commercial_code` |  | `bubble_company_law` [1800-2400] |  |
| 2549 | `secret_printed_ballot` | `manhood_suffrage` |  | `scrutiny_lot_elections` [1200-1800], `town_printing_houses` [knowledge, 1800-2400] |  |
| 2552 | `civil_divorce_courts` | `civil_divorce` [demography, 1800-2400], `universal_civil_code` |  | `marriage_dissolution_courts` [demography, 1800-2400] |  |
| 2555 | `dependencies_ministry` | `single_minister_departments`, `overseas_viceroyalties` [1800-2400] |  | `trade_and_colonies_board` [1800-2400] | contact_required=yes |
| 2571 | `rural_district_assemblies` | `elected_municipal_councils` [1800-2400] |  | `abolition_of_estate_privileges` [1800-2400], `householder_franchise` |  |
| 2576 | `independent_audit_office` | `fixed_court_of_accounts` [1200-1800], `annual_budget_vote` |  | `responsible_ministry` |  |
| 2576 | `lender_of_last_resort` | `central_note_monopoly` |  | `share_exchange_bourse` [1800-2400], `limited_liability_registration` |  |
| 2579 | `ceremonial_crown` | `granted_constitution`, `responsible_ministry` |  | `manhood_suffrage` |  |
| 2592 | `career_diplomatic_service` | `resident_ambassadors` [1800-2400], `competitive_civil_service` |  | `envoy_credentials_immunity` [1800-2400], `foreign_affairs_office` [1800-2400] |  |
| 2592 | `interrealm_arbitration` | `great_realm_conference`, `law_of_war_and_peace` [1800-2400] |  | `neutral_wounded_convention` [health] |  |
| 2595 | `gold_standard_link` | `central_note_monopoly`, `lender_of_last_resort` |  | `undersea_telegraph_cable` [knowledge], `customs_union` |  |
| 2600 | `municipal_utilities` | `elected_municipal_councils` [1800-2400], `coal_gas_works` [production] |  | `steam_pumped_waterworks` [infrastructure], `gas_lit_streets` [infrastructure] |  |
| 2608 | `probation_parole` | `penitentiary_sentences` |  | `prison_hygiene_reform` [health, 1800-2400] |  |
| 2619 | `married_women_property` | `universal_civil_code`, `separate_wife_property` [demography, 1800-2400] |  | `womens_rights_convention` [culture] |  |
| 2629 | `audited_company_accounts` | `limited_liability_registration`, `double_entry_ledgers` [1200-1800] |  | `bankruptcy_discharge`, `independent_audit_office` |  |
| 2635 | `elected_county_councils` | `rural_district_assemblies` |  | `manhood_suffrage` |  |
| 2637 | `old_age_pensions` | `poor_law_boards`, `mortality_table_insurance` [demography] |  | `actuarial_widows_fund` [demography, 1800-2400], `registered_friendly_societies` [labor, 1800-2400], `worker_sickness_insurance` [health] |  |
| 2640 | `antimonopoly_law` | `limited_liability_registration`, `commercial_code` |  | `merchant_guild_monopoly` [1200-1800], `abolition_of_estate_privileges` [1800-2400], `railway_clearing_house` [logistics] |  |
| 2648 | `womens_suffrage` | `manhood_suffrage`, `womens_rights_convention` [culture] |  | `married_women_property` |  |
| 2661 | `initiative_referendum` | `manhood_suffrage`, `secret_printed_ballot` |  | `ruler_plebiscite` |  |
| 2664 | `juvenile_courts` | `probation_parole` |  | `child_labor_prohibition` [labor], `orphan_boarding_out` [demography] |  |
| 2664 | `proportional_representation` | `mass_political_parties`, `secret_printed_ballot` |  | `manhood_suffrage` |  |
| 2685 | `rate_regulation_commissions` | `antimonopoly_law` |  | `classed_freight_tariffs` [logistics], `municipal_utilities`, `alternating_current_grids` [infrastructure] |  |
| 2696 | `unemployment_insurance` | `worker_sickness_insurance` [health], `public_labor_exchanges` [labor] |  | `old_age_pensions`, `strike_funds` [labor, 1800-2400], `amalgamated_craft_unions` [labor] |  |
| 2696 | `upper_chamber_curbed` | `responsible_ministry`, `manhood_suffrage` |  | `annual_budget_vote` |  |
| 2704 | `war_economy_boards` | `single_minister_departments`, `labor_statistics_bureau` [labor] |  | `railway_mobilization` [security], `reserve_mobilization_plans` [security], `economic_blockade_decrees` [security] |  |
| 2707 | `frontier_passport_control` | `travel_passports` [security, 1800-2400] |  | `immigration_inspection_station` [demography], `fingerprint_identification` [security] |  |
| 2712 | `one_party_state` | `mass_political_parties`, `ruler_plebiscite` |  | `political_police_bureau` [security], `emergency_safety_committee` [1800-2400] |  |
| 2717 | `league_of_realms` | `great_realm_conference`, `interrealm_arbitration` |  | `land_war_conventions` [security], `interrealm_postal_union` [logistics] |  |
| 2720 | `constitutional_court` | `granted_constitution`, `administrative_courts` |  | `separation_of_powers` [1800-2400], `permanent_high_court` [1200-1800] |  |
| 2725 | `interrealm_permanent_court` | `interrealm_arbitration`, `league_of_realms` |  | `permanent_high_court` [1200-1800] |  |
| 2736 | `corporatist_chambers` | `trade_wide_employer_bargaining` [labor], `union_legal_standing` [labor] |  | `one_party_state`, `guild_council_seats` [labor, 1200-1800] |  |
| 2741 | `central_five_year_plan` | `war_economy_boards`, `common_ownership_doctrine` [culture] |  | `one_party_state`, `labor_statistics_bureau` [labor], `punched_card_tabulation` [knowledge] |  |
| 2747 | `emergency_decree_rule` | `emergency_safety_committee` [1800-2400], `granted_constitution` |  | `one_party_state`, `constitutional_court` |  |
| 2755 | `deposit_insurance` | `lender_of_last_resort` |  | `risk_pools` [600-1200] |  |
| 2755 | `state_propaganda_ministry` | `single_minister_departments`, `radio_broadcasting` [culture] |  | `one_party_state`, `war_newsreels_posters` [culture], `press_licensing_censors` [1800-2400] |  |
| 2757 | `national_income_accounts` | `statistical_sampling` [knowledge], `punched_card_tabulation` [knowledge] |  | `labor_statistics_bureau` [labor], `state_statistical_office` [demography] |  |
| 2757 | `securities_commission` | `audited_company_accounts`, `share_exchange_bourse` [1800-2400] |  | `antimonopoly_law` |  |
| 2763 | `countercyclical_spending` | `national_income_accounts`, `central_note_monopoly` |  | `public_relief_works` [labor], `slump_hunger_marches` [labor] |  |
| 2784 | `fixed_exchange_accord` | `gold_standard_link`, `league_of_realms` |  | `countercyclical_spending`, `national_income_accounts` |  |
| 2787 | `atrocity_tribunals` | `interrealm_permanent_court`, `land_war_conventions` [security] |  | `world_assembly_of_realms`, `gas_germ_weapon_ban` [security] |  |
| 2787 | `world_assembly_of_realms` | `league_of_realms` |  | `interrealm_permanent_court`, `land_war_conventions` [security] |  |
| 2789 | `nationalized_core_industries` | `war_economy_boards`, `common_ownership_doctrine` [culture] |  | `central_five_year_plan`, `state_railway_administration` [logistics], `municipal_utilities` |  |
| 2789 | `welfare_state` | `worker_sickness_insurance` [health], `old_age_pensions`, `unemployment_insurance` |  | `national_income_accounts`, `universal_family_allowances` [demography] |  |
| 2795 | `universal_rights_declaration` | `declaration_of_rights` [1800-2400], `world_assembly_of_realms` |  | `atrocity_tribunals` |  |
| 2800 | `regional_rights_court` | `universal_rights_declaration`, `constitutional_court` |  | `interrealm_permanent_court` |  |
| 2810 | `value_added_tax` | `national_income_accounts`, `salt_and_drink_excise` [1800-2400] |  | `audited_company_accounts`, `graduated_income_tax` [1800-2400] |  |
| 2818 | `common_market_union` | `customs_union`, `fixed_exchange_accord` |  | `league_of_realms`, `grain_tariff_repeal` |  |
| 2825 | `dependency_self_rule` | `dependencies_ministry`, `world_assembly_of_realms` |  | `universal_rights_declaration`, `settler_self_government_compact` [1800-2400] | contact_required=yes |
| 2832 | `public_defenders` | `constitutional_court` |  | `universal_rights_declaration`, `poor_petition_court` [1800-2400] |  |
| 2835 | `civil_rights_law` | `constitutional_court`, `universal_rights_declaration` |  | `nonviolent_rights_movements` [culture] |  |
| 2838 | `death_penalty_abolition` | `penitentiary_sentences`, `probation_parole` |  | `universal_rights_declaration`, `regional_rights_court` |  |
| 2840 | `freedom_of_information` | `press_freedom_statute` [1800-2400], `independent_audit_office` |  | `assembly_ombudsman` |  |
| 2845 | `ombudsman_network` | `assembly_ombudsman` |  | `administrative_courts`, `elected_county_councils` |  |
| 2852 | `floating_fiat_currency` | `fixed_exchange_accord`, `central_note_monopoly` |  | `countercyclical_spending` |  |
| 2858 | `personal_data_protection` | `universal_rights_declaration`, `relational_databases` [knowledge] |  | `punched_card_tabulation` [knowledge], `continuous_population_register` [demography] |  |
| 2860 | `anticorruption_commission` | `independent_audit_office` |  | `ombudsman_network`, `freedom_of_information` |  |
| 2872 | `state_enterprise_privatization` | `nationalized_core_industries`, `securities_commission` |  | `floating_fiat_currency` |  |
| 2885 | `truth_commissions` | `universal_rights_declaration`, `atrocity_tribunals` |  | `regional_rights_court` |  |
| 2898 | `participatory_budgets` | `elected_municipal_councils` [1800-2400], `annual_budget_vote` |  | `initiative_referendum` |  |
| 2900 | `inflation_targeting` | `floating_fiat_currency`, `national_income_accounts` |  | `central_note_monopoly` |  |
| 2905 | `electoral_commissions` | `secret_printed_ballot` |  | `proportional_representation`, `anticorruption_commission` |  |
| 2912 | `trade_dispute_panels` | `world_assembly_of_realms`, `interrealm_arbitration` |  | `common_market_union`, `fixed_exchange_accord` |  |
| 2922 | `single_currency_union` | `common_market_union`, `floating_fiat_currency` |  | `inflation_targeting` |  |
| 2925 | `online_government_services` | `world_hypertext_web` [knowledge] |  | `relational_databases` [knowledge], `competitive_civil_service` |  |
| 2928 | `equal_marriage_law` | `civil_rights_law` |  | `registered_partnerships` [demography], `womens_liberation_movement` [culture], `civil_divorce_courts` |  |
| 2930 | `digital_identity_register` | `continuous_population_register` [demography], `online_government_services` |  | `public_key_ciphers` [knowledge] |  |
| 2930 | `permanent_atrocity_court` | `atrocity_tribunals`, `interrealm_permanent_court` |  | `truth_commissions` |  |
| 2948 | `bank_stress_tests` | `deposit_insurance`, `securities_commission` |  | `lender_of_last_resort`, `constrained_optimization` [knowledge] |  |
| 2950 | `open_government_data` | `freedom_of_information`, `online_government_services` |  | `relational_databases` [knowledge] |  |
| 2960 | `lobbying_register` | `anticorruption_commission` |  | `freedom_of_information`, `open_government_data` |  |
| 2970 | `comprehensive_data_rights` | `personal_data_protection` |  | `online_social_networks` [culture], `cloud_data_halls` [knowledge] |  |
| 2978 | `global_minimum_tax` | `graduated_income_tax` [1800-2400], `trade_dispute_panels` |  | `offshored_work` [labor], `single_currency_union` |  |
| 2985 | `learned_machine_law` | `comprehensive_data_rights`, `large_language_models` [knowledge] |  | `algorithmic_feeds` [culture] |  |
| 2992 | `algorithmic_decision_audits` | `learned_machine_law`, `independent_audit_office` |  | `algorithmic_management` [labor] |  |
| 3000 | `central_bank_digital_currency` | `floating_fiat_currency`, `digital_identity_register` |  | `public_key_ciphers` [knowledge], `mobile_remittances` [demography] |  |

## Cross-line prerequisites assumed from other 2400–3000 lines

Hard parents owned by lines outside knowledge, institutions, culture and labor, mapped in parallel by other agents:

- `coal_gas_works` (production 2420) → `municipal_utilities`
- `mortality_table_insurance` (demography 2467) → `old_age_pensions`
- `worker_sickness_insurance` (health 2621) → `unemployment_insurance`
- `worker_sickness_insurance` (health 2621) → `welfare_state`
- `land_war_conventions` (security 2666) → `atrocity_tribunals`
- `continuous_population_register` (demography 2845) → `digital_identity_register`

## Prerequisites from the other kicl lines

- `research_university` (knowledge 2427) → `competitive_civil_service`
- `common_ownership_doctrine` (culture 2528) → `central_five_year_plan`
- `common_ownership_doctrine` (culture 2528) → `nationalized_core_industries`
- `womens_rights_convention` (culture 2528) → `womens_suffrage`
- `union_legal_standing` (labor 2587) → `corporatist_chambers`
- `trade_wide_employer_bargaining` (labor 2600) → `corporatist_chambers`
- `labor_statistics_bureau` (labor 2605) → `war_economy_boards`
- `punched_card_tabulation` (knowledge 2640) → `national_income_accounts`
- `statistical_sampling` (knowledge 2667) → `national_income_accounts`
- `public_labor_exchanges` (labor 2690) → `unemployment_insurance`
- `radio_broadcasting` (culture 2720) → `state_propaganda_ministry`
- `relational_databases` (knowledge 2850) → `personal_data_protection`
- `world_hypertext_web` (knowledge 2902) → `online_government_services`
- `large_language_models` (knowledge 2975) → `learned_machine_law`

## Year adjustments

None.
