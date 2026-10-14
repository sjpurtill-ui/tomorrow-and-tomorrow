extends GdUnitTestSuite
const Board:=preload("res://scripts/hud/world_history_board.gd")
var opened:Array[int]=[]
func entries()->Array:
	var out:Array=[]
	for i in 19:
		out.append({"day":7300-i*80,"season":"Spring","title":"River event %d" % i,"text":"Full telling %d about the cedar route. The messenger brought detailed news." % i,"group":["contact","war","scout"][i%3],"icon":"world","count":2 if i==7 else 1,"on_open":func():opened.append(i)})
	return out
func board()->Control:
	var b:=Board.new();add_child(b);auto_free(b);b.setup({"entries":entries(),"view":{}});return b
func test_recent_has_three_choices_and_one_complete_telling()->void:
	var b=board()
	assert_int(b.list.get_child_count()).is_equal(3)
	assert_str(b.find_child("SelectedText",true,false).text).contains("The messenger brought detailed news.")
	assert_bool(b.search.visible).is_false()
	assert_int(b.find_children("SelectedTelling","",true,false).size()).is_equal(1)
func test_archive_is_six_per_page_and_all_entries_are_reachable()->void:
	var b=board();b.set_archive(true)
	assert_int(b.list.get_child_count()).is_equal(6)
	b.change_page(1);assert_str(b.find_child("SelectedTitle",true,false).text).is_equal("River event 6")
	b.change_page(2);assert_int(b.list.get_child_count()).is_equal(1)
	assert_str(b.find_child("SelectedTitle",true,false).text).is_equal("River event 18")
	assert_bool(b.next.disabled).is_true()
func test_search_and_filter_select_matching_complete_telling_and_callback()->void:
	opened.clear();var b=board();b.set_archive(true)
	b.search.text="telling 7";b.search.text_changed.emit(b.search.text)
	assert_int(b.list.get_child_count()).is_equal(1)
	assert_str(b.find_child("SelectedTitle",true,false).text).is_equal("River event 7")
	b.find_child("OpenReport",true,false).pressed.emit();assert_array(opened).contains_exactly([7])
	b.search.text="";b.search.text_changed.emit("")
	b.find_child("Filter_scout",true,false).pressed.emit()
	assert_int(b.chosen().size()).is_equal(6)
	assert_str(b.find_child("SelectedTitle",true,false).text).is_equal("River event 2")
func test_no_match_hides_old_reader_and_live_refresh_preserves_search_focus()->void:
	var b=board();b.set_archive(true);b.search.grab_focus()
	b.search.text="missing";b.search.text_changed.emit("missing")
	assert_bool(b.reader.get_parent().visible).is_false()
	b.update_block({"entries":entries(),"view":b.view})
	assert_str(b.search.text).is_equal("missing")
	assert_object(get_viewport().gui_get_focus_owner()).is_same(b.search)
func test_return_to_recent_preserves_archive_query_and_page()->void:
	var b=board();b.set_archive(true);b.search.text="cedar";b.search.text_changed.emit("cedar");b.change_page(2)
	b.set_archive(false);assert_int(b.list.get_child_count()).is_equal(3)
	b.set_archive(true);assert_str(b.search.text).is_equal("cedar");assert_int(b.view.page).is_equal(2)
	assert_str(b.find_child("SelectedTitle",true,false).text).is_equal("River event 12")
func test_shrinking_records_clamps_page_without_losing_reader()->void:
	var b=board();b.set_archive(true);b.change_page(3)
	b.update_block({"entries":entries().slice(0,2),"view":b.view})
	assert_int(b.view.page).is_equal(0);assert_int(b.list.get_child_count()).is_equal(2)
	assert_str(b.find_child("SelectedTitle",true,false).text).is_equal("River event 0")
func test_narrow_archive_opens_one_telling_and_returns_to_same_results()->void:
	var b=board();b.size.x=520;b._layout();b.set_archive(true);b.change_page(1)
	assert_bool(b.browser.visible).is_true();assert_bool(b.reader.get_parent().visible).is_false()
	b.select_entry(b.chosen()[7])
	assert_bool(b.browser.visible).is_false();assert_bool(b.reader.get_parent().visible).is_true()
	assert_str(b.find_child("SelectedTitle",true,false).text).is_equal("River event 7")
	b.find_child("BackToResults",true,false).pressed.emit()
	assert_bool(b.browser.visible).is_true();assert_int(b.view.page).is_equal(1)
	assert_int(b.list.get_child_count()).is_equal(6)
func test_replacing_view_synchronizes_search_text_with_visible_results()->void:
	var b=board();b.set_archive(true);b.search.text="absent";b.search.text_changed.emit("absent")
	b.update_block({"entries":entries(),"view":{"archive":true}})
	assert_str(b.search.text).is_equal("");assert_int(b.list.get_child_count()).is_equal(6)
