# Demography dependencies: years 1800–2400

Generated from `docs/research/y1800/deps/partials/nhde.json`. It uses ids from `registry_2400.json`, the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), the 600–1200 graph (`docs/research/y600/deps/graph_1200.json`), the 0–600 graph and the game's baked blocks only. Brackets mark a parent from another line or an earlier block: `[logistics]` is a 1800–2400 id owned by Logistics, `[ecology, 1200-1800]` is a 1200–1800 Ecology id, `[0-600]` is a same-line 0–600 id. An `environment` list means any one of the listed environments satisfies the gate. `requires_all` are hard prerequisites dated at or before the dependent (no edge links two 1800–2400 items of the same year); `requires_any` groups need one member; precedents are soft influences, also dated at or before it. `contact_required` is reserved in this block for items that need ocean contact through Logistics `transoceanic_contact_voyages` (1912), directly or through a contact-gated parent. (regional) items are gated by `environment` or inherit a regional parent from 1200–1800, which already carries `contact_required`. No year moves are proposed for this line (`partials/nhde_year_adjustments.json` is empty).

**83 entries, 114 hard edges, 134 precedent edges, 0 requires_any groups.**

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1804 | post_mortality_remarriage | consent_marriage [1200-1800] |  | widow_third_dower [1200-1800], deserted_village_pasture [1200-1800] |  |
| 1812 | vacant_holding_migration | deserted_village_pasture [1200-1800] |  | town_migration_dependence [1200-1800], holding_fragmentation [1200-1800] |  |
| 1818 | decennial_household_registers | mutual_surety_tithings [institutions, 1200-1800] |  | hearth_tax_counts [1200-1800], decimal_unit_census [1200-1800] |  |
| 1824 | free_citizenship_grants | burgess_rolls [1200-1800] |  | vacant_holding_migration, invited_craft_colonies [1200-1800] |  |
| 1832 | wage_seeking_migration | town_migration_dependence [1200-1800] |  | vacant_holding_migration, quarter_session_wage_hearings [labor], board_and_dry_wage_rates [labor] |  |
| 1846 | town_quarter_house_lists | burgess_rolls [1200-1800] |  | hearth_tax_counts [1200-1800], adult_poll_rolls [1200-1800] |  |
| 1852 | public_dowry_fund | poor_bride_dowries [1200-1800], municipal_exchange_bank [institutions] |  | age_priced_life_annuities [1200-1800] |  |
| 1856 | household_wealth_census | realm_holding_survey [1200-1800], town_quarter_house_lists |  | poll_tax_per_head [institutions], adult_poll_rolls [1200-1800], hearth_tax_counts [1200-1800] |  |
| 1860 | dowry_caps | public_dowry_fund |  | bride_dower_gift [1200-1800] |  |
| 1864 | census_age_recording | household_wealth_census |  | fixed_majority_ages [1200-1800] |  |
| 1872 | registered_foundling_hospital | foundling_wheel [1200-1800], foundling_house [1200-1800] |  | ward_hospitals [health, 1200-1800] |  |
| 1877 | health_office_death_registers | town_quarter_house_lists, pestilence_health_boards [health, 1200-1800] |  | commemorative_death_books [1200-1800] |  |
| 1880 | foundling_wet_nurses | registered_foundling_hospital, wet_nurse_licensing [600-1200] |  |  |  |
| 1886 | town_orphanage | orphan_chambers [1200-1800] |  | apprentice_indentures [labor, 1200-1800], registered_foundling_hospital |  |
| 1890 | women_refuge_houses | single_women_houses [1200-1800] |  | inward_devotion_movement [culture] |  |
| 1894 | pestilence_orphan_lists | town_orphanage |  | health_office_death_registers, congregation_widow_rolls [600-1200] |  |
| 1902 | lineage_genealogy_books | ranked_clan_genealogies [1200-1800] |  | block_printed_books [knowledge, 1200-1800] |  |
| 1912 | expelled_community_refuge | invited_craft_colonies [1200-1800] |  | foreign_merchant_quarters [1200-1800], orthodoxy_tribunal [institutions] |  |
| 1920 | emigrant_port_licences | transoceanic_contact_voyages [logistics] |  | ocean_house_of_trade [logistics], town_quarter_house_lists | contact_required: True |
| 1926 | overseas_settler_colonies | overseas_colony_founding [600-1200], transoceanic_contact_voyages [logistics] |  | emigrant_port_licences, fortified_trading_posts [logistics] | contact_required: True |
| 1930 | printed_midwife_manual | womens_medicine_treatise [1200-1800], town_printing_houses [knowledge] |  | midwifery_manuals [600-1200], sworn_town_midwives [1200-1800] |  |
| 1936 | contact_epidemic_records | overseas_settler_colonies |  | epidemic_chronicles [health, 600-1200], pox_measles_distinction [health, 1200-1800] | contact_required: True |
| 1948 | shrine_vital_registers | commemorative_death_books [1200-1800], dynastic_vital_register [1200-1800] |  | public_marriage_banns [1200-1800], godparent_kinship [1200-1800] |  |
| 1952 | devotee_house_closure | celibate_communities [600-1200] |  | crown_seizes_temple_lands [institutions], printed_reform_dispute [culture] |  |
| 1956 | marriage_dissolution_courts | divorce_settlements [0-600] |  | printed_reform_dispute [culture], equity_conscience_court [institutions] |  |
| 1968 | witnessed_marriage_rule | public_marriage_banns [1200-1800], shrine_vital_registers |  | consent_marriage [1200-1800] |  |
| 1986 | mixed_descent_status | intermarriage_permission [1200-1800], overseas_settler_colonies |  |  | contact_required: True |
| 1994 | postmortem_caesarean_rule | sworn_town_midwives [1200-1800] |  | printed_midwife_manual, surgical_anatomy [health, 600-1200] |  |
| 2008 | weekly_mortality_bills | shrine_vital_registers, corpse_searchers [health] |  | printed_broadsides [knowledge], health_office_death_registers |  |
| 2018 | living_mother_caesarean | postmortem_caesarean_rule |  | dissection_anatomy_atlas [health], amputation_ligature [health] |  |
| 2028 | annual_soul_lists | shrine_vital_registers |  | town_quarter_house_lists |  |
| 2036 | headright_land_grants | frontier_settler_grants [0-600], overseas_settler_colonies |  | settler_estate_shares [1200-1800] | contact_required: True |
| 2052 | secret_obstetric_forceps | sworn_town_midwives [1200-1800], printed_midwife_manual |  | screw_tap_and_die [production], dissection_anatomy_atlas [health] |  |
| 2064 | soldier_marriage_limits | pike_and_shot_regiment [security] |  | witnessed_marriage_rule, articles_of_war [security] |  |
| 2078 | man_midwives | sworn_town_midwives [1200-1800], secret_obstetric_forceps |  | living_mother_caesarean |  |
| 2088 | ship_passenger_lists | emigrant_port_licences |  | ship_logbooks [logistics], overseas_settler_colonies | contact_required: True |
| 2096 | childbed_death_counts | weekly_mortality_bills |  | man_midwives |  |
| 2108 | strict_family_settlement | entailed_family_land [1200-1800] |  | equity_conscience_court [institutions], heir_wardship [1200-1800] |  |
| 2112 | burial_age_entries | shrine_vital_registers |  | census_age_recording, weekly_mortality_bills |  |
| 2124 | mortality_bill_arithmetic | weekly_mortality_bills |  | printed_arithmetic_summa [knowledge], inductive_method_program [knowledge], probability_theory [knowledge] |  |
| 2130 | colonist_bride_passages | overseas_settler_colonies |  | ship_passenger_lists, public_dowry_fund | contact_required: True |
| 2134 | large_family_tax_relief | marriage_incentive_laws [600-1200] |  | household_wealth_census |  |
| 2140 | country_wet_nursing | wet_nurse_licensing [600-1200] |  | foundling_wet_nurses |  |
| 2148 | colonial_household_registers | annual_soul_lists, overseas_settler_colonies |  | overseas_viceroyalties [institutions] | contact_required: True |
| 2156 | separate_wife_property | sealed_family_contracts [institutions, 0-600] |  | equity_conscience_court [institutions], strict_family_settlement |  |
| 2162 | populationist_policy | mortality_bill_arithmetic |  | reason_of_state_treatise [institutions], cameral_domain_chambers [institutions], personal_rule_ministers [institutions] |  |
| 2170 | faith_refugee_edict | expelled_community_refuge, rite_toleration_edict [institutions] |  | populationist_policy |  |
| 2178 | tontine_annuities | age_priced_life_annuities [1200-1800] |  | mortality_bill_arithmetic, probability_theory [knowledge] |  |
| 2186 | register_life_table | mortality_bill_arithmetic, burial_age_entries |  | probability_theory [knowledge], decimal_log_tables [knowledge] |  |
| 2192 | vital_events_tax | shrine_vital_registers |  | appropriated_annual_budget [institutions] |  |
| 2196 | birth_multiplier_estimates | mortality_bill_arithmetic |  | annual_soul_lists |  |
| 2208 | nominal_realm_census | household_wealth_census, register_life_table |  | birth_multiplier_estimates, annual_soul_lists |  |
| 2216 | birth_sex_ratio | register_life_table |  | probability_theory [knowledge] |  |
| 2224 | post_plague_colonization | vacant_holding_migration, populationist_policy |  | colonist_recruiting_agents [1200-1800] |  |
| 2226 | marriage_register_details | shrine_vital_registers, witnessed_marriage_rule |  | census_age_recording |  |
| 2232 | convict_transportation | overseas_settler_colonies |  | convict_galley_oarsmen [labor], realm_criminal_code [institutions] | contact_required: True |
| 2240 | midwife_birth_returns | sworn_town_midwives [1200-1800] |  | weekly_mortality_bills, man_midwives |  |
| 2248 | military_orphanage | town_orphanage, crown_standing_army [security] |  | invalid_soldiers_hospital [health] |  |
| 2256 | lodging_guest_registers | town_quarter_house_lists |  | capital_police_lieutenant [security], travel_passports [security] |  |
| 2266 | published_obstetric_forceps | secret_obstetric_forceps, man_midwives |  | medical_case_journals [health] |  |
| 2282 | national_foundling_hospital | registered_foundling_hospital |  | subscription_hospitals [health], foundling_wet_nurses |  |
| 2286 | divine_order_population_treatise | register_life_table |  | birth_sex_ratio |  |
| 2290 | actuarial_widows_fund | register_life_table |  | tontine_annuities, friendly_society_boxes [labor] |  |
| 2294 | lying_in_hospital | man_midwives, subscription_hospitals [health] |  | published_obstetric_forceps |  |
| 2298 | population_tables_office | nominal_realm_census, register_life_table |  | cameral_science_chairs [institutions], midwife_birth_returns |  |
| 2302 | life_expectancy_tables | register_life_table |  | integral_calculus [knowledge], actuarial_widows_fund |  |
| 2302 | settler_doubling_observation | colonial_household_registers |  | birth_multiplier_estimates | contact_required: True |
| 2308 | clandestine_marriage_ban | witnessed_marriage_rule, marriage_register_details |  |  |  |
| 2318 | maternal_nursing_campaign | country_wet_nursing |  | foundling_wet_nurses, epistolary_novel [culture] |  |
| 2320 | inoculation_mortality_reckoning | population_tables_office, preventive_inoculation [health] |  | register_life_table |  |
| 2326 | frontier_colonist_recruitment | colonist_recruiting_agents [1200-1800], populationist_policy |  | post_plague_colonization, faith_refugee_edict |  |
| 2332 | manikin_midwife_schools | sworn_town_midwives [1200-1800], published_obstetric_forceps |  | anatomical_wax_models [health] |  |
| 2338 | wet_nurse_bureau | wet_nurse_licensing [600-1200], country_wet_nursing |  | servant_register_offices [labor] |  |
| 2346 | pauper_marriage_bar | settlement_removal_laws [labor] |  | workhouse_test [labor] |  |
| 2352 | emigrant_recruiting_agents | indentured_passage [labor] |  | frontier_colonist_recruitment, ship_passenger_lists | contact_required: True |
| 2356 | infant_death_causes | population_tables_office |  | childbed_death_counts, foundling_wet_nurses |  |
| 2364 | marital_birth_limitation | family_size_counsel [600-1200] |  | life_expectancy_tables, maternal_nursing_campaign |  |
| 2368 | secret_birth_house | lying_in_hospital |  | national_foundling_hospital |  |
| 2372 | foundling_nurse_inspection | wet_nurse_bureau |  | national_foundling_hospital, infant_death_causes |  |
| 2380 | decennial_apportionment_census | nominal_realm_census, population_tables_office |  | fixed_term_estates [institutions], federal_written_constitution [institutions] |  |
| 2385 | civil_vital_registration | shrine_vital_registers, population_tables_office |  | abolition_of_estate_privileges [institutions], uniform_departments [institutions] |  |
| 2390 | civil_divorce | marriage_dissolution_courts |  | civil_vital_registration, declaration_of_rights [institutions] |  |
| 2396 | population_pressure_treatise | divine_order_population_treatise |  | settler_doubling_observation, four_course_rotation [nutrition], division_of_labor_doctrine [labor] |  |

## Notes

- **Counting people.** `realm_holding_survey` + `town_quarter_house_lists` → `household_wealth_census` → `census_age_recording`. `commemorative_death_books` + `dynastic_vital_register` → `shrine_vital_registers` → `weekly_mortality_bills` (with Health `corpse_searchers`) → `mortality_bill_arithmetic` → `register_life_table` (with `burial_age_entries`) → `nominal_realm_census`. The realm census requires both `household_wealth_census` and `register_life_table`, giving the chain mortality bills → life table → census. The life table also leads to `birth_sex_ratio`, `actuarial_widows_fund`, `life_expectancy_tables` and `divine_order_population_treatise` → `population_pressure_treatise`. `population_tables_office` needs the census and the life table, and leads to `infant_death_causes`, `inoculation_mortality_reckoning` (with Health `preventive_inoculation`), `decennial_apportionment_census` and `civil_vital_registration`.
- **Ocean migration.** Contact-gated: `emigrant_port_licences` and `overseas_settler_colonies` (600–1200 `overseas_colony_founding` + Logistics `transoceanic_contact_voyages`), then `contact_epidemic_records`, `mixed_descent_status`, `headright_land_grants`, `ship_passenger_lists`, `colonist_bride_passages`, `colonial_household_registers` → `settler_doubling_observation`, `convict_transportation`, and `emigrant_recruiting_agents` (Labor `indentured_passage`).
- **Migration within the realm.** `deserted_village_pasture` → `vacant_holding_migration` → `post_plague_colonization` (with `populationist_policy`). `invited_craft_colonies` → `expelled_community_refuge` → `faith_refugee_edict` (Institutions `rite_toleration_edict`). `frontier_colonist_recruitment` needs `colonist_recruiting_agents` and `populationist_policy`.
- **Birth and infancy.** `sworn_town_midwives` → `postmortem_caesarean_rule` → `living_mother_caesarean`; `secret_obstetric_forceps` → `man_midwives` → `published_obstetric_forceps` → `manikin_midwife_schools`. `lying_in_hospital` needs `man_midwives` and Health `subscription_hospitals` → `secret_birth_house`. Foundlings: `foundling_wheel` + `foundling_house` → `registered_foundling_hospital` → `foundling_wet_nurses` and `national_foundling_hospital`. `wet_nurse_licensing` → `country_wet_nursing` → `wet_nurse_bureau` → `foundling_nurse_inspection`.
- **Marriage and household.** `public_marriage_banns` + `shrine_vital_registers` → `witnessed_marriage_rule` → `clandestine_marriage_ban`. `divorce_settlements` → `marriage_dissolution_courts` → `civil_divorce`. `pauper_marriage_bar` needs Labor `settlement_removal_laws`. `soldier_marriage_limits` needs Security `pike_and_shot_regiment`; `military_orphanage` needs Security `crown_standing_army`.

## Cross-line parents in 1800–2400 (mapped by other agents)

- **Culture:** `epistolary_novel` (2280), `inward_devotion_movement` (1848), `printed_reform_dispute` (1931)
- **Health:** `amputation_ligature` (1970), `anatomical_wax_models` (2268), `corpse_searchers` (1990), `dissection_anatomy_atlas` (1952), `invalid_soldiers_hospital` (2140), `medical_case_journals` (2176), `preventive_inoculation` (2302), `subscription_hospitals` (2250)
- **Institutions:** `abolition_of_estate_privileges` (2378), `appropriated_annual_budget` (2180), `cameral_domain_chambers` (2080), `cameral_science_chairs` (2254), `crown_seizes_temple_lands` (1945), `declaration_of_rights` (2352), `equity_conscience_court` (1850), `federal_written_constitution` (2374), `fixed_term_estates` (2188), `municipal_exchange_bank` (1834), `orthodoxy_tribunal` (1898), `overseas_viceroyalties` (1946), `personal_rule_ministers` (2122), `poll_tax_per_head` (1818), `realm_criminal_code` (1943), `reason_of_state_treatise` (1928), `rite_toleration_edict` (1998), `uniform_departments` (2380)
- **Knowledge:** `decimal_log_tables` (2034), `inductive_method_program` (2040), `integral_calculus` (2150), `printed_arithmetic_summa` (1912), `printed_broadsides` (1890), `probability_theory` (2108), `town_printing_houses` (1892)
- **Labor:** `board_and_dry_wage_rates` (1822), `convict_galley_oarsmen` (1864), `division_of_labor_doctrine` (2356), `friendly_society_boxes` (2190), `indentured_passage` (2036), `quarter_session_wage_hearings` (1804), `servant_register_offices` (2262), `settlement_removal_laws` (2126), `workhouse_test` (2246)
- **Logistics:** `fortified_trading_posts` (1872), `ocean_house_of_trade` (1918), `ship_logbooks` (2022), `transoceanic_contact_voyages` (1912)
- **Nutrition:** `four_course_rotation` (2324)
- **Production:** `screw_tap_and_die` (1890)
- **Security:** `articles_of_war` (2040), `capital_police_lieutenant` (2134), `crown_standing_army` (2100), `pike_and_shot_regiment` (1946), `travel_passports` (1950)
