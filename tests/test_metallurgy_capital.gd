extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const ITEMS=["vacuum_melting_chambers", "fracture_loading_frames", "fracture_reference_stations", "slitting_measurement_sets", "calibrated_slitting_stations", "induction_shaft_stations", "section_indentation_sets", "foam_pattern_molding_sets", "casting_ventilation_sets", "alloy_phase_trial_sets", "surface_trace_comparators", "honing_head_sets", "superfinishing_head_sets", "metal_treatment_furnace", "reflected_metal_microscope", "metal_section_preparation_sets", "material_vacuum_pump_sets"]
func test_apparatus_fabrication_uses_daily_generator_and_paid_inputs()->void:
	for item:String in ITEMS:
		WorldSimulation.clear();WorldSimulation.create_actor("capital",1834)
		WorldSimulation.scoped("capital",func()->void:
			var state=WorldSimulation.state;var spec:=I.product(item)
			state.settlement_site_committed=true;state.convoy_traveling=false
			state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
			state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
			for gate:String in [String(spec.gate),"electrical_generators","steam_propulsion","workshop_standards"]:
				state.known_discoveries.append(gate);state.discovery_adoption[gate]=1.0
			for resource:String in Ops.PLANTS.steam_generator.cost:state.resource_stockpiles[resource]=100.0
			state.resource_stockpiles.Coal=100.0;state.resource_stockpiles.Freshwater=100.0
			assert_bool(Ops.install("steam_generator").get("ok",false)).is_true()
			for day:int in range(1,11):state.elapsed_days=day;Ops.advance(day)
			for field:String in ["materials","tooling"]:
				for resource:String in spec[field]:state.resource_stockpiles[resource]=100.0
			state.resource_stockpiles[spec.output]=0.0
			assert_bool(WorldSimulation.military.start_production_line(item,1).get("ok",false)).is_true()
			var line:Dictionary=WorldSimulation.military.equipment_queue.back()
			var start_stocks:Dictionary=state.resource_stockpiles.duplicate(true)
			var coal:=float(state.resource_stockpiles.Coal)
			var spent:Dictionary={}
			for day:int in range(11,211):
				state.elapsed_days=day;Ops.advance(day)
				WorldSimulation.military._process_equipment_production_day()
				for resource:String in line.last_consumed:spent[resource]=float(spent.get(resource,0))+float(line.last_consumed[resource])
				if int(line.completed)>0:break
				assert_float(float(state.resource_stockpiles[spec.output])).is_equal(0.0)
			assert_int(int(line.completed)).is_equal(1)
			assert_float(float(state.resource_stockpiles[spec.output])).is_equal(1.0)
			assert_float(float(state.resource_stockpiles.Coal)).is_less(coal)
			for resource:String in spec.materials:
				assert_float(float(spent.get(resource,0))).is_equal_approx(float(spec.materials[resource]),.000001)
				if resource not in ["Coal","Freshwater"]:assert_float(float(state.resource_stockpiles[resource])).is_equal_approx(float(start_stocks[resource])-float(spec.materials[resource]),.000001)
			assert_str(P.validate_saved({"equipment_queue":[line]})).is_empty()
		)
	WorldSimulation.clear()
