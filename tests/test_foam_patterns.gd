extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const F=preload("res://scripts/foam_pattern_measurement.gd")
func test_paid_measured_patterns_reject_worn_molds_and_feed_actual_casting()->void:
	for wear:float in [0.0,1.0]:
		WorldSimulation.clear();WorldSimulation.create_actor("patterns",1866)
		WorldSimulation.scoped("patterns",func()->void:
			var state=WorldSimulation.state;var spec:=I.product("expanded_casting_patterns")
			state.settlement_site_committed=true;state.convoy_traveling=false
			state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
			state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
			for resource:String in spec.materials:state.resource_stockpiles[resource]=spec.materials[resource]
			for resource:String in spec.tooling:state.resource_stockpiles[resource]=10.0
			Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
			assert_bool(WorldSimulation.military.start_production_line("expanded_casting_patterns",1).get("ok",false)).is_true()
			var line:Dictionary=WorldSimulation.military.equipment_queue.back();line.pattern_wear=wear
			P.advance(WorldSimulation.military,line,2)
			assert_float(float(state.resource_stockpiles.get(spec.output,0))).is_equal(0.0)
			assert_float(float(state.resource_stockpiles["Pattern Polystyrene Pellets"])).is_equal(0.0)
			var restored:Dictionary=bytes_to_var(var_to_bytes(line))
			assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
			P.advance(WorldSimulation.military,restored,2)
			assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
			assert_bool(restored.pattern_last.report.qualified).is_equal(wear==0)
			assert_float(float(state.resource_stockpiles.get(spec.output,0))).is_equal(1.0 if wear==0 else 0.0)
			assert_float(float(state.resource_stockpiles.get("Rejected EPS Patterns",0))).is_equal(0.0 if wear==0 else 1.0)
			var corrupted:Dictionary=restored.duplicate(true);corrupted.pattern_last.witness.volume=2.0
			assert_str(P.validate_saved({"equipment_queue":[corrupted]})).is_not_empty()
			if wear==0:
				var casting:=I.product("lost_foam_copper_brackets")
				state.known_discoveries.append(casting.gate);state.discovery_adoption[casting.gate]=1.0
				for resource:String in casting.materials:
					if resource!=spec.output:state.resource_stockpiles[resource]=casting.materials[resource]
				for resource:String in casting.tooling:state.resource_stockpiles[resource]=10.0
				WorldSimulation.military.equipment_queue.clear()
				assert_bool(WorldSimulation.military.start_production_line("lost_foam_copper_brackets",1).get("ok",false)).is_true()
				P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),.5)
				assert_float(float(state.resource_stockpiles[spec.output])).is_equal(0.0)
		)
	WorldSimulation.clear()
func test_interruption_changes_expansion_without_changing_observer_inputs()->void:
	var normal:=F.evidence(4,0)
	var interrupted:=F.evidence(4,0,[{"work":1.5,"days":100}])
	assert_bool(F.inspect(F.witness(normal)).qualified).is_true()
	assert_bool(F.inspect(F.witness(interrupted)).qualified).is_false()
	var measured:=F.witness(normal)
	normal.expansion=0.0
	assert_bool(F.inspect(measured).qualified).is_true()
