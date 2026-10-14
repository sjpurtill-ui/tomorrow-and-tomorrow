extends GdUnitTestSuite
const Board:=preload("res://scripts/hud/council_reader.gd")
var called:Array[int]=[]
var discussed:Array[int]=[]
func _block()->Dictionary:
	var people:Array=[];var orders:Array=[]
	for i in 21:
		people.append({"id":str(i),"group":"Officials","cells":{"name":"Official %d" % i,"title":"Keeper of the river"},"office":"Keeper of the river","place":"At the northern ford","read":"Watchful","love":0.6,"dread":0.2,"matters":1 if i==2 else 0,"button":{"on_press":func():called.append(i)}})
		orders.append({"id":str(i),"label":"Keep the crossing open for caravan %d" % i,"value":"Under way","tip":"The leader is gathering the needed hands.","on_click":func():discussed.append(i)})
	return {"people":people,"orders":orders,"view":{}}
func _board()->Control:
	var b:=Board.new();add_child(b);auto_free(b);b.setup(_block());return b
func test_one_official_and_one_order_keep_all_choices_reachable()->void:
	var b=_board()
	assert_int(b.people_picker.item_count).is_equal(21);assert_int(b.order_picker.item_count).is_equal(21)
	assert_str(b.view.person).is_equal("2")
	assert_int(b.find_children("Summon","Button",true,false).size()).is_equal(1)
	assert_int(b.find_children("DiscussOrder","Button",true,false).size()).is_equal(1)
func test_search_select_and_original_callbacks_on_last_records()->void:
	called.clear();discussed.clear();var b=_board()
	b.people_search.text="Official 20";b.people_search.text_changed.emit(b.people_search.text)
	assert_int(b.people_picker.item_count).is_equal(1)
	b.people_picker.select(0);b.people_picker.item_selected.emit(0);b.find_child("Summon",true,false).pressed.emit()
	assert_array(called).contains_exactly([20])
	b.order_search.text="caravan 20";b.order_search.text_changed.emit(b.order_search.text)
	b.order_picker.select(0);b.order_picker.item_selected.emit(0);b.find_child("DiscussOrder",true,false).pressed.emit()
	assert_array(discussed).contains_exactly([20])
func test_live_refresh_retains_selection_query_and_search_focus()->void:
	var b=_board();b.people_search.text="Official 20";b.people_search.text_changed.emit(b.people_search.text);b.people_picker.select(0);b.people_picker.item_selected.emit(0);b.people_search.grab_focus()
	var fresh:=_block();fresh.view=b.view;b.update_block(fresh)
	assert_str(b.view.person).is_equal("20");assert_str(b.people_search.text).is_equal("Official 20")
	assert_object(get_viewport().gui_get_focus_owner()).is_same(b.people_search)
	b.people_search.text="absent";b.people_search.text_changed.emit("absent");assert_bool(b.person_reader.visible).is_false()
	b.order_search.text="absent";b.order_search.text_changed.emit("absent");assert_bool(b.order_reader.visible).is_false()
func test_empty_roster_and_orders_are_valid()->void:
	var b=_board();b.update_block({"people":[],"orders":[],"view":{}})
	assert_int(b.people_picker.item_count).is_equal(0);assert_bool(b.person_reader.visible).is_false()
	assert_bool(b.order_picker.visible).is_false();assert_bool(b.order_reader.visible).is_true()
