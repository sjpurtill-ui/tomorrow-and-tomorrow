class_name GameStateDemographicsTest
extends GdUnitTestSuite

const GAME_STATE_SCRIPT := preload("res://scripts/game_state.gd")
const TEST_SEED := 184271
const AGE_COHORTS := ["children", "youth", "early_adults", "established_adults", "mature_adults", "elders"]

var state: Node


func before_test() -> void:
	state = auto_free(GAME_STATE_SCRIPT.new())
	state.reset_for_new_world(TEST_SEED)
	state.initialize_population_model()


func _cohort_sum(subject: Node) -> float:
	var total := 0.0
	for cohort in AGE_COHORTS:
		total += float(subject.population_cohorts.get(cohort, 0.0))
	return total


func _property_names(subject: Object) -> PackedStringArray:
	var names := PackedStringArray()
	for property in subject.get_property_list():
		names.append(String(property.name))
	return names


func test_founding_population_is_six_numeric_cohorts() -> void:
	assert_int(state.population_total).is_equal(120)
	assert_float(_cohort_sum(state)).is_equal_approx(state.population_exact, 0.001)
	assert_int(state.population_cohorts.size()).is_equal(9)
	for cohort in AGE_COHORTS:
		assert_bool(state.population_cohorts[cohort] is float).is_true()
	assert_bool(_property_names(state).has("citizen_registry")).is_false()
	assert_bool(_property_names(state).has("active_pregnancies")).is_false()


func test_planetary_population_does_not_create_more_runtime_records() -> void:
	var founding_keys: int = state.population_cohorts.keys().size()
	var pregnancy_keys: int = state.pregnancy_cohorts.keys().size()
	state.ensure_population_total(12_000_000_000)
	assert_int(state.population_total).is_equal(12_000_000_000)
	assert_float(_cohort_sum(state)).is_equal_approx(12_000_000_000.0, 16.0)
	assert_int(state.population_cohorts.keys().size()).is_equal(founding_keys)
	assert_int(state.pregnancy_cohorts.keys().size()).is_equal(pregnancy_keys)
	assert_int(state.population_age_profile().bands.size()).is_equal(6)
	assert_int(state.age_distribution().size()).is_equal(17)


func test_same_state_and_conditions_produce_same_aggregate_demography() -> void:
	var comparison: Node = auto_free(GAME_STATE_SCRIPT.new())
	comparison.reset_for_new_world(TEST_SEED)
	comparison.initialize_population_model()
	state.ensure_population_total(10_000_000)
	comparison.ensure_population_total(10_000_000)
	var context := {"health": 0.76, "food_security": 0.81, "housing_ratio": 0.94, "cohesion": 0.63}
	var first: Dictionary = state.process_reproduction_day(context)
	var second: Dictionary = comparison.process_reproduction_day(context)
	assert_dict(first).is_equal(second)
	assert_dict(state.population_cohorts).is_equal(comparison.population_cohorts)
	assert_dict(state.pregnancy_cohorts).is_equal(comparison.pregnancy_cohorts)


func test_role_allocations_conserve_the_able_population_at_every_scale() -> void:
	for scale in [120, 1_000_000, 1_000_000_000, 12_000_000_000]:
		state.ensure_population_total(scale)
		state.synchronize_population_allocations()
		var allocated := 0
		for role in state.POPULATION_ROLES:
			allocated += int(state.population_allocations.get(role, 0))
		assert_int(allocated).is_equal(state.able_population())


func test_founding_focus_is_a_real_one_time_aggregate_choice()->void:
	var initial_health:float=float(state.population_health)
	var initial_security:=float(state.simulation_metrics.security)
	var selected:Dictionary=state.select_founding_focus("defense")
	assert_bool(bool(selected.get("ok",false))).is_true()
	assert_str(state.founding_focus).is_equal("defense")
	assert_float(state.population_health).is_equal(initial_health)
	assert_float(float(state.simulation_metrics.security)).is_greater(initial_security)
	assert_float(state.founding_effect("training_rate")).is_greater(0.0)
	assert_float(state.founding_effect("knowledge_gain")).is_less(0.0)
	assert_float(float(state.population_allocation_percentages.Defense)).is_equal(11.0)
	assert_bool(state.select_founding_focus("inquiry").has("error")).is_true()
	var allocated:=0
	for role in state.POPULATION_ROLES: allocated+=int(state.population_allocations.get(role,0))
	assert_int(allocated).is_equal(state.able_population())


func test_every_founding_focus_has_strengths_costs_and_fixed_size_state()->void:
	assert_int(state.founding_focus_catalog().size()).is_equal(6)
	for definition in state.founding_focus_catalog():
		assert_str(String(definition.get("strengths",""))).is_not_empty()
		assert_str(String(definition.get("tradeoff",""))).is_not_empty()
		assert_int((definition.get("allocations",{}) as Dictionary).size()).is_equal(state.POPULATION_ROLES.size())
	state.ensure_population_total(1_000_000_000)
	state.select_founding_focus("generations")
	assert_int(state.founding_focus_catalog().size()).is_equal(6)
	assert_int(state.population_cohorts.size()).is_equal(9)


func test_pregnancy_pipeline_is_numeric_and_condition_sensitive() -> void:
	state.ensure_population_total(1_000_000_000)
	var good: Dictionary = state.process_reproduction_day({
		"health": 0.92, "food_security": 0.96, "housing_ratio": 1.0, "cohesion": 0.80,
		"maternal_safety": 0.35, "neonatal_survival": 0.35
	})
	var stressed_state: Node = auto_free(GAME_STATE_SCRIPT.new())
	stressed_state.reset_for_new_world(TEST_SEED)
	stressed_state.initialize_population_model()
	stressed_state.ensure_population_total(1_000_000_000)
	var bad: Dictionary = stressed_state.process_reproduction_day({
		"health": 0.28, "food_security": 0.22, "housing_ratio": 0.30, "cohesion": 0.30,
		"traveling": true
	})
	assert_float(float(good.annual_conceptions_expected)).is_greater(float(bad.annual_conceptions_expected))
	assert_int(int(good.maternal_deaths_count)).is_less(int(bad.maternal_deaths_count))
	assert_int(int(good.neonatal_deaths_count)).is_less(int(bad.neonatal_deaths_count))
	for stage in state.pregnancy_cohorts:
		assert_bool(state.pregnancy_cohorts[stage] is float).is_true()
		assert_float(float(state.pregnancy_cohorts[stage])).is_greater_equal(0.0)


func test_numeric_deaths_conserve_population_and_report_cohorts() -> void:
	state.ensure_population_total(1_000_000)
	var result: Dictionary = state.register_population_deaths(125_000, "Exposure")
	assert_int(int(result.count)).is_equal(125_000)
	assert_int(state.population_total).is_equal(875_000)
	var accounted := 0.0
	for amount in (result.affected_cohorts as Dictionary).values():
		accounted += float(amount)
	assert_float(accounted).is_equal_approx(125_000.0, 0.01)
	assert_float(_cohort_sum(state)).is_equal_approx(state.population_exact, 0.01)


func test_mortality_cause_changes_aggregate_age_pattern() -> void:
	var exposure_state: Node = auto_free(GAME_STATE_SCRIPT.new())
	exposure_state.reset_for_new_world(TEST_SEED)
	exposure_state.initialize_population_model()
	exposure_state.ensure_population_total(1_000_000)
	var battle_state: Node = auto_free(GAME_STATE_SCRIPT.new())
	battle_state.reset_for_new_world(TEST_SEED)
	battle_state.initialize_population_model()
	battle_state.ensure_population_total(1_000_000)
	var exposure: Dictionary = exposure_state.register_population_deaths(50_000, "Exposure")
	var battle: Dictionary = battle_state.register_population_deaths(50_000, "Killed in battle")
	assert_float(float(exposure.affected_cohorts.get("elders", 0.0))).is_greater(float(battle.affected_cohorts.get("elders", 0.0)))
	assert_float(float(battle.affected_cohorts.get("early_adults", 0.0))).is_greater(float(exposure.affected_cohorts.get("early_adults", 0.0)))


func test_age_profile_accounts_for_the_entire_population() -> void:
	state.ensure_population_total(1_000_000_000)
	var profile: Dictionary = state.population_age_profile()
	var total := 0
	for band in profile.bands:
		total += int(band.count)
	assert_int(total).is_equal(state.population_total)
	assert_int(int(profile.working_age) + int(profile.dependents)).is_equal(state.population_total)


func test_population_function_profile_conserves_roles_and_removes_real_absences()->void:
	state.ensure_population_total(1_000_000_000)
	var commitments:={
		"total_absent":12_345_678,
		"by_function":{"productive":8_000_000,"support":2_000_000,"mobilized":1_000_000,"dependent":1_345_678},
		"records":[{"id":"test_convoy","personnel":12_345_678}]
	}
	var profile:Dictionary=state.population_function_profile(commitments)
	assert_int(int(profile.accounted)).is_equal(state.population_total)
	assert_int(int(profile.absent)).is_equal(12_345_678)
	assert_int(int(profile.productive)).is_equal(int(state.population_allocations.Food)+int(state.population_allocations.Survey)+int(state.population_allocations.Extraction)+int(state.population_allocations.Construction)+int(state.population_allocations.Crafting)+int(state.population_allocations.Logistics)-8_000_000)
	assert_int(int(profile.support)).is_equal(int(state.population_allocations.Knowledge)+int(state.population_allocations.Administration)-2_000_000)
	assert_int((profile.functions as Array).size()).is_equal(5)
	assert_bool(bool(profile.bounded)).is_true()


func test_proportional_population_commitment_is_exact_and_constant_shape_at_planet_scale()->void:
	state.ensure_population_total(12_000_000_000)
	var sources:Dictionary=state.proportional_population_commitment(240_000_000)
	var total:=0
	for function_id in ["productive","support","mobilized","dependent"]: total+=int(sources.get(function_id,0))
	assert_int(total).is_equal(240_000_000)
	assert_int(sources.size()).is_equal(4)
	var profile:Dictionary=state.population_function_profile({"total_absent":total,"by_function":sources})
	assert_int(int(profile.accounted)).is_equal(state.population_total)
	assert_int(int(profile.absent)).is_equal(total)


func test_mobilization_above_defense_allocation_displaces_other_work_instead_of_duplication()->void:
	state.ensure_population_total(1_000_000_000)
	var baseline:Dictionary=state.population_function_profile()
	var excess:=25_000_000
	var mobilized_total:=int(baseline.mobilized)+excess
	var profile:Dictionary=state.population_function_profile({"mobilized_total":mobilized_total,"mobilization":{"total":mobilized_total,"excess_beyond_defense":excess}})
	assert_int(int(profile.accounted)).is_equal(state.population_total)
	assert_int(int(profile.mobilized)).is_equal(mobilized_total)
	assert_int(int(profile.productive)).is_equal(int(baseline.productive)-excess)
	assert_int(int((profile.mobilized_from as Dictionary).productive)).is_equal(excess)
	assert_int(int(profile.absent)).is_equal(0)


func test_decades_at_billion_scale_keep_constant_state_shape() -> void:
	state.ensure_population_total(1_000_000_000)
	var cohort_keys: int = state.population_cohorts.keys().size()
	var pregnancy_keys: int = state.pregnancy_cohorts.keys().size()
	var context := {"health": 0.72, "food_security": 0.82, "housing_ratio": 1.0, "cohesion": 0.60}
	for _day in 10_000:
		state.process_reproduction_day(context)
	assert_int(state.population_cohorts.keys().size()).is_equal(cohort_keys)
	assert_int(state.pregnancy_cohorts.keys().size()).is_equal(pregnancy_keys)
	assert_int(state.demographic_remainders.keys().size()).is_equal(6)
	assert_bool(state.population_total > 0).is_true()
	assert_float(_cohort_sum(state)).is_equal_approx(state.population_exact, 2.0)
