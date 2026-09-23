extends GdUnitTestSuite
const C=preload("res://scripts/induction_case_cycle.gd")
const W=preload("res://scripts/induction_workshop.gd")
const I=preload("res://scripts/civilian_industry.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("induction_work",1224)
func after_test()->void:WorldSimulation.clear()
func test_surface_response_depends_on_coupling_and_history_cannot_be_rewritten()->void:
	var run:=C.start()
	for index:int in range(C.TICKS):C.step(run)
	assert_bool(C.valid(run)).is_true()
	assert_bool(C.accepted(C.indentation(run))).is_true()
	assert_float(float(run.peaks[0])).is_greater(800)
	assert_float(float(run.peaks[4])).is_less(800)
	var loose:=C.start(100,3)
	for index:int in range(C.TICKS):C.step(loose)
	assert_bool(C.accepted(C.indentation(loose))).is_false()
	run.transformed[4]=true
	assert_bool(C.valid(run)).is_false()
func test_small_labor_allocations_survive_reload_and_tempering_is_required()->void:
	WorldSimulation.scoped("induction_work",func()->void:
		var state=WorldSimulation.state;var spec:=I.product("induction_hardened_shafts")
		for resource:String in spec.materials:state.resource_stockpiles[resource]=spec.materials[resource]
		for resource:String in W.INSPECTION:state.resource_stockpiles[resource]=10.0
		state.resource_stockpiles.Freshwater=3.0
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
		var line:Dictionary={"id":1,"item":"induction_hardened_shafts","completed":0,"target_stock":1,"tooling_paid":true,"tooling":spec.tooling.duplicate(true),"last_consumed":{},"last_work":0.0,"progress_days":0.0}
		W.advance(line,spec,.01)
		assert_int(line.induction_pending.run.tick).is_equal(0)
		assert_str(W.validate_job(line,spec)).is_empty()
		line=bytes_to_var(var_to_bytes(line))
		for index:int in range(549):W.advance(line,spec,.01)
		assert_str(W.validate_job(line,spec)).is_empty()
		assert_bool(line.induction_last.accepted).is_true()
		assert_float(float(line.last_work)).is_equal_approx(5.5,.000001)
		assert_float(Ops.service("electricity")).is_equal_approx(83.6,.000001)
		var run:=C.start()
		for index:int in range(40):C.step(run)
		assert_bool(C.accepted(C.indentation(run))).is_false()
		for index:int in range(60):C.step(run)
		assert_bool(C.accepted(C.indentation(run))).is_true()
	)

func test_calendar_outage_cools_hot_case_and_cannot_substitute_for_quench()->void:
	var run:=C.start()
	for index:int in range(20):C.step(run)
	var hot:=float(run.temperatures[0])
	C.idle(run,1)
	assert_float(float(run.temperatures[0])).is_less(hot)
	assert_bool(C.valid(run)).is_true()
	for index:int in range(C.TICKS-20):C.step(run)
	assert_bool(C.accepted(C.indentation(run))).is_false()
	assert_bool(C.valid(run)).is_true()
	WorldSimulation.scoped("induction_work",func()->void:
		var state=WorldSimulation.state;var hot_run:=C.start()
		for index:int in range(20):C.step(hot_run)
		var line:Dictionary={"paused":true,"induction_pending":{"run":hot_run,"site":state.resource_settlement_id,"last_day":int(state.elapsed_days)}}
		state.elapsed_days+=1
		W.synchronize_idle(line,0)
		assert_int(line.induction_pending.run.trace.back().idle_days).is_equal(1)
		var retained:Dictionary=line.duplicate(true)
		W.synchronize_idle(line,0)
		assert_dict(line).is_equal(retained)
		assert_bool(C.valid(line.induction_pending.run)).is_true()
		state.elapsed_days+=1
		W.synchronize_idle(line,0)
		assert_int(line.induction_pending.run.trace.back().idle_days).is_equal(2)
		assert_bool(C.valid(line.induction_pending.run)).is_true()
	)
