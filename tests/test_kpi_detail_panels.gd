extends GdUnitTestSuite
const Data=preload("res://scripts/hud/kpi_detail_data.gd")
const Chip=preload("res://scripts/hud/kpi_detail_chip.gd")
func before_test()->void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(4242)
	SettlementModel.reset_for_new_world()
	GameState.settlement_name="Test City"
	GameState.settlement_site_committed=true
	GameState.settlement_completed=["Hearth Circle"]
	SettlementModel.ensure_founded()
func test_all_six_panels_have_structured_data_and_build()->void:
	var chip=auto_free(Chip.new());add_child(chip)
	for id in ["population","food","water","health","science","gdp"]:
		var data:=Data.snapshot(id)
		assert_str(data.title).is_not_empty()
		assert_int(data.rows.size()).is_greater_equal(1)
		var panel=auto_free(chip.detail_panel(data));add_child(panel)
		assert_int(panel.get_child_count()).is_greater(0)
func test_food_net_is_rations_not_production_ratio()->void:
	GameState.simulation_metrics={"food_days":12.0,"food_consumption":10.0,"food_balance":0.25,"food_net":-7.5,"food_intake_ratio":0.8}
	var data:=Data.snapshot("food")
	assert_str(data.rows[2].value).is_equal("-7.5 rations/day")
	assert_str(data.tone).is_equal("warning")
	assert_float(data.meter).is_equal(0.8)
func test_unmeasured_water_does_not_claim_needs_are_met()->void:
	GameState.water_metrics={}
	var data:=Data.snapshot("water")
	assert_float(data.meter).is_equal(-1.0)
	assert_str(data.value).is_equal("Awaiting report")
func test_selected_city_resources_do_not_leak_into_primary()->void:
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","primary":false,"position":Vector2(10,0),"population_share":0.25,"founded_day":0})
	var city:=SettlementModel.settlement_record("second")
	SettlementModel._ensure_city_resources(city)
	city.local_resources.water_metrics={"days":2.0,"required_today":20.0,"intake_ratio":0.5}
	GameState.water_metrics={"days":9.0,"required_today":60.0,"intake_ratio":1.0}
	GameState.selected_player_settlement_id="second"
	var data:=Data.snapshot("water")
	assert_str(data.scope).is_equal("Entire civilization")
	assert_str(data.value).is_equal("7.3")
	assert_float(data.meter).is_equal(0.875)
	assert_float(float(GameState.water_metrics.days)).is_equal(9.0)
func test_topbar_compiles_with_custom_chips()->void:
	assert_object(load("res://scripts/hud/command_rail_hud.gd")).is_not_null()


func test_totals_are_independent_of_selection_and_show_both_cities()->void:
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","primary":false,"position":Vector2(10,0),"population_share":0.25,"founded_day":0})
	GameState.simulation_metrics={"food_consumption":60.0,"food_days":10.0,"food_production":65.0,"food_eaten":60.0,"labor_efficiency":0.8}
	SettlementModel.with_city_resources("second",func()->void:
		GameState.simulation_metrics={"food_consumption":20.0,"food_days":2.0,"food_production":5.0,"food_eaten":10.0,"labor_efficiency":0.4})
	var model=preload("res://scripts/hud/civilization_kpi_model.gd")
	var first:=model.snapshot()
	GameState.selected_player_settlement_id="second"
	var second:=model.snapshot()
	assert_dict(first).is_equal(second)
	assert_float(first.food_produced).is_equal(70.0)
	assert_float(first.food_days).is_equal(8.0)
	assert_int(first.food_shortages).is_equal(1)
	assert_float(first.output).is_equal(float(first.cities[0].output)+float(first.cities[1].output))
	assert_float(first.science).is_equal(float(first.cities[0].science)+float(first.cities[1].science))
	var detail:=Data.from_totals("food",first)
	assert_str(detail.rows[-1].label).is_equal("Rivermeet")
	assert_str(detail.rows[-1].value).contains("SHORTFALL")
	assert_float(float(GameState.simulation_metrics.food_days)).is_equal(10.0)

func test_food_batch_subset_cannot_zero_out_total_reserves()->void:
	GameState.simulation_metrics={"food_days":133.1,"food_consumption":42.0,"food_batch_stock":0.0,"food_eaten":42.0}
	var model=preload("res://scripts/hud/civilization_kpi_model.gd")
	assert_float(float(model.snapshot().food_days)).is_equal_approx(133.1,.000001)
	GameState.simulation_metrics.food_total_stock=420.0
	assert_float(float(model.snapshot().food_days)).is_equal_approx(10.0,.000001)
	GameState.simulation_metrics.food_total_stock=0.0
	assert_float(float(model.snapshot().food_days)).is_equal(0.0)

