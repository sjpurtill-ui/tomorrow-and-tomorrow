extends GdUnitTestSuite
const M=preload("res://scripts/vacuum_melt.gd")
const W=preload("res://scripts/vacuum_workshop.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("vacuum_work",1228)
func after_test()->void:WorldSimulation.clear()
func test_leak_sensitive_porosity_and_charge_mass_balance()->void:
	var sealed:=M.evidence(6,.001);var leaking:=M.evidence(6,5)
	assert_bool(M.inspect(M.witness(sealed)).qualified).is_true()
	assert_bool(M.inspect(M.witness(leaking)).qualified).is_false()
	assert_float(float(sealed.dissolved_gas)+float(sealed.headspace_gas)+float(sealed.exhausted_gas)).is_equal_approx(M.GAS,.0000001)
	assert_float(float(sealed.metal_mass)+float(sealed.vapor_loss)+M.GAS).is_equal_approx(M.CHARGE,.0000001)
	assert_float(float(sealed.exhausted_gas)).is_greater(0.0)
func test_paid_vacuum_melt_reloads_and_actual_wire_recipe_consumes_cast_metal()->void:
	WorldSimulation.scoped("vacuum_work",func()->void:
		var state=WorldSimulation.state;var spec:=I.product("vacuum_copper_casting")
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
		state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
		for resource:String in spec.materials:state.resource_stockpiles[resource]=spec.materials[resource]
		for resource:String in spec.tooling:state.resource_stockpiles[resource]=10.0
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":100.0}
		assert_bool(WorldSimulation.military.start_production_line("vacuum_copper_casting",1).get("ok",false)).is_true()
		var line:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,line,2.5)
		assert_float(float(state.resource_stockpiles["Refined Copper"])).is_equal(0.0)
		var restored:Dictionary=bytes_to_var(var_to_bytes(line))
		assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
		P.advance(WorldSimulation.military,restored,4)
		assert_str(W.validate_job(restored,spec)).is_empty()
		assert_bool(restored.vacuum_last.report.qualified).is_true()
		assert_float(float(state.resource_stockpiles[spec.output])).is_greater(1.0)
		var cast_mass:=float(state.resource_stockpiles[spec.output])
		var accounted:=cast_mass
		for material:String in ["Spent Vacuum Witness Sections","Copper Casting Sprues","Vacuum Metal Condensate","Extracted Melt Gas"]:accounted+=float(state.resource_stockpiles[material])
		assert_float(accounted).is_equal_approx(M.CHARGE,.0000001)
		var consumer:=I.product("vacuum_copper_motor_leads")
		state.known_discoveries.append(consumer.gate);state.discovery_adoption[consumer.gate]=1.0
		for resource:String in consumer.tooling:state.resource_stockpiles[resource]=10.0
		state.resource_stockpiles["Steel Tool Bits"]=1.0;state.resource_stockpiles[consumer.output]=0.0
		WorldSimulation.military.equipment_queue.clear()
		assert_bool(WorldSimulation.military.start_production_line("vacuum_copper_motor_leads",1).get("ok",false)).is_true()
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),3)
		assert_float(float(state.resource_stockpiles[spec.output])).is_equal_approx(cast_mass-1.0,.0000001)
		assert_float(float(state.resource_stockpiles[consumer.output])).is_equal(1.0)
	)
