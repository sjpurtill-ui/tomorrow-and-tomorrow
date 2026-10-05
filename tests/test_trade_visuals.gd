extends GdUnitTestSuite
## Presentation reads and actions stay attached to the real Trade ledger.
const Board = preload("res://scripts/hud/trade_board.gd")
const Probe = preload("res://tests/trade_visual_acceptance_probe.gd")
const Ledger = preload("res://scripts/trade_ledger.gd")
const Stances = preload("res://scripts/trade_stances.gd")
const Words = preload("res://scripts/trade_words.gd")
const Tracker = preload("res://scripts/order_tracker.gd")
const Goods = preload("res://scripts/civilian_goods.gd")
const EraWords = preload("res://scripts/hud/era_words.gd")
var ids: Array

func test_one_balance_bar_is_centered_and_changes_direction() -> void:
	var chart: Control = auto_free(preload("res://scripts/hud/trade_graphics.gd").new())
	for sample: Array in [[[0.0,0.0],0.0],[[80.0,80.0],0.0],[[80.0,0.0],-1.0],[[0.0,80.0],1.0],[[30.0,90.0],0.5],[[90.0,30.0],-0.5]]:
		chart.values=sample[0]
		assert_float(float(chart._balance())).is_equal_approx(float(sample[1]),0.001)

func before_test() -> void:
	ids = Probe.prepare_fixture("barter")

func after_test() -> void:
	Probe.cleanup_fixture()

func _board() -> Control:
	var board: Control = auto_free(Board.new())
	add_child(board)
	board.setup({})
	board.set_process(false)
	return board

func test_hero_totals_convert_real_monthly_flows_once() -> void:
	var board := _board()
	var chart: Control = board.find_child("FlowTotals", true, false)
	assert_object(board.find_child("TradeHero", true, false)).is_not_null()
	assert_object(chart).is_not_null()
	if chart == null: return
	var sent := 0.0
	var received := 0.0
	for row: Dictionary in Ledger.partners("player"):
		sent += Ledger.flow_value("player", String(row.id))
		received += Ledger.flow_value(String(row.id), "player")
	assert_array(Array(chart.values)).is_equal([sent * 3.0, received * 3.0])
	assert_array(Array(chart.labels)).is_equal(["Sent", "Received"])
	assert_str((board.find_child("GoodsToTrade", true, false) as Label).text).contains(EraWords.grouped(roundi(Goods.spare())))

func test_partner_flow_periods_follow_barter_and_coin_ledger() -> void:
	for kind: String in ["barter", "coin"]:
		ids = Probe.prepare_fixture(kind)
		var board := _board()
		var id := String(ids[0])
		var people := board.find_child("People_" + id, true, false)
		var chart: Control = people.find_child("Flows", true, false)
		assert_object(chart).is_not_null()
		if chart == null: continue
		var form := String(Ledger.pair("player", id).form)
		assert_array(Array(chart.values)).is_equal([Words.per_period(Ledger.flow_value("player", id), form), Words.per_period(Ledger.flow_value(id, "player"), form)])
		assert_object(people.find_child("Wesend", true, false)).is_not_null()
		assert_object(people.find_child("Theysend", true, false)).is_not_null()
		assert_str((people.find_child("Name", true, false) as Label).text).is_equal(Ledger.name_of(id))

func test_word_only_contacts_have_no_trade_figures_or_actions() -> void:
	ids = Probe.prepare_fixture("word")
	var board := _board()
	for id: String in ids:
		var people := board.find_child("People_" + id, true, false)
		assert_object(people).is_not_null()
		for key: String in ["Flows", "Stances", "BuyWithGoods", "Wesend", "Theysend"]:
			assert_object(people.find_child(key, true, false)).is_null()

func test_refresh_retains_live_controls_and_preserves_domain_state() -> void:
	var board := _board()
	var nodes: Dictionary = {}
	for key: String in ["FlowTotals", "People_" + String(ids[0]), "People_" + String(ids[1]), "Stance_toll", "BuyWithGoods"]:
		var node := board.find_child(key, true, false)
		assert_object(node).is_not_null()
		if node != null: nodes[key] = node.get_instance_id()
	var before := Probe.economic_fingerprint()
	for pass_index in 5: board.refresh()
	assert_array(Array(Probe.economic_fingerprint())).is_equal(Array(before))
	for key: String in nodes: assert_int(board.find_child(key, true, false).get_instance_id()).is_equal(int(nodes[key]))

func test_directional_change_updates_totals_even_when_combined_value_is_equal() -> void:
	var board := _board()
	var chart: Control = board.find_child("FlowTotals", true, false)
	assert_object(chart).is_not_null()
	if chart == null: return
	var before: Array = chart.values.duplicate()
	var pair := Ledger.pair("player", String(ids[0]))
	var out := "ab" if String(pair.a) == "player" else "ba"
	var incoming := "ba" if out == "ab" else "ab"
	pair.val[out] += 10.0
	pair.val[incoming] -= 10.0
	Ledger.revision += 1
	# Exercise ordinary changed-data refresh after its real throttle, with no
	# pointer hold. No private timing hook or forced rebuild masks invalidation.
	board.visible = false
	# Headless fixed-frame runs advance SceneTreeTimer faster than wall time.
	# The runtime throttle intentionally uses the monotonic wall clock.
	var wait_until := Time.get_ticks_msec() + Board.REBUILD_MS + 50
	while Time.get_ticks_msec() < wait_until: await get_tree().process_frame
	board.refresh()
	await await_idle_frame()
	chart = board.find_child("FlowTotals", true, false)
	assert_float(float(chart.values[0])).is_equal_approx(float(before[0]) + 30.0, 0.001)
	assert_float(float(chart.values[1])).is_equal_approx(float(before[1]) - 30.0, 0.001)

func test_actual_board_fits_320px_independently_of_shared_dock_minimum() -> void:
	var scroll: ScrollContainer = auto_free(ScrollContainer.new())
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size = Vector2(320, 900)
	add_child(scroll)
	var board := Board.new()
	scroll.add_child(board)
	board.setup({})
	board.set_process(false)
	for frame in 12: await await_idle_frame()
	assert_float(board.size.x).is_less_equal(320.0)
	assert_float(board.get_combined_minimum_size().x).is_less_equal(320.0)
	var overflow: Array[String] = []
	Probe.horizontal_overflow(board, scroll.get_global_rect(), overflow)
	assert_array(overflow).is_empty()

func test_stance_button_uses_real_court_action_and_tracks_order() -> void:
	var board := _board()
	var id := String(ids[0])
	var people := board.find_child("People_" + id, true, false)
	var button := people.find_child("Stance_favour", true, false) as Button
	assert_object(button).is_not_null()
	var orders_before := Tracker.orders().size()
	button.pressed.emit()
	assert_str(String(Stances.stance("player", id).id)).is_equal("favour")
	assert_int(Tracker.orders().size()).is_equal(orders_before + 1)
	assert_bool((board.find_child("Said", true, false) as Label).text.is_empty()).is_false()

func test_squeeze_menu_applies_selected_good_with_stated_odds() -> void:
	var board := _board()
	var id := String(ids[0])
	var people := board.find_child("People_" + id, true, false)
	var menu := people.find_child("Stance_squeeze", true, false) as MenuButton
	assert_bool(menu.disabled).is_false()
	assert_int(menu.get_popup().item_count).is_greater(0)
	var flint_index := -1
	for index in menu.get_popup().item_count:
		if menu.get_popup().get_item_text(index).to_lower().begins_with("flint"): flint_index = index
	assert_int(flint_index).is_greater_equal(0)
	if flint_index < 0: return
	menu.get_popup().id_pressed.emit(flint_index)
	var stance := Stances.stance("player", id)
	assert_str(String(stance.id)).is_equal("squeeze")
	assert_str(String(stance.good)).is_equal("Flint")
	assert_int(int(stance.answer)).is_greater(int(GameState.elapsed_days))
	assert_object(board.find_child("Odds", true, false)).is_not_null()

func test_buy_menu_moves_actual_goods_and_registers_order() -> void:
	var board := _board()
	var id := String(ids[0])
	var people := board.find_child("People_" + id, true, false)
	var menu := people.find_child("BuyWithGoods", true, false) as MenuButton
	var offers := Ledger.deal_offers("player", id)
	var chosen := -1
	for index in offers.size():
		if bool(offers[index].ok) and String(offers[index].what) not in Ledger.PEOPLE and String(offers[index].what) != Ledger.ARMS:
			chosen = index
			break
	assert_int(chosen).is_greater_equal(0)
	if chosen < 0: return
	var terms: Dictionary = offers[chosen].duplicate(true)
	var goods_before := float(GameState.resource_stockpiles["Civilian Goods"])
	var held_before := _stock("player", String(terms.what))
	var theirs_before := _stock(id, String(terms.what))
	var orders_before := Tracker.orders().size()
	assert_bool(menu.get_popup().is_item_disabled(chosen)).is_false()
	menu.get_popup().id_pressed.emit(chosen)
	assert_float(goods_before - float(GameState.resource_stockpiles["Civilian Goods"])).is_equal_approx(float(terms.goods), 0.01)
	assert_float(_stock("player", String(terms.what)) - held_before).is_equal_approx(float(terms.count), 0.01)
	assert_float(theirs_before - _stock(id, String(terms.what))).is_equal_approx(float(terms.count), 0.01)
	assert_int(Tracker.orders().size()).is_equal(orders_before + 1)

func test_embargo_disables_buy_without_hiding_stance_choices() -> void:
	var board := _board()
	var people := board.find_child("People_" + String(ids[1]), true, false)
	assert_bool((people.find_child("BuyWithGoods", true, false) as MenuButton).disabled).is_true()
	assert_object(people.find_child("Stances", true, false)).is_not_null()
	assert_str((people.find_child("Theirs", true, false) as Label).text.to_lower()).contains("embargo")
	assert_object(people.find_child("LastWord", true, false)).is_not_null()

func _stock(owner: String, good: String) -> float:
	return float(WorldSimulation.scoped(owner, func() -> float:
		return WorldSimulation.food.total_stored() if good == "Food" else float(WorldSimulation.state.resource_stockpiles.get(good, 0.0))))
