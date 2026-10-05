extends GdUnitTestSuite
const FoodPanel = preload("res://scripts/hud/food_folio.gd")
const Reserve = preload("res://scripts/hud/food_common_store.gd")
const Probe = preload("res://tests/trade_visual_acceptance_probe.gd")

static func prepared_food() -> Dictionary:
	return {"city":"Ashfire", "leader_name":"Koki", "managed":true, "focus":"", "can_direct":true,
		"rows":[{"name":"Fresh food", "stock":0.0, "lost":3.0, "detail":"Fresh food carrying and care."}, {"name":"Stored food", "stock":96411.0, "lost":19.0, "detail":"Stored food keeping and care."}],
		"food_days":226.3, "water":{"required_today":426.0, "collected_today":440.0, "intake_ratio":1.0},
		"forecast90":{"first_shortage_day":-1, "ending_days":240.0}, "forecast30":{},
		"flow":{"Produced":583.0, "Eaten":426.0, "Spoiled":22.0, "Missions":0.0, "Net":135.0},
		"selected":"", "has_deliveries":false, "on_select":func(_kind):pass, "on_focus":func(_kind):pass,
		"on_water":func():pass, "on_sources":func():pass, "on_history":func():pass, "on_trade":func():pass}

func test_live_change_and_shortage_keep_nodes_and_callbacks() -> void:
	var panel = auto_free(FoodPanel.new())
	var block := prepared_food()
	var chosen: Array = []
	block.on_focus = func(kind):chosen.append(kind)
	panel.setup(block)
	var value: Label = panel.daily_values.Net
	assert_str(value.text).is_equal("+135")
	assert_str(panel._refs.food.get_child(1).text).contains("135 rations added")
	block.flow.Net = -37.0
	block.water.intake_ratio = 0.5
	block.forecast90.first_shortage_day = 12
	assert_bool(panel.update_block(block)).is_true()
	assert_object(panel.daily_values.Net).is_same(value)
	assert_str(value.text).is_equal("-37")
	assert_str(panel._refs.forecast.text).contains("food runs short")
	assert_str(panel._refs.water.get_child(0).text).contains("5 in every 10")
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

func test_reserve_disclosure_retains_spending_controls_and_open_state() -> void:
	Probe.prepare_fixture("barter")
	var board = auto_free(Reserve.new())
	add_child(board)
	board.setup({"mode":"store"})
	assert_bool(board.details.visible).is_false()
	assert_object(board.find_child("Level_heavy", true, false)).is_not_null()
	board.disclosure.button_pressed = true
	assert_bool(board.details.visible).is_true()
	assert_bool(board.update_block({"mode":"store"})).is_true()
	assert_bool(board.details.visible).is_true()
	assert_bool(board.view_state().reserve_open).is_true()
	board.restore_view_state({"reserve_open":false})
	assert_bool(board.details.visible).is_false()
	board._build_sources({"towns":[{"name":"Ashfire"}], "rich":0.0, "deposits":0.0, "evaded":0.0})
	assert_bool(board.sources_box.visible).is_false()
	Probe.cleanup_fixture()

func _has_button(node: Node, words: String) -> bool:
	for button: Node in node.find_children("*", "Button", true, false):
		if button.text == words: return true
	return false
