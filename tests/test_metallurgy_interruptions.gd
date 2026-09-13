extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func test_calendar_interruptions_survive_reload_without_duplicate_cooling()->void:
	for kind:String in ["weld","vacuum"]:
		WorldSimulation.clear();WorldSimulation.create_actor("interrupt",187)
		WorldSimulation.scoped("interrupt",func()->void:
			var state=WorldSimulation.state
			var recipe:="welded_strap_qualification" if kind=="weld" else "vacuum_copper_casting"
			var spec:=I.product(recipe)
			state.settlement_site_committed=true;state.convoy_traveling=false
			state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
			state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
			for resource:String in spec.materials:state.resource_stockpiles[resource]=spec.materials[resource]
			for resource:String in spec.tooling:state.resource_stockpiles[resource]=10.0
			Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
			assert_bool(WorldSimulation.military.start_production_line(recipe,1).get("ok",false)).is_true()
			var line:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,line,2.5)
			var key:=kind+"_pending"
			var hot:Dictionary=line[key].evidence.duplicate(true)
			line.paused=true;state.elapsed_days+=3
			P.advance(WorldSimulation.military,line,1)
			var cold:Dictionary=line[key].evidence.duplicate(true)
			assert_float(float(line[key].work)).is_equal(2.5)
			if kind=="weld":assert_float(float(cold.temperatures[0])).is_less(float(hot.temperatures[0]))
			else:
				assert_float(float(cold.temperature)).is_less(float(hot.temperature))
				assert_float(float(cold.pressure)).is_greater(float(hot.pressure))
			P.advance(WorldSimulation.military,line,1)
			assert_bool(line[key].evidence==cold).is_true()
			line=bytes_to_var(var_to_bytes(line))
			assert_str(P.validate_saved({"equipment_queue":[line]})).is_empty()
			line.paused=false;state.elapsed_days+=2
			Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":0.0}
			P.advance(WorldSimulation.military,line,1)
			assert_int(int(line[key].pauses[0].days)).is_equal(5)
			assert_float(float(line[key].energy)).is_equal(5.0)
			Ops.data().services={"electricity":100.0}
			P.advance(WorldSimulation.military,line,4)
			assert_bool(line.has(kind+"_last")).is_true()
			assert_str(P.validate_saved({"equipment_queue":[line]})).is_empty()
		)
	WorldSimulation.clear()
