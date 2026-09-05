extends GdUnitTestSuite
const History:=preload("res://scripts/strategic_history.gd")
const Charts:=preload("res://scripts/hud/strategic_chart_blocks.gd")

func before_test()->void:
	GameState.reset_for_new_world(99117)
	for system_name in SaveSystem.REFLECTED_SYSTEMS+SaveSystem.CURATED_SYSTEMS:
		if system_name!="GameState" and get_node("/root/"+system_name).has_method("reset_for_new_world"): get_node("/root/"+system_name).reset_for_new_world()

func test_centuries_are_bounded_and_preserve_billion_counts()->void:
	var history:Dictionary={}
	for day in range(0,365*400,30):
		History.record(history,day,{"civilization":{"population":2000000000+day}})
	assert_int(history.scopes.civilization.monthly.size()).is_equal(120)
	assert_int(history.scopes.civilization.annual.size()).is_equal(256)
	var rows:=History.points(history,"civilization")
	assert_bool(rows.size()<=376).is_true()
	assert_int(rows[-1].population).is_greater(2000000000)
	for i in range(1,rows.size()): assert_int(rows[i].day).is_greater(rows[i-1].day)
	var count:int=history.scopes.civilization.monthly.size()
	History.record(history,int(history.last_day)+1,{"civilization":{"population":1}})
	assert_int(history.scopes.civilization.monthly.size()).is_equal(count)
	assert_int(History.points(history,"civilization")[-1].population).is_greater(2000000000)

func test_city_stocks_and_missing_observations_stay_separate()->void:
	GameState.population_exact=1000
	GameState.population_total=1000
	GameState.player_settlements=[{"id":"home","primary":true},{"id":"dawngate","primary":false,"population_share":0.2,"local_resources":{"resource_stockpiles":{"Timber":7},"simulation_metrics":{"food_days":2}}}]
	GameState.resource_stockpiles={"Timber":900}
	var scopes:=History.capture_scopes()
	assert_int(scopes.dawngate.population).is_equal(200)
	assert_float(scopes.dawngate.Timber).is_equal(7.0)
	assert_float(scopes.home.Timber).is_equal(900.0)
	assert_bool(scopes.dawngate.has("water_days")).is_false()
	History.record(GameState.strategic_history,30,scopes)
	GameState.selected_player_settlement_id="dawngate"
	assert_float(Charts.stocks("dawngate").items[0].Timber).is_equal(7.0)
	GameState.selected_player_settlement_id="home"
	assert_float(Charts.stocks("home").items[0].Timber).is_equal(900.0)
	assert_bool(Charts.stocks("unknown").items.is_empty()).is_true()

func test_legacy_records_are_actual_values_not_inferred_balances()->void:
	GameState.player_settlements=[{"id":"home","primary":true}]
	GameState.economy_history=[{"day":12,"stage":"currency","treasury":40,"currency_hoards":9}]
	GameState.demographic_ledger=[{"day":10,"population_after":100}]
	var rows:=History.available_points("home",[{"key":"treasury"}])
	assert_int(rows.size()).is_equal(1)
	assert_int(rows[0].treasury).is_equal(40)
	assert_bool(rows[0].has("private_currency")).is_false()
	GameState.player_settlements=[{"id":"dawngate","local_resources":{"food_history":[{"day":2,"stored":100,"required":20,"produced":25,"eaten":20}],"water_history":[{"day":2,"stored":60,"required":20}]}}]
	rows=Charts.reserves("dawngate").items
	assert_float(rows[0].food_days).is_equal(5.0)
	assert_float(rows[0].water_days).is_equal(3.0)

func test_actual_save_load_and_older_missing_field()->void:
	var slot:="strategic_chart_test_"+str(Time.get_ticks_usec())
	History.record(GameState.strategic_history,30,{"civilization":{"population":2000000000},"dawngate":{"Timber":7}})
	var expected:=GameState.strategic_history.duplicate(true)
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	GameState.strategic_history={}
	var load_result:Dictionary=SaveSystem.load_game(slot)
	if load_result.has("error"): print(load_result)
	assert_dict(load_result).contains_key_value("ok",true)
	assert_dict(GameState.strategic_history).is_equal(expected)
	var payload:=SaveSystem._read_payload(slot)
	payload.reflected_GameState.erase("strategic_history")
	var file:=FileAccess.open(SaveSystem.slot_path(slot),FileAccess.WRITE)
	file.store_string(var_to_str(payload))
	file.close()
	load_result=SaveSystem.load_game(slot)
	if load_result.has("error"): print(load_result)
	assert_dict(load_result).contains_key_value("ok",true)
	assert_bool(GameState.strategic_history.is_empty()).is_true()
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))

func test_chart_range_and_city_control_state()->void:
	var chart:=preload("res://scripts/hud/trend_chart.gd").new()
	add_child(chart)
	History.record(GameState.strategic_history,0,{"home":{"population":20}})
	History.record(GameState.strategic_history,1000,{"home":{"population":40}})
	chart.setup(Charts.population("home",true))
	chart.buttons[0].pressed.emit()
	assert_int(chart.graph.points.size()).is_equal(1)
	chart.buttons[3].pressed.emit()
	assert_int(chart.graph.points.size()).is_equal(2)
	chart.free()




func test_currency_accounts_are_local_and_stage_gated()->void:
	GameState.player_settlements=[{"id":"home","primary":true},{"id":"dawngate","local_resources":{"economy_stage":"currency","public_treasury":7.0,"private_currency":12.0,"currency_hoards":2.0,"mutual_aid_reserve":1.0}}]
	GameState.economy_stage="currency"
	GameState.public_treasury=900.0
	var scopes:=History.capture_scopes()
	assert_float(scopes.home.treasury).is_equal(900.0)
	assert_float(scopes.dawngate.treasury).is_equal(7.0)
	assert_bool(scopes.civilization.has("treasury")).is_false()
	GameState.player_settlements[1].local_resources.economy_stage="subsistence"
	scopes=History.capture_scopes()
	assert_bool(scopes.dawngate.has("treasury")).is_false()

func test_recorded_values_override_legacy_only_at_same_observation()->void:
	GameState.player_settlements=[{"id":"home","primary":true}]
	GameState.food_history=[{"day":12,"produced":20},{"day":42,"produced":25}]
	History.record(GameState.strategic_history,42,{"home":{"food_production":30}})
	var rows:=History.available_points("home",[{"key":"food_production"}])
	assert_int(rows.size()).is_equal(2)
	assert_int(rows[0].food_production).is_equal(20)
	assert_int(rows[1].food_production).is_equal(30)
