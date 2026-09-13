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
func clothing_setup()->void:
	var state=WorldSimulation.state
	state.ensure_population_total(100);state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_allocations.Logistics=20;state.population_allocations.Crafting=20
	state.resource_stockpiles={"Freshwater":100.0,"Clay":30.0,"Stone":30.0,"Timber":100.0,"Fiber Plants":100.0}
	for gate:String in ["cordage","drop_spindles","knitted_loop_fabrics","fiber_retting"]:
		state.known_discoveries.append(gate);state.discovery_adoption[gate]=1.0
func test_clothing_requests_actual_upstream_yarn_and_then_pays_for_garments()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		clothing_setup();var state=WorldSimulation.state
		var clothing=preload("res://scripts/household_clothing.gd")
		var initial_fibers:=float(state.resource_stockpiles["Fiber Plants"])
		for item:String in ["retted_fibers","spun_yarn"]:
			var order:=F.clothing_recommendation()
			assert_str(String(order.get("item",""))).is_equal(item)
			C.civilian_orders("paper_ruler",{})
			var job:Dictionary=WorldSimulation.military.equipment_queue[0]
			assert_str(String(job.item)).is_equal(item)
			for step in 10:preload("res://scripts/persistent_production.gd").advance(WorldSimulation.military,job,20.0)
		assert_float(float(state.resource_stockpiles["Fiber Plants"])).is_less(initial_fibers)
		assert_float(float(state.resource_stockpiles["Spun Yarn"])).is_equal(10.0)
		assert_float(clothing.count()).is_equal(0.0)
		clothing.advance(100,100,false)
		assert_float(clothing.count()).is_equal(2.0);assert_float(float(state.resource_stockpiles["Spun Yarn"])).is_equal(8.0)
	)
func test_clothing_supply_respects_absence_pause_travel_and_sufficient_stocks()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		clothing_setup();var state=WorldSimulation.state
		state.resource_stockpiles.Freshwater=0.0;assert_dict(F.clothing_recommendation()).is_empty()
		state.resource_stockpiles.Freshwater=100.0;state.convoy_traveling=true;assert_dict(F.clothing_recommendation()).is_empty()
		state.convoy_traveling=false;C.civilian_orders("paper_ruler",{});WorldSimulation.military.equipment_queue[0].paused=true
		assert_dict(F.clothing_recommendation()).is_empty()
		WorldSimulation.military.equipment_queue[0].paused=false;state.resource_stockpiles["Spun Yarn"]=10.0
		assert_dict(F.clothing_recommendation()).is_empty()
		state.resource_stockpiles["Spun Yarn"]=0.0;preload("res://scripts/household_clothing.gd").add("knit",110)
		assert_dict(F.clothing_recommendation()).is_empty()
	)
func test_single_automatic_workshop_replenishes_upstream_after_garment_consumption()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		clothing_setup();var state=WorldSimulation.state
		var production=preload("res://scripts/persistent_production.gd")
		var clothing=preload("res://scripts/household_clothing.gd")
		for item:String in ["retted_fibers","spun_yarn"]:
			C.civilian_orders("paper_ruler",{})
			var job:Dictionary=WorldSimulation.military.equipment_queue[0]
			assert_str(String(job.item)).is_equal(item)
			for step in 10:production.advance(WorldSimulation.military,job,20.0)
		var fibers:=float(state.resource_stockpiles["Fiber Plants"])
		for day in range(1,4):
			state.elapsed_days=day;clothing.advance(100,100,false)
			assert_float(float(state.resource_stockpiles["Spun Yarn"])).is_equal(8.0)
			for item:String in ["retted_fibers","spun_yarn"]:
				C.civilian_orders("paper_ruler",{})
				assert_int(WorldSimulation.military.equipment_queue.size()).is_equal(1)
				var job:Dictionary=WorldSimulation.military.equipment_queue[0]
				assert_str(String(job.item)).is_equal(item)
				for step in 5:production.advance(WorldSimulation.military,job,20.0)
			assert_float(float(state.resource_stockpiles["Spun Yarn"])).is_equal(10.0)
		assert_float(float(state.resource_stockpiles["Fiber Plants"])).is_less(fibers)
		assert_float(clothing.count()).is_equal(6.0)
	)
func test_blocked_reuse_preserves_manual_paused_reserved_and_in_progress_lines()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		clothing_setup();var state=WorldSimulation.state;var production=preload("res://scripts/persistent_production.gd")
		state.resource_stockpiles["Prepared Fibers"]=10.0
		C.civilian_orders("paper_ruler",{})
		var job:Dictionary=WorldSimulation.military.equipment_queue[0]
		assert_str(String(job.item)).is_equal("spun_yarn")
		state.resource_stockpiles["Prepared Fibers"]=0.0
		assert_int(F.finished_line("Prepared Fibers")).is_equal(int(job.id))
		assert_int(F.finished_line("Paper")).is_equal(-1)
		job.progress_days=.1;assert_int(F.finished_line("Prepared Fibers")).is_equal(-1)
		job.progress_days=0.0;job.reserved_materials={"Prepared Fibers":.1};assert_int(F.finished_line("Prepared Fibers")).is_equal(-1)
		job.reserved_materials={};job.paused=true;assert_int(F.finished_line("Prepared Fibers")).is_equal(-1)
		job.paused=false;production.configure(WorldSimulation.military,int(job.id),10,false)
		assert_bool(bool(job.get("planner_managed",false))).is_false()
		assert_int(F.finished_line("Prepared Fibers")).is_equal(-1)
		C.civilian_orders("paper_ruler",{})
		assert_str(String(job.item)).is_equal("spun_yarn")
		assert_bool(bool(job.get("planner_managed",false))).is_false()
	)
func test_saved_automatic_line_resumes_without_rebuying_existing_tools()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		clothing_setup();var state=WorldSimulation.state
		state.resource_stockpiles["Prepared Fibers"]=10.0;C.civilian_orders("paper_ruler",{})
		state.resource_stockpiles["Prepared Fibers"]=0.0
	)
	var saved:=WorldSimulation.export_state();assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	WorldSimulation.scoped("paper_ruler",func()->void:
		var state=WorldSimulation.state;var production=preload("res://scripts/persistent_production.gd")
		var job:Dictionary=WorldSimulation.military.equipment_queue[0]
		assert_bool(bool(job.get("planner_managed",false))).is_true()
		var clay:=float(state.resource_stockpiles.Clay);var tools:=production.installed_tooling(job)
		C.civilian_orders("paper_ruler",{})
		assert_str(String(job.item)).is_equal("retted_fibers")
		# Retting needs 3 clay tools; the spinner's existing 1 is retained.
		assert_float(float(state.resource_stockpiles.Clay)).is_equal(clay-maxf(0,3.0-float(tools.get("Clay",0))))
		assert_bool(bool(job.get("planner_managed",false))).is_true()
		job.planner_managed="yes"
		assert_str(production.validate_saved({"equipment_queue":[job]})).is_not_empty()
	)
func test_sewing_supply_uses_collected_bone_and_real_yarn_production()->void:
	WorldSimulation.scoped("paper_ruler",func()->void:
		clothing_setup();var state=WorldSimulation.state
		var clothing=preload("res://scripts/household_clothing.gd")
		state.known_discoveries.erase("knitted_loop_fabrics")
		for gate:String in ["bone_needle_sewing","hafted_tools"]:
			state.known_discoveries.append(gate);state.discovery_adoption[gate]=1.0
		state.resource_stockpiles["Woven Cloth"]=10.0;state.resource_stockpiles["Prepared Fibers"]=10.0
		assert_dict(F.clothing_recommendation()).is_empty()
		clothing.advance(0,100,false,50)
		assert_str(String(F.clothing_recommendation().get("item",""))).is_equal("spun_yarn")
		C.civilian_orders("paper_ruler",{})
		var job:Dictionary=WorldSimulation.military.equipment_queue[0]
		preload("res://scripts/persistent_production.gd").advance(WorldSimulation.military,job,20)
		assert_float(float(state.resource_stockpiles["Spun Yarn"])).is_equal(1.0)
		state.elapsed_days=1;clothing.advance(100,100,false)
		assert_float(clothing.count()).is_equal(2.0)
		assert_float(clothing.available(clothing.BONE_RESOURCE)).is_equal_approx(0,.000001)
		assert_float(float(state.resource_stockpiles["Woven Cloth"])).is_equal_approx(8.6,.000001)
	)
