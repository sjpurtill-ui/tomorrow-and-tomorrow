extends GdUnitTestSuite
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
const CASES=[
	["normalizing_steel_sections",1.0],["induction_hardened_shafts",.01],
	["investment_copper_brackets",.75],["lost_foam_copper_brackets",.75],
	["lead_tin_phase_survey",7.0],["honing_qualified_parts",1.0],
	["superfinishing_qualified_parts",1.0],["residual_slitting_surveys",2.5],
	["precracked_fracture_trials",2.0],["welded_strap_qualification",2.5],
	["vacuum_copper_casting",2.5],["external_residual_assessment",2.5],["external_fracture_assessment",2.0]]
func before_test()->void:
	GameState.set_process(false);CivilizationSystem.set_process(false);MilitaryCampaign.set_process(false)
	WorldSimulation.clear()
func after_test()->void:
	WorldSimulation.clear()
	GameState.set_process(true);CivilizationSystem.set_process(true);MilitaryCampaign.set_process(true)
func test_full_game_save_preserves_retained_processes_and_resumes_outputs()->void:
	var pending:Dictionary={};var stocks:Dictionary={};var queues:Dictionary={}
	for index:int in range(CASES.size()):
		var actor:="metal_save_%d"%index
		WorldSimulation.create_actor(actor,1300+index)
		WorldSimulation.scoped(actor,func()->void:
			var item:=String(CASES[index][0]);var spec:=I.product(item);var state=WorldSimulation.state
			state.settlement_site_committed=true;state.convoy_traveling=false
			state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
			if spec.get("slitting_external",false) or spec.get("fracture_external",false):
				WorldSimulation.progression.domain_levels.security=1
				state.known_discoveries.append("stress_strain_relations");state.discovery_adoption["stress_strain_relations"]=1.0
				state.resource_stockpiles.Steel=1.0
				state.resource_stockpiles["Machine Bench Vises"]=10.0;state.resource_stockpiles["Gauge Blocks"]=10.0
				Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":10000.0}
				assert_bool(WorldSimulation.military.start_production_line("gently_formed_steel_bars",1).get("ok",false)).is_true()
				P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),2)
			state.known_discoveries.append(spec.gate);state.discovery_adoption[spec.gate]=1.0
			for field:String in ["materials","tooling","machine_inspection"]:
				for resource:String in spec.get(field,{}):
					if resource!="Traceable Formed Steel Bars":state.resource_stockpiles[resource]=100.0
			for resource:String in ["Steel Tool Bits","Graded Alumina Abrasive","Steel Section Etchant","Woven Cloth","Freshwater","Paper"]:state.resource_stockpiles[resource]=100.0
			Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":10000.0}
			var started:=WorldSimulation.military.start_production_line(item,1)
			assert_bool(started.get("ok",false)).override_failure_message(str(started)).is_true()
			if not started.get("ok",false):return
			var line:Dictionary=WorldSimulation.military.equipment_queue.back()
			P.advance(WorldSimulation.military,line,float(CASES[index][1]))
			assert_float(float(line.progress_days)).is_greater(0.0)
			pending[actor]=line.duplicate(true);stocks[actor]=state.resource_stockpiles.duplicate(true)
			queues[actor]=WorldSimulation.military.equipment_queue.duplicate(true)
		)
	var slot:="codex_metallurgy_%d"%Time.get_ticks_usec()
	var saved:=SaveSystem.save_game(slot)
	assert_bool(saved.get("ok",false)).override_failure_message(str(saved)).is_true()
	if not saved.get("ok",false):return
	WorldSimulation.clear()
	var loaded:=SaveSystem.load_game(slot)
	DirAccess.remove_absolute(SaveSystem.slot_path(slot))
	assert_bool(loaded.get("ok",false)).override_failure_message(str(loaded)).is_true()
	if not loaded.get("ok",false):return
	for index:int in range(CASES.size()):
		var actor:="metal_save_%d"%index
		WorldSimulation.scoped(actor,func()->void:
			var spec:=I.product(String(CASES[index][0]));var line:Dictionary=WorldSimulation.military.equipment_queue.back()
			assert_dict(line).is_equal(pending[actor])
			assert_array(WorldSimulation.military.equipment_queue).is_equal(queues[actor])
			assert_dict(WorldSimulation.state.resource_stockpiles).is_equal(stocks[actor])
			Ops.data().services.electricity=10000.0
			P.advance(WorldSimulation.military,line,float(spec.days))
			P.advance(WorldSimulation.military,line,1.0)
			assert_int(line.completed).override_failure_message(String(line.item)).is_equal(1)
			assert_float(float(WorldSimulation.state.resource_stockpiles.get(spec.output,0))).is_greater(0.0)
			assert_str(P.validate_saved({"equipment_queue":[line]})).is_empty()
		)
