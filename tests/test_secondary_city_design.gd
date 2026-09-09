extends GdUnitTestSuite
const EARLY=preload("res://scripts/early_settlement_visual.gd")
class FlatTerrain extends "res://scripts/local_terrain.gd":
	func _settlement_model()->Node:return SettlementModel
	func _settlement_stage_land_at(_point:Vector2)->bool:return true
	func _close_surface_height_at(_x:float,_z:float)->float:return .1

class HudFixture extends "res://scripts/hud/command_rail_hud.gd":
	func _layout()->void:pass

func before_test()->void:
	GameState.reset_for_new_world(424242)
	SettlementModel.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.ensure_population_total(1000)
	GameState.settlement_completed=["Hearth Circle"]
	GameState.settlement_name="Home"
	SettlementModel.ensure_founded()
	GameState.player_settlements.append({"id":"second","name":"Rivermeet","position":Vector2(10,10),"primary":false,"population_share":.2,"founded_day":20})

func test_secondary_gets_independent_persistent_foundation_without_changing_home()->void:
	var home:=GameState.settlement_plots.duplicate(true)
	var routes:=GameState.settlement_routes.duplicate(true)
	var ledger:=GameState.building_ledger.duplicate(true)
	var city:=SettlementModel.settlement_record("second")
	SettlementModel._ensure_city_resources(city)
	var local:Dictionary=city.local_resources
	var plots:Array[Dictionary]=[];plots.assign(local.settlement_plots)
	var paths:Array[Dictionary]=[];paths.assign(local.settlement_routes)
	assert_int(plots.size()).is_greater(0)
	assert_int(plots.size()).is_less_equal(101)
	assert_int(paths.size()).is_equal(plots.size())
	var residents:=0
	for plot in plots:residents+=int(plot.resident_count);assert_int(int(plot.created_day)).is_equal(20)
	assert_int(residents).is_equal(200)
	var plan:=EARLY.layout(plots,paths,func(_p:Vector2)->bool:return true)
	assert_int(plan.buildings.size()).is_greater(0)
	var saved:=local.duplicate(true)
	GameState.population_exact=2000;GameState.population_total=2000;GameState.elapsed_days=500
	SettlementModel._ensure_city_resources(city)
	assert_dict(city.local_resources).is_equal(saved)
	assert_array(GameState.settlement_plots).is_equal(home)
	assert_array(GameState.settlement_routes).is_equal(routes)
	assert_array(GameState.building_ledger).is_equal(ledger)

func test_new_city_classification_has_no_age_gate()->void:
	var city:=SettlementModel.settlement_record("second")
	assert_str(SettlementModel._settlement_classification(city,40)).is_equal("hamlet")
	assert_str(SettlementModel._settlement_classification(city,3000)).is_equal("town")

func test_actual_secondary_renderer_uses_design_assets_and_ground()->void:
	var terrain:Node3D=auto_free(FlatTerrain.new())
	var parent:Node3D=auto_free(Node3D.new())
	assert_bool(terrain._create_secondary_city_design({"id":"second"},parent)).is_true()
	assert_int(parent.get_child_count()).is_equal(1)
	var batches:=parent.find_children("*","MultiMeshInstance3D",true,false)
	assert_int(batches.size()).is_greater(0)
	var count:=0
	for batch in batches:count+=batch.multimesh.instance_count
	assert_int(count).is_greater(0)
	assert_int(count).is_less_equal(512)
	assert_int(parent.find_children("*","MeshInstance3D",true,false).size()).is_greater(0)

func test_existing_recorded_fabric_is_never_replaced()->void:
	var city:=SettlementModel.settlement_record("second")
	SettlementModel._ensure_city_resources(city)
	city.local_resources.settlement_plots[0].form="earthen_household"
	var saved:Dictionary=city.local_resources.duplicate(true)
	SettlementModel._ensure_city_resources(city)
	assert_dict(city.local_resources).is_equal(saved)

func test_hud_retains_overall_and_selected_counts()->void:
	var terrain:Node3D=auto_free(FlatTerrain.new())
	var hud:Control=auto_free(HudFixture.new())
	hud.terrain=terrain
	hud._build_time_pill();hud._build_kpi_strip()
	GameState.selected_player_settlement_id="second"
	hud._refresh_kpis()
	assert_str(hud.kpi_chips.population.value.text).is_equal("1000 overall")
	assert_str(hud.kpi_chips.population.delta.text).is_equal("200 · Rivermeet")
	assert_int(GameState.population_total).is_equal(1000)
	GameState.selected_player_settlement_id=String(GameState.player_settlements[0].id)
	hud._refresh_kpis()
	assert_str(hud.kpi_chips.population.value.text).is_equal("1000 overall")
	assert_str(hud.kpi_chips.population.delta.text).is_equal("800 · Home")
	assert_int(GameState.population_total).is_equal(1000)

func test_local_demography_changes_only_its_city_and_national_total()->void:
	var home_before:=SettlementModel.primary_population_exact()
	var city:=SettlementModel.settlement_record("second")
	SettlementModel.with_city_resources("second",func()->void:
		SettlementModel.with_local_population(func()->void:GameState.register_population_deaths(7,"Illness"),true))
	assert_int(GameState.population_total).is_equal(993)
	assert_float(SettlementModel._settlement_population(city)).is_equal_approx(193,.00001)
	assert_float(SettlementModel.primary_population_exact()).is_equal_approx(home_before,.00001)
	assert_int(GameState.lifetime_deaths).is_equal(7)
	var selected:=GameState.selected_player_settlement_id
	GameState.selected_player_settlement_id="second"
	SettlementModel.with_local_population(func()->void:GameState.register_population_deaths(3,"Illness"),true)
	assert_int(GameState.population_total).is_equal(990)
	assert_float(SettlementModel._settlement_population(city)).is_equal_approx(193,.00001)
	assert_float(SettlementModel.primary_population_exact()).is_equal_approx(home_before-3,.00001)
	GameState.selected_player_settlement_id=selected

func test_local_monthly_work_updates_own_plots_and_ledger()->void:
	var city:=SettlementModel.settlement_record("second")
	SettlementModel._ensure_city_resources(city)
	var home:=GameState.settlement_plots.duplicate(true)
	var next_id:=GameState.next_settlement_plot_id
	city.local_resources.settlement_completed.append("Lean-to Shelters")
	GameState.elapsed_days=30
	SettlementModel.with_city_resources("second",func()->void:
		SettlementModel.with_local_population(func()->void:SettlementModel.process_month({})))
	var rooted:=0
	for plot in city.local_resources.settlement_plots:
		if plot.form=="lean_to_household_cluster":rooted+=1
	assert_int(rooted).is_greater(0)
	assert_array(GameState.settlement_plots).is_equal(home)
	assert_int(GameState.next_settlement_plot_id).is_equal(next_id)
	var records:=GameState.building_ledger_summary("second")
	assert_int(records.records.size()).is_greater(0)
	assert_int(city.local_resources.last_morphology_day).is_equal(30)

func test_all_map_labels_share_name_and_population_format()->void:
	var terrain:Node3D=auto_free(FlatTerrain.new())
	assert_str(terrain._city_map_label("Rivermeet",200)).is_equal("Rivermeet  •  200")
	assert_str(terrain._city_map_label("Elsewhere",-1,{"low":100,"high":300})).is_equal("Elsewhere  •  est. 100–300")
	assert_str(terrain._city_map_label("Unidentified settlement")).contains("Population unknown")
	assert_str(terrain._settlement_map_label_text(.1)).is_equal(terrain._settlement_map_label_text(10000))

func test_city_ticks_once_with_independent_health_and_survives_save_load()->void:
	var city:=SettlementModel.settlement_record("second")
	SettlementModel._ensure_city_resources(city)
	city.local_resources.population_health=.31
	city.local_resources.resource_stockpiles["Timber"]=123.0
	var home_health:=GameState.population_health
	GameState.elapsed_days=31
	SettlementModel.process_city_resources("second",{"settled":true,"origin":Vector3(10,0,10)})
	assert_float(GameState.population_health).is_equal(home_health)
	assert_int(int(city.get("last_economy_day",-1))).is_equal(31)
	assert_int(int(city.local_resources.last_morphology_day)).is_equal(30)
	var once:Dictionary=city.duplicate(true)
	SettlementModel.process_city_resources("second",{"settled":true,"origin":Vector3(10,0,10)})
	assert_dict(city).is_equal(once)
	var total:=GameState.population_exact
	assert_bool(bool(SaveSystem.save_game("city_parity_test").get("ok",false))).is_true()
	GameState.player_settlements.clear()
	assert_bool(bool(SaveSystem.load_game("city_parity_test").get("ok",false))).is_true()
	assert_float(GameState.population_exact).is_equal_approx(total,.0001)
	var loaded:=SettlementModel.settlement_record("second")
	assert_roundtrip(loaded,once)
	DirAccess.remove_absolute(SaveSystem.slot_path("city_parity_test"))

func assert_roundtrip(actual:Variant,expected:Variant)->void:
	if expected is Dictionary:
		assert_int(actual.size()).is_equal(expected.size())
		for key in expected:
			assert_bool(actual.has(key)).is_true()
			assert_roundtrip(actual.get(key),expected[key])
	elif expected is Array:
		assert_int(actual.size()).is_equal(expected.size())
		for index in expected.size():assert_roundtrip(actual[index],expected[index])
	elif expected is float or expected is int:
		assert_float(float(actual)).is_equal_approx(float(expected),maxf(.000001,absf(float(expected))*.0000001))
	else:assert_that(actual).is_equal(expected)
