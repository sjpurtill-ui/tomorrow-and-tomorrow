class_name GameStateDemographicsTest
extends GdUnitTestSuite

const GAME_STATE_SCRIPT := preload("res://scripts/game_state.gd")
const TEST_SEED := 184271

var state: Node


func before_test() -> void:
	state = auto_free(GAME_STATE_SCRIPT.new())
	state.world_seed = TEST_SEED
	state.initialize_citizen_registry()


func test_founding_population_is_fully_traceable() -> void:
	assert_int(state.population_total).is_equal(120)
	assert_int(state.living_citizen_count()).is_equal(120)

	var names: Dictionary = {}
	for person: Dictionary in state.citizen_registry:
		var person_name := String(person.get("name", ""))
		assert_str(person_name).is_not_empty()
		assert_bool(names.has(person_name)).is_false()
		names[person_name] = true
		assert_int(state.citizen_age_years(person)).is_between(0, 76)
		assert_str(String(person.get("role", ""))).is_not_empty()


func test_same_world_seed_creates_same_founders() -> void:
	var comparison: Node = auto_free(GAME_STATE_SCRIPT.new())
	comparison.world_seed = TEST_SEED
	comparison.initialize_citizen_registry()

	var first_names := PackedStringArray()
	var second_names := PackedStringArray()
	for person: Dictionary in state.citizen_registry:
		first_names.append(String(person.get("name", "")))
	for person: Dictionary in comparison.citizen_registry:
		second_names.append(String(person.get("name", "")))

	assert_array(first_names).is_equal(second_names)


func test_every_citizen_has_bounded_individual_condition_stats() -> void:
	var fields := ["strength","endurance","agility","awareness","composure","health_condition","nutrition_condition","fatigue"]
	for person: Dictionary in state.citizen_registry:
		for field: String in fields:
			assert_bool(person.has(field)).is_true()
			assert_float(float(person[field])).is_between(0.0,1.0)
		assert_float(state.citizen_physical_capacity(person)).is_between(0.0,1.0)


func test_individual_stats_are_reproducible_from_world_seed() -> void:
	var comparison: Node = auto_free(GAME_STATE_SCRIPT.new())
	comparison.world_seed = TEST_SEED
	comparison.initialize_citizen_registry()
	for index in state.citizen_registry.size():
		var first: Dictionary = state.citizen_registry[index]
		var second: Dictionary = comparison.citizen_registry[index]
		assert_float(first.strength).is_equal(second.strength)
		assert_float(first.endurance).is_equal(second.endurance)
		assert_float(first.agility).is_equal(second.agility)
		assert_float(first.awareness).is_equal(second.awareness)
		assert_float(first.composure).is_equal(second.composure)
		assert_float(first.health_condition).is_equal(second.health_condition)
		assert_float(first.nutrition_condition).is_equal(second.nutrition_condition)
		assert_float(first.fatigue).is_equal(second.fatigue)


func test_age_health_nutrition_and_fatigue_change_physical_capacity() -> void:
	var adult: Dictionary = state.citizen_registry[0].duplicate(true)
	adult.birth_day = int(state.elapsed_days)-25*365
	adult.strength = 0.8
	adult.endurance = 0.8
	adult.agility = 0.8
	adult.health_condition = 1.0
	adult.nutrition_condition = 1.0
	adult.fatigue = 0.0
	var diminished := adult.duplicate(true)
	diminished.health_condition = 0.55
	diminished.nutrition_condition = 0.60
	diminished.fatigue = 0.70
	assert_float(state.citizen_physical_capacity(adult)).is_greater(state.citizen_physical_capacity(diminished))


func test_condition_profile_accounts_for_every_living_citizen() -> void:
	var profile: Dictionary = state.citizen_condition_profile(state.citizen_registry)
	var band_total := 0
	var share_total := 0.0
	for band: Dictionary in profile.bands:
		band_total += int(band.count)
		share_total += float(band.share)
	assert_int(profile.total).is_equal(state.population_total)
	assert_int(band_total).is_equal(state.population_total)
	assert_float(share_total).is_equal_approx(1.0,0.0001)
	assert_float(profile.average_capacity).is_between(0.0,1.0)


func test_role_allocations_use_exactly_the_able_population() -> void:
	var allocated := 0
	for role: String in state.POPULATION_ROLES:
		allocated += int(state.population_allocations.get(role, 0))
	assert_int(allocated).is_equal(state.able_population())

	for person: Dictionary in state.living_citizens():
		var age: int = state.citizen_age_years(person)
		if age >= 14 and age < 60:
			assert_bool(String(person.get("role", "")) in state.POPULATION_ROLES).is_true()


func test_deaths_record_names_places_and_causes() -> void:
	state.elapsed_days = 45.0
	var victims: Array[String] = state.register_deaths(2, "Exposure")

	assert_int(victims.size()).is_equal(2)
	assert_int(state.population_total).is_equal(118)
	for victim_name: String in victims:
		var found := false
		for person: Dictionary in state.citizen_registry:
			if String(person.get("name", "")) != victim_name:
				continue
			found = true
			assert_bool(bool(person.get("alive", true))).is_false()
			assert_str(String(person.get("death_cause", ""))).is_equal("Exposure")
			assert_int(int(person.get("death_day", -1))).is_equal(45)
			break
		assert_bool(found).is_true()


func test_founding_households_and_pregnancies_are_traceable() -> void:
	var women := 0
	var men := 0
	var linked_children := 0
	for person: Dictionary in state.citizen_registry:
		assert_int(int(person.get("household_id", -1))).is_greater_equal(1)
		assert_bool(String(person.get("sex", "")) in ["Female", "Male"]).is_true()
		if String(person.get("sex", "")) == "Female":
			women += 1
		else:
			men += 1
		if state.citizen_age_years(person) < 14 and int(person.get("mother_id", -1)) >= 0:
			linked_children += 1
	assert_int(women).is_equal(60)
	assert_int(men).is_equal(60)
	assert_int(linked_children).is_greater(18)
	assert_int(state.active_pregnancies().size()).is_between(1, 3)
	for pregnancy: Dictionary in state.active_pregnancies():
		var mother: Dictionary = state.citizen_by_id(int(pregnancy.mother_id))
		assert_bool(mother.is_empty()).is_false()
		assert_int(int(mother.current_pregnancy_id)).is_equal(int(pregnancy.id))
		assert_int(int(pregnancy.due_day)).is_greater(int(state.elapsed_days))


func test_delivery_creates_parent_linked_newborn_and_postpartum_recovery() -> void:
	var pregnancy: Dictionary = state.active_pregnancies()[0]
	var mother: Dictionary = state.citizen_by_id(int(pregnancy.mother_id))
	var father: Dictionary = state.citizen_by_id(int(pregnancy.father_id))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77192
	var newborn: Dictionary = state.register_birth_from_pregnancy(pregnancy, rng)
	assert_bool(newborn.is_empty()).is_false()
	assert_int(int(newborn.mother_id)).is_equal(int(mother.id))
	assert_int(int(newborn.father_id)).is_equal(int(father.id))
	assert_int(int(newborn.household_id)).is_equal(int(mother.household_id))
	assert_int(int(newborn.id)).is_in(mother.children_ids)
	assert_int(int(newborn.id)).is_in(father.children_ids)
	assert_int(int(mother.current_pregnancy_id)).is_equal(-1)
	assert_int(int(mother.postpartum_until_day)).is_greater_equal(450)
	assert_bool(mother in state.eligible_gestational_parents()).is_false()


func test_pregnancies_respect_gestation_and_stable_population_has_plausible_births() -> void:
	var initial_population: int = int(state.population_total)
	var initial_partnerships: int = int(state.lifetime_partnerships)
	var earliest_due := 100000
	for pregnancy: Dictionary in state.active_pregnancies():
		earliest_due = mini(earliest_due, int(pregnancy.due_day))
	var births_before_due := 0
	var births_over_ten_years := 0
	var stable_context := {
		"health": 0.86,
		"food_security": 0.90,
		"housing_ratio": 0.92,
		"cohesion": 0.76,
		"traveling": false,
		"birth_crisis": false
	}
	for day in range(1, 3651):
		state.elapsed_days = float(day)
		var result: Dictionary = state.process_reproduction_day(stable_context)
		var daily_births := int((result.get("births", []) as Array).size())
		births_over_ten_years += daily_births
		if day < earliest_due:
			births_before_due += daily_births
	assert_int(births_before_due).is_equal(0)
	assert_int(births_over_ten_years).is_between(18, 65)
	assert_int(state.population_total).is_greater(initial_population)
	assert_int(int(state.lifetime_partnerships)).is_greater(initial_partnerships)
	for person: Dictionary in state.citizen_registry:
		if String(person.get("origin", "")) != "Born here":
			continue
		assert_int(int(person.get("mother_id", -1))).is_greater_equal(1)
		assert_int(int(person.get("father_id", -1))).is_greater_equal(1)


func test_birth_spacing_prevents_immediate_repeat_pregnancy() -> void:
	var pregnancies_by_mother: Dictionary = {}
	var stable_context := {"health": 0.9, "food_security": 0.9, "housing_ratio": 0.9, "cohesion": 0.8, "traveling": false, "birth_crisis": false}
	for day in range(1, 3651):
		state.elapsed_days = float(day)
		state.process_reproduction_day(stable_context)
	for pregnancy: Dictionary in state.pregnancy_registry:
		var mother_id: int = int(pregnancy.mother_id)
		if not pregnancies_by_mother.has(mother_id): pregnancies_by_mother[mother_id] = []
		(pregnancies_by_mother[mother_id] as Array).append(pregnancy)
	for mother_id in pregnancies_by_mother:
		var pregnancies: Array = pregnancies_by_mother[mother_id]
		pregnancies.sort_custom(func(first: Dictionary, second: Dictionary) -> bool: return int(first.conception_day) < int(second.conception_day))
		for index in range(1, pregnancies.size()):
			var previous: Dictionary = pregnancies[index - 1]
			var current: Dictionary = pregnancies[index]
			if String(previous.get("outcome", "")) == "Live birth":
				assert_int(int(current.conception_day) - int(previous.end_day)).is_greater_equal(450)


func test_environment_changes_conception_and_pregnancy_risk_in_opposite_directions() -> void:
	var candidates: Array[Dictionary] = state.eligible_gestational_parents()
	assert_bool(candidates.is_empty()).is_false()
	var mother: Dictionary = candidates[0]
	var stable := {"health": 0.88, "food_security": 0.92, "housing_ratio": 0.92, "cohesion": 0.80, "traveling": false, "birth_crisis": false}
	var crisis := {"health": 0.34, "food_security": 0.20, "housing_ratio": 0.28, "cohesion": 0.30, "traveling": true, "birth_crisis": true}
	var stable_conception: float = state._conception_condition_factor(mother, stable)
	var crisis_conception: float = state._conception_condition_factor(mother, crisis)
	var stable_risk: float = state._pregnancy_risk_multiplier(mother, stable)
	var crisis_risk: float = state._pregnancy_risk_multiplier(mother, crisis)
	assert_float(stable_conception).is_greater(crisis_conception * 8.0)
	assert_float(crisis_risk).is_greater(stable_risk * 2.0)


func test_age_specific_fertility_has_a_biological_curve() -> void:
	assert_float(state.age_specific_conception_rate(12)).is_equal(0.0)
	assert_float(state.age_specific_conception_rate(25)).is_greater(state.age_specific_conception_rate(18))
	assert_float(state.age_specific_conception_rate(25)).is_greater(state.age_specific_conception_rate(38))
	assert_float(state.age_specific_conception_rate(46)).is_less(0.02)
	assert_float(state.age_specific_conception_rate(52)).is_equal(0.0)


func test_population_age_profile_accounts_for_every_living_person() -> void:
	var profile:Dictionary=state.population_age_profile()
	var cohort_total:=0
	for band:Dictionary in profile.bands:
		cohort_total+=int(band.count)
	assert_int(int(profile.total)).is_equal(state.living_citizen_count())
	assert_int(cohort_total).is_equal(int(profile.total))
	assert_int(int(profile.working_age)+int(profile.dependents)).is_equal(int(profile.total))
	assert_float(float(profile.median_age)).is_between(0.0,76.0)
	assert_float(float(profile.dependents_per_100_workers)).is_greater_equal(0.0)
	assert_float(float(profile.projected_life_expectancy)).is_between(1.0,110.0)
	assert_int(int(profile.recorded_deaths)).is_equal(0)
