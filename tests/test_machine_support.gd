extends GdUnitTestSuite
const S=preload("res://scripts/machine_support.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("machine_support",1212)
func after_test()->void:WorldSimulation.clear()
func line()->Dictionary:return {"completed":0,"last_work":0.0,"last_consumed":{},"machine_wear":1.0}
func test_paid_deterioration_measurement_requires_repair_and_recheck()->void:
	WorldSimulation.scoped("machine_support",func()->void:
		var state=WorldSimulation.state
		state.known_discoveries.append_array(["machine_tool_stiffness_assessment","machine_condition_monitoring"])
		state.resource_stockpiles={"Machine Load Test Sets":1.0,"Machine Vibration Test Sets":1.0,"Paper":1.0,"Refined Copper":1.0}
		var job:=line()
		assert_float(S.prepare(job,{},2)).is_equal(0.0)
		assert_bool(job.machine_support.repair_needed).is_true()
		assert_float(float(job.machine_wear)).is_equal(1.0)
		state.resource_stockpiles.Steel=1.0;state.resource_stockpiles.Graphite=1.0
		S.prepare(job,{},.25)
		assert_float(float(job.machine_support.repair_work)).is_equal(.25)
		var restored:Dictionary=bytes_to_var(var_to_bytes(job))
		S.prepare(restored,{},.25)
		assert_float(float(restored.machine_wear)).is_equal(.05)
		assert_float(float(state.resource_stockpiles.Steel)).is_equal(.8)
		assert_float(S.prepare(restored,{},1)).is_equal(.5)
		assert_bool(restored.machine_support.observations[-1].failed).is_false()
	)
func test_water_film_and_filter_require_actual_fluid_and_discard_spent_water()->void:
	WorldSimulation.scoped("machine_support",func()->void:
		var state=WorldSimulation.state
		state.known_discoveries.append_array(["fluid_film_bearings","cutting_fluid_management"])
		state.resource_stockpiles={"Water-Film Bearing Sets":1.0,"Machining Water Filter Sets":1.0}
		var job:=line();S.prepare(job,{},1)
		assert_float(S.limit_work(job,2)).is_equal(0.0)
		state.resource_stockpiles.Freshwater=.3;state.resource_stockpiles["Woven Cloth"]=1.0
		var possible:=S.limit_work(job,4)
		assert_float(possible).is_equal_approx(2.0,.000001)
		S.consume(job,possible)
		assert_float(float(state.resource_stockpiles.Freshwater)).is_equal_approx(0.0,.000001)
		assert_float(float(state.resource_stockpiles["Spent Machining Water"])).is_equal_approx(.2,.000001)
	)
func test_small_measurement_work_accumulates_without_rebuying_observations()->void:
	WorldSimulation.scoped("machine_support",func()->void:
		var state=WorldSimulation.state
		state.known_discoveries.append("machine_tool_stiffness_assessment")
		state.resource_stockpiles={"Machine Load Test Sets":1.0,"Paper":1.0,"Refined Copper":1.0}
		var job:=line();job.machine_wear=0.0
		S.prepare(job,{},.25)
		S.prepare(job,{},.1);S.prepare(job,{},.1);S.prepare(job,{},.1)
		assert_int(job.machine_support.observations.size()).is_equal(1)
		assert_float(float(state.resource_stockpiles.Paper)).is_equal(.99)
	)
