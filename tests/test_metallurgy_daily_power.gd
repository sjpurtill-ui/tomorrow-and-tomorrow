extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const ITEMS=["normalizing_steel_sections","induction_hardened_shafts","investment_copper_brackets","lost_foam_copper_brackets","lead_tin_phase_survey","honing_qualified_parts","superfinishing_qualified_parts","residual_slitting_surveys","precracked_fracture_trials","welded_strap_qualification","vacuum_copper_casting"]
func before_test()->void:
	WorldSimulation.clear()
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func test_commissioned_generator_supplies_actual_daily_production_without_injected_services()->void:
	for index:int in range(ITEMS.size()):
		var actor:="metal_daily_%d"%index
		WorldSimulation.create_actor(actor,1500+index)
		WorldSimulation.scoped(actor,func()->void:
			var spec:=I.product(ITEMS[index]);var state=WorldSimulation.state
			state.settlement_site_committed=true;state.convoy_traveling=false
			state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
			state.population_health=1.0;state.simulation_metrics.labor_efficiency=1.0
			for gate:String in [String(spec.gate),"electrical_generators","steam_propulsion","workshop_standards"]:
				state.known_discoveries.append(gate);state.discovery_adoption[gate]=1.0
			for field:String in ["materials","tooling","machine_inspection"]:
				for resource:String in spec.get(field,{}):state.resource_stockpiles[resource]=100.0
			for resource:String in ["Steel Tool Bits","Graded Alumina Abrasive","Steel Section Etchant","Woven Cloth","Freshwater","Paper"]:state.resource_stockpiles[resource]=100.0
			for resource:String in Ops.PLANTS.steam_generator.cost:state.resource_stockpiles[resource]=100.0
			state.resource_stockpiles.Coal=100.0
			assert_bool(Ops.install("steam_generator").get("ok",false)).is_true()
			for day:int in range(1,11):state.elapsed_days=day;Ops.advance(day)
			assert_int(int(Ops.data().plants.steam_generator.installed)).is_equal(1)
			# Keep precisely one batch of feed. Ongoing demand must use the reserved workpiece.
			for resource:String in spec.materials:state.resource_stockpiles[resource]=float(spec.materials[resource])
			# Inspection and cooling supplies may also be separate operating inputs.
			for resource:String in ["Steel Tool Bits","Graded Alumina Abrasive","Steel Section Etchant","Woven Cloth","Freshwater","Paper"]:state.resource_stockpiles[resource]=100.0
			assert_bool(WorldSimulation.military.start_production_line(ITEMS[index],1).get("ok",false)).is_true()
			var line:Dictionary=WorldSimulation.military.equipment_queue.back()
			var completed_day:=0
			for day:int in range(11,211):
				state.elapsed_days=day;Ops.advance(day)
				WorldSimulation.military._process_equipment_production_day()
				if int(line.completed)>0:completed_day=day;break
			assert_int(completed_day).override_failure_message(ITEMS[index]+" stalled: "+str(line.progress_days)).is_greater(0)
			assert_float(float(state.resource_stockpiles.get(spec.output,0))).override_failure_message(ITEMS[index]+" did not yield accepted output").is_greater(0.0)
			assert_float(float(state.resource_stockpiles.Coal)).is_less(100.0)
			assert_str(P.validate_saved({"equipment_queue":[line]})).override_failure_message(ITEMS[index]).is_empty()
		)
