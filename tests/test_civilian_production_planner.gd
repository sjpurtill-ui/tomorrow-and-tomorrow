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
