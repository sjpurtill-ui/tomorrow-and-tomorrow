extends GdUnitTestSuite
const F=preload("res://scripts/civilian_production_planner.gd")
const C=preload("res://scripts/civilization_controller.gd")
const E=preload("res://scripts/society_exchange.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("paper_ruler",995)
func after_test()->void:WorldSimulation.clear()
func prepare()->void:
	var state=WorldSimulation.state
	state.ensure_population_total(100);state.population_allocations.Knowledge=20
	state.known_discoveries.append("paper_making");state.discovery_adoption.paper_making=1.0
	state.resource_stockpiles.merge({"Paper Pulp":5.0,"Freshwater":5.0,"Timber":20.0,"Fiber Plants":20.0},true)
	E.data().collections["test"]={"returned_day":0,"study":0.0,"work":240.0}
func test_demand_ignores_future_completed_and_unstaffed_study()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		prepare()
		assert_int(F.recommendation().target).is_equal(2)
		E.data().collections.test.returned_day=10
		assert_dict(F.recommendation()).is_empty()
		E.data().collections.test.returned_day=0;E.data().collections.test.study=1.0
		assert_dict(F.recommendation()).is_empty()
		E.data().collections.test.study=0.0;WorldSimulation.state.population_allocations.Knowledge=0
		assert_dict(F.recommendation()).is_empty()
	)
func test_controller_pays_tooling_once_and_reuses_stock_target()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		prepare()
		C.civilian_orders("paper_ruler",{})
		assert_int(WorldSimulation.military.equipment_queue.size()).is_equal(1)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Timber)).is_equal(16.0)
		C.civilian_orders("paper_ruler",{})
		assert_int(WorldSimulation.military.equipment_queue.size()).is_equal(1)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Timber)).is_equal(16.0)
		WorldSimulation.state.resource_stockpiles.Paper=2.0
		assert_dict(F.recommendation()).is_empty()
	)
func test_missing_inputs_and_emergency_do_not_create_lines()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		prepare()
		C.civilian_orders("paper_ruler",{"hungry":true})
		C.civilian_orders("paper_ruler",{"at_war":true})
		assert_array(WorldSimulation.military.equipment_queue).is_empty()
		WorldSimulation.state.resource_stockpiles["Paper Pulp"]=0.0
		assert_dict(F.recommendation()).is_empty()
		C.civilian_orders("paper_ruler",{})
		assert_array(WorldSimulation.military.equipment_queue).is_empty()
	)
func test_target_is_bounded_and_paused_lines_are_respected()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		prepare();E.data().collections.test.work=100000.0
		assert_int(F.recommendation().target).is_equal(10)
		C.civilian_orders("paper_ruler",{})
		WorldSimulation.military.equipment_queue[0].paused=true
		assert_dict(F.recommendation()).is_empty()
		C.civilian_orders("paper_ruler",{})
		assert_int(WorldSimulation.military.equipment_queue.size()).is_equal(1)
		assert_bool(WorldSimulation.military.equipment_queue[0].paused).is_true()
	)
func test_upstream_chain_manufactures_paper_from_raw_fiber()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		prepare()
		var state=WorldSimulation.state
		state.resource_stockpiles["Paper Pulp"]=0.0
		state.resource_stockpiles.merge({"Freshwater":100.0,"Clay":30.0,"Stone":30.0,"Timber":100.0,"Fiber Plants":100.0},true)
		for gate:String in ["fiber_retting","fiber_pulp_beating"]:
			state.known_discoveries.append(gate);state.discovery_adoption[gate]=1.0
		assert_int(WorldSimulation.military.production_line_capacity()).is_equal(1)
		var expected:Array[String]=["retted_fibers","beaten_pulp","handmade_paper"]
		for item:String in expected:
			assert_str(F.recommendation().item).is_equal(item)
			C.civilian_orders("paper_ruler",{})
			assert_int(WorldSimulation.military.equipment_queue.size()).is_equal(1)
			var job:Dictionary={}
			for candidate:Dictionary in WorldSimulation.military.equipment_queue:
				if String(candidate.item)==item:job=candidate
			assert_bool(job.is_empty()).is_false()
			for step in 5:preload("res://scripts/persistent_production.gd").advance(WorldSimulation.military,job,20.0)
		assert_float(float(state.resource_stockpiles.Paper)).is_equal(2.0)
		assert_float(float(state.resource_stockpiles["Paper Pulp"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Prepared Fibers"])).is_equal(0.0)
		assert_dict(F.recommendation()).is_empty()
	)
func test_no_upstream_investment_when_other_required_raw_material_is_absent()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		prepare()
		var state=WorldSimulation.state
		state.resource_stockpiles["Paper Pulp"]=0.0;state.resource_stockpiles.Freshwater=0.0
		state.resource_stockpiles["Prepared Fibers"]=10.0
		state.known_discoveries.append("fiber_pulp_beating");state.discovery_adoption.fiber_pulp_beating=1.0
		assert_dict(F.recommendation()).is_empty()
	)
func test_retooling_never_takes_paused_unfinished_or_military_line()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		prepare();C.civilian_orders("paper_ruler",{})
		var job:Dictionary=WorldSimulation.military.equipment_queue[0]
		WorldSimulation.state.resource_stockpiles.Paper=2.0
		assert_int(F.finished_line()).is_equal(int(job.id))
		job.progress_days=.1
		assert_int(F.finished_line()).is_equal(-1)
		job.progress_days=0.0;job.reserved_materials={"Paper Pulp":.1}
		assert_int(F.finished_line()).is_equal(-1)
		job.reserved_materials={};job.paused=true
		assert_int(F.finished_line()).is_equal(-1)
		job.paused=false;job.job_type="production"
		assert_int(F.finished_line()).is_equal(-1)
	)
func test_unpowered_machine_does_not_displace_workable_hand_pulp_route()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		prepare()
		var state=WorldSimulation.state
		state.resource_stockpiles["Paper Pulp"]=0.0
		state.resource_stockpiles.merge({"Prepared Fibers":20.0,"Freshwater":100.0,"Stone":20.0,"Clay":20.0,"Electric Motors":1.0,"Shaft Bearings":1.0,"Steel":4.0},true)
		for gate:String in ["fiber_pulp_beating","electric_pulp_beating"]:
			state.known_discoveries.append(gate);state.discovery_adoption[gate]=1.0
		assert_str(F.recommendation().item).is_equal("beaten_pulp")
	)
