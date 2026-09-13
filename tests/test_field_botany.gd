extends GdUnitTestSuite
const B=preload("res://scripts/field_botany.gd")
const K=preload("res://scripts/field_botany_knowledge.gd")
func knowledge()->Array:
	var result:Array=[]
	for entry:Dictionary in K.entries():result.append(entry.id)
	return result
func test_two_generations_require_paid_observation_days()->void:
	var ledger:=B.empty_state()
	ledger.balance=true
	assert_float(B.retain_seed(ledger,100.0,"home",0)).is_equal(1.0)
	assert_bool(B.sow_trial(ledger,0,"home",0)).is_true()
	var used_water:=0.0
	var used_work:=0.0
	for day:int in range(1,91):
		var report:=B.observe(ledger,day,"home",knowledge(),1.0,1.0,.5)
		used_water+=float(report.water);used_work+=float(report.work)
		assert_int(int(B.observe(ledger,day,"home",knowledge(),1.0,1.0,.5).completed)).is_equal(0)
	assert_float(used_water).is_equal_approx(27.0,.001)
	assert_float(used_work).is_equal_approx(9.0,.001)
	assert_int(ledger.lines.size()).is_equal(2)
	assert_bool(ledger.vouchers[0].qualified).is_false()
	assert_bool(B.sow_trial(ledger,1,"home",90)).is_true()
	for day:int in range(91,181):B.observe(ledger,day,"home",knowledge(),1.0,1.0,.5)
	assert_bool(ledger.vouchers[1].qualified).is_true()
	assert_int(ledger.lines[2].generation).is_equal(2)
	assert_bool(B.valid(ledger)).is_true()
func test_missing_resources_and_wrong_site_do_not_advance_cohort()->void:
	var ledger:=B.empty_state()
	ledger.balance=true
	B.retain_seed(ledger,100.0,"home",0)
	B.sow_trial(ledger,0,"home",0)
	B.observe(ledger,1,"away",knowledge(),1.0,1.0,.5)
	B.observe(ledger,2,"home",knowledge(),0.0,1.0,.5)
	B.observe(ledger,3,"home",knowledge(),1.0,0.0,.5)
	assert_int(ledger.trials[0].age).is_equal(0)
	B.observe(ledger,181,"home",knowledge(),1.0,1.0,.5)
	assert_int(ledger.trials.size()).is_equal(0)
	assert_int(ledger.lines.size()).is_equal(1)
func test_quote_expires_and_never_mutates_or_awards_future_success()->void:
	var ledger:=B.empty_state()
	ledger.balance=true
	ledger.applications.append({"site":"home","until":30,"area":.1,"response":.5})
	var before:=ledger.duplicate(true)
	assert_float(B.application_quote(ledger,"home",29,100,.5)).is_greater(0)
	assert_float(B.application_quote(ledger,"home",30,100,.5)).is_equal(0.0)
	assert_float(B.application_quote(ledger,"away",29,100,.5)).is_equal(0.0)
	assert_dict(ledger).is_equal(before)
func test_local_operation_spends_materials_and_applies_only_paid_descendant_seed()->void:
	WorldSimulation.clear()
	WorldSimulation.create_actor("botanist",91420)
	WorldSimulation.scoped("botanist",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true
		state.known_discoveries.append_array(knowledge())
		state.known_discoveries.append_array(["standard_measures","seed_selection"])
		state.resource_stockpiles={"Timber":2.0,"Fiber Plants":2.0,"Stone":2.0,"Clay":10.0,"Freshwater":1000.0}
		B.retain_seed(state.field_botany,100,"home",0)
		state.field_botany.lines[0].drought_tolerance=.4
		for day:int in range(1,184):
			state.elapsed_days=day
			var report:=B.advance(20,false,.5)
			assert_float(float(report.workers)).is_less_equal(1.0)
			var stocks:Dictionary=state.resource_stockpiles.duplicate(true)
			B.advance(20,false,.5)
			assert_dict(state.resource_stockpiles).is_equal(stocks)
		assert_bool(state.field_botany.balance).is_true()
		assert_float(float(state.resource_stockpiles.Timber)).is_less(2.0)
		assert_float(float(state.resource_stockpiles.Freshwater)).is_less(950.0)
		assert_int(state.field_botany.applications.size()).is_equal(1)
		assert_float(float(state.field_botany.applications[0].seed)).is_greater(0.0)
		assert_bool(B.valid(state.field_botany)).is_true()
	)
	WorldSimulation.clear()
func test_actual_food_consumer_uses_application_and_expiry_without_mutating_preview()->void:
	WorldSimulation.clear()
	WorldSimulation.create_actor("field",91420)
	WorldSimulation.scoped("field",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true
		state.known_discoveries.append("seed_selection")
		state.discovery_adoption.seed_selection=1.0
		state.population_allocations.Food=30
		var food=WorldSimulation.food
		var day:=1
		while day<365 and food._weather_yield_factor(food._environment_mix(),day)>=.99:day+=1
		state.elapsed_days=day
		var baseline:Dictionary=food._produce(30,1,1,false)
		state.field_botany.applications.append({"site":"home","until":day+10,"area":.1,"response":.2})
		var before:Dictionary=state.field_botany.duplicate(true)
		var applied:Dictionary=food._produce(30,1,1,false)
		assert_float(float(applied["Dry staples"])).is_greater(float(baseline["Dry staples"]))
		assert_dict(state.field_botany).is_equal(before)
		state.field_botany.applications[0].until=day
		assert_dict(food._produce(30,1,1,false)).is_equal(baseline)
	)
	WorldSimulation.clear()
func test_small_matching_harvests_top_up_but_never_import_foreign_seed()->void:
	var ledger:=B.empty_state()
	B.retain_seed(ledger,1,"home",0)
	assert_bool(B.sow_trial(ledger,0,"home",0)).is_false()
	assert_float(B.retain_seed(ledger,10,"away",1)).is_equal(0.0)
	for day:int in range(1,25):B.retain_seed(ledger,1,"home",day)
	assert_bool(B.sow_trial(ledger,0,"home",25)).is_true()
	assert_float(float(ledger.reference_seed)).is_less(.1)
func test_failed_morphological_match_cannot_qualify_and_nested_forgery_is_rejected()->void:
	var ledger:=B.empty_state();ledger.balance=true
	B.retain_seed(ledger,100,"home",0)
	B.sow_trial(ledger,0,"home",0)
	for day:int in range(1,90):B.observe(ledger,day,"home",knowledge(),1,1,.5)
	ledger.trials[0].stages[0].leaf_ratio=.999
	B.observe(ledger,90,"home",knowledge(),1,1,.5)
	assert_bool(ledger.vouchers[0].methods.has("identity")).is_false()
	assert_bool(ledger.vouchers[0].qualified).is_false()
	var corrupted:=ledger.duplicate(true)
	corrupted.vouchers[0].qualified=true
	assert_bool(B.valid(corrupted)).is_false()
	corrupted=ledger.duplicate(true)
	corrupted.lines[0].drought_tolerance=-.1
	assert_bool(B.valid(corrupted)).is_false()
func human_field()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.reset_for_new_world(1902);CivilizationSystem.reset_for_new_world();MilitaryCampaign.reset_for_new_world();DiscoverySystem.reset_for_new_world();GovernmentPeopleSystem.reset_for_new_world()
	GameState.initialize_population_model();GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
	GameState.known_discoveries.append_array(knowledge())
	GameState.known_discoveries.append("standard_measures")
	GameState.resource_stockpiles={"Timber":2.0,"Fiber Plants":2.0,"Stone":2.0,"Clay":10.0,"Freshwater":1000.0}
func release_field()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func test_full_save_and_city_swap_preserve_unfinished_trials_and_local_costs()->void:
	human_field()
	B.retain_seed(GameState.field_botany,100,"home",0)
	for day:int in range(1,25):
		GameState.elapsed_days=day;B.advance(20,false,.5)
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","position":Vector2(10,10),"primary":false,"population_share":.2,"founded_day":20})
	var home:=GameState.field_botany.duplicate(true)
	var stocks:=GameState.resource_stockpiles.duplicate(true)
	SettlementModel.with_city_resources("second",func()->void:
		assert_dict(GameState.field_botany).is_equal(B.empty_state())
		GameState.resource_stockpiles={"Timber":2.0,"Fiber Plants":2.0,"Stone":2.0,"Clay":2.0,"Freshwater":2.0}
		B.retain_seed(GameState.field_botany,100,"second",24)
		B.advance(20,false,.5)
	)
	assert_dict(GameState.field_botany).is_equal(home)
	assert_dict(GameState.resource_stockpiles).is_equal(stocks)
	var slot:="codex_botany_%d" % Time.get_ticks_usec()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	GameState.field_botany=B.empty_state()
	var restored:=SaveSystem.load_game(slot)
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	assert_dict(GameState.field_botany).is_equal(home)
	assert_dict(GameState.resource_stockpiles).is_equal(stocks)
	B.advance(20,false,.5)
	assert_dict(GameState.field_botany).is_equal(home)
	GameState.elapsed_days=25;B.advance(20,false,.5)
	assert_int(int(GameState.field_botany.trials[0].age)).is_equal(int(home.trials[0].age)+1)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	release_field()
func test_forecast_expires_current_application_without_spending_or_creating_trials()->void:
	human_field()
	GameState.known_discoveries.append("seed_selection");GameState.discovery_adoption.seed_selection=1.0
	GameState.population_allocations.Food=30
	var day:=1
	while day<365 and FoodSystem._weather_yield_factor(FoodSystem._environment_mix(),day)>=.99:day+=1
	GameState.elapsed_days=day
	GameState.field_botany.applications.append({"site":"home","until":day+1,"area":.1,"response":.2})
	var report:Dictionary={}
	var harvest:Dictionary=FoodSystem._produce(30,1,1,false,false,report)
	var before:=GameState.field_botany.duplicate(true)
	var stocks:=GameState.resource_stockpiles.duplicate(true)
	var demand:Dictionary=FoodSystem._calculate_demand(false)
	var finite:Dictionary=FoodSystem._forecast(90,harvest,demand,false,1,{},report)
	var repeated:Dictionary=FoodSystem._forecast(90,harvest,demand,false)
	assert_float(float(finite.average_production)).is_less(float(repeated.average_production))
	assert_dict(GameState.field_botany).is_equal(before)
	assert_dict(GameState.resource_stockpiles).is_equal(stocks)
	release_field()
func test_inferior_candidate_and_exhausted_reference_cannot_create_advantage_or_free_seed()->void:
	var ledger:=B.empty_state();ledger.balance=true
	B.retain_seed(ledger,100,"home",0)
	ledger.lines[0].drought_tolerance=.1
	B.sow_trial(ledger,0,"home",0)
	for day:int in range(1,91):B.observe(ledger,day,"home",knowledge(),1,1,.5)
	assert_float(float(ledger.vouchers[0].response)).is_equal(0.0)
	ledger.reference_seed=0.0;ledger.reference_line.seed=0.0
	assert_bool(B.sow_trial(ledger,0,"home",91)).is_false()
	var candidate_before:=float(ledger.lines[0].seed)
	assert_float(B.retain_seed(ledger,10,"home",91)).is_equal(.1)
	assert_float(float(ledger.lines[0].seed)).is_greater(candidate_before)
	assert_float(float(ledger.reference_seed)).is_equal(.05)
