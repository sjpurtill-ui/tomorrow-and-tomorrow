extends GdUnitTestSuite
## Each course a people chooses works on its life through the engine's own
## levers, with a gain and a cost (ambition_effects.gd).
const Effects:=preload("res://scripts/ambition_effects.gd")


func before_test()->void:
	GameState.reset_for_new_world(4242); GameState.civic_api_enabled=false
	WorldSimulation.direction.reset_for_new_world()


func test_every_course_has_a_gain_and_a_cost()->void:
	for id in PeopleDirection.AMBITIONS:
		assert_bool(Effects.EFFECTS.has(id)).override_failure_message(id).is_true()
		var table:Dictionary=Effects.EFFECTS[id]
		assert_bool(table.values().any(func(v:float)->bool:return v>0.0)).override_failure_message(id).is_true()
		assert_bool(table.values().any(func(v:float)->bool:return v<0.0)).override_failure_message(id).is_true()
		for lever in table: assert_bool(Effects.WORDS.has(lever)).override_failure_message(lever).is_true()
		assert_str(Effects.describe(id)).contains("Costs:")


func test_the_chosen_course_moves_the_engines_levers()->void:
	assert_float(GameState.founding_effect("training_rate")).is_equal(0.0)
	assert_dict(WorldSimulation.direction.choose("military")).contains_keys(["ok"])
	assert_str(GameState.founding_focus).is_equal("collective_ambition")
	# A people set on military strength drills faster and pays in food.
	assert_float(GameState.founding_effect("training_rate")).is_equal_approx(0.20,0.001)
	assert_float(GameState.founding_effect("food_yield")).is_less(0.0)
	assert_float(GameState.founding_effect("survey_output")).is_equal(0.0)


func test_courses_blend_by_their_share_of_memory()->void:
	var half:={"sustenance":0.5,"inquiry":0.5}
	assert_float(Effects.effect("food_yield",half)).is_equal_approx(0.5*0.12+0.5*-0.02,0.0001)
	assert_float(Effects.effect("knowledge_gain",half)).is_equal_approx(0.5*-0.05+0.5*0.15,0.0001)
