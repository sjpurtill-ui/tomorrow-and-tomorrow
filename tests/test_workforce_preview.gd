extends GdUnitTestSuite

const Preview = preload("res://scripts/hud/workforce_preview.gd")
const Manual = preload("res://scripts/manual_work.gd")

var _processing: Dictionary = {}

func before() -> void:
	for name: String in WorldSimulation.OWNED_SYSTEMS:
		var node := WorldSimulation.system(name)
		_processing[node] = node.is_processing()
		node.set_process(false)

func after() -> void:
	WorldSimulation.clear()
	# Do not resume the synthetic mature realm while the test reporter drains.
	GameState.reset_for_new_world(78154)
	MilitaryCampaign.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	ForeignDiplomacy.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	ResourceSystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	PeopleDirection.reset_for_new_world()
	ProgressionSystem.reset_for_new_world()
	for node: Node in _processing: node.set_process(bool(_processing[node]))

func before_test() -> void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(78154)
	GameState.civic_api_enabled = false
	ResourceSystem.reset_for_new_world()
	FoodSystem.reset_for_new_world()
	SettlementModel.reset_for_new_world()
	DiscoverySystem.reset_for_new_world()
	MilitaryCampaign.reset_for_new_world()
	CivilizationSystem.reset_for_new_world()
	GovernmentPeopleSystem.reset_for_new_world()
	PeopleDirection.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.ensure_population_total(120)
	GameState.settlement_name = "Preview town"
	GameState.settlement_site_committed = true
	GameState.settlement_completed.assign(["Hearth Circle", "Lean-to Shelters"])
	GameState.elapsed_days = 365.0 * 10.0 + 40.0
	GameState.food_stocks = {"Fresh food": 20.0, "Stored food": 900.0}
	GameState.resource_stockpiles = {"Food": 920.0, "Timber": 100.0, "Fiber Plants": 100.0, "Civilian Goods": 50.0, "Freshwater": 50.0}
	ResourceSystem.initialized = true
	FoodSystem.initialized = true
	DiscoverySystem.initialize()
	PeopleDirection.ensure()
	PeopleDirection.automatic_work = true
	# Keep this fixture independent of yesterday's food alarm.
	GameState.simulation_metrics.merge({"food_production": 120.0, "food_consumption": 100.0, "food_spoilage": 0.0,
		"food_net": 20.0, "food_projected_days": 9999.0, "food_total_stock": 920.0,
		"food_intake_ratio": 1.0, "food_labor_share": 0.42, "food_forecast_90": {"first_shortage_day": -1}}, true)
	var hands := float(GameState.effective_workers("Logistics")) + float(GameState.effective_workers("Food")) * 0.22
	GameState.water_metrics = {"required_today": 120.0, "total_required_today": 120.0, "collected_today": 120.0,
		"household_collected_today": 40.0, "organized_collection_capacity": 80.0, "collection_workers": hands,
		"intake_ratio": 1.0, "source_accessible": true, "stored": 50.0}

func test_delegated_capture_uses_current_heads_and_steps_conserve_every_worker() -> void:
	PeopleDirection.work_baseline = {"Food": 100.0}
	var draft := Preview.capture()
	assert_dict(draft.shares).is_equal(Manual._shares_of(Manual.counts()))
	var original := draft.duplicate(true)
	var changed := Preview.step(draft, "Knowledge", 17)
	assert_dict(draft).is_equal(original)
	assert_int(int(Preview._sum(changed.shares))).is_equal(100)
	assert_int(int(Preview._sum(changed.counts))).is_equal(int(draft.able))
	assert_int(int(changed.shares.Knowledge)).is_equal(int(Manual.percents(draft.shares).Knowledge) + 17)
	assert_array(changed.commands).is_equal([{"role": "Knowledge", "points": 17}])

func test_steps_match_original_move_share_including_ties_and_negative_points() -> void:
	var draft := Preview.capture()
	for command in [["Knowledge", 19], ["Construction", 8], ["Food", -9], ["Knowledge", -1000]]:
		draft = Preview.step(draft, command[0], command[1])
	# Replay the original command function on detached models only. No cities
	# means delegation cannot publish a town-feeding Chronicle entry.
	var expected := Preview._isolated(draft._snapshot, func() -> Dictionary:
		WorldSimulation.government.initializing = true
		for command: Dictionary in draft.commands: Manual.move_share(command.role, command.points)
		WorldSimulation.government.initializing = false
		return {"shares": Manual.percents(), "counts": Manual.counts()})
	assert_dict(draft.shares).is_equal(expected.shares)
	assert_dict(draft.counts).is_equal(expected.counts)
	assert_int(int(Preview._sum(draft.counts))).is_equal(int(draft.able))

func test_net_zero_draft_does_not_take_control_or_round_the_original_split() -> void:
	var captured := Preview.capture()
	var draft := Preview.step(Preview.step(captured, "Knowledge", 1), "Knowledge", -1)
	assert_bool(draft.has_changes).is_false()
	assert_array(draft.commands).is_empty()
	assert_dict(draft.shares).is_equal(captured.shares)
	assert_dict(draft.counts).is_equal(captured.counts)
	var result := Preview.evaluate(draft)
	assert_dict(result.before).is_equal(result.after)
	assert_bool(PeopleDirection.automatic_work).is_true()

func test_preview_is_deterministic_and_never_changes_live_ledgers_rng_or_scope() -> void:
	var live := Preview._capture_systems()
	var active := WorldSimulation._active
	var bindings: Array = []
	for field: String in Preview.BINDINGS: bindings.append(WorldSimulation.get(field))
	var draft := Preview.step(Preview.capture(), "Knowledge", 10)
	var original_draft := draft.duplicate(true)
	var first := Preview.evaluate(draft)
	assert_bool(first.ok).is_true()
	assert_dict(Preview.evaluate(draft)).is_equal(first)
	assert_dict(draft).is_equal(original_draft)
	assert_dict(Preview._capture_systems()).is_equal(live)
	assert_dict(WorldSimulation._active).is_equal(active)
	for index in Preview.BINDINGS.size(): assert_object(WorldSimulation.get(Preview.BINDINGS[index])).is_same(bindings[index])
	assert_bool(Preview.is_current(draft)).is_true()
	assert_int(WorldSimulation.span).is_equal(1)

func test_food_matches_existing_calculator_and_risk_is_not_a_death_prediction() -> void:
	GameState.food_stocks = {"Fresh food": 0.0, "Stored food": 0.0}
	GameState.resource_stockpiles.Food = 0.0
	var draft := Preview.step(Preview.capture(), "Food", -100)
	var result := Preview.evaluate(draft)
	assert_bool(result.ok).is_true()
	assert_str(result.after.food.hunger_risk).is_equal("now")
	assert_int(result.after.food.shortage_day).is_equal(0)
	assert_float(float(result.after.food.production)).is_equal(0.0)
	assert_bool(result.warnings.any(func(w: Dictionary) -> bool: return w.kind == "starvation")).is_true()
	assert_bool(result.after.food.has("deaths")).is_false()
	var expected := Preview._isolated(draft._snapshot, func() -> Dictionary:
		Preview._lay_requested_split(draft.shares)
		WorldSimulation.state.simulation_metrics.erase("food_forecast_day")
		return WorldSimulation.food._process_local_day({"traveling": false}, 0.72, 0.88))
	assert_float(float(result.after.food.required)).is_equal_approx(float(expected.food_consumption), 0.00001)
	assert_float(float(result.after.food.net)).is_equal_approx(float(expected.food_net), 0.00001)
	assert_dict(result.after.food.forecast90).is_equal(expected.food_forecast_90)

func test_practical_impacts_follow_effective_assignment_without_instant_care_or_inventory() -> void:
	var impacts := preload("res://scripts/hud/people_work_impacts.gd")
	var care := preload("res://scripts/food_care.gd")
	var live := Preview._capture_systems()
	var draft := Preview.step(Preview.capture(), "Administration", 10)
	var result := Preview.evaluate(draft)
	var expected := Preview._isolated(draft._snapshot, func() -> Dictionary:
		Preview._replay(draft)
		return impacts.local_reading())
	assert_float(float(result.after.work_impacts.care_target)).is_equal_approx(float(expected.care_target), 0.000001)
	assert_float(float(result.after.work_impacts.stored_rot_cut)).is_equal_approx(float(expected.stored_rot_cut), 0.000001)
	assert_float(float(result.after.work_impacts.care_current)).is_equal_approx(float(result.before.work_impacts.care_current), 0.000001)
	assert_float(float(result.after.work_impacts.extracted_today)).is_equal_approx(float(result.before.work_impacts.extracted_today), 0.000001)
	assert_float(float(result.after.work_impacts.care_target)).is_greater_equal(float(result.before.work_impacts.care_target))
	assert_float(float(result.after.work_impacts.stored_rot_cut)).is_less_equal(care.KEEP_STORED_CUT * 100.0)
	assert_dict(Preview._capture_systems()).is_equal(live)

func test_validated_state_becomes_stale_when_food_or_workers_or_day_changes() -> void:
	var draft := Preview.capture()
	assert_bool(Preview.is_current(draft)).is_true()
	DiscoverySystem._scan.scores["ui-only-question"] = 12.0
	DiscoverySystem.society_model._today.sources_key += 1
	assert_bool(Preview.is_current(draft)).is_true()
	GameState.food_stocks["Stored food"] += 1.0
	assert_bool(Preview.is_current(draft)).is_false()
	draft = Preview.capture()
	GameState.population_allocations.Food += 1
	assert_bool(Preview.is_current(draft)).is_false()
	draft = Preview.capture()
	GameState.elapsed_days += 1.0
	assert_bool(Preview.is_current(draft)).is_false()
	assert_bool(Preview.evaluate(draft).stale).is_true()

func test_food_safeguard_is_applied_on_the_copy_and_disclosed() -> void:
	SettlementModel.ensure_founded()
	GameState.simulation_metrics.merge({"food_production": 10.0, "food_consumption": 120.0,
		"food_total_stock": 10.0, "food_net": -110.0, "food_projected_days": 0.1, "food_intake_ratio": 0.5}, true)
	GameState.food_stocks = {"Fresh food": 0.0, "Stored food": 10.0}
	var live := Preview._capture_systems()
	var draft := Preview.step(Preview.capture(), "Food", -20)
	var result := Preview.evaluate(draft)
	assert_bool(result.ok).is_true()
	assert_int(int(result.after.counts.Food)).is_greater(int(draft.counts.Food))
	assert_bool(result.warnings.any(func(w: Dictionary) -> bool: return w.kind == "safeguard")).is_true()
	assert_int(int(Preview._sum(result.after.counts))).is_equal(int(draft.able))
	assert_dict(Preview._capture_systems()).is_equal(live)

func test_legacy_food_measurement_replays_each_safeguard_intervention() -> void:
	SettlementModel.ensure_founded()
	GameState.simulation_metrics.merge({"food_production": 95.0, "food_consumption": 100.0,
		"food_total_stock": 2500.0, "food_net": -5.0, "food_projected_days": 20.0, "food_intake_ratio": 1.0}, true)
	GameState.simulation_metrics.erase("food_labor_share")
	var draft := Preview.capture()
	for index in 4: draft = Preview.step(draft, "Construction", 1)
	var result := Preview.evaluate(draft)
	var original := Preview._isolated(draft._snapshot, func() -> Dictionary:
		if not Manual.manual(): Manual.set_manual(true)
		for command: Dictionary in draft.commands: Manual.move_share(command.role, command.points)
		return {"counts": Manual.counts(), "towns": WorldSimulation.state.player_settlements.duplicate(true)})
	assert_dict(result.after.counts).is_equal(original.counts)
	assert_dict(result.after.towns[0].safeguard.allocations).is_equal(original.towns[0].local_allocations)
	assert_bool(Preview.is_current(draft)).is_true()

func test_research_construction_and_water_are_real_capacity_readings() -> void:
	var draft := Preview.capture()
	var learning := Preview.evaluate(Preview.step(draft, "Knowledge", 15))
	assert_float(float(learning.after.research.work)).is_greater(float(learning.before.research.work))
	assert_float(float(learning.after.research.goods_a_day)).is_greater(float(learning.before.research.goods_a_day))
	var building := Preview.evaluate(Preview.step(draft, "Construction", 15))
	assert_float(float(building.after.construction.builders)).is_greater(float(building.before.construction.builders))
	var carrying := Preview.evaluate(Preview.step(draft, "Logistics", 15))
	assert_bool(carrying.after.water.estimate).is_true()
	assert_float(float(carrying.after.water.collected)).is_greater(float(carrying.before.water.collected))
	assert_bool(carrying.after.materials.forecast_available).is_false()

func test_missing_water_measurement_is_unknown_and_invalid_drafts_restore_scope() -> void:
	GameState.water_metrics = {}
	var draft := Preview.capture()
	assert_bool(Preview.evaluate(draft).after.water.known).is_false()
	assert_dict(Preview.step(draft, "invented role", 2)).is_equal(draft)
	assert_bool(Preview.evaluate({}).ok).is_false()
	var state := WorldSimulation.state
	assert_dict(Preview._isolated(draft._snapshot, func() -> Dictionary: return {})).is_empty()
	assert_dict(Preview._isolated(draft._snapshot, func() -> Variant: return null)).is_empty()
	assert_dict(Preview._isolated({}, func() -> Dictionary: return {})).is_empty()
	assert_object(WorldSimulation.state).is_same(state)
	assert_bool(Preview._busy).is_false()

func test_snapshot_contains_only_detached_data_and_preview_cost_is_measured() -> void:
	# An ordinary court/leader read warms a cache containing the live state.
	# It must not escape into a detached workforce or Home care preview.
	GovernmentPeopleSystem.officeholder("head_of_government")
	var started := Time.get_ticks_usec()
	var draft := Preview.capture()
	var captured := Time.get_ticks_usec()
	assert_bool(_has_reference(draft._snapshot)).is_false()
	var evaluating := Time.get_ticks_usec()
	var result := Preview.evaluate(Preview.step(draft, "Construction", 4))
	var evaluated := Time.get_ticks_usec()
	assert_bool(result.ok).is_true()
	print("Workforce preview capture %.1fms; evaluate %.1fms" % [float(captured - started) / 1000.0, float(evaluated - evaluating) / 1000.0])
	for name: String in draft._snapshot:
		var tick := Time.get_ticks_usec()
		var record := Preview._freeze_object(WorldSimulation.system(name))
		var took := float(Time.get_ticks_usec() - tick) / 1000.0
		if took > 10.0: print("Preview snapshot %s %.1fms, %.1fKB" % [name, took, var_to_bytes(record).size() / 1024.0])

func test_two_towns_retain_separate_food_risks_and_match_original_delegation() -> void:
	SettlementModel.ensure_founded()
	GameState.player_settlements.append({"id": "second", "name": "Other bank", "primary": false,
		"position": Vector2(9, 4), "population_share": 0.25, "founded_day": 0})
	SettlementModel.with_city_resources("second", func() -> void:
		GameState.food_stocks = {"Fresh food": 0.0, "Stored food": 0.0}
		GameState.simulation_metrics.merge({"food_production": 0.0, "food_consumption": 30.0,
			"food_total_stock": 0.0, "food_intake_ratio": 0.0}, true))
	var draft := Preview.step(Preview.capture(), "Construction", 12)
	var result := Preview.evaluate(draft)
	assert_bool(result.ok).is_true()
	assert_int(result.after.towns.size()).is_equal(2)
	assert_float(float(result.after.food.stock)).is_equal_approx(float(result.after.towns[0].food.stock) + float(result.after.towns[1].food.stock), 0.00001)
	assert_bool(result.after.towns[1].safeguard.active).is_true()
	assert_bool(result.after.construction.housing.is_empty()).is_true()
	var actual := Preview._isolated(draft._snapshot, func() -> Dictionary:
		for command: Dictionary in draft.commands: Manual.move_share(command.role, command.points)
		return {"counts": Manual.counts()})
	assert_dict(result.after.counts).is_equal(actual.counts)
	assert_bool(Preview.is_current(draft)).is_true()

func _has_reference(value: Variant) -> bool:
	if typeof(value) in [TYPE_OBJECT, TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID]: return true
	if value is Dictionary:
		for key in value:
			if _has_reference(key) or _has_reference(value[key]): return true
	elif value is Array:
		for item in value:
			if _has_reference(item): return true
	return false

func test_mature_realm_latency_and_ledgers() -> void:
	GameState.ensure_population_total(30000)
	GameState.elapsed_days = 1200.0 * 365.0 + 40.0
	GameState.housing_capacity = 31000
	GameState.food_stocks = {"Fresh food": 10000.0, "Stored food": 900000.0}
	for definition: Dictionary in DiscoverySystem.technology_catalog:
		if int(definition.get("day", 0)) > int(GameState.elapsed_days): continue
		var id := String(definition.get("id", ""))
		if id not in GameState.known_discoveries: GameState.known_discoveries.append(id)
		GameState.discovery_adoption[id] = 0.6
	SettlementModel.ensure_founded()
	for day in 370:
		GameState.food_history.append({"day": int(GameState.elapsed_days) - 370 + day, "stored": 900000.0, "produced": 30000.0, "required": 29500.0, "eaten": 29500.0, "spoiled": 100.0, "net": 400.0})
	var past := GameState.food_history.duplicate(true)
	for index in 18:
		var id := "town-%d" % index
		GameState.player_settlements.append({"id": id, "name": "Town %d" % index, "primary": false,
			"position": Vector2(index * 8.0, 9.0), "population_share": 0.025, "founded_day": 200 * 365})
		SettlementModel.with_city_resources(id, func() -> void:
			GameState.food_stocks = {"Fresh food": 800.0, "Stored food": 70000.0}
			GameState.food_history.assign(past.duplicate(true)))
	var tick := Time.get_ticks_usec()
	var captured := Preview.capture()
	var after_capture := Time.get_ticks_usec()
	var draft := Preview.step(captured, "Construction", 4)
	var after_step := Time.get_ticks_usec()
	var result := Preview.evaluate(draft)
	var after_evaluate := Time.get_ticks_usec()
	var next := Preview.evaluate(Preview.step(draft, "Construction", 1))
	var after_next := Time.get_ticks_usec()
	assert_bool(Preview.is_current(draft)).is_true()
	var after_current := Time.get_ticks_usec()
	assert_bool(result.ok).is_true()
	assert_bool(next.ok).is_true()
	assert_int(result.after.towns.size()).is_equal(19)
	assert_int(int(Preview._sum(result.after.counts))).is_equal(int(captured.able))
	print("Mature workforce preview: %d discoveries,19 towns, capture %.1fms step %.1fms first %.1fms next %.1fms check %.1fms" % [GameState.known_discoveries.size(), float(after_capture-tick)/1000.0, float(after_step-after_capture)/1000.0, float(after_evaluate-after_step)/1000.0, float(after_next-after_evaluate)/1000.0, float(after_current-after_next)/1000.0])
