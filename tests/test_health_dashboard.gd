extends GdUnitTestSuite
const Dashboard:=preload("res://scripts/hud/health_dashboard.gd")
const Discoveries:=preload("res://scripts/hud/health_discoveries.gd")
const Provider:=preload("res://scripts/hud/content/dock_detail_health.gd")
const Chart:=preload("res://scripts/hud/health_history_chart.gd")
var dashboard:VBoxContainer

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(771204);GameState.initialize_population_model()
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	SettlementModel.reset_for_new_world()

func after_test()->void:
	if is_instance_valid(dashboard):dashboard.queue_free()
	await get_tree().process_frame

func _fixture()->Dictionary:
	var readings:Array=[]
	for label:String in ["LIFE EXPECTANCY","INFANTS LOST","DEATHS THIS YEAR","AGE AT DEATH"]:
		readings.append({"label":label,"value":"30 years","delta":"since last month"})
	return {"readings":readings,"history":[
		{"day":0,"life_expectancy":25.0,"delta":0.0},
		{"day":30,"life_expectancy":26.0,"delta":1.0,"marker_type":"discovery","marker_label":"Clean water","reasons":[{"key":"food","years":0.7,"from":0.6,"to":0.7},{"key":"care","years":0.3}]}],
		"research":{"totals":[{"id":"water_safety","label":"Water safety","amount":0.004,"unlocked":0.02,"count":1,"tip":"Safer water"}],"recent":[{"id":"clean_water","day":12,"name":"Clean water","adoption":0.2,"practice":0.18,"effects":[{"label":"Water safety","value":"+0.40 points","tip":"Safer water"}],"protections":[],"record":"Monthly change includes all causes.","mechanism":"Clean water helps children avoid infection."},
		{"id":"wounds","name":"Wound care","adoption":0.5,"practice":0.5,"effects":[],"protections":[],"record":"No earlier reading."}]},
		"conditions":[{"name":"Diet","value":"Good","detail":"A varied diet."}],"care":"Care of the sick","care_share":0.25,"care_unlocked":true,"water":100,"housing":100}

func _open(width:float)->void:
	dashboard=Dashboard.new();add_child(dashboard);dashboard.size.x=width;dashboard.setup(_fixture())
	for frame in 6:await get_tree().process_frame

func test_wide_dashboard_fits_without_a_long_outer_page()->void:
	await _open(1000)
	assert_bool(dashboard._columns.vertical).is_false()
	assert_float(dashboard.get_combined_minimum_size().y).is_less(590)
	assert_float(dashboard.size.x).is_equal(1000.0)
	assert_bool(dashboard._chart.is_visible_in_tree()).is_true()
	assert_int(dashboard.find_children("*","OptionButton",true,false).size()).is_equal(0)
	for control:Control in dashboard.find_children("*","Control",true,false):
		if control.is_visible_in_tree() and not dashboard._detail.is_ancestor_of(control):
			assert_float(control.get_global_rect().end.x).is_less_equal(dashboard.get_global_rect().end.x+1)

func test_narrow_dashboard_wraps_and_keeps_controls_accessible()->void:
	await _open(500)
	assert_bool(dashboard._columns.vertical).is_true()
	assert_int(dashboard._metrics.columns).is_equal(2)
	assert_float(dashboard.get_combined_minimum_size().x).is_less_equal(500)
	assert_int(dashboard.find_children("*","OptionButton",true,false).size()).is_equal(0)

func test_daily_refresh_keeps_selected_month_and_navigation_focus()->void:
	await _open(1000)
	dashboard._select_month(0);dashboard._next.grab_focus()
	var block:=_fixture();block.history.append({"day":60,"life_expectancy":27.0})
	block.research.totals[0].amount=0.006
	dashboard.update_block(block)
	assert_int(dashboard.selected_day).is_equal(0)
	assert_bool(dashboard._next.has_focus()).is_true()
	assert_int(dashboard._chart.selected_index).is_equal(0)

func test_care_buttons_invoke_existing_command_with_chosen_share()->void:
	await _open(1000)
	var calls:Array=[];var block:=_fixture();block.on_care=func(share:float):calls.append(share)
	dashboard.update_block(block);dashboard.topic=2;dashboard._refresh_detail(true)
	for button:Button in dashboard._detail.find_children("*","Button",true,false):
		if button.text=="50%":button.pressed.emit()
	assert_array(calls).contains_exactly([0.5])

func test_chart_click_selects_recorded_month()->void:
	var chart:Control=auto_free(Chart.new());add_child(chart)
	chart.set_points(_fixture().history);chart.plot_rect=Rect2(40,10,400,200)
	var selections:Array=[];chart.point_selected.connect(func(index:int):selections.append(index))
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=Vector2(430,30)
	chart._gui_input(event)
	assert_array(selections).contains_exactly([1])

func test_discovery_month_is_not_claimed_as_isolated_lifespan_gain()->void:
	var words:=Discoveries.record_for("clean_water",[{"id":"clean_water","day":12}],_fixture().history)
	assert_str(words).contains("all causes together").contains("not an isolated gain")
	assert_str(Discoveries.record_for("missing",[],[])).contains("No discovery date")
	assert_str(Discoveries.record_for("new",[{"id":"new","day":75}],_fixture().history)).contains("not been recorded yet")

func test_discovery_sources_follow_actual_adoption_without_changing_ledger()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(771204);GameState.initialize_population_model()
	DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	var discovery:Node=WorldSimulation.discovery
	GameState.known_discoveries=["clean_water","wound_cleaning"]
	GameState.discovery_adoption={"clean_water":0.25,"wound_cleaning":0.5}
	discovery.refresh_operating_effects()
	var before:=[GameState.discovery_adoption.duplicate(true),GameState.knowledge_effects.duplicate(true),GameState.known_discoveries.duplicate(),GameState.health_history.duplicate(true)]
	var research:=Discoveries.read()
	var rows:Array=research.recent
	assert_int(rows.size()).is_equal(2)
	var water:Dictionary=rows[1]
	assert_str(water.id).is_equal("clean_water")
	assert_float(float(water.adoption)).is_equal(0.25)
	assert_bool((water.effects as Array).is_empty()).is_false()
	assert_bool((water.protections as Array).is_empty()).is_false()
	assert_array([GameState.discovery_adoption,GameState.knowledge_effects,GameState.known_discoveries,GameState.health_history]).is_equal(before)

func test_provider_uses_one_dashboard_and_no_duplicate_brief()->void:
	var provider:=Provider.new(null,null)
	var page:Dictionary=provider.tab(0)
	assert_bool(bool(provider.meta().spatial_view)).is_true()
	assert_bool(page.has("brief")).is_false()
	assert_int((page.blocks as Array).size()).is_equal(1)
	assert_str(String(page.blocks[0].type)).is_equal("health_dashboard")

func test_selecting_discovery_highlights_its_recording_interval()->void:
	await _open(1000)
	dashboard._select_month(0)
	dashboard._open_discovery(_fixture().research.recent[0])
	assert_int(dashboard.selected_day).is_equal(30)
	assert_int(dashboard._chart.selected_index).is_equal(1)

func test_real_opening_readings_fit_the_wide_dashboard()->void:
	var provider:=Provider.new(null,null)
	dashboard=Dashboard.new();add_child(dashboard);dashboard.size.x=1000
	dashboard.setup(provider.tab(0).blocks[0])
	for frame in 6:await get_tree().process_frame
	assert_float(dashboard.get_combined_minimum_size().y).is_less(590)
	assert_float(dashboard.get_combined_minimum_size().x).is_less_equal(1000)

func test_aggregate_totals_include_every_known_discovery_and_keep_only_latest_three()->void:
	var ids:Array[String]=["clean_water","wound_cleaning","birth_attendants","herbal_classification","shared_childcare"]
	for id:String in ids:
		GameState.known_discoveries.append(id);GameState.discovery_adoption[id]=0.5
	GameState.discovery_log=[{"id":"clean_water","day":120},{"id":"wound_cleaning","day":100},{"id":"birth_attendants","day":80},{"id":"herbal_classification","day":60},{"id":"shared_childcare","day":40}]
	DiscoverySystem.refresh_operating_effects()
	var model=DiscoverySystem.society_model
	var sources:Dictionary=model.effect_sources(model.practice_basis(),Discoveries.CHANNELS.keys(),null,false)
	var report:=Discoveries.read()
	assert_int(report.recent.size()).is_equal(3)
	assert_str(report.recent[0].id).is_equal("clean_water")
	assert_str(report.recent[2].id).is_equal("birth_attendants")
	for total:Dictionary in report.totals:
		var expected:=0.0;var unlocked:=0.0;var count:=0
		for value in sources.get(total.id,{}).values():expected+=float(value)
		for id:String in GameState.known_discoveries:
			var definition:Dictionary=DiscoverySystem.discovery_definition(id)
			if not definition.get("effects",{}).has(total.id):continue
			count+=1
			var scale:float=model.practice_scale(String(definition.get("dynamic","")),model.line_focus,model.neglect_for(model.line_focus))
			unlocked+=model.scaled_effect(total.id,float(definition.effects[total.id]),scale)
		assert_float(float(total.amount)).is_equal_approx(expected,0.000001)
		assert_float(float(total.unlocked)).is_equal_approx(unlocked,0.000001)
		assert_int(int(total.count)).is_equal(count)
	var water:Array=report.totals.filter(func(row:Dictionary)->bool:return row.id=="water_safety")
	assert_int(water.size()).is_equal(1)
	assert_float(float(water[0].unlocked)).is_greater(0.0)

func test_all_categories_and_last_three_fit_without_dropdowns()->void:
	await _open(1100)
	var block:=_fixture();block.research.totals=[]
	for id:String in Discoveries.CHANNELS:
		block.research.totals.append({"id":id,"label":Discoveries.CHANNELS[id][0],"amount":-0.3,"unlocked":-0.5,"count":35,"tip":"Known research"})
	var third:Dictionary=block.research.recent[0].duplicate(true);third.id="third"
	block.research.recent.append(third)
	dashboard.update_block(block)
	for frame in 8:await get_tree().process_frame
	assert_int(dashboard.find_children("*","OptionButton",true,false).size()).is_equal(0)
	assert_int(dashboard.find_children("RecentDiscovery*","Button",true,false).size()).is_equal(3)
	assert_float(dashboard.get_combined_minimum_size().y).is_less(590)
	var bar=dashboard._detail_scroll.get_v_scroll_bar()
	print("HEALTH_TOTALS_LAYOUT: content=",dashboard._detail.size," viewport=",dashboard._detail_scroll.size," dashboard=",dashboard.get_combined_minimum_size())
	assert_float(bar.max_value-bar.page).is_less_equal(1.0)
