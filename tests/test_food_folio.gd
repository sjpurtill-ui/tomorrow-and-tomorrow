extends GdUnitTestSuite
const FoodPanel = preload("res://scripts/hud/food_folio.gd")

static func prepared_food() -> Dictionary:
	return {"city":"Ashfire", "leader_name":"Koki", "managed":true, "focus":"", "can_direct":true,
		"rows":[{"name":"Fresh food", "stock":0.0, "lost":3.0, "detail":"Fresh food carrying and care."}, {"name":"Stored food", "stock":96411.0, "lost":19.0, "detail":"Stored food keeping and care."}],
		"food_days":226.3, "capacity":200000.0, "food_workers":120.0, "food_share":0.4,
		"water":{"required_today":426.0, "collected_today":440.0, "intake_ratio":1.0, "stored":900.0},
		"forecast90":{"first_shortage_day":-1, "ending_days":240.0}, "forecast30":{},
		"sources":[{"name":"Wild gathering", "produced":300.0, "access":"available", "source_health":0.9, "renewable":250.0, "overused":true},
			{"name":"Hunting", "produced":70.0, "access":"ambient wildlife only", "source_health":0.8},
			{"name":"Fishing", "produced":30.0, "access":"retrievable", "source_health":0.7},
			{"name":"Cultivation", "produced":183.0, "access":"retrievable", "source_health":1.0}],
		"fire":{"available":true, "embers":0.8, "source":"friction", "status":"Embers kept alight"}, "fuel":12.0,
		"water_access":{"recognized":true, "accessible":true, "source_kind":"spring", "distance_km":0.4},
		"history":[{"day":0, "value":200.0}, {"day":30, "value":226.0}], "deliveries":[],
		"flow":{"Produced":583.0, "Eaten":426.0, "Spoiled":22.0, "Missions":0.0, "Net":135.0},
		"has_deliveries":false, "on_focus":func(_kind):pass, "on_trade":func():pass}

func _texts(node: Node) -> String:
	var out: PackedStringArray = []
	for child in node.find_children("*", "Label", true, false): out.append((child as Label).text)
	for child in node.find_children("*", "Button", true, false): out.append((child as Button).text)
	return "\n".join(out)

func test_live_change_and_shortage_keep_nodes_and_callbacks() -> void:
	var panel = auto_free(FoodPanel.new())
	var block := prepared_food()
	var chosen: Array = []
	block.on_focus = func(kind):chosen.append(kind)
	panel.setup(block)
	var value: Label = panel.daily_values.Net
	assert_str(value.text).is_equal("+135")
	# Which way the stores went is said once, beside the day's head.
	assert_str(panel._refs.today_side.text).is_equal("Stores are growing")
	# The situation leads, while exact evidence and source warnings remain.
	assert_str(_texts(panel)).contains("226").contains("96,411").contains("Wild gathering")
	assert_str(_texts(panel).to_lower()).contains("overused")
	var strip: Array = FoodPanel.kpis(block)
	assert_str(String(strip[1].value)).is_equal("240 days")
	block.flow.Net = -37.0
	block.water.intake_ratio = 0.5
	block.forecast90.first_shortage_day = 12
	assert_bool(panel.update_block(block)).is_true()
	assert_object(panel.daily_values.Net).is_same(value)
	assert_str(value.text).is_equal("−37")
	var later: Array = FoodPanel.kpis(block)
	assert_str(String(later[1].value)).is_equal("Short in 12 days")
	assert_str(String(later[2].value)).is_equal("50%")
	assert_str(_texts(panel)).contains("12 days").contains("50%").contains("120")
	# Every cell is an engine term, and they add up: in + taken - eaten - spoiled - lost in drying = kept.
	assert_bool(panel.daily_values.has("Other")).is_false()
	var real := prepared_food()
	real.on_focus = block.on_focus
	real.flow = {"Produced":62593.0, "Taken":0.0, "Eaten":53105.0, "Spoiled":276.0, "Keeping":146.0, "Missions":165.0, "Net":9066.0}
	assert_bool(panel.update_block(real)).is_true()
	var shown := {}
	for key: String in panel.daily_values: shown[key] = int(String(panel.daily_values[key].text).replace(",", "").replace("+", "").replace("−", ""))
	assert_int(int(shown.Produced) + int(shown.Taken) - int(shown.Eaten) - int(shown.Spoiled) - int(shown.Keeping)).is_equal(int(shown.Net))
	assert_bool((panel.daily_values.Keeping.get_parent() as Control).visible).is_true()
	assert_bool((panel.daily_values.Taken.get_parent() as Control).visible).is_false()
	assert_str(panel._refs.missions.text).contains("165 rations went out")
	# The stores' spoilage sums to the day's Spoiled.
	assert_str(panel._refs.stores_side.text).is_equal("276 spoiled today")
	(panel.find_child("Choice_Provisions", true, false) as Button).pressed.emit()
	assert_array(chosen).contains_exactly(["provisions"])

func test_delivery_link_only_appears_when_there_are_records() -> void:
	var panel = auto_free(FoodPanel.new())
	var block := prepared_food()
	panel.setup(block)
	assert_bool(_has_button(panel, "Deliveries")).is_false()
	block = block.duplicate(true)
	block.has_deliveries = true
	assert_bool(panel.update_block(block)).is_true()
	assert_bool(_has_button(panel, "Deliveries")).is_true()
	block.has_deliveries = false
	assert_bool(panel.update_block(block)).is_true()
	assert_bool(_has_button(panel, "Deliveries")).is_false()

func _has_button(node: Node, words: String) -> bool:
	for button: Node in node.find_children("*", "Button", true, false):
		if button.text == words and button.visible: return true
	return false

func test_all_four_sources_survive_zero_unknown_and_depleted_readings() -> void:
	var panel = auto_free(FoodPanel.new())
	var block := prepared_food()
	panel.setup(block)
	var originals: Dictionary = {}
	for source: String in ["Gathering", "Hunting", "Fishing", "Cultivation"]:
		var node: Node = panel.find_child("Source_" + source, true, false)
		assert_object(node).is_not_null()
		originals[source] = node
	block.sources[0].produced = 0.0
	block.sources[0].source_health = 0.12
	block.sources[0].overused = false
	block.sources[1].produced = 0.0
	block.sources[2].produced = 0.0
	block.sources[2].access = "unconfirmed or inaccessible"
	block.sources[3].produced = 0.0
	block.sources[3].access = "practice not discovered"
	assert_bool(panel.update_block(block)).is_true()
	for source: String in originals:
		assert_object(panel.find_child("Source_" + source, true, false)).is_same(originals[source])
	var cultivation := _texts(originals.Cultivation).to_lower()
	assert_bool("not known" in cultivation or "not discovered" in cultivation or "undiscovered" in cultivation).is_true()
	var gathering := _texts(originals.Gathering).to_lower()
	assert_bool("depleted" in gathering or "thin" in gathering or "12%" in gathering or "12 / 100" in gathering).is_true()
	# A source absent from an older receipt remains named and explicitly unmeasured.
	block.sources = []
	var unread = auto_free(FoodPanel.new())
	unread.setup(block)
	for source: String in originals:
		var node: Node = unread.find_child("Source_" + source, true, false)
		assert_object(node).is_not_null()
		var words := _texts(node).to_lower()
		assert_bool("not measured" in words or "not recorded" in words or "no reading" in words or "—" in words).is_true()

func test_shortage_today_is_not_a_safe_forecast_and_missing_forecast_is_unknown() -> void:
	var panel = auto_free(FoodPanel.new())
	var block := prepared_food()
	block.forecast90 = {"first_shortage_day":0, "ending_days":0.0}
	panel.setup(block)
	var words := String(panel._refs.forecast.text).to_lower()
	assert_bool("today" in words or "now" in words).is_true()
	assert_str(words).not_contains("no shortage")
	var ahead: Dictionary = FoodPanel.kpis(block)[1]
	assert_bool("today" in String(ahead.value).to_lower() or "now" in String(ahead.value).to_lower()).is_true()
	block.forecast90 = {}
	block.forecast30 = {}
	assert_bool(panel.update_block(block)).is_true()
	words = String(panel._refs.forecast.text).to_lower()
	assert_bool("not" in words or "unknown" in words or "—" in words).is_true()
	assert_str(words).not_contains("no shortage")
	assert_str(String(FoodPanel.kpis(block)[1].value)).is_equal("—")

func test_low_water_and_unmeasured_water_are_distinct() -> void:
	var panel = auto_free(FoodPanel.new())
	var block := prepared_food()
	block.water = {"required_today":426.0, "collected_today":213.0, "intake_ratio":0.5, "stored":0.0}
	panel.setup(block)
	assert_str(String(FoodPanel.kpis(block)[2].value)).is_equal("50%")
	assert_str(_texts(panel)).contains("50%")
	block.water = {}
	assert_bool(panel.update_block(block)).is_true()
	assert_str(String(FoodPanel.kpis(block)[2].value)).is_equal("—")
	var water: Node = panel.find_child("WaterStatus", true, false)
	assert_object(water).is_not_null()
	var words := String(water.text).to_lower() if water is Label else _texts(water).to_lower()
	assert_bool("not" in words or "unknown" in words or "—" in words).is_true()
	assert_str(words).not_contains("0%")

func test_reading_and_live_update_do_not_act_and_buttons_use_fresh_callbacks() -> void:
	var panel = auto_free(FoodPanel.new())
	var called: Array[String] = []
	var block := prepared_food()
	block.on_focus = func(_kind: String): called.append("old focus")
	block.on_assign = func(): called.append("old food")
	block.on_assign_water = func(): called.append("old water")
	block.on_trade = func(): called.append("old delivery")
	block.on_talk = func(): called.append("old talk")
	block.on_water_map = func(): called.append("old map")
	var original := block.duplicate(true)
	panel.setup(block)
	assert_dict(block).is_equal(original)
	assert_array(called).is_empty()
	var fresh := block.duplicate(true)
	fresh.leader_name = "New keeper"
	fresh.focus = "water"
	fresh.managed = false
	fresh.has_deliveries = true
	fresh.on_focus = func(kind: String): called.append("focus:" + kind)
	fresh.on_assign = func(): called.append("food")
	fresh.on_assign_water = func(): called.append("water")
	fresh.on_trade = func(): called.append("delivery")
	fresh.on_talk = func(): called.append("talk")
	fresh.on_water_map = func(): called.append("map")
	var unchanged := fresh.duplicate(true)
	assert_bool(panel.update_block(fresh)).is_true()
	assert_dict(fresh).is_equal(unchanged)
	assert_array(called).is_empty()
	for node_name: String in ["AssignFoodWorkers", "AssignWaterCarriers", "Choice_Provisions"]:
		var button: Button = panel.find_child(node_name, true, false)
		assert_object(button).is_not_null()
		if button != null: button.pressed.emit()
	for button: Node in panel.find_children("*", "Button", true, false):
		if button.text == "Deliveries" and button.visible: button.pressed.emit()
	(panel.find_child("TalkFoodLeader", true, false) as Button).pressed.emit()
	panel._refs.water_map.pressed.emit()
	assert_array(called).contains_exactly(["food", "water", "focus:provisions", "delivery", "talk", "map"])

func test_unknown_daily_flow_never_claims_stores_are_stable_or_empty() -> void:
	var panel = auto_free(FoodPanel.new())
	var block := prepared_food()
	block.flow_known = false
	block.flow = {}
	block.food_days = -1.0
	block.forecast90 = {}
	panel.setup(block)
	var words := String(panel._refs.today_side.text).to_lower()
	assert_str(words).not_contains("no change").not_contains("growing").not_contains("shrinking")
	assert_bool("not" in words or "unknown" in words or "—" in words).is_true()
	assert_str(String(panel._refs.horizon.text).to_lower()).not_contains("stores are empty")
	block.flow_known = true
	block.flow = {"Produced":0.0,"Eaten":0.0,"Spoiled":0.0,"Net":0.0}
	block.food_days = 0.0
	assert_bool(panel.update_block(block)).is_true()
	assert_str(String(panel._refs.today_side.text)).contains("No change")

func test_pantry_disclosure_and_live_values_keep_controls_and_input_unchanged() -> void:
	var panel = auto_free(FoodPanel.new())
	var block := prepared_food()
	panel.setup(block)
	var details: Button = panel.find_child("PantryDetails", true, false)
	assert_object(details).is_not_null()
	if details == null: return
	details.pressed.emit()
	assert_bool(panel._refs.details.visible).is_true()
	var id := details.get_instance_id()
	var fresh := block.duplicate(true)
	fresh.rows[0].stock = 125.0
	fresh.rows[1].stock = 96000.0
	fresh.flow.Net = -135.0
	var untouched := fresh.duplicate(true)
	assert_bool(panel.update_block(fresh)).is_true()
	assert_dict(fresh).is_equal(untouched)
	assert_int(panel.find_child("PantryDetails", true, false).get_instance_id()).is_equal(id)
	assert_bool(panel._refs.details.visible).is_true()
	assert_str(String(panel.daily_values.Net.text)).is_equal("−135")
	assert_str(_texts(panel)).contains("125").contains("96,000")

func test_coverage_compares_actual_need_without_inventing_unknown_need()->void:
	var panel=auto_free(FoodPanel.new());var block:=prepared_food()
	panel.setup(block)
	assert_bool(panel._refs.food_coverage.visible).is_false()
	assert_bool(panel._refs.water_coverage.visible).is_true()
	assert_float(float(panel._refs.water_coverage.get_meta("left"))).is_equal(426.0)
	assert_float(float(panel._refs.water_coverage.get_meta("right"))).is_equal(440.0)
	block.food_need=600.0;block.flow.Eaten=400.0
	var original=panel._refs.food_coverage
	panel.update_block(block)
	assert_object(panel._refs.food_coverage).is_same(original)
	assert_bool(original.visible).is_true()
	assert_float(float(original.get_meta("left"))).is_equal(600.0)
	assert_float(float(original.get_meta("right"))).is_equal(400.0)

func test_narrow_food_scene_keeps_sources_readable_and_restores_wide_layout()->void:
	var host:Control=auto_free(Control.new());host.size=Vector2(360,1000);add_child(host)
	var panel:=FoodPanel.new();host.add_child(panel);panel.size=Vector2(360,1000);panel.setup(prepared_food())
	for frame in 4:await get_tree().process_frame
	assert_bool(panel._refs.source_grid.visible).is_true()
	for source:String in panel.SOURCE_NAMES:
		assert_object(panel._refs.source_labels[source].box.get_parent()).is_same(panel._refs.source_grid)
	assert_float(panel.get_combined_minimum_size().x).is_less_equal(360.0)
	panel.size.x=1200
	for frame in 4:await get_tree().process_frame
	assert_bool(panel._refs.source_grid.visible).is_false()
	for source:String in panel.SOURCE_NAMES:
		assert_object(panel._refs.source_labels[source].box.get_parent()).is_same(panel._scene)
