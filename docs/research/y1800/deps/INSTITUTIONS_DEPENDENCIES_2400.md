# Institutions dependencies: years 1800–2400

Machine-readable source: `partials/kicl.json` (knowledge, institutions, culture, labor). Contract: the 600–1200 and 1200–1800 mappings (`docs/research/y600/deps/partials/kicl.json`, `docs/research/y1200/deps/partials/kicl.json`, merged by `tools/research/merge_graph_1200.py` and `merge_graph_1800.py`). Ids come from `registry_2400.json`, the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), the 600–1200 graph, the 0–600 graph and the game's baked blocks. Prerequisites may be ids of any earlier block in any line, or 1800–2400 ids, and every prerequisite and precedent is dated at or before its dependent (registry target years; earlier blocks at their baked years). Brackets mark a parent from another line or an earlier block: `[production]` is a 1800–2400 id owned by Production, `[ecology, 1200-1800]` is a 1200–1800 Ecology id, `[0-600]` is a same-line 0–600 id. `contact_required` marks items that need ocean contact, directly or through a contact-gated hard parent. No year moves are proposed for this line.

**104 entries, 163 hard edges, 205 precedent edges, 0 requires_any groups.** Contact-gated: `overseas_viceroyalties`, `settler_self_government_compact`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1801 | `quarter_session_justices` | `keepers_of_the_peace` [1200-1800] |  | `royal_justice_circuits` [1200-1800], `presenting_jury_of_neighbours` [1200-1800] |  |
| 1802 | `two_chamber_estates` | `estates_assembly` [1200-1800] |  | `consented_taxation` [1200-1800], `spring_magnate_assembly` [1200-1800] |  |
| 1808 | `town_league_diet` | `chartered_town_league` [1200-1800] |  | `revised_town_statute_books` [1200-1800], `elected_town_consuls` [1200-1800] |  |
| 1813 | `commons_speaker_office` | `two_chamber_estates` |  | `consented_taxation` [1200-1800] |  |
| 1814 | `estates_impeachment` | `two_chamber_estates` |  | `impeaching_censorate` [1200-1800], `petty_trial_jury` [1200-1800], `commons_speaker_office` |  |
| 1817 | `hereditary_town_signory` | `hired_outside_magistrate` [1200-1800] |  | `elected_town_consuls` [1200-1800], `castellan_local_lordship` [1200-1800] |  |
| 1818 | `poll_tax_per_head` | `twice_yearly_coin_tax` [1200-1800], `consented_taxation` [1200-1800] |  | `decennial_household_registers` [demography] |  |
| 1821 | `regency_council` | `palace_mayor_regency` [1200-1800], `sworn_royal_council` [1200-1800] |  | `chief_justiciar_viceroy` [1200-1800] |  |
| 1833 | `pleaded_case_reports` | `writ_forms_of_action` [1200-1800] |  | `chancery_enrolment_rolls` [1200-1800], `glossator_law_schools` [1200-1800], `permanent_high_court` [1200-1800] |  |
| 1834 | `municipal_exchange_bank` | `branch_banking_houses` [1200-1800], `municipal_charters` [600-1200] |  | `bills_of_exchange` [logistics, 1200-1800], `double_entry_ledgers` [1200-1800] |  |
| 1838 | `lawyers_training_inns` | `pleaded_case_reports`, `glossator_law_schools` [1200-1800] |  | `permanent_high_court` [1200-1800], `chartered_university` [knowledge, 1200-1800] |  |
| 1839 | `creditor_debt_house` | `funded_public_debt_shares` [1200-1800] |  | `double_entry_ledgers` [1200-1800], `municipal_exchange_bank` |  |
| 1845 | `conciliar_supremacy` | `great_priestly_council_decrees` [1200-1800] |  | `sacred_law_concordance` [1200-1800], `closed_college_election` [1200-1800] |  |
| 1850 | `equity_conscience_court` | `royal_chancery_office` [1200-1800], `writ_forms_of_action` [1200-1800] |  | `petty_trial_jury` [1200-1800], `sacred_law_concordance` [1200-1800] |  |
| 1852 | `salt_and_drink_excise` | `consented_taxation` [1200-1800] |  | `salt_iron_monopoly` [600-1200], `town_hopped_brewhouses` [nutrition] |  |
| 1862 | `banker_family_signory` | `branch_banking_houses` [1200-1800], `hereditary_town_signory` |  | `scrutiny_lot_elections` [1200-1800], `municipal_exchange_bank` |  |
| 1866 | `permanent_army_tax` | `consented_taxation` [1200-1800] |  | `service_money_commutation` [security, 1200-1800], `captain_service_contracts` [security], `poll_tax_per_head` |  |
| 1875 | `resident_ambassadors` | `envoy_inviolability` [600-1200], `letter_writing_art` [knowledge, 1200-1800] |  | `paired_royal_envoys` [1200-1800], `chancery_enrolment_rolls` [1200-1800] |  |
| 1878 | `balance_of_power_league` | `resident_ambassadors` |  | `chartered_town_league` [1200-1800] |  |
| 1883 | `envoy_credentials_immunity` | `resident_ambassadors`, `envoy_inviolability` [600-1200] |  | `sealed_royal_writs` [1200-1800] |  |
| 1885 | `charitable_pawn_banks` | `branch_banking_houses` [1200-1800] |  | `wandering_preacher_orders` [culture, 1200-1800], `guild_welfare_chests` [labor, 1200-1800], `aged_almshouses` [health, 1200-1800] |  |
| 1891 | `composite_realm_union` | `coronation_oath_to_realm` [1200-1800], `estates_assembly` [1200-1800] |  | `personal_law_by_people` [1200-1800], `shared_co_rulers` [600-1200] |  |
| 1897 | `town_brotherhood_police` | `chartered_town_league` [1200-1800], `ward_night_watch` [security, 1200-1800] |  | `parish_constables` [security] |  |
| 1898 | `orthodoxy_tribunal` | `inquisitorial_written_procedure` [1200-1800] |  | `sacred_law_concordance` [1200-1800], `poor_devout_dissent` [culture, 1200-1800] |  |
| 1900 | `specialized_royal_councils` | `sworn_royal_council` [1200-1800] |  | `privy_seal_office` [1200-1800], `fixed_court_of_accounts` [1200-1800] |  |
| 1906 | `prerogative_council_court` | `sworn_royal_council` [1200-1800] |  | `equity_conscience_court`, `specialized_royal_councils` |  |
| 1911 | `poor_petition_court` | `equity_conscience_court` |  | `town_advocate_for_poor` [600-1200], `prerogative_council_court` |  |
| 1912 | `perpetual_public_peace` | `holy_truce_days` [1200-1800], `permanent_high_court` [1200-1800] |  | `town_league_diet` |  |
| 1917 | `regional_peace_circles` | `perpetual_public_peace` |  | `town_league_diet` |  |
| 1920 | `secretaries_of_state` | `privy_seal_office` [1200-1800], `royal_chancery_office` [1200-1800] |  | `specialized_royal_councils`, `sworn_royal_council` [1200-1800] |  |
| 1925 | `venal_office_sales` | `salaried_royal_bailiffs` [1200-1800] |  | `funded_public_debt_shares` [1200-1800], `permanent_high_court` [1200-1800] |  |
| 1928 | `reason_of_state_treatise` | `mirror_for_rulers` [culture, 1200-1800], `town_printing_houses` [knowledge] |  | `civic_humanism` [culture], `resident_ambassadors`, `balance_of_power_league` |  |
| 1943 | `realm_criminal_code` | `revised_realm_law_code` [1200-1800], `inquisitorial_written_procedure` [1200-1800] |  | `jurist_digest_codification` [1200-1800], `perpetual_public_peace`, `town_printing_houses` [knowledge] |  |
| 1945 | `crown_seizes_temple_lands` | `printed_reform_dispute` [culture] |  | `priestly_investiture_settlement` [1200-1800], `conciliar_supremacy` |  |
| 1946 | `overseas_viceroyalties` | `chief_justiciar_viceroy` [1200-1800], `transoceanic_contact_voyages` [logistics] |  | `fortified_trading_posts` [logistics], `ocean_house_of_trade` [logistics], `permanent_high_court` [1200-1800] | contact_required=yes |
| 1948 | `press_licensing_censors` | `town_printing_houses` [knowledge] |  | `orthodoxy_tribunal`, `printed_reform_dispute` [culture] |  |
| 1950 | `privy_council_minutes` | `sworn_royal_council` [1200-1800], `secretaries_of_state` |  | `chancery_enrolment_rolls` [1200-1800] |  |
| 1962 | `ruler_chooses_rite` | `printed_reform_dispute` [culture] |  | `perpetual_public_peace`, `regional_peace_circles`, `crown_seizes_temple_lands` |  |
| 1967 | `tax_farming_leases` | `salt_and_drink_excise` |  | `creditor_debt_house`, `frontier_customs_posts` [logistics, 600-1200] |  |
| 1980 | `sovereignty_doctrine` | `reason_of_state_treatise` |  | `ruler_chooses_rite`, `jurist_digest_codification` [1200-1800] |  |
| 1982 | `provincial_union_estates` | `estates_assembly` [1200-1800], `chartered_town_league` [1200-1800] |  | `town_league_diet`, `composite_realm_union` |  |
| 1984 | `deposition_of_tyrant` | `estates_assembly` [1200-1800] |  | `provincial_union_estates`, `sovereignty_doctrine`, `estates_impeachment` |  |
| 1998 | `rite_toleration_edict` | `ruler_chooses_rite` |  | `sovereignty_doctrine` |  |
| 2000 | `joint_stock_company` | `funded_traveling_merchant` [logistics, 1200-1800], `funded_public_debt_shares` [1200-1800] |  | `fortified_trading_posts` [logistics], `bills_of_exchange` [logistics, 1200-1800], `double_entry_ledgers` [1200-1800] |  |
| 2004 | `share_exchange_bourse` | `joint_stock_company`, `merchants_exchange_hall` [infrastructure] |  | `creditor_debt_house`, `bills_of_exchange` [logistics, 1200-1800] |  |
| 2018 | `city_exchange_bank` | `municipal_exchange_bank` |  | `share_exchange_bourse`, `endorsed_bills` [logistics] |  |
| 2018 | `free_seas_doctrine` | `written_sea_customs` [logistics, 1200-1800], `jurist_digest_codification` [1200-1800] |  | `joint_stock_company`, `company_merchant_fleets` [logistics] |  |
| 2040 | `settler_self_government_compact` | `overseas_settler_colonies` [demography] |  | `sworn_town_commune` [1200-1800], `royal_covenant_charter` [600-1200] | contact_required=yes |
| 2048 | `invention_patent_statute` | `guild_trade_monopoly` [labor, 1200-1800], `sealed_royal_writs` [1200-1800] |  | `two_chamber_estates` |  |
| 2050 | `law_of_war_and_peace` | `free_seas_doctrine` |  | `envoy_credentials_immunity`, `balance_of_power_league` |  |
| 2056 | `petition_of_right` | `great_liberties_charter` [1200-1800], `two_chamber_estates` |  | `consented_taxation` [1200-1800], `commons_speaker_office` |  |
| 2070 | `provincial_intendants` | `paired_royal_envoys` [1200-1800], `secretaries_of_state` |  | `venal_office_sales`, `specialized_royal_councils` |  |
| 2080 | `cameral_domain_chambers` | `fixed_court_of_accounts` [1200-1800] |  | `specialized_royal_councils`, `mining_ordinances` [labor] |  |
| 2096 | `sovereign_realms_congress` | `resident_ambassadors`, `law_of_war_and_peace` |  | `sovereignty_doctrine`, `balance_of_power_league`, `rite_toleration_edict` |  |
| 2098 | `estates_rule_without_ruler` | `two_chamber_estates`, `deposition_of_tyrant` |  | `petition_of_right`, `provincial_union_estates` |  |
| 2106 | `written_frame_of_government` | `estates_rule_without_ruler` |  | `settler_self_government_compact`, `great_liberties_charter` [1200-1800] |  |
| 2120 | `restoration_amnesty` | `estates_rule_without_ruler` |  | `coronation_oath_to_realm` [1200-1800] |  |
| 2122 | `personal_rule_ministers` | `secretaries_of_state`, `privy_council_minutes` |  | `provincial_intendants`, `sovereignty_doctrine` |  |
| 2128 | `mercantile_trade_council` | `specialized_royal_councils` |  | `personal_rule_ministers`, `own_hull_navigation_law` [logistics], `joint_stock_company` |  |
| 2136 | `treasury_commission_board` | `fixed_court_of_accounts` [1200-1800], `specialized_royal_councils` |  | `restoration_amnesty`, `creditor_debt_house` |  |
| 2140 | `war_ministry_bureaus` | `secretaries_of_state`, `crown_standing_army` [security] |  | `personal_rule_ministers`, `muster_commissaries` [security] |  |
| 2146 | `test_oath_for_office` | `ruler_chooses_rite` |  | `restoration_amnesty`, `orthodoxy_tribunal` |  |
| 2158 | `habeas_writ` | `writ_forms_of_action` [1200-1800], `petition_of_right` |  | `pleaded_case_reports`, `restoration_amnesty` |  |
| 2160 | `estates_parties` | `two_chamber_estates` |  | `coffeehouse_public_talk` [culture], `restoration_amnesty`, `test_oath_for_office` |  |
| 2164 | `grand_palace_court` | `fixed_capital_archives` [1200-1800], `personal_rule_ministers` |  | `axial_palace_gardens` [infrastructure], `court_ballet_spectacle` [culture] |  |
| 2178 | `conditional_crown_settlement` | `deposition_of_tyrant`, `estates_parties` |  | `restoration_amnesty`, `coronation_oath_to_realm` [1200-1800] |  |
| 2178 | `realm_bill_of_rights` | `petition_of_right`, `conditional_crown_settlement` |  | `habeas_writ`, `crown_standing_army` [security] |  |
| 2180 | `appropriated_annual_budget` | `consented_taxation` [1200-1800], `treasury_commission_board` |  | `realm_bill_of_rights`, `double_entry_ledgers` [1200-1800] |  |
| 2184 | `state_lottery_loans` | `creditor_debt_house`, `probability_theory` [knowledge] |  | `funded_public_debt_shares` [1200-1800], `treasury_commission_board` |  |
| 2188 | `chartered_central_bank` | `city_exchange_bank`, `joint_stock_company` |  | `appropriated_annual_budget`, `treasury_paper_notes` [1200-1800], `state_lottery_loans` |  |
| 2188 | `fixed_term_estates` | `two_chamber_estates`, `realm_bill_of_rights` |  | `estates_parties` |  |
| 2190 | `press_licence_lapse` | `press_licensing_censors` |  | `estates_parties`, `realm_bill_of_rights` |  |
| 2192 | `trade_and_colonies_board` | `mercantile_trade_council` |  | `own_hull_navigation_law` [logistics], `treasury_commission_board` |  |
| 2200 | `foreign_affairs_office` | `secretaries_of_state`, `resident_ambassadors` |  | `sovereign_realms_congress`, `fireproof_record_vaults` [infrastructure] |  |
| 2214 | `realm_union_treaty` | `composite_realm_union`, `two_chamber_estates` |  | `conditional_crown_settlement` |  |
| 2222 | `governing_senate_colleges` | `specialized_royal_councils`, `personal_rule_ministers` |  | `cameral_domain_chambers` |  |
| 2226 | `justice_ombudsman` | `personal_rule_ministers`, `permanent_high_court` [1200-1800] |  | `impeaching_censorate` [1200-1800], `governing_senate_colleges` |  |
| 2226 | `succession_sanction` | `sovereignty_doctrine` |  | `coronation_oath_to_realm` [1200-1800], `composite_realm_union`, `regency_council` |  |
| 2234 | `debt_sinking_fund` | `funded_public_debt_shares` [1200-1800], `appropriated_annual_budget` |  | `chartered_central_bank`, `probability_theory` [knowledge] |  |
| 2236 | `cadastral_tax_survey` | `triangulation_survey` [knowledge], `graded_land_tax` [600-1200] |  | `realm_holding_survey` [demography, 1200-1800], `cameral_domain_chambers`, `printed_engraved_maps` [knowledge] |  |
| 2240 | `bubble_company_law` | `share_exchange_bourse`, `joint_stock_company` |  | `chartered_central_bank`, `state_lottery_loans` |  |
| 2242 | `cabinet_first_minister` | `secretaries_of_state`, `privy_council_minutes`, `estates_parties` |  | `appropriated_annual_budget`, `treasury_commission_board`, `fixed_term_estates` |  |
| 2244 | `table_of_service_ranks` | `governing_senate_colleges` |  | `crown_standing_army` [security], `regular_merit_examinations` [1200-1800] |  |
| 2254 | `cameral_science_chairs` | `cameral_domain_chambers`, `ruler_founded_universities` [knowledge] |  | `governing_senate_colleges`, `mercantile_trade_council` |  |
| 2260 | `police_ordinance_science` | `cameral_science_chairs` |  | `capital_police_lieutenant` [security] |  |
| 2280 | `servant_ruler_doctrine` | `sovereignty_doctrine` |  | `cameral_science_chairs`, `personal_rule_ministers` |  |
| 2296 | `separation_of_powers` | `realm_bill_of_rights`, `sovereignty_doctrine` |  | `cabinet_first_minister`, `fixed_term_estates` |  |
| 2312 | `compiled_civil_code` | `revised_realm_law_code` [1200-1800], `cameral_science_chairs` |  | `realm_criminal_code`, `jurist_digest_codification` [1200-1800] |  |
| 2316 | `free_grain_trade_doctrine` | `cameral_science_chairs`, `printed_grain_prices` [nutrition] |  | `grain_export_bounties` [nutrition], `agricultural_improvement_societies` [nutrition] |  |
| 2324 | `social_contract_doctrine` | `sovereignty_doctrine` |  | `written_frame_of_government`, `servant_ruler_doctrine`, `separation_of_powers` |  |
| 2328 | `penal_reform_no_torture` | `realm_criminal_code` |  | `separation_of_powers`, `police_ordinance_science` |  |
| 2332 | `press_freedom_statute` | `press_licence_lapse` |  | `separation_of_powers`, `daily_printed_newspaper` [knowledge] |  |
| 2340 | `cameral_service_examinations` | `cameral_science_chairs`, `regular_merit_examinations` [1200-1800] |  | `table_of_service_ranks` |  |
| 2352 | `declaration_of_rights` | `realm_bill_of_rights`, `social_contract_doctrine` |  | `separation_of_powers`, `written_frame_of_government`, `press_freedom_statute` |  |
| 2360 | `constituent_convention` | `written_frame_of_government`, `declaration_of_rights` |  | `social_contract_doctrine`, `settler_self_government_compact` |  |
| 2374 | `federal_written_constitution` | `constituent_convention`, `separation_of_powers`, `provincial_union_estates` |  | `declaration_of_rights`, `two_chamber_estates` |  |
| 2378 | `abolition_of_estate_privileges` | `single_national_assembly` |  | `declaration_of_rights` |  |
| 2378 | `single_national_assembly` | `two_chamber_estates`, `declaration_of_rights` |  | `social_contract_doctrine` |  |
| 2380 | `elected_municipal_councils` | `municipal_charters` [600-1200], `single_national_assembly` |  | `declaration_of_rights` |  |
| 2380 | `uniform_departments` | `single_national_assembly`, `cadastral_tax_survey` |  | `provincial_intendants` |  |
| 2384 | `realm_republic` | `single_national_assembly`, `deposition_of_tyrant` |  | `constituent_convention`, `social_contract_doctrine` |  |
| 2386 | `emergency_safety_committee` | `realm_republic` |  | `sovereignty_doctrine` |  |
| 2388 | `general_land_code` | `compiled_civil_code` |  | `cadastral_tax_survey`, `servant_ruler_doctrine` |  |
| 2398 | `graduated_income_tax` | `appropriated_annual_budget`, `cadastral_tax_survey` |  | `nominal_realm_census` [demography], `poll_tax_per_head` |  |

## Cross-line prerequisites assumed from other 1800–2400 lines

These ids are mapped by other partials in parallel; each edge assumes the parent keeps its registry year. Hard edges only; precedents are listed in the table.

- `transoceanic_contact_voyages` (logistics 1912) → `overseas_viceroyalties`
- `overseas_settler_colonies` (demography 1926) → `settler_self_government_compact`
- `merchants_exchange_hall` (infrastructure 1968) → `share_exchange_bourse`
- `printed_grain_prices` (nutrition 2036) → `free_grain_trade_doctrine`
- `crown_standing_army` (security 2100) → `war_ministry_bureaus`

## Prerequisites from the other kicl lines

- `ruler_founded_universities` (knowledge 1821) → `cameral_science_chairs`
- `town_printing_houses` (knowledge 1892) → `press_licensing_censors`
- `town_printing_houses` (knowledge 1892) → `reason_of_state_treatise`
- `printed_reform_dispute` (culture 1931) → `crown_seizes_temple_lands`
- `printed_reform_dispute` (culture 1931) → `ruler_chooses_rite`
- `triangulation_survey` (knowledge 1944) → `cadastral_tax_survey`
- `probability_theory` (knowledge 2108) → `state_lottery_loans`

## Year adjustments

None.
