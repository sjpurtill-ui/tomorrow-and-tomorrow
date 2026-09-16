extends GdUnitTestSuite

const Works=preload("res://scripts/water_waste_works.gd")
const State=preload("res://scripts/water_waste_works_state.gd")

func before_test()->void:
	WorldSimulation.clear();GameState.reset_for_new_world(7510);DiscoverySystem.reset_for_new_world();DiscoverySystem.initialize()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	GameState.ensure_population_total(100);GameState.settlement_site_committed=true;GameState.convoy_traveling=false
	GameState.population_allocations.Construction=20;GameState.population_allocations.Logistics=10
	GameState.resource_stockpiles={"Stone":40.0,"Timber":20.0,"Clay":20.0,"Joined Timber Components":4.0,"Sealed Clay Vessels":4.0,"Freshwater":0.0}

func after_test()->void:
	WorldSimulation.clear();GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func know(ids:Array[String])->void:
	for id:String in ids:
		if id not in GameState.known_discoveries:GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id]=1.0

func finish(kind:String,context:Dictionary={})->void:
	assert_bool(Works.begin(kind,context).get("ok",false)).is_true()
	Works.construction_work(100.0,1)

func rainy_context()->Dictionary:
	return {"origin":Vector3.ZERO,"environment_profile":{"precipitation":1.0}}

func well_context()->Dictionary:
	return {"origin":Vector3.ZERO,"water_conveyance_sources":[{"id":"well:1","kind":"Lined well","revealed":true,"position":Vector3.ZERO}]}

func test_discoveries_without_built_works_grant_no_effects()->void:
	know(["latrine_siting","protected_wellheads","rainwater_cisterns","water_settling_basins"])
	DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("sanitation")).is_equal(0.0)
	assert_float(DiscoverySystem.effect("water_access")).is_equal(0.0)
	assert_float(DiscoverySystem.effect("water_safety")).is_equal(0.0)

func test_latrine_consumes_materials_and_needs_construction_and_staff()->void:
	know(["latrine_siting"])
	assert_bool(Works.begin("latrine").get("ok",false)).is_true()
	assert_float(float(GameState.resource_stockpiles.Stone)).is_equal(36.0)
	assert_float(float(GameState.resource_stockpiles.Timber)).is_equal(18.0)
	assert_float(Works.factor("latrine_siting")).is_equal(0.0)
	Works.construction_work(17.0,1);Works.advance({},1,100.0);DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("sanitation")).is_equal(0.0)
	Works.construction_work(1.0,2);Works.advance({},2,100.0);DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("sanitation")).is_greater(0.0)
	GameState.population_allocations.Construction=0;GameState.population_allocations.Logistics=0
	Works.advance({},3,100.0);DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("sanitation")).is_equal(0.0)

func test_wellhead_requires_an_existing_well_and_never_creates_supply()->void:
	know(["protected_wellheads"])
	assert_bool(Works.quote("wellhead",{}).has("error")).is_true()
	finish("wellhead",well_context())
	var before:=float(GameState.resource_stockpiles.Freshwater)
	Works.advance(well_context(),1,100.0);DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("water_safety")).is_greater(0.0)
	assert_float(float(GameState.resource_stockpiles.Freshwater)).is_equal(before)
	Works.advance({},2,100.0);DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("water_safety")).is_equal(0.0)

func test_cistern_uses_one_real_lining_and_rain_adds_finite_unsafe_water()->void:
	know(["rainwater_cisterns"])
	finish("cistern",rainy_context())
	assert_float(float(GameState.resource_stockpiles["Sealed Clay Vessels"])).is_equal(2.0)
	GameState.elapsed_days=1;WorldSimulation.resources._process_water_flow(rainy_context())
	assert_float(float(GameState.water_metrics.rain_collected_today)).is_between(15.9,16.0)
	assert_float(float(GameState.water_metrics.cistern_capacity)).is_greater(249.0)
	assert_float(DiscoverySystem.effect("water_access")).is_greater(0.0)
	assert_float(DiscoverySystem.effect("water_safety")).is_equal(0.0)
	Works.advance({"environment_profile":{"precipitation":0.0}},2,100.0);DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("water_access")).is_equal(0.0)

func test_settling_basin_is_staff_and_volume_bounded_not_sterilization()->void:
	know(["water_settling_basins"]);finish("settling_basin")
	Works.advance({},1,100.0);DiscoverySystem.refresh_operating_effects()
	assert_float(Works.factor("water_settling_basins")).is_between(.5,.56)
	assert_float(DiscoverySystem.effect("water_safety")).is_between(.01,.012)
	GameState.population_allocations.Logistics=0;Works.advance({},2,100.0);DiscoverySystem.refresh_operating_effects()
	assert_float(DiscoverySystem.effect("water_safety")).is_equal(0.0)

func test_state_validation_rejects_impossible_records()->void:
	know(["latrine_siting"]);finish("latrine")
	assert_bool(State.valid(GameState.water_waste_works)).is_true()
	var broken:Dictionary=GameState.water_waste_works.duplicate(true);broken.works[0].condition=INF
	assert_bool(State.valid(broken)).is_false()
	assert_bool(State.valid_state({"player_settlements":[]})).is_true()

func test_full_save_restores_a_paid_unfinished_cistern()->void:
	GameState.reset_for_new_world(7510);CivilizationSystem.reset_for_new_world();WorldSimulation.create_actor("water_works",7510)
	WorldSimulation.scoped("water_works",func()->void:
		var state=WorldSimulation.state;state.ensure_population_total(100);state.settlement_site_committed=true;state.convoy_traveling=false
		state.resource_stockpiles={"Stone":40.0,"Sealed Clay Vessels":4.0,"Freshwater":0.0}
		state.known_discoveries.append("rainwater_cisterns");state.discovery_adoption["rainwater_cisterns"]=1.0
		assert_bool(Works.begin("cistern",rainy_context()).get("ok",false)).is_true();Works.construction_work(12.0,1))
	var slot:="water_waste_works_%d" % OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.scoped("water_works",func()->void:WorldSimulation.state.water_waste_works=State.empty();WorldSimulation.state.resource_stockpiles["Sealed Clay Vessels"]=99.0)
	var restored:=SaveSystem.load_game(slot);DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	WorldSimulation.scoped("water_works",func()->void:
		assert_float(float(Works.work_for("cistern").work_done)).is_equal(12.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Sealed Clay Vessels"])).is_equal(2.0))
