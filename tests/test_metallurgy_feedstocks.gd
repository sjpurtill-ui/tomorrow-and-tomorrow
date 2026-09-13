extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const CHAIN=["metallographic_nitric_acid","metallographic_nital","reflected_metal_microscope","metal_section_preparation_sets","material_vacuum_pump_sets","separated_pattern_benzene","pattern_ethylbenzene","styrene_iron_oxide","styrene_promoter_salts","qualified_styrene_catalyst","crude_pattern_styrene","purified_pattern_styrene","thermal_pattern_polystyrene","devolatilized_pattern_polystyrene","pattern_pentane"]
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("metallurgy_feed",1215)
func after_test()->void:WorldSimulation.clear()
func prepare(item:String)->Dictionary:
	var state=WorldSimulation.state
	state.settlement_site_committed=true;state.convoy_traveling=false
	state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
	var spec:=I.product(item)
	state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
	for field:String in ["materials","tooling"]:
		for resource:String in spec[field]:state.resource_stockpiles[resource]=100.0
	state.resource_stockpiles[spec.output]=0.0
	Ops.data().last_day=int(state.elapsed_days)
	Ops.data().services={"electricity":100.0,"polymer_stirred_work":10.0,"polymer_heat_removal":10.0}
	var result:Dictionary=WorldSimulation.military.start_production_line(item,1)
	assert_bool(result.get("ok",false)).override_failure_message(str(result)).is_true()
	return WorldSimulation.military.equipment_queue.back() if result.get("ok",false) else {}
func test_precursor_work_retains_partial_progress_and_pays_feed_once()->void:
	WorldSimulation.scoped("metallurgy_feed",func()->void:
		for item:String in CHAIN:
			WorldSimulation.military.equipment_queue.clear()
			var line:=prepare(item);var spec:=I.product(item)
			var before:Dictionary=WorldSimulation.state.resource_stockpiles.duplicate(true)
			P.advance(WorldSimulation.military,line,float(spec.days)/2)
			assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).is_equal(0.0)
			var restored:Dictionary=bytes_to_var(var_to_bytes(line))
			assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
			P.advance(WorldSimulation.military,restored,float(spec.days)/2)
			assert_float(float(WorldSimulation.state.resource_stockpiles[spec.output])).is_equal(1.0)
			for resource:String in spec.materials:
				assert_float(float(WorldSimulation.state.resource_stockpiles[resource])).is_equal_approx(float(before[resource])-float(spec.materials[resource]),.000001)
	)
func test_styrene_polymerization_waits_for_actual_cooling_capacity()->void:
	WorldSimulation.scoped("metallurgy_feed",func()->void:
		var line:=prepare("thermal_pattern_polystyrene")
		var before:=float(WorldSimulation.state.resource_stockpiles["Pattern-Grade Styrene"])
		Ops.data().services.polymer_heat_removal=0.0
		P.advance(WorldSimulation.military,line,7)
		assert_float(float(line.progress_days)).is_equal(0.0)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Pattern-Grade Styrene"])).is_equal(before)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Raw Pattern Polystyrene"])).is_equal(0.0)
		Ops.data().services.polymer_heat_removal=2.0
		P.advance(WorldSimulation.military,line,7)
		assert_float(float(WorldSimulation.state.resource_stockpiles["Raw Pattern Polystyrene"])).is_equal(1.0)
		assert_float(Ops.service("polymer_heat_removal")).is_equal(0.0)
	)
