extends GdUnitTestSuite
const Feed:=preload("res://scripts/hud/chronicle_feed.gd")
const Works:=preload("res://scripts/hud/chronicle_works_reader.gd")

func _year()->Dictionary:
	var entries:Array=[]
	for index in 70:entries.append({"key":"record%d" % index,"day":index,"tier":"notice","kind":"discovery","title":"Known way %d" % index,"text":"Complete account of finding %d, including its effect on the people's work." % index})
	return {"entries":entries,"years":[{"n":1,"closed":false,"story":entries,"pop":100,"born":7,"buried":2,"learned":70,"text":"A year of making and learning."}]}

func test_busy_year_starts_with_three_and_search_pages_keep_all_accounts()->void:
	var feed:Control=auto_free(Feed.new());add_child(feed);feed.size=Vector2(1060,700);feed.setup(_year())
	for i in 3:await get_tree().process_frame
	assert_int(feed.event_choices.get_children().filter(func(node:Node)->bool:return node.get_node_or_null("Line")!=null).size()).is_equal(3)
	feed.browse_toggle.pressed.emit()
	assert_int(feed.event_choices.get_children().filter(func(node:Node)->bool:return node.get_node_or_null("Line")!=null).size()).is_equal(6)
	feed.archive_page=11;feed._render_list()
	assert_int(feed.event_choices.get_children().filter(func(node:Node)->bool:return node.get_node_or_null("Line")!=null).size()).is_equal(4)
	feed.archive_search.text="finding 4,";feed.archive_search.text_changed.emit("finding 4,")
	assert_int(feed.event_choices.get_children().filter(func(node:Node)->bool:return node.get_node_or_null("Line")!=null).size()).is_equal(1)
	feed.open_key="record4";feed._render_list()
	assert_object(feed.find_child("Reading",true,false)).is_not_null()
	assert_bool(feed.facts.visible).is_false()
	var state:Dictionary=feed.view_state();feed.update_block(_year())
	assert_dict(feed.view_state()).is_equal(state)
	feed.event_choices.get_child(0).get_node("Line").pressed.emit()
	feed.size.x=420;feed._layout_events()
	assert_bool(feed.event_reader.visible).is_true()
	assert_bool(feed.event_choices.visible).is_false()
	feed.event_back.pressed.emit()
	assert_bool(feed.event_reader.visible).is_false()
	assert_bool(feed.event_choices.visible).is_true()
	feed.event_choices.get_child(0).get_node("Line").pressed.emit()
	assert_bool(feed.event_reader.visible).is_true()

func test_year_choice_and_full_telling_survive_focused_archive()->void:
	var feed:Control=auto_free(Feed.new());add_child(feed);feed.setup(_year())
	feed.open_key="telling:1";feed._render_folio()
	assert_object(feed.find_child("Telling",true,false)).is_not_null()
	feed._choose(1)
	feed.browsing=true;feed.archive_page=2;feed._render_list()
	var state:Dictionary=feed.view_state()
	var restored:Control=auto_free(Feed.new());add_child(restored);restored.setup(_year());restored.restore_view_state(state)
	assert_dict(restored.view_state()).is_equal(state)
	assert_int(restored.event_choices.get_children().filter(func(node:Node)->bool:return node.get_node_or_null("Line")!=null).size()).is_equal(6)

func test_building_reader_pages_all_records_and_keeps_full_materials_and_notes()->void:
	var records:Array=[]
	for index in 90:records.append({"key":str(index),"title":"Hearth %d" % index,"event":"Rebuilt","date":"Year %d" % index,"place":"Riverbank","materials":"12 timber, 8 clay","note":"Complete note %d" % index})
	var reader:Control=auto_free(Works.new());add_child(reader);reader.size=Vector2(1060,700);reader.setup({"records":records})
	assert_int(reader.choices.get_children().filter(func(node:Node)->bool:return node is PanelContainer).size()).is_equal(3)
	reader.browse_button.pressed.emit()
	assert_int(reader.choices.get_children().filter(func(node:Node)->bool:return node is PanelContainer).size()).is_equal(6)
	reader.search.text="Complete note 89";reader.search.text_changed.emit("Complete note 89")
	assert_int(reader.choices.get_children().filter(func(node:Node)->bool:return node is PanelContainer).size()).is_equal(1)
	assert_str(reader.selected).is_equal("89")
	assert_str(reader.reader.get_child(4).text).is_equal("12 timber, 8 clay")
	assert_str(reader.reader.get_child(5).text).is_equal("Complete note 89")
	var state:Dictionary=reader.view_state();reader.restore_view_state(state)
	assert_dict(reader.view_state()).is_equal(state)
