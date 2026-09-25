# Labor dependencies: years 1800–2400

Machine-readable source: `partials/kicl.json` (knowledge, institutions, culture, labor). Contract: the 600–1200 and 1200–1800 mappings (`docs/research/y600/deps/partials/kicl.json`, `docs/research/y1200/deps/partials/kicl.json`, merged by `tools/research/merge_graph_1200.py` and `merge_graph_1800.py`). Ids come from `registry_2400.json`, the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), the 600–1200 graph, the 0–600 graph and the game's baked blocks. Prerequisites may be ids of any earlier block in any line, or 1800–2400 ids, and every prerequisite and precedent is dated at or before its dependent (registry target years; earlier blocks at their baked years). Brackets mark a parent from another line or an earlier block: `[production]` is a 1800–2400 id owned by Production, `[ecology, 1200-1800]` is a 1200–1800 Ecology id, `[0-600]` is a same-line 0–600 id. `contact_required` marks items that need ocean contact, directly or through a contact-gated hard parent. No year moves are proposed for this line.

**99 entries, 165 hard edges, 148 precedent edges, 0 requires_any groups.** Contact-gated: `overseas_bound_estate_labor`, `plantation_gang_labor`, `rotating_mine_drafts`, `indentured_passage`, `bound_labor_abolition_movement`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1804 | `quarter_session_wage_hearings` | `post_plague_labor_statutes` [1200-1800], `quarter_session_justices` [institutions] |  | `hiring_fairs` [1200-1800] |  |
| 1815 | `cloth_workers_guild_demand` | `cloth_craft_chain` [1200-1800], `craft_guilds` [institutions, 1200-1800] |  | `weaver_walkouts` [1200-1800], `journeymen_brotherhoods` [1200-1800] |  |
| 1818 | `tenant_leagues_against_bondage` | `laborer_mobility` [1200-1800], `post_plague_labor_statutes` [1200-1800] |  | `poll_tax_per_head` [institutions], `sworn_town_commune` [institutions, 1200-1800] |  |
| 1822 | `board_and_dry_wage_rates` | `seasonal_day_rates` [1200-1800], `coin_and_ration_wages` [600-1200] |  | `post_plague_labor_statutes` [1200-1800] |  |
| 1826 | `journeymen_town_boycotts` | `journeymen_brotherhoods` [1200-1800] |  | `weaver_walkouts` [1200-1800], `guild_fixed_journey_rates` [1200-1800] |  |
| 1830 | `begging_licence_badges` | `vagrant_expulsion` [demography, 1200-1800] |  | `post_plague_labor_statutes` [1200-1800], `aged_almshouses` [health, 1200-1800] |  |
| 1835 | `roll_copy_tenure` | `general_rent_commutation` [1200-1800], `manor_court_customals` [institutions, 1200-1800] |  | `estate_survey_books` [1200-1800] |  |
| 1840 | `demesne_leasing_to_farmers` | `general_rent_commutation` [1200-1800] |  | `improvement_leases` [1200-1800], `cottager_day_laborers` [1200-1800] |  |
| 1846 | `mining_ordinances` | `free_miner_companies` [1200-1800] |  | `miners_relief_chest` [1200-1800], `town_trade_statute_book` [1200-1800] |  |
| 1850 | `mandatory_wander_years` | `journeyman_passes` [1200-1800], `journeymen_brotherhoods` [1200-1800] |  | `closed_mastership` [1200-1800] |  |
| 1853 | `eight_hour_mine_shifts` | `mining_ordinances` |  | `saltworks_shift_crews` [1200-1800], `striking_equal_hour_clock` [knowledge, 1200-1800] |  |
| 1856 | `dawn_hiring_squares` | `cottager_day_laborers` [1200-1800], `laborer_mobility` [1200-1800] |  | `work_bell_hours` [1200-1800] |  |
| 1860 | `arsenal_sequence_fitting` | `state_shipyard_workforce` [1200-1800], `series_built_war_galleys` [security, 1200-1800] |  | `cloth_craft_chain` [1200-1800] |  |
| 1864 | `convict_galley_oarsmen` | `convict_work_gangs` [1200-1800], `spur_prow_galleys` [security, 1200-1800] |  | `captive_ransom_brotherhoods` [demography, 1200-1800] |  |
| 1868 | `off_season_cottage_weaving` | `rural_putting_out` [1200-1800] |  | `cottager_day_laborers` [1200-1800], `rented_loom_putting_out` [1200-1800] |  |
| 1872 | `statutory_work_hours` | `post_plague_labor_statutes` [1200-1800], `work_bell_hours` [1200-1800] |  | `striking_equal_hour_clock` [knowledge, 1200-1800] |  |
| 1876 | `lump_sum_building_contracts` | `master_mason_retainers` [1200-1800], `notarized_work_contracts` [600-1200] |  | `weekly_works_payrolls` [1200-1800] |  |
| 1880 | `permanent_journeymen` | `closed_mastership` [1200-1800] |  | `mandatory_wander_years`, `journeymen_town_boycotts` |  |
| 1884 | `shareholder_wage_miners` | `free_miner_companies` [1200-1800], `mining_ordinances` |  | `funded_public_debt_shares` [institutions, 1200-1800], `eight_hour_mine_shifts` |  |
| 1893 | `wage_books` | `weekly_works_payrolls` [1200-1800], `double_entry_ledgers` [institutions, 1200-1800] |  | `board_and_dry_wage_rates` |  |
| 1894 | `printing_house_crews` | `town_printing_houses` [knowledge] |  | `hand_relief_printing` [knowledge], `metal_type_casting` [knowledge] |  |
| 1896 | `export_estate_labor_dues` | `week_work_service` [1200-1800], `bound_estate_tenants` [institutions, 1200-1800] |  | `hereditary_unfree_status` [demography, 1200-1800] |  |
| 1900 | `tramping_relief` | `journeymen_brotherhoods` [1200-1800], `journeyman_passes` [1200-1800] |  | `mandatory_wander_years`, `guild_welfare_chests` [1200-1800] |  |
| 1904 | `furnace_campaign_crews` | `blast_furnace` [production, 1200-1800] |  | `load_paid_forest_crews` [1200-1800], `cast_iron_shot_firebacks` [production] |  |
| 1908 | `vagrancy_return_laws` | `begging_licence_badges` |  | `vagrant_expulsion` [demography, 1200-1800], `parish_constables` [security] |  |
| 1912 | `putting_out_ledgers` | `rented_loom_putting_out` [1200-1800], `double_entry_ledgers` [institutions, 1200-1800] |  | `wage_books` |  |
| 1916 | `fathom_bid_contracts` | `shareholder_wage_miners` |  | `lump_sum_building_contracts` |  |
| 1924 | `guild_loom_exclusion` | `womens_craft_guilds` [1200-1800], `closed_mastership` [1200-1800] |  | `permanent_journeymen` |  |
| 1928 | `public_work_relief` | `begging_licence_badges` |  | `convict_work_gangs` [1200-1800], `vagrancy_return_laws` |  |
| 1933 | `clothier_household_workshops` | `debt_bound_putting_out` [1200-1800], `putting_out_ledgers` |  | `cloth_craft_chain` [1200-1800] |  |
| 1937 | `overseas_bound_estate_labor` | `island_cane_plantations` [nutrition], `transoceanic_contact_voyages` [logistics] |  | `hereditary_unfree_status` [demography, 1200-1800], `captive_trained_corps` [security, 1200-1800] | contact_required=yes |
| 1941 | `fewer_holy_days` | `printed_reform_dispute` [culture] |  | `civic_holiday_calendar` [600-1200], `holy_servants_feast_year` [culture, 1200-1800] |  |
| 1946 | `compositor_strikes` | `printing_house_crews` |  | `journeymen_town_boycotts`, `weaver_walkouts` [1200-1800] |  |
| 1950 | `plantation_gang_labor` | `overseas_bound_estate_labor`, `island_cane_plantations` [nutrition] |  | `refined_loaf_sugar` [nutrition, 1200-1800] | contact_required=yes |
| 1961 | `correction_workhouses` | `public_work_relief`, `vagrancy_return_laws` |  | `convict_work_gangs` [1200-1800] |  |
| 1966 | `rotating_mine_drafts` | `rotating_artisan_service` [1200-1800], `overseas_viceroyalties` [institutions] |  | `mercury_ore_amalgamation` [production] | contact_required=yes |
| 1969 | `realm_artisan_statute` | `apprentice_indentures` [1200-1800], `quarter_session_wage_hearings` |  | `town_trade_statute_book` [1200-1800], `board_and_dry_wage_rates` |  |
| 1977 | `compulsory_poor_rate` | `begging_licence_badges`, `public_work_relief` |  | `compulsory_tithe` [institutions, 1200-1800], `correction_workhouses` |  |
| 1983 | `acre_rate_harvest_gangs` | `sheaf_share_reaping` [1200-1800], `migrant_harvest_crews` [1200-1800] |  | `board_and_dry_wage_rates` |  |
| 1990 | `bound_colliers` | `sea_coal_substitution` [ecology, 1200-1800], `hereditary_unfree_status` [demography, 1200-1800] |  | `mining_ordinances`, `bound_estate_tenants` [institutions, 1200-1800] |  |
| 1995 | `central_manufactory` | `cloth_craft_chain` [1200-1800], `clothier_household_workshops` |  | `arsenal_sequence_fitting` |  |
| 2002 | `parish_poor_law` | `compulsory_poor_rate`, `apprentice_indentures` [1200-1800] |  | `correction_workhouses` |  |
| 2006 | `company_servant_terms` | `salaried_trade_factors` [1200-1800], `joint_stock_company` [institutions] |  | `fortified_trading_posts` [logistics] |  |
| 2010 | `poor_work_stock` | `parish_poor_law` |  | `correction_workhouses` |  |
| 2014 | `gang_master_harvest_crews` | `migrant_harvest_crews` [1200-1800], `acre_rate_harvest_gangs` |  | `dawn_hiring_squares` |  |
| 2026 | `printed_wage_assessments` | `realm_artisan_statute`, `town_printing_houses` [knowledge] |  | `quarter_session_wage_hearings` |  |
| 2036 | `indentured_passage` | `overseas_bound_estate_labor`, `apprentice_indentures` [1200-1800] |  | `overseas_settler_colonies` [demography] | contact_required=yes |
| 2044 | `lace_schools` | `bobbin_lace` [production] |  | `parish_poor_law`, `needle_lace` [production] |  |
| 2052 | `dockyard_task_work` | `state_shipyard_workforce` [1200-1800] |  | `arsenal_sequence_fitting`, `carver_piece_rates` [1200-1800] |  |
| 2066 | `commoner_hedge_riots` | `enclosure_by_agreement` [ecology] |  | `sheep_enclosure_depopulation` [ecology], `fen_drainage_cuts` [infrastructure], `tenant_leagues_against_bondage` |  |
| 2078 | `corf_piece_rates` | `bound_colliers` |  | `carver_piece_rates` [1200-1800], `wage_books` |  |
| 2090 | `frame_rent_knitters` | `stocking_knitting_frame` [production], `rented_loom_putting_out` [1200-1800] |  | `putting_out_ledgers` |  |
| 2098 | `freeborn_labor_debates` | `estates_rule_without_ruler` [institutions] |  | `petition_of_right` [institutions], `printed_weekly_news` [knowledge] |  |
| 2106 | `seamens_articles` | `voyage_share_wages` [1200-1800], `written_sea_customs` [logistics, 1200-1800] |  | `company_servant_terms` |  |
| 2114 | `licensed_numbered_carters` | `sworn_porter_guilds` [1200-1800] |  | `hackney_coaches` [logistics] |  |
| 2126 | `settlement_removal_laws` | `vagrancy_return_laws`, `parish_poor_law` |  | `restoration_amnesty` [institutions] |  |
| 2132 | `privileged_crown_manufactories` | `mercantile_trade_council` [institutions], `central_manufactory` |  | `guild_trade_monopoly` [1200-1800] |  |
| 2134 | `rebuild_trade_opening` | `guild_trade_monopoly` [1200-1800], `fire_rebuilding_acts` [infrastructure] |  |  |  |
| 2142 | `pay_ticket_wages` | `wage_books`, `dockyard_task_work` |  | `treasury_paper_notes` [institutions, 1200-1800] |  |
| 2150 | `houses_of_call` | `journeymen_brotherhoods` [1200-1800], `permanent_journeymen` |  | `tramping_relief` |  |
| 2160 | `customary_perquisites` | `dockyard_task_work` |  | `clothier_household_workshops` |  |
| 2170 | `crown_works_settlements` | `privileged_crown_manufactories` |  | `arsenal_sequence_fitting` |  |
| 2180 | `recruited_foreign_craftsmen` | `joint_stock_company` [institutions], `privileged_crown_manufactories` |  | `company_servant_terms` |  |
| 2190 | `friendly_society_boxes` | `guild_welfare_chests` [1200-1800], `houses_of_call` |  | `miners_relief_chest` [1200-1800], `probability_theory` [knowledge] |  |
| 2194 | `seamens_hospital_levy` | `seamens_articles`, `invalid_soldiers_hospital` [health] |  | `charity_hospitals` [health, 600-1200] |  |
| 2206 | `coal_river_strikes` | `corf_piece_rates` |  | `compositor_strikes` |  |
| 2214 | `spinning_schools` | `poor_work_stock`, `central_manufactory` |  | `lace_schools`, `compulsory_parish_schooling` [knowledge] |  |
| 2222 | `family_moulder_gangs` | `clamp_fired_brick` [production, 1200-1800], `brick_quotas` [0-600] |  | `carver_piece_rates` [1200-1800], `stamped_brickyard_output` [600-1200] |  |
| 2230 | `loom_shop_cottages` | `off_season_cottage_weaving`, `house_glass_windows` [infrastructure, 1200-1800] |  | `clothier_household_workshops` |  |
| 2238 | `mill_hand_workforce` | `silk_throwing_mills` [production, 1200-1800], `central_manufactory` |  | `work_bell_hours` [1200-1800], `crown_works_settlements` |  |
| 2242 | `artisan_emigration_bans` | `recruited_foreign_craftsmen` |  | `mercantile_trade_council` [institutions], `travel_passports` [security] |  |
| 2246 | `workhouse_test` | `parish_poor_law`, `settlement_removal_laws` |  | `correction_workhouses`, `poor_work_stock` |  |
| 2250 | `town_wide_combinations` | `houses_of_call`, `journeymen_town_boycotts` |  | `friendly_society_boxes` |  |
| 2256 | `saint_monday_custom` | `fewer_holy_days` |  | `work_bell_hours` [1200-1800], `frame_rent_knitters` |  |
| 2262 | `servant_register_offices` | `hiring_fairs` [1200-1800], `daily_printed_newspaper` [knowledge] |  |  |  |
| 2270 | `gauged_piece_tickets` | `pay_ticket_wages` |  | `putting_out_ledgers`, `carver_piece_rates` [1200-1800] |  |
| 2278 | `mine_shift_registers` | `mining_ordinances`, `eight_hour_mine_shifts` |  | `wage_books`, `fathom_bid_contracts` |  |
| 2286 | `perquisite_strikes` | `customary_perquisites` |  | `coal_river_strikes` |  |
| 2294 | `pin_shop_division` | `central_manufactory` |  | `nailer_workshops` [production, 1200-1800] |  |
| 2302 | `yearly_pitmen_bond` | `bound_colliers` |  | `corf_piece_rates`, `hiring_fairs` [1200-1800] |  |
| 2310 | `navvy_gangs` | `gang_master_harvest_crews`, `staircase_summit_canal` [logistics] |  | `fen_drainage_cuts` [infrastructure] |  |
| 2326 | `strike_funds` | `town_wide_combinations`, `friendly_society_boxes` |  | `coal_river_strikes` |  |
| 2332 | `wage_assessment_lapse` | `printed_wage_assessments` |  | `free_grain_trade_doctrine` [institutions], `town_wide_combinations` |  |
| 2340 | `factory_shift_system` | `mill_hand_workforce`, `roller_water_frame` [production] |  | `eight_hour_mine_shifts`, `striking_equal_hour_clock` [knowledge, 1200-1800] |  |
| 2344 | `landless_wage_laborers` | `cottager_day_laborers` [1200-1800], `enclosure_by_agreement` [ecology], `assembly_enclosure_acts` [ecology] |  | `commoner_hedge_riots`, `demesne_leasing_to_farmers` |  |
| 2346 | `statutory_price_lists` | `joint_rate_boards` [1200-1800], `quarter_session_wage_hearings` |  | `printed_wage_assessments`, `strike_funds` |  |
| 2350 | `factory_villages` | `factory_shift_system`, `crown_works_settlements` |  | `loom_shop_cottages` |  |
| 2353 | `trade_freedom_edict` | `guild_trade_monopoly` [1200-1800], `free_grain_trade_doctrine` [institutions] |  | `rebuild_trade_opening`, `privileged_crown_manufactories` |  |
| 2356 | `division_of_labor_doctrine` | `pin_shop_division`, `free_grain_trade_doctrine` [institutions] |  | `reasoned_trades_encyclopedia` [knowledge], `central_manufactory` |  |
| 2360 | `pauper_mill_apprentices` | `parish_poor_law`, `factory_shift_system` |  | `spinning_schools` |  |
| 2364 | `machine_breaking_riots` | `weaver_walkouts` [1200-1800], `multi_spindle_spinning` [production] |  | `gig_mill_napping` [production], `commoner_hedge_riots` |  |
| 2367 | `worker_pass_books` | `journeyman_passes` [1200-1800] |  | `lodging_guest_registers` [demography], `mandatory_wander_years`, `wage_books` |  |
| 2370 | `factory_fine_rules` | `factory_shift_system` |  | `statutory_work_hours` |  |
| 2374 | `bound_labor_abolition_movement` | `overseas_bound_estate_labor`, `daily_printed_newspaper` [knowledge] |  | `sentimental_novel` [culture], `declaration_of_rights` [institutions] | contact_required=yes |
| 2378 | `estate_bondage_abolition` | `export_estate_labor_dues`, `abolition_of_estate_privileges` [institutions] |  | `tenant_leagues_against_bondage`, `servant_ruler_doctrine` [institutions] |  |
| 2383 | `registered_friendly_societies` | `friendly_society_boxes` |  | `strike_funds`, `actuarial_widows_fund` [demography] |  |
| 2388 | `bread_scale_wage_supplements` | `parish_poor_law`, `printed_grain_prices` [nutrition] |  | `workhouse_test`, `landless_wage_laborers` |  |
| 2393 | `general_combination_ban` | `town_wide_combinations`, `strike_funds` |  | `emergency_safety_committee` [institutions], `machine_breaking_riots` |  |
| 2398 | `collier_bond_release` | `bound_colliers`, `yearly_pitmen_bond` |  | `estate_bondage_abolition` |  |

## Cross-line prerequisites assumed from other 1800–2400 lines

These ids are mapped by other partials in parallel; each edge assumes the parent keeps its registry year. Hard edges only; precedents are listed in the table.

- `island_cane_plantations` (nutrition 1878) → `overseas_bound_estate_labor`
- `island_cane_plantations` (nutrition 1878) → `plantation_gang_labor`
- `transoceanic_contact_voyages` (logistics 1912) → `overseas_bound_estate_labor`
- `enclosure_by_agreement` (ecology 1935) → `commoner_hedge_riots`
- `enclosure_by_agreement` (ecology 1935) → `landless_wage_laborers`
- `bobbin_lace` (production 1953) → `lace_schools`
- `stocking_knitting_frame` (production 1990) → `frame_rent_knitters`
- `printed_grain_prices` (nutrition 2036) → `bread_scale_wage_supplements`
- `staircase_summit_canal` (logistics 2080) → `navvy_gangs`
- `fire_rebuilding_acts` (infrastructure 2134) → `rebuild_trade_opening`
- `invalid_soldiers_hospital` (health 2140) → `seamens_hospital_levy`
- `assembly_enclosure_acts` (ecology 2326) → `landless_wage_laborers`
- `multi_spindle_spinning` (production 2328) → `machine_breaking_riots`
- `roller_water_frame` (production 2338) → `factory_shift_system`

## Prerequisites from the other kicl lines

- `quarter_session_justices` (institutions 1801) → `quarter_session_wage_hearings`
- `town_printing_houses` (knowledge 1892) → `printed_wage_assessments`
- `town_printing_houses` (knowledge 1892) → `printing_house_crews`
- `printed_reform_dispute` (culture 1931) → `fewer_holy_days`
- `overseas_viceroyalties` (institutions 1946) → `rotating_mine_drafts`
- `joint_stock_company` (institutions 2000) → `company_servant_terms`
- `joint_stock_company` (institutions 2000) → `recruited_foreign_craftsmen`
- `estates_rule_without_ruler` (institutions 2098) → `freeborn_labor_debates`
- `mercantile_trade_council` (institutions 2128) → `privileged_crown_manufactories`
- `daily_printed_newspaper` (knowledge 2204) → `bound_labor_abolition_movement`
- `daily_printed_newspaper` (knowledge 2204) → `servant_register_offices`
- `free_grain_trade_doctrine` (institutions 2316) → `division_of_labor_doctrine`
- `free_grain_trade_doctrine` (institutions 2316) → `trade_freedom_edict`
- `abolition_of_estate_privileges` (institutions 2378) → `estate_bondage_abolition`

## Year adjustments

None.
