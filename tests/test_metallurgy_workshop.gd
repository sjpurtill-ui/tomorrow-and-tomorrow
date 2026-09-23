extends GdUnitTestSuite
const M=preload("res://scripts/metallurgy_workshop.gd")
const T=preload("res://scripts/metallurgy_thermal_cycle.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("thermal_workshop",1217)
func after_test()->void:WorldSimulation.clear()
func spec()->Dictionary:
	return {"output":"Inspected Normalized Steel","materials":{"Steel":1.0},
		"tooling":{"Thermal Treatment Furnaces":1},"thermal_capacity":1.0,
		"thermal_program":T.normalizing_program()}
func job()->Dictionary:
	return {"id":1,"item":"test_normalizing","completed":0,"target_stock":1,
		"tooling_paid":true,"tooling":{"Thermal Treatment Furnaces":1},
		"last_consumed":{},"last_work":0.0,"progress_days":0.0}
func test_last_feed_is_retained_across_outage_and_reload_without_early_output()->void:
	WorldSimulation.scoped("thermal_workshop",func()->void:
		WorldSimulation.state.resource_stockpiles["Steel"]=1.0
		Ops.data().last_day=int(WorldSimulation.state.elapsed_days)
		Ops.data().services={"electricity":3000.0}
		var line:=job();var recipe:=spec()
		M.advance(line,recipe,1)
		assert_float(float(WorldSimulation.state.resource_stockpiles.Steel)).is_equal(0.0)
		assert_float(float(line.metallurgy_pending.run.temperature)).is_greater(20.0)
		var retained:=line.duplicate(true)
		Ops.data().services.electricity=0.0
		M.advance(line,recipe,2)
		assert_dict(line).is_equal(retained)
		var restored:Dictionary=bytes_to_var(var_to_bytes(line))
		assert_str(M.validate_job(restored,recipe)).is_empty()
		Ops.data().services.electricity=3000.0
		M.advance(restored,recipe,6)
		assert_str(restored.metallurgy_pending.phase).is_equal("inspection")
		assert_str(M.validate_job(restored,recipe)).is_empty()
		assert_float(float(WorldSimulation.state.resource_stockpiles.Steel)).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get(recipe.output,0))).is_equal(0.0)
		M.advance(restored,recipe,100)
		assert_float(float(WorldSimulation.state.resource_stockpiles.get(recipe.output,0))).is_equal(0.0)
	)
func test_unpaid_apparatus_blocks_reservation_and_retooling_does_not_refund()->void:
	WorldSimulation.scoped("thermal_workshop",func()->void:
		WorldSimulation.state.resource_stockpiles["Steel"]=1.0
		Ops.data().last_day=int(WorldSimulation.state.elapsed_days)
		Ops.data().services={"electricity":3000.0}
		var line:=job();var recipe:=spec()
		line.tooling_paid=false
		M.advance(line,recipe,1)
		assert_bool(line.has("metallurgy_pending")).is_false()
		assert_float(float(WorldSimulation.state.resource_stockpiles.Steel)).is_equal(1.0)
		line.tooling_paid=true
		M.advance(line,recipe,1)
		var corrupt:=line.duplicate(true);corrupt.metallurgy_pending.ordinal+=1
		assert_str(M.validate_job(corrupt,recipe)).is_not_empty()
		M.clear(line)
		assert_bool(line.has("metallurgy_pending")).is_false()
		assert_float(float(WorldSimulation.state.resource_stockpiles.Steel)).is_equal(0.0)
	)
func test_idle_calendar_cools_without_paying_or_satisfying_hot_work()->void:
	WorldSimulation.scoped("thermal_workshop",func()->void:
		var state=WorldSimulation.state
		state.resource_stockpiles.Steel=1.0
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":3000.0}
		var line:=job();var recipe:=spec()
		M.advance(line,recipe,3)
		var before:Dictionary=line.metallurgy_pending.run.duplicate(true)
		line.paused=true;state.elapsed_days+=100
		M.synchronize_idle(line,0)
		assert_float(float(line.metallurgy_pending.run.temperature)).is_less(30.0)
		for field:String in ["work","energy","coolant","hot_work"]:
			assert_float(float(line.metallurgy_pending.run[field])).is_equal(float(before[field]))
		var idle:Dictionary=line.duplicate(true)
		M.synchronize_idle(line,0)
		assert_dict(line).is_equal(idle)
		line=bytes_to_var(var_to_bytes(line));line.paused=false
		assert_str(M.validate_job(line,recipe)).is_empty()
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":3000.0}
		M.advance(line,recipe,4)
		assert_str(line.metallurgy_pending.phase).is_equal("inspection")
		assert_float(float(line.metallurgy_pending.run.hot_work)).is_equal(float(before.hot_work))
		var uninterrupted:=T.start(recipe.thermal_program)
		T.advance(uninterrupted,7,3000,0)
		assert_float(float(line.metallurgy_pending.run.hot_work)).is_less(float(uninterrupted.hot_work))
		assert_float(float(line.metallurgy_pending.run.longest_hold)).is_equal(0.0)
		assert_float(float(uninterrupted.longest_hold)).is_equal_approx(1.0,.000001)
		assert_str(M.validate_job(line,recipe)).is_empty()
	)
