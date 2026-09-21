extends GdUnitTestSuite
const S=preload("res://scripts/civilization_start.gd")
func test_generated_seats_have_a_subsistence_base_and_are_repeatable()->void:
	for seed in [91420,74119,991704]:
		GameState.reset_for_new_world(seed)
		var positions:Array=[]
		for seat in 12:
			var point:=S.candidate(seed,seat)
			assert_bool(S.supports_founders(PlanetEnvironment.profile_at(point))).is_true()
			assert_bool(point==S.candidate(seed,seat)).is_true()
			positions.append(point)
		assert_bool(positions[0]!=positions[1]).is_true()
func test_water_or_land_alone_does_not_make_a_generalist_start_viable()->void:
	assert_bool(S.supports_founders({"land":true,"food_potential":.1,"mean_temperature_c":0,"growing_season":.1,"water_access":1})).is_false()
	assert_bool(S.supports_founders({"land":false,"food_potential":1,"mean_temperature_c":18,"growing_season":.8})).is_false()
