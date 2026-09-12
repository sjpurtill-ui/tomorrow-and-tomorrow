extends GdUnitTestSuite
const K=preload("res://scripts/paper_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const S=preload("res://scripts/paper_study.gd")
const E=preload("res://scripts/society_exchange.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("papermaker",995)
func after_test()->void:WorldSimulation.clear()
func test_authored_contracts_and_paid_fiber_to_paper_chain()->void:
	WorldSimulation.scoped("papermaker",func()->void:
		assert_int(K.entries().size()).is_equal(4)
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
		var state=WorldSimulation.state
		state.resource_stockpiles.merge({"Prepared Fibers":1.0,"Freshwater":4.0,"Timber":20.0,"Stone":20.0,"Clay":20.0,"Fiber Plants":20.0},true)
		for item:String in ["beaten_pulp","handmade_paper"]:
			var recipe:=I.product(item);state.known_discoveries.append(recipe.gate);state.discovery_adoption[recipe.gate]=1.0
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(recipe.days))
			assert_int(int(job.completed)).is_equal(1)
			assert_bool(WorldSimulation.military.cancel_equipment_job(int(job.id)).get("cancelled",false)).is_true()
		assert_float(float(state.resource_stockpiles.Paper)).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Paper Pulp"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Prepared Fibers"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles.Freshwater)).is_equal(0.0)
	)
func test_motor_beating_needs_power_and_saved_partial_work_finishes_once()->void:
	WorldSimulation.scoped("papermaker",func()->void:
		var r:=I.product("electric_pulp");var state=WorldSimulation.state
		state.known_discoveries.append(r.gate);state.discovery_adoption[r.gate]=1.0
		for k:String in r.materials:state.resource_stockpiles[k]=10.0
		for k:String in r.tooling:state.resource_stockpiles[k]=10.0
		assert_bool(WorldSimulation.military.start_production_line("electric_pulp",1).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();var before:Dictionary=state.resource_stockpiles.duplicate(true)
		P.advance(WorldSimulation.military,job,5.0)
		assert_dict(state.resource_stockpiles).is_equal(before)
		state.technology_operations.last_day=int(state.elapsed_days);state.technology_operations.services.electricity=1.0
		P.advance(WorldSimulation.military,job,1.0)
		var saved:Dictionary=JSON.parse_string(JSON.stringify(job))
		assert_str(P.validate_saved({"equipment_queue":[saved]})).is_empty()
		state.technology_operations.services.electricity=1.0
		P.advance(WorldSimulation.military,saved,1.0);P.advance(WorldSimulation.military,saved,5.0)
		assert_float(float(state.resource_stockpiles["Paper Pulp"])).is_equal(1.0)
	)
func test_paper_support_is_stock_limited_and_never_spent_beyond_remaining_work()->void:
	WorldSimulation.scoped("papermaker",func()->void:
		var state=WorldSimulation.state
		assert_float(float(S.use(10.0,20.0).progress)).is_equal(10.0)
		state.resource_stockpiles.Paper=.05
		var partial:=S.use(10.0,20.0)
		assert_float(float(partial.progress)).is_equal(11.0)
		assert_float(float(partial.work)).is_equal(10.0)
		assert_float(float(state.resource_stockpiles.Paper)).is_equal(0.0)
		state.resource_stockpiles.Paper=1.0
		var finish:=S.use(10.0,1.2)
		assert_float(float(finish.work)).is_equal_approx(1.0,.000001)
		assert_float(float(finish.progress)).is_equal_approx(1.2,.000001)
		assert_float(float(state.resource_stockpiles.Paper)).is_equal_approx(.99,.000001)
		S.use(10.0,0.0);S.use(0.0,100.0)
		assert_float(float(state.resource_stockpiles.Paper)).is_equal_approx(.99,.000001)
	)
func test_daily_collection_study_consumes_paper_only_for_arrived_unfinished_material()->void:
	WorldSimulation.scoped("papermaker",func()->void:
		var state=WorldSimulation.state
		state.ensure_population_total(100);state.population_allocations.Knowledge=20;state.simulation_metrics.food_intake_ratio=1.0
		state.resource_stockpiles.Paper=1.0
		E.data().collections={"a":{"id":"a","kind":"knowledge","name":"Account","source_id":"","discovery_id":"clay_shaping","study":0.0,"work":100.0,"returned_day":0,"signals":[]},"b":{"id":"b","kind":"knowledge","name":"Later","source_id":"","discovery_id":"clay_shaping","study":0.0,"work":100.0,"returned_day":100,"signals":[]}}
		var base:=state.effective_workers("Knowledge")*.15
		E.advance(1)
		assert_float(float(E.data().collections.a.study)).is_equal_approx(base*1.2/100.0,.000001)
		assert_float(float(E.data().collections.b.study)).is_equal(0.0)
		assert_float(float(state.resource_stockpiles.Paper)).is_equal_approx(1.0-base*.01,.000001)
		var remaining:=float(state.resource_stockpiles.Paper)
		E.advance(1)
		assert_float(float(state.resource_stockpiles.Paper)).is_equal(remaining)
		E.data().collections.a.study=1.0;E.advance(2)
		assert_float(float(state.resource_stockpiles.Paper)).is_equal(remaining)
	)
func test_cloth_pulp_and_pressed_sheets_use_their_actual_inputs()->void:
	WorldSimulation.scoped("papermaker",func()->void:
		var state=WorldSimulation.state
		state.resource_stockpiles.merge({"Woven Cloth":.5,"Freshwater":5.0,"Timber":20.0,"Stone":20.0,"Clay":20.0,"Wrought Iron":5.0},true)
		for item:String in ["rag_pulp","pressed_paper"]:
			var r:=I.product(item);state.known_discoveries.append(r.gate);state.discovery_adoption[r.gate]=1.0
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,job,float(r.days))
			assert_int(int(job.completed)).is_equal(1)
			assert_bool(WorldSimulation.military.cancel_equipment_job(int(job.id)).get("cancelled",false)).is_true()
		assert_float(float(state.resource_stockpiles.Paper)).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Woven Cloth"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles["Paper Pulp"])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles.Freshwater)).is_equal(0.0)
	)
