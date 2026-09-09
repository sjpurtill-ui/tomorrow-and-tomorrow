extends GdUnitTestSuite
const Demography=preload("res://scripts/civilization_demography.gd")

func test_identical_conditions_give_identical_human_and_independent_state_results()->void:
	GameState.reset_for_new_world(123);GameState.initialize_population_model()
	var state:=Demography.capture(GameState)
	var context:={"health":.72,"food_security":.82,"housing_ratio":1.0,"cohesion":.58,"traveling":false}
	for day in range(1,731):
		GameState.elapsed_days=day
		var rates:={"Illness":.004,"Natural causes":GameState.current_natural_mortality_rate(1.0)}
		GameState.process_demographic_day(context,rates)
		state=Demography.advance(state,context,rates,day).state
	assert_dict(state).is_equal(Demography.capture(GameState))
	assert_bool(Demography.valid(state)).is_true()

func test_two_civilizations_do_not_mutate_each_other_or_live_player()->void:
	GameState.reset_for_new_world(456);GameState.initialize_population_model()
	var player:=Demography.capture(GameState)
	var first:=Demography.initial();var second:=first.duplicate(true)
	var result:=Demography.advance(first,{"health":.9,"food_security":.95,"housing_ratio":1.0},{},1,365)
	assert_dict(first).is_equal(second)
	assert_dict(Demography.capture(GameState)).is_equal(player)
	assert_bool(result.state==second).is_false()
	assert_bool(result.state.pregnancy_cohorts==second.pregnancy_cohorts).is_false()

func test_demographic_save_roundtrip_continues_without_reseeding_pregnancies()->void:
	var state:=Demography.initial()
	var conditions:={"health":.85,"food_security":.9,"housing_ratio":.9}
	state=Demography.advance(state,conditions,{},1,180).state
	var restored:Dictionary=JSON.parse_string(JSON.stringify(state))
	assert_bool(Demography.valid(restored)).is_true()
	var uninterrupted:=Demography.advance(state,conditions,{},181,180)
	var resumed:=Demography.advance(restored,conditions,{},181,180)
	assert_int(int(resumed.births)).is_equal(int(uninterrupted.births))
	assert_int(int(resumed.deaths)).is_equal(int(uninterrupted.deaths))
	for field:String in Demography.FIELDS:
		var expected:Variant=uninterrupted.state[field];var actual:Variant=resumed.state[field]
		if expected is Dictionary:
			for key in expected:assert_float(float(actual.get(key,-1))).is_equal_approx(float(expected[key]),0.000000001)
		else:assert_float(float(actual)).is_equal_approx(float(expected),0.000000001)
