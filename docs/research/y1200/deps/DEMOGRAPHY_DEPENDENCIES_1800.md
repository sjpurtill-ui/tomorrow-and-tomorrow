# Demography dependencies: years 1200–1800

Generated with `docs/research/y1200/deps/partials/nhde.json`. It uses ids from `registry_1800.json`, the 600–1200 graph (`docs/research/y600/deps/graph_1200.json`) and the 0–600 graph only. Brackets mark a parent from another line or an earlier block: `[logistics]` is a 1200–1800 id owned by Logistics, `[ecology, 600-1200]` is a 600–1200 Ecology id, `[0-600]` is a same-line 0–600 id. An `environment` list means any one of the listed environments satisfies the gate. `requires_all` are hard prerequisites dated at or before the dependent (no edge links two items of the same year); `requires_any` groups need one member; precedents are soft influences, also dated at or before it. No year moves are proposed for this line (`partials/nhde_year_adjustments.json` is empty).

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1206 | infanticide_ban | intent_graded_homicide_law [institutions, 600-1200], foundling_rescue [600-1200] |  | compiled_rescript_code [institutions, 600-1200] |  |
| 1212 | fifteen_year_assessment | head_land_tax_units [600-1200] |  | periodic_citizen_census [600-1200], graded_land_tax [institutions, 600-1200] |  |
| 1225 | town_to_estate_drift | land_bound_tenancy [labor, 600-1200] |  | city_grain_migration [600-1200], famine_refugee_hosting [0-600] |  |
| 1232 | settler_estate_shares | federate_settlement [600-1200] |  | service_land_grants [institutions, 0-600] |  |
| 1245 | foundling_free_status | foundling_rescue [600-1200], freed_person_status [600-1200] |  | infanticide_ban |  |
| 1250 | refuge_site_towns | refugee_land_settlement [600-1200], town_enclosure_walls [infrastructure, 0-600] |  | hilltop_citadel_towns [security] |  |
| 1270 | conqueror_landed_settlement | military_settler_colonies [600-1200], settler_estate_shares |  | forced_resettlement [600-1200] |  |
| 1280 | bride_dower_gift | recorded_dowry [0-600], widow_portion_law [0-600] |  | written_customary_codes [institutions] |  |
| 1286 | child_oblation | celibate_communities [600-1200], devotee_communities_under_rule [culture] |  | kin_fostering_networks [0-600] |  |
| 1296 | presumed_death_term | widow_remarriage_custom [600-1200], written_customary_codes [institutions] |  | registered_marriage [600-1200] |  |
| 1300 | captive_artisan_resettlement | forced_resettlement [600-1200], craftsman_naturalization [600-1200] |  | registered_state_artisans [labor] |  |
| 1310 | intermarriage_permission | personal_law_by_people [institutions], settler_estate_shares |  | intertown_marriage_rights [600-1200] |  |
| 1320 | ranked_clan_genealogies | nine_rank_official_grading [institutions, 600-1200] |  | merit_recommendation [institutions, 600-1200], peoples_origin_histories [culture] |  |
| 1330 | blood_heir_rule | dynastic_succession [institutions, 0-600], written_customary_codes [institutions] |  | heir_adoption [600-1200] |  |
| 1340 | soldier_farmer_holdings | military_district_settlement [security], garrison_farm_colonies [600-1200] |  | veteran_land_allotments [600-1200] |  |
| 1345 | godparent_kinship | kin_birth_registration [600-1200], ranked_priestly_hierarchy [institutions] |  | kin_fostering_networks [0-600] |  |
| 1350 | herder_tribute_registers | household_tax_registers [600-1200], people_herd_counts [0-600] |  | codified_tribute_schedules [institutions, 0-600] | contact_required: True |
| 1360 | wide_kin_marriage_ban | single_wife_households [600-1200], ranked_priestly_hierarchy [institutions] |  | heiress_marriage_rule [600-1200], ranked_clan_genealogies |  |
| 1375 | child_fosterage | kin_fostering_networks [0-600] |  | child_oblation, patron_protection [0-600] |  |
| 1385 | frontier_repopulation | forced_resettlement [600-1200], deserted_land_grants [600-1200] |  | conqueror_landed_settlement |  |
| 1405 | foundling_house | foundling_free_status, charity_hospitals [health, 600-1200] |  | wet_nurse_licensing [600-1200], alimentary_child_funds [600-1200] |  |
| 1422 | commemorative_death_books | devotee_communities_under_rule [culture], household_vital_lists [0-600] |  | retreat_copying_rooms [knowledge] |  |
| 1430 | hearth_tax_counts | hearth_counts [0-600], household_tax_registers [600-1200] |  | twice_yearly_coin_tax [institutions] |  |
| 1440 | hereditary_unfree_status | unfree_headcount [600-1200], land_bound_tenancy [labor, 600-1200] |  | bound_estate_tenants [institutions] |  |
| 1450 | invited_craft_colonies | craftsman_naturalization [600-1200] |  | charter_colonies [institutions, 600-1200], witnessed_land_charters [institutions] |  |
| 1455 | childhood_disease_book | childhood_illness_recognition [0-600], authored_prose_treatises [knowledge, 600-1200] |  | practitioner_compendium [health], midwifery_manuals [600-1200] |  |
| 1465 | fortified_frontier_villages | deserted_land_grants [600-1200], frontier_settler_grants [0-600] |  | burgh_defense_network [security], witnessed_land_charters [institutions] |  |
| 1472 | marriage_out_fee | hereditary_unfree_status, manor_court_customals [institutions] |  | bound_estate_tenants [institutions] |  |
| 1480 | herder_sedentarization | herder_tribute_registers |  | deserted_land_grants [600-1200] | contact_required: True |
| 1490 | village_nucleation | three_field_rotation [nutrition], manor_court_customals [institutions] |  | town_consolidation [600-1200], shared_plough_teams [labor] |  |
| 1500 | foreign_merchant_quarters | merchant_quarters_abroad [logistics, 0-600], resident_alien_status [600-1200] |  | foreigners_court [institutions, 600-1200] | contact_required: True |
| 1510 | single_heir_holdings | partible_inheritance [0-600], written_wills [600-1200] |  | carrying_capacity_awareness [0-600], hereditary_fief_succession [institutions] |  |
| 1540 | eldest_son_succession | hereditary_fief_succession [institutions], eldest_double_share [600-1200] |  | single_heir_holdings |  |
| 1564 | younger_son_careers | eldest_son_succession |  | celibate_communities [600-1200], fief_tenure_for_service [institutions] |  |
| 1572 | realm_holding_survey | estate_survey_books [labor], hearth_tax_counts |  | graded_land_tax [institutions, 600-1200], raider_tribute_land_tax [institutions] |  |
| 1580 | minimum_marriage_ages | marriage_age_norms [0-600], registered_marriage [600-1200] |  | written_customary_codes [institutions] |  |
| 1585 | consent_marriage | registered_marriage [600-1200], wide_kin_marriage_ban |  | minimum_marriage_ages |  |
| 1590 | womens_medicine_treatise | midwifery_manuals [600-1200], womens_ailment_texts [health, 0-600] |  | practitioner_compendium [health], canon_textbook [health] |  |
| 1596 | widow_third_dower | bride_dower_gift, widow_portion_law [0-600] |  | hereditary_fief_succession [institutions] |  |
| 1602 | legitimation_by_marriage | consent_marriage, blood_heir_rule |  | compiled_rescript_code [institutions, 600-1200] |  |
| 1615 | burgess_rolls | ward_residence_lists [0-600], sworn_town_commune [institutions] |  | belonging_oaths [0-600] |  |
| 1622 | colonist_recruiting_agents | clearance_dues_holiday [labor], fortified_frontier_villages |  | invited_craft_colonies |  |
| 1626 | heiress_fief_inheritance | hereditary_fief_succession [institutions], eldest_son_succession |  | heiress_marriage_rule [600-1200] |  |
| 1632 | heir_wardship | orphan_guardianship [600-1200], fief_tenure_for_service [institutions] |  | heiress_fief_inheritance |  |
| 1640 | burgage_plot_towns | planned_colony_lots [600-1200], chartered_town_liberties [institutions] |  | standard_lot_grid_towns [infrastructure, 600-1200] |  |
| 1645 | settler_home_law | colonist_recruiting_agents, personal_law_by_people [institutions] |  |  |  |
| 1646 | fixed_majority_ages | majority_enrollment [600-1200], heir_wardship |  | knightly_conduct_code [culture] |  |
| 1652 | noble_lineage_rolls | ranked_clan_genealogies, heraldic_arms [culture] |  | eldest_son_succession |  |
| 1660 | dynastic_vital_register | household_vital_lists [0-600], dynastic_succession [institutions, 0-600] |  | royal_chancery_office [institutions], commemorative_death_books |  |
| 1665 | captive_ransom_brotherhoods | devotee_communities_under_rule [culture] |  | treaty_hostage_exchange [institutions, 600-1200], nursing_brotherhoods [health] |  |
| 1670 | foundling_wheel | foundling_house |  | wet_nurse_licensing [600-1200] |  |
| 1680 | public_marriage_banns | registered_marriage [600-1200], wide_kin_marriage_ban |  | public_heralds [institutions, 0-600] |  |
| 1690 | retirement_maintenance_contracts | single_heir_holdings, manor_court_customals [institutions] |  | public_notaries [institutions], multigenerational_household_norms [0-600] |  |
| 1700 | hereditary_surnames | hearth_tax_counts |  | noble_lineage_rolls, burgess_rolls, chancery_enrolment_rolls [institutions] |  |
| 1705 | single_women_houses | devotee_communities_under_rule [culture] |  | poor_devout_dissent [culture], estate_weaving_houses [labor] |  |
| 1710 | decimal_unit_census | decimal_army_organization [security], household_tax_registers [600-1200] |  | realm_holding_survey |  |
| 1712 | holding_fragmentation | partible_inheritance [0-600], carrying_capacity_awareness [0-600] |  | single_heir_holdings, cottager_day_laborers [labor] |  |
| 1716 | town_migration_dependence | rural_urban_migration [0-600], burgess_rolls |  | tenement_crowding [600-1200], town_residence_freedom [labor] |  |
| 1720 | purchased_corrodies | devotee_communities_under_rule [culture], aged_almshouses [health] |  | retirement_maintenance_contracts |  |
| 1722 | orphan_chambers | orphan_guardianship [600-1200], sworn_town_commune [institutions] |  | public_notaries [institutions] |  |
| 1730 | age_priced_life_annuities | annuity_life_tables [600-1200], funded_public_debt_shares [institutions] |  | purchased_corrodies |  |
| 1737 | entailed_family_land | eldest_son_succession, written_wills [600-1200] |  | noble_lineage_rolls |  |
| 1750 | service_before_marriage | yearly_farm_servants [labor], minimum_marriage_ages |  | consent_marriage |  |
| 1756 | widow_trade_continuation | guild_trade_monopoly [labor], widow_portion_law [0-600] |  | guild_welfare_chests [labor] |  |
| 1762 | poor_bride_dowries | recorded_dowry [0-600], guild_welfare_chests [labor] |  | alimentary_child_funds [600-1200] |  |
| 1765 | vagrant_expulsion | burgess_rolls, internal_passes [600-1200] |  | fugitive_worker_returns [labor] |  |
| 1775 | bread_mouth_census | ward_residence_lists [0-600], graded_rations [nutrition, 0-600] |  | dearth_price_ceilings [nutrition], keep_cistern_stores [security] |  |
| 1785 | sworn_town_midwives | midwifery_manuals [600-1200], trained_midwives [600-1200] |  | womens_medicine_treatise, craft_guilds [institutions] |  |
| 1792 | deserted_village_pasture | post_plague_resettlement [600-1200], bubo_plague_recognition [health] |  | wool_flock_overgrazing [ecology], marginal_land_retreat [ecology] |  |
| 1798 | adult_poll_rolls | hearth_tax_counts, levy_age_rolls [600-1200] |  | realm_holding_survey |  |

## Notes

- **Counting people.** `hearth_counts` (0–600) + `household_tax_registers` → `hearth_tax_counts` (1430). It leads to `realm_holding_survey` (1572, which also requires labor `estate_survey_books`), `hereditary_surnames` and `adult_poll_rolls` (with `levy_age_rolls`). `decimal_unit_census` requires security `decimal_army_organization`.
- **Inheritance.** Institutions `hereditary_fief_succession` (1440) + `eldest_double_share` → `eldest_son_succession` (1540). It leads to `younger_son_careers`, `heiress_fief_inheritance`, `entailed_family_land` and `heir_wardship`. `heir_wardship` also requires institutions `fief_tenure_for_service` and leads to `fixed_majority_ages`. The peasant line runs `partible_inheritance` + `written_wills` → `single_heir_holdings` → `retirement_maintenance_contracts`. `holding_fragmentation` stays on the partible branch.
- **Marriage.** `registered_marriage` + institutions `ranked_priestly_hierarchy` feed `wide_kin_marriage_ban` → `consent_marriage` → `legitimation_by_marriage`. They also feed `public_marriage_banns`. `minimum_marriage_ages` + labor `yearly_farm_servants` → `service_before_marriage`. Dower runs `recorded_dowry` → `bride_dower_gift` → `widow_third_dower`.
- **Foundlings and religious houses.** `foundling_rescue` → `foundling_free_status` → `foundling_house` (with `charity_hospitals`) → `foundling_wheel`. Culture `devotee_communities_under_rule` (1250) gates `child_oblation`, `commemorative_death_books`, `captive_ransom_brotherhoods`, `single_women_houses` and `purchased_corrodies`.
- **Settlement and migration.** `federate_settlement` → `settler_estate_shares` → `conqueror_landed_settlement` and `intermarriage_permission`. `deserted_land_grants` + `frontier_settler_grants` → `fortified_frontier_villages`. With labor `clearance_dues_holiday` that leads to `colonist_recruiting_agents` → `settler_home_law`. `burgage_plot_towns` requires institutions `chartered_town_liberties`. `ward_residence_lists` + institutions `sworn_town_commune` → `burgess_rolls`, which leads to `town_migration_dependence` and `vagrant_expulsion`.
- `deserted_village_pasture` (1792) requires `post_plague_resettlement` and health `bubo_plague_recognition`. `age_priced_life_annuities` requires `annuity_life_tables` and institutions `funded_public_debt_shares`.
- **Regional items.** `herder_tribute_registers`, `herder_sedentarization` and `foreign_merchant_quarters` carry `contact_required`. The two herder items follow the source's regional tag. `foreign_merchant_quarters` inherits the gate from its 0–600 parent `merchant_quarters_abroad`.
