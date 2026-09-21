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
		assert_int(data.rows.size()).is_greater_equal(3)
		var panel=auto_free(chip.detail_panel(data));add_child(panel)
		assert_int(panel.get_child_count()).is_greater(0)
func test_food_net_is_rations_not_production_ratio()->void:
	GameState.simulation_metrics={"food_days":12.0,"food_balance":0.25,"food_net":-7.5,"food_intake_ratio":0.8}
	var data:=Data.snapshot("food")
	assert_str(data.rows[4].value).is_equal("-7.5 rations/day")
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
	assert_str(data.scope).is_equal("Rivermeet")
	assert_str(data.value).is_equal("2.0")
	assert_float(data.meter).is_equal(0.5)
	assert_float(float(GameState.water_metrics.days)).is_equal(9.0)
func test_topbar_compiles_with_custom_chips()->void:
	assert_object(load("res://scripts/hud/command_rail_hud.gd")).is_not_null()
