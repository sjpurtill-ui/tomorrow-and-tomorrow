extends GdUnitTestSuite
const F=preload("res://scripts/fracture_trial.gd")
const W=preload("res://scripts/fracture_workshop.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("fracture_work",1226)
func after_test()->void:WorldSimulation.clear()
func test_unqualified_geometry_and_missing_precracks_are_comparison_only()->void:
	var record:=W.evidence(4.5)
	assert_bool(F.measure(record).qualified).is_true()
	var thin:Dictionary=record.duplicate(true);thin.geometry.thickness=.001
	assert_bool(F.measure(thin).qualified).is_false()
	assert_str(F.measure(thin).classification).is_equal("comparison_only")
	var no_precrack:Dictionary=record.duplicate(true);no_precrack.precrack.cycles=0
	assert_bool(F.measure(no_precrack).qualified).is_false()
	var malformed:Dictionary=record.duplicate(true);malformed.trace[5].opening=malformed.trace[4].opening
	assert_bool(F.measure(malformed).qualified).is_false()
	malformed=record.duplicate(true);malformed.final_front=malformed.initial_front.duplicate()
	assert_bool(F.measure(malformed).qualified).is_false()
func test_paid_precrack_reload_and_actual_report_consumer()->void:
	WorldSimulation.scoped("fracture_work",func()->void:
		var state=WorldSimulation.state;var spec:=I.product("precracked_fracture_trials")
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
		state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
		for resource:String in spec.materials:state.resource_stockpiles[resource]=spec.materials[resource]
		for resource:String in spec.tooling:state.resource_stockpiles[resource]=10.0
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
		assert_bool(WorldSimulation.military.start_production_line("precracked_fracture_trials",1).get("ok",false)).is_true()
		var line:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,line,2)
		assert_int(line.fracture_pending.evidence.precrack.cycles).is_equal(500)
		assert_float(float(state.resource_stockpiles["Selected Medium-Carbon Steel"])).is_equal(0.0)
		var restored:Dictionary=bytes_to_var(var_to_bytes(line))
		assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
		var corrupt:Dictionary=restored.duplicate(true);corrupt.fracture_pending.evidence.precrack.cycles=1000
		assert_str(W.validate_job(corrupt,spec)).is_not_empty()
		Ops.data().services.electricity=0.0
		P.advance(WorldSimulation.military,restored,2.5)
		assert_float(float(restored.fracture_pending.work)).is_equal(2.0)
		Ops.data().services.electricity=100.0
		P.advance(WorldSimulation.military,restored,2.5)
		assert_str(W.validate_job(restored,spec)).is_empty()
		assert_bool(restored.fracture_last.report.qualified).is_true()
		assert_float(float(state.resource_stockpiles[spec.output])).is_equal(1.0)
		var consumer:=I.product("fracture_reference_stations")
		state.resource_stockpiles.Steel=1.0;state.resource_stockpiles["Fracture Loading Frames"]=1.0
		WorldSimulation.military.equipment_queue.clear()
		assert_bool(WorldSimulation.military.start_production_line("fracture_reference_stations",1).get("ok",false)).is_true()
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),2)
		assert_float(float(state.resource_stockpiles[spec.output])).is_equal(0.0)
		assert_float(float(state.resource_stockpiles[consumer.output])).is_equal(1.0)
	)
