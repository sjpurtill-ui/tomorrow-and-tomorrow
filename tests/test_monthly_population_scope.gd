extends GdUnitTestSuite
func prepare()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(424242)
	SettlementModel.reset_for_new_world()
	GameState.initialize_population_model();GameState.ensure_population_total(1000)
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_name="Home"
	SettlementModel.ensure_founded()
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","position":Vector2(10,10),"primary":false,"population_share":.2,"founded_day":20})
func after_test()->void:WorldSimulation.clear()
func run_months(optimized:bool,secondary:bool)->Dictionary:
	prepare()
	for day in range(1,62):
		GameState.elapsed_days=day
		if day==12:GameState.settlement_name="Renamed home"
		var operation:=func()->void:
			# Exercise missing-summary repair between monthly boundaries too.
			if day==17:GameState.settlement_morphology.clear()
			if optimized:SettlementModel.process_local_month({})
			else:SettlementModel.with_local_population(func()->void:SettlementModel.process_month({}))
		if secondary:SettlementModel.with_city_resources("second",operation)
		else:operation.call()
	return SaveSystem._capture_reflected(GameState,[])
func test_primary_idle_days_month_boundaries_and_summary_repair_match_previous_path()->void:
	var original:=run_months(false,false)
	var optimized:=run_months(true,false)
	assert_dict(optimized).is_equal(original)
	assert_str(String(GameState.player_settlements[0].name)).is_equal("Renamed home")
func test_secondary_local_population_and_fabric_match_previous_path()->void:
	var original:=run_months(false,true)
	var optimized:=run_months(true,true)
	assert_dict(optimized).is_equal(original)
	assert_float(GameState.population_exact).is_equal(1000.0)
