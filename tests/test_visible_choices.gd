extends GdUnitTestSuite
const Choices=preload("res://scripts/hud/visible_choices.gd")

func test_programmatic_reading_does_not_issue_commands_and_click_keeps_identity()->void:
	var tray=auto_free(Choices.new());add_child(tray)
	var commands:Array=[];tray.item_selected.connect(func(index:int):commands.append(tray.get_item_metadata(index)))
	tray.add_item("Timber",42);tray.set_item_metadata(0,"timber")
	tray.add_item("Stone",84);tray.set_item_metadata(1,"stone")
	tray.select(1)
	await get_tree().process_frame
	assert_array(commands).is_empty()
	assert_int(tray.get_selected_id()).is_equal(84)
	tray.buttons[0].pressed.emit()
	assert_array(commands).contains_exactly(["timber"])
	assert_int(tray.get_item_index(42)).is_equal(0)

func test_large_choice_sets_are_searchable_bounded_and_keep_control_instances()->void:
	var tray=auto_free(Choices.new());add_child(tray);tray.size.x=320
	for i in 100:tray.add_item("Town "+str(i));tray.set_item_metadata(i,i)
	tray.select(98)
	await get_tree().process_frame
	assert_bool(tray.search.visible).is_true()
	assert_int(tray.buttons.size()).is_equal(6)
	assert_int(tray.page).is_equal(16)
	var original:Array=tray.buttons.duplicate()
	tray.search.text="Town 42";tray.search.text_changed.emit("Town 42")
	await get_tree().process_frame
	assert_str(tray.buttons[0].text).is_equal("Town 42")
	assert_bool(tray.buttons[1].visible).is_false()
	tray.buttons[0].pressed.emit()
	assert_int(tray.selected).is_equal(42)
	tray.set_item_text(42,"Town 42 · updated")
	await get_tree().process_frame
	assert_array(tray.buttons).contains_exactly(original)
	assert_int(tray.find_children("*","OptionButton",true,false).size()).is_equal(0)
	assert_int(tray.find_children("*","PopupMenu",true,false).size()).is_equal(0)
	assert_float(tray.get_combined_minimum_size().x).is_less_equal(320.0)

func test_disabled_choices_never_dispatch_even_if_signal_is_triggered()->void:
	var tray=auto_free(Choices.new());add_child(tray)
	var commands:Array=[];tray.item_selected.connect(func(index:int):commands.append(index))
	tray.add_item("Unknown place");tray.set_item_disabled(0,true)
	await get_tree().process_frame
	tray.buttons[0].pressed.emit();assert_array(commands).is_empty()
	tray.set_item_disabled(0,false);tray.disabled=true
	await get_tree().process_frame
	tray.buttons[0].pressed.emit();assert_array(commands).is_empty()

func test_outer_search_does_not_hide_pagination()->void:
	var tray=auto_free(Choices.new());add_child(tray);tray.searchable=false
	for i in 20:tray.add_item("Town "+str(i))
	await get_tree().process_frame
	assert_bool(tray.search.visible).is_false()
	assert_bool(tray.pager.visible).is_true()
	tray.next.pressed.emit()
	await get_tree().process_frame
	assert_int(tray.page).is_equal(1)
	assert_str(tray.buttons[0].text).is_equal("Town 6")

func test_refresh_between_paint_and_click_cannot_dispatch_another_item()->void:
	var tray=auto_free(Choices.new());add_child(tray)
	var commands:Array=[];tray.item_selected.connect(func(index:int):commands.append(tray.get_item_metadata(index)))
	tray.add_item("Timber");tray.set_item_metadata(0,"timber")
	tray.add_item("Stone");tray.set_item_metadata(1,"stone")
	await get_tree().process_frame
	tray.buttons[0].grab_focus()
	tray.clear()
	tray.add_item("Stone");tray.set_item_metadata(0,"stone")
	tray.add_item("Timber");tray.set_item_metadata(1,"timber")
	tray.buttons[0].pressed.emit()
	assert_array(commands).contains_exactly(["timber"])
	await get_tree().process_frame
	assert_bool(tray.buttons[1].has_focus()).is_true()
