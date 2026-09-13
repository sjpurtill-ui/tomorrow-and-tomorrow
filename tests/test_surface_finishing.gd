extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const M=preload("res://scripts/machine_workshop.gd")
const F=preload("res://scripts/surface_finish_measurement.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("surface_finish",1219)
func after_test()->void:WorldSimulation.clear()
func prepare(item:String)->Dictionary:
	var state=WorldSimulation.state;var spec:=I.product(item)
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
	state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
	for field:String in ["materials","tooling","machine_inspection"]:
		for resource:String in spec.get(field,{}):state.resource_stockpiles[resource]=100.0
	Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
	assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
	return WorldSimulation.military.equipment_queue.back()
func test_two_finishes_retain_motion_inspect_samples_and_enter_bearing_assemblies()->void:
	WorldSimulation.scoped("surface_finish",func()->void:
		for kind:String in ["honing","superfinishing"]:
			WorldSimulation.military.equipment_queue.clear()
			var line:=prepare(kind+"_qualified_parts");var spec:=I.product(line.item)
			P.advance(WorldSimulation.military,line,1.5)
			var restored:Dictionary=bytes_to_var(var_to_bytes(line))
			assert_str(M.validate_job(restored,spec)).is_empty()
			P.advance(WorldSimulation.military,restored,1.5)
			assert_int(restored.machine_pending.physical.strokes).is_equal(3 if kind=="honing" else 30)
			assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))).is_equal(0.0)
			P.advance(WorldSimulation.military,restored,1)
			assert_bool(restored.machine_last.accepted).is_true()
			assert_int(restored.machine_last.observation.surface_samples.size()).is_equal(32)
			assert_str(M.validate_job(restored,spec)).is_empty()
			var consumer:=I.product("honed_bearing_assemblies" if kind=="honing" else "superfinished_bearing_assemblies")
			var state=WorldSimulation.state
			state.known_discoveries.append(consumer.gate);state.discovery_adoption[consumer.gate]=1.0
			for field:String in ["materials","tooling"]:
				for resource:String in consumer[field]:
					if resource!=spec.output:state.resource_stockpiles[resource]=100.0
			state.resource_stockpiles[consumer.output]=0.0
			WorldSimulation.military.equipment_queue.clear()
			assert_bool(WorldSimulation.military.start_production_line("honed_bearing_assemblies" if kind=="honing" else "superfinished_bearing_assemblies",1).get("ok",false)).is_true()
			P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),1.5)
			assert_float(float(state.resource_stockpiles[spec.output])).is_equal(0.0)
			assert_float(float(state.resource_stockpiles[consumer.output])).is_equal(1.0)
	)
func test_worn_finishing_tool_fails_measured_surface_without_accepted_stock()->void:
	WorldSimulation.scoped("surface_finish",func()->void:
		var line:=prepare("superfinishing_qualified_parts");var spec:=I.product(line.item)
		line.machine_wear=2.0
		P.advance(WorldSimulation.military,line,3);P.advance(WorldSimulation.military,line,1)
		assert_bool(line.machine_last.accepted).is_false()
		assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles[spec.machine_reject])).is_equal(1.0)
		var changed:Dictionary=line.machine_last.physical.duplicate(true)
		changed.surface_trace.fill(0.0)
		assert_float(float(F.observed(changed,spec).readings.roughness_error)).is_equal(0.0)
		assert_float(float(line.machine_last.observation.readings.roughness_error)).is_greater(.5)
	)
