# Labor dependencies

Machine-readable source: `docs/research/deps/labor.json`. Format per `MAPPING_CONTRACT.md`. Year flags: `labor_FLAGS.md`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1 | `labor_rotations` — Shared work taken in turns | — | — | — | — |
| 2 | `household_task_division` — Household tasks divided by age and season | — | — | labor_rotations | — |
| 3 | `dawn_task_briefings` — Tasks assigned at dawn | — | — | labor_rotations, household_task_division | — |
| 4 | `aptitude_trials` — Aptitude trials for new hands | — | — | household_task_division | — |
| 5 | `paired_task_assignment` — Hard tasks done in pairs | — | — | labor_rotations | — |
| 6 | `rest_break_timing` — Rest breaks timed by the sun | labor_rotations | — | seasonal_patterns, weather_sign_reading | — |
| 8 | `shared_work_signals` — Shared work signals: calls and claps | labor_rotations | — | communal_work_songs, distance_call_signals | — |
| 10 | `seasonal_work_round` — Seasonal round: set times to plant, fell and build | household_task_division, seasonal_patterns | — | weather_sign_reading | — |
| 12 | `task_sequencing_habits` — Task sequencing habits | dawn_task_briefings | — | raw_material_prestaging | — |
| 14 | `midday_heat_rest` — Midday rest in the hot season | rest_break_timing | — | seasonal_work_round | — |
| 16 | `children_light_tasks` — Children's light tasks: bird-scaring and gleaning | household_task_division | — | seasonal_work_round | — |
| 18 | `skill_recognition` — Skilled hands recognized by name | aptitude_trials | — | novice_task_shadowing | — |
| 22 | `rotating_heavy_tasks` — Heavy tasks rotated among the able | labor_rotations, paired_task_assignment | — | aptitude_trials | — |
| 25 | `herding_rotas` — Herding rotas for common flocks | labor_rotations, animal_taming | — | herd_size_limits | — |
| 28 | `work_party_feasts` — Neighbour work party repaid with a feast | labor_rotations, reciprocal_gift_exchange | — | communal_work_songs, shared_hearth_gatherings | — |
| 32 | `festival_rest_days` — Festival rest days | festival_calendar, rest_break_timing | — | — | — |
| 36 | `part_time_specialists` — Part-time craft specialists within households | skill_recognition, seasonal_work_round | any of food_drying, smoking | — | min_population=30 |
| 40 | `slack_season_building` — Building work kept for the slack season | seasonal_work_round, framed_construction | — | — | — |
| 50 | `household_craft_learning` — Children learn a craft beside a parent | part_time_specialists, novice_task_shadowing | — | — | — |
| 55 | `motion_economy_habits` — Economical movement habits | task_sequencing_habits | — | rotating_heavy_tasks | — |
| 58 | `recovery_days_after_heavy_tasks` — Recovery days after heavy tasks | rotating_heavy_tasks | — | festival_rest_days | — |
| 62 | `boundary_markers_parallel_crews` — Boundary markers for parallel crews | common_ground_marking, work_party_feasts | — | field_boundary_markers | — |
| 66 | `cross_training_circuits` — Cross-training circuits | household_craft_learning, rotating_heavy_tasks | — | — | — |
| 80 | `task_captains` — Task captains | boundary_markers_parallel_crews, skill_recognition | — | elder_council_assent | min_population=60 |
| 88 | `hauling_chants` — Hauling chants to time a pull | shared_work_signals, communal_work_songs | — | wedges_and_levers, rollers_and_runners | — |
| 95 | `paced_work_cycles` — Paced work cycles | motion_economy_habits, recovery_days_after_heavy_tasks | — | hauling_chants | — |
| 100 | `great_work_parties` — Great work parties for megaliths and dykes | task_captains, work_party_feasts | — | hauling_chants, wedges_and_levers | min_population=120 |
| 110 | `mentored_task_learning` — Mentored task learning | household_craft_learning | — | novice_task_shadowing, repeated_recitation_training | — |
| 120 | `seasonal_labor_pooling` — Seasonal labor pooling | seasonal_work_round, great_work_parties | — | shared_labor_registers | — |
| 130 | `batch_sizing_by_fatigue` — Batch size set by fatigue | paced_work_cycles, batch_task_grouping | — | — | — |
| 135 | `elder_instruction_days` — Elder instruction days | mentored_task_learning, elder_consultation_rites | — | — | — |
| 140 | `household_labor_borrowing` — Labor borrowed between households | work_party_feasts, labor_debt_tallies | — | — | — |
| 145 | `runner_relays_between_work_sites` — Runner relays between work sites | task_captains | any of relay_call_stations, relay_carrying_shifts | route_memory | — |
| 155 | `full_time_specialists` — Full-time specialists fed from shared stores | part_time_specialists, public_stores | any of raised_granaries, hermetic_grain_storage | temple_common_storehouse | min_population=200 |
| 165 | `load_tallies` — Overseer's tally of loads carried | tallies, task_captains | — | clay_counting_tokens, knotted_record_systems | — |
| 180 | `shrine_work_obligations` — Owed work days for the shrine store | first_shrine_house, seasonal_labor_pooling | — | temple_common_storehouse, labor_debt_tallies | — |
| 195 | `tool_handoff_staging` — Tools staged for handoff | raw_material_prestaging, task_captains | — | load_tallies | — |
| 205 | `cross_party_scheduling` — Scheduling across work parties | seasonal_labor_pooling, runner_relays_between_work_sites | — | solar_year_reckoning | — |
| 215 | `fixed_worker_rations` — Fixed grain rations per worker | full_time_specialists, public_grain_weighing | — | temple_ration_issue, standard_measures | — |
| 225 | `craft_quarters` — Craft quarters: specialists cluster by trade | full_time_specialists | — | downwind_workshop_placement, workshop_space_sharing | min_population=400 |
| 235 | `specialist_rotation_ladders` — Specialist rotation ladders | full_time_specialists, cross_training_circuits | — | mentored_task_learning | — |
| 240 | `crew_handoffs` — Crews hand over unfinished work by tally | load_tallies, cross_party_scheduling | — | — | — |
| 248 | `capacity_ledgers` — Capacity ledgers | load_tallies | any of impressed_number_tablets, knotted_record_systems, marked_storage_registers | shared_labor_registers | — |
| 252 | `tool_reach_zoning` — Tool reach zoning | motion_economy_habits, workshop_space_sharing | — | craft_quarters | — |
| 262 | `joint_crew_debriefs` — Joint crew debriefs | crew_handoffs, focused_error_review | — | problem_council_sessions | — |
| 268 | `journeyman_placement` — Skilled helpers placed with masters | mentored_task_learning, craft_quarters | — | specialist_rotation_ladders | — |
| 280 | `age_graded_load_limits` — Age-graded load limits | rotating_heavy_tasks, load_tallies | — | load_carrying_posture, coming_of_age_rites | — |
| 310 | `apprentice_for_keep` — Apprentice works for keep while learning | journeyman_placement, fixed_worker_rations | — | scribal_apprenticeship | — |
| 345 | `workshop_layout_planning` — Workshop layout planning | tool_reach_zoning, craft_quarters | — | temple_workshops | — |
| 350 | `crew_count_scribes` — Scribes assigned to count crews | capacity_ledgers, scribal_apprenticeship | — | clay_record_tablets | — |
| 355 | `gangs_of_ten` — Gangs of ten under a foreman | work_gang_overseers | — | tens_sixties_bundling, task_captains | — |
| 365 | `certified_craft_competence` — Recognized master craftworkers | journeyman_placement | — | craft_lineage_naming, workshop_standards | — |
| 380 | `rotating_named_gangs` — Named gangs in rotating watches for great works | gangs_of_ten | — | shared_work_crew_rotation, watch_duty_rotation | — |
| 385 | `flood_season_great_works` — Great works scheduled for the flood season | great_work_parties, cross_party_scheduling | any of star_rise_markers, solar_year_reckoning | flood_levees | environment=river |
| 390 | `workers_villages` — Workers' village beside a great work | fixed_worker_rations, rotating_named_gangs | — | work_gang_bakeries | min_population=800 |
| 400 | `shift_overlap_briefings` — Shift overlap briefings | crew_handoffs | — | joint_crew_debriefs, dawn_task_briefings | — |
| 420 | `fatigue_aware_task_assignment` — Fatigue-aware task assignment | batch_sizing_by_fatigue, age_graded_load_limits | — | — | — |
| 425 | `measured_plot_allotment` — Field work allotted by measured plots | standard_measures, field_boundary_markers | — | boundary_marker_surveys, geometric_survey | — |
| 430 | `brick_quotas` — Daily brick quota per moulder | mould_made_mudbricks, capacity_ledgers | — | standard_brick_proportions | — |
| 440 | `hired_harvest_hands` — Harvest hands hired for the season | seasonal_labor_pooling, fixed_worker_rations | — | barter_equivalence_custom | — |
| 450 | `daily_task_norms` — Standard daily task norms for digging and carrying | brick_quotas, crew_count_scribes | — | area_volume_rules | — |
| 470 | `light_duty_for_infirm` — Lighter tasks and rations for sick and aged workers | fatigue_aware_task_assignment | — | disability_care, graded_rations | — |
| 480 | `man_day_accounts` — Man-day accounts of labor owed and done | daily_task_norms, crew_count_scribes | — | labor_debt_tallies | — |
| 490 | `monthly_rest_days` — Fixed rest days in the working month | festival_rest_days, moon_counting | — | calendar_feast_days | — |
| 500 | `levy_substitutes` — Substitutes hired to serve another's levy | public_levies, hired_harvest_hands | — | — | — |
| 520 | `hired_labor_contracts` — Labor hired for silver or grain by sealed agreement | hired_harvest_hands, sealed_tablet_contracts | — | price_wage_schedules | — |
| 540 | `apprentice_contracts` — Apprentice contracts with a set term | apprentice_for_keep, sealed_tablet_contracts | — | hired_labor_contracts | — |
| 555 | `levy_exemptions` — Exemption from levy for temple or craft service | public_levies, certified_craft_competence | — | temple_estates, written_law_code | — |
| 570 | `attendance_lists` — Foremen's daily attendance lists | man_day_accounts | — | — | — |
| 580 | `trade_elders` — Trade elders speak for workshop crews | certified_craft_competence, craft_quarters | — | free_adult_assembly, petition_speakers | — |
| 590 | `apprentice_quotas` — Masters train a set number of apprentices | apprentice_contracts, trade_elders | — | workshop_quotas | — |
| 600 | `crew_loans_between_cities` — Skilled crews lent between cities | rotating_named_gangs, certified_craft_competence | any of foreign_treaties, boundary_treaties, sealed_travel_passes | — | min_settlements=3 |
