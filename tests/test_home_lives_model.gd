extends GdUnitTestSuite

const Model = preload("res://scripts/hud/home_lives_model.gd")
const Preview = preload("res://scripts/hud/workforce_preview.gd")
const Manual = preload("res://scripts/manual_work.gd")
const History = preload("res://scripts/strategic_history.gd")
var _processing: Dictionary = {}

func before() -> void:
	for name: String in WorldSimulation.OWNED_SYSTEMS:
		var node := WorldSimulation.system(name)
		_processing[node] = node.is_processing()
		node.set_process(false)

func after() -> void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(78154)
	for node in [MilitaryCampaign, GovernmentPeopleSystem, ForeignDiplomacy, CivilizationSystem, FoodSystem, DiscoverySystem, ResourceSystem, SettlementModel, PeopleDirection, ProgressionSystem]: node.reset_for_new_world()
	for node: Node in _processing: node.set_process(bool(_processing[node]))

func before_test() -> void:
	WorldSimulation.clear()
	GameState.reset_for_new_world(78154)
	GameState.civic_api_enabled = false
	for node in [ResourceSystem, FoodSystem, SettlementModel, DiscoverySystem, MilitaryCampaign, CivilizationSystem, GovernmentPeopleSystem, PeopleDirection]: node.reset_for_new_world()
	GameState.initialize_population_model()
	GameState.ensure_population_total(120)
	GameState.settlement_name = "First hearth"
	GameState.settlement_site_committed = true
	GameState.settlement_completed.assign(["Hearth Circle", "Lean-to Shelters"])
	GameState.elapsed_days = 3690.0
	GameState.housing_capacity = 180
	GameState.food_stocks = {"Fresh food": 20.0, "Stored food": 900.0}
	GameState.resource_stockpiles = {"Food": 920.0, "Timber": 100.0, "Fiber Plants": 100.0, "Civilian Goods": 50.0, "Freshwater": 50.0}
	ResourceSystem.initialized = true
	FoodSystem.initialized = true
	DiscoverySystem.initialize()
	PeopleDirection.ensure()
	PeopleDirection.automatic_work = true
	GameState.simulation_metrics.merge({"food_production": 120.0, "food_consumption": 100.0, "food_eaten": 100.0, "food_spoilage": 2.0,
		"food_net": 18.0, "food_projected_days": 9999.0, "food_total_stock": 920.0,
		"food_intake_ratio": 1.0, "food_labor_share": 0.42, "food_forecast_90": {"first_shortage_day": -1}}, true)
	var hands := float(GameState.effective_workers("Logistics")) + float(GameState.effective_workers("Food")) * 0.22
	GameState.water_metrics = {"required_today": 120.0, "total_required_today": 120.0, "collected_today": 120.0,
		"household_collected_today": 40.0, "organized_collection_capacity": 80.0, "collection_workers": hands,
		"intake_ratio": 1.0, "source_accessible": true, "stored": 50.0}
	Model._comparison_draft = {}; Model._comparison_result = {}; Model._comparison_key = ""

func test_snapshot_is_read_only_even_when_older_save_defaults_are_missing() -> void:
	SettlementModel.ensure_founded()
	GameState.built_fabric = {}; GameState.fabric_realm = {}
	GameState.early_care = {}; GameState.early_care_blend = 0.42
	PeopleDirection.cultural_memory = {}
	MilitaryCampaign.settlement_defense = {}
	# Older saves can have no sex-by-age/cohort summary. Read helpers normalize
	# these lazily; even those repairs must stay inside this reader's guard.
	GameState.population_cohorts.erase("working_age")
	GameState.population_cohorts.erase("female")
	GameState.pregnancy_cohorts = {}
	var before := Preview._capture_systems()
	var bindings: Array = []
	for field: String in Preview.BINDINGS: bindings.append(WorldSimulation.get(field))
	var active := WorldSimulation._active.duplicate(true)
	var start := Time.get_ticks_usec()
	var result := Model.snapshot()
	print("HOME_LIVES_SNAPSHOT_MS ", (Time.get_ticks_usec() - start) / 1000.0)
	assert_bool(result.ok).is_true()
	assert_array(_changed_fields(before, Preview._capture_systems())).is_empty()
	assert_dict(WorldSimulation._active).is_equal(active)
	for index in Preview.BINDINGS.size(): assert_object(WorldSimulation.get(Preview.BINDINGS[index])).is_same(bindings[index])
	assert_bool(SettlementModel._local_population_scope).is_false()
	assert_float(float(result.conditions.food.stock)).is_equal(920.0)
	assert_float(float(result.conditions.food.net)).is_equal(18.0)
	assert_int(int(result.conditions.housing.capacity)).is_equal(180)
	assert_int(int(result.conditions.housing.spare)).is_equal(60)
	assert_str(result.conditions.infant_risk.period).is_equal("Before the first birthday")

func test_two_towns_keep_population_receipts_reserves_and_housing_local() -> void:
	var second := _two_towns()
	var primary: Dictionary = GameState.player_settlements[0]
	primary["population_state"] = {"population": 90, "vital_statistics_tracking_start_day": 3680,
		"vital_statistics_history": [{"day": 3685, "births": 3, "deaths": 1}]}
	second["population_state"] = {"population": 30, "vital_statistics_tracking_start_day": 3688,
		"vital_statistics_history": [{"day": 3688, "births": 1, "deaths": 4}, {"day": 3690, "births": 2, "deaths": 0}]}
	GameState.chronicle = {"year_acc": {"year": 10, "pop0": 100, "born": 99, "buried": 88}}
	History.record(GameState.strategic_history, 3650, {"second": {"population": 31}, String(primary.id): {"population": 89}})
	var before := Preview._capture_systems()
	var a := Model.snapshot(String(primary.id))
	var b := Model.snapshot("second")
	assert_int(int(a.population.current)).is_equal(90)
	assert_int(int(b.population.current)).is_equal(30)
	assert_int(int(b.scope.national_population)).is_equal(120)
	assert_int(int(b.population.year_delta)).is_equal(-1)
	assert_int(int(b.population.vitals.births)).is_equal(3)
	assert_int(int(b.population.vitals.deaths)).is_equal(4)
	assert_int(int(b.population.vitals.natural_change)).is_equal(-1)
	assert_int(int(b.population.vitals.tracked_days)).is_equal(3)
	assert_float(float(a.conditions.food.stock)).is_equal(920.0)
	assert_float(float(b.conditions.food.stock)).is_equal(7.0)
	assert_int(int(b.conditions.housing.capacity)).is_equal(40)
	assert_array(_changed_fields(before, Preview._capture_systems())).is_empty()
	assert_bool(b.population.has("other")).is_false()

func test_missing_reports_are_unknown_and_no_national_year_start_is_assigned_to_satellite() -> void:
	_two_towns()
	GameState.chronicle = {"year_acc": {"year": 10, "pop0": 119}}
	SettlementModel.with_city_resources("second", func() -> void:
		GameState.simulation_metrics = {}; GameState.water_metrics = {})
	var result := Model.snapshot("second")
	assert_bool(result.population.year_start_known).is_false()
	assert_bool(result.population.vitals.known).is_false()
	assert_bool(result.conditions.food.known).is_false()
	assert_bool(result.conditions.water.known).is_false()
	assert_float(float(result.conditions.food.required)).is_equal(-1.0)
	assert_bool(result.regard.known).is_false()

func test_uninitialized_direction_is_not_initialized_by_opening_home() -> void:
	PeopleDirection.initialized = false
	PeopleDirection.ambition = "makers"
	var before := Preview._capture_systems()
	assert_bool(Model.snapshot().ok).is_false()
	assert_array(_changed_fields(before, Preview._capture_systems())).is_empty()

func test_midyear_accumulator_and_zero_demand_water_are_not_measurements() -> void:
	GameState.chronicle = {"year_acc": {"year": 10, "pop0": 118}}
	GameState.water_metrics = {"intake_ratio": 0.0, "required_today": 0.0, "collected_today": 0.0}
	var result := Model.snapshot()
	assert_bool(result.population.year_start_known).is_false()
	assert_bool(result.conditions.water.known).is_false()

func test_research_reports_adoption_without_primary_supply_or_unproved_fallback() -> void:
	GameState.known_discoveries.assign(["clean_water"])
	GameState.discovery_adoption = {"clean_water": 0.75}
	GameState.water_metrics.intake_ratio = 0.0
	GameState.active_investigations = {}
	var result := Model.snapshot()
	assert_dict(result.research.current).is_empty()
	assert_int(int(result.research.adopted_count)).is_equal(1)
	var id := ""
	for item: Dictionary in DiscoverySystem.catalog:
		if not GameState.known_discoveries.has(String(item.id)): id = String(item.id); break
	assert_str(id).is_not_empty()
	GameState.active_investigations = {"test": id}
	GameState.discovery_progress[id] = 0.1
	result = Model.snapshot()
	assert_str(result.research.current.id).is_equal(id)
	assert_float(float(result.research.current.adoption)).is_equal(0.0)

func test_comparison_is_lazy_read_only_and_labels_realm_command_with_actual_donors() -> void:
	var before := Preview._capture_systems()
	Model.snapshot()
	assert_dict(Model._comparison_draft).is_empty()
	var start := Time.get_ticks_usec()
	var result := Model.compare_care()
	print("HOME_LIVES_COMPARISON_MS ", (Time.get_ticks_usec() - start) / 1000.0)
	assert_bool(result.ok).is_true()
	assert_str(result.label).contains("5 percentage points")
	assert_str(result.scope).contains("Civilization-wide")
	assert_array(result.transfers).is_not_empty()
	assert_float(float(result.after.care.current)).is_equal(float(result.before.care.current))
	assert_bool(result.after.care.has("infant_risk")).is_false()
	assert_bool(PeopleDirection.automatic_work).is_true()
	assert_array(_changed_fields(before, Preview._capture_systems())).is_empty()
	start = Time.get_ticks_usec()
	assert_dict(Model.compare_care()).is_equal(result)
	print("HOME_LIVES_CACHED_COMPARISON_MS ", (Time.get_ticks_usec() - start) / 1000.0)
	GameState.food_stocks["Stored food"] += 1.0
	assert_int(int(Model.compare_care().token)).is_not_equal(int(result.token))

func test_secondary_comparison_keeps_starvation_warning_from_another_town() -> void:
	_two_towns()
	GameState.food_stocks = {"Fresh food": 0.0, "Stored food": 0.0}
	GameState.resource_stockpiles.Food = 0.0
	GameState.food_source_health = {"Wild gathering": 0.0, "Hunting": 0.0, "Fishing": 0.0, "Cultivation": 0.0}
	GameState.simulation_metrics.merge({"food_production": 0.0, "food_consumption": 90.0, "food_net": -90.0,
		"food_intake_ratio": 0.0, "food_projected_days": 0.0, "food_total_stock": 0.0}, true)
	var before := Preview._capture_systems()
	var result := Model.compare_care("second")
	assert_bool(result.ok).is_true()
	assert_str(result.after.id).is_equal("second")
	assert_str(result.scope).contains("Other bank")
	assert_bool(result.warnings.any(func(w: Dictionary) -> bool: return w.kind in ["starvation", "food_shortage"] and w.town == "First hearth")).is_true()
	assert_array(_changed_fields(before, Preview._capture_systems())).is_empty()

func _two_towns() -> Dictionary:
	SettlementModel.ensure_founded()
	var second := {"id": "second", "name": "Other bank", "primary": false, "position": Vector2(9, 4), "population_share": 0.25, "founded_day": 0}
	GameState.player_settlements.append(second)
	SettlementModel.with_city_resources("second", func() -> void:
		GameState.food_stocks = {"Fresh food": 2.0, "Stored food": 5.0}
		GameState.resource_stockpiles = {"Food": 7.0, "Freshwater": 3.0}
		GameState.housing_capacity = 40
		GameState.simulation_metrics.merge({"food_production": 35.0, "food_consumption": 30.0, "food_eaten": 30.0, "food_spoilage": 1.0, "food_net": 4.0, "food_intake_ratio": 1.0}, true)
		GameState.water_metrics = {"intake_ratio": 0.5, "collected_today": 15.0, "required_today": 30.0})
	return second

func _changed_fields(before: Dictionary, after_state: Dictionary) -> Array:
	var changed: Array = []
	for system: String in before:
		for category: String in before[system]:
			var old: Dictionary = before[system][category]
			var now: Dictionary = after_state.get(system, {}).get(category, {})
			for field: String in old:
				if not now.has(field) or old[field] != now[field]: changed.append(system + "." + category + "." + field)
			for field: String in now:
				if not old.has(field): changed.append(system + "." + category + "." + field)
	return changed
