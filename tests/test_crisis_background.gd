extends GdUnitTestSuite
## THE CRISES' SHARE OF THE AGE TABLE (scripts/crisis_background.gd). The age
## table is all-cause, crises included; the crises kill on their own odds, so
## the day's ordinary deaths emit the table less the crises' expected share,
## cohort by cohort. The screens read the whole table: life as it is lived.

const GAME_STATE_SCRIPT:=preload("res://scripts/game_state.gd")
const Background:=preload("res://scripts/crisis_background.gd")
const EarlyCare:=preload("res://scripts/early_life_conditions.gd")

class FakeDiscovery extends Node:
	var effects:Dictionary={}
	func adoption(_id:String)->float:return 1.0
	func effect(id:String)->float:return float(effects.get(id,0.0))
	func discovery_definition(id:String)->Dictionary:return {"id":id,"name":id.capitalize()}

var state:Node
var discovery:FakeDiscovery

func before_test()->void:
	state=auto_free(GAME_STATE_SCRIPT.new())
	state.reset_for_new_world(184271)
	state.initialize_population_model()
	state.population_health=0.97
	state.food_security=0.97
	state.housing_capacity=135
	state.early_care_blend=1.0
	for day in 120:state.food_history.append({"day":day,"diet_quality":0.66})
	discovery=auto_free(FakeDiscovery.new())
	state.early_care=EarlyCare.profile(state,discovery)

## The whole table's yearly deaths per head, at the given conditions.
func _whole_rate(conditions:float)->float:
	var hazards:Dictionary=state._natural_cohort_hazards(conditions)
	var deaths:=0.0
	for key:String in hazards:deaths+=float(state.population_cohorts[key])*clampf(float(hazards[key])*conditions,0.0001,0.98)
	return deaths/maxf(1.0,state.population_exact)

func test_the_shares_follow_the_era_and_hold_past_the_table()->void:
	var first:Array=Background.CRISIS_SHARE[0]
	var last:Array=Background.CRISIS_SHARE[Background.CRISIS_SHARE.size()-1]
	for row:Array in Background.CRISIS_SHARE:
		for key:String in Background.COHORTS:assert_float(float(row[1][key])).is_between(0.0,0.6)
	var at_founding:=Background.shares(0.0)
	var long_after:=Background.shares(float(last[0])+5000.0)
	for key:String in Background.COHORTS:
		assert_float(float(at_founding[key])).is_equal(float(first[1][key]))
		assert_float(float(long_after[key])).is_equal(float(last[1][key]))
		assert_float(float(Background.background(0.0)[key])).is_equal_approx(1.0-float(first[1][key]),0.000001)
	# Halfway between two rows, halfway between their shares.
	var second:Array=Background.CRISIS_SHARE[1]
	var middle:=Background.shares((float(first[0])+float(second[0]))*0.5)
	assert_float(float(middle.children)).is_equal_approx((float(first[1].children)+float(second[1].children))*0.5,0.000001)
	# Sickness and hunger take a larger share of the young's deaths than of the
	# old's, whose deaths the table already counts in plenty.
	assert_float(float(at_founding.children)).is_greater(float(at_founding.elders))

func test_the_day_emits_the_table_less_the_crises_share()->void:
	var conditions:float=state._mortality_condition_factor(1.0)
	var whole:Dictionary=state._natural_cohort_hazards(conditions)
	var kept:=Background.background(state.elapsed_days/365.0)
	var expected:=0.0
	for key:String in whole:expected+=float(state.population_cohorts[key])*clampf(float(whole[key])*float(kept[key])*conditions,0.0001,0.98)
	var rate:float=state.current_natural_mortality_rate(1.0)
	assert_float(rate).is_equal_approx(expected/state.population_exact,0.000001)
	# About a fifth of the founders' deaths are left to the crises.
	assert_float(rate/_whole_rate(conditions)).is_between(0.70,0.90)
	# Ordinary deaths fall by the background's own age profile.
	var weights:Dictionary=state._mortality_weights_for("Natural causes")
	var background:Dictionary=state._background_cohort_hazards()
	for key:String in background:assert_float(float(weights[key])).is_equal_approx(float(background[key]),0.000001)

## The screens read the whole table, crises included, never the background:
## life expectancy is the whole table's (about 25 years at the founding in
## play), and both stay inside the pre-modern bounds (BENCHMARKS_600.md).
func test_the_screens_show_life_as_lived_crises_included()->void:
	var inputs:Dictionary=state.life_inputs()
	inputs["hazard"]=0.0
	var care:Dictionary=state.care_profile()
	var conditions:=lerpf(1.90,0.64,clampf(float(inputs.health),0.0,1.0))*lerpf(2.40,0.78,clampf(float(inputs.food),0.0,1.0))*lerpf(1.65,0.88,clampf(float(inputs.housing),0.0,1.0))
	var survival:=1.0
	var years:=0.0
	for age in 110:
		years+=survival
		survival*=1.0-clampf(float(state.BASELINE_HAZARD_BY_AGE[age])*EarlyCare.age_multiplier(care,age,conditions)*conditions,0.0001,0.98)
	assert_float(state.life_expectancy_from(inputs)).is_equal_approx(years,0.0001)
	assert_float(state.life_expectancy_from(inputs)).is_between(18.0,33.0)
	var infants:float=preload("res://scripts/civilization_indicators.gd").infant_mortality_per_1000(state,discovery)
	assert_float(infants).is_between(160.0,400.0)
