extends GdUnitTestSuite
const B=preload("res://scripts/building_material_operations.gd")
const K=preload("res://scripts/earthen_building_knowledge.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("earth",1341)
func after_test()->void:WorldSimulation.clear()
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func weather(temperature:float=20,rain:float=.2)->void:
	var state=WorldSimulation.state
	if state.player_settlements.is_empty():state.player_settlements.append({"id":"earth_city","name":"Earth City","position":Vector2.ZERO,"primary":true})
	state.player_settlements[0].environment_profile={"mean_temperature_c":temperature,"seasonality_c":0.0,"precipitation":rain}
func profile(id:String)->Dictionary:
	learn(String(B.PROFILES[id].gate))
	for option:Dictionary in B.options():
		if String(option.building_materials.id)==id:return option.building_materials.duplicate(true)
	return {}
func test_two_building_methods_have_paid_materials_and_valid_contracts()->void:
	WorldSimulation.scoped("earth",func()->void:
		assert_int(K.entries().size()).is_equal(2)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		for id:String in ["adobe_units","wattle_daub"]:assert_bool(B.valid(profile(id))).is_true())
func test_adobe_dries_before_wall_work_and_cannot_skip_wet_or_cold_time()->void:
	WorldSimulation.scoped("earth",func()->void:
		weather();var plot:={"construction_progress":0.0,"building_materials":profile("adobe_units"),"status":"under_construction"}
		assert_float(B.progress(plot,0,0)).is_equal(0.0);assert_bool(plot.has("curing_started_day")).is_false()
		assert_float(B.progress(plot,10,0)).is_equal(0.0)
		weather(20,.9);assert_float(B.progress(plot,10,28)).is_equal(0.0)
		assert_float(float(plot.curing_work_days)).is_equal(0.0)
		weather(0,.2);assert_float(B.progress(plot,10,56)).is_equal(0.0)
		weather();assert_float(B.progress(plot,.5,70)).is_equal(0.0)
		assert_float(float(plot.curing_work_days)).is_equal(14.0)
		B.progress(plot,10,70);assert_float(float(plot.curing_work_days)).is_equal(14.0)
		assert_float(B.progress(plot,.5,84)).is_equal(.4)
		assert_int(int(plot.curing_completed_day)).is_equal(84)
		plot.construction_progress=.4
		assert_float(B.progress(plot,.75,84)).is_equal(1.0)
		assert_bool(B.valid_plot(plot)).is_true())
func test_wattle_daub_requires_application_then_drying_before_occupancy()->void:
	WorldSimulation.scoped("earth",func()->void:
		weather();var plot:={"construction_progress":0.0,"building_materials":profile("wattle_daub"),"status":"under_construction"}
		assert_float(B.progress(plot,.5,0)).is_equal(.5);assert_bool(plot.has("curing_started_day")).is_false()
		plot.construction_progress=.5;assert_float(B.progress(plot,.5,1)).is_equal(.99)
		plot.construction_progress=.99;weather(20,.9)
		assert_float(B.progress(plot,1,15)).is_equal(.99)
		weather();assert_float(B.progress(plot,1,29)).is_equal(1.0)
		assert_float(float(plot.curing_work_days)).is_equal(14.0)
		assert_bool(B.describe(plot).contains("Applied daub")).is_true())
func test_secondary_drying_and_repairs_use_the_selected_city_only()->void:
	WorldSimulation.scoped("earth",func()->void:
		weather();var state=WorldSimulation.state
		state.player_settlements.append({"id":"wet_city","name":"Wet City","position":Vector2(10,0),"primary":false,"population_share":.25,"environment_profile":{"mean_temperature_c":20.0,"seasonality_c":0.0,"precipitation":.9}})
		var primary:={"construction_progress":0.0,"building_materials":profile("adobe_units")}
		var secondary:=primary.duplicate(true)
		state.resource_stockpiles["Adobe Mix"]=1.0
		B.progress(primary,1,0);B.progress(primary,1,28)
		WorldSimulation.settlements.with_city_resources("wet_city",func()->void:
			B.progress(secondary,1,0);B.progress(secondary,1,28)
			assert_float(float(secondary.curing_work_days)).is_equal(0.0)
			assert_float(B.supplied_maintenance(secondary,.1)).is_equal(0.0))
		assert_float(float(primary.curing_work_days)).is_equal(28.0)
		assert_float(float(state.resource_stockpiles["Adobe Mix"])).is_equal(1.0))
func test_actual_housing_growth_pays_and_waits_for_dry_units()->void:
	WorldSimulation.scoped("earth",func()->void:
		var state=WorldSimulation.state;var model=WorldSimulation.settlements
		state.ensure_population_total(80);state.settlement_completed.assign(["Hearth Circle"])
		state.settlement_site_committed=true;state.convoy_traveling=false;state.elapsed_days=19;model.ensure_founded()
		state.ensure_population_total(240);state.population_allocations.Construction=20;state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
		learn("adobe_wall_construction");weather(20,.9)
		state.resource_stockpiles={"Adobe Mix":4.0,"Stone":1.0,"Timber":1.0,"Thatch Panels":1.0}
		var events:Array[Dictionary]=[]
		assert_bool(model._attempt_household_growth(90,events,{},0)).is_true()
		var plot:Dictionary=state.settlement_plots.back()
		assert_str(plot.building_materials.id).is_equal("adobe_units")
		assert_float(float(state.resource_stockpiles["Adobe Mix"])).is_equal(0.0)
		state.elapsed_days=120;model.process_month();state.elapsed_days=150;model.process_month()
		assert_str(plot.status).is_equal("under_construction")
		weather();state.elapsed_days=180;model.process_month()
		assert_str(plot.status).is_equal("active")
		assert_bool(B.valid_plot(plot)).is_true())
func test_rain_exposure_and_actual_repair_consumption_remain_visible()->void:
	WorldSimulation.scoped("earth",func()->void:
		weather(20,0);var plot:={"building_materials":profile("wattle_daub")}
		var dry:=B.decay_factor(plot);weather(20,1)
		assert_float(B.decay_factor(plot)).is_greater(dry)
		WorldSimulation.state.resource_stockpiles["Earthen Daub"]=.1
		assert_float(B.supplied_maintenance(plot,.1)).is_equal_approx(.05,.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Earthen Daub"])).is_equal(0.0)
		assert_float(B.decay_factor({})).is_equal(1.0))
func test_whole_save_preserves_partly_dried_adobe_before_assembly()->void:
	GameState.reset_for_new_world(1341);CivilizationSystem.reset_for_new_world()
	WorldSimulation.create_actor("earth",1341)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("earth",func()->void:
		var state=WorldSimulation.state;state.settlement_completed.assign(["Hearth Circle"]);state.elapsed_days=30
		WorldSimulation.settlements.ensure_founded();weather()
		var plot:Dictionary=state.settlement_plots[0];plot.building_materials=profile("adobe_units");plot.construction_progress=0.0
		B.progress(plot,1,30);B.progress(plot,1,44);state.elapsed_days=44
		assert_float(float(plot.curing_work_days)).is_equal(14.0))
	var slot:="earthen_building_%d" % OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.clear()
	var loaded:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	WorldSimulation.scoped("earth",func()->void:
		var plot:Dictionary=WorldSimulation.state.settlement_plots[0]
		assert_float(float(plot.curing_work_days)).is_equal(14.0)
		assert_float(B.progress(plot,1.25,44)).is_equal(0.0)
		assert_float(B.progress(plot,1.25,58)).is_equal(1.0)
		assert_bool(B.valid_plot(plot)).is_true())
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_invalid_completed_drying_cannot_bypass_saved_elapsed_stage()->void:
	WorldSimulation.scoped("earth",func()->void:
		var plot:={"building_materials":profile("adobe_units"),"curing_started_day":10,"curing_last_day":20,"curing_work_days":1.0,"curing_completed_day":20}
		assert_bool(B.valid_plot(plot)).is_false()
		plot.curing_work_days=28.0;plot.curing_last_day=38;plot.curing_completed_day=38
		assert_bool(B.valid_plot(plot)).is_true())
