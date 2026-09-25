# Labor dependencies, years 1200–1800

Machine-readable source: `partials/kicl.json` (knowledge, institutions, culture, labor). Contract: the 600–1200 mapping (`docs/research/y600/deps/partials/kicl.json`, merged by `tools/research/merge_graph_1200.py`). Prerequisites may be 0–600, 600–1200 or 1200–1800 ids in any line, dated at or before the dependent. Any-sets are separated by ` / ` within brackets. Year adjustments are in `partials/kicl_year_adjustments.json`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1215 | `city_supply_corporations` | `hereditary_trade_obligation` |  | `town_grain_dole`, `state_bread_ovens`, `bakery_mill_workforces` |  |
| 1222 | `improvement_leases` | `sharecropping_tenancy`, `witnessed_land_sales` |  | `staked_vine_training`, `deserted_land_grants` |  |
| 1228 | `landowner_patronage_tenancy` | `land_bound_tenancy`, `patron_protection` |  | `head_land_tax_units` |  |
| 1240 | `registered_state_artisans` | `state_manufactories`, `occupation_census` |  | `hereditary_trade_obligation`, `standard_kit_issue` |  |
| 1250 | `fugitive_worker_returns` | `registered_state_artisans`, `land_bound_tenancy` |  | `internal_passes`, `bound_estate_tenants` |  |
| 1255 | `convict_work_gangs` | `mine_lease_labor` |  | `soldier_work_details`, `public_levies` |  |
| 1262 | `hereditary_waterworks_crews` | `conduit_maintenance_crews`, `hereditary_trade_obligation` |  | `heated_public_baths`, `long_distance_conduits` |  |
| 1268 | `communal_house_workshops` | `celibate_communities`, `devotee_communities_under_rule` |  | `household_workshops_with_hands`, `kitchen_gardens` |  |
| 1280 | `rotating_artisan_service` | `registered_state_artisans` |  | `rotating_named_gangs`, `specialist_rotation_ladders` |  |
| 1292 | `settled_bondsman_households` | `landowner_patronage_tenancy`, `home_farm_tenant_split` |  | `freed_person_status`, `term_limited_debt_labor` |  |
| 1305 | `estate_weaving_houses` | `palace_weaving_houses`, `home_farm_tenant_split` |  | `two_beam_upright_loom`, `settled_bondsman_households` |  |
| 1312 | `vineyard_task_work` | `piece_rate_pay`, `staked_vine_training` |  | `improvement_leases`, `daily_task_norms` |  |
| 1318 | `week_work_service` | `home_farm_tenant_split`, `settled_bondsman_households` |  | `bound_estate_tenants`, `land_for_service_tenure` |  |
| 1330 | `harvest_boon_work` | `week_work_service` |  | `cooperative_harvest_gatherings`, `hired_harvest_hands` |  |
| 1335 | `estate_bound_craftsmen` | `week_work_service`, `full_time_specialists` |  | `estate_bailiffs`, `palace_specialist_workshops` |  |
| 1360 | `reciprocal_work_days` | `mutual_aid_customs` |  | `cooperative_harvest_gatherings`, `village_self_rule_after_collapse` |  |
| 1368 | `yearly_grain_share_crafts` | `full_time_specialists`, `iron_farm_tools` |  | `grain_levy_accounting`, `village_labor_quotas` |  |
| 1375 | `load_paid_forest_crews` | `piece_rate_pay`, `covered_charcoal_clamps` |  | `charcoal_licensing`, `fixed_charcoal_hearths` |  |
| 1380 | `estate_survey_books` | `estate_bailiffs`, `week_work_service` |  | `witnessed_land_charters`, `household_tax_registers` |  |
| 1392 | `craft_quarter_streets` | `craft_quarters`, `licensed_guilds` |  | `market_wardens` |  |
| 1395 | `increase_share_herding` | `sharecropping_tenancy` |  | `people_herd_counts`, `summer_pasture_dairies` |  |
| 1400 | `craft_render_quotas` | `estate_bound_craftsmen`, `workshop_quotas` |  | `estate_survey_books` |  |
| 1410 | `estate_steward_audits` | `estate_bailiffs`, `estate_survey_books` |  | `end_of_term_audits`, `provincial_accounts` |  |
| 1425 | `communal_bell_hours` | `clock_timed_shifts`, `communal_house_workshops` |  | `outflow_water_clock`, `devotee_communities_under_rule` |  |
| 1430 | `shared_plough_teams` | `mouldboard_plough`, `reciprocal_work_days` |  | `coulter_plough`, `estate_survey_books` |  |
| 1440 | `salaried_trade_factors` | `voyage_partnerships`, `merchant_letter_accounts` |  | `licensed_merchant_houses`, `salaried_works_staff` |  |
| 1442 | `sheaf_share_reaping` | `hired_harvest_hands`, `harvest_boon_work` |  | `sharecropping_tenancy`, `increase_share_herding` |  |
| 1450 | `contracted_silk_reelers` | `sericulture_reeling`, `putting_out_spinning` |  | `surety_backed_work_contracts` |  |
| 1458 | `saltworks_shift_crews` | `brine_purification`, `clock_timed_shifts` |  | `shift_overlap_briefings`, `salt_working` |  |
| 1468 | `yearly_herdsman_hire` | `hired_labor_contracts`, `increase_share_herding` |  | `summer_shielings` |  |
| 1475 | `mill_suit_obligation` | `water_mills`, `seigneurial_immunity_courts` |  | `mill_operator_trade`, `horizontal_wheel_mills` |  |
| 1482 | `catch_share_crews` | `communal_catch_limits`, `voyage_partnerships` |  | `increase_share_herding`, `sheaf_share_reaping` |  |
| 1495 | `manumission_charters` | `settled_bondsman_households`, `witnessed_land_charters` |  | `freed_person_status`, `freed_craftsman_obligations` |  |
| 1505 | `migrant_harvest_crews` | `harvest_labor_migration`, `hired_harvest_hands` |  | `sheaf_share_reaping`, `harvest_gang_contracts` |  |
| 1512 | `voyage_share_wages` | `voyage_partnerships`, `paid_rowing_crews` |  | `catch_share_crews`, `open_sea_cargo_ships` |  |
| 1520 | `cloth_craft_chain` | `workshop_task_division`, `fullers_earth_finishing` |  | `two_beam_upright_loom`, `treadle_frame_loom`, `craft_quarter_streets` |  |
| 1528 | `clearance_dues_holiday` | `deserted_land_grants`, `manumission_charters` |  | `improvement_leases`, `endowed_reclamation` |  |
| 1535 | `apprentice_indentures` | `apprentice_contracts`, `notarized_work_contracts` |  | `apprentice_quotas`, `craft_quarter_streets` |  |
| 1555 | `hired_labor_levy` | `labor_dues_commutation`, `levy_substitutes` |  | `raider_tribute_land_tax`, `public_work_tenders` |  |
| 1575 | `sworn_porter_guilds` | `porter_gangs`, `merchant_guild_monopoly` |  | `licensed_guilds`, `formal_oath_taking` |  |
| 1585 | `cottager_day_laborers` | `hired_labor_contracts`, `village_nucleation` |  | `uniform_day_rate`, `manumission_charters` |  |
| 1592 | `mill_fulling_crews` | `fulling_mills`, `cloth_craft_chain` |  | `mill_operator_trade` |  |
| 1598 | `state_shipyard_workforce` | `naval_arsenals`, `salaried_works_staff` |  | `series_built_war_galleys`, `carvel_frame_construction` |  |
| 1600 | `guild_trade_monopoly` | `craft_guilds` |  | `merchant_guild_monopoly`, `licensed_guilds`, `sworn_town_commune` |  |
| 1604 | `yearly_farm_servants` | `hired_labor_contracts`, `cottager_day_laborers` |  | `yearly_herdsman_hire` |  |
| 1605 | `single_craft_rule` | `guild_trade_monopoly` |  | `craft_quarter_streets`, `cloth_craft_chain` |  |
| 1610 | `lay_brother_granges` | `communal_house_workshops`, `devotee_communities_under_rule` |  | `endowed_reclamation`, `estate_steward_audits` |  |
| 1615 | `shearing_gangs` | `piece_rate_pay`, `spring_shears` |  | `migrant_harvest_crews`, `yearly_herdsman_hire` |  |
| 1616 | `town_residence_freedom` | `chartered_town_liberties`, `manumission_charters` |  | `sworn_town_commune`, `fugitive_worker_returns` |  |
| 1622 | `guild_searchers` | `guild_trade_monopoly`, `market_wardens` |  | `single_craft_rule`, `spoilage_inspection` |  |
| 1628 | `village_reeve_office` | `manor_court_customals`, `week_work_service` |  | `village_nucleation`, `trade_foremen` |  |
| 1634 | `harvest_bylaws` | `village_reeve_office`, `manor_court_customals` |  | `three_field_rotation`, `common_fallow_grazing_rule` |  |
| 1638 | `guild_cloth_seals` | `guild_searchers`, `cloth_craft_chain` |  | `cargo_seals`, `workman_stamp_marks` |  |
| 1640 | `journeyman_passes` | `journeyman_travel_circuits`, `craft_guilds` |  | `sealed_travel_passes`, `apprentice_indentures` |  |
| 1644 | `dike_duty_lengths` | `estuary_embankments`, `village_reeve_office` |  | `wall_repair_levy`, `measured_length_contracts` |  |
| 1648 | `master_mason_retainers` | `master_builder_office`, `round_arch_great_houses` |  | `skill_graded_wages` |  |
| 1652 | `guild_welfare_chests` | `craft_mutual_aid_clubs`, `craft_guilds` |  | `crew_sick_funds` |  |
| 1658 | `seasonal_day_rates` | `uniform_day_rate`, `master_mason_retainers` |  | `posted_wage_tables`, `decreed_wage_rates` |  |
| 1664 | `purchased_freedom` | `manumission_charters` |  | `town_residence_freedom`, `labor_dues_commutation` |  |
| 1670 | `masons_lodge_rules` | `master_mason_retainers`, `craft_guilds` |  | `trade_hall_lodging` |  |
| 1676 | `shop_size_limits` | `apprentice_quotas`, `guild_trade_monopoly` |  | `single_craft_rule` |  |
| 1680 | `free_miner_companies` | `mine_lease_labor`, `chartered_town_liberties` |  | `water_ore_stamps`, `underground_shift_rotation` |  |
| 1682 | `carver_piece_rates` | `piece_rate_pay`, `master_mason_retainers` |  | `seasonal_day_rates`, `sculpted_portal_programs` |  |
| 1686 | `weekly_works_payrolls` | `public_work_accounts`, `seasonal_day_rates` |  | `master_mason_retainers`, `annual_receipt_rolls` |  |
| 1692 | `masterpiece_trial` | `certified_craft_competence`, `craft_guilds` |  | `guild_searchers`, `journeyman_passes` |  |
| 1698 | `guild_fixed_journey_rates` | `journeyman_passes`, `decreed_wage_rates` |  | `seasonal_day_rates`, `masterpiece_trial` |  |
| 1705 | `debt_bound_putting_out` | `putting_out_spinning`, `cloth_craft_chain` |  | `term_limited_debt_labor`, `spinning_wheels` |  |
| 1712 | `town_trade_statute_book` | `guild_trade_monopoly`, `revised_town_statute_books` |  | `masterpiece_trial`, `guild_searchers` |  |
| 1718 | `night_work_bans` | `guild_trade_monopoly`, `communal_bell_hours` |  | `monthly_rest_days`, `holy_truce_days` |  |
| 1722 | `miners_relief_chest` | `crew_sick_funds`, `free_miner_companies` |  | `guild_welfare_chests` |  |
| 1728 | `womens_craft_guilds` | `craft_guilds`, `contracted_silk_reelers` |  | `single_women_houses` |  |
| 1735 | `rented_loom_putting_out` | `debt_bound_putting_out`, `broad_treadle_loom` |  | `contracted_silk_reelers`, `cloth_craft_chain` |  |
| 1740 | `general_rent_commutation` | `labor_dues_commutation`, `hired_labor_levy` |  | `week_work_service`, `cottager_day_laborers` |  |
| 1746 | `weaver_walkouts` | `cloth_craft_chain`, `ration_work_stoppages` |  | `debt_bound_putting_out`, `journeyman_passes`, `crew_grievance_hearings` |  |
| 1750 | `guild_letter_schools` | `craft_guilds`, `letter_schools_for_citizens` |  | `reckoning_schools`, `apprentice_indentures` |  |
| 1755 | `work_bell_hours` | `communal_bell_hours`, `pit_cast_bells` |  | `night_work_bans`, `belfry_town_halls` |  |
| 1760 | `joint_rate_boards` | `weaver_walkouts`, `guild_fixed_journey_rates` |  | `crew_grievance_hearings`, `town_trade_statute_book` |  |
| 1762 | `rural_putting_out` | `putting_out_spinning`, `debt_bound_putting_out` |  | `guild_trade_monopoly`, `fulling_mills` |  |
| 1765 | `guild_almshouses` | `guild_welfare_chests` |  | `aged_almshouses`, `charity_hospitals` |  |
| 1770 | `journeymen_brotherhoods` | `journeyman_passes`, `guild_welfare_chests` |  | `weaver_walkouts`, `trade_hall_lodging` |  |
| 1772 | `closed_mastership` | `masterpiece_trial`, `guild_trade_monopoly` |  | `shop_size_limits`, `closed_hereditary_council` |  |
| 1775 | `guild_council_seats` | `town_trade_statute_book`, `elected_town_consuls` |  | `chartered_town_league`, `closed_mastership` |  |
| 1780 | `truck_pay_ban` | `coin_and_ration_wages`, `debt_bound_putting_out` |  | `joint_rate_boards`, `silver_wage_payment` |  |
| 1785 | `hiring_fairs` | `yearly_farm_servants`, `guarded_trade_fairs` |  | `public_hiring_grounds` |  |
| 1790 | `post_plague_labor_statutes` | `maximum_wage_edicts`, `bubo_plague_recognition` |  | `guild_fixed_journey_rates`, `keepers_of_the_peace` |  |
| 1797 | `laborer_mobility` | `post_plague_labor_statutes`, `cottager_day_laborers` |  | `general_rent_commutation`, `hiring_fairs`, `deserted_village_pasture` |  |

## Cross-line prerequisites assumed from other 1200–1800 lines

These ids are mapped by other partials in parallel; the edge assumes they keep their registry year.

- `sericulture_reeling` (production 1288) → `contracted_silk_reelers`
- `bubo_plague_recognition` (health 1292) → `post_plague_labor_statutes`
- `brine_purification` (production 1395) → `saltworks_shift_crews`
- `mouldboard_plough` (nutrition 1400) → `shared_plough_teams`
- `pit_cast_bells` (production 1448) → `work_bell_hours`
- `village_nucleation` (demography 1490) → `cottager_day_laborers`
- `estuary_embankments` (infrastructure 1498) → `dike_duty_lengths`
- `fulling_mills` (production 1558) → `mill_fulling_crews`
- `broad_treadle_loom` (production 1570) → `rented_loom_putting_out`
- `guarded_trade_fairs` (logistics 1580) → `hiring_fairs`

## Year adjustments

None.
