extends GdUnitTestSuite
const A=preload("res://scripts/alloy_phase_trials.gd")
const I=preload("res://scripts/civilian_industry.gd")
const P=preload("res://scripts/persistent_production.gd")
const Ops=preload("res://scripts/technology_operations.gd")
func before_test()->void:WorldSimulation.clear();WorldSimulation.create_actor("alloy_trial",1221)
func after_test()->void:WorldSimulation.clear()
func test_actual_survey_retains_compositions_and_partial_observations_before_solder_use()->void:
	WorldSimulation.scoped("alloy_trial",func()->void:
		var state=WorldSimulation.state;var recipe:=I.product("lead_tin_phase_survey")
		state.settlement_site_committed=true;state.convoy_traveling=false
		state.population_allocations.Crafting=100;state.population_allocations.Logistics=100
		state.known_discoveries.append(recipe.gate);state.discovery_adoption[recipe.gate]=1.0
		for resource:String in recipe.tooling:state.resource_stockpiles[resource]=10.0
		for resource:String in recipe.materials:state.resource_stockpiles[resource]=float(recipe.materials[resource])
		Ops.data().last_day=int(state.elapsed_days);Ops.data().services={"electricity":500.0}
		assert_bool(WorldSimulation.military.start_production_line("lead_tin_phase_survey",1).get("ok",false)).is_true()
		var line:Dictionary=WorldSimulation.military.equipment_queue.back()
		P.advance(WorldSimulation.military,line,7)
		assert_int(line.alloy_trial.samples.size()).is_equal(3)
		assert_float(float(state.resource_stockpiles["Refined Tin"])).is_equal(0.0)
		assert_float(Ops.workshop_power_demand()).is_greater(0.0)
		var restored:Dictionary=bytes_to_var(var_to_bytes(line))
		assert_str(P.validate_saved({"equipment_queue":[restored]})).is_empty()
		P.advance(WorldSimulation.military,restored,29)
		assert_int(restored.alloy_last.samples.size()).is_equal(18)
		assert_str(A.validate_job(restored,recipe)).is_empty()
		assert_float(float(restored.alloy_last.selected_tin)).is_equal_approx(.6213,.000001)
		assert_float(float(state.resource_stockpiles[recipe.output])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles["Spent Lead-Tin Trial Samples"])).is_equal(.9)
		var solder:=I.product("phase_selected_solder")
		for resource:String in solder.materials:state.resource_stockpiles[resource]=float(solder.materials[resource])
		state.resource_stockpiles["Ceramic Crucibles"]=1.0
		WorldSimulation.military.equipment_queue.clear()
		assert_bool(WorldSimulation.military.start_production_line("phase_selected_solder",1).get("ok",false)).is_true()
		P.advance(WorldSimulation.military,WorldSimulation.military.equipment_queue.back(),3)
		assert_float(float(state.resource_stockpiles[solder.output])).is_equal(1.0)
		assert_float(float(state.resource_stockpiles[recipe.output])).is_equal(0.0)
	)
func test_mobility_readings_distinguish_compositions_and_drive_selection()->void:
	assert_str(A.observation(.2,185).state).is_not_equal("flowing")
	assert_str(A.observation(.6213,185).state).is_equal("flowing")
	assert_str(A.observation(.6213,170).state).is_equal("immobile")
	var samples:Array=[{"tin_mass":.01,"observation":{"state":"flowing","temperature_c":300}},
		{"tin_mass":.031065,"observation":{"state":"flowing","temperature_c":185}}]
	assert_float(A.selected_composition(samples)).is_equal_approx(.6213,.000001)
	samples[1].observation.state="immobile"
	assert_float(A.selected_composition(samples)).is_equal_approx(.2,.000001)
