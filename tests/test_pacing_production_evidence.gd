extends GdUnitTestSuite
const Evidence=preload("res://tools/pacing_production_evidence.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("evidence",117)
func after_test()->void:WorldSimulation.clear()
func test_real_partial_production_is_reported_without_mutating_state()->void:
	WorldSimulation.scoped("evidence",func()->void:
		var state=WorldSimulation.state;state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=10
		state.known_discoveries.append("clay_levigation");state.discovery_adoption.clay_levigation=1.0
		for resource:String in ["Clay","Freshwater","Timber","Stone"]:state.resource_stockpiles[resource]=100.0
		assert_bool(WorldSimulation.military.start_production_line("prepared_clay",2).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,1.0)
		var stocks:Dictionary=state.resource_stockpiles.duplicate(true);var queue:Array=WorldSimulation.military.equipment_queue.duplicate(true);var operations:Dictionary=Ops.data().duplicate(true)
		var result:=Evidence.capture(true)
		assert_int(int(result.civilian_lines)).is_equal(1)
		assert_float(float(result.lines[0].progress_days)).is_equal(1.0)
		assert_int(int(result.lines[0].completed_on_current_line)).is_equal(0)
		assert_dict(state.resource_stockpiles).is_equal(stocks);assert_array(WorldSimulation.military.equipment_queue).is_equal(queue);assert_dict(Ops.data()).is_equal(operations)
		P.advance(WorldSimulation.military,job,1.0);result=Evidence.capture(true)
		assert_float(float(result.manufactured_stocks["Prepared Clay"])).is_equal(1.0)
		assert_int(int(result.lines[0].completed_on_current_line)).is_equal(1)
	)
func test_stale_service_ledger_does_not_claim_current_operating_capability()->void:
	WorldSimulation.scoped("evidence",func()->void:
		WorldSimulation.state.elapsed_days=10
		Ops.data().last_day=9;Ops.data().services.electricity=2.0
		Ops.data().plants.solar_array={"installed":1,"building":2,"work":0.0,"enabled":true,"running_units":1.0}
		var result:=Evidence.capture(true)
		assert_bool(result.operations_ledger_current).is_false();assert_dict(result.remaining_daily_services).is_empty()
		assert_int(int(result.installed_units)).is_equal(1);assert_int(int(result.units_under_construction)).is_equal(2)
		assert_float(float(result.plants[0].running)).is_equal(0.0)
		Ops.data().last_day=10;result=Evidence.capture(true)
		assert_float(float(result.remaining_daily_services.electricity)).is_equal(2.0)
		assert_float(float(result.plants[0].running)).is_equal(1.0)
		assert_bool(Evidence.capture().has("recipes")).is_false()
	)

func test_produced_totals_survive_line_removal_and_consumption()->void:
	WorldSimulation.scoped("evidence",func()->void:
		var state=WorldSimulation.state;var host=WorldSimulation.military
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=10
		state.known_discoveries.append("clay_levigation");state.discovery_adoption.clay_levigation=1.0
		for resource:String in ["Clay","Freshwater","Timber","Stone"]:state.resource_stockpiles[resource]=100.0
		assert_bool(host.start_production_line("prepared_clay",1).get("ok",false)).is_true()
		var job:Dictionary=host.equipment_queue.back()
		var before:Dictionary=host.workshop.output_stocks(job)
		P.advance(host,job,2.0);host.workshop.record(job,before)
		host.equipment_queue.clear();state.resource_stockpiles["Prepared Clay"]=0.0
		var result:=Evidence.capture(true)
		assert_int(int(result.civilian_lines)).is_equal(0)
		assert_float(float(result.recorded_output["Prepared Clay"])).is_equal(1.0)
		assert_int(result.recorded_output_by_settlement.size()).is_equal(1)
	)

func test_food_and_delivery_guards_are_reported_from_current_metrics()->void:
	WorldSimulation.scoped("evidence",func()->void:
		var metrics:Dictionary=WorldSimulation.state.simulation_metrics
		metrics.merge({"food_days":120,"food_intake_ratio":.94,"food_consumption":100.0,"army_provisions_required":10.0,"army_provision_delivery_ratio":.4},true)
		var result:=Evidence.capture()
		assert_bool(result.delivery_shortage).is_true()
		assert_bool(result.food_shortage).is_false()
		assert_bool(result.production_food_blocked).is_false()
		metrics.food_intake_ratio=.8;result=Evidence.capture()
		assert_bool(result.food_shortage).is_true()
		assert_bool(result.production_food_blocked).is_true()
	)
