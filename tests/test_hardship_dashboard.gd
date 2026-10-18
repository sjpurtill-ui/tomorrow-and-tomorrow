extends GdUnitTestSuite
const Dashboard:=preload("res://scripts/hud/hardship_dashboard.gd")
var board:VBoxContainer
var summoned:=0

func after_test()->void:
	if is_instance_valid(board):board.queue_free()
	await get_tree().process_frame

func _fixture(count:=15)->Dictionary:
	var events:Array=[]
	for index in count:
		events.append({"id":"event%d" % index,"name":"The Coughing Winter","sub":"Sickness · Year %d · Our settlement" % (21-index),
			"detail":"Nine fell ill. The sick were kept apart. Nobody died.","date":"Year %d · Winter" % (21-index),
			"day":7300-index*365,"kind":"Sickness","dead":0 if index==0 else 2,"sick":9,"food":12,"shelter":3,"timber":1})
	return {"events":events,"today":7301,"empty":"Nothing written yet"}

func _open(width:=1000.0,count:=15)->void:
	board=Dashboard.new();add_child(board);board.size.x=width;board.setup(_fixture(count))
	for frame in 6:await get_tree().process_frame

func test_two_hundred_events_remain_a_bounded_dashboard()->void:
	await _open(1100,200)
	assert_int(board._buttons.filter(func(b:Button)->bool:return b.visible).size()).is_equal(6)
	assert_bool(board._columns.vertical).is_false()
	assert_float(board.get_combined_minimum_size().y).is_less(590)
	assert_int(board.find_children("*","OptionButton",true,false).size()).is_equal(0)
	assert_str(board._account.text).is_equal(_fixture().events[0].detail)
	board._older.pressed.emit()
	assert_int(board.page).is_equal(1)
	assert_str(board.selected_id).is_equal("event6")

func test_daily_refresh_retains_selection_and_button_focus()->void:
	await _open()
	board._select_slot(3);board._buttons[3].grab_focus()
	var refreshed:=_fixture();var event:Dictionary=refreshed.events[0].duplicate(true)
	event.id="new";refreshed.events.push_front(event)
	board.update_block(refreshed)
	assert_str(board.selected_id).is_equal("event3")
	assert_bool(board._buttons[3].has_focus()).is_true()
	assert_str(board._sub.text).is_equal(refreshed.events[4].sub)

func test_year_filter_totals_and_empty_year()->void:
	await _open()
	assert_str(board._values[0].text).is_equal("10")
	assert_str(board._values[1].text).is_equal("18")
	assert_str(board._values[2].text).is_equal("90")
	board.year_filter=20;board._refresh_events()
	assert_int(board._page_events().size()).is_equal(1)
	assert_str(board.selected_id).is_equal("event0")
	board.year_filter=30;board._refresh_events()
	assert_bool(board._empty.visible).is_true()
	assert_str(board._account.text).is_empty()

func test_selecting_event_does_not_summon_until_action_pressed()->void:
	await _open()
	var block:=_fixture();block.events[1]["on_click"]=func():summoned+=1
	board.update_block(block);board._select_slot(1)
	assert_int(summoned).is_equal(0)
	assert_bool(board._action.visible).is_true()
	board._action.pressed.emit();assert_int(summoned).is_equal(1)
	block.events[1].erase("on_click");board.update_block(block)
	assert_bool(board._action.visible).is_false()

func test_empty_and_narrow_views()->void:
	await _open(500,0)
	assert_bool(board._columns.vertical).is_true()
	assert_bool(board._empty.visible).is_true()
	assert_str(board._empty.text).is_equal("Nothing written yet")
	assert_float(board.get_combined_minimum_size().x).is_less_equal(500)
	assert_bool(board._action.visible).is_false()
