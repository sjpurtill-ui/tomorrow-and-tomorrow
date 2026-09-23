extends GdUnitTestSuite
const K=preload("res://scripts/record_media_knowledge.gd")
const S=preload("res://scripts/paper_study.gd")
const E=preload("res://scripts/society_exchange.gd")
const F=preload("res://scripts/civilian_production_planner.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("recorder",996)
func after_test()->void:WorldSimulation.clear()
const GOODS:="Civilian Goods"
func learn(id:String)->void:
	if id not in WorldSimulation.state.known_discoveries:WorldSimulation.state.known_discoveries.append(id)
	WorldSimulation.state.discovery_adoption[id]=1.0
func note(kind:String="knowledge")->Dictionary:
	return {"id":"local_note","kind":kind,"name":"Local comparison","source_id":"","source_name":"Local","position":{"x":0.0,"z":0.0},"observed_day":0,"returned_day":0,"discovery_id":"clay_shaping","study":0.0,"work":100.0,"signals":[]}
func test_three_record_methods_have_real_production_consumers()->void:
	WorldSimulation.scoped("recorder",func()->void:
		assert_int(K.entries().size()).is_equal(3)
		for entry:Dictionary in K.entries():
			if entry.id=="bookbinding_assemblies":assert_bool(preload("res://scripts/technology_requirements.gd").evaluate(entry,["cordage"]).ready).is_true()
		assert_array(preload("res://scripts/technology_catalog_contract.gd").validate(K.entries(),WorldSimulation.discovery.technology_catalog)).is_empty()
	)
func test_mixed_media_share_one_work_budget_and_cannot_overshoot()->void:
	WorldSimulation.scoped("recorder",func()->void:
		var state=WorldSimulation.state
		for id:String in ["clay_record_tablets","knotted_record_systems"]:learn(id)
		var tablets:=S.bill("Clay Record Tablets");var cords:=S.bill("Record Cords")
		state.resource_stockpiles.merge({GOODS:100.0,"Freshwater":100.0,"Fiber Plants":100.0},true)
		# Clay for exactly one unit of tablet-supported work; cords take the rest.
		state.resource_stockpiles.Clay=float(tablets.Clay)
		var result:=S.use(6,100,note("specimen"))
		assert_float(float(result.work)).is_equal_approx(6,.000001);assert_float(float(result.progress)).is_equal_approx(1.15+5*1.12,.000001)
		assert_float(float(state.resource_stockpiles.Clay)).is_equal_approx(0,.000001)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal_approx(100-float(tablets[GOODS])-5*float(cords[GOODS]),.000001)
		state.resource_stockpiles.Clay=1.0
		result=S.use(10,.115)
		assert_float(float(result.work)).is_equal_approx(.1,.000001);assert_float(float(result.progress)).is_equal_approx(.115,.000001)
		assert_float(float(state.resource_stockpiles.Clay)).is_equal_approx(1-.1*float(tablets.Clay),.000001)
		var stocks:Dictionary=state.resource_stockpiles.duplicate(true);S.use(0,100);S.use(100,0);assert_dict(state.resource_stockpiles).is_equal(stocks)
	)
func test_knotted_records_need_local_interpretation_and_quantity_context()->void:
	WorldSimulation.scoped("recorder",func()->void:
		var state=WorldSimulation.state;state.resource_stockpiles.merge({GOODS:1.0,"Fiber Plants":1.0},true)
		var cords:=S.bill("Record Cords")
		assert_float(float(S.use(10,100,note("specimen")).progress)).is_equal(10.0)
		learn("knotted_record_systems")
		assert_float(float(S.use(10,100,note()).progress)).is_equal(10.0)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal(1.0)
		assert_float(float(S.use(10,100,note("specimen")).progress)).is_equal_approx(11.2,.000001)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal_approx(1-10*float(cords[GOODS]),.000001)
		assert_float(float(state.resource_stockpiles["Fiber Plants"])).is_equal_approx(1-10*float(cords["Fiber Plants"]),.000001)
	)
func test_goods_without_record_techniques_give_no_bonus_or_knowledge()->void:
	WorldSimulation.scoped("recorder",func()->void:
		var state=WorldSimulation.state
		state.resource_stockpiles.merge({GOODS:1.0,"Clay":1.0,"Raw Hides":1.0,"Limestone":1.0,"Freshwater":1.0,"Fiber Plants":1.0,"Timber":1.0},true)
		var stocks:Dictionary=state.resource_stockpiles.duplicate(true)
		var result:=S.use(10,100,note());assert_float(float(result.progress)).is_equal(10.0)
		assert_dict(state.resource_stockpiles).is_equal(stocks)
		assert_bool("bookbinding_assemblies" in state.known_discoveries).is_false()
		assert_bool("clay_record_tablets" in state.known_discoveries).is_false()
	)
func test_daily_study_uses_only_arrived_records_and_remains_idempotent()->void:
	WorldSimulation.scoped("recorder",func()->void:
		var state=WorldSimulation.state;state.ensure_population_total(100);state.population_allocations.Knowledge=20;state.simulation_metrics.food_intake_ratio=1.0
		learn("clay_record_tablets");state.resource_stockpiles.merge({GOODS:1.0,"Clay":1.0,"Freshwater":1.0},true)
		E.data().collections.local_note=note();var later:=note();later.id="later";later.returned_day=100;E.data().collections.later=later
		var base:=state.effective_workers("Knowledge")*.15;E.advance(1)
		assert_float(float(E.data().collections.local_note.study)).is_equal_approx(base*1.15/100,.000001)
		assert_float(float(E.data().collections.later.study)).is_equal(0.0)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal_approx(1-base*float(S.bill("Clay Record Tablets")[GOODS]),.000001)
		var stock:=float(state.resource_stockpiles[GOODS]);E.advance(1);assert_float(float(state.resource_stockpiles[GOODS])).is_equal(stock)
		assert_bool("clay_shaping" in state.known_discoveries).is_false()
	)
func test_record_study_falls_back_to_clay_tablets_without_paper()->void:
	WorldSimulation.scoped("recorder",func()->void:
		var state=WorldSimulation.state;state.population_allocations.Knowledge=20;learn("clay_record_tablets")
		state.resource_stockpiles.merge({GOODS:10.0,"Clay":10.0,"Freshwater":10.0,"Timber":10.0,"Stone":10.0},true)
		E.data().collections.local_note=note()
		# Media are drawn from Civilian Goods; no study line is ever ordered.
		assert_dict(F.study_recommendation()).is_empty()
		assert_float(float(S.use(10,100,note()).progress)).is_equal(11.5)
		assert_float(float(state.resource_stockpiles[GOODS])).is_equal_approx(10-10*float(S.bill("Clay Record Tablets")[GOODS]),.000001)
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
