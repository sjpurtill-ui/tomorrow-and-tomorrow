extends GdUnitTestSuite

const Indicators:=preload("res://scripts/civilization_indicators.gd")

func test_real_gdp_uses_effective_assigned_work_and_shared_productivity()->void:
	var result:=Indicators.economy()
	assert_float(float(result.gdp)).is_equal_approx(float(result.effective_workers)*float(result.productivity),0.0001)
	assert_float(float(result.gdp_per_capita)).is_equal_approx(float(result.gdp)/maxf(1.0,float(GameState.population_total)),0.0001)

func test_science_capacity_is_minds_times_average_education()->void:
	var result:=Indicators.science()
	assert_float(float(result.education)).is_between(0.01,1.0)
	assert_float(float(result.capacity)).is_equal_approx(float(result.minds)*float(result.education),0.0001)

func test_survival_indicator_reports_life_expectancy_and_infant_deaths_per_thousand()->void:
	var result:=Indicators.health()
	assert_float(float(result.life_expectancy)).is_greater(0.0)
	assert_float(float(result.infant_mortality_per_1000)).is_between(4.0,180.0)
