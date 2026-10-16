extends GdUnitTestSuite
## The view must stay a retained reader; only explicit callbacks can act.
const View = preload("res://scripts/hud/home_lives_view.gd")
var view: VBoxContainer
var comparisons := 0
var actions: Array[String] = []

func before_test() -> void:
	comparisons = 0
	actions = []
	view = View.new()
	add_child(view)
	view.size = Vector2(1068, 800)
	view.setup(_block())

func after_test() -> void:
	if is_instance_valid(view): view.free()

func _act(key: String) -> void:
	actions.append(key)

func _compare() -> Dictionary:
	comparisons += 1
	return {"ok": true, "before": {"care": {"target": .5}, "food": {"net": 4.0}},
		"after": {"care": {"target": .7}, "food": {"production": 85.0, "eaten": 90.0, "required": 90.0, "spoilage": 1.0, "net": -6.0}},
		"actual_transfers": [{"role": "Food", "delta": -5}, {"role": "Administration", "delta": 5}],
		"warnings": [{"text": "The preview reaches a food shortage."}], "risk_note": "No future infant-risk forecast."}

func _block() -> Dictionary:
	return {"type": "settlement_overview", "lives": {"ok": true, "day": 45, "scope": {"id": "home", "name": "Our camp"},
		"population": {"current": 93, "year_start_known": false, "vitals": {"known": true, "births": 4, "deaths": 2, "natural_change": 2, "from_day": 10, "to_day": 45}},
		"conditions": {"food": {"known": true, "production": 95.0, "required": 90.0, "eaten": 90.0, "spoilage": 1.0, "net": 4.0, "stock": 900.0, "stored_days": 10.0, "intake_ratio": 1.0},
			"water": {"known": false}, "care": {"known": true, "current": .4, "target": .5, "assigned": 5, "workers": 4.5, "settle_days": 60},
			"housing": {"capacity": 100, "population": 93, "spare": 7, "coverage": 1.0, "quality": .2, "illness_factor": .96, "upkeep": .9},
			"infant_risk": {"known": true, "per_100": 17.3, "note": "Projected risk, not recorded deaths."}},
		"research": {"known": true, "known_count": 8, "adopted_count": 5, "current": {}},
		"culture": {"known": false}, "regard": {"known": false}, "foundations": {}},
		"leader": {"name": "Ari", "age": 50}, "compare_care": _compare,
		"on_assign_care": _act.bind("care"), "on_leader": _act.bind("leader"), "on_people": _act.bind("people"),
		"on_leaders": _act.bind("delegation"), "ruler_sets_work": true,
		"works": {"progress": [], "offers": [{"id": "water", "title": "Collect rain", "sentence": "Collect water at the homes.", "cost": "20 timber", "action": "Start rain collection", "on_press": _act.bind("water")}]}}

func test_reading_and_refresh_never_evaluate_or_act_and_keep_named_nodes() -> void:
	var portrait := view.find_child("HomePortrait", true, false)
	var risk := view.find_child("RiskValue", true, false)
	var button := view.find_child("CareCompare", true, false)
	var update := _block()
	update.lives.population.current = 94
	assert_bool(view.update_block(update)).is_true()
	assert_object(view.find_child("HomePortrait", true, false)).is_same(portrait)
	assert_object(view.find_child("RiskValue", true, false)).is_same(risk)
	assert_object(view.find_child("CareCompare", true, false)).is_same(button)
	assert_int(comparisons).is_equal(0)
	assert_array(actions).is_empty()
	assert_str(view._refs.population.text).is_equal("94 people")

func test_comparison_is_lazy_keeps_current_risk_and_current_restores_reading() -> void:
	var original := String(view.find_child("RiskValue", true, false).text)
	view.find_child("CareCompare", true, false).pressed.emit()
	assert_int(comparisons).is_equal(1)
	assert_bool(view.comparison_active).is_true()
	assert_str(view.find_child("RiskValue", true, false).text).is_equal(original)
	assert_str(view._refs.comparison.text).contains("food shortage")
	assert_str(view._refs.comparison.text).contains("All towns:")
	assert_str(view._refs.balance.text).contains("−6")
	assert_array(actions).is_empty()
	view.find_child("CareCurrent", true, false).pressed.emit()
	assert_bool(view.comparison_active).is_false()
	assert_str(view._refs.balance.text).contains("+4")
	assert_int(comparisons).is_equal(1)

func test_same_day_changed_conditions_invalidate_the_old_comparison() -> void:
	view.find_child("CareCompare", true, false).pressed.emit()
	var fresh := _block()
	fresh.lives.conditions.care.assigned = 8
	view.update_block(fresh)
	assert_bool(view.comparison_active).is_false()
	assert_int(comparisons).is_equal(1)

func test_preserved_callbacks_use_the_current_provider_and_blocked_work_cannot_start() -> void:
	view.find_child("AssignCare", true, false).pressed.emit()
	view.find_child("TalkToLeader", true, false).pressed.emit()
	view.find_child("BackToLeaders", true, false).pressed.emit()
	view.find_child("StartSelectedWork", true, false).pressed.emit()
	assert_array(actions).is_equal(["care", "leader", "delegation", "water"])
	var fresh := _block()
	fresh.works.offers[0].blocked = "Not enough timber"
	view.update_block(fresh)
	view.find_child("StartSelectedWork", true, false).pressed.emit()
	assert_int(actions.size()).is_equal(4)
	assert_bool(view.find_child("StartSelectedWork", true, false).disabled).is_true()

func test_missing_measurements_are_not_presented_as_zero_coverage_or_recorded_deaths() -> void:
	assert_str(view._drivers.water.value.text).is_equal("—")
	assert_str(view._refs.year.text).is_equal("No dated baseline")
	assert_str(view._refs.vital_period.text).contains("natural change +2")
	assert_str(view._refs.risk_note.text).contains("not recorded deaths")
	assert_str(view._refs.foundations.text).contains("not measured")
	assert_str(view._refs.watch.text).contains("not measured")

func test_unavailable_comparison_does_not_create_a_food_measurement() -> void:
	var block := _block()
	block.lives.conditions.food = {"known": false}
	block.compare_care = func() -> Dictionary: return {"ok": false, "reason": "No estimate available."}
	view.update_block(block)
	view.find_child("CareCompare", true, false).pressed.emit()
	assert_dict(view._food_graph.reading).is_empty()
	assert_str(view._refs.food_period.text).not_contains("Compared assignment")
	assert_str(view._refs.balance.text).is_equal("No daily balance recorded")

func test_cross_town_starvation_warning_precedes_water_and_safeguard_notes() -> void:
	var block := _block()
	block.compare_care = func() -> Dictionary:
		var result := _compare()
		result.warnings = [{"kind": "water", "text": "Our town: low water."}, {"kind": "safeguard", "text": "Our town: food protection."}, {"kind": "starvation", "text": "South town: starvation risk."}]
		return result
	view.update_block(block)
	view.find_child("CareCompare", true, false).pressed.emit()
	assert_str(view._refs.comparison.text).contains("South town: starvation risk.")
	assert_str(view._refs.comparison.text).not_contains("Our town: low water.")

func test_portrait_reserves_its_aspect_and_comparison_targets_keep_their_geometry() -> void:
	for frame in 4: await get_tree().process_frame
	assert_bool(view._hero.vertical).is_false()
	var frame_rect: Rect2 = view._picture_frame.get_global_rect()
	var picture_rect: Rect2 = view._portrait.get_global_rect()
	assert_bool(frame_rect.grow(1).encloses(picture_rect)).is_true()
	assert_float(frame_rect.size.y).is_greater(100.0)
	var current: Rect2 = view.find_child("CareCurrent", true, false).get_global_rect()
	var compare: Rect2 = view.find_child("CareCompare", true, false).get_global_rect()
	var assign: Rect2 = view.find_child("AssignCare", true, false).get_global_rect()
	view.find_child("CareCompare", true, false).pressed.emit()
	for frame in 4: await get_tree().process_frame
	assert_object(view.find_child("CareCurrent", true, false).get_global_rect()).is_equal(current)
	assert_object(view.find_child("CareCompare", true, false).get_global_rect()).is_equal(compare)
	assert_object(view.find_child("AssignCare", true, false).get_global_rect()).is_equal(assign)
