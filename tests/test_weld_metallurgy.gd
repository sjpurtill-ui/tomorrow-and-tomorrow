extends GdUnitTestSuite
const M=preload("res://scripts/weld_metallurgy.gd")
const W=preload("res://scripts/weld_workshop.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("weld_work",1227)
func after_test()->void:WorldSimulation.clear()
func test_joint_witness_distinguishes_cooling_and_incomplete_bond()->void:
	var controlled:=M.evidence(5,1)
	var quenched:=M.evidence(5,3)
	assert_bool(M.inspect(M.witness(controlled)).qualified).is_true()
	assert_bool(M.inspect(M.witness(quenched)).qualified).is_false()
	assert_bool(M.inspect(M.witness(M.evidence(1,1))).qualified).is_false()
	var observed:=M.witness(controlled)
	controlled.bond=0.0
	assert_bool(M.inspect(observed).qualified).is_true()
func test_paid_weld_reloads_and_actual_bearing_recipe_consumes_accepted_joint()->void:
	WorldSimulation.scoped("weld_work",func()->void:
		var state=WorldSimulation.state;var spec:=I.product("welded_strap_qualification")
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
		state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
		for resource:String in spec.materials:state.resource_stockpiles[resource]=spec.materials[resource]
		for resource:String in spec.tooling:state.resource_stockpiles[resource]=10.0
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
		assert_bool(WorldSimulation.military.start_production_line("welded_strap_qualification",1).get("ok",false)).is_true()
		var line:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,line,2.5)
		assert_float(float(state.resource_stockpiles["Selected Medium-Carbon Steel"])).is_equal(0.0)
		var restored:Dictionary=bytes_to_var(var_to_bytes(line))
		assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
		P.advance(WorldSimulation.military,restored,3)
		assert_str(W.validate_job(restored,spec)).is_empty()
		assert_bool(restored.weld_last.report.qualified).is_true()
		assert_float(float(state.resource_stockpiles[spec.output])).is_equal(1.0)
		var consumer:=I.product("welded_strap_bearing_frames")
		state.known_discoveries.append(consumer.gate);state.discovery_adoption[consumer.gate]=1.0
		for resource:String in consumer.tooling:state.resource_stockpiles[resource]=10.0
		state.resource_stockpiles["Steel Tool Bits"]=1.0;state.resource_stockpiles[consumer.output]=0.0
		WorldSimulation.military.equipment_queue.clear()
		assert_bool(WorldSimulation.military.start_production_line("welded_strap_bearing_frames",1).get("ok",false)).is_true()
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),3)
		assert_float(float(state.resource_stockpiles[spec.output])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles[consumer.output])).is_equal(1.0)
	)
