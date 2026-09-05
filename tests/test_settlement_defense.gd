extends GdUnitTestSuite


func before_test()->void:
	GameState.reset_for_new_world(91357)
	GameState.settlement_site_committed=true
	GameState.resource_stockpiles={"Food":5000.0,"Timber":5000.0,"Stone":5000.0,"Fiber Plants":5000.0,"Clay":5000.0}
	GameState.population_allocations["Defense"]=24
	GameState.population_allocations["Construction"]=12
	GameState.simulation_metrics["labor_efficiency"]=0.82
	FoodSystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()


func test_defense_upgrade_consumes_materials_and_improves_home_ground()->void:
	var timber_before:=float(GameState.resource_stockpiles.Timber)
	var terrain_before:=float(MilitaryCampaign.defensive_position().modifier)
	var started:Dictionary=MilitaryCampaign.start_settlement_defense_upgrade()
	assert_bool(bool(started.get("ok",false))).is_true()
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(timber_before-10.0)
	for _day in 30: MilitaryCampaign._process_settlement_defense_day()
	var defense:Dictionary=MilitaryCampaign.settlement_defense_snapshot()
	assert_int(int(defense.stage)).is_equal(1)
	assert_str(String(defense.name)).is_equal("WATCH POSTS")
	assert_float(float(defense.observation_radius_km)).is_greater(28.0)
	assert_float(float(MilitaryCampaign.defensive_position().modifier)).is_greater(terrain_before)
	assert_array(MilitaryCampaign.validate_state()).is_empty()


func test_home_siege_damages_defenses_and_reduces_their_bonus()->void:
	MilitaryCampaign.settlement_defense={"stage":3,"integrity":1.0,"project_stage":-1,"project_progress":0.0,"project_work":0.0,"reserved_materials":{},"completed_day":0}
	var bonus_before:=float(MilitaryCampaign.settlement_defense_snapshot().defense_bonus)
	MilitaryCampaign._apply_home_siege_damage({"campaign_mode":"defensive","target_region_id":"","round_count":4,"outcome":"attacker_victory"})
	var defense:Dictionary=MilitaryCampaign.settlement_defense_snapshot()
	assert_float(float(defense.integrity)).is_less(1.0)
	assert_float(float(defense.defense_bonus)).is_less(bonus_before)
	assert_float(float(MilitaryCampaign.store_protection().structural_protection)).is_greater(0.0)
	assert_array(MilitaryCampaign.validate_state()).is_empty()


func test_billion_population_keeps_one_fixed_defense_record()->void:
	var keys_before:=(MilitaryCampaign.settlement_defense_snapshot() as Dictionary).keys().size()
	GameState.ensure_population_total(1_000_000_000)
	var defense:Dictionary=MilitaryCampaign.settlement_defense_snapshot()
	assert_int(defense.keys().size()).is_equal(keys_before)
	assert_int(int(defense.garrison_required)).is_greater(1_000_000)
	assert_bool(MilitaryCampaign.settlement_defense is Dictionary).is_true()
	assert_array(MilitaryCampaign.validate_state()).is_empty()


func test_camp_drill_spends_rations_and_improves_field_army_readiness()->void:
	_field_basic_army(2)
	var training_before:=float(MilitaryCampaign.home_army.formations[0].training)
	var readiness_before:=float(MilitaryCampaign.home_army.get("readiness",0.0))
	var food_before:=FoodSystem.total_stored()
	var started:Dictionary=MilitaryCampaign.start_training_program("camp_drill")
	assert_bool(bool(started.get("ok",false))).is_true()
	for _day in 40:
		if MilitaryCampaign.training_program.is_empty(): break
		MilitaryCampaign._process_training_program_day()
	assert_bool(MilitaryCampaign.training_program.is_empty()).is_true()
	assert_int(MilitaryCampaign.training_program_cycles).is_equal(1)
	assert_float(float(MilitaryCampaign.home_army.formations[0].training)).is_greater(training_before)
	assert_float(float(MilitaryCampaign.home_army.get("readiness",0.0))).is_greater(readiness_before)
	assert_float(FoodSystem.total_stored()).is_less(food_before)
	assert_float(float(MilitaryCampaign.home_army.get("exercise_readiness_bonus",0.0))).is_greater(0.03)
	assert_array(MilitaryCampaign.validate_state()).is_empty()


func test_staff_exercise_develops_the_command_institution_and_round_trips()->void:
	_field_basic_army(2)
	GameState.known_discoveries.append("military_staffs")
	GameState.discovery_adoption["military_staffs"]=1.0
	var command_before:=float(MilitaryCampaign.campaign_army_snapshot().commander.command)
	var started:Dictionary=MilitaryCampaign.start_training_program("staff_exercise")
	assert_bool(bool(started.get("ok",false))).is_true()
	for _day in 50:
		if MilitaryCampaign.training_program.is_empty(): break
		MilitaryCampaign._process_training_program_day()
	var command_after:=float(MilitaryCampaign.campaign_army_snapshot().commander.command)
	assert_float(float(MilitaryCampaign.command_development.command)).is_greater(0.03)
	assert_float(float(MilitaryCampaign.command_development.logistics)).is_greater(0.04)
	assert_float(command_after).is_greater(command_before)
	var saved:=MilitaryCampaign.export_state()
	MilitaryCampaign.command_development={"command":0.0,"tactics":0.0,"logistics":0.0,"resolve":0.0}
	assert_bool(bool(MilitaryCampaign.import_state(saved).get("ok",false))).is_true()
	assert_float(float(MilitaryCampaign.command_development.command)).is_greater(0.03)
	assert_array(MilitaryCampaign.validate_state()).is_empty()


func _field_basic_army(count:int)->void:
	MilitaryCampaign.military_inventory["improvised"]=count
	MilitaryCampaign.raise_recruits(count)
	var order:=MilitaryCampaign.start_training("levy","improvised",count)
	var training:Dictionary=MilitaryCampaign.training_queue[0].duplicate(true)
	training["equipment_access_sum"]=float(training.required_days)
	training["instruction_progress_sum"]=float(training.required_days)
	MilitaryCampaign._complete_training(training)
	MilitaryCampaign.training_queue.clear()
