extends Node

const FORBIDDEN_PERSON_KEYS := [
	"citizen_registry", "citizen_ids", "soldier_ids", "wounded_ids",
	"scattered_ids", "captured_ids", "mother_id", "father_id", "household_id"
]

func _ready() -> void:
	var game_state:=get_node("/root/GameState")
	var food_system:=get_node("/root/FoodSystem")
	var consequence:=get_node("/root/ConsequenceEngine")
	var military:=get_node("/root/MilitaryCampaign")
	var settlement:=get_node("/root/SettlementModel")
	game_state.reset_for_new_world(8675309)
	game_state.initialize_population_model()
	var cohort_shape:int=game_state.population_cohorts.keys().size()
	var pregnancy_shape:int=game_state.pregnancy_cohorts.keys().size()
	game_state.ensure_population_total(1_000_000_000)
	assert(game_state.population_total==1_000_000_000)
	assert(game_state.population_cohorts.keys().size()==cohort_shape)
	assert(game_state.pregnancy_cohorts.keys().size()==pregnancy_shape)
	assert(game_state.able_population()>500_000_000)
	var demand:Dictionary=food_system._calculate_demand(false)
	assert(float(demand.total)>800_000_000.0)
	var before:int=game_state.population_total
	game_state.process_reproduction_day({"health":0.72,"food_security":0.82,"housing_ratio":1.0,"cohesion":0.6})
	assert(game_state.population_total>=before)
	var deaths:Dictionary=game_state.register_population_deaths(1_000_000,"Scale probe")
	assert(int(deaths.count)==1_000_000)
	assert(game_state.population_total>=998_000_000)
	assert(game_state.population_cohorts.keys().size()==cohort_shape)

	# Integrated world days must preserve billion-scale totals and bounded histories.
	game_state.resource_stockpiles={"Food":40_000_000_000.0,"Timber":5_000_000_000.0,"Stone":5_000_000_000.0,"Clay":1_000_000_000.0,"Fiber Plants":1_000_000_000.0}
	game_state.housing_capacity=1_100_000_000
	for day in 3:
		game_state.elapsed_days=day
		consequence.process_day({"traveling":false})
	assert(game_state.population_total>900_000_000)
	assert(game_state.food_history.size()<=370 and game_state.material_history.size()<=370 and game_state.economy_history.size()<=730)

	# A million-person mobilization is represented by counts and one formation.
	military.reset_for_new_world()
	var raised:Dictionary=military.raise_recruits(1_000_000)
	assert(int(raised.raised)==1_000_000)
	var order:Dictionary=military.start_training("levy","improvised",500_000)
	assert(int(order.accepted)==500_000)
	var training:Dictionary=military.training_queue[0].duplicate(true)
	military._complete_training(training)
	military.training_queue.clear()
	assert(int(military.home_army.troops)==500_000)
	assert((military.home_army.formations as Array).size()==1)
	assert(int(military.home_army.formations[0].count)==500_000)
	assert(not _has_forbidden_person_data(military.export_state()))
	assert(military.validate_state().is_empty())
	assert(JSON.stringify(military.export_state()).length()<50_000)

	# A capital-sized population still owns a bounded visual morphology.
	game_state.settlement_completed.assign(["Hearth Circle"])
	game_state.settlement_founded_day=0
	settlement.ensure_founded()
	assert(game_state.settlement_plots.size()<=settlement.MAX_SIMULATED_PLOTS)
	assert(game_state.settlement_plots.size()<200)
	print("POPULATION_SCALE_PASS total=%d cohorts=%d military_formations=%d demand=%.0f" % [game_state.population_total,cohort_shape,(military.home_army.formations as Array).size(),float(demand.total)])
	get_tree().quit()


func _has_forbidden_person_data(value:Variant)->bool:
	if value is Dictionary:
		for key in value:
			if String(key) in FORBIDDEN_PERSON_KEYS:
				return true
			if _has_forbidden_person_data(value[key]):
				return true
	elif value is Array:
		for entry in value:
			if _has_forbidden_person_data(entry):
				return true
	return false
