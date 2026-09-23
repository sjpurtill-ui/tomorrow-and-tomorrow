extends GdUnitTestSuite
const Evidence=preload("res://tools/pacing_production_evidence.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const P=preload("res://scripts/persistent_production.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("evidence",117)
func after_test()->void:WorldSimulation.clear()
func test_government_counts_distinguish_candidates_and_dual_officeholders()->void:
	WorldSimulation.scoped("evidence",func()->void:
		WorldSimulation.government.people.assign([
			{"status":"active","office_key":"Steward","local_leader_of":"capital"},
			{"status":"active","office_key":"","local_leader_of":"village"},
			{"status":"active","office_key":"Scholar","local_leader_of":""},
			{"status":"active","office_key":"","local_leader_of":""},
			{"status":"deceased","office_key":"Steward","local_leader_of":"capital"},
			{"status":"detained","office_key":"","local_leader_of":""}])
		var counts:Dictionary=Evidence.capture().government
		assert_int(counts.recorded_people).is_equal(6)
		assert_int(counts.active_roster).is_equal(4)
		assert_int(counts.officeholders).is_equal(3)
		assert_int(counts.central_officeholders).is_equal(2)
		assert_int(counts.settlement_leaders).is_equal(2)
		assert_int(counts.unappointed_candidates).is_equal(1)
	)
func test_real_partial_production_is_reported_without_mutating_state()->void:
	WorldSimulation.scoped("evidence",func()->void:
		var state=WorldSimulation.state;var host=WorldSimulation.military;state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0;state.population_allocations.Crafting=10
		for resource:String in ["Clay","Freshwater","Timber","Stone"]:state.resource_stockpiles[resource]=100.0
		state.resource_stockpiles["Civilian Goods"]=3.0
		# Lines make military items only; evidence reports no civilian lines.
		assert_bool(host.start_production_line("improvised",2).get("ok",false)).is_true()
		var job:Dictionary=host.equipment_queue.back();P.advance(host,job,float(job.work_per_item)*.5)
		var stocks:Dictionary=state.resource_stockpiles.duplicate(true);var queue:Array=host.equipment_queue.duplicate(true);var operations:Dictionary=Ops.data().duplicate(true)
		var result:=Evidence.capture(true)
		assert_int(int(result.civilian_lines)).is_equal(0)
		assert_float(float(result.household_stocks["Civilian Goods"])).is_equal(3.0)
		assert_bool(result.military_capabilities.improvised.recipe_known).is_true()
		assert_int(int(result.military_capabilities.improvised.stored)).is_equal(0)
		assert_dict(state.resource_stockpiles).is_equal(stocks);assert_array(host.equipment_queue).is_equal(queue);assert_dict(Ops.data()).is_equal(operations)
		P.advance(host,job,float(job.work_per_item)*.5);result=Evidence.capture(true)
		assert_int(int(result.military_capabilities.improvised.stored)).is_equal(1)
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
		for resource:String in ["Clay","Freshwater","Timber","Stone"]:state.resource_stockpiles[resource]=100.0
		assert_bool(host.start_production_line("improvised",1).get("ok",false)).is_true()
		var job:Dictionary=host.equipment_queue.back()
		var before:Dictionary=host.workshop.output_stocks(job)
		P.advance(host,job,float(job.work_per_item)*2.0);host.workshop.record(job,before)
		host.equipment_queue.clear();host.military_inventory.improvised=0
		var result:=Evidence.capture(true)
		assert_int(int(result.military_capabilities.improvised.stored)).is_equal(0)
		assert_float(float(result.recorded_output.improvised)).is_equal(1.0)
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
