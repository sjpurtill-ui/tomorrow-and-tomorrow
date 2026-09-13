extends GdUnitTestSuite
const Water=preload("res://scripts/water_conveyance.gd")
const State=preload("res://scripts/water_conveyance_state.gd")
class IntakeTerrain extends "res://scripts/local_terrain.gd":
	func _height_at(_x:float,z:float)->float:return 1.0-z/3.0
	func _surface_water_sources(origin:Vector3,_limit:float=INF)->Array[Dictionary]:
		return [{"kind":"River","position":Vector3(0,_height_at(0,origin.z),origin.z),"distance_km":absf(origin.x)}]
func before_test()->void:
	WorldSimulation.clear();WorldSimulation.create_actor("water_builders",611)
func after_test()->void:WorldSimulation.clear()
func source()->Dictionary:return {"id":"river_1","position":Vector3(0,2,0),"revealed":true}
func height(x:float,_z:float)->float:return 2.0-x
func prepare()->void:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.settlement_founded_at=Vector3(1,1,0)
	for id:String in ["joinery","gravity_conduit_grade_control"]:
		state.known_discoveries.append(id);state.discovery_adoption[id]=1.0
	state.resource_stockpiles={"Wooden Conduits":10.0,"Clay":2.0,"Freshwater":0.0}
func install()->Dictionary:
	return Water.install(source(),Vector3(1,1,0),height,"timber")
func context()->Dictionary:return {"origin":Vector3(1,1,0),"water_conveyance_sources":[source()]}

func test_imported_pipe_is_paid_once_and_requires_finite_construction()->void:
	WorldSimulation.scoped("water_builders",func()->void:
		prepare()
		assert_bool(install().get("ok",false)).is_true()
		assert_float(float(WorldSimulation.state.resource_stockpiles["Wooden Conduits"])).is_equal(0.0)
		assert_bool("wooden_log_conduits" in WorldSimulation.state.known_discoveries).is_false()
		assert_float(Water.delivery(context(),1,100)).is_equal(0.0)
		assert_bool(install().has("error")).is_true()
		assert_float(Water.construction_work(20,1)).is_equal(20.0)
		assert_float(Water.construction_work(20,1)).is_equal(0.0)
		assert_float(Water.delivery(context(),2,100)).is_equal(0.0)
		assert_float(Water.construction_work(100,2)).is_equal(20.0)
		assert_float(Water.delivery(context(),3,100)).is_greater(0.0)
		assert_float(Water.delivery(context(),3,100)).is_equal(0.0)
	)

func test_missing_intake_and_relocation_disable_installed_delivery()->void:
	WorldSimulation.scoped("water_builders",func()->void:
		prepare();install();Water.construction_work(100,1)
		assert_float(Water.delivery({"origin":Vector3(1,1,0)},2,100)).is_equal(0.0)
		var moved:=context();moved.origin=Vector3(2,0,0)
		assert_float(Water.delivery(moved,3,100)).is_equal(0.0)
		assert_float(Water.delivery(context(),4,100)).is_greater(0.0)
	)

func test_actual_resource_flow_accounts_for_delivery_in_the_single_stock()->void:
	WorldSimulation.scoped("water_builders",func()->void:
		prepare();install();Water.construction_work(100,1)
		WorldSimulation.state.ensure_population_total(100)
		WorldSimulation.state.elapsed_days=2
		WorldSimulation.resources._process_water_flow(context())
		var metrics:Dictionary=WorldSimulation.state.water_metrics
		assert_float(float(metrics.conveyed_today)).is_greater(0.0)
		assert_float(float(metrics.collected_today)).is_equal_approx(float(metrics.consumed_today)+float(metrics.stored),.000001)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Freshwater)).is_equal(float(metrics.stored))
	)

func test_repairs_are_material_bounded_and_do_not_spend_another_actor_stock()->void:
	WorldSimulation.create_actor("neighbor",612)
	WorldSimulation.scoped("neighbor",func()->void:WorldSimulation.state.resource_stockpiles["Wooden Conduits"]=9.0)
	WorldSimulation.scoped("water_builders",func()->void:
		prepare();install();Water.construction_work(100,1)
		Water.data().lines[0].condition=.5
		assert_float(Water.maintain(1,100)).is_equal(0.0)
		WorldSimulation.state.resource_stockpiles["Wooden Conduits"]=.2
		assert_float(Water.maintain(1,100)).is_equal_approx(10.0,.000001)
		assert_float(float(Water.data().lines[0].condition)).is_equal_approx(.6,.000001)
		assert_bool(State.valid(Water.data())).is_true()
		var broken:Dictionary=Water.data().duplicate(true);broken.lines[0].condition=INF
		assert_bool(State.valid(broken)).is_false()
		assert_bool(State.valid_state({"player_settlements":[{"local_resources":{"water_conveyance":broken}}]})).is_false()
		assert_bool(State.valid_state({})).is_true()
	)
	WorldSimulation.scoped("neighbor",func()->void:assert_float(float(WorldSimulation.state.resource_stockpiles["Wooden Conduits"])).is_equal(9.0))

func test_full_save_restores_unfinished_work_and_paid_inventory()->void:
	GameState.reset_for_new_world(611);CivilizationSystem.reset_for_new_world()
	WorldSimulation.create_actor("water_builders",611)
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.scoped("water_builders",func()->void:
		prepare();install();Water.construction_work(12,1))
	var slot:="water_conveyance_%d" % OS.get_process_id()
	assert_bool(SaveSystem.save_game(slot).get("ok",false)).is_true()
	WorldSimulation.scoped("water_builders",func()->void:
		Water.data().lines.clear();WorldSimulation.state.resource_stockpiles["Wooden Conduits"]=99.0)
	var restored:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(restored.get("ok",false)).override_failure_message(str(restored)).is_true()
	WorldSimulation.scoped("water_builders",func()->void:
		assert_float(float(Water.data().lines[0].work_done)).is_equal(12.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Wooden Conduits"])).is_equal(0.0)
		assert_float(Water.construction_work(100,2)).is_equal(28.0)
		assert_float(Water.delivery(context(),3,100)).is_greater(0.0))
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)

func test_secondary_city_conserves_its_own_water_and_local_drinking_demand()->void:
	WorldSimulation.scoped("water_builders",func()->void:
		var state=WorldSimulation.state;var model=WorldSimulation.settlements
		state.ensure_population_total(1000);state.settlement_completed.assign(["Hearth Circle"])
		model.ensure_founded()
		state.player_settlements.append({"id":"second","name":"Rivermeet","position":Vector2(1,0),"primary":false,"population_share":.2,"founded_day":20})
		state.resource_stockpiles["Freshwater"]=700.0
		model.with_city_resources("second",func()->void:
			prepare();install();Water.construction_work(100,1)
			state.elapsed_days=2
			WorldSimulation.resources.process_day(context())
			assert_float(float(state.water_metrics.required_today)).is_equal(200.0)
			assert_float(float(state.water_metrics.conveyed_today)).is_greater(0.0)
			assert_int(Water.data().lines.size()).is_equal(1))
		assert_float(float(state.resource_stockpiles.Freshwater)).is_equal(700.0)
		assert_int(Water.data().lines.size()).is_equal(0)
		var city:Dictionary=model.settlement_record("second")
		assert_int(city.local_resources.water_conveyance.lines.size()).is_equal(1)
		assert_bool(State.valid_state({"player_settlements":state.player_settlements})).is_true())

func test_clay_workshop_chain_consumes_unfired_sections_and_fuel()->void:
	WorldSimulation.scoped("water_builders",func()->void:
		var industry=preload("res://scripts/civilian_industry.gd")
		var production=preload("res://scripts/persistent_production.gd")
		var state=WorldSimulation.state
		state.resource_stockpiles={"Prepared Clay":10.0,"Freshwater":10.0,"Timber":20.0,"Stone":20.0,"Clay":20.0}
		for item:String in ["unfired_clay_conduits","fired_clay_conduits"]:
			var spec:Dictionary=industry.product(item)
			state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
			var quantity:=2 if item=="unfired_clay_conduits" else 1
			assert_bool(WorldSimulation.military.start_production_line(item,quantity).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			production.advance(WorldSimulation.military,job,float(spec.days)*quantity)
			assert_int(int(job.completed)).is_equal(quantity)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
		assert_float(float(state.resource_stockpiles["Fired Clay Conduits"])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Unfired Clay Conduits"])).is_equal(.75)
		assert_float(float(state.resource_stockpiles["Prepared Clay"])).is_equal(6.0))

func test_player_control_uses_the_same_paid_installation_action()->void:
	WorldSimulation.scoped("water_builders",func()->void:
		prepare()
		var panel:=VBoxContainer.new();auto_free(panel)
		var ctx:=context();ctx.terrain_height_at=height
		preload("res://scripts/hud/water_conveyance_controls.gd").build(panel,ctx)
		var enabled:Array[Button]=[]
		for child in panel.get_children():
			if child is Button and not child.disabled:enabled.append(child)
		assert_int(enabled.size()).is_equal(1)
		if not enabled.is_empty():enabled[0].pressed.emit()
		assert_int(Water.data().lines.size()).is_equal(1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Wooden Conduits"])).is_equal(0.0))

func test_local_source_search_finds_upstream_head_and_stays_bounded()->void:
	var terrain:=IntakeTerrain.new();auto_free(terrain)
	var sources:=terrain._water_conveyance_sources(Vector3(1,1,0))
	assert_int(sources.size()).is_greater(0)
	assert_int(sources.size()).is_less_equal(4)
	assert_bool(sources[0].gravity_feasible).is_true()
	assert_float(float(sources[0].position.z)).is_less(0.0)
	for candidate:Dictionary in sources:
		assert_float(float(candidate.distance_km)).is_less_equal(6.0)
		assert_bool(candidate.revealed).is_true()

func test_rival_investment_uses_the_paid_installation_path()->void:
	var old_provider:Callable=WorldSimulation.context_provider
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:
		var ctx:=context();ctx.terrain_height_at=height;ctx.environment_profile={};return ctx
	WorldSimulation.scoped("water_builders",func()->void:
		prepare()
		WorldSimulation.state.population_allocations.Construction=20
		WorldSimulation.state.population_health=1.0
		WorldSimulation.state.simulation_metrics.labor_efficiency=1.0
		WorldSimulation.state.water_metrics={"intake_ratio":.5,"source_distance_km":1.0}
		preload("res://scripts/water_conveyance_investment.gd").recommendation()
		assert_int(Water.data().lines.size()).is_equal(1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Wooden Conduits"])).is_equal(0.0))
	WorldSimulation.context_provider=old_provider

func test_secondary_control_callback_keeps_the_city_scope_after_panel_build()->void:
	WorldSimulation.scoped("water_builders",func()->void:
		prepare()
		var state=WorldSimulation.state;var model=WorldSimulation.settlements
		state.settlement_completed.assign(["Hearth Circle"]);model.ensure_founded()
		state.player_settlements.append({"id":"second","name":"Rivermeet","position":Vector2(1,0),"primary":false,"population_share":.2,"founded_day":20})
		var panel:=VBoxContainer.new();auto_free(panel)
		var ctx:=context();ctx.terrain_height_at=height
		model.with_city_resources("second",func()->void:
			state.resource_stockpiles={"Wooden Conduits":10.0,"Clay":2.0}
			preload("res://scripts/hud/water_conveyance_controls.gd").build(panel,ctx,"second","Rivermeet"))
		for child in panel.get_children():
			if child is Button and not child.disabled:child.pressed.emit();break
		assert_int(Water.data().lines.size()).is_equal(0)
		assert_float(float(state.resource_stockpiles["Wooden Conduits"])).is_equal(10.0)
		var city:Dictionary=model.settlement_record("second")
		assert_int(city.local_resources.water_conveyance.lines.size()).is_equal(1)
		assert_float(float(city.local_resources.resource_stockpiles["Wooden Conduits"])).is_equal(0.0))

func test_load_assessment_requires_paid_bedding_and_additional_completed_work()->void:
	WorldSimulation.scoped("water_builders",func()->void:
		prepare()
		var state=WorldSimulation.state
		for id:String in ["rigid_pipe_bedding","buried_pipe_load_assessment"]:
			state.known_discoveries.append(id);state.discovery_adoption[id]=1.0
		var bare:=Water.quote(source(),Vector3(1,1,0),height,"timber")
		assert_bool("buried_pipe_load_assessment" in bare.applied).is_false()
		assert_float(float(bare.work_required)).is_equal(40.0)
		state.resource_stockpiles["Conduit Bedding"]=2.0
		assert_bool(install().get("ok",false)).is_true()
		assert_float(float(state.resource_stockpiles["Conduit Bedding"])).is_equal(0.0)
		var line:Dictionary=Water.data().lines[0]
		assert_bool("buried_pipe_load_assessment" in line.applied).is_true()
		assert_float(float(line.decay)).is_equal_approx(.0012*.7*.85,.00000001)
		Water.construction_work(40,1)
		assert_float(Water.delivery(context(),2,100)).is_equal(0.0)
		assert_float(Water.construction_work(10,2)).is_equal(10.0)
		assert_float(Water.delivery(context(),3,100)).is_greater(0.0))

func test_investment_chooses_manufacturable_timber_when_ceramic_is_unavailable()->void:
	var old_provider:Callable=WorldSimulation.context_provider
	WorldSimulation.context_provider=func(_origin:Vector2)->Dictionary:
		var ctx:=context();ctx.terrain_height_at=height;ctx.environment_profile={};return ctx
	WorldSimulation.scoped("water_builders",func()->void:
		prepare()
		var state=WorldSimulation.state
		state.population_allocations.Construction=20
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
		state.water_metrics={"intake_ratio":.5,"source_distance_km":1.0}
		state.resource_stockpiles={"Timber":100.0,"Wrought Iron":2.0,"Clay":2.0}
		for id:String in ["wooden_log_conduits","clay_pipe_socket_jointing"]:
			state.known_discoveries.append(id);state.discovery_adoption[id]=1.0
		var planner=preload("res://scripts/water_conveyance_investment.gd")
		assert_bool(planner.targets().has("Wooden Conduits")).is_true()
		var order:Dictionary=planner.recommendation()
		assert_str(String(order.get("item",""))).is_equal("wooden_conduits")
		assert_bool(WorldSimulation.military.start_production_line(order.item,int(order.target)).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back()
		preload("res://scripts/persistent_production.gd").advance(WorldSimulation.military,job,50)
		assert_int(int(job.completed)).is_equal(10)
		planner.recommendation()
		assert_int(Water.data().lines.size()).is_equal(1)
		assert_float(float(state.resource_stockpiles["Wooden Conduits"])).is_equal(0.0))
	WorldSimulation.context_provider=old_provider

func test_primary_control_button_pays_for_an_installed_line()->void:
	WorldSimulation.scoped("water_builders",func()->void:
		prepare()
		var panel:=VBoxContainer.new();auto_free(panel)
		var ctx:=context();ctx.terrain_height_at=height
		preload("res://scripts/hud/water_conveyance_controls.gd").build(panel,ctx)
		var pressed:=false
		for child in panel.get_children():
			if child is Button and not child.disabled:child.pressed.emit();pressed=true;break
		assert_bool(pressed).is_true()
		assert_int(Water.data().lines.size()).is_equal(1)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Wooden Conduits"])).is_equal(0.0)
		assert_str(String(Water.data().lines[0].status)).is_equal("under_construction"))
