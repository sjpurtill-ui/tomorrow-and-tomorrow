extends GdUnitTestSuite
const Water=preload("res://scripts/water_conveyance.gd")
const State=preload("res://scripts/water_conveyance_state.gd")
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
