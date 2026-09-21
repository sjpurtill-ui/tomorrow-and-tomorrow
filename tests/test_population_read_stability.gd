extends GdUnitTestSuite
func before_test()->void:
	GameState.reset_for_new_world(9241)
func test_repeated_population_reads_do_not_rescale_rounding_noise()->void:
	GameState.population_exact=177.007077071881
	GameState.population_cohorts={"children":63.5044587323371,"youth":40.8554271446304,"early_adults":28.3057030529771,"established_adults":21.0037770008031,"mature_adults":17.4440648890412,"elders":5.89364625209247}
	GameState.initialize_population_model()
	var before:=GameState.population_cohorts.duplicate(true)
	for i in 100:
		GameState.initialize_population_model()
		GameState._integer_age_cohorts()
	assert_dict(GameState.population_cohorts).is_equal(before)
func test_real_population_change_still_rescales_demographics()->void:
	GameState.initialize_population_model()
	var before:=GameState.population_cohorts.duplicate(true)
	GameState.population_exact*=1.5
	GameState.initialize_population_model()
	assert_float(GameState._age_cohort_sum()).is_equal_approx(GameState.population_exact,.000001)
	assert_float(float(GameState.population_cohorts.children)).is_equal_approx(float(before.children)*1.5,.000001)
	assert_float(float(GameState.population_cohorts.female)+float(GameState.population_cohorts.male)).is_equal_approx(GameState.population_exact,.000001)
