extends GdUnitTestSuite

const Impacts = preload("res://scripts/hud/people_work_impacts.gd")

func _result() -> Dictionary:
	var plan := {"food": {"production": 100.0, "required": 90.0},
		"effective_workers": {"Extraction": 6.0}, "water": {"known": false},
		"work_impacts": {"survey_target": 60.0, "finds_month": 1.2, "extracted_today": 8.5,
			"making_capacity": 4.0, "goods_room": 20.0, "fresh_rot_cut": 25.0,
			"harvest_reach": 12.5, "care_target": 50.0, "stored_rot_cut": 40.0,
			"guard": 6.0, "guard_need": 8.0, "armed": 75.0},
		"research": {"effective_work": 2.5, "teams": 3, "goods_a_day": 1.5},
		"construction": {"homes": 2.0, "repair": 1.0, "repair_want": 3.0, "fabric": 4.0, "housing": {}}}
	return {"ok": true, "before": plan.duplicate(true), "after": plan.duplicate(true)}

func test_every_role_has_bounded_practical_readings_with_units_and_explanations() -> void:
	var result := _result()
	var original := result.duplicate(true)
	for role: String in ["Food", "Survey", "Extraction", "Construction", "Crafting", "Logistics", "Knowledge", "Administration", "Defense"]:
		var readings := Impacts.readings(result, role)
		assert_int(readings.size()).is_between(1, 3)
		for reading: Dictionary in readings:
			assert_str(reading.unit).is_not_empty()
			assert_str(reading.note).is_not_empty()
			assert_bool(is_finite(float(reading.after))).is_true()
	assert_dict(result).is_equal(original)

func test_care_target_is_not_presented_as_instant_health_or_death_change() -> void:
	var result := _result()
	result.after.work_impacts.care_target = 75.0
	var readings := Impacts.readings(result, "Administration", "", true)
	assert_str(readings[0].label).contains("settles toward")
	assert_str(readings[0].words).contains("50 → 75 %")
	assert_str(readings[0].note).contains("60 days")
	assert_bool(str(readings).contains("deaths")).is_false()

func test_unmeasured_water_is_omitted_instead_of_claiming_zero_collection() -> void:
	var result := _result()
	assert_int(Impacts.readings(result, "Logistics").size()).is_equal(2)
	result.after.water = {"known": true, "collected": 150.0, "required": 120.0}
	result.before.water = {"known": true, "collected": 100.0, "required": 120.0}
	var readings := Impacts.readings(result, "Logistics", "", true)
	assert_int(readings.size()).is_equal(3)
	assert_float(float(readings[0].need)).is_equal(120.0)
	assert_str(readings[0].words).is_equal("100 → 150 water/day")

func test_capacity_and_observed_extraction_are_explicit_not_promised_output() -> void:
	var result := _result()
	result.after.effective_workers.Extraction = 9.0
	var readings := Impacts.readings(result, "Extraction", "", true)
	assert_str(readings[0].words).is_equal("6 → 9 fit workers")
	assert_str(readings[1].label).is_equal("Last measured extraction")
	assert_str(readings[1].words).is_equal("8.5 loads/day")
	assert_str(Impacts.readings(result, "Crafting")[0].label).contains("before supply limits")

func test_housing_reads_selected_town_and_does_not_compare_stopped_work_to_zero_days() -> void:
	var result := _result()
	result.before.construction.towns = [{"id": "first", "construction": {"housing": {"building": false, "work_per_day": 0, "days_left": -1}}}]
	result.after.construction.towns = [{"id": "first", "construction": {"housing": {"building": true, "work_per_day": 2.0, "days_left": 15.0, "batch": 12}}}, {"id": "other", "construction": {"housing": {"building": true, "work_per_day": 1.0, "days_left": 99.0, "batch": 8}}}]
	var readings := Impacts.readings(result, "Construction", "first", true)
	assert_str(readings[0].words).is_equal("About 15 days with this crew")
	assert_str(readings[0].label).contains("12 home places")
	assert_bool(readings[0].lower_better).is_true()

func test_failed_forecast_does_not_display_invented_zero_impacts() -> void:
	assert_array(Impacts.readings({"ok": false}, "Knowledge")).is_empty()
