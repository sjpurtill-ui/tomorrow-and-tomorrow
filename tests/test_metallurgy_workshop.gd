extends GdUnitTestSuite
const M=preload("res://scripts/metallurgy_workshop.gd")
const T=preload("res://scripts/metallurgy_thermal_cycle.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Sections=preload("res://scripts/metallurgy_sections.gd")
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
func test_actual_normalizing_line_pays_section_and_supplies_a_shaft_consumer()->void:
	WorldSimulation.scoped("thermal_workshop",func()->void:
		var state=WorldSimulation.state
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
		var recipe:=I.product("normalizing_steel_sections")
		state.known_discoveries.append(recipe.gate);state.discovery_adoption[recipe.gate]=1.0
		for resource:String in recipe.tooling:state.resource_stockpiles[resource]=10.0
		for resource:String in Sections.COST:state.resource_stockpiles[resource]=10.0
		state.resource_stockpiles["Selected Medium-Carbon Steel"]=1.02
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":3000.0}
		assert_bool(WorldSimulation.military.start_production_line("normalizing_steel_sections",1).get("ok",false)).is_true()
		var line:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,line,1)
		assert_float(float(state.resource_stockpiles["Selected Medium-Carbon Steel"])).is_equal(0.0)
		assert_float(Ops.workshop_power_demand()).is_greater(0.0)
		P.advance(WorldSimulation.military,line,6)
		assert_float(float(state.resource_stockpiles.get(recipe.output,0))).is_equal(0.0)
		var held:Dictionary=line.metallurgy_pending.duplicate(true)
		var supplies:Dictionary=state.resource_stockpiles.duplicate(true)
		assert_str(P.state(WorldSimulation.military,line)).contains("grain-size measurement")
		P.advance(WorldSimulation.military,line,1)
		assert_dict(line.metallurgy_pending).is_equal(held)
		assert_dict(state.resource_stockpiles).is_equal(supplies)
		state.known_discoveries.append("metal_grain_size_measurement")
		state.discovery_adoption["metal_grain_size_measurement"]=.05
		assert_bool(Sections.available(recipe)).is_false()
		state.discovery_adoption["metal_grain_size_measurement"]=1.0
		P.advance(WorldSimulation.military,line,.25)
		var etchant:=float(state.resource_stockpiles["Steel Section Etchant"])
		var restored:Dictionary=bytes_to_var(var_to_bytes(line))
		assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
		P.advance(WorldSimulation.military,restored,.25)
		assert_str(M.validate_job(restored,recipe)).is_empty()
		assert_bool(restored.metallurgy_last.accepted).is_true()
		assert_float(float(state.resource_stockpiles[recipe.output])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Spent Metallographic Sections"])).is_equal(.02)
		assert_float(float(state.resource_stockpiles["Steel Section Etchant"])).is_equal(etchant)
		var consumer:=I.product("normalized_plain_shaft_blanks")
		state.known_discoveries.append(consumer.gate);state.discovery_adoption[consumer.gate]=1.0
		for resource:String in consumer.tooling:state.resource_stockpiles[resource]=10.0
		state.resource_stockpiles["Steel Tool Bits"]=10.0
		WorldSimulation.military.equipment_queue.clear()
		assert_bool(WorldSimulation.military.start_production_line("normalized_plain_shaft_blanks",1).get("ok",false)).is_true()
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),3)
		assert_float(float(state.resource_stockpiles[recipe.output])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles[consumer.output])).is_equal(1.0)
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
