extends GdUnitTestSuite
const Town=preload("res://scripts/hud/town_scope_button.gd")
const Zoom=preload("res://scripts/hud/compact_choices.gd")
func test_zoom_refresh_retains_four_buttons_and_emits_only_explicit_choice()->void:
	var control:Control=auto_free(Zoom.new());add_child(control)
	for name:String in ["Close by","The valley","The region","The far lands"]:control.add_item(name)
	var selected:Array=[];control.item_selected.connect(func(index:int):selected.append(index))
	var before:Button=control.buttons[1]
	control.select(3);assert_array(selected).is_empty();assert_object(control.buttons[1]).is_same(before)
	before.pressed.emit();assert_array(selected).contains_exactly([1]);assert_int(control.selected).is_equal(1)
func test_town_tray_is_bounded_and_retains_identity_after_a_refresh()->void:
	var control:Control=auto_free(Town.new());add_child(control);control.position=Vector2(20,20);control.size=Vector2(150,32)
	for i in 12:control.add_item("Town "+str(i));control.set_item_metadata(i,"city_"+str(i))
	var chosen:Array=[];control.item_selected.connect(func(index:int):chosen.append(control.get_item_metadata(index)))
	control.select(2);control.pressed.emit()
	for i in 4:await get_tree().process_frame
	assert_bool(control.panel.visible).is_true();assert_int(control.choice.buttons.size()).is_equal(6)
	assert_str(control.text).is_equal("Town · Town 2")
	var button:Button=control.choice.buttons[2]
	control.clear()
	for i in range(11,-1,-1):control.add_item("Town "+str(i));control.set_item_metadata(11-i,"city_"+str(i))
	button.pressed.emit()
	assert_array(chosen).contains_exactly(["city_2"])
	assert_bool(control.panel.visible).is_false()
	assert_str(control.text).is_equal("Town · Town 2")

func test_narrow_map_bar_keeps_town_population_and_clock_separate()->void:
	var canvas:SubViewport=auto_free(SubViewport.new());canvas.size=Vector2i(914,643);add_child(canvas)
	var hud:Control=auto_free(preload("res://tests/trade_visual_acceptance_probe.gd").TradeHud.new());canvas.add_child(hud)
	hud.city_selector.clear();hud.city_selector.add_item("A long settlement name");hud.city_selector.show()
	hud._update_kpi("population","435 souls","",Color.WHITE,"");hud._update_kpi("food","225 days","",Color.WHITE,"")
	hud.time_text.text="[b]Year 119 · Autumn[/b]";hud._layout()
	for i in 6:await get_tree().process_frame
	hud._layout()
	for i in 6:await get_tree().process_frame
	assert_float(hud.city_selector.get_global_rect().end.x).is_less_equal(hud.time_pill.position.x)
	assert_float(hud.time_pill.get_global_rect().end.x).is_less_equal(hud.top_actions.position.x)
	assert_bool(hud.top_readings.entries.population.button.visible).is_true()
	assert_str(hud.top_readings.entries.population.caption.text).is_equal("ALL PEOPLE")
