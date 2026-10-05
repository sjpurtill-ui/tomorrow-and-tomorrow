extends GdUnitTestSuite
const Probe = preload("res://tests/trade_visual_acceptance_probe.gd")
const Economy = preload("res://scripts/hud/content/dock_content_economy.gd")
var canvas: SubViewport
var hud: Control

class SpeedTarget extends Node:
	var game_speed:=0.0
	func _set_game_speed(speed:float)->void:game_speed=speed

func before_test() -> void:
	Probe.prepare_fixture("barter")
	GameState.simulation_metrics={"food_days":12.0,"food_consumption":120.0,"food_eaten":120.0}
	GameState.water_metrics={"stored":1680.0,"required_today":120.0,"intake_ratio":1.0}
	canvas=SubViewport.new()
	canvas.size=Vector2i(1536,1024)
	add_child(canvas)
	hud=Probe.TradeHud.new()
	canvas.add_child(hud)
	hud.time_text.text="[b]Year 1209 · Autumn[/b] · Freezing →"
	hud._refresh_kpis()
	hud.register_provider("economy",Economy.new(null,hud))
	hud.open_dock("economy",3)
	for i in 4: await get_tree().process_frame

func after_test() -> void:
	if is_instance_valid(canvas):canvas.queue_free()
	for i in 3: await get_tree().process_frame
	Probe.cleanup_fixture()

func _assert_parity() -> void:
	for reading: Dictionary in hud.kpi_readings():
		var entry: Dictionary=hud.top_readings.entries[reading.id]
		assert_bool(entry.button.visible).is_true()
		assert_str(entry.caption.text).is_equal(String(reading.caption))
		assert_str(entry.value.text).is_equal(String(reading.value))
		assert_str(entry.note).is_equal(String(reading.note))
		assert_str(entry.button.accessibility_name).contains(String(reading.note))

func test_top_bar_matches_hidden_strip_and_preserves_navigation_and_hover() -> void:
	assert_bool(hud.kpi_strip.visible).is_false()
	assert_bool(hud.top_readings.is_visible_in_tree()).is_true()
	assert_float(hud.top_readings.get_global_rect().end.y).is_less_equal(45.0)
	assert_object(hud.dock.find_child("FolioReadings",true,false)).is_null()
	assert_object(hud.top_frame.find_child("FolioPaper",true,false)).is_null()
	assert_object(hud.top_frame.get_theme_stylebox("panel").bg_color).is_equal(Color.TRANSPARENT)
	assert_float(hud.get_node("MapTopTint").get_global_rect().end.x).is_equal(1536.0)
	assert_int(hud.kpi_readings().size()).is_equal(5)
	_assert_parity()
	var chosen: Array=[]
	hud.section_requested.connect(func(section:String,sub:int)->void:chosen.assign([section,sub]))
	var entry: Dictionary=hud.top_readings.entries.water
	assert_dict(entry.button.hover_spec()).is_equal(hud.kpi_chips.water.chip.hover_spec())
	entry.button.pressed.emit()
	assert_array(chosen).is_equal(["economy",0])

func test_live_warning_update_retains_focus_controls_and_trade_state() -> void:
	var readings: Control=hud.top_readings
	var button: Button=readings.entries.food.button
	var board: Node=hud.dock.find_child("TradeBoard",true,false)
	var identity:=board.get_instance_id()
	hud.dock.body_scroll.scroll_vertical=100
	for i in 3: await get_tree().process_frame
	var offset: int=hud.dock.body_scroll.scroll_vertical
	button.grab_focus()
	GameState.water_metrics.stored=120.0
	GameState.water_metrics.intake_ratio=0.5
	GameState.simulation_metrics.food_eaten=60.0
	var economic_before:=Probe.economic_fingerprint()
	hud._refresh_kpis()
	for i in 3: await get_tree().process_frame
	_assert_parity()
	assert_str(readings.entries.water.value.text).is_equal("1 day")
	assert_object(readings.entries.water.value.get_theme_color("font_color")).is_equal(readings.SHORTAGE_INK)
	assert_bool(button.has_focus()).is_true()
	assert_int(hud.dock.find_child("TradeBoard",true,false).get_instance_id()).is_equal(identity)
	assert_int(hud.dock.body_scroll.scroll_vertical).is_equal(offset)
	assert_array(Array(Probe.economic_fingerprint())).is_equal(Array(economic_before))
	hud.close_dock()
	hud.open_dock("economy",3)
	_assert_parity()

func test_era_changes_and_narrow_layout_keep_live_values_inside_top_bar() -> void:
	GameState.known_discoveries.append("printing_process")
	hud._refresh_words()
	hud._refresh_kpis()
	_assert_parity()

	assert_bool(hud.top_readings.entries.gdp.button.visible).is_true()
	for width: int in [1536,1138]:
		canvas.size=Vector2i(width,1024)
		hud._layout()
		for i in 6: await get_tree().process_frame
		hud.force_dock_layout()
		_assert_parity()
		assert_float(hud.dock.body_scroll.size.y).is_greater(250.0)
		assert_float(hud.top_frame.get_global_rect().end.x).is_less_equal(hud.time_pill.position.x)
		for entry: Dictionary in hud.top_readings.entries.values():
			if not entry.button.visible:continue
			assert_float(entry.button.get_global_rect().end.x).is_less_equal(hud.top_frame.get_global_rect().end.x-19.0)
	hud.open_dock("economy",2)
	for i in 3: await get_tree().process_frame
	assert_bool(hud.top_readings.is_visible_in_tree()).is_true()
	var open_position:Vector2=hud.top_readings.global_position
	var open_size:Vector2=hud.top_readings.size
	hud.close_dock()
	for i in 3: await get_tree().process_frame
	assert_bool(hud.top_readings.is_visible_in_tree()).is_true()
	assert_bool(hud.kpi_strip.is_visible_in_tree()).is_false()
	assert_object(hud.top_readings.global_position).is_equal(open_position)
	assert_object(hud.top_readings.size).is_equal(open_size)
	_assert_parity()

func test_reference_sidebar_and_speed_controls_keep_their_actions() -> void:
	var target:=SpeedTarget.new()
	hud.add_child(target)
	hud.terrain=target
	for speed in range(1,6):
		hud.speed_buttons[speed].pressed.emit()
		assert_float(target.game_speed).is_equal(float(speed))
		hud._style_speed_controls(speed)
	hud.pause_button.pressed.emit()
	assert_float(target.game_speed).is_equal(0.0)
	hud.pause_button.pressed.emit()
	assert_float(target.game_speed).is_equal(5.0)
	hud.close_dock()
	var chosen:Array=[]
	hud.section_requested.connect(func(section:String,sub:int)->void:chosen.assign([section,sub]))
	for target_page:Array in [["trade","economy",3],["wealth","economy",2],["materials","economy",1]]:
		hud.rail_buttons[target_page[0]].pressed.emit()
		assert_array(chosen).is_equal([target_page[1],target_page[2]])
	hud.open_dock("economy",3)
	hud.rail_buttons.trade.pressed.emit()
	assert_array(chosen).is_equal(["",3])
