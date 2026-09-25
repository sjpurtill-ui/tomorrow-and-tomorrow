# Labor dependencies: years 2400–3000

Machine-readable source: `partials/kicl.json` (knowledge, institutions, culture, labor). Contract: the 600–1200 mapping (`docs/research/y600/deps/partials/kicl.json`, merged by `tools/research/merge_graph_1200.py`) and its 1200–1800 and 1800–2400 successors. Ids come from `registry_3000.json`, `registry_2400.json` with the 1800–2400 partials, the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), and the game's baked 0–600 and 600–1200 blocks. Prerequisites may be ids of any earlier block in any line, or 2400–3000 ids, and every prerequisite and precedent is dated at or before its dependent (registry target years after the year adjustments; earlier blocks at their baked or graph years). Brackets mark a parent from another line or an earlier block: `[production]` is a 2400–3000 id owned by Production, `[ecology, 1800-2400]` is a 1800–2400 Ecology id, `[1200-1800]` is a same-line 1200–1800 id. `contact_required` marks items that need ocean contact, directly or through a contact-gated hard parent. Chains are modern (AD 1800–2030). Year moves for this line are listed at the end.

**110 entries, 165 hard edges, 159 precedent edges, 0 requires_any groups.** Contact-gated: `chattel_bondage_abolition`, `indentured_contract_migration`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2408 | `first_factory_act` | `pauper_mill_apprentices` [1800-2400] |  | `factory_shift_system` [1800-2400], `statutory_work_hours` [1800-2400] |  |
| 2412 | `overlookers_foremen` | `factory_fine_rules` [1800-2400] |  | `factory_shift_system` [1800-2400], `mill_hand_workforce` [1800-2400] |  |
| 2421 | `weavers_minimum_rate_petition` | `statutory_price_lists` [1800-2400] |  | `wage_assessment_lapse` [1800-2400] |  |
| 2430 | `secret_trade_societies` | `general_combination_ban` [1800-2400] |  | `journeymen_brotherhoods` [1200-1800], `houses_of_call` [1800-2400], `strike_funds` [1800-2400] |  |
| 2440 | `handloom_weaver_distress` | `iron_power_loom_sheds` [production] |  | `weavers_minimum_rate_petition`, `off_season_cottage_weaving` [1800-2400] |  |
| 2448 | `spinners_federation` | `strike_funds` [1800-2400], `mule_spinning` [production, 1800-2400] |  | `secret_trade_societies` |  |
| 2455 | `union_tramping_cards` | `strike_funds` [1800-2400] |  | `tramping_relief` [1800-2400], `spinners_federation` |  |
| 2460 | `mechanics_institutes` | `public_experiment_lectures` [knowledge, 1800-2400] |  | `subscription_libraries` [knowledge, 1800-2400], `state_polytechnic_school` [knowledge, 1800-2400], `reading_circles` [culture] |  |
| 2464 | `combination_ban_repeal` | `general_combination_ban` [1800-2400] |  | `secret_trade_societies`, `spinners_federation` |  |
| 2470 | `master_servant_penalties` | `worker_pass_books` [1800-2400] |  | `yearly_pitmen_bond` [1800-2400], `combination_ban_repeal` |  |
| 2470 | `mine_butty_gangs` | `navvy_gangs` [1800-2400] |  | `corf_piece_rates` [1800-2400], `lump_sum_building_contracts` [1800-2400] |  |
| 2483 | `coin_wages_act` | `truck_pay_ban` [1200-1800] |  | `pay_ticket_wages` [1800-2400] |  |
| 2488 | `factory_inspectorate` | `first_factory_act` |  | `single_minister_departments` [institutions] |  |
| 2490 | `chattel_bondage_abolition` | `bound_labor_abolition_movement` [1800-2400] |  | `plantation_gang_labor` [1800-2400], `estate_bondage_abolition` [1800-2400] | contact_required=yes |
| 2500 | `indentured_contract_migration` | `chattel_bondage_abolition`, `indentured_passage` [1800-2400] |  | `overseas_bound_estate_labor` [1800-2400], `island_cane_plantations` [nutrition, 1800-2400] | contact_required=yes |
| 2507 | `underground_work_limits` | `factory_inspectorate` |  | `mining_ordinances` [1800-2400] |  |
| 2512 | `consumer_cooperatives` | `friendly_society_boxes` [1800-2400] |  | `registered_friendly_societies` [1800-2400], `factory_villages` [1800-2400] |  |
| 2515 | `half_time_schooling` | `factory_inspectorate`, `compulsory_parish_schooling` [knowledge, 1800-2400] |  | `spinning_schools` [1800-2400] |  |
| 2525 | `ten_hour_day` | `factory_inspectorate` |  | `statutory_work_hours` [1800-2400], `eight_hour_mine_shifts` [1800-2400] |  |
| 2536 | `amalgamated_craft_unions` | `strike_funds` [1800-2400], `combination_ban_repeal` |  | `union_tramping_cards`, `registered_friendly_societies` [1800-2400] |  |
| 2540 | `saturday_half_holiday` | `ten_hour_day` |  | `saint_monday_custom` [1800-2400] |  |
| 2545 | `district_rate_lists` | `joint_rate_boards` [1200-1800], `combination_ban_repeal` |  | `statutory_price_lists` [1800-2400], `amalgamated_craft_unions` |  |
| 2555 | `sweated_home_work` | `sewing_machine_mechanisms` [production] |  | `debt_bound_putting_out` [1200-1800], `rural_putting_out` [1200-1800] |  |
| 2560 | `company_towns` | `factory_villages` [1800-2400] |  | `crown_works_settlements` [1800-2400], `model_worker_dwellings` [infrastructure] |  |
| 2565 | `railway_staff_hierarchy` | `public_steam_railway` [logistics], `intercity_passenger_railway` [logistics] |  | `printed_railway_timetables` [logistics], `railway_clearing_house` [logistics] |  |
| 2580 | `worker_owned_workshops` | `consumer_cooperatives` |  | `limited_liability_registration` [institutions] |  |
| 2585 | `employer_lockouts` | `amalgamated_craft_unions` |  | `district_rate_lists`, `coal_river_strikes` [1800-2400] |  |
| 2587 | `union_legal_standing` | `combination_ban_repeal`, `amalgamated_craft_unions` |  | `manhood_suffrage` [institutions] |  |
| 2590 | `machine_guarding_rules` | `factory_inspectorate` |  | `belt_power_transmission` [production, 1800-2400] |  |
| 2595 | `conciliation_boards` | `district_rate_lists` |  | `employer_lockouts` |  |
| 2597 | `peaceful_picketing` | `union_legal_standing` |  |  |  |
| 2600 | `trade_wide_employer_bargaining` | `employer_lockouts` |  | `conciliation_boards` |  |
| 2602 | `rail_harvest_gangs` | `acre_rate_harvest_gangs` [1800-2400], `public_steam_railway` [logistics] |  | `gang_master_harvest_crews` [1800-2400] |  |
| 2605 | `labor_statistics_bureau` | `state_statistical_office` [demography] |  | `amalgamated_craft_unions`, `statistical_inference` [knowledge] |  |
| 2613 | `employer_liability_law` | `factory_inspectorate` |  | `machine_guarding_rules`, `union_legal_standing`, `commercial_code` [institutions] |  |
| 2615 | `women_office_clerks` | `compulsory_elementary_schooling` [knowledge] |  | `telephone_circuits` [knowledge], `manual_switchboards` [knowledge] |  |
| 2617 | `shop_hours_limits` | `factory_inspectorate` |  | `saturday_half_holiday`, `ten_hour_day` |  |
| 2620 | `blacklists_and_no_union_pledges` | `employer_lockouts` |  | `company_towns` |  |
| 2625 | `profit_sharing_schemes` | `limited_liability_registration` [institutions] |  | `worker_owned_workshops`, `share_exchange_bourse` [institutions, 1800-2400] |  |
| 2630 | `accident_insurance` | `employer_liability_law`, `worker_sickness_insurance` [health] |  | `mortality_table_insurance` [demography] |  |
| 2632 | `time_clock_recording` | `pendulum_regulated_clock` [knowledge, 1800-2400], `overlookers_foremen` |  | `mine_shift_registers` [1800-2400] |  |
| 2634 | `eight_hour_campaign` | `ten_hour_day`, `union_legal_standing` |  | `amalgamated_craft_unions` |  |
| 2636 | `general_unions` | `amalgamated_craft_unions`, `union_legal_standing` |  | `employer_lockouts` |  |
| 2641 | `job_cost_accounting` | `double_entry_ledgers` [institutions, 1200-1800], `time_clock_recording` |  | `audited_company_accounts` [institutions] |  |
| 2644 | `child_labor_prohibition` | `factory_inspectorate`, `compulsory_elementary_schooling` [knowledge] |  | `half_time_schooling`, `underground_work_limits` |  |
| 2650 | `premium_bonus_pay` | `time_clock_recording`, `job_cost_accounting` |  | `gauged_piece_tickets` [1800-2400] |  |
| 2660 | `minimum_wage_boards` | `sweated_home_work`, `conciliation_boards` |  | `weavers_minimum_rate_petition` |  |
| 2663 | `examined_trade_apprenticeships` | `apprentice_indentures` [1200-1800], `mechanics_institutes` |  | `compulsory_elementary_schooling` [knowledge], `state_polytechnic_school` [knowledge, 1800-2400] |  |
| 2665 | `industrial_arbitration_courts` | `conciliation_boards`, `union_legal_standing` |  | `trade_wide_employer_bargaining` |  |
| 2667 | `work_rest_limits` | `ten_hour_day`, `statistical_sampling` [knowledge] |  | `eight_hour_campaign` |  |
| 2680 | `scheduled_occupational_diseases` | `accident_insurance` |  | `trade_diseases_treatise` [health, 1800-2400], `disease_notification_law` [health] |  |
| 2688 | `general_strike` | `general_unions` |  | `eight_hour_campaign`, `workers_festival_day` [culture] |  |
| 2690 | `public_labor_exchanges` | `labor_statistics_bureau`, `servant_register_offices` [1800-2400] |  | `union_tramping_cards`, `telephone_circuits` [knowledge] |  |
| 2696 | `work_motion_studies` | `time_clock_recording`, `premium_bonus_pay` |  | `job_cost_accounting`, `fixed_light_images` [knowledge], `work_rest_limits` |  |
| 2700 | `labor_ministry` | `labor_statistics_bureau`, `single_minister_departments` [institutions] |  | `public_labor_exchanges` |  |
| 2701 | `moving_assembly_line` | `work_motion_studies`, `interchangeable_component_fits` [production] |  | `machine_block_line` [production], `series_built_motor_car` [logistics], `electric_motors` [production] |  |
| 2703 | `domestic_service_decline` | `women_office_clerks` |  | `compulsory_elementary_schooling` [knowledge], `mechanical_washing_machines` [production] |  |
| 2704 | `high_day_wage` | `moving_assembly_line` |  |  |  |
| 2710 | `industrial_welfare_departments` | `company_towns` |  | `accident_insurance`, `codified_ball_games` [culture] |  |
| 2715 | `employment_departments` | `job_cost_accounting`, `public_labor_exchanges` |  | `work_motion_studies`, `high_day_wage` |  |
| 2717 | `eight_hour_day_law` | `eight_hour_campaign`, `labor_ministry` |  | `general_strike` |  |
| 2719 | `standing_labor_conference` | `labor_ministry`, `league_of_realms` [institutions] |  |  |  |
| 2721 | `works_councils` | `union_legal_standing`, `labor_ministry` |  | `industrial_arbitration_courts` |  |
| 2735 | `five_day_week` | `saturday_half_holiday`, `eight_hour_day_law` |  | `moving_assembly_line` |  |
| 2740 | `work_group_morale_studies` | `work_motion_studies`, `statistical_sampling` [knowledge] |  | `employment_departments` |  |
| 2745 | `slump_hunger_marches` | `unemployment_insurance` [institutions] |  | `general_unions`, `general_strike` |  |
| 2750 | `public_relief_works` | `labor_ministry`, `public_labor_exchanges` |  | `famine_relief_works` [nutrition], `public_work_relief` [1800-2400] |  |
| 2758 | `industrial_unions` | `general_unions`, `moving_assembly_line` |  | `works_councils` |  |
| 2760 | `collective_bargaining_law` | `union_legal_standing`, `industrial_arbitration_courts` |  | `industrial_unions`, `labor_ministry` |  |
| 2762 | `sit_down_strikes` | `industrial_unions`, `moving_assembly_line` |  |  |  |
| 2763 | `paid_annual_holidays` | `eight_hour_day_law` |  | `five_day_week`, `excursion_tourism` [culture] |  |
| 2765 | `penal_labor_camps` | `one_party_state` [institutions], `penitentiary_sentences` [institutions] |  | `convict_transportation` [demography, 1800-2400], `political_police_bureau` [security] |  |
| 2768 | `national_minimum_wage` | `minimum_wage_boards`, `labor_ministry` |  | `collective_bargaining_law`, `eight_hour_day_law` |  |
| 2778 | `total_labor_mobilization` | `war_economy_boards` [institutions], `class_year_conscription` [security] |  | `women_office_clerks`, `public_labor_exchanges` |  |
| 2782 | `wartime_wage_controls` | `war_economy_boards` [institutions], `collective_bargaining_law` |  | `national_minimum_wage` |  |
| 2795 | `tripartite_wage_bargaining` | `collective_bargaining_law`, `labor_ministry` |  | `corporatist_chambers` [institutions], `wartime_wage_controls` |  |
| 2803 | `board_level_codetermination` | `works_councils` |  | `tripartite_wage_bargaining`, `limited_liability_registration` [institutions] |  |
| 2810 | `negotiated_occupational_pensions` | `old_age_pensions` [institutions], `collective_bargaining_law` |  | `mortality_table_insurance` [demography] |  |
| 2828 | `public_sector_unions` | `collective_bargaining_law`, `competitive_civil_service` [institutions] |  |  |  |
| 2832 | `quality_circles` | `work_group_morale_studies`, `statistical_sampling` [knowledge] |  |  |  |
| 2835 | `automation_retraining` | `industrial_robots` [production] |  | `numerical_machine_control` [production], `unemployment_insurance` [institutions], `examined_trade_apprenticeships` |  |
| 2835 | `equal_pay_law` | `civil_rights_law` [institutions], `national_minimum_wage` |  | `womens_suffrage` [institutions], `total_labor_mobilization` |  |
| 2843 | `flexible_working_hours` | `time_clock_recording`, `five_day_week` |  |  |  |
| 2845 | `lean_production` | `moving_assembly_line`, `quality_circles` |  | `statistical_sampling` [knowledge] |  |
| 2850 | `occupational_safety_agency` | `machine_guarding_rules`, `labor_ministry` |  | `scheduled_occupational_diseases` |  |
| 2855 | `age_discrimination_ban` | `civil_rights_law` [institutions] |  |  |  |
| 2862 | `redundancy_pay` | `collective_bargaining_law` |  | `unemployment_insurance` [institutions], `industrial_robots` [production] |  |
| 2870 | `service_economy_shift` | `national_income_accounts` [institutions], `women_office_clerks` |  | `mass_higher_education` [knowledge] |  |
| 2875 | `temporary_agency_work` | `public_labor_exchanges` |  | `service_economy_shift` |  |
| 2880 | `labor_market_deregulation` | `collective_bargaining_law` |  | `state_enterprise_privatization` [institutions], `temporary_agency_work`, `floating_fiat_currency` [institutions] |  |
| 2885 | `desktop_office_work` | `desk_computers` [knowledge] |  | `women_office_clerks` |  |
| 2887 | `workplace_harassment_rules` | `civil_rights_law` [institutions] |  | `womens_liberation_movement` [culture] |  |
| 2890 | `offshored_work` | `intermodal_shipping_containers` [logistics] |  | `labor_market_deregulation`, `data_modems` [knowledge] |  |
| 2900 | `disability_accommodation` | `civil_rights_law` [institutions] |  | `accessible_building_rules` [infrastructure] |  |
| 2905 | `call_centre_work` | `desk_computers` [knowledge], `data_modems` [knowledge] |  | `service_economy_shift`, `work_motion_studies` |  |
| 2908 | `common_working_time_rules` | `eight_hour_day_law`, `common_market_union` [institutions] |  |  |  |
| 2915 | `networked_telework` | `world_hypertext_web` [knowledge], `desktop_office_work` |  |  |  |
| 2935 | `zero_hours_contracts` | `temporary_agency_work`, `labor_market_deregulation` |  |  |  |
| 2940 | `living_wage_indexing` | `national_minimum_wage` |  | `statistical_sampling` [knowledge], `national_income_accounts` [institutions] |  |
| 2948 | `platform_gig_work` | `pocket_networked_computers` [knowledge], `temporary_agency_work` |  |  |  |
| 2955 | `algorithmic_management` | `platform_gig_work` |  | `deep_learning_networks` [knowledge] |  |
| 2968 | `right_to_disconnect` | `networked_telework`, `pocket_networked_computers` [knowledge] |  | `eight_hour_day_law` |  |
| 2978 | `platform_worker_status` | `platform_gig_work` |  | `zero_hours_contracts`, `industrial_arbitration_courts` |  |
| 2980 | `worker_monitoring_limits` | `algorithmic_management`, `personal_data_protection` [institutions] |  | `comprehensive_data_rights` [institutions] |  |
| 2985 | `four_day_week_trials` | `five_day_week` |  | `networked_telework` |  |
| 2986 | `paid_care_work` | `old_age_pensions` [institutions] |  | `long_term_care_insurance` [demography], `paid_parental_leave` [demography] |  |
| 2988 | `heat_stress_work_limits` | `work_rest_limits`, `occupational_safety_agency` |  | `extreme_event_attribution` [ecology] |  |
| 2990 | `machine_assistant_desk_work` | `desktop_office_work`, `large_language_models` [knowledge] |  |  |  |
| 2992 | `lifelong_learning_accounts` | `automation_retraining` |  | `mass_higher_education` [knowledge], `online_government_services` [institutions] |  |
| 2996 | `basic_income_pilots` | `welfare_state` [institutions] |  | `mobile_remittances` [demography], `machine_assistant_desk_work`, `living_wage_indexing` |  |

## Cross-line prerequisites assumed from other 2400–3000 lines

Hard parents owned by lines outside knowledge, institutions, culture and labor, mapped in parallel by other agents:

- `class_year_conscription` (security 2411) → `total_labor_mobilization`
- `interchangeable_component_fits` (production 2424) → `moving_assembly_line`
- `iron_power_loom_sheds` (production 2440) → `handloom_weaver_distress`
- `public_steam_railway` (logistics 2467) → `rail_harvest_gangs`
- `public_steam_railway` (logistics 2467) → `railway_staff_hierarchy`
- `intercity_passenger_railway` (logistics 2480) → `railway_staff_hierarchy`
- `state_statistical_office` (demography 2480) → `labor_statistics_bureau`
- `sewing_machine_mechanisms` (production 2523) → `sweated_home_work`
- `worker_sickness_insurance` (health 2621) → `accident_insurance`
- `intermodal_shipping_containers` (logistics 2815) → `offshored_work`
- `industrial_robots` (production 2834) → `automation_retraining`

## Prerequisites from the other kicl lines

- `single_minister_departments` (institutions 2427) → `labor_ministry`
- `penitentiary_sentences` (institutions 2453) → `penal_labor_camps`
- `competitive_civil_service` (institutions 2541) → `public_sector_unions`
- `limited_liability_registration` (institutions 2547) → `profit_sharing_schemes`
- `compulsory_elementary_schooling` (knowledge 2587) → `child_labor_prohibition`
- `compulsory_elementary_schooling` (knowledge 2587) → `women_office_clerks`
- `old_age_pensions` (institutions 2637) → `negotiated_occupational_pensions`
- `old_age_pensions` (institutions 2637) → `paid_care_work`
- `statistical_sampling` (knowledge 2667) → `quality_circles`
- `statistical_sampling` (knowledge 2667) → `work_group_morale_studies`
- `statistical_sampling` (knowledge 2667) → `work_rest_limits`
- `unemployment_insurance` (institutions 2696) → `slump_hunger_marches`
- `war_economy_boards` (institutions 2704) → `total_labor_mobilization`
- `war_economy_boards` (institutions 2704) → `wartime_wage_controls`
- `one_party_state` (institutions 2712) → `penal_labor_camps`
- `league_of_realms` (institutions 2717) → `standing_labor_conference`
- `national_income_accounts` (institutions 2757) → `service_economy_shift`
- `welfare_state` (institutions 2789) → `basic_income_pilots`
- `common_market_union` (institutions 2818) → `common_working_time_rules`
- `data_modems` (knowledge 2825) → `call_centre_work`
- `civil_rights_law` (institutions 2835) → `age_discrimination_ban`
- `civil_rights_law` (institutions 2835) → `disability_accommodation`
- `civil_rights_law` (institutions 2835) → `equal_pay_law`
- `civil_rights_law` (institutions 2835) → `workplace_harassment_rules`
- `personal_data_protection` (institutions 2858) → `worker_monitoring_limits`
- `desk_computers` (knowledge 2868) → `call_centre_work`
- `desk_computers` (knowledge 2868) → `desktop_office_work`
- `world_hypertext_web` (knowledge 2902) → `networked_telework`
- `pocket_networked_computers` (knowledge 2942) → `platform_gig_work`
- `pocket_networked_computers` (knowledge 2942) → `right_to_disconnect`
- `large_language_models` (knowledge 2975) → `machine_assistant_desk_work`

## Year adjustments

- `automation_retraining`: 2830 → 2835. Continues industrial_robots (production 2834); the registry had the dependent 4 years before its parent. Moved to 2835, inside band 2805-2855.
