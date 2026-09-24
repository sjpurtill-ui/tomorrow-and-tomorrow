extends GdUnitTestSuite
## Early care practices, diet and overwork change infant, child, adult and
## birth mortality, conception and life expectancy; older saves blend in.

const GAME_STATE_SCRIPT:=preload("res://scripts/game_state.gd")
const EarlyCare:=preload("res://scripts/early_life_conditions.gd")
const Indicators:=preload("res://scripts/civilization_indicators.gd")

class FakeDiscovery extends Node:
	var effects:Dictionary={}
	func adoption(_id:String)->float:return 1.0
	func effect(id:String)->float:return float(effects.get(id,0.0))
	func discovery_definition(id:String)->Dictionary:return {"id":id,"name":id.capitalize()}

var state:Node
var discovery:FakeDiscovery

func before_test()->void:
	state=auto_free(GAME_STATE_SCRIPT.new())
	state.reset_for_new_world(5150)
	state.initialize_population_model()
	state.population_health=0.9
	state.food_security=0.9
	state.housing_capacity=150
	state.early_care_blend=1.0
	state.food_history.clear()
	for day in 120:state.food_history.append({"day":day,"diet_quality":0.70})
	discovery=auto_free(FakeDiscovery.new())

func _profile()->Dictionary:
	var care:=EarlyCare.profile(state,discovery)
	state.early_care=care
	return care

func test_society_without_care_practices_loses_far_more_young_children()->void:
	var care:=_profile()
	assert_float(float(care.under5)).is_greater(2.5)
	assert_float(float(care.neonatal)).is_greater(2.0)
	assert_float(float(care.maternal)).is_greater(2.0)
	assert_float(float(care.adult)).is_greater(1.3)
	var expectancy:float=state.projected_life_expectancy()
	# research_600 balance: with the pre-modern burden a careless founding band
	# lives about as long as the worst documented Neolithic series.
	assert_float(expectancy).is_between(14.0,26.0)
	assert_float(Indicators.infant_mortality_per_1000(state,discovery)).is_greater(150.0)

func test_each_early_practice_raises_life_expectancy_until_the_baseline_table()->void:
	var previous:=-1.0
	for id:String in ["wound_cleaning","herbal_classification","clean_water","birth_attendants","shared_childcare","hearth_roasting_control","food_drying","smoking","edible_resource_recognition","food_pounding_mortars","well_siting","drainage","maternal_recovery","labor_rotations","public_stores"]:
		state.known_discoveries.append(id)
		_profile()
		var expectancy:float=state.projected_life_expectancy()
		assert_float(expectancy).is_greater_equal(previous)
		previous=expectancy
	var care:=_profile()
	var legacy:Node=auto_free(GAME_STATE_SCRIPT.new())
	legacy.reset_for_new_world(5150)
	legacy.initialize_population_model()
	legacy.population_health=state.population_health
	legacy.food_security=state.food_security
	legacy.housing_capacity=state.housing_capacity
	assert_float(float(care.adult)).is_less(1.12)
	# research_600 balance: every early practice in place still leaves the
	# pre-modern burden (docs/research/BENCHMARKS_600.md: e0 about 25-38)...
	assert_float(state.projected_life_expectancy()).is_between(25.0,38.0)
	# ...which only modern general health knowledge lifts back to the table.
	discovery.effects={"health_protection":0.55,"sanitation":0.65,"water_safety":0.60,"disease_exposure":-0.55}
	_profile()
	assert_float(state.projected_life_expectancy()).is_greater(legacy.projected_life_expectancy()-6.0)

func test_later_knowledge_counts_through_general_effect_channels()->void:
	var without:=float(_profile().under5)
	discovery.effects={"water_safety":0.30,"sanitation":0.25,"health_protection":0.30,"neonatal_survival":0.25,"maternal_safety":0.25,"injury_risk":-0.20,"nutrition_quality":0.25,"food_storage":0.40}
	var care:=_profile()
	assert_float(float(care.under5)).is_less(without)
	assert_float(float(care.neonatal)).is_less(1.3)

func test_thin_diet_raises_child_deaths_and_slows_conception()->void:
	var fed:=_profile()
	for row:Dictionary in state.food_history:row["diet_quality"]=0.42
	var thin:=_profile()
	assert_float(float(thin.under5)).is_greater(float(fed.under5)*1.25)
	assert_float(float(thin.conception)).is_less(float(fed.conception))

func test_overwork_lowers_conception_and_raises_pregnancy_risk()->void:
	var rested:=EarlyCare.profile(state,discovery,{"overwork":0.0})
	var worked:=EarlyCare.profile(state,discovery,{"overwork":1.0})
	assert_float(float(worked.conception)).is_less(float(rested.conception)*0.9)
	assert_float(float(worked.pregnancy_risk)).is_greater(float(rested.pregnancy_risk))

func test_infant_loss_shortens_birth_intervals_without_full_replacement()->void:
	var low:=EarlyCare.profile(state,discovery,{"infant_loss":0.10})
	var high:=EarlyCare.profile(state,discovery,{"infant_loss":0.30})
	assert_float(float(high.conception)).is_greater(float(low.conception))
	assert_float(float(high.conception)/float(low.conception)).is_less(1.6)

func test_older_save_blends_in_over_two_years_without_sudden_deaths()->void:
	state.early_care_blend=0.0
	state.elapsed_days=4000.0
	var legacy_expectancy:float=state.projected_life_expectancy()
	var care:=EarlyCare.refresh(state,discovery)
	assert_float(state.early_care_blend).is_less(0.01)
	assert_float(float(care.under5)).is_less(1.02)
	assert_float(state.projected_life_expectancy()).is_equal_approx(legacy_expectancy,0.5)
	for _day in 365:EarlyCare.refresh(state,discovery)
	assert_float(state.early_care_blend).is_between(0.45,0.56)

func test_new_world_applies_rules_at_once()->void:
	state.early_care_blend=0.0
	state.elapsed_days=3.0
	EarlyCare.refresh(state,discovery)
	assert_float(state.early_care_blend).is_equal(1.0)

func test_natural_deaths_follow_the_care_adjusted_life_table()->void:
	var legacy_rate:float=state.current_natural_mortality_rate()
	state.early_care={}
	var baseline_rate:float=state.current_natural_mortality_rate()
	assert_float(legacy_rate).is_equal_approx(baseline_rate,0.0001)
	_profile()
	assert_float(state.current_natural_mortality_rate()).is_greater(baseline_rate*1.3)
	var weights:Dictionary=state._mortality_weights_for("Natural causes")
	assert_float(float(weights.children)).is_greater(float(weights.youth))

func test_missing_birth_care_raises_newborn_and_maternal_deaths()->void:
	state.ensure_population_total(1_000_000)
	var careless:=_profile()
	var context:={"health":0.9,"food_security":0.9,"housing_ratio":1.0,"cohesion":0.6,"neonatal_care":float(careless.neonatal),"maternal_care":float(careless.maternal)}
	var careful:Node=auto_free(GAME_STATE_SCRIPT.new())
	careful.reset_for_new_world(5150)
	careful.initialize_population_model()
	careful.ensure_population_total(1_000_000)
	var without_care:Dictionary={"neonatal_deaths_count":0,"maternal_deaths_count":0}
	var with_care:Dictionary={"neonatal_deaths_count":0,"maternal_deaths_count":0}
	for _day in 200:
		var a:Dictionary=state.process_reproduction_day(context)
		var b:Dictionary=careful.process_reproduction_day({"health":0.9,"food_security":0.9,"housing_ratio":1.0,"cohesion":0.6})
		for key in without_care:
			without_care[key]=int(without_care[key])+int(a[key])
			with_care[key]=int(with_care[key])+int(b[key])
	assert_int(int(without_care.neonatal_deaths_count)).is_greater(int(with_care.neonatal_deaths_count)*2)
	assert_int(int(without_care.maternal_deaths_count)).is_greater(int(with_care.maternal_deaths_count))

func test_explanation_names_known_practices_and_what_to_learn()->void:
	state.known_discoveries.append("clean_water")
	var rows:=EarlyCare.explanation(_profile())
	assert_int(rows.size()).is_equal(EarlyCare.CATEGORIES.size())
	var water:Dictionary=rows[0]
	assert_str(String(water.status)).is_equal("Partly practiced")
	assert_str(String(water.detail)).contains("Clean Water")
	var birth:Dictionary=rows[3]
	assert_str(String(birth.status)).is_equal("Not yet practiced")
	assert_str(String(birth.detail)).contains("To learn")
