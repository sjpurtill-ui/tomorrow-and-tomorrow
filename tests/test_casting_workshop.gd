extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const C=preload("res://scripts/casting_workshop.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("casting_work",1223)
func after_test()->void:WorldSimulation.clear()
func prepare(item:String)->Dictionary:
	var state=WorldSimulation.state;var spec:=I.product(item)
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
	state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
	for resource:String in spec.materials:state.resource_stockpiles[resource]=float(spec.materials[resource])
	for resource:String in spec.tooling:state.resource_stockpiles[resource]=10.0
	state.resource_stockpiles[spec.output]=0.0
	Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
	assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
	return WorldSimulation.military.equipment_queue.back()
func test_distinct_casting_routes_resume_paid_molds_and_supply_machined_bearings()->void:
	WorldSimulation.scoped("casting_work",func()->void:
		for kind:String in ["investment","lost_foam"]:
			WorldSimulation.military.equipment_queue.clear()
			var line:=prepare(kind+"_copper_brackets");var spec:=I.product(line.item)
			P.advance(WorldSimulation.military,line,.75)
			assert_float(float(WorldSimulation.state.resource_stockpiles["EPS Casting Patterns"])).is_equal(0.0)
			var restored:Dictionary=bytes_to_var(var_to_bytes(line))
			assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
			P.advance(WorldSimulation.military,restored,float(spec.days)-.75)
			assert_str(C.validate_job(restored,spec)).is_empty()
			assert_bool(restored.casting_last.accepted).is_true()
			assert_float(float(restored.casting_last.pour_pattern_mass)).is_equal(0.0 if kind=="investment" else 1.0)
			assert_int(restored.casting_last.shell_layers).is_equal(3 if kind=="investment" else 1)
			var state=WorldSimulation.state
			assert_float(float(state.resource_stockpiles[spec.output])).is_equal(1.0)
			var consumer:=I.product("cast_bracket_bearings")
			state.known_discoveries.append(consumer.gate);state.discovery_adoption[consumer.gate]=1.0
			for resource:String in consumer.tooling:state.resource_stockpiles[resource]=10.0
			state.resource_stockpiles["Steel Tool Bits"]=1.0;state.resource_stockpiles[consumer.output]=0.0
			WorldSimulation.military.equipment_queue.clear()
			assert_bool(WorldSimulation.military.start_production_line("cast_bracket_bearings",1).get("ok",false)).is_true()
			P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),3)
			assert_float(float(state.resource_stockpiles[spec.output])).is_equal(0.0)
			assert_float(float(state.resource_stockpiles[consumer.output])).is_equal(1.0)
	)
func test_worn_casting_setup_rejects_and_underpaid_stage_cannot_advance()->void:
	WorldSimulation.scoped("casting_work",func()->void:
		var line:=prepare("investment_copper_brackets");var spec:=I.product(line.item)
		line.casting_wear=2.0
		P.advance(WorldSimulation.military,line,4.5)
		assert_int(line.casting_pending.stage).is_equal(6)
		Ops.data().services.electricity=0.0
		P.advance(WorldSimulation.military,line,2)
		assert_int(line.casting_pending.stage).is_equal(6)
		Ops.data().services.electricity=100.0
		P.advance(WorldSimulation.military,line,float(spec.days)-4.5)
		assert_bool(line.casting_last.accepted).is_false()
		assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles[spec.casting_reject])).is_equal(1.0)
	)

func test_casting_saved_materials_must_follow_paid_stage_history()->void:
	WorldSimulation.scoped("casting_work",func()->void:
		var line:=prepare("investment_copper_brackets");var spec:=I.product(line.item)
		P.advance(WorldSimulation.military,line,.75)
		for field:String in ["moisture","pattern_mass","evaporated_water","shell_layers"]:
			var altered:Dictionary=line.duplicate(true)
			altered.casting_pending[field]+=1
			assert_str(C.validate_job(altered,spec)).is_not_empty()
		P.advance(WorldSimulation.military,line,float(spec.days)-.75)
		assert_str(C.validate_job(line,spec)).is_empty()
		var altered:Dictionary=line.duplicate(true)
		altered.casting_last.pour_temperature=1000.0
		altered.casting_last.observation.readings=C.readings(altered.casting_last,spec)
		altered.casting_last.accepted=C.accepted(altered.casting_last.observation.readings)
		assert_str(C.validate_job(altered,spec)).is_not_empty()
		altered=line.duplicate(true)
		altered.casting_last.run.temperature=20.0
		altered.casting_last.observation.readings=C.readings(altered.casting_last,spec)
		altered.casting_last.accepted=C.accepted(altered.casting_last.observation.readings)
		assert_str(C.validate_job(altered,spec)).is_not_empty()
		altered=line.duplicate(true)
		altered.casting_last.trace[0].pattern_remaining=0.0
		assert_str(C.validate_job(altered,spec)).is_not_empty()
	)

func test_cast_metal_retains_heat_until_cooling_and_paused_days_do_not_add_work()->void:
	WorldSimulation.scoped("casting_work",func()->void:
		for kind:String in ["investment","lost_foam"]:
			WorldSimulation.military.equipment_queue.clear()
			var line:=prepare(kind+"_copper_brackets");var spec:=I.product(line.item)
			var before_cooling:=0.0
			for stage:Dictionary in spec.casting_stages:
				if stage.kind=="cool":break
				before_cooling+=float(stage.work)
			P.advance(WorldSimulation.military,line,before_cooling)
			assert_float(float(line.casting_pending.run.temperature)).is_greater(1000.0)
			assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).is_equal(0.0)
			var progress:=float(line.progress_days)
			var stocks:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			line.paused=true;WorldSimulation.state.elapsed_days+=3
			P.advance(WorldSimulation.military,line,1)
			assert_float(float(line.casting_pending.run.temperature)).is_less(150.0)
			assert_float(float(line.progress_days)).is_equal(progress)
			assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stocks)
			var cooled:Dictionary=line.duplicate(true)
			P.advance(WorldSimulation.military,line,1)
			assert_dict(line.casting_pending).is_equal(cooled.casting_pending)
			line=bytes_to_var(var_to_bytes(line));line.paused=false
			assert_str(C.validate_job(line,spec)).is_empty()
			Ops.data().last_day=int(WorldSimulation.state.elapsed_days);Ops.data().services={"electricity":100.0}
			P.advance(WorldSimulation.military,line,float(spec.days)-before_cooling)
			assert_bool(line.casting_last.accepted).is_true()
			assert_float(float(line.casting_last.observation.readings.temperature)).is_less(150.0)
			assert_str(C.validate_job(line,spec)).is_empty()
	)

func test_brief_hot_burnout_cannot_remove_pattern_before_an_interruption()->void:
	WorldSimulation.scoped("casting_work",func()->void:
		var line:=prepare("investment_copper_brackets");var spec:=I.product(line.item)
		P.advance(WorldSimulation.military,line,6.3)
		assert_str(spec.casting_stages[int(line.casting_pending.stage)].kind).is_equal("burnout")
		assert_float(float(line.casting_pending.run.peak)).is_equal_approx(850,.000001)
		assert_float(C.burnout_remaining(line.casting_pending.run)).is_greater(.1)
		line.paused=true;WorldSimulation.state.elapsed_days+=100
		P.advance(WorldSimulation.military,line,1)
		line=bytes_to_var(var_to_bytes(line));line.paused=false
		assert_str(C.validate_job(line,spec)).is_empty()
		Ops.data().last_day=int(WorldSimulation.state.elapsed_days);Ops.data().services={"electricity":100.0}
		P.advance(WorldSimulation.military,line,float(spec.days)-6.3)
		assert_float(float(line.casting_last.pour_pattern_mass)).is_greater(.1)
		assert_bool(line.casting_last.accepted).is_false()
		assert_float(float(WorldSimulation.state.resource_stockpiles[spec.casting_reject])).is_equal(1.0)
		assert_str(C.validate_job(line,spec)).is_empty()
	)
