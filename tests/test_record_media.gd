extends GdUnitTestSuite
const K=preload("res://scripts/record_media_knowledge.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const S=preload("res://scripts/paper_study.gd")
const E=preload("res://scripts/society_exchange.gd")
const F=preload("res://scripts/civilian_production_planner.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("recorder",996)
func after_test()->void:WorldSimulation.clear()
func note(kind:String="knowledge")->Dictionary:
	return {"id":"local_note","kind":kind,"name":"Local comparison","source_id":"","source_name":"Local","position":{"x":0.0,"z":0.0},"observed_day":0,"returned_day":0,"discovery_id":"clay_shaping","study":0.0,"work":100.0,"signals":[]}
func test_three_record_methods_have_real_production_consumers()->void:
	WorldSimulation.scoped("recorder",func()->void:
		assert_int(K.entries().size()).is_equal(3)
		for entry:Dictionary in K.entries():
			if entry.id=="bookbinding_assemblies":assert_bool(preload("res://scripts/technology_requirements.gd").evaluate(entry,["cordage"]).ready).is_true()
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func test_each_medium_needs_paid_materials_and_completed_work()->void:
	WorldSimulation.scoped("recorder",func()->void:
		var state=WorldSimulation.state
		for item:String in ["clay_record_tablets","knotted_record_cords","bound_record_books"]:
			var spec:=I.product(item);state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
			for resource:String in spec.materials:state.resource_stockpiles[resource]=100.0
			for resource:String in spec.tooling:state.resource_stockpiles[resource]=100.0
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var job:Dictionary=WorldSimulation.military.equipment_queue.back();var stock:Dictionary=state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,job,float(spec.days)*.5)
			assert_float(float(state.resource_stockpiles.get(spec.output,0))).is_equal(0.0)
			var restored:Dictionary=bytes_to_var(var_to_bytes(job));assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
			P.advance(WorldSimulation.military,restored,float(spec.days)*.5)
			assert_float(float(state.resource_stockpiles[spec.output])).is_equal(1.0)
			for resource:String in spec.materials:assert_float(float(stock[resource])-float(state.resource_stockpiles[resource])).is_equal_approx(float(spec.materials[resource]),.000001)
			WorldSimulation.military.cancel_equipment_job(int(job.id))
	)
func test_mixed_media_share_one_work_budget_and_cannot_overshoot()->void:
	WorldSimulation.scoped("recorder",func()->void:
		var state=WorldSimulation.state;state.known_discoveries.append("knotted_record_systems");state.discovery_adoption.knotted_record_systems=1.0
		for resource:String in S.MEDIA:state.resource_stockpiles[resource]=float(S.MEDIA[resource].per_work)
		var result:=S.use(6,100,note("specimen"))
		assert_float(float(result.work)).is_equal_approx(6,.000001);assert_float(float(result.progress)).is_equal_approx(7.22,.000001)
		for resource:String in S.MEDIA:assert_float(float(state.resource_stockpiles[resource])).is_equal_approx(0,.000001)
		state.resource_stockpiles["Clay Record Tablets"]=1.0
		result=S.use(10,.115)
		assert_float(float(result.work)).is_equal_approx(.1,.000001);assert_float(float(result.progress)).is_equal_approx(.115,.000001)
		assert_float(float(state.resource_stockpiles["Clay Record Tablets"])).is_equal_approx(.998,.000001)
		var stocks:Dictionary=state.resource_stockpiles.duplicate(true);S.use(0,100);S.use(100,0);assert_dict(state.resource_stockpiles).is_equal(stocks)
	)
func test_knotted_records_need_local_interpretation_and_quantity_context()->void:
	WorldSimulation.scoped("recorder",func()->void:
		var state=WorldSimulation.state;state.resource_stockpiles["Record Cords"]=1.0
		assert_float(float(S.use(10,100,note("specimen")).progress)).is_equal(10.0)
		state.known_discoveries.append("knotted_record_systems");state.discovery_adoption.knotted_record_systems=1.0
		assert_float(float(S.use(10,100,note()).progress)).is_equal(10.0)
		assert_float(float(state.resource_stockpiles["Record Cords"])).is_equal(1.0)
		assert_float(float(S.use(10,100,note("specimen")).progress)).is_equal_approx(11.2,.000001)
		assert_float(float(state.resource_stockpiles["Record Cords"])).is_equal_approx(.9,.000001)
	)
func test_imported_tablets_and_volumes_do_not_teach_manufacture()->void:
	WorldSimulation.scoped("recorder",func()->void:
		var state=WorldSimulation.state
		state.resource_stockpiles["Bound Record Books"]=1.0
		var result:=S.use(10,100,note());assert_float(float(result.progress)).is_equal(12.5)
		assert_bool("bookbinding_assemblies" in state.known_discoveries).is_false()
		assert_bool("clay_record_tablets" in state.known_discoveries).is_false()
	)
func test_daily_study_uses_only_arrived_records_and_remains_idempotent()->void:
	WorldSimulation.scoped("recorder",func()->void:
		var state=WorldSimulation.state;state.ensure_population_total(100);state.population_allocations.Knowledge=20;state.simulation_metrics.food_intake_ratio=1.0
		state.resource_stockpiles["Clay Record Tablets"]=1.0
		E.data().collections.local_note=note();var later:=note();later.id="later";later.returned_day=100;E.data().collections.later=later
		var base:=state.effective_workers("Knowledge")*.15;E.advance(1)
		assert_float(float(E.data().collections.local_note.study)).is_equal_approx(base*1.15/100,.000001)
		assert_float(float(E.data().collections.later.study)).is_equal(0.0)
		var stock:=float(state.resource_stockpiles["Clay Record Tablets"]);E.advance(1);assert_float(float(state.resource_stockpiles["Clay Record Tablets"])).is_equal(stock)
		assert_bool("clay_shaping" in state.known_discoveries).is_false()
	)
func test_record_supply_falls_back_to_actual_clay_production_without_paper()->void:
	WorldSimulation.scoped("recorder",func()->void:
		var state=WorldSimulation.state;state.population_allocations.Knowledge=20;state.known_discoveries.append("clay_record_tablets");state.discovery_adoption.clay_record_tablets=1.0
		state.resource_stockpiles.merge({"Clay":10.0,"Freshwater":10.0,"Timber":10.0,"Stone":10.0},true)
		E.data().collections.local_note=note()
		var order:=F.study_recommendation();assert_str(String(order.get("item",""))).is_equal("clay_record_tablets")
		assert_int(int(order.target)).is_equal(2)
		assert_bool(WorldSimulation.military.start_production_line(order.item,order.target).get("ok",false)).is_true()
		var job:Dictionary=WorldSimulation.military.equipment_queue.back();P.advance(WorldSimulation.military,job,10)
		assert_float(float(state.resource_stockpiles["Clay Record Tablets"])).is_equal(2.0)
		assert_dict(F.study_recommendation()).is_empty()
		assert_float(float(S.use(10,100,note()).progress)).is_equal(11.5)
	)
func test_saved_owner_continuation_retains_media_and_study_progress()->void:
	WorldSimulation.scoped("recorder",func()->void:
		var state=WorldSimulation.state;state.ensure_population_total(100);state.population_allocations.Knowledge=20;state.simulation_metrics.food_intake_ratio=1.0
		state.resource_stockpiles["Bound Record Books"]=1.0;E.data().collections.local_note=note();E.advance(1)
	)
	var saved:=WorldSimulation.export_state().duplicate(true)
	WorldSimulation.scoped("recorder",func()->void:E.advance(2))
	var state:Node=WorldSimulation.actors.recorder.systems.GameState
	var expected:Dictionary=state.society_exchange.duplicate(true);var stocks:Dictionary=state.resource_stockpiles.duplicate(true)
	assert_bool(WorldSimulation.import_state(bytes_to_var(var_to_bytes(saved))).get("ok",false)).is_true()
	WorldSimulation.scoped("recorder",func()->void:E.advance(2))
	assert_dict(WorldSimulation.actors.recorder.systems.GameState.society_exchange).is_equal(expected)
	assert_dict(WorldSimulation.actors.recorder.systems.GameState.resource_stockpiles).is_equal(stocks)
