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

func test_generated_starts_remain_viable_after_real_ground_sampling()->void:
	for seed:int in [91420,9241,777]:
		GameState.reset_for_new_world(seed)
		var terrain=preload("res://scripts/local_terrain.gd").new()
		terrain._configure_shape();terrain._configure_noise();terrain._prepare_river_course()
		for seat in 16:
			var point:Vector2=terrain._civilization_start(S.candidate(seed,seat))
			var context:Dictionary=terrain._civilization_geography(point)
			assert_bool(S.supports_founders(context.environment_profile)).override_failure_message("Final ground must support founders at seat %d" % seat).is_true()
			assert_float(float(context.surface_water_distance_km)).is_less_equal(6.0)
			assert_bool(S.supports_founding_materials(context.surface_material_catchments)).override_failure_message("Generated seat %d needs working founding materials" % seat).is_true()
		terrain.free()

func test_food_does_not_replace_the_material_basis_of_the_founding_kit()->void:
	assert_bool(S.supports_founding_materials({"Timber":{"density":0},"Stone":{"density":1},"Fiber Plants":{"density":1}})).is_false()
	assert_bool(S.supports_founding_materials({"Timber":{"density":.1},"Stone":{"density":.1},"Fiber Plants":{"density":.1}})).is_true()
