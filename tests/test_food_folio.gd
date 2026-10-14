extends GdUnitTestSuite
const FoodPanel = preload("res://scripts/hud/food_folio.gd")

static func prepared_food() -> Dictionary:
	return {"city":"Ashfire", "leader_name":"Koki", "managed":true, "focus":"", "can_direct":true,
		"rows":[{"name":"Fresh food", "stock":0.0, "lost":3.0, "detail":"Fresh food carrying and care."}, {"name":"Stored food", "stock":96411.0, "lost":19.0, "detail":"Stored food keeping and care."}],
		"food_days":226.3, "capacity":200000.0, "food_workers":120.0, "food_share":0.4,
		"water":{"required_today":426.0, "collected_today":440.0, "intake_ratio":1.0, "stored":900.0},
		"forecast90":{"first_shortage_day":-1, "ending_days":240.0}, "forecast30":{},
		"sources":[{"name":"Wild gathering", "produced":400.0, "access":"available", "source_health":0.9, "renewable":300.0, "overused":true}, {"name":"Cultivation", "produced":183.0, "access":"retrievable", "source_health":1.0}],
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
	# The top bar says how long the food lasts; this page never repeats it.
	assert_str(_texts(panel)).not_contains("Food lasts").contains("96,411").contains("Wild gathering").contains("Overused")
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
	assert_bool(panel.update_block(block)).is_false()
	var with_delivery = auto_free(FoodPanel.new())
	with_delivery.setup(block)
	assert_bool(_has_button(with_delivery, "Deliveries")).is_true()

func _has_button(node: Node, words: String) -> bool:
	for button: Node in node.find_children("*", "Button", true, false):
		if button.text == words: return true
	return false
